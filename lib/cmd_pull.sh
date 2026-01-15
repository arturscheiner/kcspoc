#!/bin/bash

cmd_pull() {
    ui_banner
    
    # Args Parsing
    local FORCE_VERSION=""
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --version) FORCE_VERSION="$2"; shift ;;
            *) ;;
        esac
        shift
    done

    # Load Config
    if ! load_config; then
        echo -e "${RED}${ICON_FAIL} Error: Configuration not found. Please run 'kcspoc config' first.${NC}"
        exit 1
    fi
    
    ui_section "Pulling KCS Chart"

    # 1. Registry Login
    echo -e "${YELLOW}${ICON_GEAR} Authenticating to Registry ($REGISTRY_SERVER)...${NC}"
    if echo "$REGISTRY_PASS" | helm registry login "$REGISTRY_SERVER/v2/" --username "$REGISTRY_USER" --password-stdin; then
        echo -e "${GREEN}${ICON_OK} Login Successful${NC}"
    else
        echo -e "${RED}${ICON_FAIL} Login Failed${NC} (Trying fallback to root path...)"
        if echo "$REGISTRY_PASS" | helm registry login "$REGISTRY_SERVER" --username "$REGISTRY_USER" --password-stdin; then
             echo -e "${GREEN}${ICON_OK} Login Successful${NC}"
        else
             echo -e "${RED}${ICON_FAIL} Error: Could not login to registry.${NC}"
             exit 1
        fi
    fi

    # 2. Determine Version
    local TARGET_VER=""
    
    if [ -n "$FORCE_VERSION" ]; then
        TARGET_VER="$FORCE_VERSION"
        echo -e "   ${ICON_INFO} Version Source: Command Flag ($TARGET_VER)"
    elif [ -n "$KCS_VERSION" ] && [ "$KCS_VERSION" != "latest" ]; then
        TARGET_VER="$KCS_VERSION"
        echo -e "   ${ICON_INFO} Version Source: Config File ($TARGET_VER)"
    else
        TARGET_VER="latest"
        echo -e "   ${ICON_INFO} Version Source: Default (latest)"
    fi
    
    local HELM_ARGS=""
    if [ "$TARGET_VER" != "latest" ]; then
        HELM_ARGS="--version $TARGET_VER"
    fi

    # 3. Helm Pull
    cd "$CONFIG_DIR" || exit 1
    echo -e "\n${BLUE}${ICON_Arrow} Downloading KCS Chart...${NC}"
    
    # Using explicit repo URL as requested
    if helm pull oci://repo.kcs.kaspersky.com/charts/kcs $HELM_ARGS; then
        echo -e "${GREEN}${ICON_OK} Download successful.${NC}"
        
        # 4. Extract
        TGZ_FILE=$(ls -t kcs-*.tgz 2>/dev/null | head -n 1)
        
        if [ -f "$TGZ_FILE" ]; then
            echo "   Extracting $TGZ_FILE..."
            tar -xzf "$TGZ_FILE"
            echo -e "${GREEN}${ICON_OK} Chart extracted to $CONFIG_DIR${NC}"
        else
             echo -e "${RED}${ICON_FAIL} Error: Downloaded file not found!${NC}"
             exit 1
        fi
    else
        echo -e "${RED}${ICON_FAIL} Helm pull failed.${NC}"
        exit 1
    fi
}
