#!/bin/bash

# ==============================================================================
# Layer: Service
# File: bootstrap_service.sh
# Responsibility: Business logic for API integration bootstrap
# ==============================================================================

service_bootstrap_run() {
    view_bootstrap_intro

    # Phase 1: Interactive Token Collection (Skip if already configured)
    local token=""
    
    if config_service_load && [ -n "$ADMIN_API_TOKEN" ]; then
        token="$ADMIN_API_TOKEN"
        view_bootstrap_token_detected "$token"
    else
        while [ -z "$token" ]; do
            view_bootstrap_prompt_token token
            if [ -z "$token" ]; then
                view_bootstrap_error_empty
            fi
        done
    fi

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

    # Phase 4: Environment Discovery
    view_bootstrap_discovery_start
    local scope_id
    scope_id=$(bootstrap_service_get_default_scope_id "$DOMAIN" "$token")
    local status=$?

    if [ $status -eq 0 ]; then
        view_bootstrap_discovery_stop "PASS"
        view_bootstrap_scope_found "Default scope" "$scope_id"
    else
        view_bootstrap_discovery_stop "FAIL"
        # We don't fail the whole bootstrap if discovery fails, we just warn
        echo -e "      ${RED}${ICON_FAIL} Warning: Could not discover Default scope automatically.${NC}"
    fi

    # Phase 5: Finalization
    view_bootstrap_success
    return 0
}

bootstrap_service_get_default_scope_id() {
    local domain="$1"
    local token="$2"

    [ -z "$domain" ] || [ -z "$token" ] && return 1

    local json_response
    json_response=$(model_kcs_api_get_scopes "$domain" "$token")
    [ $? -ne 0 ] && return 1

    # Extract ID for "Default scope"
    local scope_id
    scope_id=$(echo "$json_response" | jq -r '.[] | select(.name == "Default scope") | .id')

    if [ -z "$scope_id" ] || [ "$scope_id" == "null" ]; then
        return 2 # Scope not found
    fi

    echo "$scope_id"
    return 0
}
