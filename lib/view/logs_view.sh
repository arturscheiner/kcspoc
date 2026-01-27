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
    view_ui_table_header \
        "DATE/TIME:17" \
        "ID:8" \
        "COM:10" \
        "EXEC ID:8" \
        "STATUS:15" \
        "VERSION:10"
}

view_logs_list_row() {
    local date="$1"
    local id="$2"
    local com="$3"
    local exec_id="$4"
    local status="$5"
    local version="$6"

    local color=$NC
    if [ "$status" == "SUCCESS" ]; then color=$BRIGHT_GREEN; 
    elif [ "$status" == "FAIL" ]; then color=$BRIGHT_RED;
    elif [ "$status" == "UNKNOWN" ] || [ "$status" == "-" ]; then color=$DIM; fi

    local colored_status="${color}${status}${NC}"

    view_ui_table_row \
        "$date:17" \
        "${BRIGHT_CYAN}${id}${NC}:8" \
        "${BOLD}${com}${NC}:10" \
        "${DIM}${exec_id}${NC}:8" \
        "$colored_status:15" \
        "$version:10"
}

view_logs_show_content() {
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

logs_view_report_start() {
    local hash="$1"
    local model="$2"
    local msg=$(printf "$MSG_LOGS_ANALYSIS_START" "$hash" "$model")
    service_spinner_start "$msg"
}

logs_view_report_success() {
    local cmd="$1"
    local hash="$2"
    local suffix="$3"
    local report_path="$REPORTS_BASE_DIR/$cmd/${hash}.${suffix}"
    
    service_spinner_stop "PASS"
    local msg=$(printf "$MSG_LOGS_ANALYSIS_SUCCESS" "$report_path")
    echo -e "      ${BRIGHT_GREEN}${ICON_OK} ${msg}${NC}"
}

logs_view_report_fail() {
    local hash="$1"
    service_spinner_stop "FAIL"
    local msg=$(printf "$MSG_LOGS_ANALYSIS_FAIL" "$hash")
    echo -e "      ${BRIGHT_RED}${ICON_FAIL} ${msg}${NC}"
}
