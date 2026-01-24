#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: config_controller.sh
# Responsibility: Command Routing and CLI Argument Parsing
# ==============================================================================

config_controller() {
    local SET_VER=""
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --set-version) SET_VER="$2"; shift ;;
            --help|help)
                ui_help "config" "$MSG_HELP_CONFIG_DESC" "$MSG_HELP_CONFIG_OPTS" "$MSG_HELP_CONFIG_EX"
                return 0
                ;;
            *)
                ui_help "config" "$MSG_HELP_CONFIG_DESC" "$MSG_HELP_CONFIG_OPTS" "$MSG_HELP_CONFIG_EX"
                return 1
                ;;
        esac
        shift
    done

    if [ -n "$SET_VER" ]; then
        config_service_set_version "$SET_VER"
        return $?
    fi

    config_service_wizard
}
