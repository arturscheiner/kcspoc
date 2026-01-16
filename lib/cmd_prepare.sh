
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

    # 1. Namespace
    if confirm_step "Namespace" "$MSG_PREPARE_STEP_1_A" "Setup of $NAMESPACE." "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_1_A"
        kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT"
        kubectl label namespace "$NAMESPACE" $POC_LABEL --overwrite &>> "$DEBUG_OUT"
        ui_spinner_stop "PASS"
        check_k8s_label "namespace" "$NAMESPACE"
    fi

    # 1.1 Registry Auth
    if confirm_step "Registry Auth" "$MSG_PREPARE_STEP_1_B" "Setup of Docker Registry credentials." "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_STEP_1_B"
        kubectl create secret docker-registry kcs-registry-secret \
          --docker-server="$REGISTRY_SERVER" \
          --docker-username="$REGISTRY_USER" \
          --docker-password="$REGISTRY_PASS" \
          --docker-email="$REGISTRY_EMAIL" \
          -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT"
        kubectl label secret kcs-registry-secret -n "$NAMESPACE" $POC_LABEL --overwrite &>> "$DEBUG_OUT"
        ui_spinner_stop "PASS"
        check_k8s_label "secret" "kcs-registry-secret" "$NAMESPACE"
    fi

    # 2. Cert-Manager
    if confirm_step "Cert-Manager" "$MSG_PREPARE_WHY_CERT_TITLE" "$MSG_PREPARE_WHY_CERT_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_INSTALL_CERT"
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
        fi
    fi

    # 3. Local Path Storage
    if confirm_step "Local Path Storage" "$MSG_PREPARE_WHY_STORAGE_TITLE" "$MSG_PREPARE_WHY_STORAGE_DESC" "$UNATTENDED"; then
        ui_spinner_start "$MSG_PREPARE_INSTALL_LOCAL"
        
        # Deploy Local Path Provisioner (Embedded v0.0.31)
        cat << 'EOF' | kubectl apply -f - &>> "$DEBUG_OUT"
apiVersion: v1
kind: Namespace
metadata:
  name: local-path-storage

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: local-path-provisioner-service-account
  namespace: local-path-storage

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: local-path-provisioner-role
  namespace: local-path-storage
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: local-path-provisioner-role
rules:
  - apiGroups: [""]
    resources: ["nodes", "persistentvolumeclaims", "configmaps", "pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "patch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: local-path-provisioner-bind
  namespace: local-path-storage
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: local-path-provisioner-role
subjects:
  - kind: ServiceAccount
    name: local-path-provisioner-service-account
    namespace: local-path-storage

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: local-path-provisioner-bind
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: local-path-provisioner-role
subjects:
  - kind: ServiceAccount
    name: local-path-provisioner-service-account
    namespace: local-path-storage

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-path-provisioner
  namespace: local-path-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: local-path-provisioner
  template:
    metadata:
      labels:
        app: local-path-provisioner
    spec:
      serviceAccountName: local-path-provisioner-service-account
      containers:
        - name: local-path-provisioner
          image: rancher/local-path-provisioner:v0.0.31
          imagePullPolicy: IfNotPresent
          command:
            - local-path-provisioner
            - --debug
            - start
            - --config
            - /etc/config/config.json
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config/
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: CONFIG_MOUNT_PATH
              value: /etc/config/
      volumes:
        - name: config-volume
          configMap:
            name: local-path-config

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: local-path-config
  namespace: local-path-storage
data:
  config.json: |-
    {
            "nodePathMap":[
            {
                    "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
                    "paths":["/opt/local-path-provisioner"]
            }
            ]
    }
  setup: |-
    #!/bin/sh
    set -eu
    mkdir -m 0777 -p "$VOL_DIR"
  teardown: |-
    #!/bin/sh
    set -eu
    rm -rf "$VOL_DIR"
  helperPod.yaml: |-
    apiVersion: v1
    kind: Pod
    metadata:
      name: helper-pod
    spec:
      priorityClassName: system-node-critical
      tolerations:
        - key: node.kubernetes.io/disk-pressure
          operator: Exists
          effect: NoSchedule
      containers:
      - name: helper-pod
        image: busybox
        imagePullPolicy: IfNotPresent
EOF
        kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' &>> "$DEBUG_OUT"
        kubectl label sc local-path $POC_LABEL --overwrite &>> "$DEBUG_OUT"
        ui_spinner_stop "PASS"
        check_k8s_label "sc" "local-path"
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
        check_k8s_label "deployment" "metrics-server" "kube-system"
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
            check_k8s_label "namespace" "metallb-system"
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
            check_k8s_label "namespace" "ingress-nginx"
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
