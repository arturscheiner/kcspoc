#!/bin/bash

# ==============================================================================
# Layer: View
# File: reports_view.sh
# Responsibility: UI presentation for Report management
# ==============================================================================

view_reports_list_header() {
    view_ui_table_header \
        "HASH:8" \
        "DATE/TIME:22" \
        "COMMAND:12" \
        "FORMAT:8" \
        "TYPE:10" \
        "AI MODEL:20"
}

view_reports_list_item() {
    local hash="$1"
    local timestamp="$2"
    local cmd="$3"
    local ext="$4"
    local type="$5"
    local model="$6"
    
    local type_color=$DIM
    if [ "$type" == "ai" ]; then type_color=$BRIGHT_MAGENTA; fi
    
    view_ui_table_row \
        "${BRIGHT_CYAN}${hash}${NC}:8" \
        "${DIM}${timestamp}${NC}:22" \
        "${BOLD}${cmd}${NC}:12" \
        "${DIM}${ext}${NC}:8" \
        "${type_color}${type}${NC}:10" \
        "${DIM}${model}${NC}:20"
}

view_reports_show_content() {
    local hash="$1"
    local file_path="$2"
    
    echo -e "${DIM}File: $file_path${NC}\n"
    if command -v less &>/dev/null; then
        less -R "$file_path"
    else
        cat "$file_path"
    fi
}

view_reports_empty() {
    echo -e "   ${DIM}No reports found in ~/.kcspoc/reports/${NC}"
}
