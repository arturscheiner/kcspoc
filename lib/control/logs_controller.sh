#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: logs_controller.sh
# Responsibility: Argument parsing and routing for Logs Command
# ==============================================================================

logs_controller() {
    local action=""
    local target=""
    
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

    view_logs_banner

    case "$action" in
        list)
            service_logs_get_history "$target"
            ;;
        show)
            if [ -z "$target" ]; then
                echo -e "${RED}Error: Hash required for --show (e.g., --show A1B2C3)${NC}"
                return 1
            fi
            service_logs_show_entry "$target"
            ;;
        cleanup)
            service_logs_perform_cleanup
            ;;
    esac
}
