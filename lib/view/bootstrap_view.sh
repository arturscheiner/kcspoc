#!/bin/bash

# ==============================================================================
# Layer: View
# File: bootstrap_view.sh
# Responsibility: UI prompts and instructions for Bootstrap command
# ==============================================================================

view_bootstrap_intro() {
    ui_section "KCS API Integration Bootstrap"

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

view_bootstrap_error_empty() {
    echo -e "      ${RED}${ICON_FAIL} Token cannot be empty. Please try again.${NC}"
}

view_bootstrap_warn_short() {
    echo -e "   ${RED}${ICON_FAIL} The token seems too short. Are you sure it's correct?${NC}"
}

view_bootstrap_saving_start() {
    ui_spinner_start "Saving configuration to $CONFIG_FILE"
}

view_bootstrap_saving_stop() {
    ui_spinner_stop "PASS"
}

view_bootstrap_success() {
    echo -e "\n   ${GREEN}${BOLD}${ICON_OK} BOOTSTRAP COMPLETED!${NC}"
    echo -e "   The API token has been securely stored in ~/.kcspoc/config."
    
    echo -e "\n   ${BOLD}Next Journey Steps:${NC}"
    echo -e "   - Run ${GREEN}${BOLD}./kcspoc deploy --agents${NC} to install KCS Agents on your nodes."
    echo -e "   - Check the walkthrough for advanced configuration tips.\n"
}
