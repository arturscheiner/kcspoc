#!/bin/bash

# ==============================================================================
# Layer: Service
# File: spinner_service.sh
# Responsibility: Spinner lifecycle and background process management
# ==============================================================================

_SPINNER_PID=0

service_spinner_start() {
    local msg="$1"
    view_ui_spinner_start "$msg"
    
    (
        local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        while true; do
            for frame in "${frames[@]}"; do
                echo -ne "${CYAN}${frame}${NC}"
                sleep 0.1
                echo -ne "\b"
            done
        done
    ) &
    _SPINNER_PID=$!
}

service_spinner_stop() {
    local status="$1" # PASS or FAIL
    
    if [ "$_SPINNER_PID" -ne 0 ]; then
        kill "$_SPINNER_PID" &>/dev/null || true
        wait "$_SPINNER_PID" &>/dev/null || true
        _SPINNER_PID=0
    fi
    
    view_ui_spinner_stop "$status"
}

service_spinner_cleanup() {
    local exit_code="$1"
    local exec_log_file="$2"
    local exec_hash="$3"
    
    # 1. Spinner Cleanup
    if [ "$_SPINNER_PID" -ne 0 ]; then
        kill "$_SPINNER_PID" &>/dev/null || true
        wait "$_SPINNER_PID" &>/dev/null || true
        _SPINNER_PID=0
        view_ui_spinner_cleanup "$exit_code"
    fi

    # 2. Log Finalization (If logging was active)
    if [ -n "$exec_log_file" ]; then
        local status="SUCCESS"
        [ "$exit_code" -ne 0 ] && status="FAIL"
        
        service_exec_save_status "$status"
        view_ui_log_info "$exec_hash"
    fi
}
