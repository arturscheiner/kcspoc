#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: bootstrap_controller.sh
# Responsibility: Orchestration for Bootstrap command
# ==============================================================================

bootstrap_controller() {
    # Check for help
    if [[ "$1" == "--help" ]] || [[ "$1" == "help" ]]; then
        # Use existing help data (defined in common.sh or locales)
        ui_help "bootstrap" "Configure KCS API Integration (API Token)" "" ""
        return 0
    fi

    service_bootstrap_run
}
