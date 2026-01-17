#!/bin/bash

_generate_random_secret() {
    local length=${1:-24}
    # Avoid complex characters that might break sed or shell if not escaped, 
    # but keep it strong enough. Alphanumeric only is safest for this POC tool.
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

cmd_config() {
    # Args Parsing
    local SET_VER=""
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --set-version) SET_VER="$2"; shift ;;
            --help|help)
                ui_help "config" "$MSG_HELP_CONFIG_DESC" "$MSG_HELP_CONFIG_OPTS" "$MSG_HELP_CONFIG_EX"
                return 0
                ;;
            *)
                ui_help "config" "$MSG_HELP_CONFIG_DESC" "$MSG_HELP_CONFIG_OPTS" "$MSG_HELP_CONFIG_EX"
                return 1
                ;;
        esac
        shift
    done

    # Handle --set-version early
    if [ -n "$SET_VER" ]; then
        ui_banner
        ui_section "$MSG_CONFIG_VER_UPDATED"
        
        if [ ! -f "$CONFIG_FILE" ]; then
             echo -e "   ${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
             exit 1
        fi
        
        # Load, modify and save
        source "$CONFIG_FILE"
        sed -i "s|KCS_VERSION=.*|KCS_VERSION=\"$SET_VER\"|g" "$CONFIG_FILE"
        echo -e "   ${GREEN}${ICON_OK} ${MSG_CONFIG_VER_UPDATED}: ${BOLD}${SET_VER}${NC}\n"
        return 0
    fi

    ui_banner
    ui_section "$MSG_CONFIG_WIZARD_TITLE"
    echo -e "$MSG_CONFIG_WIZARD_DESC"
    echo ""

    mkdir -p "$CONFIG_DIR"
    
    # Load existing config to show as "Current"
    local CUR_NS="" CUR_DOMAIN="" CUR_REG_SRV="" CUR_REG_USER="" CUR_REG_EMAIL="" CUR_IP_RANGE="" CUR_DEEP="" CUR_VER="" CUR_LANG="" CUR_PLAT=""
    local CUR_PG_USER="" CUR_PG_PASS="" CUR_MINIO_USER="" CUR_MINIO_PASS="" CUR_CH_ADMIN_PASS="" CUR_CH_WRITE_PASS="" CUR_CH_READ_PASS="" CUR_MCHD_USER="" CUR_MCHD_PASS="" CUR_APP_SECRET=""
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
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
        # Secrets
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
        echo -e "${GREEN}${ICON_OK} $MSG_CONFIG_LOADED${NC}"
    fi

    local TOTAL_STEPS=9

    # 0. Language (Step 1 effectively)
    ui_step 1 $TOTAL_STEPS "$MSG_STEP_LANG" "$MSG_STEP_LANG_DESC"
    
    # List available
    # We find .sh files in locales/ and strip path/extension
    AVAIL_LOCALES=$(ls "$SCRIPT_DIR/locales/"*.sh 2>/dev/null | xargs -n 1 basename | sed 's/\.sh//')
    # Format list
    AVAIL_STR=$(echo "$AVAIL_LOCALES" | tr '\n' ' ')
    echo -e "   ${DIM}${MSG_LANG_AVAILABLE}: [ $AVAIL_STR]${NC}"

    # Determine default for prompt: Current Config > System/Detected (from load_locale scope)
    # common.sh calculates LANG_CODE, but local scope might not see it if not exported.
    # Re-detect roughly or rely on what load_locale did?
    # load_locale set vars but didn't export LANG_CODE.
    # Let's re-calculate simple default if CUR_LANG is empty.
    
    local DEF_LANG="en_US"
    if [ -n "$CUR_LANG" ]; then
        DEF_LANG="$CUR_LANG"
    elif [ -n "$LC_ALL" ] || [ -n "$LANG" ]; then
         # Try to match detected system lang to available list?
         # Simplified: Defaults to en_US for the prompt if no config. 
         # Or we can grep what load_locale found.
         # Let's just default to 'en_US' if not configured, or if the user is seeing this in Portuguese, 
         # it means load_locale worked.
         # So we should default to the CURRENTLY LOADED language code.
         # We can infer it by checking which file was loaded? No.
         # Let's iterate available and check if MSG_USAGE is defined? No.
         : # No-op
    fi
   
    # If we are here, we are already speaking some language.
    # Let's assume en_US as the visual default prompt if nothing is saved.
    
    ui_input "$MSG_INPUT_LANG" "en_US" "$CUR_LANG"
    PREFERRED_LANG="$RET_VAL"

    # --- HOT-SWAP LOCALE ---
    # If user selected a new language, load it immediately so next steps use it.
    NEW_LOCALE_FILE="$SCRIPT_DIR/locales/${PREFERRED_LANG}.sh"
    if [ -f "$NEW_LOCALE_FILE" ]; then
        source "$NEW_LOCALE_FILE"
        # Optional: update visual confirmation if needed, but the next step title will be enough proof.
    fi
    # -----------------------

    # 1. Namespace
    ui_step 2 $TOTAL_STEPS "$MSG_STEP_NS" "$MSG_STEP_NS_DESC"
    ui_input "$MSG_INPUT_NS" "kcs" "$CUR_NS"
    NAMESPACE="$RET_VAL"

    # 2. Domain
    ui_step 3 $TOTAL_STEPS "$MSG_STEP_DOMAIN" "$MSG_STEP_DOMAIN_DESC"
    ui_input "$MSG_INPUT_DOMAIN" "kcs.cluster.lab" "$CUR_DOMAIN"
    DOMAIN="$RET_VAL"

    # 3. Registry
    ui_step 4 $TOTAL_STEPS "$MSG_STEP_REG" "$MSG_STEP_REG_DESC"
    
    ui_input "$MSG_INPUT_REG_URL" "repo.kcs.kaspersky.com" "$CUR_REG_SRV"
    REGISTRY_SERVER="$RET_VAL"
    
    ui_input "$MSG_INPUT_REG_USER" "" "$CUR_REG_USER"
    REGISTRY_USER="$RET_VAL"
    
    ui_input "$MSG_INPUT_REG_PASS" "" "****" "yes"
    # If user hit enter (empty) and we had a previous password (**** aka set), keep old param
    if [ "$RET_VAL" == "****" ]; then
         REGISTRY_PASS="$REGISTRY_PASS" # Keep existing global variable
    else
         REGISTRY_PASS="$RET_VAL"
    fi
    
    ui_input "$MSG_INPUT_REG_EMAIL" "" "$CUR_REG_EMAIL"
    REGISTRY_EMAIL="$RET_VAL"

    # 4. MetalLB
    ui_step 5 $TOTAL_STEPS "$MSG_STEP_METALLB" "$MSG_STEP_METALLB_DESC"
    ui_input "$MSG_INPUT_IP_RANGE" "" "$CUR_IP_RANGE"
    IP_RANGE="$RET_VAL"

    # 5. Deep Check
    ui_step 6 $TOTAL_STEPS "$MSG_STEP_DEEP" "$MSG_STEP_DEEP_DESC"
    ui_input "$MSG_INPUT_DEEP" "false" "$CUR_DEEP"
    ENABLE_DEEP_CHECK="$RET_VAL"

    # 6. Version
    ui_step 7 $TOTAL_STEPS "$MSG_STEP_VERSION" "$MSG_STEP_VERSION_DESC"
    ui_input "$MSG_INPUT_VERSION" "latest" "$CUR_VER"
    KCS_VERSION="$RET_VAL"

    # 7. Platform
    ui_step 8 $TOTAL_STEPS "$MSG_STEP_PLATFORM" "$MSG_STEP_PLATFORM_DESC"
    ui_input "$MSG_INPUT_PLATFORM" "kubernetes" "$CUR_PLAT"
    PLATFORM="$RET_VAL"

    # 8. Secrets
    ui_step 9 $TOTAL_STEPS "$MSG_STEP_SECRETS" "$MSG_STEP_SECRETS_DESC"
    ui_input "$MSG_INPUT_SECRETS_AUTO" "y" "y"
    local AUTO_GEN="$RET_VAL"

    if [[ "$AUTO_GEN" =~ ^[yY]$ ]]; then
        POSTGRES_USER="${CUR_PG_USER:-pguser}"
        POSTGRES_PASSWORD="$(_generate_random_secret)"
        MINIO_ROOT_USER="${CUR_MINIO_USER:-miniouser}"
        MINIO_ROOT_PASSWORD="$(_generate_random_secret)"
        CLICKHOUSE_ADMIN_PASSWORD="$(_generate_random_secret)"
        CLICKHOUSE_WRITE_PASSWORD="$(_generate_random_secret)"
        CLICKHOUSE_READ_PASSWORD="$(_generate_random_secret)"
        MCHD_USER="${CUR_MCHD_USER:-mchduser}"
        MCHD_PASS="$(_generate_random_secret)"
        APP_SECRET="$(_generate_random_secret)"
        echo -e "      ${DIM}${ICON_OK} Secrets generated randomly.${NC}"
    else
        ui_input "$MSG_INPUT_PG_USER" "pguser" "$CUR_PG_USER"
        POSTGRES_USER="$RET_VAL"
        ui_input "$MSG_INPUT_PG_PASS" "Ka5per5Ky!" "$CUR_PG_PASS"
        POSTGRES_PASSWORD="$RET_VAL"
        ui_input "$MSG_INPUT_MINIO_USER" "miniouser" "$CUR_MINIO_USER"
        MINIO_ROOT_USER="$RET_VAL"
        ui_input "$MSG_INPUT_MINIO_PASS" "Ka5per5Ky!" "$CUR_MINIO_PASS"
        MINIO_ROOT_PASSWORD="$RET_VAL"
        ui_input "$MSG_INPUT_CH_ADMIN_PASS" "Ka5per5Ky!" "$CUR_CH_ADMIN_PASS"
        CLICKHOUSE_ADMIN_PASSWORD="$RET_VAL"
        ui_input "$MSG_INPUT_CH_WRITE_PASS" "Ka5per5Ky!" "$CUR_CH_WRITE_PASS"
        CLICKHOUSE_WRITE_PASSWORD="$RET_VAL"
        ui_input "$MSG_INPUT_CH_READ_PASS" "Ka5per5Ky!" "$CUR_CH_READ_PASS"
        CLICKHOUSE_READ_PASSWORD="$RET_VAL"
        ui_input "$MSG_INPUT_MCHD_USER" "mchduser" "$CUR_MCHD_USER"
        MCHD_USER="$RET_VAL"
        ui_input "$MSG_INPUT_MCHD_PASS" "Ka5per5Ky!" "$CUR_MCHD_PASS"
        MCHD_PASS="$RET_VAL"
        ui_input "$MSG_INPUT_APP_SECRET" "Ka5per5Ky!" "$CUR_APP_SECRET"
        APP_SECRET="$RET_VAL"
    fi

    # Save
    cat > "$CONFIG_FILE" <<EOF
