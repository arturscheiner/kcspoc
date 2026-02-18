# ==============================================================================
# Layer: Service
# File: config_service.sh
# Responsibility: Business Logic and Configuration Management
# Rules: 
# 1. MUST NOT print output.
# 2. MUST NOT parse CLI arguments.
# ==============================================================================

config_service_generate_secret() {
    local length=${1:-32}
    service_base_require_dependencies "tr" "head"
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

config_service_set_version() {
    local set_ver="$1"
    
    if ! kubeconfig_update_version "$set_ver"; then
         return 1
    fi
    
    return 0
}

config_service_load() {
    if kubeconfig_load; then
        return 0
    fi
    return 1
}

config_service_get_locales() {
    ls "$SCRIPT_DIR/locales/"*.sh 2>/dev/null | xargs -n 1 basename | sed 's/\.sh//' | tr '\n' ' '
}

config_service_get_current_context() {
    kubeconfig_get_current_context
}

config_service_get_all_contexts() {
    kubeconfig_get_all_contexts
}

config_service_save() {
    local config_data="$1"
    mkdir -p "$CONFIG_DIR"
    kubeconfig_save "$config_data"
}

config_service_verify_ai() {
    local endpoint="$1"
    local model="$2"
    
    # 1. Check endpoint
    ai_model_check_endpoint "$endpoint"
    local status=$?
    
    if [ "$status" -eq 127 ]; then
        return 127 # Curl missing
    elif [ "$status" -ne 0 ]; then
        return 1 # Endpoint unreachable or non-200
    fi
    
    # 2. Check model
    if ! ai_model_verify_presence "$endpoint" "$model"; then
        return 2 # Model not found
    fi
    
    return 0
}

config_service_verify_kcs() {
    local token_override="${1:-}"
    
    # 1. Check dependencies
    if ! command -v curl &>/dev/null; then
        return 127
    fi

    local domain="${DOMAIN:-}"
    local token="${token_override:-${ADMIN_API_TOKEN:-}}"

    if [ -z "$domain" ] || [ -z "$token" ]; then
        return 1 # Configuration missing
    fi

    # 2. Call API model (Get Scopes is a lightweight read operation)
    # captures the actual HTTP status to distinguish 401/403 from connectivity errors
    local response_info
    response_info=$(curl -s -k -o /dev/null -w "%{http_code}" \
        -X 'GET' "https://${domain}/api/v1/security/scopes" \
        -H "Tron-Token: ${token}" \
        --connect-timeout 5)
    local status=$?

    if [ $status -ne 0 ]; then
        return 1 # Connectivity error
    fi

    case "$response_info" in
        200) return 0 ;;
        401|403) return 2 ;; # Unauthorized
        *) return 3 ;; # Other API error
    esac
}
