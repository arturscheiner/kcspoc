#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: prepare_controller.sh
# Responsibility: Argument parsing and orchestration for Prepare Command
# ==============================================================================

prepare_controller() {
    # Parse Arguments (Standard layout for v0.6.0)
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --help|help)
                view_ui_help "prepare" "$MSG_HELP_PREPARE_DESC" "$MSG_HELP_PREPARE_OPTS" "$MSG_HELP_PREPARE_EX" "$VERSION"
                return 0
                ;;
            *)
                # Prepare often takes positional args or flags like --unattended in global context
                # but cmd_prepare historically didn't have specific flags. 
                # Just catch-all to avoid help on unknown flags if intended.
                break
                ;;
        esac
    done

    # Load config (Service will check requirements)
    if ! model_fs_load_config &>> "$DEBUG_OUT"; then
        echo -e "${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
        return 1
    fi

    service_prepare_run_all
}
