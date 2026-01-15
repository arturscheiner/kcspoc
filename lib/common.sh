#!/bin/bash

# --- VISUAL IDENTITY & CONSTANTS ---
# Colors
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons
ICON_OK="✔"
ICON_FAIL="✘"
ICON_INFO="ℹ"
ICON_WARN="⚠"
ICON_QUESTION="?"
ICON_ARROW="➜"
ICON_GEAR="⚙"

CONFIG_DIR="$HOME/.kcspoc"
CONFIG_FILE="$CONFIG_DIR/config"
VERSION="0.2.0"

# --- HELPER FUNCTIONS ---

ui_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  _  __ _____ ____  ____   ___   _____"
    echo " | |/ // ____/ ___||  _ \ / _ \ / ____|"
    echo " | ' /| |    \___ \| |_) | | | | |     "
    echo " |  < | |     ___) |  __/| |_| | |     "
    echo " |_|\_\\_____|____/|_|    \___/ \_____|"
    echo -e "${NC}"
    echo -e "${DIM}  Kaspersky Container Security - Proof of Concept Tool${NC}"
    echo -e "${BLUE}  ====================================================${NC}"
    echo -e "${DIM}  Version: ${VERSION}${NC}"
    echo -e "${DIM}  Author: Artur Scheiner${NC}"
    echo ""
}

ui_section() {
    local title="$1"
    echo -e "${MAGENTA}${BOLD}:: ${title} ::${NC}"
    echo -e "${DIM}------------------------------------------------------${NC}"
}

ui_step() {
    local current="$1"
    local total="$2"
    local title="$3"
    local desc="$4"
    echo -e "\n${BOLD}[${current}/${total}] ${title}${NC}"
    if [ -n "$desc" ]; then
        echo -e "${DIM}   ${desc}${NC}"
    fi
}

ui_input() {
    local label="$1"
    local default_val="$2"
    local current_val="$3"
    local is_secret="$4"
    
    echo -ne "   ${ICON_ARROW} ${label}"
    
    if [ -n "$default_val" ]; then
        echo -ne " ${DIM}(Default: ${default_val})${NC}"
    fi
    
    local prompt_val="${current_val:-$default_val}"
    
    echo -ne " ${CYAN}[${prompt_val}]${NC}: "
    
    if [ "$is_secret" == "yes" ]; then
        stty -echo
        read -r user_in
        stty echo
        echo ""
    else
        read -r user_in
    fi
    
    if [ -z "$user_in" ]; then
        RET_VAL="$prompt_val"
    else
        RET_VAL="$user_in"
    fi
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}
