#!/bin/bash

# ==============================================================================
# Layer: Facade
# File: common.sh
# Responsibility: Legacy backward compatibility for pre-v0.6.0 commands.
# ==============================================================================

# --- VISUAL IDENTITY & CONSTANTS ---
# Delegated to lib/view/base_view.sh via kcspoc.sh sourcing

# --- GLOBAL CONFIGURATION ---
CONFIG_DIR="$HOME/.kcspoc"
CONFIG_FILE="$CONFIG_DIR/config"
ARTIFACTS_DIR="$CONFIG_DIR/artifacts"
LOGS_DIR="$CONFIG_DIR/logs"

# Sourced from model
VERSION=$(model_version_get)

# --- EXECUTION STATE ---
EXEC_HASH=""
EXEC_LOG_FILE=""
EXEC_CMD=""
EXEC_STATUS="UNKNOWN"
DEBUG_OUT="/dev/null"
KCS_DEBUG=false

# TODO: Remove legacy spinner PID from facade after full command migration
_SPINNER_PID=0 

# --- LOGGING & LIFECYCLE ---

init_logging() {
    service_exec_init_logging "$1" "$VERSION"
}

save_log_status() {
    service_exec_save_status "$1"
}

_update_state() {
    model_ns_update_state "$1" "$2" "$3" "$4" "$5" "$6" "${7:-0}"
}

get_config_hash() {
    model_config_get_hash
}

setup_debug() {
    service_exec_setup_debug "$1" "$KCS_DEBUG"
}

# --- LOCALE & I18N ---

load_locale() {
    service_locale_load
}

# Call it immediately when common is sourced
load_locale

# --- UI PRIMITIVES (DELEGATED TO VIEW) ---

ui_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

ui_section() {
    view_ui_section "$1"
}

ui_step() {
    view_ui_step "$1" "$2" "$3" "$4"
}

ui_input() {
    view_ui_input "$1" "$2" "$3" "$4"
}

ui_help() {
    view_ui_help "$1" "$2" "$3" "$4" "$VERSION"
}

# --- UI SPINNER (DELEGATED TO SERVICE) ---

# TODO: In v0.6.x, this trap must migrate to execution_service.sh 
# and the facade should only call service_exec_register_traps.
_ui_spinner_cleanup() {
    service_spinner_cleanup "$?" "$EXEC_LOG_FILE" "$EXEC_HASH"
}
trap _ui_spinner_cleanup EXIT

ui_spinner_start() {
    service_spinner_start "$1"
}

ui_spinner_stop() {
    service_spinner_stop "$1"
}

# --- K8S & CLUSTER OPERATIONS ---

check_k8s_label() {
    service_ns_check_label_with_ui "$1" "$2" "$3"
}

force_delete_ns() {
    model_ns_force_delete "$1"
}

wait_and_force_delete_ns() {
    service_exec_wait_and_force_delete_ns "$1" "${2:-5}"
}

# --- FILESYSTEM & CONFIG ---

download_artifact() {
    model_fs_download_artifact "$1" "$2"
}

load_config() {
    model_fs_load_config
}
