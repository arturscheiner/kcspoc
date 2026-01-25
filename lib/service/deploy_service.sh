#!/bin/bash

# ==============================================================================
# Layer: Service
# File: deploy_service.sh
# Responsibility: Business logic for KCS Cor and Agents deployment
# ==============================================================================

service_deploy_core() {
    local target_ver="${KCS_VERSION:-latest}"
    local values_override="$1"
    local mode_override="$2"
    local ns="$NAMESPACE"
    local exec_id="$EXEC_HASH"
    local local_hash=$(model_config_get_hash)

    # 1. Pre-flight Diagnostics
    view_deploy_section "Pre-flight Diagnostics"
    
    # 1.1 Collision Check
    view_deploy_step_start "Analyzing cluster for KCS instances"
    local collisions=$(model_deploy_find_global_instances "$ns")
    view_deploy_step_stop "PASS"
    
    if [ -n "$collisions" ]; then
        view_deploy_collision_warning "$collisions"
        if ! view_deploy_prompt_collision_proceed; then
            view_deploy_info "Deployment aborted to prevent global conflict."
            return 0
        fi
        view_deploy_section "Pre-flight Diagnostics"
    fi

    # 1.2 Existence Check
    view_deploy_step_start "Checking target namespace ($ns)"
    local kcs_exists=false
    model_kubectl_get_resource_exists "configmap" "infraconfig" "$ns" && kcs_exists=true
    view_deploy_step_stop "PASS"

    local op_type="install"
    if [ "$kcs_exists" == "true" ]; then
        local installed_ver=$(model_deploy_get_installed_version "$ns")
        view_deploy_info "KCS version $installed_ver is already installed in namespace $ns."
        
        if [ -n "$mode_override" ]; then
            op_type="$mode_override"
        elif [ "$installed_ver" == "$target_ver" ]; then
            op_type="update"
        else
            local latest=$(printf "%s\n%s" "$installed_ver" "$target_ver" | sort -V | tail -n 1)
            [ "$latest" == "$target_ver" ] && op_type="upgrade" || op_type="update"
        fi

        if ! view_deploy_prompt_upgrade "$target_ver" "$op_type"; then
            view_deploy_info "Deployment cancelled by user."
            return 0
        fi
    else
        [ -n "$mode_override" ] && op_type="$mode_override"
        if ! view_deploy_prompt_install "$target_ver" "$op_type"; then
            view_deploy_info "Deployment cancelled by user."
            return 0
        fi
    fi

    # 2. Preparation
    # 2.1 APP_SECRET Recovery
    if [[ "$op_type" =~ ^(update|upgrade)$ ]]; then
        view_deploy_step_start "Recovering APP_SECRET from cluster"
        local cluster_secret=$(model_kubectl_get_secret_value "infracreds" "$ns" "APP_SECRET")
        if [ -n "$cluster_secret" ]; then
            APP_SECRET="$cluster_secret"
            view_deploy_step_stop "RECOVERED"
        else
            view_deploy_step_stop "SKIP (New Secret)"
        fi
    fi

    view_deploy_section "$MSG_DEPLOY_CORE"

    # 3. Execution
    _update_state "$ns" "deploying" "$op_type" "$exec_id" "$local_hash" "$target_ver"
    
    # 3.1 Namespace & Registry Secret
    view_deploy_step_start "[1/5] $MSG_PREPARE_STEP_1_A"
    model_kubectl_create_namespace "$ns"
    _update_state "$ns" "deploying" "$op_type" "$exec_id" "$local_hash" "$target_ver"
    view_deploy_step_stop "PASS"

    if [ -z "$values_override" ]; then
        view_deploy_step_start "KCS Registry Secret"
        if model_kubectl_create_docker_secret "kcs-registry-secret" "$ns" "$REGISTRY_SERVER" "$REGISTRY_USER" "$REGISTRY_PASS" && \
           model_kubectl_label "secret" "kcs-registry-secret" "$ns" "kcspoc.io/managed-by=kcspoc"; then
            view_deploy_step_stop "PASS"
        else
            view_deploy_step_stop "FAIL"
            return 1
        fi
    fi

    # 3.2 Identity Bootstrap
    view_deploy_step_start "[2/5] Identity Bootstrap (Issuer/CA)"
    # Apply CA manifest via stdin model
    cat <<EOF | model_kubectl_apply_stdin
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: kcs-issuer
  namespace: $ns
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    meta.helm.sh/release-name: kcs
    meta.helm.sh/release-namespace: $ns
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cert-ca
  namespace: $ns
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    meta.helm.sh/release-name: kcs
    meta.helm.sh/release-namespace: $ns
spec:
  isCA: true
  commonName: kcs-ca
  secretName: cert-ca
  privateKey:
    algorithm: ECDSA
    size: 256
  secretTemplate:
    labels:
      app.kubernetes.io/managed-by: Helm
    annotations:
      meta.helm.sh/release-name: kcs
      meta.helm.sh/release-namespace: $ns
  issuerRef:
    name: kcs-issuer
    kind: Issuer
    group: cert-manager.io
EOF
    view_deploy_step_stop "PASS"

    view_deploy_step_start "[3/5] Waiting for Root CA Readiness"
    if model_kubectl_wait_certificate "cert-ca" "$ns" "45s"; then
        view_deploy_step_stop "PASS"
    else
        view_deploy_step_stop "FAIL"
        return 1
    fi

    # 3.3 Helm Deployment
    local artifact_path="$ARTIFACTS_DIR/kcs/$target_ver"
    local tgz_file=$(ls "$artifact_path"/kcs-*.tgz 2>/dev/null | head -n 1)
    local processed_values="$CONFIG_DIR/values-core-$target_ver.yaml"
    
    if [ -n "$values_override" ] && [ -f "$values_override" ]; then
        processed_values="$values_override"
    else
        local template="$artifact_path/values-core-$target_ver.yaml"
        # Processing moved to Model
        model_deploy_process_values "$template" "$processed_values" "$target_ver" "$local_hash" "$VERSION"
        
        # Validation
        view_deploy_step_start "Validating deployment configuration"
        local missing=$(grep -oP '\$[A-Z0-9_]+(_CONFIG|_CONFIGURED)|\$\{[A-Z0-9_]+\}' "$processed_values" | sort | uniq | tr '\n' ' ')
        if [ -n "$missing" ]; then
            view_deploy_step_stop "FAIL"
            view_deploy_error "Missing placeholders in template: $missing"
            return 1
        fi
        view_deploy_step_stop "PASS"
    fi

    # Integrity Gate
    if ! service_deploy_verify_config_integrity "$ns" "$local_hash"; then
        return 1
    fi

    # Helm Action
    view_deploy_step_start "[4/5] Helm Upgrade/Install"
    local helm_err="/tmp/kcspoc_helm_deploy.err"
    if model_helm_upgrade_install_local "kcs" "$tgz_file" "$ns" &> "$helm_err"; then
        view_deploy_step_stop "PASS"
    else
        # Self-Healing for Immutability
        if grep -q "Forbidden: updates to statefulset spec" "$helm_err"; then
            view_deploy_step_stop "RESILIENCE"
            view_deploy_healing_immutability
            kubectl delete sts kcs-s3 kcs-postgres kcs-clickhouse -n "$ns" --cascade=orphan &>> "$DEBUG_OUT"
            
            view_deploy_step_start "[4/5] Retrying Helm Upgrade/Install"
            if model_helm_upgrade_install_local "kcs" "$tgz_file" "$ns" &>> "$DEBUG_OUT"; then
                view_deploy_step_stop "PASS"
            else
                view_deploy_step_stop "FAIL"
                return 1
            fi
        else
            view_deploy_step_stop "FAIL"
            cat "$helm_err" >> "$DEBUG_OUT"
            return 1
        fi
    fi

    # Final Identity Refresh
    view_deploy_step_start "[5/5] Final Sync & Identity Refresh"
    model_kubectl_wait_all_certificates "$ns" "60s"
    model_kubectl_delete_pods_force "$ns"
    view_deploy_step_stop "PASS"

    # 4. Stability Watcher
    if service_deploy_watch_stability "$ns" "$op_type" "$exec_id" "$target_ver" "$local_hash"; then
        service_deploy_verify_health "$ns"
        return 0
    fi

    return 1
}

