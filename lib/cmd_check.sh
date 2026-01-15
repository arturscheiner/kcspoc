#!/bin/bash

cmd_check() {
    ui_banner
    ui_section "Environment Check"
    
    local ERROR=0

    # Check 1: Tools
    echo -ne "Checking CLI tools... "
    MISSING_TOOLS=""
    for tool in kubectl helm; do
        if ! command -v $tool &> /dev/null; then
            MISSING_TOOLS="$MISSING_TOOLS $tool"
        fi
    done

    if [ -n "$MISSING_TOOLS" ]; then
        echo -e "${RED}FAIL${NC}"
        echo -e "${RED}Missing required tools:$MISSING_TOOLS${NC}"
        ERROR=1
    else
        echo -e "${GREEN}OK${NC}"
    fi

    # Check 2: Config
    echo -ne "Checking Configuration... "
    if load_config; then
        if [ -z "$NAMESPACE" ] || [ -z "$IP_RANGE" ] || [ -z "$REGISTRY_USER" ]; then
             echo -e "${RED}FAIL (Missing variables in config)${NC}"
             echo "Run 'kcspoc config' to fix this."
             ERROR=1
        else
            echo -e "${GREEN}OK${NC} (Loaded)"
        fi
    else
        echo -e "${RED}FAIL (Config file not found)${NC}"
        echo "Run 'kcspoc config' to create it."
        ERROR=1
    fi

    # Check 3: Cluster Context & Connectivity
    echo -ne "Checking Cluster Connectivity... "
    
    if command -v kubectl &> /dev/null; then
        CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "None")
        echo -e "\n${BLUE}Target Cluster Context: ${YELLOW}${CURRENT_CTX}${NC}"
        echo -e "The KCS installation will target this cluster."
    fi

    echo -ne "Verifying connectivity... "
    if kubectl get nodes &> /dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        echo -e "Could not connect to Kubernetes cluster ${YELLOW}${CURRENT_CTX}${NC}."
        ERROR=1
        return 1
    fi

    # Check 4: Cluster Resources & Topology
    echo -e "\n${YELLOW}=== Cluster Resources & Topology ===${NC}"
    
    # 4.1 Kubernetes Version Check
    echo -ne "Checking Kubernetes Version... "
    K8S_VER_STR=$(kubectl version -o json 2>/dev/null | grep gitVersion | grep -v Client | head -n 1 | awk -F'"' '{print $4}')
    if [ -z "$K8S_VER_STR" ]; then
        K8S_VER_STR=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}')
    fi
    VER_CLEAN=$(echo "$K8S_VER_STR" | sed 's/v//')
    MAJOR=$(echo "$VER_CLEAN" | cut -d. -f1)
    MINOR=$(echo "$VER_CLEAN" | cut -d. -f2)

    if [ "$MAJOR" -eq 1 ] && [ "$MINOR" -ge 25 ] && [ "$MINOR" -le 34 ]; then
         echo -e "${GREEN}${K8S_VER_STR}${NC} (Pass: 1.25 <= v <= 1.34)"
    else
         echo -e "${RED}${K8S_VER_STR}${NC} (FAIL: Supported range 1.25 - 1.34)"
         ERROR=1
    fi

    # 4.2 Architecture Check
    echo -ne "Checking Architecture... "
    ARCH_COUNT=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' | tr ' ' '\n' | sort | uniq -c)
    if echo "$ARCH_COUNT" | grep -q "amd64"; then
         if [ $(echo "$ARCH_COUNT" | wc -l) -eq 1 ]; then
             echo -e "${GREEN}amd64${NC} (Pass)"
         else
             echo -e "${YELLOW}Mixed Architectures detected${NC} (Warning: Core only supports amd64)"
         fi
    else
         echo -e "${RED}No amd64 nodes found${NC} (FAIL)"
         ERROR=1
    fi

    # 4.3 Container Runtime Check
    echo -ne "Checking Container Runtime... "
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
                 echo -e "  - containerd $RT_VER ${GREEN}(OK - 1.6+)${NC}"
             else
                 echo -e "  - containerd $RT_VER ${RED}(FAIL - Min 1.6)${NC}"
                 ERROR=1
             fi
        elif [[ "$RT_NAME" == "cri-o" ]]; then
             if [ "$(check_ver "$RT_VER" "1.24")" == "ok" ]; then
                  echo -e "  - cri-o $RT_VER ${GREEN}(OK - 1.24+)${NC}"
             else
                  echo -e "  - cri-o $RT_VER ${RED}(FAIL - Min 1.24)${NC}"
                  ERROR=1
             fi
        elif [[ "$RT_NAME" == "docker" ]]; then
             echo -e "  - docker ${YELLOW}(Warning: Deprecated)${NC}"
        else
             echo -e "  - $rt ${YELLOW}(Unknown/Untested)${NC}"
        fi
    done
    
    # 4.4 CNI Plugin Check
    echo -ne "Checking CNI Plugin... "
    CNI_PODS=$(kubectl get pods -A --no-headers | grep -E "calico|flannel|cilium|weave|antrea|kube-proxy" | grep "Running" || true)
    
    if [ -n "$CNI_PODS" ]; then
        CNI_NAMES=$(echo "$CNI_PODS" | awk '{print $2}' | grep -oE "calico|flannel|cilium|weave|antrea" | sort | uniq | tr '\n' ' ')
        if [ -z "$CNI_NAMES" ]; then CNI_NAMES="kube-proxy (Standard)"; fi
        echo -e "${GREEN}OK${NC} (Detected: $CNI_NAMES)"
    else
        echo -e "${YELLOW}Warning: No common CNI pods detected.${NC}"
    fi

    # 4.5 Node Resources & Deep Inspection
    echo -e "\n${BLUE}Node Resources (CPU / RAM / Disk / Kernel Headers / eBPF):${NC}"
    
    if [[ "$ENABLE_DEEP_CHECK" == "true" ]]; then
        echo -e "${YELLOW}Running Deep Node Inspection (Privileged Pods)...${NC}"
    else
        echo -e "${YELLOW}(Deep Check Disabled: Basic info only)${NC}"
    fi
    
    printf "%-30s %-15s %-10s %-15s %-15s %-10s %-20s\n" "NODE" "ROLE" "CPU" "RAM" "DISK" "eBPF" "HEADERS"
    echo "----------------------------------------------------------------------------------------------------------------------------------"

    for name in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        
        node_info=$(kubectl get node "$name" -o jsonpath='{.metadata.labels}|{.status.capacity.cpu}|{.status.capacity.memory}')
        IFS='|' read -r labels cpu mem_raw <<< "$node_info"
        unset IFS
        
        if [[ "$labels" == *"node-role.kubernetes.io/control-plane"* ]] || [[ "$labels" == *"node-role.kubernetes.io/master"* ]]; then
            role="control-plane"
        else
            role="worker"
        fi
        
        MEM_KB=$(echo "$mem_raw" | sed 's/[^0-9]*//g')
        if [[ "$mem_raw" == *"Mi"* ]]; then MEM_GB=$((MEM_KB / 1024)); elif [[ "$mem_raw" == *"Gi"* ]]; then MEM_GB=$MEM_KB; else MEM_GB=$((MEM_KB / 1024 / 1024)); fi
        
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

        if [[ "$ENABLE_DEEP_CHECK" == "true" ]]; then
            kubectl apply -f "$POD_FILE" &> /dev/null
            
            sleep 2
            if ! kubectl wait --for=condition=Ready pod/debug-node-${name} --timeout=40s &> /dev/null; then
                DISK_AVAIL="Err-Pod"
                HAS_HEADERS="Err-Pod"
                HAS_EBPF="Err-Pod"
            else
                DISK_AVAIL=$(kubectl exec debug-node-${name} -- chroot /host df -h / | tail -n 1 | awk '{print $4}' 2>/dev/null || echo "N/A")
                
                if kubectl exec debug-node-${name} -- chroot /host test -f /sys/kernel/btf/vmlinux &> /dev/null; then
                     HAS_EBPF="${GREEN}OK${NC}"
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
                     HAS_HEADERS="${RED}Err${NC}"
                fi
            fi

            kubectl delete pod debug-node-${name} --force --grace-period=0 &> /dev/null
        else
            DISK_AVAIL="-"
            HAS_HEADERS="-"
            HAS_EBPF="-"
        fi

        printf "%-30s %-15s %-10s %-15s %-15s %-10s %-20b\n" "$name" "$role" "$cpu" "${MEM_GB}G" "$DISK_AVAIL" "$HAS_EBPF" "$HAS_HEADERS"
    done

    # 4.6 Repo Connectivity
    echo -e "\n${BLUE}Checking Repo Connectivity (repo.kcs.kaspersky.com)...${NC}"
    if kubectl run -i --rm --image=curlimages/curl --restart=Never connectivity-test -- curl -m 5 -I https://repo.kcs.kaspersky.com &> /dev/null; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL${NC}"
         ERROR=1
    fi

    # Global Requirements
    TOTAL_CPU=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.capacity.cpu}{"\n"}{end}' | awk '{s+=$1} END {print s}')
    TOTAL_MEM_KI=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.capacity.memory}{"\n"}{end}' | sed 's/Ki//g' | awk '{s+=$1} END {print s}')
    TOTAL_MEM_GB=$((TOTAL_MEM_KI / 1024 / 1024))
    
    echo -e "\n${YELLOW}Global Cluster Totals:${NC}"
    if [ "$TOTAL_CPU" -ge 4 ]; then echo -e "CPU: ${GREEN}${TOTAL_CPU} vCPUs${NC} (Pass)"; else echo -e "CPU: ${RED}${TOTAL_CPU} vCPUs${NC} (FAIL)"; ERROR=1; fi
    if [ "$TOTAL_MEM_GB" -ge 8 ]; then echo -e "RAM: ${GREEN}~${TOTAL_MEM_GB} GB${NC} (Pass)"; else echo -e "RAM: ${RED}~${TOTAL_MEM_GB} GB${NC} (FAIL)"; ERROR=1; fi

    if [ $ERROR -eq 0 ]; then
        echo -e "\n${GREEN}All checks passed.${NC}"
    else
        echo -e "\n${RED}Checks failed. Please address the issues above.${NC}"
        exit 1
    fi
}
