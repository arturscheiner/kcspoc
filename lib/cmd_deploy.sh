#!/bin/bash

cmd_deploy() {
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
                ui_help "deploy" "$MSG_HELP_DEPLOY_DESC" "$MSG_HELP_DEPLOY_OPTS" "$MSG_HELP_DEPLOY_EX"
                return 0
                ;;
            *)
                ui_help "deploy" "$MSG_HELP_DEPLOY_DESC" "$MSG_HELP_DEPLOY_OPTS" "$MSG_HELP_DEPLOY_EX"
                return 1
                ;;
        esac
    done

    # Default to help if no options provided
    if [ -z "$INSTALL_CORE" ] && [ -z "$INSTALL_AGENTS" ]; then
        ui_help "deploy" "$MSG_HELP_DEPLOY_DESC" "$MSG_HELP_DEPLOY_OPTS" "$MSG_HELP_DEPLOY_EX"
        return 1
    fi

    load_config || { echo -e "${RED}${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"; return 1; }
    ui_banner

    local INSTALL_ERROR=0

    # --- 1. CORE INSTALLATION ---
    if [ "$INSTALL_CORE" == "true" ]; then
        ui_section "$MSG_DEPLOY_CORE"
        
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
                      -f \"$PROCESSED_VALUES\""
                else
                    # Fallback to OCI
                    echo -e "      ${YELLOW}${ICON_INFO} Local artifact not found for $TARGET_VER. Falling back to OCI...${NC}" >> "$DEBUG_OUT"
                    HELM_CMD="helm upgrade --install kcs oci://$REGISTRY_SERVER/charts/kcs \
                      --version $TARGET_VER \
                      -n \"$NAMESPACE\" \
                      -f \"$PROCESSED_VALUES\""
                fi

                if eval "$HELM_CMD" &>> "$DEBUG_OUT"; then
                    ui_spinner_stop "PASS"
                    # Run health check if Helm deployment was accepted
                    _verify_deploy_bootstrap "$NAMESPACE"
                else
                    ui_spinner_stop "FAIL"
                    INSTALL_ERROR=1
                fi
            fi
        fi
    fi

    # --- 2. AGENTS INSTALLATION (Placeholder) ---
    if [ "$INSTALL_AGENTS" == "true" ]; then
        ui_section "$MSG_DEPLOY_AGENTS"
        echo -e "   ${YELLOW}${ICON_INFO} Agents deployment logic is being finalized.${NC}"
        echo -e "      ${DIM}Manual deploy: ./kcspoc pull --version X && helm install agents...${NC}"
    fi

    echo ""
    # Clean up temporary processed values
    [ -f "$CONFIG_DIR/processed-values.yaml" ] && rm "$CONFIG_DIR/processed-values.yaml"

    if [ "$INSTALL_ERROR" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}${ICON_OK} $MSG_DEPLOY_SUCCESS${NC}"
        echo -e "\n  ${BOLD}${MSG_DEPLOY_BOOTSTRAP_HINT}${NC}"
        echo -e "  ${CYAN}kubectl get pods -n $NAMESPACE -w${NC}\n"
    else
        echo -e "${RED}${BOLD}${ICON_FAIL} Installation failed. Check logs with: ./kcspoc logs --show $EXEC_HASH${NC}"
        return 1
    fi
}

# --- Helpers ---

_verify_deploy_bootstrap() {
    local ns="$1"
    
    echo -e "\n  ${BOLD}${ICON_GEAR} ${MSG_DEPLOY_HEALTH_CHECK}${NC}"
    
    # 1. Verify PVCs
    ui_spinner_start "${MSG_DEPLOY_PVC_STATUS}"
    # Wait a bit for PVCs to settle
    sleep 2
    local pvc_count=$(kubectl get pvc -n "$ns" --no-headers 2>/dev/null | wc -l)
    if [ "$pvc_count" -gt 0 ]; then
        local pending_pvc=$(kubectl get pvc -n "$ns" --no-headers 2>/dev/null | grep -v "Bound" | wc -l)
        if [ "$pending_pvc" -eq 0 ]; then
            ui_spinner_stop "PASS"
        else
            ui_spinner_stop "INFO"
            echo -e "      ${YELLOW}${ICON_INFO} $pending_pvc PVC(s) are still pending. This is normal during bootstrap.${NC}"
        fi
    else
        ui_spinner_stop "SKIP"
    fi

    # 2. Verify Labelling
    ui_spinner_start "${MSG_DEPLOY_LABEL_CHECK}"
    if kubectl get ns "$ns" -o jsonpath='{.metadata.labels.provisioned-by}' 2>/dev/null | grep -q "kcspoc"; then
        ui_spinner_stop "PASS"
    else
        # Apply labels if missing (best effort)
        kubectl label ns "$ns" provisioned-by=kcspoc --overwrite &>> "$DEBUG_OUT"
        ui_spinner_stop "FIXED"
    fi

    # 3. Monitor Pods (Short loop to detect initial pod creation)
    ui_spinner_start "${MSG_DEPLOY_POD_STATUS}"
    local pods_started=0
    for i in {1..8}; do
        local pods_count=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
        if [ "$pods_count" -gt 0 ]; then
            pods_started=1
            break
        fi
        sleep 3
    done

    if [ "$pods_started" -eq 1 ]; then
        # Check for Pulling events as a sign of progress
        local pulling=$(kubectl get events -n "$ns" --sort-by='.lastTimestamp' 2>/dev/null | grep -iE "Pulling|Pulled|Started" | tail -n 1)
        if [ -n "$pulling" ]; then
             ui_spinner_stop "PASS"
             echo -e "      ${DIM}Event: $(echo $pulling | awk '{print $4, $5, $6, $7, $8}')${NC}"
        else
             ui_spinner_stop "PASS"
        fi
    else
        ui_spinner_stop "WARN"
    fi
    
    echo -e "\n  ${GREEN}${ICON_OK} ${MSG_DEPLOY_BOOTSTRAP_OK}${NC}"
}
