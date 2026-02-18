#!/bin/bash

# ==============================================================================
# Layer: View
# File: bootstrap_view.sh
# Responsibility: UI prompts and instructions for Bootstrap command
# ==============================================================================

view_bootstrap_intro() {
    view_ui_section_header "KCS API Integration Bootstrap"

    echo -e "   This command will guide you through the initial KCS API configuration."
    echo -e "   The API token is required for automated agent deployment and management.\n"

    echo -e "   ${BOLD}Step 1: Get your API Token${NC}"
    echo -e "   1. Log in to the KCS Console."
    echo -e "   2. Go to: ${BOLD}Settings > My Profile${NC} (or Admin > My Profile)."
    echo -e "   3. Click on ${BOLD}API Token${NC} and copy the value."
    echo ""
}

view_bootstrap_prompt_token() {
    local token_ref="$1"
    echo -ne "   ${ICON_QUESTION} Please paste your ${BOLD}API Token${NC} here: "
    read -rs token
    eval "$token_ref=\"$token\""
    echo ""
}

view_bootstrap_token_detected() {
    local token="$1"
    # Show masked token for security
    local masked="********************${token: -4}"
    echo -e "   ${ICON_OK} ${BRIGHT_WHITE}Existing API Token detected:${NC} ${DIM}${masked}${NC}"
    echo -e "      ${DIM}Skipping interactive prompt. To change, edit ~/.kcspoc/config.${NC}\n"
}

view_bootstrap_error_empty() {
    echo -e "      ${BRIGHT_RED}${ICON_FAIL} Token cannot be empty. Please try again.${NC}"
}

view_bootstrap_warn_short() {
    echo -e "   ${BRIGHT_RED}${ICON_FAIL} The token seems too short. Are you sure it's correct?${NC}"
}

view_bootstrap_verifying_token() {
    service_spinner_start "Verifying API Token validity"
}

view_bootstrap_error_invalid_token() {
    service_spinner_stop "FAIL"
    echo -e "      ${BRIGHT_RED}${ICON_FAIL} Invalid or expired token. Please provide a valid one.${NC}"
}

view_bootstrap_error_connectivity() {
    service_spinner_stop "FAIL"
    echo -e "      ${YELLOW}${ICON_GEAR} Warning: Could not reach KCS API. Check your network or DOMAIN config.${NC}"
}

view_bootstrap_saving_start() {
    service_spinner_start "Saving configuration to $CONFIG_FILE"
}

view_bootstrap_saving_stop() {
    service_spinner_stop "PASS"
}

view_bootstrap_discovery_start() {
    service_spinner_start "Discovering KCS Environment"
}

view_bootstrap_discovery_stop() {
    local status="$1"
    service_spinner_stop "$status"
}

view_bootstrap_scope_found() {
    local name="$1"
    local id="$2"
    echo -e "      ${BOLD}Scope Detected:${NC} ${BRIGHT_WHITE}${name}${NC} ${DIM}(ID: ${id})${NC}"
}

view_bootstrap_group_create_start() {
    local name="$1"
    service_spinner_start "Creating PoC Agent Group ($name)"
}

view_bootstrap_group_exists() {
    local name="$1"
    service_spinner_stop "WARN"
    echo -e "      ${YELLOW}${ICON_GEAR} Group '${name}' already exists. Skipping creation.${NC}"
}

view_bootstrap_group_created() {
    local id="$1"
    service_spinner_stop "PASS"
    echo -e "      ${DIM}Group ID: ${id}${NC}"
}

view_bootstrap_asset_download_start() {
    service_spinner_start "Downloading KCS Agent Deployment Assets"
}

view_bootstrap_asset_compare() {
    # Redirect to stderr to avoid being captured in $(...) subshells
    echo -e "      ${DIM}Comparing online yaml with local configuration...${NC}" >&2
}

view_bootstrap_asset_download_stop() {
    local status="$1"
    local path="$2"
    service_spinner_stop "$status"
    if [ "$status" == "PASS" ]; then
        echo -e "      ${DIM}Assets saved to:${NC}"
        echo -e "      ${path}"
    elif [ "$status" == "SKIPPED" ]; then
        echo -e "      ${DIM}Local assets are already in sync with server.${NC}"
    fi
}

view_bootstrap_success() {
    echo -e "\n   ${BRIGHT_GREEN}${BOLD}${ICON_OK} BOOTSTRAP COMPLETED!${NC}"
    echo -e "   The API token has been securely stored in ~/.kcspoc/config."
    
    echo -e "\n   ${BOLD}Next Journey Steps:${NC}"
    echo -e "   - Run ${BRIGHT_GREEN}${BOLD}./kcspoc deploy --agents${NC} to install KCS Agents on your nodes."
    echo -e "   - Check the walkthrough for advanced configuration tips.\n"
}
