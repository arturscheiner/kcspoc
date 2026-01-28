#!/bin/bash

# ==============================================================================
# Layer: Service
# File: check_service.sh
# Responsibility: Business logic for diagnostics and resource audits
# ==============================================================================

service_check_validate_prereqs() {
    local error=0

    # 1. Kubeconfig
    view_check_step_start "$MSG_CHECK_KUBECONFIG"
    if [ ! -f "$HOME/.kube/config" ]; then
        view_check_step_stop "FAIL"
        view_check_prereq_kubeconfig_fail
        error=1
    else
        view_check_step_stop "PASS"
    fi

    # 2. Tools
    view_check_step_start "$MSG_CHECK_TOOLS"
    local missing_tools=""
    for tool in kubectl helm jq; do
        if ! command -v "$tool" &>> "$DEBUG_OUT"; then
            missing_tools="$missing_tools $tool"
        fi
    done

    if [ -n "$missing_tools" ]; then
        view_check_step_stop "FAIL"
        view_check_prereq_tools_fail "$missing_tools"
        error=1
    else
        view_check_step_stop "PASS"
    fi

    # 3. Config
    view_check_step_start "$MSG_CHECK_CONFIG"
    if model_fs_load_config; then
        if [ -z "$NAMESPACE" ] || [ -z "$IP_RANGE" ] || [ -z "$REGISTRY_USER" ]; then
             view_check_step_stop "FAIL"
             view_check_prereq_config_fix
             error=1
        else
            view_check_step_stop "PASS"
        fi
    else
        view_check_step_stop "FAIL"
        view_check_prereq_config_create
        error=1
    fi

    return $error
}

service_check_context() {
    view_check_step_start "$MSG_CHECK_CTX"
    local ctx
    ctx=$(model_cluster_get_current_context)
    if [ "$ctx" == "None" ]; then
        view_check_step_stop "FAIL"
        return 1
    fi
    view_check_step_stop "PASS"
    view_check_info_ctx "$ctx"

    view_check_step_start "${MSG_CHECK_CONN_VERIFY:-Verifying Cluster Connectivity}"
    local conn_err="/tmp/kcspoc_conn_err.tmp"
    if model_cluster_verify_connectivity "$conn_err"; then
        view_check_step_stop "PASS"
        return 0
    else
        view_check_step_stop "FAIL"
        local err_msg=$(grep -v "memcache.go" "$conn_err" | grep -v "^E[0-9]\{4\}" | tail -n 2)
        [ -z "$err_msg" ] && err_msg=$(tail -n 1 "$conn_err")
        view_check_conn_error "$err_msg"
        cat "$conn_err" >> "$DEBUG_OUT"
        return 1
    fi
}

service_check_topology() {
    local error=0
    
    # 1. K8s Version
    view_check_step_start "$MSG_CHECK_K8S_VER"
    local ver_str
    ver_str=$(model_cluster_get_version)
    local ver_clean=$(echo "$ver_str" | sed 's/v//')
    local major=$(echo "$ver_clean" | cut -d. -f1)
    local minor=$(echo "$ver_clean" | cut -d. -f2)

    if [ "$major" -eq 1 ] && [ "$minor" -ge 25 ] && [ "$minor" -le 34 ]; then
         view_check_step_stop "PASS"
         view_check_k8s_ver_info "$ver_str" "PASS"
    else
         view_check_step_stop "FAIL"
         view_check_k8s_ver_info "$ver_str" "FAIL"
         error=1
    fi

    # 2. Architecture
    view_check_step_start "$MSG_CHECK_ARCH"
    local arch_count
    arch_count=$(model_cluster_get_architectures)
    if echo "$arch_count" | grep -q "amd64"; then
         view_check_step_stop "PASS"
         if [ $(echo "$arch_count" | wc -l) -gt 1 ]; then
             view_check_arch_mixed_warn
         fi
    else
         view_check_step_stop "FAIL"
         view_check_arch_none_err
         error=1
    fi

    # 3. Runtime
    view_check_step_start "$MSG_CHECK_RUNTIME"
    local runtimes
    runtimes=$(model_cluster_get_runtimes)
    view_check_step_stop "PASS"
    view_check_runtime_info "$runtimes"
    
    for rt in $runtimes; do
        local rt_name=$(echo "$rt" | awk -F'://' '{print $1}')
        local rt_ver=$(echo "$rt" | awk -F'://' '{print $2}')
        
        _check_ver_lte() {
             local v=$1; local m=$2
             if [ "$(printf '%s\n' "$m" "$v" | sort -V | head -n1)" = "$m" ]; then echo "ok"; else echo "fail"; fi
        }

        if [[ "$rt_name" == "containerd" ]]; then
             local status=$(_check_ver_lte "$rt_ver" "1.6")
             view_check_runtime_ver_status "containerd" "$rt_ver" "1.6" "$status"
             [ "$status" == "fail" ] && error=1
        elif [[ "$rt_name" == "cri-o" ]]; then
             local status=$(_check_ver_lte "$rt_ver" "1.24")
             view_check_runtime_ver_status "cri-o" "$rt_ver" "1.24" "$status"
             [ "$status" == "fail" ] && error=1
        elif [[ "$rt_name" == "docker" ]]; then
             view_check_runtime_docker_warn
        else
             view_check_runtime_unknown "$rt"
        fi
    done
    
    # 4. CNI
    view_check_step_start "$MSG_CHECK_CNI"
    local cni_pods
    cni_pods=$(model_cluster_get_cni_pods)
    if [ -n "$cni_pods" ]; then
        local cni_names=$(echo "$cni_pods" | awk '{print $2}' | grep -oE "calico|flannel|cilium|weave|antrea" | sort | uniq | tr '\n' ' ')
        [ -z "$cni_names" ] && cni_names="kube-proxy (Standard)"
        view_check_step_stop "PASS"
        view_check_cni_info "$cni_names"
    else
        view_check_step_stop "PASS"
        view_check_cni_warn
    fi

    return $error
}

