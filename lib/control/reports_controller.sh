#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: reports_controller.sh
# Responsibility: Orchestration for Report management command
# ==============================================================================

reports_controller() {
    local action=""
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -l|--list) action="list"; shift ;;
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
                    view_reports_list_item "$h" "$t" "$c" "$e"
                done
            fi
            echo ""
            ;;
    esac
}
