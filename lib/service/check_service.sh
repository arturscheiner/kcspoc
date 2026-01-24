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
    if load_config; then
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

    view_check_step_start "Verifying Cluster Connectivity"
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
                    if [ -n "$headers_out" ]; then ebpf="${GREEN}YES${NC}"; else ebpf="${RED}NO${NC}"; fi # TYPO FIX: should be headers
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
    view_check_section_title "7" "$MSG_AUDIT_TITLE"
    view_check_audit_header
    
    local cluster_pass=true
    local min_cpu=4000; local min_ram=7680; local min_disk=80
    
    while IFS='|' read -r name role cpu_a_m cpu_c_m mem_a_m mem_c_m disk_val disk_disp ebpf headers; do
        [ -z "$name" ] && continue
        local fail_reasons=""
        [ "$cpu_a_m" -lt "$min_cpu" ] && { fail_reasons+="${RED}      ✖ $(printf "$MSG_AUDIT_FAIL_CPU" "$((cpu_a_m/1000))" "4")${NC}\n"; fail_reasons+="        -> $MSG_AUDIT_CAUSE_CPU\n"; }
        [ "$mem_a_m" -lt "$min_ram" ] && { fail_reasons+="${RED}      ✖ $(printf "$MSG_AUDIT_FAIL_RAM" "$mem_a_m" "7680")${NC}\n"; fail_reasons+="        -> $MSG_AUDIT_CAUSE_RAM\n"; }
        [ "$disk_val" -lt "$min_disk" ] && { local d_v_s="$disk_val"; [ "$disk_val" -eq 0 ] && d_v_s="0 (Unknown)"; fail_reasons+="${RED}      ✖ $(printf "$MSG_AUDIT_FAIL_DISK" "$d_v_s" "80")${NC}\n"; fail_reasons+="        -> $MSG_AUDIT_CAUSE_DISK\n"; }

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
