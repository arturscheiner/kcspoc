
#!/bin/bash

confirm_step() {
    local step_name="$1"
    local title="$2"
    local desc="$3"
    local unattended="$4"

    if [ "$unattended" = true ]; then
        return 0
    fi

    echo -e "\n${BLUE}${BOLD}--- $title ---${NC}"
    echo -e "${BLUE}${MSG_AUDIT_RES}:${NC} $desc"
    echo ""
    echo -ne "   ${ICON_QUESTION} $(printf "$MSG_PREPARE_PROMPT_INSTALL" "$step_name")"
    read -r response
    if [[ "$response" =~ ^[SsYy]$ ]]; then
        return 0
    else
        return 1
    fi
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
            *)
                shift
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

    # 1. Namespace & Secret
    if confirm_step "Namespace & Secret" "$MSG_PREPARE_STEP_1" "Setup of $NAMESPACE and credentials." "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_1"
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT"
        kubectl label namespace "$NAMESPACE" $POC_LABEL --overwrite &>> "$DEBUG_OUT"
        
        kubectl create secret docker-registry kcs-registry-secret \
          --docker-server="$REGISTRY_SERVER" \
          --docker-username="$REGISTRY_USER" \
          --docker-password="$REGISTRY_PASS" \
          --docker-email="$REGISTRY_EMAIL" \
          -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT"
        kubectl label secret kcs-registry-secret -n "$NAMESPACE" $POC_LABEL --overwrite &>> "$DEBUG_OUT"
        ui_spinner_stop "PASS"
    fi

    # 2. Cert-Manager
    if confirm_step "Cert-Manager" "$MSG_PREPARE_WHY_CERT_TITLE" "$MSG_PREPARE_WHY_CERT_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_INSTALL_CERT"
        local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
        helm repo add jetstack https://charts.jetstack.io --force-update &>> "$DEBUG_OUT"
        if helm upgrade --install cert-manager jetstack/cert-manager \
            --namespace cert-manager --create-namespace \
            --set crds.enabled=true \
            --wait --timeout 300s &> "$HELM_ERR"; then
            
            # Log successful helm output to debug
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            
            # Label namespace and resources
            kubectl label namespace cert-manager $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            kubectl label deployment -n cert-manager --all $POC_LABEL --overwrite &>> "$DEBUG_OUT"
            ui_spinner_stop "PASS"
        else
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)...${NC}"
        fi
    fi

    # 3. Local Path Storage
    if confirm_step "Local Path Storage" "$MSG_PREPARE_WHY_STORAGE_TITLE" "$MSG_PREPARE_WHY_STORAGE_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_INSTALL_LOCAL"
        kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml &>> "$DEBUG_OUT"
        kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' &>> "$DEBUG_OUT"
        kubectl label sc local-path $POC_LABEL --overwrite &>> "$DEBUG_OUT"
        ui_spinner_stop "PASS"
    fi

    # 4. Metrics Server
    if confirm_step "Metrics Server" "$MSG_PREPARE_WHY_METRICS_TITLE" "$MSG_PREPARE_WHY_METRICS_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_INSTALL_METRICS"
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml &>> "$DEBUG_OUT"
        kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
          {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
          {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP"}
        ]' &>> "$DEBUG_OUT"
        kubectl label deployment metrics-server -n kube-system $POC_LABEL --overwrite &>> "$DEBUG_OUT"
        ui_spinner_stop "PASS"
    fi

    # 5. MetalLB
    if confirm_step "MetalLB" "$MSG_PREPARE_WHY_METALLB_TITLE" "$MSG_PREPARE_WHY_METALLB_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_3"
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
        else
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)...${NC}"
        fi
    fi

    # 6. Ingress-Nginx
    if confirm_step "Ingress-Nginx" "$MSG_PREPARE_WHY_INGRESS_TITLE" "$MSG_PREPARE_WHY_INGRESS_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_4"
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
        else
            cat "$HELM_ERR" >> "$DEBUG_OUT"
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)...${NC}"
        fi
    fi

    # 7. Kernel Headers
    if confirm_step "Kernel Headers" "$MSG_PREPARE_WHY_HEADERS_TITLE" "$MSG_PREPARE_WHY_HEADERS_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_5"
        if command -v sudo &>> "$DEBUG_OUT"; then
            sudo apt update &>> "$DEBUG_OUT" && sudo apt install linux-headers-$(uname -r) -y &>> "$DEBUG_OUT"
            ui_spinner_stop "PASS"
        else
            ui_spinner_stop "FAIL"
            echo -e "      ${RED}${MSG_PREPARE_SUDO_FAIL}${NC}"
        fi
    fi

    # 8. Verification
    ui_section "$MSG_PREPARE_STEP_6"
    sleep 5
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>> "$DEBUG_OUT" || echo "Pending...")

    echo -e "${GREEN}${ICON_OK} ${MSG_PREPARE_COMPLETED}${NC}"
    echo -e "   ${MSG_PREPARE_INGRESS_IP}: ${BOLD}${BLUE}$INGRESS_IP${NC}"
    echo -e "   ${MSG_PREPARE_HOSTS_HINT}: ${BOLD}${YELLOW}$INGRESS_IP $DOMAIN${NC}"
    echo ""
}
