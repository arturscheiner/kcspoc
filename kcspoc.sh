#!/bin/bash

# ==============================================================================
# Script: kcspoc.sh
# Description: CLI tool for Kaspersky Container Security PoC management.
#              Provides interactive configuration, environment checking, and preparation.
# Environment: Linux (Ubuntu/Debian preferred), K8s
# ==============================================================================

set -e

# Resolve Script Directory to find libs (Handles Symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
LIB_DIR="$SCRIPT_DIR/lib"

# Check lib existence
if [ ! -d "$LIB_DIR" ]; then
    echo "Error: Library directory not found at $LIB_DIR"
    exit 1
fi

# Source MVC Components (v0.6.0+)
for layer in model view service control; do
    if [ -d "$LIB_DIR/$layer" ]; then
        for component in "$LIB_DIR/$layer"/*.sh; do
            [ -f "$component" ] && source "$component"
        done
    fi
done

# Initialize Infrastructure (v0.6.0+)
VERSION=$(model_version_get)
service_locale_load
service_exec_register_traps

# Source Commands (Decommissioned lib/cmd_*.sh wrappers, calling controllers directly)

cmd_usage() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
    echo -e "${BLUE}${BOLD}${MSG_USAGE}:${NC}"
    echo -e "  kcspoc <command> [options]\n"

    echo -e "${BLUE}${BOLD}${MSG_COMMANDS}:${NC}"
    printf "  ${CYAN}%-10s${NC} %s\n" "config"  "$MSG_CMD_CONFIG_DESC"
    printf "  ${CYAN}%-10s${NC} %s\n" "pull"    "$MSG_CMD_PULL_DESC"
    printf "  ${CYAN}%-10s${NC} %s\n" "check"   "$MSG_CMD_CHECK_DESC"
    printf "  ${CYAN}%-10s${NC} %s\n" "prepare" "$MSG_CMD_PREPARE_DESC"
    printf "  ${CYAN}%-10s${NC} %s\n" "deploy"  "$MSG_CMD_DEPLOY_DESC"
    printf "  ${CYAN}%-10s${NC} %s\n" "destroy" "$MSG_DESTROY_TITLE"
    printf "  ${CYAN}%-10s${NC} %s\n" "logs"    "Manage logs (--list, --show, --cleanup)"
    printf "  ${CYAN}%-10s${NC} %s\n" "bootstrap" "Configure KCS API Integration (API Token)"
    printf "  ${CYAN}%-10s${NC} %s\n" "help"    "$MSG_CMD_HELP_DESC"
    echo ""

    echo -e "${BLUE}${BOLD}${MSG_HELP_EXAMPLES}:${NC}"
    echo -e "  ${DIM}# Start here${NC}"
    echo -e "  kcspoc config"
    echo -e "  kcspoc check"
    echo ""
    echo -e "  ${DIM}# Installation flow${NC}"
    echo -e "  kcspoc pull"
    echo -e "  kcspoc prepare"
    echo -e "  kcspoc deploy --core"
    echo -e "  kcspoc bootstrap"
    echo ""
    echo -e "  ${DIM}# Troubleshooting${NC}"
    echo -e "  kcspoc logs --list"
    echo ""
    exit 0
}

# --- CLI Logic ---

# Global Debug is now ALWAYS ON by default (handled by service_exec_service_exec_init_logging)
KCS_DEBUG=true

# Helper to check if help is requested (to avoid creating log files)
cmd_needs_logging() {
    for arg in "$@"; do
        if [[ "$arg" == "help" ]] || [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
            return 1
        fi
    done
    return 0
}

case "$1" in
    config)
        shift
        cmd_needs_logging "$@" && service_exec_service_exec_init_logging "config"
        config_controller "$@"
        ;;
    pull)
        shift
        cmd_needs_logging "$@" && service_exec_service_exec_init_logging "pull"
        pull_controller "$@"
        ;;
    check)
        shift
        cmd_needs_logging "$@" && service_exec_service_exec_init_logging "check"
        check_controller "$@"
        ;;
    prepare)
        shift
        cmd_needs_logging "$@" && service_exec_service_exec_init_logging "prepare"
        prepare_controller "$@"
        ;;
    deploy)
        shift
        cmd_needs_logging "$@" && service_exec_service_exec_init_logging "deploy"
        deploy_controller "$@"
        ;;
    destroy)
        shift
        cmd_needs_logging "$@" && service_exec_service_exec_init_logging "destroy"
        destroy_controller "$@"
        ;;
    logs)
        shift
        # No logging for the logs command itself
        logs_controller "$@"
        ;;
    bootstrap)
        shift
        cmd_needs_logging "$@" && service_exec_service_exec_init_logging "bootstrap"
        bootstrap_controller "$@"
        ;;
    help|*)
        cmd_usage
        ;;
esac
