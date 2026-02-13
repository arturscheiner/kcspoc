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
    local group_response
    group_response=$(bootstrap_service_create_poc_group "$DOMAIN" "$token" "$scope_id" "$group_name")
    local group_status=$?

    if [ $group_status -eq 0 ]; then
        group_id="$group_response"
        view_bootstrap_group_created "$group_id"
    elif [ $group_status -eq 4 ]; then # 4 = Recovered existing group
        group_id="$group_response"
        view_bootstrap_group_exists "$group_name"
        echo -e "      ${DIM}Group ID: ${group_id}${NC}"
    else
        service_spinner_stop "FAIL"
        echo -e "      ${RED}${ICON_FAIL} Error: Failed to create Agent Group.${NC}"
        [ -n "$group_response" ] && echo -e "      ${DIM}${group_response}${NC}"
    fi

    # Phase 6: Asset Management
    if [ -n "$group_id" ]; then
        local asset_result
        view_bootstrap_asset_download_start
        asset_result=$(bootstrap_service_download_assets "$DOMAIN" "$token" "$group_id")
        local status=$?
        
        if [ $status -eq 0 ]; then
            view_bootstrap_asset_download_stop "PASS" "$asset_result"
        elif [ $status -eq 2 ]; then # 2 means SKIPPED/SYNCED
            view_bootstrap_asset_download_stop "SKIPPED"
        else
            view_bootstrap_asset_download_stop "FAIL"
        fi
    fi

    # Phase 7: Finalization
    view_bootstrap_success
    return 0
}

bootstrap_service_download_assets() {
    local domain="$1"
    local token="$2"
    local group_id="$3"

    [ -z "$domain" ] || [ -z "$token" ] || [ -z "$group_id" ] && return 1

    local artifacts_dir="${HOME}/.kcspoc/artifacts/deployments"
    mkdir -p "$artifacts_dir" || return 1

    local target_file="${artifacts_dir}/kcs-agent-deployment.yaml"

    # 1. Download content from server
    local content
    content=$(model_kcs_api_download_config "$domain" "$token" "$group_id")
    [ $? -ne 0 ] && return 1

    # 2. Compare with local version using hash (SHA-256)
    view_bootstrap_asset_compare
    local server_hash=$(echo "$content" | sha256sum | awk '{print $1}')
    
    if [ -f "$target_file" ]; then
        local local_hash=$(sha256sum "$target_file" | awk '{print $1}')
        if [ "$server_hash" == "$local_hash" ]; then
            return 2 # Signal: Already in sync
        fi
    fi

    # 3. Save new content
    if echo "$content" > "$target_file"; then
        echo "$target_file"
        return 0
    fi

    return 1
}

bootstrap_service_get_group_id_by_name() {
    local domain="$1"
    local token="$2"
    local name="$3"

    [ -z "$domain" ] || [ -z "$token" ] || [ -z "$name" ] && return 1

    local json_response
    json_response=$(model_kcs_api_get_agent_groups "$domain" "$token" "$name")
    [ $? -ne 0 ] && return 1

    local id
    # Handle both paginated ({items: []}) and direct ([]) responses
    id=$(echo "$json_response" | jq -r "if type == \"array\" then .[] else .items[]? // empty end | select(.groupName == \"$name\") | .id" 2>/dev/null | head -n 1)
    
    if [ -n "$id" ] && [ "$id" != "null" ]; then
        echo "$id"
        return 0
    fi

    return 1
}

bootstrap_service_create_poc_group() {
    local domain="$1"
    local token="$2"
    local scope_id="$3"
    local name="$4"

    [ -z "$domain" ] || [ -z "$token" ] || [ -z "$scope_id" ] || [ -z "$name" ] && return 1

    # 1. Proactive Check: Does it already exist?
    local existing_id
    existing_id=$(bootstrap_service_get_group_id_by_name "$domain" "$token" "$name")
    if [ -n "$existing_id" ]; then
        echo "$existing_id"
        return 4 # Use 4 as a "Conflict/Exists but recovered" signal
    fi

    # 2. Prepare JSON payload
    local payload
    payload=$(jq -n \
        --arg name "$name" \
        --arg scope "$scope_id" \
        --arg ns "${NAMESPACE:-kcs}" \
        --arg reg "${REGISTRY_SERVER}/images" \
        --arg user "$REGISTRY_USER" \
        '{
            "agentType": "tron-kube-agent",
            "containerLifecycleEnabled": true,
            "description": "PoC Agent Group created by kcspoc",
            "fileOperationsEnabled": true,
            "fileThreatProtectionEnabled": true,
            "fileThreatProtectionMonitoring": "all",
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
        return $exit_code
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
