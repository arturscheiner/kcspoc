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
# Colors (High-Contrast Palette)
export BOLD='\033[1m'
export DIM='\033[2m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Bright / High-Contrast Variations
export BRIGHT_GREEN='\033[1;32m'
export BRIGHT_RED='\033[1;31m'
export BRIGHT_YELLOW='\033[1;33m'
export BRIGHT_CYAN='\033[1;36m'
export BRIGHT_WHITE='\033[1;37m'
export ORANGE='\033[38;5;208m'
export BRIGHT_ORANGE='\033[1;38;5;208m'
export BRIGHT_CYAN='\033[1;36m'

# Structural Components
export UI_LINE_CHAR="-"
export UI_SEP_CHAR="="
export UI_TABLE_SEP="-"

# Icons
export ICON_OK="${BRIGHT_GREEN}✔${NC}"
export ICON_FAIL="${BRIGHT_RED}✘${NC}"
export ICON_INFO="${BRIGHT_CYAN}ℹ${NC}"
export ICON_WARN="${BRIGHT_YELLOW}⚠${NC}"
export ICON_QUESTION="${BOLD}?${NC}"
export ICON_ARROW="${ORANGE}➜${NC}"
export ICON_GEAR="${BRIGHT_CYAN}⚙${NC}"

# --- CORE UI COMPONENTS ---

# Standardized Section Header
view_ui_section_header() {
    local title="$1"
    echo -e "\n${ORANGE}:: ${title} ::${NC}"
    view_ui_line
}

# Standardized Line Separator
view_ui_line() {
    local width=$(tput cols 2>/dev/null || echo 100)
    [ $width -gt 100 ] && width=100
    printf "${DIM}%${width}s${NC}\n" | tr " " "${UI_LINE_CHAR}"
}

# Standardized Strong Separator
view_ui_separator() {
    local width=$(tput cols 2>/dev/null || echo 100)
    [ $width -gt 100 ] && width=100
    printf "${ORANGE}%${width}s${NC}\n" | tr " " "${UI_SEP_CHAR}"
}