service_check_infrastructure() {
    view_check_infra_header
    view_check_infra_item "Cert-Manager" "$([ $(model_cluster_get_infrastructure_status "namespace" "cert-manager") ] && echo "INSTALLED" || echo "MISSING")"
    view_check_infra_item "MetalLB" "$([ $(model_cluster_get_infrastructure_status "namespace" "metallb-system") ] && echo "INSTALLED" || echo "MISSING")"
    view_check_infra_item "Ingress-Nginx" "$([ $(model_cluster_get_infrastructure_status "namespace" "ingress-nginx") ] && echo "INSTALLED" || echo "MISSING")"
    view_check_infra_item "Local Path Storage" "$([ $(model_cluster_get_infrastructure_status "namespace" "local-path-storage") ] && echo "INSTALLED" || echo "MISSING")"
    view_check_infra_item "Metrics Server" "$([ $(model_cluster_get_infrastructure_status "deployment" "metrics-server" "kube-system") ] && echo "INSTALLED" || echo "MISSING")"
    echo ""
}

service_check_cloud_and_cri() {
    local raw_cloud
    raw_cloud=$(model_cluster_get_raw_provider_data)
    
    IFS='|' read -r prov_id region zone os_img <<< "$raw_cloud"
    unset IFS

    local provider_name="$MSG_CHECK_CLOUD_UNKNOWN"
    if [[ "$prov_id" == *"aws"* ]] || [[ "$os_img" == *"aws"* ]]; then provider_name="AWS (EKS)"
    elif [[ "$prov_id" == *"azure"* ]] || [[ "$os_img" == *"azure"* ]]; then provider_name="Azure (AKS)"
    elif [[ "$prov_id" == *"gce"* ]] || [[ "$os_img" == *"g1"* ]]; then provider_name="Google (GKE)"
    elif [[ "$prov_id" == *"oci"* ]]; then provider_name="Oracle (OKE)"
    elif [[ "$prov_id" == *"digitalocean"* ]]; then provider_name="DigitalOcean"
    elif [[ "$prov_id" == *"huawei"* ]]; then provider_name="Huawei (CCE)"
    elif [[ "$prov_id" == *"kind"* ]]; then provider_name="Kind (Local)"
    fi
    
    view_check_cloud_provider_info "$provider_name" "$prov_id" "$region" "$zone" "$os_img"

    # CRI Discovery
    view_check_cri_detecting
    local runtime_ver
    runtime_ver=$(model_cluster_get_runtimes | head -n 1) # Simple heuristic for discovery UI
    
    if [ -n "$runtime_ver" ]; then
        local socket=""
        local type=""
        if [[ "$runtime_ver" == *"containerd"* ]]; then socket="/run/containerd/containerd.sock"; type="containerd"
        elif [[ "$runtime_ver" == *"cri-o"* ]]; then socket="/run/crio/crio.sock"; type="CRI-O"
        elif [[ "$runtime_ver" == *"docker"* ]]; then socket="/var/run/cri-dockerd.sock"; type="Docker (via cri-dockerd)"
        fi
        view_check_cri_info "$type" "$runtime_ver" "$socket"
    fi
}