service_deploy_watch_stability() {
    local ns="$1"
    local op_type="$2"
    local exec_id="$3"
    local target_ver="$4"
    local local_hash="$5"
    local timeout=900
    local start_time=$(date +%s)
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local frame_idx=0
    local poll_interval=50
    local poll_counter=$poll_interval

    view_deploy_stability_watcher_start

    while true; do
        if [ "$poll_counter" -ge "$poll_interval" ]; then
            local pods_info=$(model_kubectl_get_pods_info "$ns")
            local total_pods=$(echo "$pods_info" | grep -v "^$" | wc -l)
            local ready_pods=$(echo "$pods_info" | awk '$2 ~ /\// {split($2,a,"/"); if(a[1]==a[2] && a[2]!="0") print $0}' | wc -l)
            local completed_jobs=$(echo "$pods_info" | grep "Completed" | wc -l)
            
            local stable_count=$((ready_pods + completed_jobs))
            local percent=0
            [ "$total_pods" -gt 0 ] && percent=$((stable_count * 100 / total_pods))

            # Progress Bar logic (Service layer calculates, View renders)
            local bar_size=20
            local filled=$((percent * bar_size / 100))
            local empty=$((bar_size - filled))
            local bar="["
            for ((i=0; i<filled; i++)); do bar+="#"; done
            for ((i=0; i<empty; i++)); do bar+="-"; done
            bar+="]"

            _update_state "$ns" "deploying" "$op_type" "$exec_id" "$(model_config_get_hash)" "$target_ver" "$percent"
            poll_counter=0
        fi

        view_deploy_stability_progress "$bar" "$percent" "$stable_count" "$total_pods" "${frames[$frame_idx]}"

        if [ "$poll_counter" -eq 0 ] && [ "$stable_count" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
            view_deploy_stability_watcher_stop
            view_deploy_stability_success
            _update_state "$ns" "stable" "$op_type" "$exec_id" "$local_hash" "$target_ver" "100"
            
            # Final Boarding Pass
            local domain=$(model_kubectl_get_ingress_domain "$ns")
            [ -z "$domain" ] && domain="kcs.cluster.local"
            local display_pass="admin"
            local pass_note="Initial Password"
            if [[ "$op_type" =~ ^(update|upgrade)$ ]]; then
                display_pass="*******"
                pass_note="Preserved Credentials"
            fi
            view_deploy_boarding_pass "$domain" "$display_pass" "$pass_note"
            break
        fi

        local elapsed=$(($(date +%s) - start_time))
        if [ "$elapsed" -gt "$timeout" ]; then
            view_deploy_stability_watcher_stop
            view_deploy_stability_timeout
            _update_state "$ns" "failed" "$op_type" "$exec_id" "$local_hash" "$target_ver" "$percent"
            return 1
        fi

        sleep 0.1
        ((frame_idx = (frame_idx + 1) % ${#frames[@]}))
        ((poll_counter++))
    done
    return 0
}

service_deploy_verify_config_integrity() {
    local ns="$1"
    local local_hash="$2"
    [ "$local_hash" == "none" ] && return 0
    
    local remote_hash=$(model_kubectl_get_label "ns" "$ns" "" "kcspoc.io/config-hash")
    if [ -n "$remote_hash" ] && [ "$remote_hash" != "$local_hash" ]; then
        view_deploy_mismatch_warning "hash"
        return 1
    fi
    return 0
}

service_deploy_verify_health() {
    local ns="$1"
    view_deploy_info "$MSG_DEPLOY_HEALTH_CHECK"
    # Port original health checks to service
    _verify_deploy_bootstrap "$ns" # Keeping temporarily as internal helper or move to health_service
}

service_deploy_check_integrity() {
    local mode="$1"
    local ns="$NAMESPACE"
    local local_val=""
    local remote_val=""
    local col_header=""
    local label_key=""

    case "$mode" in
        hash)
            local_val=$(model_config_get_hash)
            label_key="kcspoc.io/config-hash"
            col_header="CONFIG HASH"
            ;;
        version)
            local_val="${KCS_VERSION:-latest}"
            label_key="kcspoc.io/kcs-version"
            col_header="KCS VERSION"
            ;;
        *) return 1 ;;
    esac

    remote_val=$(model_kubectl_get_label "ns" "$ns" "" "$label_key" || echo "N/A")
    local match_icon="${RED}${ICON_FAIL}${NC}"
    [ "$local_val" == "$remote_val" ] && match_icon="${GREEN}${ICON_OK}${NC}"

    view_deploy_section "Integrity Check: $mode"
    view_deploy_integrity_report "$col_header" "$ns" "$local_val" "$remote_val" "$match_icon"

    if [ "$remote_val" != "N/A" ] && [ "$local_val" != "$remote_val" ]; then
        view_deploy_mismatch_warning "$mode"
    fi
}
