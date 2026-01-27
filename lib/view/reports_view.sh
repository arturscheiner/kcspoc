#!/bin/bash

# ==============================================================================
# Layer: View
# File: reports_view.sh
# Responsibility: UI presentation for Report management
# ==============================================================================

view_reports_list_header() {
    view_ui_table_header \
        "DATE/TIME:17" \
        "ID:8" \
        "COM:10" \
        "EXEC ID:8" \
        "FORMAT:8" \
        "TYPE:10" \
        "AI MODEL:20"
}

view_reports_list_item() {
    local date="$1"
    local id="$2"
    local com="$3"
    local exec_id="$4"
    local ext="$5"
    local type="$6"
    local model="$7"
    
    local type_color=$DIM
    if [ "$type" == "ai" ]; then type_color=$BRIGHT_MAGENTA; fi
    
    view_ui_table_row \
        "$date:17" \
        "${BRIGHT_CYAN}${id}${NC}:8" \
        "${BOLD}${com}${NC}:10" \
        "${BRIGHT_YELLOW}${exec_id}${NC}:8" \
        "${DIM}${ext}${NC}:8" \
        "${type_color}${type}${NC}:10" \
        "${DIM}${model}${NC}:20"
}

view_reports_show_content() {
    local hash="$1"
    local file_path="$2"
    
    echo -e "${DIM}File: $file_path${NC}\n"
    if command -v less &>/dev/null; then
        # -R: ANSI colors, -F: Exit if content fits on one screen, -X: No init (don't clear screen)
        # tr: remove carriage returns (fix ugly progress bars)
        # sed: strip leading blank lines for cleaner output
        tr -d '\r' < "$file_path" | sed '/./,$!d' | less -RFX
    else
        tr -d '\r' < "$file_path" | sed '/./,$!d'
    fi
}

view_reports_empty() {
    local cmd="$1"
    if [ -n "$cmd" ]; then
        echo -e "   ${DIM}No reports found for command: $cmd${NC}"
    else
        echo -e "   ${DIM}No reports found in ~/.kcspoc/reports/${NC}"
    fi
}

view_reports_confirm_cleanup() {
    local cmd="$1"
    local msg="ALL reports"
    if [ -n "$cmd" ]; then msg="all reports for command '$cmd'"; fi
    
    echo -e "   ${BRIGHT_RED}${ICON_WARN} CAUTION:${NC} This will permanently delete ${msg}."
    echo -n "   Are you sure? [y/N]: "
    read -r choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

view_reports_cleanup_start() {
    local cmd="$1"
    local msg="Reports"
    if [ -n "$cmd" ]; then msg="$cmd reports"; fi
    service_spinner_start "Cleaning $msg"
}

view_reports_cleanup_stop() {
    service_spinner_stop "$1"
    if [ "$1" == "PASS" ]; then
        echo -e "      ${BRIGHT_GREEN}${ICON_OK} Cleanup completed successfully.${NC}"
    fi
}

view_reports_cleanup_cancel() {
    echo -e "   ${DIM}Cleanup cancelled.${NC}"
}
