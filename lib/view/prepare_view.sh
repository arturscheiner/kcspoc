#!/bin/bash

# ==============================================================================
# Layer: View
# File: prepare_view.sh
# Responsibility: UI and output for Prepare command
# ==============================================================================

view_prepare_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

view_prepare_section() {
    view_ui_section_header "$1"
}

view_prepare_step_start() {
    service_spinner_start "$1"
}

view_prepare_step_stop() {
    service_spinner_stop "$1"
}

view_prepare_step_error() {
    local msg="$1"
    [ -n "$msg" ] && echo -e "      ${BRIGHT_RED}${msg}${NC}"
}

view_prepare_summary_header() {
    view_ui_section_header "$MSG_PREPARE_STEP_6"
}

view_prepare_summary_success() {
    local ingress_ip="$1"
    local domain="$2"
    echo -e "${BRIGHT_GREEN}${ICON_OK} ${MSG_PREPARE_COMPLETED}${NC}"
    echo -e "   ${MSG_PREPARE_INGRESS_IP}: ${BOLD}${BRIGHT_CYAN}$ingress_ip${NC}"
    echo -e "   ${MSG_PREPARE_HOSTS_HINT}: ${BOLD}${BRIGHT_YELLOW}$ingress_ip $domain${NC}"
}

view_prepare_summary_fail() {
    echo -e "${BRIGHT_RED}${BOLD}${ICON_FAIL} ${MSG_PREPARE_COMPLETED}${NC} (With errors)"
    echo -e "   ${MSG_ERROR_CONFIG_NOT_FOUND}" # Fallback generic error msg
}

view_prepare_infra_check() {
    local type="$1"
    local name="$2"
    local ns="$3"
    check_k8s_label "$type" "$name" "$ns"
}

view_prepare_confirm_step() {
    local label="$1"
    local title="$2"
    local desc="$3"
    local unattended="${4:-false}"
    
    if [ "$unattended" == "true" ]; then
        return 0
    fi
    
    echo -e "\n${BOLD}${ICON_QUESTION} ${title}${NC}"
    echo -e "   ${DIM}${desc}${NC}"
    echo -ne "   Do you want to proceed with $label? (y/n) [y]: "
    read -r ans
    if [ "$ans" == "n" ] || [ "$ans" == "N" ]; then
        return 1
    fi
    return 0
}
