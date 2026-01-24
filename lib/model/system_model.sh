#!/bin/bash

# ==============================================================================
# Layer: Model
# File: system_model.sh
# Responsibility: Host system operations (Kernel headers, apt)
# ==============================================================================

model_system_install_headers() {
    local err_file="$1"
    if command -v sudo &>> "$DEBUG_OUT"; then
        if sudo apt update &>> "$DEBUG_OUT" && sudo apt install linux-headers-$(uname -r) -y &>> "$DEBUG_OUT"; then
            return 0
        fi
    else
        echo -e "      ${RED}${MSG_PREPARE_SUDO_FAIL}${NC}"
    fi
    return 1
}
