#!/bin/bash

# ==============================================================================
# Layer: Service
# File: execution_service.sh
# Responsibility: Global execution lifecycle, logging, and state
# ==============================================================================

service_exec_init_logging() {
    local cmd_name="$1"
    local version="$2"
    
    EXPORTED_CMD_NAME="$cmd_name"
    
    # Generate random 6-char hash
    EXEC_HASH=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 6 | head -n 1)
    
    # Setup Log Dir
    local cmd_log_dir="$LOGS_DIR/$cmd_name"
    [ -d "$cmd_log_dir" ] || mkdir -p "$cmd_log_dir"

    # Define Log File: YYYYMMDD-HHMMSS-HASH.log
    local timestamp
    timestamp=$(date +'%Y%m%d-%H%M%S')
    EXEC_LOG_FILE="$cmd_log_dir/${timestamp}-${EXEC_HASH}.log"

    # Global Debug Output override
    DEBUG_OUT="$EXEC_LOG_FILE"
    
    # Init Log Header
    {
        echo "--- KCS EXECUTION LOG ---"
        echo "Date: $(date)"
        echo "Command: $cmd_name"
        echo "Hash: $EXEC_HASH"
        echo "Version: $version"
        echo "-------------------------"
    } > "$EXEC_LOG_FILE"
}

service_exec_save_status() {
    local status="$1" # SUCCESS or FAIL
    [ -z "$EXEC_LOG_FILE" ] && return
    echo "--- EXECUTION FINISHED: $status ---" >> "$EXEC_LOG_FILE"
}

service_exec_setup_debug() {
    local cmd_name="$1"
    local is_debug_enabled="$2"
    
    if [ "$is_debug_enabled" = true ]; then
        [ -d "$CONFIG_DIR" ] || mkdir -p "$CONFIG_DIR"
        DEBUG_OUT="$CONFIG_DIR/debug-${cmd_name}.log"
        echo "--- KCS DEBUG START: $(date) ---" > "$DEBUG_OUT"
        echo "Command: $cmd_name" >> "$DEBUG_OUT"
        echo "--------------------------------" >> "$DEBUG_OUT"
    fi
}

service_exec_wait_and_force_delete_ns() {
    local ns="$1"
    local timeout=${2:-5}
    
    # Wait up to 'timeout' seconds for normal deletion
    for i in $(seq 1 "$timeout"); do
        local status
        status=$(kubectl get namespace "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
        if [ "$status" == "NotFound" ]; then
            return 0
        fi
        sleep 1
    done
    
    # If still there (likely Terminating), force it
    model_ns_force_delete "$ns"
}

# --- Lifecycle & Traps ---

service_exec_cleanup() {
    local exit_code="$1"
    
    # Ensure cursor is visible
    tput cnorm 2>/dev/null || true
    
    # Cleanup spinner if running
    service_spinner_cleanup "$exit_code" "$EXEC_LOG_FILE" "$EXEC_HASH"
    
    # Final state sync
    if [ "$exit_code" -ne 0 ]; then
        service_exec_save_status "FAIL"
    else
        service_exec_save_status "SUCCESS"
    fi
}

service_exec_register_traps() {
    # Centralized trap for script exit
    trap 'service_exec_cleanup $?' EXIT
    trap 'service_exec_cleanup 1' SIGINT SIGTERM
}