# KCS PoC Configuration
# Generated on $(date)

# Localization
PREFERRED_LANG="$PREFERRED_LANG"

NAMESPACE="$NAMESPACE"
DOMAIN="$DOMAIN"

# Registry
REGISTRY_SERVER="$REGISTRY_SERVER"
REGISTRY_USER="$REGISTRY_USER"
REGISTRY_PASS="$REGISTRY_PASS"
REGISTRY_EMAIL="$REGISTRY_EMAIL"

# Networking
IP_RANGE="$IP_RANGE"

# Installation
KCS_VERSION="$KCS_VERSION"
PLATFORM="$PLATFORM"

# Checks
ENABLE_DEEP_CHECK="$ENABLE_DEEP_CHECK"

# Secrets
POSTGRES_USER="$POSTGRES_USER"
POSTGRES_PASSWORD="$POSTGRES_PASSWORD"
MINIO_ROOT_USER="$MINIO_ROOT_USER"
MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD"
CLICKHOUSE_ADMIN_PASSWORD="$CLICKHOUSE_ADMIN_PASSWORD"
CLICKHOUSE_WRITE_PASSWORD="$CLICKHOUSE_WRITE_PASSWORD"
CLICKHOUSE_READ_PASSWORD="$CLICKHOUSE_READ_PASSWORD"
MCHD_USER="$MCHD_USER"
MCHD_PASS="$MCHD_PASS"
APP_SECRET="$APP_SECRET"
EOF
    
    echo -e "\n${GREEN}${ICON_OK} $MSG_CONFIG_SAVED $CONFIG_FILE${NC}"
    echo -e "${DIM}${MSG_CONFIG_NEXT_STEPS}${NC}"
}
