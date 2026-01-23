#!/bin/bash

_generate_random_secret() {
    local length=${1:-24}
    # Avoid complex characters that might break sed or shell if not escaped, 
    # but keep it strong enough. Alphanumeric only is safest for this POC tool.
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

_validate_k8s_context() {
    ui_section "$MSG_CONFIG_CTX_TITLE"
    
    # 1. Check if kubectl exists
    if ! command -v kubectl &>/dev/null; then
        echo -e "   ${RED}${ICON_FAIL} ${MSG_CONFIG_CTX_ERR_NO_CTX}${NC}"
        echo -e "   ${DIM}${MSG_CONFIG_CTX_ERR_NO_CTX_DESC}${NC}"
        return 0 # Non-blocking if kubectl is missing, maybe they don't have it yet
    fi

    # 2. List available contexts
    local contexts=($(kubectl config get-contexts -o name 2>/dev/null))
    local current_context=$(kubectl config current-context 2>/dev/null)

    if [ ${#contexts[@]} -eq 0 ]; then
        echo -e "   ${YELLOW}${ICON_WARN} ${MSG_CONFIG_CTX_ERR_NO_CTX}${NC}"
        echo -e "   ${DIM}${MSG_CONFIG_CTX_ERR_NO_CTX_DESC}${NC}"
        return 0
    fi

    echo -e "   ${ICON_INFO} ${MSG_CONFIG_CTX_DISC}"
    echo ""
    
    local i=1
    for ctx in "${contexts[@]}"; do
        local marker=" "
        if [ "$ctx" == "$current_context" ]; then
            marker="${GREEN}*${NC}"
        fi
        echo -e "      [$i] $marker $ctx"
        ((i++))
    done
    echo ""

    echo -ne "   ${ICON_QUESTION} ${MSG_CONFIG_CTX_PROMPT} "
    echo -ne "${CYAN}[${current_context}]${NC}: "
    read -r choice

    local selected_context="$current_context"
    if [ -n "$choice" ]; then
        # Check if choice is a number
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#contexts[@]} ]; then
            selected_context="${contexts[$((choice-1))]}"
        else
            # Assume choice is a context name, verify if it's in the list
            local found=false
            for ctx in "${contexts[@]}"; do
                if [ "$ctx" == "$choice" ]; then
                    found=true
                    selected_context="$ctx"
                    break
                fi
            done
            if [ "$found" = false ]; then
                echo -e "   ${YELLOW}${ICON_WARN} ${MSG_CONFIG_CTX_INVALID_SEL} ${selected_context}${NC}"
            fi
        fi
    fi

    # Switch context if different
    if [ "$selected_context" != "$current_context" ]; then
        kubectl config use-context "$selected_context" &>/dev/null
    fi

    echo -e "   ${ICON_OK} ${MSG_CONFIG_CTX_HINT}"
    echo ""
    return 0
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
    local CUR_NS="" CUR_DOMAIN="" CUR_REG_SRV="" CUR_REG_USER="" CUR_REG_EMAIL="" CUR_IP_RANGE="" CUR_DEEP="" CUR_VER="" CUR_LANG="" CUR_PLAT="" CUR_CRI=""
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
        CUR_CRI="$CRI_SOCKET"
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

    # --- [1] INTERACTION & IDENTITY ---
    ui_section "1. Interaction & Identity"
    
    # Language
    AVAIL_LOCALES=$(ls "$SCRIPT_DIR/locales/"*.sh 2>/dev/null | xargs -n 1 basename | sed 's/\.sh//')
    AVAIL_STR=$(echo "$AVAIL_LOCALES" | tr '\n' ' ')
    echo -e "   ${DIM}${MSG_LANG_AVAILABLE}: [ $AVAIL_STR]${NC}"
    ui_input "$MSG_INPUT_LANG" "en_US" "$CUR_LANG"
    PREFERRED_LANG="$RET_VAL"

    # --- HOT-SWAP LOCALE ---
    NEW_LOCALE_FILE="$SCRIPT_DIR/locales/${PREFERRED_LANG}.sh"
    if [ -f "$NEW_LOCALE_FILE" ]; then source "$NEW_LOCALE_FILE"; fi

    # --- [2] ENVIRONMENT & CLUSTER ---
    ui_section "2. Environment & Cluster"
    
    # Context Selection
    _validate_k8s_context

    # Platform
    ui_input "$MSG_INPUT_PLATFORM" "kubernetes" "$CUR_PLAT"
    PLATFORM="$RET_VAL"

    # CRI Socket
    local SUGGESTED_CRI="$CUR_CRI"
    if [ -z "$SUGGESTED_CRI" ]; then
        local RT_VER=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}' 2>/dev/null)
        if [[ "$RT_VER" == *"containerd"* ]]; then SUGGESTED_CRI="/run/containerd/containerd.sock"; fi
        if [[ "$RT_VER" == *"cri-o"* ]]; then SUGGESTED_CRI="/run/crio/crio.sock"; fi
        if [[ "$RT_VER" == *"docker"* ]]; then SUGGESTED_CRI="/var/run/cri-dockerd.sock"; fi
    fi
    ui_input "$MSG_INPUT_CRI_SOCKET" "$SUGGESTED_CRI" "$CUR_CRI"
    CRI_SOCKET="$RET_VAL"

    # Namespace
    ui_input "$MSG_INPUT_NS" "kcs" "$CUR_NS"
    NAMESPACE="$RET_VAL"

    # Domain
    ui_input "$MSG_INPUT_DOMAIN" "kcs.cluster.lab" "$CUR_DOMAIN"
    DOMAIN="$RET_VAL"

    # --- [3] REGISTRY & ARTIFACTS ---
    ui_section "3. Registry & Artifacts"
    
    ui_input "$MSG_INPUT_REG_URL" "repo.kcs.kaspersky.com" "$CUR_REG_SRV"
    REGISTRY_SERVER="$RET_VAL"
    
    ui_input "$MSG_INPUT_REG_USER" "" "$CUR_REG_USER"
    REGISTRY_USER="$RET_VAL"
    
    ui_input "$MSG_INPUT_REG_PASS" "" "****" "yes"
    if [ "$RET_VAL" == "****" ]; then
         REGISTRY_PASS="$REGISTRY_PASS"
    else
         REGISTRY_PASS="$RET_VAL"
    fi
    
    ui_input "$MSG_INPUT_REG_EMAIL" "" "$CUR_REG_EMAIL"
    REGISTRY_EMAIL="$RET_VAL"

    # Version
    ui_input "$MSG_INPUT_VERSION" "latest" "$CUR_VER"
    KCS_VERSION="$RET_VAL"

    # --- [4] INFRASTRUCTURE & TUNING ---
    ui_section "4. Infrastructure & Tuning"

    # MetalLB
    ui_input "$MSG_INPUT_IP_RANGE" "" "$CUR_IP_RANGE"
    IP_RANGE="$RET_VAL"

    # Deep Check
    ui_input "$MSG_INPUT_DEEP" "false" "$CUR_DEEP"
    ENABLE_DEEP_CHECK="$RET_VAL"

    # --- [5] SECURITY & PASSWORDS ---
    ui_section "5. Security & Passwords"
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
CRI_SOCKET="$CRI_SOCKET"

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
