#!/bin/bash

cmd_config() {
    ui_banner
    ui_section "Configuration Wizard"
    echo -e "This wizard generates the ${YELLOW}~/.kcspoc/config${NC} file."
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
        echo -e "${GREEN}${ICON_OK} Loaded existing configuration.${NC}"
    fi

    # 1. Namespace
    ui_step 1 6 "Kubernetes Namespace" "Where KCS resources will be created."
    ui_input "Namespace" "kcs" "$CUR_NS"
    NAMESPACE="$RET_VAL"

    # 2. Domain
    ui_step 2 6 "Base Domain" "Domain for KCS console/services (e.g. kcs.lab)."
    ui_input "Domain" "kcs.cluster.lab" "$CUR_DOMAIN"
    DOMAIN="$RET_VAL"

    # 3. Registry
    ui_step 3 6 "Registry Credentials" "Access to KCS container images."
    
    ui_input "Server URL" "repo.kcs.kaspersky.com" "$CUR_REG_SRV"
    REGISTRY_SERVER="$RET_VAL"
    
    ui_input "Username" "" "$CUR_REG_USER"
    REGISTRY_USER="$RET_VAL"
    
    ui_input "Password" "" "****" "yes"
    # If user hit enter (empty) and we had a previous password (**** aka set), keep old param
    if [ "$RET_VAL" == "****" ]; then
         REGISTRY_PASS="$REGISTRY_PASS" # Keep existing global variable
    else
         REGISTRY_PASS="$RET_VAL"
    fi
    
    ui_input "Email" "" "$CUR_REG_EMAIL"
    REGISTRY_EMAIL="$RET_VAL"

    # 4. MetalLB
    ui_step 4 6 "MetalLB IP Range" "Range for LoadBalancer (e.g. 172.16.0.10-172.16.0.20)"
    ui_input "IP Range" "" "$CUR_IP_RANGE"
    IP_RANGE="$RET_VAL"

    # 5. Deep Check
    ui_step 5 6 "Deep Node Inspection" "Run privileged pods to check disk/headers?"
    ui_input "Enable Deep Check? (true/false)" "false" "$CUR_DEEP"
    ENABLE_DEEP_CHECK="$RET_VAL"

    # 6. Version
    ui_step 6 6 "KCS Version" "Target version to install."
    ui_input "Version" "latest" "$CUR_VER"
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
    
    echo -e "\n${GREEN}${ICON_OK} Configuration saved to $CONFIG_FILE${NC}"
    echo -e "${DIM}You can now run 'kcspoc pull' or 'kcspoc check'.${NC}"
}
