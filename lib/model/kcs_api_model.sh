#!/bin/bash

# ==============================================================================
# Layer: Model
# File: kcs_api_model.sh
# Responsibility: Kaspersky Container Security (KCS) REST API Abstraction
# ==============================================================================

_kcs_api_do_request() {
    local method="$1"
    local url="$2"
    local token="$3"
    local payload="${4:-}"
    local accept="${5:-application/json}"
    local content_type="${6:-application/json}"

    local cmd=(curl -s -f -k -X "$method" "$url" -H "Tron-Token: ${token}" -H "accept: ${accept}")
    
    if [ -n "$payload" ]; then
        cmd+=(-H "Content-Type: ${content_type}" -d "$payload")
    fi

    "${cmd[@]}"
}

model_kcs_api_get_scopes() {
    local domain="$1"
    local token="$2"

    [ -z "$domain" ] || [ -z "$token" ] && return 1

    _kcs_api_do_request "GET" "https://${domain}/api/v1/security/scopes" "$token"
}

model_kcs_api_create_agent_group() {
    local domain="$1"
    local token="$2"
    local payload="$3"

    [ -z "$domain" ] || [ -z "$token" ] || [ -z "$payload" ] && return 1

    _kcs_api_do_request "POST" "https://${domain}/api/v1/integrations/agent-group" "$token" "$payload"
}

model_kcs_api_download_config() {
    local domain="$1"
    local token="$2"
    local group_id="$3"

    [ -z "$domain" ] || [ -z "$token" ] || [ -z "$group_id" ] && return 1

    _kcs_api_do_request "GET" "https://${domain}/api/v1/integrations/agent-group/${group_id}/config" "$token" "" "application/x-yaml"
}
