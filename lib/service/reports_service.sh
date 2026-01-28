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
        local exec_id=$(echo "$report" | jq -r '.orig_exec_id // "-"')
        
        local fmt_date=$(view_ui_format_timestamp "$t")
        
        view_reports_list_item "$fmt_date" "$h" "$c" "$exec_id" "$e" "$type" "$model"
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

service_report_serve() {
    local port="${1:-6000}"
    local reports_index=$(model_report_get_index)
    local reports_dir="$REPORTS_BASE_DIR"
    local index_file="$reports_dir/index.html"
    
    # Generate the Dashboard
    view_render_report_dashboard "$reports_index" > "$index_file"
    
    # Start the server
    view_reports_serve_start "$port"
    (cd "$reports_dir" && python3 -m http.server "$port")
}
