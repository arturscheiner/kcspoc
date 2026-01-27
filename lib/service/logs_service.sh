#!/bin/bash

# ==============================================================================
# Layer: Service
# File: logs_service.sh
# Responsibility: Business logic for processing log history and metadata
# ==============================================================================

service_logs_get_history() {
    local target="$1"
    local pattern="$LOGS_DIR"
    
    if [ -n "$target" ]; then
        if ! model_logs_has_target_dir "$target"; then
            view_logs_no_logs_found "$target"
            return 0
        fi
        pattern="$LOGS_DIR/$target"
        view_logs_section "Logs for '$target'"
    else
        view_logs_section "Global Log History (Latest 10)"
    fi

    view_logs_list_header "$target"

    model_logs_find_files "$pattern" | while read -r log_file; do
        local filename=$(basename "$log_file")
        local cmd_from_path=$(basename "$(dirname "$log_file")")
        
        # Parse Filename: YYYYMMDD-HHMMSS-HASH.log
        local date_part=$(echo "$filename" | cut -d'-' -f1)
        local time_part=$(echo "$filename" | cut -d'-' -f2)
        local hash_part=$(echo "$filename" | cut -d'-' -f3 | cut -d'.' -f1)
        
        local fmt_date="${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${time_part:0:2}:${time_part:2:2}"

        # Get metadata from Model
        local meta=$(model_logs_get_metadata "$log_file")
        local status="${meta%|*}"
        local version="${meta#*|}"
        
        view_logs_list_row "$fmt_date" "$hash_part" "$cmd_from_path" "-" "$status" "$version"
    done
    echo ""
}

service_logs_show_entry() {
    local hash="$1"
    local log_file=$(model_logs_find_by_hash "$hash")
    
    if [ -z "$log_file" ]; then
        view_logs_hash_not_found "$hash"
        return 1
    fi
    
    view_logs_section "Log Content: $hash"
    view_logs_show_content "$hash" "$log_file"
}

service_logs_perform_cleanup() {
    view_logs_cleanup_start
    if model_logs_delete_all; then
        view_logs_cleanup_stop "PASS" "false"
    else
        view_logs_cleanup_stop "PASS" "true"
    fi
}
