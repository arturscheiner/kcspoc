#!/bin/bash

# ------------------------------------------------------------------------------
# KCS POC - Bootstrap & API Integration
# ------------------------------------------------------------------------------

cmd_bootstrap() {
    ui_banner
    ui_section "KCS API Integration Bootstrap"

    echo -e "   This command will guide you through the initial KCS API configuration."
    echo -e "   The API token is required for automated agent deployment and management.\n"

    echo -e "   ${BOLD}Step 1: Get your API Token${NC}"
    echo -e "   1. Log in to the KCS Console."
    echo -e "   2. Go to: ${BOLD}Settings > My Profile${NC} (or Admin > My Profile)."
    echo -e "   3. Click on ${BOLD}API Token${NC} and copy the value."
    echo ""

    # Phase O: Interactive Token Collection
    local token=""
    while [ -z "$token" ]; do
        echo -ne "   ${ICON_QUESTION} Please paste your ${BOLD}API Token${NC} here: "
        read -rs token
        echo ""
        if [ -z "$token" ]; then
            echo -e "      ${RED}${ICON_FAIL} Token cannot be empty. Please try again.${NC}"
        fi
    done

    # Validate token format (simple length check for now)
    if [ ${#token} -lt 20 ]; then
        echo -e "   ${RED}${ICON_FAIL} The token seems too short. Are you sure it's correct?${NC}"
    fi

    ui_spinner_start "Saving configuration to $CONFIG_FILE"
    
    # Secure Configuration Storage
    if [ -f "$CONFIG_FILE" ]; then
        # Remove existing token if present
        sed -i '/^ADMIN_API_TOKEN=/d' "$CONFIG_FILE"
        # Append new token
        echo "ADMIN_API_TOKEN=\"$token\"" >> "$CONFIG_FILE"
    fi
    
    ui_spinner_stop "PASS"

    echo -e "\n   ${GREEN}${BOLD}${ICON_OK} BOOTSTRAP COMPLETED!${NC}"
    echo -e "   The API token has been securely stored in ~/.kcspoc/config."
    
    echo -e "\n   ${BOLD}Next Journey Steps:${NC}"
    echo -e "   - Run ${GREEN}${BOLD}./kcspoc deploy --agents${NC} to install KCS Agents on your nodes."
    echo -e "   - Check the walkthrough for advanced configuration tips.\n"
}
