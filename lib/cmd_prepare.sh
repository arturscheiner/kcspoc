#!/bin/bash

cmd_prepare() {
    ui_banner
    
    # Load config first
    if ! load_config; then
        echo -e "${RED}${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
        exit 1
    fi

    echo -e "${YELLOW}${ICON_GEAR} ${MSG_PREPARE_START}${NC}"
    echo "${MSG_PREPARE_USING_NS}: $NAMESPACE"
    echo "${MSG_PREPARE_USING_REG}: $REGISTRY_SERVER"
    echo "${MSG_PREPARE_USING_DOMAIN}: $DOMAIN"
    echo "${MSG_PREPARE_USING_IP}: $IP_RANGE"
    echo "----------------------------"

    # 1. Namespace & Secret
    echo -e "${YELLOW}[1/6] ${MSG_PREPARE_STEP_1}${NC}"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    echo "${MSG_PREPARE_CREATING_SECRET}"
    kubectl create secret docker-registry kcs-registry-secret \
      --docker-server="$REGISTRY_SERVER" \
      --docker-username="$REGISTRY_USER" \
      --docker-password="$REGISTRY_PASS" \
      --docker-email="$REGISTRY_EMAIL" \
      -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    # 2. Infrastructure Dependencies
    echo -e "${YELLOW}[2/6] ${MSG_PREPARE_STEP_2}${NC}"
    
    # Cert-Manager
    echo "${MSG_PREPARE_INSTALL_CERT}"
    helm repo add jetstack https://charts.jetstack.io --force-update > /dev/null
    helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true --wait > /dev/null

    # Local Path Storage
    echo "${MSG_PREPARE_INSTALL_LOCAL}"
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml > /dev/null
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

    # Metrics Server
    echo "${MSG_PREPARE_INSTALL_METRICS}"
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml > /dev/null
    # Patch for lab environments (insecure TLS)
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
      {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
      {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP"}
    ]' 2>/dev/null || true

    # 3. MetalLB
    echo -e "${YELLOW}[3/6] ${MSG_PREPARE_STEP_3}${NC}"
    helm repo add metallb https://metallb.github.io/metallb > /dev/null
    helm upgrade --install metallb metallb/metallb --namespace metallb-system --create-namespace --wait > /dev/null
    
    sleep 5
    
    cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - $IP_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
EOF

    # 4. Ingress-Nginx
    echo -e "${YELLOW}[4/6] ${MSG_PREPARE_STEP_4}${NC}"
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx > /dev/null
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait > /dev/null

    # 5. Kernel Headers
    echo -e "${YELLOW}[5/6] ${MSG_PREPARE_STEP_5}${NC}"
    # Check if we have sudo
    if command -v sudo > /dev/null; then
        sudo apt update && sudo apt install linux-headers-$(uname -r) -y
    else
        echo -e "${RED}${MSG_PREPARE_SUDO_FAIL}${NC}"
    fi

    # 6. Verification
    echo -e "${YELLOW}[6/6] ${MSG_PREPARE_STEP_6}${NC}"
    sleep 5
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

    echo -e "${GREEN}${ICON_OK} ${MSG_PREPARE_COMPLETED}${NC}"
    echo -e "${MSG_PREPARE_INGRESS_IP}: $INGRESS_IP"
    echo -e "${MSG_PREPARE_HOSTS_HINT}: $INGRESS_IP $DOMAIN"
}
