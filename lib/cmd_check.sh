#!/bin/bash

cmd_check() {
    ui_banner
    
    # --- [1] Prerequisites ---
    ui_section "1. Prerequisites"
    
    local ERROR=0

    # Tools check
    echo -ne "   ${ICON_GEAR} $MSG_CHECK_TOOLS "
    MISSING_TOOLS=""
    for tool in kubectl helm; do
        if ! command -v $tool &> /dev/null; then
            MISSING_TOOLS="$MISSING_TOOLS $tool"
        fi
    done

    if [ -n "$MISSING_TOOLS" ]; then
        echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC}"
        echo -e "      ${RED}${MSG_CHECK_TOOLS_FAIL}:$MISSING_TOOLS${NC}"
        ERROR=1
    else
        echo -e "${GREEN}$MSG_CHECK_LABEL_PASS${NC}"
    fi

    # Config check
    echo -ne "   ${ICON_GEAR} $MSG_CHECK_CONFIG "
    if load_config; then
        if [ -z "$NAMESPACE" ] || [ -z "$IP_RANGE" ] || [ -z "$REGISTRY_USER" ]; then
             echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC}"
             echo -e "      ${YELLOW}$MSG_CHECK_CONFIG_FIX${NC}"
             ERROR=1
        else
            echo -e "${GREEN}$MSG_CHECK_LABEL_PASS${NC} ${DIM}(Loaded)${NC}"
        fi
    else
        echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC}"
        echo -e "      ${YELLOW}$MSG_CHECK_CONFIG_CREATE${NC}"
        ERROR=1
    fi

    # --- [2] Cluster Context ---
    ui_section "2. Cluster Context"
    
    echo -ne "   ${ICON_INFO} $MSG_CHECK_CONN "
    if command -v kubectl &> /dev/null; then
        CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "None")
        echo -e "${BLUE}${CURRENT_CTX}${NC}"
        echo -e "      ${DIM}$MSG_CHECK_CTX_DESC${NC}"
    else
        echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC}"
        ERROR=1
    fi

    echo -ne "   ${ICON_GEAR} $MSG_CHECK_VERIFY_CONN "
    if kubectl get nodes &> /dev/null; then
        echo -e "${GREEN}$MSG_CHECK_LABEL_PASS${NC}"
    else
        echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC}"
        echo -e "      ${RED}${MSG_CHECK_CONN_FAIL}${NC}"
        ERROR=1
        return 1
    fi

    # --- [3] Cluster Topology ---
    ui_section "3. Cluster Topology"
    
    # 3.1 Kubernetes Version
    echo -ne "   ${ICON_GEAR} $MSG_CHECK_K8S_VER "
    K8S_VER_STR=$(kubectl version -o json 2>/dev/null | grep gitVersion | grep -v Client | head -n 1 | awk -F'"' '{print $4}')
    if [ -z "$K8S_VER_STR" ]; then
        K8S_VER_STR=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}')
    fi
    VER_CLEAN=$(echo "$K8S_VER_STR" | sed 's/v//')
    MAJOR=$(echo "$VER_CLEAN" | cut -d. -f1)
    MINOR=$(echo "$VER_CLEAN" | cut -d. -f2)

    if [ "$MAJOR" -eq 1 ] && [ "$MINOR" -ge 25 ] && [ "$MINOR" -le 34 ]; then
         echo -e "${GREEN}$MSG_CHECK_LABEL_PASS${NC} ${BLUE}${K8S_VER_STR}${NC} ${DIM}(1.25 - 1.34)${NC}"
    else
         echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC} ${RED}${K8S_VER_STR}${NC} ${DIM}(Supported: 1.25 - 1.34)${NC}"
         ERROR=1
    fi

    # 3.2 Architecture
    echo -ne "   ${ICON_GEAR} $MSG_CHECK_ARCH "
    ARCH_COUNT=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' | tr ' ' '\n' | sort | uniq -c)
    if echo "$ARCH_COUNT" | grep -q "amd64"; then
         if [ $(echo "$ARCH_COUNT" | wc -l) -eq 1 ]; then
             echo -e "${GREEN}$MSG_CHECK_LABEL_PASS${NC} ${BLUE}amd64${NC}"
         else
             echo -e "${YELLOW}$MSG_CHECK_LABEL_WARN${NC} ${YELLOW}$MSG_CHECK_ARCH_MIXED${NC}"
             echo -e "      ${DIM}$MSG_CHECK_ARCH_WARN${NC}"
         fi
    else
         echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC} ${RED}$MSG_CHECK_ARCH_NONE${NC}"
         ERROR=1
    fi

    # 3.3 Container Runtime
    echo -ne "   ${ICON_GEAR} $MSG_CHECK_RUNTIME "
    RUNTIMES=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}' | tr ' ' '\n' | sort | uniq)
    echo -e "${BLUE}$RUNTIMES${NC}"
    
    for rt in $RUNTIMES; do
        RT_NAME=$(echo "$rt" | awk -F'://' '{print $1}')
        RT_VER=$(echo "$rt" | awk -F'://' '{print $2}')
        
        check_ver() {
             local ver=$1
             local min=$2
             if [ "$(printf '%s\n' "$min" "$ver" | sort -V | head -n1)" = "$min" ]; then echo "ok"; else echo "fail"; fi
        }

        if [[ "$RT_NAME" == "containerd" ]]; then
             if [ "$(check_ver "$RT_VER" "1.6")" == "ok" ]; then
                 echo -e "      - containerd $RT_VER ${GREEN}(OK - 1.6+)${NC}"
             else
                 echo -e "      - containerd $RT_VER ${RED}(FALHA - Min 1.6)${NC}"
                 ERROR=1
             fi
        elif [[ "$RT_NAME" == "cri-o" ]]; then
             if [ "$(check_ver "$RT_VER" "1.24")" == "ok" ]; then
                  echo -e "      - cri-o $RT_VER ${GREEN}(OK - 1.24+)${NC}"
             else
                  echo -e "      - cri-o $RT_VER ${RED}(FALHA - Min 1.24)${NC}"
                  ERROR=1
             fi
        elif [[ "$RT_NAME" == "docker" ]]; then
             echo -e "      - docker ${YELLOW}($MSG_CHECK_LABEL_WARN)${NC}"
        else
             echo -e "      - $rt ${DIM}(Unknown)${NC}"
        fi
    done
    
    # 3.4 CNI Plugin
    echo -ne "   ${ICON_GEAR} $MSG_CHECK_CNI "
    CNI_PODS=$(kubectl get pods -A --no-headers | grep -E "calico|flannel|cilium|weave|antrea|kube-proxy" | grep "Running" || true)
    
    if [ -n "$CNI_PODS" ]; then
        CNI_NAMES=$(echo "$CNI_PODS" | awk '{print $2}' | grep -oE "calico|flannel|cilium|weave|antrea" | sort | uniq | tr '\n' ' ')
        if [ -z "$CNI_NAMES" ]; then CNI_NAMES="kube-proxy (Standard)"; fi
        echo -e "${GREEN}$MSG_CHECK_LABEL_PASS${NC} ${DIM}($CNI_NAMES)${NC}"
    else
        echo -e "${YELLOW}$MSG_CHECK_LABEL_WARN${NC} ${DIM}$MSG_CHECK_CNI_WARN${NC}"
    fi

    # --- [4] Cloud Provider & Topology ---
    ui_section "4. Cloud Provider & Topology"
    
    # Get raw data for the first node
    RAW_CLOUD=$(kubectl get nodes -o jsonpath='{.items[0].spec.providerID}|{.items[0].metadata.labels.topology\.kubernetes\.io/region}|{.items[0].metadata.labels.topology\.kubernetes\.io/zone}|{.items[0].status.nodeInfo.osImage}' 2>/dev/null)
    
    IFS='|' read -r PROV_ID REGION ZONE OS_IMG <<< "$RAW_CLOUD"
    unset IFS

    # Detect Provider
    PROVIDER_NAME="$MSG_CHECK_CLOUD_UNKNOWN"
    
    if [[ "$PROV_ID" == *"aws"* ]] || [[ "$OS_IMG" == *"aws"* ]]; then
        PROVIDER_NAME="AWS (EKS)"
    elif [[ "$PROV_ID" == *"azure"* ]] || [[ "$OS_IMG" == *"azure"* ]]; then
        PROVIDER_NAME="Azure (AKS)"
    elif [[ "$PROV_ID" == *"gce"* ]] || [[ "$OS_IMG" == *"g1"* ]]; then
        PROVIDER_NAME="Google (GKE)"
    elif [[ "$PROV_ID" == *"oci"* ]]; then
        PROVIDER_NAME="Oracle (OKE)"
    elif [[ "$PROV_ID" == *"digitalocean"* ]]; then
        PROVIDER_NAME="DigitalOcean"
    elif [[ "$PROV_ID" == *"huawei"* ]]; then
        PROVIDER_NAME="Huawei (CCE)"
    elif [[ "$PROV_ID" == *"kind"* ]]; then
        PROVIDER_NAME="Kind (Local)"
    fi
    
    echo -e "   ${ICON_INFO} ${BLUE}${MSG_CHECK_CLOUD_PROVIDER}:${NC} ${GREEN}${PROVIDER_NAME}${NC}"
    echo -e "      ${DIM}- ProviderID : ${PROV_ID:-N/A}${NC}"
    echo -e "      ${DIM}- ${MSG_CHECK_CLOUD_REGION}   : ${NC}${REGION:-N/A}"
    echo -e "      ${DIM}- ${MSG_CHECK_CLOUD_ZONE}     : ${NC}${ZONE:-N/A}"
    echo -e "      ${DIM}- ${MSG_CHECK_CLOUD_OS} : ${NC}${OS_IMG:-N/A}"

    # --- [5] Node Resources & Health ---
    ui_section "5. Node Resources & Health"
    
    if [[ "$ENABLE_DEEP_CHECK" == "true" ]]; then
        echo -e "   ${ICON_GEAR} ${YELLOW}${MSG_CHECK_DEEP_RUN}${NC}"
    else
        echo -e "   ${ICON_INFO} ${DIM}${MSG_CHECK_DEEP_SKIP}${NC}"
    fi
    echo ""
    
    # Table Header
    printf "   ${BOLD}%-25s %-12s %-6s %-8s %-10s %-15s %-15s${NC}\n" "NODE" "ROLE" "CPU" "RAM" "DISK" "eBPF" "HEADERS"
    printf "   ${DIM}%s${NC}\n" "--------------------------------------------------------------------------------------------"

    for name in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        
        node_info=$(kubectl get node "$name" -o jsonpath='{.metadata.labels}|{.status.capacity.cpu}|{.status.capacity.memory}')
        IFS='|' read -r labels cpu mem_raw <<< "$node_info"
        unset IFS
        
        if [[ "$labels" == *"node-role.kubernetes.io/control-plane"* ]] || [[ "$labels" == *"node-role.kubernetes.io/master"* ]]; then
            role="master"
        else
            role="worker"
        fi
        
        MEM_KB=$(echo "$mem_raw" | sed 's/[^0-9]*//g')
        if [[ "$mem_raw" == *"Mi"* ]]; then MEM_GB=$((MEM_KB / 1024)); elif [[ "$mem_raw" == *"Gi"* ]]; then MEM_GB=$MEM_KB; else MEM_GB=$((MEM_KB / 1024 / 1024)); fi
        
        # Deep inspection if enabled
        DISK_AVAIL="-"; HAS_EBPF="${DIM}-${NC}"; HAS_HEADERS="${DIM}-${NC}"

        if [[ "$ENABLE_DEEP_CHECK" == "true" ]]; then
            POD_FILE="$CONFIG_DIR/debug-node-${name}.yaml"
            cat <<EOF > "$POD_FILE"
