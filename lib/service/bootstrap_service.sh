#!/bin/bash

# ==============================================================================
# Layer: Service
# File: bootstrap_service.sh
# Responsibility: Business logic for API integration bootstrap
# ==============================================================================

service_bootstrap_run() {
    view_bootstrap_intro

    # Phase 1: Interactive Token Collection
    local token=""
    while [ -z "$token" ]; do
        view_bootstrap_prompt_token token
        if [ -z "$token" ]; then
            view_bootstrap_error_empty
        fi
    done

    # Phase 2: Validation
    # Validate token format (simple length check for now)
    if [ ${#token} -lt 20 ]; then
        view_bootstrap_warn_short
    fi

    # Phase 3: Persistence
    view_bootstrap_saving_start
    if model_config_set_api_token "$token"; then
        view_bootstrap_saving_stop
    else
        # Should not happen if config exists, but good for safety
        service_spinner_stop "FAIL"
        return 1
    fi

    # Phase 4: Finalization
    view_bootstrap_success
    return 0
}
