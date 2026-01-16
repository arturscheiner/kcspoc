#!/bin/bash

cmd_pull() {
    ui_banner
    
    # Args Parsing
    local FORCE_VERSION=""
    local LIST_LOCAL=""
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --version) FORCE_VERSION="$2"; shift ;;
            --list-local) LIST_LOCAL="true" ;;
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

    # Handle --local early
    if [ "$LIST_LOCAL" == "true" ]; then
        echo -e "   ${BOLD}${MSG_PULL_LOCAL_TITLE}${NC}"
        if [ -d "$kcs_artifact_base" ]; then
            # Sort version numbers naturally
            local versions=$(ls -F "$kcs_artifact_base" | grep "/" | sed 's|/||g' | sort -V)
            
            if [ -n "$versions" ]; then
                printf "   %-15s | %-20s | %-40s\n" "${BOLD}$MSG_PULL_TABLE_VER${NC}" "${BOLD}$MSG_PULL_TABLE_DATE${NC}" "${BOLD}$MSG_PULL_TABLE_PATH${NC}"
                echo -e "   ----------------|----------------------|-------------------------------------"
                for ver in $versions; do
                    local date_file="$kcs_artifact_base/$ver/.downloaded"
                    local ddate="---"
                    [ -f "$date_file" ] && ddate=$(cat "$date_file")
                    printf "   %-15s | %-20s | %-40s\n" "$ver" "$ddate" "$kcs_artifact_base/$ver"
                done
            else
                echo -e "   ${YELLOW}${ICON_INFO} ${MSG_PULL_LOCAL_EMPTY}${NC}"
            fi
        else
            echo -e "   ${YELLOW}${ICON_INFO} ${MSG_PULL_LOCAL_EMPTY}${NC}"
        fi
        echo ""
        return 0
    fi

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

    local ARTIFACT_PATH="$ARTIFACTS_DIR/kcs/$TARGET_VER"

    # 3. Cache Check
    if [ "$TARGET_VER" != "latest" ] && [ -d "$ARTIFACT_PATH/kcs" ]; then
        echo -e "   ${GREEN}${ICON_OK} ${MSG_PULL_SUCCESS}${NC} (Local cache: $TARGET_VER)"
        return 0
    fi

    # 4. Target Path Setup
    mkdir -p "$ARTIFACT_PATH" &>> "$DEBUG_OUT"

    # 5. Helm Pull
    ui_spinner_start "$MSG_PULL_DOWNLOADING"
    
    if helm pull oci://repo.kcs.kaspersky.com/charts/kcs $HELM_ARGS --destination "$ARTIFACT_PATH" 2>&1 | tee -a "$DEBUG_OUT" > /dev/null; then
        ui_spinner_stop "PASS"
        
        # 6. Extract and Resolve Real Version
        local TGZ_FILE=$(ls -t "$ARTIFACT_PATH"/kcs-*.tgz 2>/dev/null | head -n 1)
        
        if [ -f "$TGZ_FILE" ]; then
            # Extract version from filename (e.g., kcs-2.3.0.tgz -> 2.3.0)
            local REAL_VER=$(basename "$TGZ_FILE" | sed -E 's/kcs-([0-9.]+)\.tgz/\1/')
            
            # If we were using "latest", we need to rename the directory and update config
            if [ "$TARGET_VER" == "latest" ]; then
                local FINAL_ARTIFACT_PATH="$ARTIFACTS_DIR/kcs/$REAL_VER"
                
                # Check if the target version directory already exists to avoid conflict
                if [ "$ARTIFACT_PATH" != "$FINAL_ARTIFACT_PATH" ]; then
                    [ -d "$FINAL_ARTIFACT_PATH" ] && rm -rf "$FINAL_ARTIFACT_PATH"
                    mv "$ARTIFACT_PATH" "$FINAL_ARTIFACT_PATH"
                    ARTIFACT_PATH="$FINAL_ARTIFACT_PATH"
                    TGZ_FILE="$ARTIFACT_PATH/$(basename "$TGZ_FILE")"
                fi
                
                # Update Config File: KCS_VERSION="latest" -> KCS_VERSION="X.X.X"
                if [ -f "$CONFIG_FILE" ]; then
                    if grep -q "KCS_VERSION=" "$CONFIG_FILE"; then
                        sed -i "s|KCS_VERSION=.*|KCS_VERSION=\"$REAL_VER\"|g" "$CONFIG_FILE"
                    else
                        echo "KCS_VERSION=\"$REAL_VER\"" >> "$CONFIG_FILE"
                    fi
                    echo -e "      ${DIM}${ICON_INFO} Config updated: KCS_VERSION=\"$REAL_VER\"${NC}"
                fi
                TARGET_VER="$REAL_VER"
            fi

            # Double check cache again after resolving REAL_VER (only if we were latest)
            if [ -d "$ARTIFACT_PATH/kcs" ] && [ -f "$ARTIFACT_PATH/.downloaded" ]; then
                 echo -e "      ${GREEN}${ICON_OK}${NC} ${DIM}Version $REAL_VER already extracted.${NC}"
            else
                echo -ne "      ${ICON_GEAR} ${MSG_PULL_EXTRACTING} ($REAL_VER)... "
                tar -xzf "$TGZ_FILE" -C "$ARTIFACT_PATH" &>> "$DEBUG_OUT"
                echo -e "${GREEN}${ICON_OK}${NC}"
            fi

            # Save download metadata
            date +'%Y-%m-%d %H:%M' > "$ARTIFACT_PATH/.downloaded"
            echo -e "      ${DIM}${MSG_PULL_EXTRACTED}: $ARTIFACT_PATH/kcs${NC}"
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
