#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: pull_controller.sh
# Responsibility: Argument parsing and routing for Pull Command
# ==============================================================================

pull_controller() {
    local force_version=""
    local list_local="false"
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --version) force_version="$2"; shift ;;
            --list-local) list_local="true" ;;
            --help|help)
                ui_help "pull" "$MSG_HELP_PULL_DESC" "$MSG_HELP_PULL_OPTS" "$MSG_HELP_PULL_EX"
                return 0
                ;;
            *)
                ui_help "pull" "$MSG_HELP_PULL_DESC" "$MSG_HELP_PULL_OPTS" "$MSG_HELP_PULL_EX"
                return 1
                ;;
        esac
        shift
    done

    # Load Config
    if ! load_config; then
        echo -e "${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
        exit 1
    fi
    
    view_pull_banner
    view_pull_section_title

    if [ "$list_local" == "true" ]; then
        service_pull_list_local
        return $?
    fi

    service_pull_perform "$force_version"
}
