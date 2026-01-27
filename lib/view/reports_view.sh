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
        "COMMAND:15" \
        "FORMAT:8"
}

view_reports_list_item() {
    local hash="$1"
    local timestamp="$2"
    local cmd="$3"
    local ext="$4"
    
    view_ui_table_row \
        "${BRIGHT_CYAN}${hash}${NC}:8" \
        "${DIM}${timestamp}${NC}:22" \
        "${BOLD}${cmd}${NC}:15" \
        "${DIM}${ext}${NC}:8"
}

view_reports_empty() {
    echo -e "   ${DIM}No reports found in ~/.kcspoc/reports/${NC}"
}
