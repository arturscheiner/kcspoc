#!/bin/bash

cmd_install() {
    # --- Parse Arguments ---
    local INSTALL_CORE=""
    local INSTALL_AGENTS=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --core)
                INSTALL_CORE="true"
                shift
                ;;
            --agents)
                INSTALL_AGENTS="true"
                shift
                ;;
            --help|help)
                ui_help "install" "$MSG_HELP_INSTALL_DESC" "$MSG_HELP_INSTALL_OPTS" "$MSG_HELP_INSTALL_EX"
                return 0
                ;;
            *)
                ui_help "install" "$MSG_HELP_INSTALL_DESC" "$MSG_HELP_INSTALL_OPTS" "$MSG_HELP_INSTALL_EX"
                return 1
                ;;
        esac
    done

    # Default to help if no options provided
    if [ -z "$INSTALL_CORE" ] && [ -z "$INSTALL_AGENTS" ]; then
        ui_help "install" "$MSG_HELP_INSTALL_DESC" "$MSG_HELP_INSTALL_OPTS" "$MSG_HELP_INSTALL_EX"
        return 1
    fi

    load_config || { echo -e "${RED}${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"; return 1; }
    ui_banner

    local INSTALL_ERROR=0

    # --- 1. CORE INSTALLATION ---
    if [ "$INSTALL_CORE" == "true" ]; then
        ui_section "$MSG_INSTALL_CORE_STEP"
        
        # 1.1 Namespace Setup
        ui_spinner_start "$MSG_PREPARE_STEP_1_A"
        force_delete_ns "$NAMESPACE"
        if kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT" && \
           kubectl label namespace "$NAMESPACE" $POC_LABEL --overwrite &>> "$DEBUG_OUT"; then
            ui_spinner_stop "PASS"
        else
            ui_spinner_stop "FAIL"
            INSTALL_ERROR=1
        fi

        # 1.2 Secret Setup
        if [ "$INSTALL_ERROR" -eq 0 ]; then
            ui_spinner_start "$MSG_PREPARE_STEP_1_B"
            if kubectl create secret docker-registry kcs-registry-secret \
              --docker-server="$REGISTRY_SERVER" \
              --docker-username="$REGISTRY_USER" \
              --docker-password="$REGISTRY_PASS" \
              --docker-email="$REGISTRY_EMAIL" \
              -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT" && \
              kubectl label secret kcs-registry-secret -n "$NAMESPACE" $POC_LABEL --overwrite &>> "$DEBUG_OUT"; then
                ui_spinner_stop "PASS"
            else
                ui_spinner_stop "FAIL"
                INSTALL_ERROR=1
            fi
        fi

        # 1.3 Helm Installation
        if [ "$INSTALL_ERROR" -eq 0 ]; then
            ui_spinner_start "Helm Upgrade/Install (KCS Core)"
            
            # Determine Version to use
            local TARGET_VER="${KCS_VERSION:-latest}"
            local ARTIFACT_PATH="$ARTIFACTS_DIR/kcs/$TARGET_VER"
            local CHART_PATH="$ARTIFACT_PATH/kcs"
            local BASE_VALUES="$CHART_PATH/values.yaml"

            if [ "$INSTALL_ERROR" -eq 0 ]; then
                # 1.3.1 Process Dynamic Overrides
                local DYNAMIC_TEMPLATE="$SCRIPT_DIR/templates/values-core.yaml"
                local PROCESSED_VALUES="$CONFIG_DIR/processed-values.yaml"
                
                if [ -f "$DYNAMIC_TEMPLATE" ]; then
                    cp "$DYNAMIC_TEMPLATE" "$PROCESSED_VALUES"
                    sed -i "s|\$DOMAIN_CONFIGURED|$DOMAIN|g" "$PROCESSED_VALUES"
                    sed -i "s|\$REGISTRY_SERVER_CONFIG|$REGISTRY_SERVER|g" "$PROCESSED_VALUES"
                    sed -i "s|\$REGISTRY_USER_CONFIG|$REGISTRY_USER|g" "$PROCESSED_VALUES"
                    sed -i "s|\$REGISTRY_PASS_CONFIG|$REGISTRY_PASS|g" "$PROCESSED_VALUES"
                    sed -i "s|\$REGISTRY_EMAIL_CONFIG|$REGISTRY_EMAIL|g" "$PROCESSED_VALUES"
                    sed -i "s|\${KCS_VERSION}|$TARGET_VER|g" "$PROCESSED_VALUES"
                else
                    # Fallback or error if template missing
                    touch "$PROCESSED_VALUES"
                fi

                local HELM_CMD=""
                
                # Check if we have the extracted artifact folder
                if [ -d "$CHART_PATH" ] && [ -f "$BASE_VALUES" ]; then
                    # Use extracted chart, base values and our processed dynamic overrides
                    HELM_CMD="helm upgrade --install kcs \"$CHART_PATH\" \
                      -n \"$NAMESPACE\" \
                      -f \"$BASE_VALUES\" \
                      -f \"$PROCESSED_VALUES\" \
                      --wait --timeout 600s"
                else
                    # Fallback to OCI
                    echo -e "      ${YELLOW}${ICON_INFO} Local artifact not found for $TARGET_VER. Falling back to OCI...${NC}" >> "$DEBUG_OUT"
                    HELM_CMD="helm upgrade --install kcs oci://$REGISTRY_SERVER/charts/kcs \
                      --version $TARGET_VER \
                      -n \"$NAMESPACE\" \
                      -f \"$PROCESSED_VALUES\" \
                      --wait --timeout 600s"
                fi

                if eval "$HELM_CMD" &>> "$DEBUG_OUT"; then
                    ui_spinner_stop "PASS"
                else
                    ui_spinner_stop "FAIL"
                    INSTALL_ERROR=1
                fi
            fi
        fi
    fi

    # --- 2. AGENTS INSTALLATION (Placeholder) ---
    if [ "$INSTALL_AGENTS" == "true" ]; then
        ui_section "$MSG_INSTALL_AGENTS_STEP"
        echo -e "   ${YELLOW}${ICON_INFO} Agents installation logic is being finalized.${NC}"
        echo -e "      ${DIM}Manual install: ./kcspoc pull --version X && helm install agents...${NC}"
    fi

    echo ""
    # Clean up temporary processed values
    [ -f "$CONFIG_DIR/processed-values.yaml" ] && rm "$CONFIG_DIR/processed-values.yaml"

    if [ "$INSTALL_ERROR" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}${ICON_OK} $MSG_INSTALL_SUCCESS${NC}"
    else
        echo -e "${RED}${BOLD}${ICON_FAIL} Installation failed. Check logs with: ./kcspoc logs --show $EXEC_HASH${NC}"
        return 1
    fi
}
