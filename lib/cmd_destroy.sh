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
            *)
                shift
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
    echo -e "${YELLOW}[1/5] $MSG_DESTROY_STEP_1${NC}"
    if helm status "$RELEASE_NAME" -n "$TARGET_NS" >/dev/null 2>&1; then
        helm uninstall "$RELEASE_NAME" -n "$TARGET_NS" >/dev/null 2>&1
        echo -e "${GREEN}${ICON_OK} $RELEASE_NAME: $MSG_DESTROY_REMOVED${NC}"
    else
        echo -e "${BLUE}${ICON_INFO} $RELEASE_NAME: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # 2. Namespace
    echo -e "${YELLOW}[2/5] $MSG_DESTROY_STEP_2${NC}"
    if kubectl get namespace "$TARGET_NS" >/dev/null 2>&1; then
        kubectl delete namespace "$TARGET_NS" --timeout=60s >/dev/null 2>&1
        echo -e "${GREEN}${ICON_OK} $TARGET_NS: $MSG_DESTROY_REMOVED${NC}"
    else
        echo -e "${BLUE}${ICON_INFO} $TARGET_NS: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # 3. PVCs (Residual)
    echo -e "${YELLOW}[3/5] $MSG_DESTROY_STEP_3${NC}"
    # Even if NS is gone, check if any PVCs are stuck (might happen during termination) or if NS deletion failed
    # We use a loop over PVCs in that NS just in case it still exists
    local RESIDUAL_PVCS=$(kubectl get pvc -n "$TARGET_NS" --no-headers 2>/dev/null | awk '{print $1}')
    if [ -n "$RESIDUAL_PVCS" ]; then
        echo "$RESIDUAL_PVCS" | xargs -I {} kubectl delete pvc {} -n "$TARGET_NS" --force --grace-period=0 2>/dev/null || true
        echo -e "${GREEN}${ICON_OK} PVCs: $MSG_DESTROY_REMOVED${NC}"
    else
        echo -e "${BLUE}${ICON_INFO} PVCs: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # 4. PVs (Orphaned)
    echo -e "${YELLOW}[4/5] $MSG_DESTROY_STEP_4${NC}"
    # Filter PVs that have claimRef to our namespace
    local KCS_PVS=$(kubectl get pv -o json 2>/dev/null | jq -r ".items[] | select(.spec.claimRef.namespace==\"$TARGET_NS\") | .metadata.name")
    
    if [ -n "$KCS_PVS" ]; then
        for pv in $KCS_PVS; do
            kubectl delete pv "$pv" --timeout=30s >/dev/null 2>&1
            echo -e "${GREEN}${ICON_OK} PV $pv: $MSG_DESTROY_REMOVED${NC}"
        done
    else
        echo -e "${BLUE}${ICON_INFO} PVs: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # 5. Global Webhooks
    echo -e "${YELLOW}[5/5] $MSG_DESTROY_STEP_5${NC}"
    local WEBHOOKS="kcs-admission-controller"
    
    # Validating
    if kubectl get validatingwebhookconfiguration "$WEBHOOKS" >/dev/null 2>&1; then
        kubectl delete validatingwebhookconfiguration "$WEBHOOKS" >/dev/null 2>&1
        echo -e "${GREEN}${ICON_OK} ValidatingWebhook: $MSG_DESTROY_REMOVED${NC}"
    else
        echo -e "${BLUE}${ICON_INFO} ValidatingWebhook: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # Mutating
    if kubectl get mutatingwebhookconfiguration "$WEBHOOKS" >/dev/null 2>&1; then
        kubectl delete mutatingwebhookconfiguration "$WEBHOOKS" >/dev/null 2>&1
        echo -e "${GREEN}${ICON_OK} MutatingWebhook: $MSG_DESTROY_REMOVED${NC}"
    else
        echo -e "${BLUE}${ICON_INFO} MutatingWebhook: $MSG_DESTROY_NOT_FOUND${NC}"
    fi

    # 6. Global RBAC
    echo -e "${YELLOW}[6/7] $MSG_DESTROY_STEP_6${NC}"
    # Delete ClusterRoles and Bindings containing 'kcs' (broad match)
    local KCS_CRS=$(kubectl get clusterrole -o name | grep "kcs")
    local KCS_CRBS=$(kubectl get clusterrolebinding -o name | grep "kcs")
    
    if [ -n "$KCS_CRS" ]; then
        echo "$KCS_CRS" | xargs -I {} kubectl delete {} >/dev/null 2>&1
        echo -e "${GREEN}${ICON_OK} ClusterRoles: $MSG_DESTROY_REMOVED${NC}"
    fi
    if [ -n "$KCS_CRBS" ]; then
        echo "$KCS_CRBS" | xargs -I {} kubectl delete {} >/dev/null 2>&1
        echo -e "${GREEN}${ICON_OK} ClusterRoleBindings: $MSG_DESTROY_REMOVED${NC}"
    fi

    # 7. Infrastructure Dependencies (Optional)
    if [ "$CLEANUP_DEPS" == "true" ]; then
         echo -e "\n${RED}${BOLD}=== $MSG_DESTROY_DEPS_TITLE ===${NC}"
         
         # Ingress
         echo -e "${YELLOW}[7.1] $MSG_DESTROY_DEPS_INGRESS${NC}"
         helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true
         kubectl delete namespace ingress-nginx --wait=false 2>/dev/null || true

         # MetalLB
         echo -e "${YELLOW}[7.2] $MSG_DESTROY_DEPS_METALLB${NC}"
         helm uninstall metallb -n metallb-system 2>/dev/null || true
         kubectl delete namespace metallb-system --wait=false 2>/dev/null || true
         
         # Cert-Manager
         echo -e "${YELLOW}[7.3] $MSG_DESTROY_DEPS_CERT${NC}"
         helm uninstall cert-manager -n cert-manager 2>/dev/null || true
         kubectl delete namespace cert-manager --wait=false 2>/dev/null || true
         
         # Storage & Metrics
         echo -e "${YELLOW}[7.4] $MSG_DESTROY_DEPS_STORAGE${NC}"
         kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml 2>/dev/null || true
         kubectl delete deployment metrics-server -n kube-system 2>/dev/null || true
         
         echo -e "${GREEN}${ICON_OK} $MSG_DESTROY_REMOVED${NC}"
    else
         echo -e "${BLUE}[7/7] $MSG_DESTROY_DEPS_SKIPPED${NC}"
    fi

    echo -e "\n${GREEN}${BOLD}${ICON_OK} $MSG_DESTROY_SUCCESS${NC}"
    echo -e "${DIM}$MSG_DESTROY_HINT${NC}"
}
