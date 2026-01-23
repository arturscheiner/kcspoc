#!/bin/bash

cmd_destroy() {
    # --- Argument Parsing ---
    local UNATTENDED=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unattended)
                UNATTENDED=true
                shift
                ;;
            --help|help)
                ui_help "destroy" "$MSG_HELP_DESTROY_DESC" "$MSG_HELP_DESTROY_OPTS" "$MSG_HELP_DESTROY_EX"
                return 0
                ;;
            *)
                ui_help "destroy" "$MSG_HELP_DESTROY_DESC" "$MSG_HELP_DESTROY_OPTS" "$MSG_HELP_DESTROY_EX"
                return 1
                ;;
        esac
    done

    ui_banner
    
    # Load config to get NAMESPACE and RELEASE_NAME (assumed kcs from standard setup)
    # If config not found, we use defaults but warn user
    local TARGET_NS="kcs"
    local RELEASE_NAME="kcs"
    
    if load_config; then
        TARGET_NS="${NAMESPACE:-kcs}"
    fi

    # Phase I: Transition Signaling (Status: cleaning)
    # Applied as soon as TARGET_NS is determined to ensure maximum visibility.
    _update_state "$TARGET_NS" "cleaning" "destroy" "$EXEC_HASH" "$(get_config_hash)" ""

    # --- Safety Check (Interactive) ---
    if [ "$UNATTENDED" = false ]; then
        ui_section "$MSG_DESTROY_TITLE"
        echo -e "${RED}${BOLD}${ICON_WARN} $MSG_DESTROY_WARN_TITLE${NC}"
        echo -e "${YELLOW}$MSG_DESTROY_WARN_DESC${NC}"
        echo ""
        
        # Get Cluster Name for confirmation phrase
        local CLUSTER_NAME=$(kubectl config current-context 2>/dev/null || echo "unknown-cluster")
        local REQUIRED_PHRASE=$(printf "$MSG_DESTROY_CONFIRM_PHRASE" "$CLUSTER_NAME")
        
        echo -e "${DIM}$MSG_DESTROY_PROMPT${NC}"
        echo -e "${BLUE}${BOLD}$REQUIRED_PHRASE${NC}"
        echo ""
        echo -ne "${ICON_QUESTION} > "
        read -r USER_INPUT
        
        if [ "$USER_INPUT" != "$REQUIRED_PHRASE" ]; then
            echo -e "\n${RED}$MSG_DESTROY_CANCEL${NC}"
            exit 1
        fi
        echo ""

        # Optional Infrastructure Removal
        echo -e "${YELLOW}$MSG_DESTROY_DEPS_PROMPT${NC}"
        echo -ne "${ICON_QUESTION} > "
        read -r DEPS_INPUT
        if [[ "$DEPS_INPUT" =~ ^[Yy]$ ]]; then
            CLEANUP_DEPS=true
        else
            CLEANUP_DEPS=false
        fi
        echo ""
    fi

    echo -e "${YELLOW}${ICON_GEAR} $MSG_DESTROY_START${NC}"
    echo "----------------------------"

    # 1. Helm Release
    if helm status "$RELEASE_NAME" -n "$TARGET_NS" &>> "$DEBUG_OUT"; then
        ui_spinner_start "[1/8] $MSG_DESTROY_STEP_1"
        helm uninstall "$RELEASE_NAME" -n "$TARGET_NS" &>> "$DEBUG_OUT"
        ui_spinner_stop "PASS"
    else
        echo -e "   ${BLUE}${ICON_INFO} [1/8] $RELEASE_NAME: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # 2. PVC Purge (Phase N: Deep Destruction)
    if kubectl get pvc -n "$TARGET_NS" &>> "$DEBUG_OUT"; then
        ui_spinner_start "[2/8] Mandatory PVC Purge"
        kubectl delete pvc --all -n "$TARGET_NS" --timeout=60s &>> "$DEBUG_OUT" || true
        ui_spinner_stop "PASS"
    else
        echo -e "   ${BLUE}${ICON_INFO} [2/8] PVCs: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # 3. Namespace & Certificates
    if kubectl get namespace "$TARGET_NS" &>> "$DEBUG_OUT"; then
        ui_spinner_start "$(printf "$MSG_DESTROY_NS_NOTICE" "$TARGET_NS")"
        # Pre-delete certificates to avoid stuck finalizers
        kubectl delete certificate --all -n "$TARGET_NS" --timeout=30s &>> "$DEBUG_OUT" || true
        kubectl delete namespace "$TARGET_NS" --timeout=120s &>> "$DEBUG_OUT"
        wait_and_force_delete_ns "$TARGET_NS" 5
        ui_spinner_stop "PASS"
    else
        echo -e "   ${BLUE}${ICON_INFO} [3/8] $TARGET_NS: $MSG_DESTROY_NOT_FOUND${NC}"
    fi
 
    # 4. PVs (Orphaned)
    ui_spinner_start "[4/8] $MSG_DESTROY_STEP_4"
    # Filter PVs that have claimRef to our namespace
    local KCS_PVS=$(kubectl get pv -o json 2>> "$DEBUG_OUT" | jq -r ".items[] | select(.spec.claimRef.namespace==\"$TARGET_NS\") | .metadata.name")
    
    if [ -n "$KCS_PVS" ]; then
        for pv in $KCS_PVS; do
            kubectl delete pv "$pv" --timeout=30s &>> "$DEBUG_OUT"
        done
        ui_spinner_stop "PASS"
    else
        ui_spinner_stop "PASS"
        echo -e "      ${DIM}$MSG_DESTROY_NOT_FOUND${NC}"
    fi
 
    # 5. Global Webhooks
    ui_spinner_start "[5/8] $MSG_DESTROY_STEP_5"
    local WEBHOOKS="kcs-admission-controller"
    
    # Validating
    kubectl delete validatingwebhookconfiguration "$WEBHOOKS" --ignore-not-found &>> "$DEBUG_OUT"
    # Mutating
    kubectl delete mutatingwebhookconfiguration "$WEBHOOKS" --ignore-not-found &>> "$DEBUG_OUT"
    ui_spinner_stop "PASS"
 
    # 6. Global RBAC
    ui_spinner_start "[6/8] $MSG_DESTROY_STEP_6"
    local TARGET_ROLES="kcs-admission-controller kcs-agent-broker kcs-scanner"
    
    kubectl delete clusterrole $TARGET_ROLES --ignore-not-found &>> "$DEBUG_OUT"
    kubectl delete clusterrolebinding $TARGET_ROLES --ignore-not-found &>> "$DEBUG_OUT"
    ui_spinner_stop "PASS"

    # 7. Sanity Check (Orphaned Secrets)
    ui_spinner_start "[7/8] Sanity Check"
    # Find any secrets matching helm release pattern across all namespaces
    local ORPHANED_SECRETS=$(kubectl get secrets -A --no-headers 2>> "$DEBUG_OUT" | grep "sh.helm.release.v1.kcs" | awk '{print $2 " -n " $1}')
    
    if [ -n "$ORPHANED_SECRETS" ]; then
        echo "$ORPHANED_SECRETS" | xargs -I {} bash -c 'kubectl delete secret {} &>> /dev/null'
    fi
    ui_spinner_stop "PASS"

    # 8. Infrastructure Dependencies (Optional)
    if [ "$CLEANUP_DEPS" == "true" ]; then
         echo -e "\n${RED}${BOLD}=== $MSG_DESTROY_DEPS_TITLE ===${NC}"
         
         # Ingress
         ui_spinner_start "$MSG_DESTROY_DEPS_INGRESS"
         helm uninstall ingress-nginx -n ingress-nginx &>> "$DEBUG_OUT" || true
         kubectl delete namespace ingress-nginx --wait=false &>> "$DEBUG_OUT" || true
         wait_and_force_delete_ns "ingress-nginx" 3
         ui_spinner_stop "PASS"
 
         # MetalLB
         ui_spinner_start "$MSG_DESTROY_DEPS_METALLB"
         helm uninstall metallb -n metallb-system &>> "$DEBUG_OUT" || true
         kubectl delete namespace metallb-system --wait=false &>> "$DEBUG_OUT" || true
         wait_and_force_delete_ns "metallb-system" 3
         ui_spinner_stop "PASS"
         
         # Cert-Manager
         ui_spinner_start "$MSG_DESTROY_DEPS_CERT"
         helm uninstall cert-manager -n cert-manager &>> "$DEBUG_OUT" || true
         kubectl delete namespace cert-manager --wait=false &>> "$DEBUG_OUT" || true
         wait_and_force_delete_ns "cert-manager" 3
         ui_spinner_stop "PASS"
         
         # Storage & Metrics
         ui_spinner_start "$MSG_DESTROY_DEPS_STORAGE"
         kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml &>> "$DEBUG_OUT" || true
         kubectl delete deployment metrics-server -n kube-system &>> "$DEBUG_OUT" || true
         ui_spinner_stop "PASS"
    else
         echo -e "${BLUE}[8/8] $MSG_DESTROY_DEPS_SKIPPED${NC}"
    fi

    echo -e "\n${GREEN}${BOLD}${ICON_OK} $MSG_DESTROY_SUCCESS${NC}"
    echo -e "${DIM}$MSG_DESTROY_HINT${NC}"
}
