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
    if ! ai_model_check_endpoint "$endpoint"; then
        return 1 # Endpoint unreachable
    fi
    
    # 2. Check model
    if ! ai_model_verify_presence "$endpoint" "$model"; then
        return 2 # Model not found
    fi
    
    return 0
}