service_check_resources() {
    local deep_enabled="$1"
    local deep_ns="$2"
    local node_data_file="/tmp/kcspoc_nodes.tmp"
    > "$node_data_file"

    if [ "$deep_enabled" == "true" ]; then
        view_check_step_start "${MSG_CHECK_DEEP_RUN}"
        view_check_deep_run_info "$deep_ns"
    else
        view_check_deep_skip_info
    fi

    local raw_api
    raw_api=$(model_node_get_raw_baseline_data)
    local deep_confirmed_socket=""

    while IFS='|' read -r name labels cpu_a cpu_c mem_a mem_c disk_a disk_c; do
        [ -z "$name" ] && continue

        local role="worker"
        [[ "$labels" == *"node-role.kubernetes.io/control-plane"* ]] || [[ "$labels" == *"node-role.kubernetes.io/master"* ]] && role="master"
        
        local cpu_a_m; [[ "$cpu_a" == *m ]] && cpu_a_m=${cpu_a%m} || cpu_a_m=$((cpu_a * 1000))
        local cpu_c_m; [[ "$cpu_c" == *m ]] && cpu_c_m=${cpu_c%m} || cpu_c_m=$((cpu_c * 1000))
        
        _to_mib() {
            local val=$(echo "$1" | sed 's/[^0-9]*//g'); [ -z "$val" ] && { echo 0; return; }
            if [[ "$1" == *Gi ]]; then echo $((val * 1024)); elif [[ "$1" == *Mi ]]; then echo $val; 
            elif [[ "$1" == *Ki ]]; then echo $((val / 1024)); else echo $((val / 1024 / 1024)); fi
        }
        local mem_a_m=$(_to_mib "$mem_a")
        local mem_c_m=$(_to_mib "$mem_c")

        _to_gib() {
            local val=$(echo "$1" | sed 's/[^0-9]*//g'); [ -z "$val" ] && { echo 0; return; }
            if [[ "$1" == *Gi ]]; then echo $val; elif [[ "$1" == *Ki ]]; then echo $((val / 1024 / 1024)); else echo $((val / 1024 / 1024 / 1024)); fi
        }
        local disk_a_g=$(_to_gib "$disk_a")
        local disk_c_g=$(_to_gib "$disk_c")
        
        local ebpf="-"
        local headers="-"
        local disk_disp="${disk_a_g}/${disk_c_g}G"
        local disk_val=$disk_a_g

        if [ "$deep_enabled" == "true" ]; then
            local pod_name="kcspoc-deep-check-${name}"
            local pod_file="$CONFIG_DIR/${pod_name}.yaml"
            if ! model_node_deploy_probe_pod "$pod_name" "$deep_ns" "$name" "$pod_file" 2>/dev/null; then
                 ebpf="${RED}ERR (Apply)${NC}"; headers="${RED}ERR (Apply)${NC}"; disk_disp="${RED}ERR (Apply)${NC}"; disk_val=0
            else
                sleep 2
                if model_node_wait_probe_pod "$pod_name" "$deep_ns" "15s"; then
                    # Disk
                    local disk_block
                    disk_block=$(model_node_exec_probe "$pod_name" "$deep_ns" chroot /host df -B1 / 2>> "$DEBUG_OUT" | tail -n 1)
                    local b_avail=$(echo "$disk_block" | awk '{print $4}')
                    local b_total=$(echo "$disk_block" | awk '{print $2}')
                    if [ -n "$b_avail" ] && [ -n "$b_total" ]; then
                        local g_avail=$((b_avail / 1024 / 1024 / 1024))
                        local g_total=$((b_total / 1024 / 1024 / 1024))
                        disk_val=$g_avail
                        disk_disp="${BOLD}${GREEN}${g_avail}${NC}/${g_total}G"
                    fi
                    # eBPF
                    if model_node_exec_probe "$pod_name" "$deep_ns" chroot /host test -f /sys/kernel/btf/vmlinux &>> "$DEBUG_OUT"; then
                        ebpf="${GREEN}YES${NC}"
                    else
                        ebpf="${RED}NO${NC}"
                    fi
                    # Headers
                    local headers_out
                    headers_out=$(model_node_exec_probe "$pod_name" "$deep_ns" /bin/bash -c "chroot /host sh -c 'dpkg -l 2>/dev/null | grep -i headers || rpm -qa 2>/dev/null | grep -i headers'" 2>/dev/null)
                    [ -n "$headers_out" ] && headers="${GREEN}YES${NC}" || headers="${RED}NO${NC}"
                    # CRI Socket
                    if [ -z "$deep_confirmed_socket" ]; then
                         local s_raw
                         s_raw=$(model_node_exec_probe "$pod_name" "$deep_ns" /bin/bash -c "tr '\0' ' ' < /proc/\$(pgrep kubelet | head -n 1)/cmdline 2>/dev/null | grep -oP '\-\-container-runtime-endpoint=\K[^ ]+' || cat /host/var/lib/kubelet/kubeadm-flags.env 2>/dev/null | grep -oP '\-\-container-runtime-endpoint=\K[^ ]+'" 2>/dev/null)
                         [ -n "$s_raw" ] && deep_confirmed_socket="${s_raw#unix://}"
                    fi
                else
                    disk_disp="${RED}ERR (Wait)${NC}"; ebpf="${RED}ERR (Wait)${NC}"; headers="${RED}ERR (Wait)${NC}"; disk_val=0
                fi
                model_node_delete_probe_pod "$pod_name" "$deep_ns"
            fi
        fi
        echo "$name|$role|$cpu_a_m|$cpu_c_m|$mem_a_m|$mem_c_m|$disk_val|$disk_disp|$ebpf|$headers" >> "$node_data_file"
    done <<< "$raw_api"
    
    if [ "$deep_enabled" == "true" ]; then
        view_check_step_stop "PASS"
        [ -n "$deep_confirmed_socket" ] && view_check_cri_confirmed "$deep_confirmed_socket"
        echo ""
    fi

    # Render Table
    view_check_node_table_header
    while IFS='|' read -r name role cpu_a_m cpu_c_m mem_a_m mem_c_m disk_val disk_disp ebpf headers; do
        [ -z "$name" ] && continue
        view_check_node_table_row "$name" "$role" "$((cpu_a_m/1000))/$((cpu_c_m/1000))" "$((mem_a_m/1024))/$((mem_c_m/1024))G" "$disk_disp" "$ebpf" "$headers"
    done < "$node_data_file"

    # Perfrom Audit
    service_check_perform_audit "$node_data_file"
}