apiVersion: v1
kind: Pod
metadata:
  name: debug-node-${name}
  namespace: default
spec:
  hostPID: true
  hostIPC: true
  hostNetwork: true
  nodeName: ${name}
  restartPolicy: Never
  containers:
  - name: debug-container
    image: ubuntu:latest
    command: ["sleep", "infinity"]
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /host
      name: host-volume
  volumes:
  - name: host-volume
    hostPath:
      path: /
  terminationGracePeriodSeconds: 1
EOF
            kubectl apply -f "$POD_FILE" &> /dev/null
            
            sleep 2
            if ! kubectl wait --for=condition=Ready pod/debug-node-${name} --timeout=15s &> /dev/null; then
                DISK_AVAIL="${RED}ERR${NC}"
                HAS_EBPF="${RED}ERR${NC}"
                HAS_HEADERS="${RED}ERR${NC}"
            else
                DISK_AVAIL=$(kubectl exec debug-node-${name} -- chroot /host df -h / 2>/dev/null | tail -n 1 | awk '{print $4}' || echo "N/A")
                
                if kubectl exec debug-node-${name} -- chroot /host test -f /sys/kernel/btf/vmlinux &> /dev/null; then
                     HAS_EBPF="${GREEN}YES${NC}"
                else
                     HAS_EBPF="${RED}NO${NC}"
                fi

                if HEADERS_OUT=$(kubectl exec "debug-node-${name}" -- /bin/bash -c "chroot /host sh -c 'dpkg -l 2>/dev/null | grep -i headers || rpm -qa 2>/dev/null | grep -i headers'" 2>/dev/null); then
                     if [ -n "$HEADERS_OUT" ]; then
                         HAS_HEADERS="${GREEN}YES${NC}"
                     else
                         HAS_HEADERS="${RED}NO${NC}"
                     fi
                else
                     HAS_HEADERS="${RED}ERR${NC}"
                fi
            fi
            kubectl delete pod debug-node-${name} --force --grace-period=0 &> /dev/null
        fi

        printf "   %-25s %-12s %-6s %-8s %-10s %-25b %-25b\n" "$name" "$role" "$cpu" "${MEM_GB}G" "$DISK_AVAIL" "$HAS_EBPF" "$HAS_HEADERS"
    done

    # --- [6] Hardware Compliance Audit (Detailed) ---
    ui_section "6. $MSG_AUDIT_TITLE"
    
    # Constants (POC Min / Ideal)
    local MIN_CPU=4000      # 4 vCPUs (in millicores)
    local MIN_RAM=7680      # 8 GB (approx 7.5GiB in MiB)
    local MIN_DISK=80       # 80 GB (in GiB)
    
    # Reference Table
    echo -e "   ${BOLD}$MSG_AUDIT_REF_TABLE:${NC}"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_RES" "$MSG_AUDIT_MIN" "$MSG_AUDIT_IDEAL"
    printf "   %-20s | %-15s | %-15s\n" "--------------------" "---------------" "---------------"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_CPU" "4 Cores" "12 Cores"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_RAM" "8 GB" "20 GB"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_DISK" "80 GB" "150 GB"
    echo ""

    local CLUSTER_PASS=true
    local NODE_NAMES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

    for name in $NODE_NAMES; do
        # Get allocatable resources. Note: ephemeral-storage might not be present on some nodes/versions
        local RAW_RES=$(kubectl get node "$name" -o jsonpath='{.status.allocatable.cpu}|{.status.allocatable.memory}|{.status.allocatable.ephemeral-storage}')
        
        IFS='|' read -r CPU_ALLOC MEM_ALLOC DISK_ALLOC <<< "$RAW_RES"
        unset IFS
        
        # CPU: convert to millicores
        local CPU_MILLI=0
        if [[ "$CPU_ALLOC" == *m ]]; then CPU_MILLI=${CPU_ALLOC%m}; else CPU_MILLI=$((CPU_ALLOC * 1000)); fi
        
        # RAM: convert to MiB
        local MEM_CLEAN=$(echo "$MEM_ALLOC" | sed 's/[^0-9]*//g') # Remove units like Ki, Mi, Gi
        local MEM_MIB=0
        # Kubectl usually returns Ki for memory. Let's handle Ki, Mi, Gi.
        if [[ "$MEM_ALLOC" == *Gi ]]; then MEM_MIB=$((MEM_CLEAN * 1024)); 
        elif [[ "$MEM_ALLOC" == *Mi ]]; then MEM_MIB=$MEM_CLEAN;
        elif [[ "$MEM_ALLOC" == *Ki ]]; then MEM_MIB=$((MEM_CLEAN / 1024));
        else MEM_MIB=$((MEM_CLEAN / 1024 / 1024)); fi # bytes
        
        # Disk: convert to GiB. If empty (unreported), treat as 0 or skip? Let's treat as 0 and warn.
        local DISK_GIB=0
        local DISK_CLEAN=$(echo "$DISK_ALLOC" | sed 's/[^0-9]*//g')
        if [ -n "$DISK_ALLOC" ]; then
            if [[ "$DISK_ALLOC" == *Gi ]]; then DISK_GIB=$DISK_CLEAN;
            elif [[ "$DISK_ALLOC" == *Ki ]]; then DISK_GIB=$((DISK_CLEAN / 1024 / 1024));
            else DISK_GIB=$((DISK_CLEAN / 1024 / 1024 / 1024)); fi # bytes
        fi

        local FAIL_REASONS=""
        
        # Check CPU
        if [ "$CPU_MILLI" -lt "$MIN_CPU" ]; then
            FAIL_REASONS+="${RED}      ✖ $(printf "$MSG_AUDIT_FAIL_CPU" "$((CPU_MILLI/1000))" "4")${NC}\n"
            FAIL_REASONS+="        -> $MSG_AUDIT_CAUSE_CPU\n"
        fi
        
        # Check RAM
        if [ "$MEM_MIB" -lt "$MIN_RAM" ]; then
            FAIL_REASONS+="${RED}      ✖ $(printf "$MSG_AUDIT_FAIL_RAM" "$MEM_MIB" "7680")${NC}\n" # 7680 MiB = ~8GB
            FAIL_REASONS+="        -> $MSG_AUDIT_CAUSE_RAM\n"
        fi
        
        # Check Disk
        if [ "$DISK_GIB" -lt "$MIN_DISK" ]; then
             if [ "$DISK_GIB" -eq 0 ]; then
                 # Disk info missing often implies cloud managed or special config. Warn but maybe don't fail hard if unsure? 
                 # User script fails hard. I will fail hard too to be safe.
                 FAIL_REASONS+="${RED}      ✖ $(printf "$MSG_AUDIT_FAIL_DISK" "0 (Unknown)" "80")${NC}\n"
             else
                 FAIL_REASONS+="${RED}      ✖ $(printf "$MSG_AUDIT_FAIL_DISK" "$DISK_GIB" "80")${NC}\n"
             fi
             FAIL_REASONS+="        -> $MSG_AUDIT_CAUSE_DISK\n"
        fi

        if [ -n "$FAIL_REASONS" ]; then
            CLUSTER_PASS=false
            echo -e "   ${BOLD}$MSG_AUDIT_NODE_EVAL: $name${NC} ${RED}$MSG_AUDIT_REJECTED${NC}"
            echo -e "$FAIL_REASONS"
            echo -e "      ${DIM}Recursos: ${CPU_MILLI}m CPU | ${MEM_MIB}Mi RAM | ${DISK_GIB}Gi Disk${NC}"
            echo "   ----------------------------------------------------"
        fi
    done

    if [ "$CLUSTER_PASS" = true ]; then
        echo -e "   ${GREEN}$MSG_AUDIT_SUCCESS${NC}"
    else
        echo -e "   ${RED}$MSG_AUDIT_FAIL${NC}"
        echo -e "   ${YELLOW}$MSG_AUDIT_REC${NC}"
        ERROR=1
    fi

    # --- [7] Connectivity Test ---
    ui_section "7. Repository Connectivity"
    
    echo -ne "   ${ICON_GEAR} $MSG_CHECK_REPO_CONN... "
    if kubectl run -i --rm --image=curlimages/curl --restart=Never kcspoc-repo-connectivity-test -- curl -m 5 -I https://repo.kcs.kaspersky.com &> /dev/null; then
         echo -e "${GREEN}$MSG_CHECK_LABEL_PASS${NC}"
    else
         echo -e "${RED}$MSG_CHECK_LABEL_FAIL${NC}"
         ERROR=1
    fi

    # --- Results ---
    ui_section "Summary Results"
    
    TOTAL_CPU=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.capacity.cpu}{"\n"}{end}' | awk '{s+=$1} END {print s}')
    TOTAL_MEM_KI=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.capacity.memory}{"\n"}{end}' | sed 's/Ki//g' | awk '{s+=$1} END {print s}')
    TOTAL_MEM_GB=$((TOTAL_MEM_KI / 1024 / 1024))
    
    echo -ne "   ${ICON_INFO} $MSG_CHECK_GLOBAL_TOTALS: "
    echo -e "${BLUE}$TOTAL_CPU vCPUs / ${TOTAL_MEM_GB} GB RAM${NC}"

    if [ "$TOTAL_CPU" -lt 4 ] || [ "$TOTAL_MEM_GB" -lt 8 ]; then
         echo -e "      ${RED}$MSG_CHECK_LABEL_FAIL${NC} ${RED}Minimum requirements not met (4 vCPU / 8 GB RAM)${NC}"
         ERROR=1
    else
         echo -e "      ${GREEN}$MSG_CHECK_LABEL_PASS${NC} ${DIM}Meets minimum requirements.${NC}"
    fi

    echo ""
    if [ $ERROR -eq 0 ]; then
        echo -e "${GREEN}${BOLD}${ICON_OK} $MSG_CHECK_ALL_PASS${NC}"
        echo -e "${DIM}Your cluster is ready for Kaspersky Container Security installation.${NC}"
    else
        echo -e "${RED}${BOLD}${ICON_FAIL} $MSG_CHECK_FINAL_FAIL${NC}"
        exit 1
    fi
}
