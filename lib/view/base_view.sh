#!/bin/bash

# ==============================================================================
# Layer: View
# File: base_view.sh
# Responsibility: User Interface and Output Presentation
#
# Rules:
# 1. Responsible for all user-facing output (colors, icons, formatting).
# 2. MUST NOT contain business logic or state mutations.
# 3. Provides standardized UI components for Controllers and Services.
# ==============================================================================

# --- VISUAL IDENTITY & CONSTANTS ---
# Colors
export BOLD='\033[1m'
export DIM='\033[2m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Icons
export ICON_OK="✔"
export ICON_FAIL="✘"
export ICON_INFO="ℹ"
export ICON_WARN="⚠"
export ICON_QUESTION="?"
export ICON_ARROW="➜"
export ICON_GEAR="⚙"

# --- CORE UI COMPONENTS ---

view_ui_banner() {
    local version="$1"
    local exec_hash="$2"
    
    clear
    echo -e "${GREEN}${BOLD}"
    echo "  _  __ _____ ____  ____   ___   ____ "
    echo " | |/ // ____/ ___||  _ \ / _ \ / ___|"
    echo " | ' /| |    \___ \| |_) | | | | |    "
    echo " |  < | |___  ___) |  __/| |_| | |___ "
    echo " |_|\_\\____/|____/|_|    \___/ \____|"
    echo -e "${NC}"
    echo -e "   Kaspersky Container Security PoC Tool - v${version}"
    if [ -n "$exec_hash" ]; then
        echo -e "   ${DIM}Execution ID: ${BOLD}${exec_hash}${NC}"
    fi
    echo ""
    echo -e "${BLUE}  ====================================================${NC}"
    echo -e "${DIM}  Version: ${version}${NC}"
    echo -e "${DIM}  ${MSG_AUTHOR}: Artur Scheiner${NC}"
    echo ""
}

view_ui_section() {
    local title="$1"
    echo -e "${MAGENTA}${BOLD}:: ${title} ::${NC}"
    echo -e "${DIM}------------------------------------------------------${NC}"
}

view_ui_step() {
    local current="$1"
    local total="$2"
    local title="$3"
    local desc="$4"
    echo -e "\n${BOLD}[${current}/${total}] ${title}${NC}"
    if [ -n "$desc" ]; then
        echo -e "${DIM}   ${desc}${NC}"
    fi
}

view_ui_input() {
    local label="$1"
    local default_val="$2"
    local current_val="$3"
    local is_secret="$4"
    
    echo -ne "   ${ICON_ARROW} ${label}"
    
    if [ -n "$default_val" ]; then
        echo -ne " ${DIM}(${MSG_DEFAULT}: ${default_val})${NC}"
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

view_ui_help() {
    local cmd="$1"
    local desc="$2"
    local opts="$3"
    local examples="$4"
    local version="$5"

    view_ui_banner "$version"
    
    echo -e "${BLUE}${BOLD}${MSG_USAGE}:${NC}"
    echo -e "   kcspoc $cmd [options]\n"

    echo -e "${BLUE}${BOLD}${MSG_HELP_DESCRIPTION}:${NC}"
    echo -e "   $desc\n"

    if [ -n "$opts" ]; then
        echo -e "${BLUE}${BOLD}${MSG_HELP_OPTIONS}:${NC}"
        echo -e "$opts" | while IFS='|' read -r opt odesc; do
            printf "   ${CYAN}%-18s${NC} %s\n" "$opt" "$odesc"
        done
        echo ""
    fi

    if [ -n "$examples" ]; then
        echo -e "${BLUE}${BOLD}${MSG_HELP_EXAMPLES}:${NC}"
        echo -e "$examples" | while read -r line; do
            echo -e "   ${DIM}$line${NC}"
        done
        echo ""
    fi
}

# --- SPINNER COMPONENTS ---

view_ui_spinner_start() {
    local msg="$1"
    echo -ne "   ${ICON_GEAR} $msg... "
    tput civis 2>/dev/null || true
}

view_ui_spinner_stop() {
    local status="$1"
    tput cnorm 2>/dev/null || true
    echo -ne "\b \b"
    if [ "$status" = "PASS" ]; then
        echo -e "[ ${GREEN}${ICON_OK}${NC} ]"
    else
        echo -e "[ ${RED}${ICON_FAIL}${NC} ]"
    fi
}

view_ui_spinner_cleanup() {
    local exit_code="$1"
    tput cnorm 2>/dev/null || true
    echo ""
    if [ "$exit_code" -ne 0 ]; then
         echo -e "[ ${RED}${ICON_FAIL}${NC} ] (Script Interrupted)"
    fi
}

view_ui_log_info() {
    local hash="$1"
    echo -e "\n${DIM}${ICON_INFO} Log saved (Hash: ${BOLD}$hash${DIM}). View with:${NC}"
    echo -e "${DIM}   ./kcspoc logs --show $hash${NC}\n"
}
