#!/bin/bash

# ==============================================================================
# Layer: View
# File: logs_view.sh
# Responsibility: UI for Log management (List tables, Show content)
# ==============================================================================

view_logs_banner() {
    ui_banner
}

view_logs_section() {
    ui_section "$1"
}

view_logs_list_header() {
    local target="$1"
    if [ -n "$target" ]; then
        printf "   ${BOLD}%-20s %-10s %-15s %-10s${NC}\n" "DATE/TIME" "HASH" "STATUS" "VERSION"
        printf "   ${DIM}%s${NC}\n" "---------------------------------------------------------"
    else
        printf "   ${BOLD}%-20s %-12s %-10s %-15s %-10s${NC}\n" "DATE/TIME" "COMMAND" "HASH" "STATUS" "VERSION"
        printf "   ${DIM}%s${NC}\n" "----------------------------------------------------------------------"
    fi
}

view_logs_list_row() {
    local date="$1"
    local cmd="$2"
    local hash="$3"
    local status="$4"
    local version="$5"
    local target="$6"

    local color=$RED
    if [ "$status" == "SUCCESS" ]; then color=$GREEN; 
    elif [ "$status" == "UNKNOWN" ] || [ "$status" == "-" ]; then color=$DIM; fi

    if [ -n "$target" ]; then
        printf "   %-20s %-10s ${color}%-15s${NC} %-10s\n" "$date" "$hash" "$status" "$version"
    else
        printf "   %-20s %-12s %-10s ${color}%-15s${NC} %-10s\n" "$date" "$cmd" "$hash" "$status" "$version"
    fi
}

view_logs_show_content() {
    local hash="$1"
    local file_path="$2"
    
    echo -e "${DIM}File: $file_path${NC}\n"
    if command -v less &>/dev/null; then
        less -R "$file_path"
    else
        cat "$file_path"
    fi
}

view_logs_no_logs_found() {
    echo -e "${YELLOW}No logs found for command: $1${NC}"
}

view_logs_hash_not_found() {
    echo -e "${RED}Log with hash '$1' not found.${NC}"
}

view_logs_cleanup_start() {
    ui_spinner_start "Cleaning all log files"
}

view_logs_cleanup_stop() {
    local status="$1"
    local empty="${2:-false}"
    ui_spinner_stop "$status"
    if [ "$status" == "PASS" ]; then
        if [ "$empty" == "true" ]; then
            echo -e "      ${DIM}No logs found to clean.${NC}"
        else
            echo -e "      ${GREEN}${ICON_OK} All logs have been cleared.${NC}"
        fi
    fi
}
