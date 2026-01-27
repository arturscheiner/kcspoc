#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: config_controller.sh
# Responsibility: Command Routing and CLI Argument Parsing
# ==============================================================================

config_controller() {
    local SET_VER=""
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --set-version) SET_VER="$2"; shift ;;
            --help|help)
                view_ui_help "config" "$MSG_HELP_CONFIG_DESC" "$MSG_HELP_CONFIG_OPTS" "$MSG_HELP_CONFIG_EX" "$VERSION"
                return 0
                ;;
            *)
                view_ui_help "config" "$MSG_HELP_CONFIG_DESC" "$MSG_HELP_CONFIG_OPTS" "$MSG_HELP_CONFIG_EX" "$VERSION"
                return 1
                ;;
        esac
        shift
    done

    if [ -n "$SET_VER" ]; then
        config_view_version_update_header
        if config_service_set_version "$SET_VER"; then
            config_view_version_update_success "$SET_VER"
            return 0
        else
            config_view_error_config_not_found
            return 1
        fi
    fi

    # Orchestrate Wizard Flow
    _config_controller_wizard
}

_config_controller_wizard() {
    config_view_wizard_intro
    
    # Load existing config logic
    local CUR_NS="" CUR_DOMAIN="" CUR_REG_SRV="" CUR_REG_USER="" CUR_REG_EMAIL="" CUR_IP_RANGE="" CUR_DEEP="" CUR_VER="" CUR_LANG="" CUR_PLAT="" CUR_CRI=""
    local CUR_PG_USER="" CUR_PG_PASS="" CUR_MINIO_USER="" CUR_MINIO_PASS="" CUR_CH_ADMIN_PASS="" CUR_CH_WRITE_PASS="" CUR_CH_READ_PASS="" CUR_MCHD_USER="" CUR_MCHD_PASS="" CUR_APP_SECRET=""
    local CUR_AI_ENDPOINT="" CUR_AI_MODEL=""
    
    if config_service_load; then
        CUR_NS="$NAMESPACE"
        CUR_DOMAIN="$DOMAIN"
        CUR_REG_SRV="$REGISTRY_SERVER"
        CUR_REG_USER="$REGISTRY_USER"
        CUR_REG_EMAIL="$REGISTRY_EMAIL"
        CUR_IP_RANGE="$IP_RANGE"
        CUR_DEEP="$ENABLE_DEEP_CHECK"
        CUR_VER="$KCS_VERSION"
        CUR_LANG="$PREFERRED_LANG"
        CUR_PLAT="$PLATFORM"
        CUR_CRI="$CRI_SOCKET"
        CUR_PG_USER="$POSTGRES_USER"
        CUR_PG_PASS="$POSTGRES_PASSWORD"
        CUR_MINIO_USER="$MINIO_ROOT_USER"
        CUR_MINIO_PASS="$MINIO_ROOT_PASSWORD"
        CUR_CH_ADMIN_PASS="$CLICKHOUSE_ADMIN_PASSWORD"
        CUR_CH_WRITE_PASS="$CLICKHOUSE_WRITE_PASSWORD"
        CUR_CH_READ_PASS="$CLICKHOUSE_READ_PASSWORD"
        CUR_MCHD_USER="$MCHD_USER"
        CUR_MCHD_PASS="$MCHD_PASS"
        CUR_APP_SECRET="$APP_SECRET"
        CUR_AI_ENDPOINT="$OLLAMA_ENDPOINT"
        CUR_AI_MODEL="$OLLAMA_MODEL"
        config_view_config_loaded
    fi

    local TOTAL_STEPS=12

    # 1. Localization
    config_view_section "$MSG_SECTION_LOCALIZATION"
    local AVAIL_STR=$(config_service_get_locales)
    local DEF_LANG="en_US"
    [ -n "$CUR_LANG" ] && DEF_LANG="$CUR_LANG"
    
    config_view_step_lang "$TOTAL_STEPS" "$AVAIL_STR" "$DEF_LANG" "$CUR_LANG"
    PREFERRED_LANG="$RET_VAL"

    # Hot-swap locale
    NEW_LOCALE_FILE="$SCRIPT_DIR/locales/${PREFERRED_LANG}.sh"
    [ -f "$NEW_LOCALE_FILE" ] && source "$NEW_LOCALE_FILE"

    # 2. Cluster Context
    config_view_section "$MSG_SECTION_CLUSTER"

    # Platform (Step 2)
    config_view_step_generic 2 "$TOTAL_STEPS" "$MSG_STEP_PLATFORM" "$MSG_STEP_PLATFORM_DESC" "$MSG_INPUT_PLATFORM" "kubernetes" "$CUR_PLAT"
    PLATFORM="$RET_VAL"

    # CRI Socket (Step 3)
    local SUGGESTED_CRI=$(kubeconfig_get_suggested_cri "$CUR_CRI")
    config_view_step_generic 3 "$TOTAL_STEPS" "$MSG_STEP_CRI" "$MSG_STEP_CRI_DESC" "$MSG_INPUT_CRI_SOCKET" "$SUGGESTED_CRI" "$CUR_CRI"
    CRI_SOCKET="$RET_VAL"

    # Domain (Step 4)
    config_view_step_generic 4 "$TOTAL_STEPS" "$MSG_STEP_DOMAIN" "$MSG_STEP_DOMAIN_DESC" "$MSG_INPUT_DOMAIN" "kcs.cluster.lab" "$CUR_DOMAIN"
    DOMAIN="$RET_VAL"

    # 3. Product Configuration
    config_view_section "$MSG_SECTION_PRODUCT"

    # Version (Step 5)
    config_view_step_generic 5 "$TOTAL_STEPS" "$MSG_STEP_VERSION" "$MSG_STEP_VERSION_DESC" "$MSG_INPUT_VERSION" "latest" "$CUR_VER"
    KCS_VERSION="$RET_VAL"

    # Namespace (Step 6)
    config_view_step_generic 6 "$TOTAL_STEPS" "$MSG_STEP_NS" "$MSG_STEP_NS_DESC" "$MSG_INPUT_NS" "kcs" "$CUR_NS"
    NAMESPACE="$RET_VAL"

    # 4. Networking
    config_view_section "$MSG_SECTION_NETWORKING"

    # MetalLB (Step 7)
    config_view_step_generic 7 "$TOTAL_STEPS" "$MSG_STEP_METALLB" "$MSG_STEP_METALLB_DESC" "$MSG_INPUT_IP_RANGE" "" "$CUR_IP_RANGE"
    IP_RANGE="$RET_VAL"

    # 5. Registry & Security
    config_view_section "$MSG_SECTION_SECURITY"

    # Registry (Step 8)
    view_ui_step 8 "$TOTAL_STEPS" "$MSG_STEP_REG" "$MSG_STEP_REG_DESC"
    view_ui_input "$MSG_INPUT_REG_URL" "repo.kcs.kaspersky.com" "$CUR_REG_SRV"
    REGISTRY_SERVER="$RET_VAL"
    view_ui_input "$MSG_INPUT_REG_USER" "" "$CUR_REG_USER"
    REGISTRY_USER="$RET_VAL"
    view_ui_input "$MSG_INPUT_REG_PASS" "" "****" "yes"
    if [ "$RET_VAL" != "****" ]; then
         REGISTRY_PASS="$RET_VAL"
    fi
    view_ui_input "$MSG_INPUT_REG_EMAIL" "" "$CUR_REG_EMAIL"
    REGISTRY_EMAIL="$RET_VAL"

    # Secrets (Step 9)
    config_view_step_generic 9 "$TOTAL_STEPS" "$MSG_STEP_SECRETS" "$MSG_STEP_SECRETS_DESC" "$MSG_INPUT_SECRETS_AUTO" "y" "y"
    local AUTO_GEN="$RET_VAL"

    if [[ "$AUTO_GEN" =~ ^[yY]$ ]]; then
        POSTGRES_USER="${CUR_PG_USER:-pguser}"
        POSTGRES_PASSWORD="$(config_service_generate_secret)"
        MINIO_ROOT_USER="${CUR_MINIO_USER:-miniouser}"
        MINIO_ROOT_PASSWORD="$(config_service_generate_secret)"
        CLICKHOUSE_ADMIN_PASSWORD="$(config_service_generate_secret)"
        CLICKHOUSE_WRITE_PASSWORD="$(config_service_generate_secret)"
        CLICKHOUSE_READ_PASSWORD="$(config_service_generate_secret)"
        MCHD_USER="${CUR_MCHD_USER:-mchduser}"
        MCHD_PASS="$(config_service_generate_secret)"
        APP_SECRET="$(config_service_generate_secret)"
        config_view_secrets_generated
    else
        view_ui_input "$MSG_INPUT_PG_USER" "pguser" "$CUR_PG_USER"; POSTGRES_USER="$RET_VAL"
        view_ui_input "$MSG_INPUT_PG_PASS" "Ka5per5Ky!" "$CUR_PG_PASS"; POSTGRES_PASSWORD="$RET_VAL"
        view_ui_input "$MSG_INPUT_MINIO_USER" "miniouser" "$CUR_MINIO_USER"; MINIO_ROOT_USER="$RET_VAL"
        view_ui_input "$MSG_INPUT_MINIO_PASS" "Ka5per5Ky!" "$CUR_MINIO_PASS"; MINIO_ROOT_PASSWORD="$RET_VAL"
        view_ui_input "$MSG_INPUT_CH_ADMIN_PASS" "Ka5per5Ky!" "$CUR_CH_ADMIN_PASS"; CLICKHOUSE_ADMIN_PASSWORD="$RET_VAL"
        view_ui_input "$MSG_INPUT_CH_WRITE_PASS" "Ka5per5Ky!" "$CUR_CH_WRITE_PASS"; CLICKHOUSE_WRITE_PASSWORD="$RET_VAL"
        view_ui_input "$MSG_INPUT_CH_READ_PASS" "Ka5per5Ky!" "$CUR_CH_READ_PASS"; CLICKHOUSE_READ_PASSWORD="$RET_VAL"
        view_ui_input "$MSG_INPUT_MCHD_USER" "mchduser" "$CUR_MCHD_USER"; MCHD_USER="$RET_VAL"
        view_ui_input "$MSG_INPUT_MCHD_PASS" "Ka5per5Ky!" "$CUR_MCHD_PASS"; MCHD_PASS="$RET_VAL"
        view_ui_input "$MSG_INPUT_APP_SECRET" "Ka5per5Ky!" "$CUR_APP_SECRET"; APP_SECRET="$RET_VAL"
    fi

    # 6. Operational Diagnostics
    config_view_section "$MSG_SECTION_DIAGNOSTICS"

    # Deep Check (Step 10)
    config_view_step_generic 10 "$TOTAL_STEPS" "$MSG_STEP_DEEP" "$MSG_STEP_DEEP_DESC" "$MSG_INPUT_DEEP" "false" "$CUR_DEEP"
    ENABLE_DEEP_CHECK="$RET_VAL"

    # 7. AI Capabilities (Ollama)
    config_view_section "$MSG_SECTION_AI"

    # AI Endpoint (Step 11)
    config_view_step_generic 11 "$TOTAL_STEPS" "$MSG_STEP_AI" "$MSG_STEP_AI_DESC" "$MSG_INPUT_AI_ENDPOINT" "http://localhost:11434" "$CUR_AI_ENDPOINT"
    OLLAMA_ENDPOINT="$RET_VAL"

    # AI Model (Step 12)
    config_view_step_generic 12 "$TOTAL_STEPS" "$MSG_STEP_AI" "$MSG_STEP_AI_DESC" "$MSG_INPUT_AI_MODEL" "llama3" "$CUR_AI_MODEL"
    OLLAMA_MODEL="$RET_VAL"

    local NEW_CONFIG=" # KCS PoC Configuration
# Generated on $(date)

# Localization
PREFERRED_LANG=\"$PREFERRED_LANG\"

NAMESPACE=\"$NAMESPACE\"
DOMAIN=\"$DOMAIN\"

# Registry
REGISTRY_SERVER=\"$REGISTRY_SERVER\"
REGISTRY_USER=\"$REGISTRY_USER\"
REGISTRY_PASS=\"$REGISTRY_PASS\"
REGISTRY_EMAIL=\"$REGISTRY_EMAIL\"

# Networking
IP_RANGE=\"$IP_RANGE\"

# Installation
KCS_VERSION=\"$KCS_VERSION\"
PLATFORM=\"$PLATFORM\"
CRI_SOCKET=\"$CRI_SOCKET\"

# Checks
ENABLE_DEEP_CHECK=\"$ENABLE_DEEP_CHECK\"

# Secrets
POSTGRES_USER=\"$POSTGRES_USER\"
POSTGRES_PASSWORD=\"$POSTGRES_PASSWORD\"
MINIO_ROOT_USER=\"$MINIO_ROOT_USER\"
MINIO_ROOT_PASSWORD=\"$MINIO_ROOT_PASSWORD\"
CLICKHOUSE_ADMIN_PASSWORD=\"$CLICKHOUSE_ADMIN_PASSWORD\"
CLICKHOUSE_WRITE_PASSWORD=\"$CLICKHOUSE_WRITE_PASSWORD\"
CLICKHOUSE_READ_PASSWORD=\"$CLICKHOUSE_READ_PASSWORD\"
MCHD_USER=\"$MCHD_USER\"
MCHD_PASS=\"$MCHD_PASS\"
APP_SECRET=\"$APP_SECRET\"

# AI / Ollama
OLLAMA_ENDPOINT=\"$OLLAMA_ENDPOINT\"
OLLAMA_MODEL=\"$OLLAMA_MODEL\""

    config_service_save "$NEW_CONFIG"
    config_view_config_saved "$CONFIG_FILE"
}