# Standardized Table Header
# Usage: view_ui_table_header "Col1:Width1" "Col2:Width2" ...
view_ui_table_header() {
    local header_line=""
    
    for item in "$@"; do
        local name="${item%:*?}" # Support Col:Name:Width
        [ "${name}" == "${item}" ] && name="${item%:*?}" 
        # Actually just use simple split assuming last part is width
        local name="${item%:*}"
        local width="${item##*:}"
        
        # Headers usually don't have colors, but bold is added here
        local raw_name="${name^^}"
        local padding=""
        local pad_width=$(( width - ${#raw_name} ))
        [ $pad_width -gt 0 ] && padding=$(printf "%${pad_width}s" " ")
        
        header_line+="$(echo -e "${BOLD}${raw_name}${NC}${padding}  ")"
    done
    
    echo -e "   ${header_line}"
    
    # Separator line
    local sep_line=""
    for item in "$@"; do
        local width="${item##*:}"
        local dashes=$(printf "%${width}s" | tr " " "-")
        sep_line+="$(printf "${DIM}%-${width}s  " "${dashes}")"
    done
    echo -e "   ${sep_line}"
}

# Standardized Table Row
# Usage: view_ui_table_row "Val1:Width1" "Val2:Width2" ...
view_ui_table_row() {
    local row_line=""
    for item in "$@"; do
        local val="${item%:*}"
        local width="${item##*:}"
        
        # Strip ANSI codes to calculate visible length
        # Using a portable sed pattern for ANSI escape sequences
        local clean_val=$(echo -e "$val" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
        local visible_len=${#clean_val}
        
        local pad_width=$(( width - visible_len ))
        [ $pad_width -lt 0 ] && pad_width=0
        
        local padding=""
        if [ $pad_width -gt 0 ]; then
            padding=$(printf "%${pad_width}s" " ")
        fi
        
        row_line+="${val}${padding}  "
    done
    echo -e "   ${row_line}"
}

view_ui_banner() {
    local version="$1"
    local exec_hash="$2"
    
    echo -e "${BRIGHT_CYAN}${BOLD}"
    echo "██╗  ██╗ ██████╗ ███████╗██████╗  ██████╗  ██████╗"
    echo "██║ ██╔╝██╔════╝ ██╔════╝██╔══██╗██╔═══██╗██╔════╝"
    echo "█████╔╝ ██║      ███████╗██████╔╝██║   ██║██║     "
    echo "██╔═██╗ ██║      ╚════██║██╔═══╝ ██║   ██║██║     "
    echo "██║  ██╗╚██████╗ ███████║██║     ╚██████╔╝╚██████╗"
    echo "╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝      ╚═════╝  ╚═════╝"
    echo -e "${NC}"
    echo -e "        ${BRIGHT_WHITE}🐳  ${BOLD}KCSPOC${NC}${BRIGHT_WHITE} — Kaspersky Container Security PoC Tool${NC}"
    
    if [ -n "$exec_hash" ]; then
        echo -e "   Execution ID: ${BRIGHT_ORANGE}${BOLD}${exec_hash}${NC}"
    fi
    echo -e "${ORANGE}================================================================================${NC}"
    echo -e "${DIM}  Version: ${version}${NC}"
    echo -e "${DIM}  Author:  Artur Scheiner${NC}"
    echo ""
}

view_ui_slim_header() {
    local version="$1"
    local exec_hash="$2"
    
    echo ""
    echo -e "   Kaspersky Container Security PoC Tool - v${version}"
    if [ -n "$exec_hash" ]; then
        echo -e "   ${DIM}Execution ID: ${BOLD}${exec_hash}${NC}"
    fi
    echo -e "${ORANGE}  ====================================================${NC}"
    echo ""
}

view_ui_section() {
    view_ui_section_header "$1"
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
    
    echo -ne " ${BRIGHT_CYAN}[${prompt_val}]${NC}: "
    
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
    
    echo -e "${ORANGE}${BOLD}${MSG_USAGE}:${NC}"
    echo -e "   kcspoc $cmd [options]\n"

    echo -e "${ORANGE}${BOLD}${MSG_HELP_DESCRIPTION}:${NC}"
    echo -e "   $desc\n"

    if [ -n "$opts" ]; then
        echo -e "${ORANGE}${BOLD}${MSG_HELP_OPTIONS}:${NC}"
        echo -e "$opts" | while IFS='|' read -r opt odesc; do
            printf "   ${BRIGHT_CYAN}%-18s${NC} %s\n" "$opt" "$odesc"
        done
        echo ""
    fi

    if [ -n "$examples" ]; then
        echo -e "${ORANGE}${BOLD}${MSG_HELP_EXAMPLES}:${NC}"
        echo -e "$examples" | while read -r line; do
            echo -e "   ${DIM}$line${NC}"
        done
        echo ""
    fi
}

view_ui_usage() {
    local version="$1"
    local exec_hash="$2"

    view_ui_banner "$version" "$exec_hash"
    echo -e "${ORANGE}${BOLD}${MSG_USAGE}:${NC}"
    echo -e "  kcspoc <command> [options]\n"

    echo -e "${ORANGE}${BOLD}${MSG_COMMANDS}:${NC}"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "config"  "$MSG_CMD_CONFIG_DESC"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "pull"    "$MSG_CMD_PULL_DESC"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "check"   "$MSG_CMD_CHECK_DESC"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "prepare" "$MSG_CMD_PREPARE_DESC"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "extras"  "$MSG_CMD_EXTRAS_DESC"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "reports" "$MSG_CMD_REPORTS_DESC"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "deploy"  "$MSG_CMD_DEPLOY_DESC"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "destroy" "$MSG_DESTROY_TITLE"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "logs"    "Manage logs (--list, --show, --cleanup)"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "bootstrap" "Configure KCS API Integration (API Token)"
    printf "  ${BRIGHT_CYAN}%-10s${NC} %s\n" "help"    "$MSG_CMD_HELP_DESC"
    echo ""

    echo -e "${ORANGE}${BOLD}${MSG_HELP_EXAMPLES}:${NC}"
    echo -e "  ${DIM}# Start here${NC}"
    echo -e "  kcspoc config"
    echo -e "  kcspoc check"
    echo ""
    echo -e "  ${DIM}# Installation flow${NC}"
    echo -e "  kcspoc pull"
    echo -e "  kcspoc prepare"
    echo -e "  kcspoc extras --list"
    echo -e "  kcspoc deploy --core"
    echo -e "  kcspoc bootstrap"
    echo ""
    echo -e "  ${DIM}# Troubleshooting${NC}"
    echo -e "  kcspoc logs --list"
    echo ""
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
        echo -e "[ ${BRIGHT_GREEN}${ICON_OK}${NC} ]"
    else
        echo -e "[ ${BRIGHT_RED}${ICON_FAIL}${NC} ]"
    fi
}

view_ui_spinner_cleanup() {
    local exit_code="$1"
    tput cnorm 2>/dev/null || true
    echo ""
    if [ "$exit_code" -ne 0 ]; then
         echo -e "[ ${BRIGHT_RED}${ICON_FAIL}${NC} ] (Script Interrupted)"
    fi
}

view_ui_log_info() {
    local hash="$1"
    echo -e "\n${DIM}${ICON_INFO} Log saved (Hash: ${BOLD}$hash${DIM}). View with:${NC}"
    echo -e "${DIM}   ./kcspoc logs --show $hash${NC}\n"
}
