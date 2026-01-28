#!/bin/bash

# ==============================================================================
# Layer: View
# File: pull_view.sh
# Responsibility: UI and Output for Pull Command
# ==============================================================================

view_pull_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

view_pull_section_title() {
    view_ui_section_header "$MSG_PULL_TITLE"
}

view_pull_local_list_header() {
    echo -e "   ${BOLD}${MSG_PULL_LOCAL_TITLE}${NC}"
    view_ui_line
}

view_pull_local_list_empty() {
    echo -e "   ${YELLOW}${ICON_INFO} ${MSG_PULL_LOCAL_EMPTY}${NC}"
}

view_pull_local_list_table_header() {
    view_ui_table_header \
        "$MSG_PULL_TABLE_ACTIVE:8" \
        "$MSG_PULL_TABLE_VER:15" \
        "$MSG_PULL_TABLE_DATE:20" \
        "$MSG_PULL_TABLE_PATH:40"
}

view_pull_local_list_item() {
    local ver="$1"
    local ddate="$2"
    local path="$3"
    local is_active="$4"

    local active_str=" "
    if [ "$is_active" == "true" ]; then
        active_str="${BRIGHT_GREEN}*${NC}"
    fi
    
    view_ui_table_row \
        "$active_str:8" \
        "$ver:15" \
        "$ddate:20" \
        "$path:40"
}

view_pull_auth_start() {
    service_spinner_start "$MSG_PULL_AUTH"
}


view_pull_login_error() {
    echo -e "      ${RED}${ICON_FAIL} ${MSG_PULL_LOGIN_ERR}${NC}"
}

view_pull_version_source_flag() {
    local ver="$1"
    echo -e "   ${ICON_INFO} ${MSG_PULL_VER_SRC_FLAG} ($ver)"
}

view_pull_version_source_config() {
    local ver="$1"
    echo -e "   ${ICON_INFO} ${MSG_PULL_VER_SRC_CONFIG} ($ver)"
}

view_pull_version_source_default() {
    echo -e "   ${ICON_INFO} ${MSG_PULL_VER_SRC_DEFAULT}"
}

view_pull_cache_hit() {
    local ver="$1"
    echo -e "   ${BRIGHT_GREEN}${ICON_OK} ${MSG_PULL_SUCCESS}${NC} (Local cache: $ver)"
}

view_pull_download_start() {
    service_spinner_start "$MSG_PULL_DOWNLOADING"
}

view_pull_config_updated() {
    local ver="$1"
    echo -e "      ${DIM}${ICON_INFO} Config updated: KCS_VERSION=\"$ver\"${NC}"
}

view_pull_success_file() {
    local filename="$1"
    echo -e "      ${DIM}${MSG_PULL_SUCCESS}: $filename${NC}"
}

view_pull_error_file_missing() {
    echo -e "      ${BRIGHT_RED}${ICON_FAIL} ${MSG_PULL_ERR_FILE}${NC}"
}

view_pull_error_fail() {
    echo -e "      ${BRIGHT_RED}${ICON_FAIL} ${MSG_PULL_ERR_FAIL}${NC}"
}

view_pull_template_fetch_start() {
    local ver="$1"
    service_spinner_start "Fetching Remote Template ($ver)"
}

view_pull_template_cached() {
    local filename="$1"
    echo -e "      ${DIM}Template: $filename cached.${NC}"
}

view_pull_template_fallback_hint() {
    echo -e "      ${YELLOW}${ICON_INFO} Versioned template not found in repo. Using 'latest' fallback.${NC}"
}
