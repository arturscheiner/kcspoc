#!/bin/bash

# ==============================================================================
# Layer: View
# File: destroy_view.sh
# Responsibility: UI prompts and messages for the Destroy command
# ==============================================================================

view_destroy_banner() {
    ui_banner
}

view_destroy_safety_check() {
    local required_phrase="$1"
    
    ui_section "$MSG_DESTROY_TITLE"
    echo -e "${RED}${BOLD}${ICON_WARN} $MSG_DESTROY_WARN_TITLE${NC}"
    echo -e "${YELLOW}$MSG_DESTROY_WARN_DESC${NC}"
    echo ""
    
    echo -e "${DIM}$MSG_DESTROY_PROMPT${NC}"
    echo -e "${BLUE}${BOLD}$required_phrase${NC}"
    echo ""
    echo -ne "${ICON_QUESTION} > "
    read -r user_input
    
    if [ "$user_input" != "$required_phrase" ]; then
        echo -e "\n${RED}$MSG_DESTROY_CANCEL${NC}"
        return 1
    fi
    return 0
}

view_destroy_confirm_infra() {
    echo -e "${YELLOW}$MSG_DESTROY_DEPS_PROMPT${NC}"
    echo -ne "${ICON_QUESTION} > "
    read -r deps_input
    if [[ "$deps_input" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

view_destroy_start_msg() {
    echo -e "${YELLOW}${ICON_GEAR} $MSG_DESTROY_START${NC}"
    echo "----------------------------"
}

view_destroy_step_start() {
    ui_spinner_start "$1"
}

view_destroy_step_stop() {
    ui_spinner_stop "$1"
}

view_destroy_info() {
    echo -e "   ${BLUE}${ICON_INFO} $1${NC}"
}

view_destroy_dim_info() {
    echo -e "      ${DIM}$1${NC}"
}

view_destroy_infra_header() {
    echo -e "\n${RED}${BOLD}=== $MSG_DESTROY_DEPS_TITLE ===${NC}"
}

view_destroy_success() {
    echo -e "\n${GREEN}${BOLD}${ICON_OK} $MSG_DESTROY_SUCCESS${NC}"
    echo -e "${DIM}$MSG_DESTROY_HINT${NC}"
}

view_destroy_infra_skipped() {
    echo -e "${BLUE}[8/8] $MSG_DESTROY_DEPS_SKIPPED${NC}"
}
