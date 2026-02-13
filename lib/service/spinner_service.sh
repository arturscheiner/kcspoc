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
        # Check if process still exists
        if kill -0 "$_SPINNER_PID" 2>/dev/null; then
            kill "$_SPINNER_PID" &>/dev/null || true
            wait "$_SPINNER_PID" &>/dev/null || true
        fi
        _SPINNER_PID=0
    fi
    
    view_ui_spinner_stop "$status"
}

service_spinner_cleanup() {
    local exit_code="$1"
    
    if [ "$_SPINNER_PID" -ne 0 ]; then
        local pid=$_SPINNER_PID
        _SPINNER_PID=0
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" &>/dev/null || true
            wait "$pid" &>/dev/null || true
        fi
        view_ui_spinner_cleanup "$exit_code"
    fi
}