service_check_perform_audit() {
    local data_file="$1"
    view_check_section_title "" "$MSG_AUDIT_TITLE"
    view_check_audit_header
    
    local cluster_pass=true
    local min_cpu=4000; local min_ram=7680; local min_disk=80
    
    while IFS='|' read -r name role cpu_a_m cpu_c_m mem_a_m mem_c_m disk_val disk_disp ebpf headers; do
        [ -z "$name" ] && continue
        local fail_reasons=""
        [ "$cpu_a_m" -lt "$min_cpu" ] && { fail_reasons+="$(printf "$MSG_AUDIT_FAIL_CPU" "$((cpu_a_m/1000))" "4")|CAUSE:$MSG_AUDIT_CAUSE_CPU\n"; }
        [ "$mem_a_m" -lt "$min_ram" ] && { fail_reasons+="$(printf "$MSG_AUDIT_FAIL_RAM" "$mem_a_m" "7680")|CAUSE:$MSG_AUDIT_CAUSE_RAM\n"; }
        [ "$disk_val" -lt "$min_disk" ] && { local d_v_s="$disk_val"; [ "$disk_val" -eq 0 ] && d_v_s="0 (Unknown)"; fail_reasons+="$(printf "$MSG_AUDIT_FAIL_DISK" "$d_v_s" "80")|CAUSE:$MSG_AUDIT_CAUSE_DISK\n"; }

        if [ -n "$fail_reasons" ]; then
            cluster_pass=false
            view_check_audit_node_rejected "$name" "$fail_reasons" "$((cpu_a_m/1000)) Cores | $((mem_a_m/1024))Gi RAM | ${disk_val}Gi Disk" "$((cpu_c_m/1000)) Cores | $((mem_c_m/1024))Gi RAM | (varies)"
        fi
    done < "$data_file"
    
    if [ "$cluster_pass" = true ]; then view_check_audit_success; else view_check_audit_fail; fi
    return 0
}

