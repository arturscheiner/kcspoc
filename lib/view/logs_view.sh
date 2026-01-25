#!/bin/bash

# ==============================================================================
# Layer: View
# File: logs_view.sh
# Responsibility: UI for Log management (List tables, Show content)
# ==============================================================================

view_logs_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

view_logs_section() {
    view_ui_section_header "$1"
}

view_logs_list_header() {
    local target="$1"
    if [ -n "$target" ]; then
        view_ui_table_header \
            "DATE/TIME:20" \
            "HASH:10" \
            "STATUS:15" \
            "VERSION:10"
    else
        view_ui_table_header \
            "DATE/TIME:20" \
            "COMMAND:12" \
            "HASH:10" \
            "STATUS:15" \
            "VERSION:10"
    fi
}

view_logs_list_row() {
    local date="$1"
    local cmd="$2"
    local hash="$3"
    local status="$4"
    local version="$5"
    local target="$6"

    local color=$NC
    if [ "$status" == "SUCCESS" ]; then color=$BRIGHT_GREEN; 
    elif [ "$status" == "FAIL" ]; then color=$BRIGHT_RED;
    elif [ "$status" == "UNKNOWN" ] || [ "$status" == "-" ]; then color=$DIM; fi

    local colored_status="${color}${status}${NC}"

    if [ -n "$target" ]; then
        view_ui_table_row \
            "$date:20" \
            "$hash:10" \
            "$colored_status:15" \
            "$version:10"
    else
        view_ui_table_row \
            "$date:20" \
            "$cmd:12" \
            "$hash:10" \
            "$colored_status:15" \
            "$version:10"
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
    service_spinner_start "Cleaning all log files"
}

view_logs_cleanup_stop() {
    local status="$1"
    local empty="${2:-false}"
    service_spinner_stop "$status"
    if [ "$status" == "PASS" ]; then
        if [ "$empty" == "true" ]; then
            echo -e "      ${DIM}No logs found to clean.${NC}"
        else
            echo -e "      ${BRIGHT_GREEN}${ICON_OK} All logs have been cleared.${NC}"
        fi
    fi
}
