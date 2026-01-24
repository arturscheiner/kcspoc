#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: bootstrap_controller.sh
# Responsibility: Orchestration for Bootstrap command
# ==============================================================================

bootstrap_controller() {
    # Check for help
    if [[ "$1" == "--help" ]] || [[ "$1" == "help" ]]; then
        view_ui_help "bootstrap" "Configure KCS API Integration (API Token)" "" "" "$VERSION"
        return 0
    fi

    service_bootstrap_run
}
