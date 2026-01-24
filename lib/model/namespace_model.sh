#!/bin/bash

# ==============================================================================
# Layer: Model
# File: namespace_model.sh
# Responsibility: Kubernetes Namespace state and labels
# ==============================================================================

model_ns_update_state() {
    local ns="$1"
    local status="$2"
    local operation="$3"
    local execution_id="$4"
    local config_hash="$5"
    local kcs_ver="$6"
    local status_progress="${7:-0}"

    # Only attempt if namespace exists
    if kubectl get ns "$ns" &>/dev/null; then
        kubectl label ns "$ns" \
          "kcspoc.io/managed-by=kcspoc" \
          "kcspoc.io/status=$status" \
          "kcspoc.io/last-operation=$operation" \
          "kcspoc.io/execution-id=$execution_id" \
          "kcspoc.io/config-hash=$config_hash" \
          "kcspoc.io/kcs-version=$kcs_ver" \
          "kcspoc.io/status-progress=$status_progress" --overwrite &>> "$DEBUG_OUT"
    fi
}

model_ns_check_label() {
    local res_type="$1"
    local res_name="$2"
    local ns="$3"
    local label_key="$4"
    local label_val="$5"
    
    local args=("$res_type" "$res_name" "--show-labels")
    if [ -n "$ns" ]; then
        args+=("-n" "$ns")
    fi
    
    if kubectl get "${args[@]}" 2>> "$DEBUG_OUT" | grep -q "$label_key=$label_val"; then
        return 0
    else
        return 1
    fi
}

model_ns_force_delete() {
    local ns="$1"
    local status
    status=$(kubectl get namespace "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    
    if [ "$status" == "Terminating" ]; then
        echo -e "[ $(date) ] Forcing deletion of namespace: $ns" >> "$DEBUG_OUT"
        kubectl get namespace "$ns" -o json 2>>"$DEBUG_OUT" | jq 'del(.spec.finalizers)' 2>>"$DEBUG_OUT" | kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f - &>> "$DEBUG_OUT"
        sleep 2
    fi
}
