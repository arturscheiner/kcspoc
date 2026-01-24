#!/bin/bash

# ==============================================================================
# Layer: Service
# File: namespace_service.sh
# Responsibility: Coordinate Namespace Model and View
# ==============================================================================

service_ns_check_label_with_ui() {
    local res_type="$1"
    local res_name="$2"
    local ns="$3"
    local label_key="${4:-$POC_LABEL_KEY}"
    local label_val="${5:-$POC_LABEL_VAL}"

    view_ns_check_start "$label_key" "$label_val"
    
    if model_ns_check_label "$res_type" "$res_name" "$ns" "$label_key" "$label_val"; then
        view_ns_check_ok
        return 0
    else
        view_ns_check_fail
        return 1
    fi
}