service_check_repo_connectivity() {
    local ns="$1"
    view_check_step_start "$MSG_CHECK_REPO_CONN"
    if model_network_verify_repo_connectivity "$ns"; then
        view_check_step_stop "PASS"
        return 0
    else
        view_check_step_stop "FAIL"
        return 1
    fi
}

service_check_summary() {
    local totals
    totals=$(model_node_get_global_totals)
    IFS='|' read -r total_cpu total_mem_gb <<< "$totals"
    
    local error=0
    if [ "$total_cpu" -lt 4 ] || [ "$total_mem_gb" -lt 8 ]; then
         view_check_global_totals "$total_cpu" "$total_mem_gb" "FAIL" "Minimum requirements not met (4 vCPU / 8 GB RAM)"
         error=1
    else
         view_check_global_totals "$total_cpu" "$total_mem_gb" "PASS" "Meets minimum requirements."
    fi
    return $error
}

# AI-Integrated Fact Collection (S-030)
# This function aggregates cluster telemetry into an evaluation-neutral JSON object.
# It MUST NOT print to stdout.
service_check_collect_facts() {
    local deep_enabled="${1:-false}"
    local deep_ns="${2:-kcspoc}"
    
    # --- 1. Cluster Topology ---
    local k8s_ver=$(model_cluster_get_version)
    local raw_archs=$(model_cluster_get_architectures | awk '{$1=""; print $0}' | xargs)
    local all_archs=$(echo "$raw_archs" | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | xargs)
    local primary_arch=$(echo "$all_archs" | awk '{print $1}')
    
    local runtimes=$(model_cluster_get_runtimes | tr '\n' ' ' | xargs)
    local primary_runtime=$(echo "$runtimes" | awk -F'://' '{print $1}')
    
    local helm_ver=$(model_cluster_get_helm_version)
    local default_sc=$(model_cluster_get_default_storageclass)
    local cni_pods=$(model_cluster_get_cni_pods)
    local cni_names="Unknown"
    [ -n "$cni_pods" ] && cni_names=$(echo "$cni_pods" | awk '{print $2}' | grep -oE "calico|flannel|cilium|weave|antrea" | sort | uniq | tr '\n' ' ' | xargs)
    [ -z "$cni_names" ] && cni_names="kube-proxy (Standard)"

    # --- 2. Programmatic Evaluation Logic ---
    
    # K8s Version (1.21 - 1.34)
    local k8s_comp="true"; local k8s_fail=""
    local v_clean=$(echo "$k8s_ver" | sed 's/v//'); local major=$(echo "$v_clean" | cut -d. -f1); local minor=$(echo "$v_clean" | cut -d. -f2)
    if [ "$major" -ne 1 ] || [ "$minor" -lt 21 ] || [ "$minor" -gt 34 ]; then
        k8s_comp="false"; k8s_fail="Kubernetes $k8s_ver is outside supported range (1.21-1.34)."
    fi

    # Architecture (AMD64)
    local arch_comp="true"; local arch_fail=""
    if [[ "$primary_arch" != "amd64" ]]; then
        arch_comp="false"; arch_fail="Primary architecture $primary_arch is not supported (AMD64 required)."
    fi

    # CNI (NetworkPolicy support check - semantic)
    local cni_comp="true"; local cni_fail=""
    if [[ "$cni_names" == *"flannel"* ]] && [[ "$cni_names" != *"calico"* ]]; then
        cni_comp="false"; cni_fail="Flannel CNI detected. NetworkPolicies (microsegmentation) will NOT be enforced."
    fi

    # StorageClass
    local sc_comp="true"; local sc_fail=""
    if [ -z "$default_sc" ]; then
        sc_comp="false"; sc_fail="No default StorageClass found. Dynamic PVC provisioning will fail."
    fi

    # Infrastructure
    local infra_json="{}"
    for item in "cert-manager" "metallb-system" "ingress-nginx" "local-path-storage"; do
        local status="MISSING"
        [ -n "$(model_cluster_get_infrastructure_status "namespace" "$item")" ] && status="INSTALLED"
        infra_json=$(echo "$infra_json" | jq -c ". + {\"$item\": \"$status\"}")
    done
    local metrics_status="MISSING"
    [ -n "$(model_cluster_get_infrastructure_status "deployment" "metrics-server" "kube-system")" ] && metrics_status="INSTALLED"
    infra_json=$(echo "$infra_json" | jq -c ". + {\"metrics-server\": \"$metrics_status\"}")

    # Cloud Provider
    local raw_cloud=$(model_cluster_get_raw_provider_data)
    IFS='|' read -r prov_id region zone os_img <<< "$raw_cloud"
    unset IFS
    
    # Global Connectivity
    local registry_conn="false"; local reg_fail="Cluster cannot reach repo.kcs.kaspersky.com."
    if model_network_verify_repo_connectivity "$deep_ns" &>/dev/null; then
        registry_conn="true"; reg_fail=""
    fi

    # --- 3. Nodes & Resources ---
    local nodes_json="[]"
    local raw_nodes=$(model_node_get_raw_baseline_data)
    local total_cpu_m=0; local total_mem_mib=0; local total_disk_gib=0

    while IFS='|' read -r name labels cpu_a cpu_c mem_a mem_c disk_a disk_c kernel_ver; do
        [ -z "$name" ] && continue
        local role="worker"
        [[ "$labels" == *"node-role.kubernetes.io/control-plane"* ]] || [[ "$labels" == *"node-role.kubernetes.io/master"* ]] && role="master"
        
        local cpu_val; [[ "$cpu_a" == *m ]] && cpu_val=${cpu_a%m} || cpu_val=$((cpu_a * 1000))
        _to_mib() {
            local val=$(echo "$1" | sed 's/[^0-9]*//g'); [ -z "$val" ] && { echo 0; return; }
            if [[ "$1" == *Gi ]]; then echo $((val * 1024)); elif [[ "$1" == *Mi ]]; then echo $val; 
            elif [[ "$1" == *Ki ]]; then echo $((val / 1024)); else echo $((val / 1024 / 1024)); fi
        }
        local mem_mib=$(_to_mib "$mem_a")
        _to_gib() {
            local val=$(echo "$1" | sed 's/[^0-9]*//g'); [ -z "$val" ] && { echo 0; return; }
            if [[ "$1" == *Gi ]]; then echo $val; elif [[ "$1" == *Ki ]]; then echo $((val / 1024 / 1024)); else echo $((val / 1024 / 1024 / 1024)); fi
        }
        local disk_gib=$(_to_gib "$disk_a")

        total_cpu_m=$((total_cpu_m + cpu_val)); total_mem_mib=$((total_mem_mib + mem_mib)); total_disk_gib=$((total_disk_gib + disk_gib))

        local ebpf_status="UNKNOWN"; local headers_status="MISSING"
        if [ "$deep_enabled" == "true" ]; then
            local pod_name="kcspoc-fact-collect-${name}"
            if model_node_deploy_probe_pod "$pod_name" "$deep_ns" "$name" "$CONFIG_DIR/${pod_name}.yaml" 2>/dev/null; then
                sleep 2
                if model_node_wait_probe_pod "$pod_name" "$deep_ns" "15s"; then
                    local disk_block=$(model_node_exec_probe "$pod_name" "$deep_ns" chroot /host df -B1 / 2>/dev/null | tail -n 1)
                    local b_avail=$(echo "$disk_block" | awk '{print $4}')
                    [ -n "$b_avail" ] && disk_gib=$((b_avail / 1024 / 1024 / 1024))
                    
                    # eBPF Mapping
                    model_node_exec_probe "$pod_name" "$deep_ns" chroot /host test -f /sys/kernel/btf/vmlinux && ebpf_status="READY" || ebpf_status="INCOMPATIBLE"
                    
                    # Headers Mapping
                    local headers_out=$(model_node_exec_probe "$pod_name" "$deep_ns" /bin/bash -c "chroot /host sh -c 'dpkg -l 2>/dev/null | grep -i headers || rpm -qa 2>/dev/null | grep -i headers'" 2>/dev/null)
                    [ -n "$headers_out" ] && headers_status="INSTALLED" || headers_status="MISSING"
                fi
                model_node_delete_probe_pod "$pod_name" "$deep_ns"
            fi
        fi

        # Privilege Requirement (Kernel >= 5.8)
        local priv_req="false"
        local k_major=$(echo "$kernel_ver" | cut -d. -f1)
        local k_minor=$(echo "$kernel_ver" | cut -d. -f2)
        if [ "$k_major" -gt 5 ] || { [ "$k_major" -eq 5 ] && [ "$k_minor" -ge 8 ]; }; then
            priv_req="true"
        fi

        nodes_json=$(echo "$nodes_json" | jq -c ". += [{
            \"name\": \"$name\", 
            \"role\": \"$role\", 
            \"kernel\": \"$kernel_ver\",
            \"cpu_cores\": $((cpu_val / 1000)),
            \"ram_gib\": $((mem_mib / 1024)),
            \"disk_gib\": $disk_gib,
            \"ebpf_status\": \"$ebpf_status\", 
            \"headers_status\": \"$headers_status\",
            \"privileged_required\": $priv_req
        }]")
    done <<< "$raw_nodes"

    # Hardware Totals Evaluation
    local cpu_tot_comp="true"; local cpu_tot_fail=""
    [ $((total_cpu_m / 1000)) -lt 12 ] && { cpu_tot_comp="false"; cpu_tot_fail="Total CPU $((total_cpu_m / 1000)) cores is below required 12."; }
    local ram_tot_comp="true"; local ram_tot_fail=""
    [ $((total_mem_mib / 1024)) -lt 20 ] && { ram_tot_comp="false"; ram_tot_fail="Total RAM $((total_mem_mib / 1024)) GiB is below required 20."; }
    local disk_tot_comp="true"; local disk_tot_fail=""
    [ "$total_disk_gib" -lt 40 ] && { disk_tot_comp="false"; disk_tot_fail="Total Disk ${total_disk_gib} GiB is below required 40."; }

    # --- 4. Assemble Programmatic Evaluation Result ---
    echo $(jq -n \
        --arg kv "$k8s_ver" --arg k8s_c "$k8s_comp" --arg k8s_f "$k8s_fail" \
        --arg arc "$primary_arch" --arg arc_c "$arch_comp" --arg arc_f "$arch_fail" \
        --arg rt "$primary_runtime" \
        --arg hv "$helm_ver" \
        --arg dsc "$default_sc" --arg sc_c "$sc_comp" --arg sc_f "$sc_fail" \
        --arg cni "$cni_names" --arg cni_c "$cni_comp" --arg cni_f "$cni_fail" \
        --arg rc "$registry_conn" --arg rc_f "$reg_fail" \
        --arg cpu_t "$((total_cpu_m / 1000))" --arg cpu_c "$cpu_tot_comp" --arg cpu_f "$cpu_tot_fail" \
        --arg mem_t "$((total_mem_mib / 1024))" --arg mem_c "$ram_tot_comp" --arg mem_f "$ram_tot_fail" \
        --arg dsk_t "$total_disk_gib" --arg dsk_c "$disk_tot_comp" --arg dsk_f "$disk_tot_fail" \
        --argjson infra "$infra_json" \
        --argjson nodes "$nodes_json" \
        '{
            evaluation_scope: { environment_type: "PoC", target_product: "Kaspersky Container Security", evaluation_goal: "Readiness Assessment" },
            results: [
              { requirement_id: "KCS-K8S-VER-01", compliant: ($k8s_c == "true"), observed: $kv, failure_reason: $k8s_f },
              { requirement_id: "KCS-ARCH-AMD64-01", compliant: ($arc_c == "true"), observed: $arc, failure_reason: $arc_f },
              { requirement_id: "KCS-RES-CPU-01", compliant: ($cpu_c == "true"), observed: ($cpu_t + " cores"), failure_reason: $cpu_f },
              { requirement_id: "KCS-RES-RAM-01", compliant: ($mem_c == "true"), observed: ($mem_t + " Gi"), failure_reason: $mem_f },
              { requirement_id: "KCS-RES-DISK-01", compliant: ($dsk_c == "true"), observed: ($dsk_t + " Gi"), failure_reason: $dsk_f },
              { requirement_id: "KCS-NET-CNI-POL-01", compliant: ($cni_c == "true"), observed: $cni, failure_reason: $cni_f },
              { requirement_id: "KCS-INF-STORAGE-01", compliant: ($sc_c == "true"), observed: $dsc, failure_reason: $sc_f },
              { requirement_id: "KCS-CONN-REPO-01", compliant: ($rc == "true"), observed: ($rc == "true" | tostring), failure_reason: $rc_f }
            ],
            raw_facts: { k8s_version: $kv, helm_version: $hv, runtime: $rt, infrastructure: $infra, nodes: $nodes }
        }')
}
