#!/bin/bash

# ==============================================================================
# Layer: Service
# File: execution_service.sh
# Responsibility: Global execution lifecycle, logging, and state
# ==============================================================================

_KCS_CLEANUP_DONE=0
_MAIN_PID=$$

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
    
    # 1. Guard against subshells
    if [ "${BASHPID:-$$}" -ne "$_MAIN_PID" ]; then
        return
    fi

    # 2. Guard against re-entrancy
    [ "$_KCS_CLEANUP_DONE" -eq 1 ] && return
    _KCS_CLEANUP_DONE=1

    # 2. Ensure cursor is visible (UX safety)
    tput cnorm 2>/dev/null || true
    
    # 3. Cleanup background processes (spinners, etc)
    service_spinner_cleanup "$exit_code"
    
    # 4. Final state sync for logging and UI summary
    if [ -n "$EXEC_LOG_FILE" ]; then
        local status="SUCCESS"
        [ "$exit_code" -ne 0 ] && status="FAIL"
        
        service_exec_save_status "$status"
        
        # Only show log info if there was a hash generated (avoids noise for simple logs)
        if [ -n "$EXEC_HASH" ]; then
            view_ui_log_info "$EXEC_HASH"
        fi
    fi
}

service_exec_register_traps() {
    # Centralized trap for script exit
    # This catches end of script, explicit 'exit', or signals after they call exit.
    trap 'service_exec_cleanup $?' EXIT

    # Signal traps: explicitly call 'exit' to trigger the EXIT trap above.
    # This prevents the script from ignoring CTRL+C.
    trap 'exit 1' SIGINT SIGTERM
}
