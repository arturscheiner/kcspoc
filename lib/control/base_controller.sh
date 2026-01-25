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
            _base_control_needs_logging "$@" && service_exec_init_logging "config" "$VERSION"
            config_controller "$@"
            ;;
        pull)
            shift
            _base_control_needs_logging "$@" && service_exec_init_logging "pull" "$VERSION"
            pull_controller "$@"
            ;;
        check)
            shift
            _base_control_needs_logging "$@" && service_exec_init_logging "check" "$VERSION"
            check_controller "$@"
            ;;
        prepare)
            shift
            _base_control_needs_logging "$@" && service_exec_init_logging "prepare" "$VERSION"
            prepare_controller "$@"
            ;;
        deploy)
            shift
            _base_control_needs_logging "$@" && service_exec_init_logging "deploy" "$VERSION"
            deploy_controller "$@"
            ;;
        destroy)
            shift
            _base_control_needs_logging "$@" && service_exec_init_logging "destroy" "$VERSION"
            destroy_controller "$@"
            ;;
        logs)
            shift
            # No logging for the logs command itself
            logs_controller "$@"
            ;;
        bootstrap)
            shift
            _base_control_needs_logging "$@" && service_exec_init_logging "bootstrap" "$VERSION"
            bootstrap_controller "$@"
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
