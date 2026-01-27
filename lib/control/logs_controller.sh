#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: logs_controller.sh
# Responsibility: Argument parsing and routing for Logs Command
# ==============================================================================

logs_controller() {
    local action=""
    local target=""
    local report=false
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --list)
                action="list"
                if [[ "$2" != --* ]] && [[ -n "$2" ]]; then
                    target="$2"
                    shift 2
                else
                    target=""
                    shift 1
                fi
                ;;
            --show)
                action="show"
                target="$2"
                shift 2
                ;;
            --report)
                report=true
                shift 1
                ;;
            --cleanup)
                action="cleanup"
                shift 1
                ;;
            --help|help)
                view_ui_help "logs" "$MSG_HELP_LOGS_DESC" "$MSG_HELP_LOGS_OPTS" "$MSG_HELP_LOGS_EX" "$VERSION"
                return 0
                ;;
            *)
                view_ui_help "logs" "$MSG_HELP_LOGS_DESC" "$MSG_HELP_LOGS_OPTS" "$MSG_HELP_LOGS_EX" "$VERSION"
                return 1
                ;;
        esac
    done

    if [ -z "$action" ]; then
        view_ui_help "logs" "$MSG_HELP_LOGS_DESC" "$MSG_HELP_LOGS_OPTS" "$MSG_HELP_LOGS_EX" "$VERSION"
        return 1
    fi

    case "$action" in
        list)
            service_logs_get_history "$target"
            ;;
        show)
            if [ -z "$target" ]; then
                echo -e "${RED}Error: Hash required for --show (e.g., --show A1B2C3)${NC}"
                return 1
            fi
            
            if [ "$report" = true ]; then
                # Load configuration for AI settings
                config_service_load
                
                local ep="${OLLAMA_ENDPOINT:-http://localhost:11434}"
                local mod="${OLLAMA_MODEL_OVERRIDE:-${OLLAMA_MODEL:-llama3}}"
                
                # Fetch log content
                local log_file=$(model_logs_find_by_hash "$target")
                if [ ! -f "$log_file" ]; then
                    echo -e "${RED}Error: Log entry $target not found.${NC}"
                    return 1
                fi
                local log_content=$(cat "$log_file")
                
                # Extract parent Execution ID from log header
                local parent_exec_id=$(grep -m 1 "Execution ID:" "$log_file" | cut -d':' -f2 | xargs 2>/dev/null || echo "-")

                # Generate a unique hash for the report itself
                local report_hash=$(model_report_generate_hash)
                
                # UI: Starting Analysis
                logs_view_report_start "$target" "$mod"
                
                # Service Call (passing IDs for prompt injection)
                local ai_report=$(ai_service_generate_log_report "$target" "$log_content" "$ep" "$mod" "$report_hash" "$parent_exec_id")
                
                if [ -n "$ai_report" ]; then
                    # Save Report
                    local tmp_report="/tmp/kcspoc_report_${report_hash}.md"
                    echo "$ai_report" > "$tmp_report"
                    model_report_save "logs" "$report_hash" "$tmp_report" "md" "ai" "$mod" "$target" "$parent_exec_id"
                    rm "$tmp_report"
                    
                    # UI: Success
                    logs_view_report_success "logs" "$report_hash" "md"
                else
                    # UI: Failure
                    logs_view_report_fail "$target"
                    return 1
                fi
            else
                service_logs_show_entry "$target"
            fi
            ;;
        cleanup)
            service_logs_perform_cleanup
            ;;
    esac
}
