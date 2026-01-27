#!/bin/bash

# ==============================================================================
# Layer: Service
# File: reports_service.sh
# Responsibility: Business logic for Report Hub (filtering, cleanup)
# ==============================================================================

service_reports_list() {
    local cmd_filter="$1" # Optional
    
    local reports=$(model_report_get_index)
    
    # Filter by command if provided
    if [ -n "$cmd_filter" ]; then
        reports=$(echo "$reports" | jq -c "[.[] | select(.command == \"$cmd_filter\")]")
    fi
    
    if [ "$(echo "$reports" | jq 'length')" -eq 0 ]; then
        view_reports_empty "$cmd_filter"
        return 0
    fi

    view_reports_list_header
    echo "$reports" | jq -c '.[]' | while read -r report; do
        local h=$(echo "$report" | jq -r '.hash')
        local t=$(echo "$report" | jq -r '.timestamp')
        local c=$(echo "$report" | jq -r '.command')
        local e=$(echo "$report" | jq -r '.extension')
        local type=$(echo "$report" | jq -r '.type // "template"')
        local model=$(echo "$report" | jq -r '.ai_model // "-"')
        local source=$(echo "$report" | jq -r '.orig_exec_id // "-"')
        view_reports_list_item "$h" "$t" "$c" "$e" "$type" "$model" "$source"
    done
}

service_reports_cleanup() {
    local cmd_filter="$1" # Optional
    
    if view_reports_confirm_cleanup "$cmd_filter"; then
        view_reports_cleanup_start "$cmd_filter"
        model_report_delete "$cmd_filter"
        view_reports_cleanup_stop "PASS"
    else
        view_reports_cleanup_cancel
    fi
}
