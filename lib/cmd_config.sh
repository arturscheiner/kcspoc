#!/bin/bash

cmd_config() {
    ui_banner
    ui_section "$MSG_CONFIG_WIZARD_TITLE"
    echo -e "$MSG_CONFIG_WIZARD_DESC"
    echo ""

    mkdir -p "$CONFIG_DIR"
    
    # Load existing config to show as "Current"
    local CUR_NS="" CUR_DOMAIN="" CUR_REG_SRV="" CUR_REG_USER="" CUR_REG_EMAIL="" CUR_IP_RANGE="" CUR_DEEP="" CUR_VER=""
    
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
        echo -e "${GREEN}${ICON_OK} $MSG_CONFIG_LOADED${NC}"
    fi

    # 1. Namespace
    ui_step 1 6 "$MSG_STEP_NS" "$MSG_STEP_NS_DESC"
    ui_input "$MSG_INPUT_NS" "kcs" "$CUR_NS"
    NAMESPACE="$RET_VAL"

    # 2. Domain
    ui_step 2 6 "$MSG_STEP_DOMAIN" "$MSG_STEP_DOMAIN_DESC"
    ui_input "$MSG_INPUT_DOMAIN" "kcs.cluster.lab" "$CUR_DOMAIN"
    DOMAIN="$RET_VAL"

    # 3. Registry
    ui_step 3 6 "$MSG_STEP_REG" "$MSG_STEP_REG_DESC"
    
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
    ui_step 4 6 "$MSG_STEP_METALLB" "$MSG_STEP_METALLB_DESC"
    ui_input "$MSG_INPUT_IP_RANGE" "" "$CUR_IP_RANGE"
    IP_RANGE="$RET_VAL"

    # 5. Deep Check
    ui_step 5 6 "$MSG_STEP_DEEP" "$MSG_STEP_DEEP_DESC"
    ui_input "$MSG_INPUT_DEEP" "false" "$CUR_DEEP"
    ENABLE_DEEP_CHECK="$RET_VAL"

    # 6. Version
    ui_step 6 6 "$MSG_STEP_VERSION" "$MSG_STEP_VERSION_DESC"
    ui_input "$MSG_INPUT_VERSION" "latest" "$CUR_VER"
    KCS_VERSION="$RET_VAL"

    # Save
    cat > "$CONFIG_FILE" <<EOF
# KCS PoC Configuration
# Generated on $(date)

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

# Checks
ENABLE_DEEP_CHECK="$ENABLE_DEEP_CHECK"
EOF
    
    echo -e "\n${GREEN}${ICON_OK} $MSG_CONFIG_SAVED $CONFIG_FILE${NC}"
    echo -e "${DIM}${MSG_CONFIG_NEXT_STEPS}${NC}"
}
