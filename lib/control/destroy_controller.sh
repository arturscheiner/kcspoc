#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: destroy_controller.sh
# Responsibility: Argument parsing and orchestration for the Destroy command
# ==============================================================================

destroy_controller() {
    local unattended=false
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --unattended)
                unattended=true
                shift
                ;;
            --help|help)
                ui_help "destroy" "$MSG_HELP_DESTROY_DESC" "$MSG_HELP_DESTROY_OPTS" "$MSG_HELP_DESTROY_EX"
                return 0
                ;;
            *)
                ui_help "destroy" "$MSG_HELP_DESTROY_DESC" "$MSG_HELP_DESTROY_OPTS" "$MSG_HELP_DESTROY_EX"
                return 1
                ;;
        esac
    done

    view_destroy_banner
    
    local target_ns="kcs"
    local cleanup_deps=false
    
    if load_config; then
        target_ns="${NAMESPACE:-kcs}"
    fi

    # Safety Check
    if [ "$unattended" == "false" ]; then
        local cluster_name=$(model_kubectl_get_current_context)
        local required_phrase=$(printf "$MSG_DESTROY_CONFIRM_PHRASE" "$cluster_name")
        
        if ! view_destroy_safety_check "$required_phrase"; then
            return 1
        fi
        
        if view_destroy_confirm_infra; then
            cleanup_deps=true
        fi
    fi

    service_destroy_run "$target_ns" "$cleanup_deps" "kcs"
}
