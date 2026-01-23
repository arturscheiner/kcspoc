
#!/bin/bash

confirm_step() {
    local step_name="$1"
    local title="$2"
    local desc="$3"
    local unattended="$4"
    local custom_prompt="$5"

    if [ "$unattended" = true ]; then
        return 0
    fi

    echo -e "\n${BLUE}${BOLD}--- $title ---${NC}"
    echo -e "${BLUE}${MSG_AUDIT_RES}:${NC} $desc"
    echo ""
    
    local prompt_msg=""
    if [ -n "$custom_prompt" ]; then
        prompt_msg="$custom_prompt"
    else
        prompt_msg="$(printf "$MSG_PREPARE_PROMPT_INSTALL" "$step_name")"
    fi

    echo -ne "   ${ICON_QUESTION} ${prompt_msg}"
    read -r response
    if [[ "$response" =~ ^[SsYy]$ ]]; then
        return 0
    else
        return 1
    fi
}

_check_dependency() {
    local component="$1"
    local ns="$2"
    local found=1

    case "$component" in
        "Namespace")
            kubectl get ns "$ns" &>/dev/null && found=0
            ;;
        "Registry Auth")
            kubectl get secret kcs-registry-secret -n "$ns" &>/dev/null && found=0
            ;;
        "Cert-Manager")
            kubectl get deployment -n cert-manager cert-manager &>/dev/null && found=0
            ;;
        "Local Path Storage")
            kubectl get sc local-path &>/dev/null && found=0
            ;;
        "Metrics Server")
            kubectl get deployment -n kube-system metrics-server &>/dev/null && found=0
            ;;
        "MetalLB")
            kubectl get ns metallb-system &>/dev/null && found=0
            ;;
        "Ingress-Nginx")
            kubectl get ns ingress-nginx &>/dev/null && found=0
            ;;
        "Kernel Headers")
            dpkg -l linux-headers-$(uname -r) &>/dev/null && found=0
            ;;
    esac

    return $found
}

