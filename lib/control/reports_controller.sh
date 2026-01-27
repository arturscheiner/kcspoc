#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: reports_controller.sh
# Responsibility: Orchestration for Report management command
# ==============================================================================

reports_controller() {
    local action=""
    local target=""
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -l|--list) action="list"; shift ;;
            -s|--show)
                action="show"
                target="$2"
                shift 2
                ;;
            --help|help)
                view_ui_help "reports" "$MSG_HELP_REPORTS_DESC" "$MSG_HELP_REPORTS_OPTS" "$MSG_HELP_REPORTS_EX" "$VERSION"
                return 0
                ;;
            *)
                view_ui_help "reports" "$MSG_HELP_REPORTS_DESC" "$MSG_HELP_REPORTS_OPTS" "$MSG_HELP_REPORTS_EX" "$VERSION"
                return 1
                ;;
        esac
    done

    # Default action if none specified
    if [ -z "$action" ]; then
        view_ui_help "reports" "$MSG_HELP_REPORTS_DESC" "$MSG_HELP_REPORTS_OPTS" "$MSG_HELP_REPORTS_EX" "$VERSION"
        return 0
    fi

    case "$action" in
        list)
            view_ui_section_header "Report History"
            local reports=$(model_report_get_index)
            if [ "$(echo "$reports" | jq 'length')" -eq 0 ]; then
                view_reports_empty
            else
                view_reports_list_header
                echo "$reports" | jq -c '.[]' | while read -r report; do
                    local h=$(echo "$report" | jq -r '.hash')
                    local t=$(echo "$report" | jq -r '.timestamp')
                    local c=$(echo "$report" | jq -r '.command')
                    local e=$(echo "$report" | jq -r '.extension')
                    local type=$(echo "$report" | jq -r '.type // "template"')
                    local model=$(echo "$report" | jq -r '.ai_model // "-"')
                    view_reports_list_item "$h" "$t" "$c" "$e" "$type" "$model"
                done
            fi
            echo ""
            ;;
        show)
            if [ -z "$target" ]; then
                echo -e "${RED}Error: Hash required for --show (e.g., --show A1B2C3)${NC}"
                return 1
            fi
            
            local report_file=$(model_report_find_by_hash "$target")
            if [ -z "$report_file" ] || [ ! -f "$report_file" ]; then
                echo -e "${RED}Error: Report with hash '$target' not found.${NC}"
                return 1
            fi
            
            view_ui_section_header "Report Viewer: $target"
            view_reports_show_content "$target" "$report_file"
            ;;
    esac
}
