#!/bin/bash

# ==============================================================================
# Layer: View
# File: config_view.sh
# Responsibility: UI and Output for Config Command
# ==============================================================================

config_view_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

config_view_wizard_intro() {
    view_ui_section_header "$MSG_CONFIG_WIZARD_TITLE"
    echo -e "${BRIGHT_WHITE}$MSG_CONFIG_WIZARD_DESC${NC}"
    echo ""
}

config_view_section() {
    local title="$1"
    view_ui_section_header "$title"
}

config_view_config_loaded() {
    config_view_action_line "$MSG_CONFIG_LOADED" "PASS"
}

config_view_step_lang() {
    local total_steps="$1"
    local avail_str="$2"
    local def_lang="$3"
    local cur_lang="$4"

    view_ui_step 1 "$total_steps" "$MSG_STEP_LANG" "$MSG_STEP_LANG_DESC"
    echo -e "   ${DIM}${MSG_LANG_AVAILABLE}: [ $avail_str]${NC}"
    view_ui_input "$MSG_INPUT_LANG" "$def_lang" "$cur_lang"
}

config_view_step_generic() {
    local step_num="$1"
    local total_steps="$2"
    local title="$3"
    local desc="$4"
    local input_label="$5"
    local default_val="$6"
    local current_val="$7"
    local is_secret="${8:-no}"

    view_ui_step "$step_num" "$total_steps" "$title" "$desc"
    view_ui_input "$input_label" "$default_val" "$current_val" "$is_secret"
}

config_view_secrets_generated() {
    echo -e "      ${DIM}${ICON_OK} $MSG_CONFIG_SECRETS_GEN${NC}"
}

config_view_config_saved() {
    local config_file="$1"
    config_view_action_line "$MSG_CONFIG_SAVED $config_file" "PASS"
    echo -e "${DIM}${MSG_CONFIG_NEXT_STEPS}${NC}"
}

config_view_action_line() {
    local msg="$1"
    local status="$2"
    echo -ne "   ${ICON_GEAR} $msg... "
    if [ "$status" = "PASS" ]; then
        echo -e "[ ${BRIGHT_GREEN}${ICON_OK}${NC} ]"
    else
        echo -e "[ ${BRIGHT_RED}${ICON_FAIL}${NC} ]"
    fi
}

config_view_version_update_header() {
    view_ui_section_header "$MSG_CONFIG_VER_UPDATED"
}

config_view_version_update_success() {
    local version="$1"
    echo -e "   ${BRIGHT_GREEN}${ICON_OK} ${MSG_CONFIG_VER_UPDATED}: ${BOLD}${version}${NC}\n"
}

config_view_error_config_not_found() {
    echo -e "   ${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
}
