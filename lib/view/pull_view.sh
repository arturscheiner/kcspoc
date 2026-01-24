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
    view_ui_section "$MSG_PULL_TITLE"
}

view_pull_local_list_header() {
    echo -e "   ${BOLD}${MSG_PULL_LOCAL_TITLE}${NC}"
    echo -e "   ${DIM}------------------------------------------------------${NC}"
}

view_pull_local_list_empty() {
    echo -e "   ${YELLOW}${ICON_INFO} ${MSG_PULL_LOCAL_EMPTY}${NC}"
}

view_pull_local_list_table_header() {
    printf "   ${BOLD}%-12s %-15s %-20s %-40s${NC}\n" "$MSG_PULL_TABLE_ACTIVE" "$MSG_PULL_TABLE_VER" "$MSG_PULL_TABLE_DATE" "$MSG_PULL_TABLE_PATH"
    printf "   ${DIM}%s${NC}\n" "------------------------------------------------------------------------------------------"
}

view_pull_local_list_item() {
    local ver="$1"
    local ddate="$2"
    local path="$3"
    local is_active="$4"

    local active_str=""
    local active_color="${NC}"
    if [ "$is_active" == "true" ]; then
        active_str="$MSG_PULL_ACTIVE_MARKER"
        active_color="${GREEN}"
    fi
    
    echo -e "   ${active_color}$(printf "%-12s" "$active_str")${NC} $(printf "%-15s" "$ver") $(printf "%-20s" "$ddate") $(printf "%-40s" "$path")"
}

view_pull_auth_start() {
    service_spinner_start "$MSG_PULL_AUTH"
}

view_pull_auth_fallback_start() {
    service_spinner_start "${MSG_PULL_AUTH} (Fallback)"
}

view_pull_login_fail_hint() {
    local server="$1"
    echo -e "      ${YELLOW}${ICON_INFO} $MSG_PULL_LOGIN_FAIL ($server)...${NC}"
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
    echo -e "   ${GREEN}${ICON_OK} ${MSG_PULL_SUCCESS}${NC} (Local cache: $ver)"
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
    echo -e "      ${RED}${ICON_FAIL} ${MSG_PULL_ERR_FILE}${NC}"
}

view_pull_error_fail() {
    echo -e "      ${RED}${ICON_FAIL} ${MSG_PULL_ERR_FAIL}${NC}"
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
