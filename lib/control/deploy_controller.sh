#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: deploy_controller.sh
# Responsibility: Argument parsing and orchestration for the Deploy command
# ==============================================================================

deploy_controller() {
    local install_core=""
    local install_agents=""
    local values_override=""
    local check_mode=""
    local mode_override=""

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --core)
                install_core="true"
                if [[ "$2" =~ ^(install|update|upgrade)$ ]]; then
                    mode_override="$2"
                    shift
                fi
                shift
                ;;
            --agents)
                install_agents="true"
                shift
                ;;
            --check)
                check_mode="$2"
                shift; shift
                ;;
            --values|-f)
                values_override="$2"
                shift; shift
                ;;
            --help|help)
                view_ui_help "deploy" "$MSG_HELP_DEPLOY_DESC" "$MSG_HELP_DEPLOY_OPTS" "$MSG_HELP_DEPLOY_EX" "$VERSION"
                return 0
                ;;
            *)
                view_ui_help "deploy" "$MSG_HELP_DEPLOY_DESC" "$MSG_HELP_DEPLOY_OPTS" "$MSG_HELP_DEPLOY_EX" "$VERSION"
                return 1
                ;;
        esac
    done

    # Default to help
    if [ -z "$install_core" ] && [ -z "$install_agents" ] && [ -z "$check_mode" ]; then
        view_ui_help "deploy" "$MSG_HELP_DEPLOY_DESC" "$MSG_HELP_DEPLOY_OPTS" "$MSG_HELP_DEPLOY_EX" "$VERSION"
        return 1
    fi

    # Load config
    if ! model_fs_load_config &>> "$DEBUG_OUT"; then
        echo -e "${RED}${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
        return 1
    fi

    view_deploy_banner

    # Check for artifacts
    local count=$(model_deploy_count_local_artifacts)
    if [ "$count" -eq 0 ]; then
        view_deploy_error "$MSG_DEPLOY_ERR_NO_ARTIFACTS"
        return 1
    fi

    # Dispatch to Service
    if [ -n "$check_mode" ]; then
        service_deploy_check_integrity "$check_mode"
    elif [ "$install_core" == "true" ]; then
        service_deploy_core "$values_override" "$mode_override"
    elif [ "$install_agents" == "true" ]; then
        # Agents logic (Placeholder)
        view_deploy_section "$MSG_DEPLOY_AGENTS"
        view_deploy_info "Agents deployment logic is being finalized."
    fi
}
