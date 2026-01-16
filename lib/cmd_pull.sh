#!/bin/bash

cmd_pull() {
    ui_banner
    
    # Args Parsing
    local FORCE_VERSION=""
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --version) FORCE_VERSION="$2"; shift ;;
            --help|help)
                ui_help "pull" "$MSG_HELP_PULL_DESC" "$MSG_HELP_PULL_OPTS" "$MSG_HELP_PULL_EX"
                return 0
                ;;
            *)
                ui_help "pull" "$MSG_HELP_PULL_DESC" "$MSG_HELP_PULL_OPTS" "$MSG_HELP_PULL_EX"
                return 1
                ;;
        esac
        shift
    done

    # Load Config
    if ! load_config; then
        echo -e "${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
        exit 1
    fi
    
    ui_section "$MSG_PULL_TITLE"

    # 1. Registry Login
    ui_spinner_start "${MSG_PULL_AUTH}"
    if echo "$REGISTRY_PASS" | helm registry login "$REGISTRY_SERVER/v2/" --username "$REGISTRY_USER" --password-stdin 2>&1 | tee -a "$DEBUG_OUT" > /dev/null; then
        ui_spinner_stop "PASS"
    else
        ui_spinner_stop "FAIL"
        echo -e "      ${YELLOW}${ICON_INFO} $MSG_PULL_LOGIN_FAIL ($REGISTRY_SERVER)...${NC}"
        ui_spinner_start "${MSG_PULL_AUTH} (Fallback)"
        if echo "$REGISTRY_PASS" | helm registry login "$REGISTRY_SERVER" --username "$REGISTRY_USER" --password-stdin 2>&1 | tee -a "$DEBUG_OUT" > /dev/null; then
             ui_spinner_stop "PASS"
        else
             ui_spinner_stop "FAIL"
             echo -e "      ${RED}${ICON_FAIL} ${MSG_PULL_LOGIN_ERR}${NC}"
             exit 1
        fi
    fi

    # 2. Determine Version
    local TARGET_VER=""
    
    if [ -n "$FORCE_VERSION" ]; then
        TARGET_VER="$FORCE_VERSION"
        echo -e "   ${ICON_INFO} ${MSG_PULL_VER_SRC_FLAG} ($TARGET_VER)"
    elif [ -n "$KCS_VERSION" ] && [ "$KCS_VERSION" != "latest" ]; then
        TARGET_VER="$KCS_VERSION"
        echo -e "   ${ICON_INFO} ${MSG_PULL_VER_SRC_CONFIG} ($TARGET_VER)"
    else
        TARGET_VER="latest"
        echo -e "   ${ICON_INFO} ${MSG_PULL_VER_SRC_DEFAULT}"
    fi
    
    local HELM_ARGS=""
    if [ "$TARGET_VER" != "latest" ]; then
        HELM_ARGS="--version $TARGET_VER"
    fi

    # 3. Helm Pull
    cd "$CONFIG_DIR" || exit 1
    ui_spinner_start "$MSG_PULL_DOWNLOADING"
    
    # Using explicit repo URL as requested
    if helm pull oci://repo.kcs.kaspersky.com/charts/kcs $HELM_ARGS 2>&1 | tee -a "$DEBUG_OUT" > /dev/null; then
        ui_spinner_stop "PASS"
        
        # 4. Extract
        TGZ_FILE=$(ls -t kcs-*.tgz 2>/dev/null | head -n 1)
        
        if [ -f "$TGZ_FILE" ]; then
            echo -ne "      ${ICON_GEAR} ${MSG_PULL_EXTRACTING}... "
            tar -xzf "$TGZ_FILE" &>> "$DEBUG_OUT"
            echo -e "${GREEN}${ICON_OK}${NC}"
            echo -e "      ${DIM}${MSG_PULL_EXTRACTED}: $CONFIG_DIR${NC}"
        else
            echo -e "      ${RED}${ICON_FAIL} ${MSG_PULL_ERR_FILE}${NC}"
            exit 1
        fi
    else
        ui_spinner_stop "FAIL"
        echo -e "      ${RED}${ICON_FAIL} ${MSG_PULL_ERR_FAIL}${NC}"
        exit 1
    fi
}
