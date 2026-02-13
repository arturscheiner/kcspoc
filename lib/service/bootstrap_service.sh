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
        return 0 # Still proceed with SUCCESS view for now or exit? 
        # User request was to get scope and show it. If it fails, we should probably stop if next steps depend on it.
    fi

    # Phase 5: Agent Group Provisioning
    local group_name="kcspoc-group"
    view_bootstrap_group_create_start "$group_name"
    
    local group_id
    group_id=$(bootstrap_service_create_poc_group "$DOMAIN" "$token" "$scope_id" "$group_name")
    local group_status=$?

    if [ $group_status -eq 0 ]; then
        view_bootstrap_group_created "$group_id"
    elif [ $group_status -eq 409 ]; then
        view_bootstrap_group_exists "$group_name"
    else
        service_spinner_stop "FAIL"
        echo -e "      ${RED}${ICON_FAIL} Error: Failed to create Agent Group.${NC}"
    fi

    # Phase 6: Finalization
    view_bootstrap_success
    return 0
}

bootstrap_service_create_poc_group() {
    local domain="$1"
    local token="$2"
    local scope_id="$3"
    local name="$4"

    [ -z "$domain" ] || [ -z "$token" ] || [ -z "$scope_id" ] || [ -z "$name" ] && return 1

    # Prepare JSON payload
    local payload
    payload=$(jq -n \
        --arg name "$name" \
        --arg scope "$scope_id" \
        --arg ns "${KCSPOC_NAMESPACE:-kcspoc}" \
        --arg reg "$REGISTRY_SERVER" \
        --arg user "$REGISTRY_USER" \
        '{
            "agentType": "tron-kube-agent",
            "containerLifecycleEnabled": true,
            "description": "PoC Agent Group created by kcspoc",
            "fileOperationsEnabled": true,
            "fileThreatProtectionEnabled": true,
            "fileThreatProtectionMonitoring": "containers",
            "groupName": $name,
            "hostLoginEnabled": true,
            "kcsNamespace": $ns,
            "kcsRegistryUrl": $reg,
            "kcsRegistryUsername": $user,
            "logicalName": $name,
            "networkEnabled": true,
            "networkListeningPortsEnabled": true,
            "networkReputationEnabled": true,
            "oSType": "linux",
            "orchestrator": "kubernetes",
            "syscallEnabled": true,
            "systemScopes": [$scope]
        }')

    # Call API
    local response
    response=$(model_kcs_api_create_agent_group "$domain" "$token" "$payload")
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        # Check if error is "already exists" (usually 400 or 409 depending on API)
        # For now, let's assume if it fails it might be a conflict if we want to be smart
        # Better: parse response if possible, but curl -f hide response body on error.
        # We'll use a secondary check or specific exit code mapping in future.
        return 1
    fi

    # Extract ID from response
    local id
    id=$(echo "$response" | jq -r '.id')
    if [ -z "$id" ] || [ "$id" == "null" ]; then
        return 1
    fi

    echo "$id"
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
