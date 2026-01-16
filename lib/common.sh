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
VERSION="0.4.20"

# Labelling Constants
POC_LABEL_KEY="provisioned-by"
POC_LABEL_VAL="kcspoc"
POC_LABEL="${POC_LABEL_KEY}=${POC_LABEL_VAL}"

# Debugging Defaults
DEBUG_OUT="/dev/null"
KCS_DEBUG=false

setup_debug() {
    local cmd_name="$1"
    if [ "$KCS_DEBUG" = true ]; then
        [ -d "$CONFIG_DIR" ] || mkdir -p "$CONFIG_DIR"
        DEBUG_OUT="$CONFIG_DIR/debug-${cmd_name}.log"
        echo "--- KCS DEBUG START: $(date) ---" > "$DEBUG_OUT"
        echo "Command: $cmd_name" >> "$DEBUG_OUT"
        echo "--------------------------------" >> "$DEBUG_OUT"
    fi
}

# --- LOCALE & I18N ---
load_locale() {
    # 1. Try Configured Language
    local CFG_LANG=""
    if [ -f "$CONFIG_FILE" ]; then
        # Extract PREFERRED_LANG safely without sourcing entire file if we want to be strict,
        # but sourcing is standard for this tool.
        # We'll detect it by grep to not accidentally overwrite other vars if called early?
        # Actually, just sourcing is easiest/safest given we control the file format.
        # However, let's just grep it to avoid side effects during early init.
        CFG_LANG=$(grep "^PREFERRED_LANG=" "$CONFIG_FILE" | cut -d'"' -f2)
    fi

    # 2. Detect System Language (Fallback)
    # Priorities: Config > LC_ALL > LC_MESSAGES > LANG
    local SYS_LANG="${CFG_LANG:-${LC_ALL:-${LC_MESSAGES:-$LANG}}}"
    
    # Extract language code (e.g., pt_BR, en_US)
    local LANG_CODE=$(echo "$SYS_LANG" | cut -d. -f1)
    
    # Default to en_US if empty
    if [ -z "$LANG_CODE" ]; then
        LANG_CODE="en_US"
    fi
    
    # Check if we have a file for this locale
    local LOCALE_FILE="$SCRIPT_DIR/locales/${LANG_CODE}.sh"
    
    # If not found, try generic language check (e.g. pt_PT -> pt_BR mapping if needed, or default)
    # For now, if exact match fails, fallback to en_US
    if [ ! -f "$LOCALE_FILE" ]; then
        LOCALE_FILE="$SCRIPT_DIR/locales/en_US.sh"
    fi
    
    # Load it
    if [ -f "$LOCALE_FILE" ]; then
        source "$LOCALE_FILE"
    else
        # Critical Fallback if en_US is missing (should not happen in dist)
        echo "Error: Locale file not found and en_US fallback missing."
        exit 1
    fi
}
# Call it immediately when common is sourced
load_locale

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
    echo -e "${DIM}  ${MSG_AUTHOR}: Artur Scheiner${NC}"
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

# --- UI SPINNER ---

_SPINNER_PID=0

# Ensure spinner is killed on script exit
_ui_spinner_cleanup() {
    local exit_code=$?
    if [ "$_SPINNER_PID" -ne 0 ]; then
        kill "$_SPINNER_PID" &>/dev/null || true
        wait "$_SPINNER_PID" &>/dev/null || true
        _SPINNER_PID=0
        tput cnorm 2>/dev/null || true
        echo ""
        # If we are cleaning up deeply (on crash), show fail
        if [ $exit_code -ne 0 ]; then
             echo -e "[ ${RED}${ICON_FAIL}${NC} ] (Script Interrupted)"
        fi
    fi
}
trap _ui_spinner_cleanup EXIT

ui_spinner_start() {
    local msg="$1"
    echo -ne "   ${ICON_GEAR} $msg... "
    
    # Hide cursor
    tput civis 2>/dev/null || true
    
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

ui_spinner_stop() {
    local status="$1" # PASS or FAIL
    
    if [ "$_SPINNER_PID" -ne 0 ]; then
        kill "$_SPINNER_PID" &>/dev/null || true
        wait "$_SPINNER_PID" &>/dev/null || true
        _SPINNER_PID=0
    fi
    
    # Show cursor
    tput cnorm 2>/dev/null || true
    
    # Clean last frame and print status
    echo -ne "\b \b" # Overwrite frame with space then move back
    
    if [ "$status" = "PASS" ]; then
        echo -e "[ ${GREEN}${ICON_OK}${NC} ]"
    else
        echo -e "[ ${RED}${ICON_FAIL}${NC} ]"
    fi
}

check_k8s_label() {
    local res_type="$1"
    local res_name="$2"
    local ns="$3"
    local label_desc="Checking Label ($POC_LABEL_KEY=$POC_LABEL_VAL)"
    
    # Construct kubectl args
    local args=("$res_type" "$res_name" "--show-labels")
    if [ -n "$ns" ]; then
        args+=("-n" "$ns")
    fi
    
    echo -ne "      ${ICON_GEAR} $label_desc... "
    # We don't use the spinner here because it's a quick check usually, 
    # and we want it indented.
    
    if kubectl get "${args[@]}" 2>> "$DEBUG_OUT" | grep -q "$POC_LABEL_KEY=$POC_LABEL_VAL"; then
        echo -e "[ ${GREEN}${ICON_OK}${NC} ]"
        return 0
    else
        echo -e "[ ${RED}${ICON_FAIL}${NC} ]"
        return 1
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