cmd_prepare() {
    # --- Argument Parsing ---
    local UNATTENDED=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unattended)
                UNATTENDED=true
                shift
                ;;
            --help|help)
                ui_help "prepare" "$MSG_HELP_PREPARE_DESC" "$MSG_HELP_PREPARE_OPTS" "$MSG_HELP_PREPARE_EX"
                return 0
                ;;
            *)
                ui_help "prepare" "$MSG_HELP_PREPARE_DESC" "$MSG_HELP_PREPARE_OPTS" "$MSG_HELP_PREPARE_EX"
                return 1
                ;;
        esac
    done

    ui_banner
    
    # Load config first
    if ! load_config; then
        echo -e "${RED}${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
        exit 1
    fi

    echo -e "${YELLOW}${ICON_GEAR} $MSG_PREPARE_START${NC}"
    if [ "$UNATTENDED" = true ]; then
        echo -e "   ${DIM}$MSG_PREPARE_UNATTENDED_RUN${NC}"
    else
        echo -e "   ${DIM}$MSG_PREPARE_INTERACTIVE_WARN${NC}"
    fi
    echo -e "   ${DIM}$MSG_PREPARE_LABEL_INFO: ${BOLD}$POC_LABEL${NC}"
    echo ""
    echo "   ${MSG_PREPARE_USING_NS}: $NAMESPACE"
    echo "   ${MSG_PREPARE_USING_REG}: $REGISTRY_SERVER"
    echo "   ${MSG_PREPARE_USING_DOMAIN}: $DOMAIN"
    echo "   ${MSG_PREPARE_USING_IP}: $IP_RANGE"
    echo "   ----------------------------"
    
    local PREPARE_ERROR=0

    # 1. Namespace Check Only
    if _check_dependency "Namespace" "$NAMESPACE"; then
        echo -e "   ${GREEN}${ICON_OK} ${MSG_PREPARE_STEP_1_A}: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    else
        echo -e "   ${YELLOW}${ICON_INFO} ${MSG_PREPARE_STEP_1_A}: ${DIM}${MSG_CHECK_INFRA_MISSING}${NC}"
        echo -e "      ${DIM}Namespace $NAMESPACE will be automatically created during 'kcspoc deploy'${NC}"
    fi

    # 1.1 Registry Auth
    if _check_dependency "Registry Auth" "$NAMESPACE"; then
        echo -e "   ${GREEN}${ICON_OK} ${MSG_PREPARE_STEP_1_B}: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    elif confirm_step "Registry Auth" "$MSG_PREPARE_STEP_1_B" "Setup of Docker Registry credentials." "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_1_B"
        if kubectl create secret docker-registry kcs-registry-secret \
          --docker-server="$REGISTRY_SERVER" \
          --docker-username="$REGISTRY_USER" \
          --docker-password="$REGISTRY_PASS" \
          --docker-email="$REGISTRY_EMAIL" \
          -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT" && \
          kubectl label secret kcs-registry-secret -n "$NAMESPACE" $POC_LABEL --overwrite &>> "$DEBUG_OUT"; then
            ui_spinner_stop "PASS"
            check_k8s_label "secret" "kcs-registry-secret" "$NAMESPACE"
        else
            ui_spinner_stop "FAIL"
            PREPARE_ERROR=1
        fi
    fi

    # 2. Cert-Manager
    if _check_dependency "Cert-Manager"; then
        echo -e "   ${GREEN}${ICON_OK} Cert-Manager: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    elif confirm_step "Cert-Manager" "$MSG_PREPARE_WHY_CERT_TITLE" "$MSG_PREPARE_WHY_CERT_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_INSTALL_CERT"
        force_delete_ns "cert-manager"
        local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
        helm repo add jetstack https://charts.jetstack.io --force-update &>> "$DEBUG_OUT"
        if helm upgrade --install cert-manager jetstack/cert-manager \
            --namespace cert-manager --create-namespace \
            --set crds.enabled=true \
            --set startupapicheck.enabled=false \
            --wait --timeout 300s &> "$HELM_ERR"; then
            
            # Log successful helm output to debug
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            
            # Label namespace and resources
            kubectl label namespace cert-manager $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            kubectl label deployment -n cert-manager --all $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            ui_spinner_stop "PASS"
            check_k8s_label "namespace" "cert-manager"
        else
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)...${NC}"
            PREPARE_ERROR=1
        fi
    fi

    # 3. Local Path Storage
    if _check_dependency "Local Path Storage"; then
        echo -e "   ${GREEN}${ICON_OK} Local Path Storage: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    elif confirm_step "Local Path Storage" "$MSG_PREPARE_WHY_STORAGE_TITLE" "$MSG_PREPARE_WHY_STORAGE_DESC" "$UNATTENDED"; then
        download_artifact "local-path-provisioner" "https://github.com/rancher/local-path-provisioner.git"
        
        ui_spinner_start "$MSG_PREPARE_INSTALL_LOCAL"
        force_delete_ns "local-path-storage"
        local CHART_PATH="$ARTIFACTS_DIR/local-path-provisioner/deploy/chart/local-path-provisioner"
        
        if helm upgrade --install local-path-storage "$CHART_PATH" \
           --namespace local-path-storage --create-namespace &>> "$DEBUG_OUT"; then
            
            kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' &>> "$DEBUG_OUT"
            kubectl label sc local-path $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            ui_spinner_stop "PASS"
            check_k8s_label "sc" "local-path"
        else
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}Helm install failed. Check logs.${NC}"
            PREPARE_ERROR=1
        fi
    fi

    # 4. Metrics Server
    if _check_dependency "Metrics Server"; then
        echo -e "   ${GREEN}${ICON_OK} Metrics Server: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    elif confirm_step "Metrics Server" "$MSG_PREPARE_WHY_METRICS_TITLE" "$MSG_PREPARE_WHY_METRICS_DESC" "$UNATTENDED"; then
        local MANIFEST_URL="https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
        download_artifact "metrics-server" "$MANIFEST_URL"
        
        ui_spinner_start "$MSG_PREPARE_INSTALL_METRICS"
        if kubectl apply -f "$ARTIFACTS_DIR/metrics-server/components.yaml" &>> "$DEBUG_OUT" && \
           kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
             {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
             {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP"}
           ]' &>> "$DEBUG_OUT" && \
           kubectl label deployment metrics-server -n kube-system $POC_LABEL --overwrite &>> "$DEBUG_OUT"; then
            ui_spinner_stop "PASS"
            check_k8s_label "deployment" "metrics-server" "kube-system"
        else
            ui_spinner_stop "FAIL"
            PREPARE_ERROR=1
        fi
    fi

    # 5. MetalLB
    if _check_dependency "MetalLB"; then
        echo -e "   ${GREEN}${ICON_OK} MetalLB: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    elif confirm_step "MetalLB" "$MSG_PREPARE_WHY_METALLB_TITLE" "$MSG_PREPARE_WHY_METALLB_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_3"
        force_delete_ns "metallb-system"
        local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
        helm repo add metallb https://metallb.github.io/metallb &>> "$DEBUG_OUT"
        if helm upgrade --install metallb metallb/metallb \
            --namespace metallb-system --create-namespace \
            --wait --timeout 300s &> "$HELM_ERR"; then
            
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            
            # Label
            kubectl label namespace metallb-system $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            kubectl label deployment -n metallb-system --all $POC_LABEL --overwrite &>> "$DEBUG_OUT"
 
            sleep 5
            cat <<EOF | kubectl apply -f - &>> "$DEBUG_OUT"
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
  labels:
    $POC_LABEL_KEY: "$POC_LABEL_VAL"
spec:
  addresses:
  - $IP_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
  labels:
    $POC_LABEL_KEY: "$POC_LABEL_VAL"
spec:
  ipAddressPools:
  - first-pool
EOF
            ui_spinner_stop "PASS"
            check_k8s_label "namespace" "metallb-system"
        else
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)...${NC}"
            PREPARE_ERROR=1
        fi
    fi

    # 6. Ingress-Nginx
    if _check_dependency "Ingress-Nginx"; then
        echo -e "   ${GREEN}${ICON_OK} Ingress-Nginx: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    elif confirm_step "Ingress-Nginx" "$MSG_PREPARE_WHY_INGRESS_TITLE" "$MSG_PREPARE_WHY_INGRESS_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_4"
        force_delete_ns "ingress-nginx"
        local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx &>> "$DEBUG_OUT"
        if helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
            --namespace ingress-nginx --create-namespace \
            --wait --timeout 300s &> "$HELM_ERR"; then
            
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            
            # Label
            kubectl label namespace ingress-nginx $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            kubectl label deployment -n ingress-nginx --all $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            ui_spinner_stop "PASS"
            check_k8s_label "namespace" "ingress-nginx"
        else
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)...${NC}"
            PREPARE_ERROR=1
        fi
    fi

    # 7. Kernel Headers
    if _check_dependency "Kernel Headers"; then
        echo -e "   ${GREEN}${ICON_OK} Kernel Headers: ${DIM}${MSG_CHECK_INFRA_INSTALLED}${NC}"
    elif confirm_step "Kernel Headers" "$MSG_PREPARE_WHY_HEADERS_TITLE" "$MSG_PREPARE_WHY_HEADERS_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_5"
        if command -v sudo &>> "$DEBUG_OUT"; then
            if sudo apt update &>> "$DEBUG_OUT" && sudo apt install linux-headers-$(uname -r) -y &>> "$DEBUG_OUT"; then
                ui_spinner_stop "PASS"
            else
                ui_spinner_stop "FAIL"
                PREPARE_ERROR=1
            fi
        else
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}${MSG_PREPARE_SUDO_FAIL}${NC}"
            PREPARE_ERROR=1
        fi
    fi

    # 8. Verification
    ui_section "$MSG_PREPARE_STEP_6"
    sleep 5
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>> "$DEBUG_OUT" || echo "Pending...")

    if [ "$PREPARE_ERROR" -eq 1 ]; then
        echo -e "${RED}${BOLD}${ICON_FAIL} ${MSG_PREPARE_COMPLETED}${NC} (With errors)"
        echo -e "   ${MSG_ERROR_CONFIG_NOT_FOUND}" # Fallback generic error msg
        exit 1
    else
        echo -e "${GREEN}${ICON_OK} ${MSG_PREPARE_COMPLETED}${NC}"
        echo -e "   ${MSG_PREPARE_INGRESS_IP}: ${BOLD}${BLUE}$INGRESS_IP${NC}"
        echo -e "   ${MSG_PREPARE_HOSTS_HINT}: ${BOLD}${YELLOW}$INGRESS_IP $DOMAIN${NC}"
    fi
    echo ""
}
