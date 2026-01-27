#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: prepare_controller.sh
# Responsibility: Argument parsing and orchestration for Prepare Command
# ==============================================================================

prepare_controller() {
    # Prepare now focuses on core bootstrap by default
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --help|-h|help)
                view_ui_help "prepare" "$MSG_HELP_PREPARE_DESC" "$MSG_HELP_PREPARE_OPTS" "$MSG_HELP_PREPARE_EX" "$VERSION"
                return 0
                ;;
            *)
                # Prepare takes --unattended or positional args handled higher up or ignored
                shift
                ;;
        esac
    done

    # Load config (Service will check requirements)
    if ! model_fs_load_config &>> "$DEBUG_OUT"; then
        echo -e "${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
        return 1
    fi

    # Core environment bootstrap sequence
    service_prepare_run_all ""
}
