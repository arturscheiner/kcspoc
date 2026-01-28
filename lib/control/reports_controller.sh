#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: reports_controller.sh
# Responsibility: Orchestration for Report management command
# ==============================================================================

reports_controller() {
    local action=""
    local target=""
    local save_path=""
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -l|--list)
                action="list"
                if [[ "$2" != --* ]] && [[ -n "$2" ]]; then
                    target="$2"
                    shift 2
                else
                    target=""
                    shift 1
                fi
                ;;
            -v|--show)
                action="show"
                target="$2"
                shift 2
                ;;
            -s|--save-as)
                save_path="$2"
                shift 2
                ;;
            --cleanup)
                action="cleanup"
                if [[ "$2" != --* ]] && [[ -n "$2" ]]; then
                    target="$2"
                    shift 2
                else
                    target=""
                    shift 1
                fi
                ;;
            -p|--serve)
                serve="true"
                if [[ "$2" != --* ]] && [[ -n "$2" ]]; then
                    port="$2"
                    shift 2
                else
                    port="6000"
                    shift 1
                fi
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
            if [ -n "$target" ]; then
                view_ui_section_header "Report History for '$target'"
            else
                view_ui_section_header "Global Report History"
            fi
            service_reports_list "$target"
            if [ "$serve" == "true" ]; then
                service_report_serve "$port"
            fi
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
            
            if [ -n "$save_path" ]; then
                model_report_export "$report_file" "$save_path"
                echo -e "   ${ICON_OK} ${BRIGHT_GREEN}Report exported to:${NC} $save_path"
            else
                view_ui_section_header "Report Viewer: $target"
                view_reports_show_content "$target" "$report_file"
            fi
            ;;
        cleanup)
            service_reports_cleanup "$target"
            ;;
    esac
}
