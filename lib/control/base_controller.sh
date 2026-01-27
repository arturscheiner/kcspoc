# ==============================================================================
# Layer: Controller
# File: base_controller.sh
# Responsibility: Orchestration and Flow Control
# ==============================================================================

base_controller_dispatch() {
    local cmd="$1"
    
    # Global Debug is now ALWAYS ON by default (via service_exec_init_logging)
    KCS_DEBUG=true

    case "$cmd" in
        config)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "config" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            config_controller "$@"
            ;;
        pull)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "pull" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            pull_controller "$@"
            ;;
        check)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "check" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            check_controller "$@"
            ;;
        prepare)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "prepare" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            prepare_controller "$@"
            ;;
        deploy)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "deploy" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            deploy_controller "$@"
            ;;
        destroy)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "destroy" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            destroy_controller "$@"
            ;;
        logs)
            shift
            if _base_control_needs_logging "$@"; then
                view_ui_slim_header "$VERSION" ""
            fi
            # No logging for the logs command itself
            logs_controller "$@"
            ;;
        bootstrap)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "bootstrap" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            bootstrap_controller "$@"
            ;;
        extras)
            shift
            if _base_control_needs_logging "$@"; then
                service_exec_init_logging "extras" "$VERSION"
                view_ui_slim_header "$VERSION" "$EXEC_HASH"
            fi
            extras_controller "$@"
            ;;
        reports)
            shift
            if _base_control_needs_logging "$@"; then
                view_ui_slim_header "$VERSION" ""
            fi
            reports_controller "$@"
            ;;
        help|*)
            view_ui_usage "$VERSION" "$EXEC_HASH"
            exit 0
            ;;
    esac
}

# --- Private Helpers ---

_base_control_needs_logging() {
    for arg in "$@"; do
        if [[ "$arg" == "help" ]] || [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
            return 1
        fi
    done
    return 0
}
