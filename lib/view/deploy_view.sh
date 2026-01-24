#!/bin/bash

# ==============================================================================
# Layer: View
# File: deploy_view.sh
# Responsibility: UI, reports and progress monitoring for the Deploy command
# ==============================================================================

view_deploy_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

view_deploy_section() {
    view_ui_section "$1"
}

view_deploy_step_start() {
    service_spinner_start "$1"
}

view_deploy_step_stop() {
    service_spinner_stop "$1"
}

view_deploy_info() {
    echo -e "   ${BLUE}${ICON_INFO} $1${NC}"
}

view_deploy_error() {
    echo -e "   ${RED}${ICON_FAIL} $1${NC}"
}

view_deploy_integrity_report() {
    local col_header="$1"
    local ns="$2"
    local local_val="$3"
    local remote_val="$4"
    local match_icon="$5"
    
    echo -e "   ${BOLD}Namespace:${NC} $ns\n"
    printf "   %-32s | %-32s | %s\n" "LOCAL $col_header" "CLUSTER/REMOTE" "MATCH"
    printf "   ---------------------------------|----------------------------------|-------\n"
    printf "   %-32s | %-32s |  %b\n" "$local_val" "$remote_val" "$match_icon"
    echo ""
}

view_deploy_mismatch_warning() {
    local mode="$1"
    echo -e "   ${RED}${BOLD}${ICON_WARN} Mismatched $mode Detected!${NC}"
    if [ "$mode" == "hash" ]; then
        echo -e "   ${DIM}This deploy may break data encryption (Cipher Error).${NC}"
    fi
    echo -e "   ${DIM}Please sync your local configuration with the cluster status.${NC}"
    echo ""
}

view_deploy_collision_warning() {
    local collision_list="$1"
    echo -e "\n   ${RED}${BOLD}${ICON_WARN} GLOBAL COLLISION DETECTED!${NC}"
    echo -e "   Kaspersky Container Security was found in other namespaces:"
    echo -e "${DIM}$collision_list${NC}"
    echo -e "   ${BOLD}DANGER:${NC} Installing multiple instances may cause conflict in global"
    echo -e "   resources (Admission Webhooks, ClusterRoles)."
}

view_deploy_stability_watcher_start() {
    echo -e "\n  ${YELLOW}${ICON_GEAR} ${BOLD}PHASE 6: DEPLOYMENT STABILITY WATCHER${NC}"
    echo -e "  ${DIM}Monitoring pod convergence (timeout: 15m)...${NC}\n"
    tput civis 2>/dev/null || true
}

view_deploy_stability_watcher_stop() {
    tput cnorm 2>/dev/null || true
}

view_deploy_stability_progress() {
    local bar="$1"
    local percent="$2"
    local stable_count="$3"
    local total_pods="$4"
    local frame="$5"

    if [ "$total_pods" -gt 0 ]; then
        printf "\r   ${ICON_ARROW} Progress: ${BLUE}%s${NC} ${BOLD}%d%%${NC} (%d/%d pods)  ${CYAN}%s${NC} " "$bar" "$percent" "$stable_count" "$total_pods" "$frame"
    else
        printf "\r   ${ICON_ARROW} Waiting for pods to initialize... ${CYAN}%s${NC} " "$frame"
    fi
}

view_deploy_stability_success() {
    echo -e "\n\n  ${GREEN}${BOLD}${ICON_OK} DEPLOYMENT SUCCESSFUL!${NC}"
    echo -e "  All KCS components are Running/Completed."
}

view_deploy_stability_timeout() {
    echo -e "\n\n  ${RED}${BOLD}${ICON_FAIL} DEPLOYMENT TIMEOUT!${NC}"
    echo -e "  Convergence took longer than 15 minutes. Checking for 'Init' or 'ImagePull' errors."
}

view_deploy_boarding_pass() {
    local domain="$1"
    local display_pass="$2"
    local pass_note="$3"

    echo -e "\n  ${BLUE}================================================================${NC}"
    echo -e "  ${BOLD}${ICON_ROCKET} KASPERSKY CONTAINER SECURITY IS READY FOR DEMO!${NC}"
    echo -e "  ${BLUE}================================================================${NC}"
    echo -e "\n  ${BOLD}1. Access the Web Console:${NC}"
    echo -e "     URL:      ${GREEN}https://$domain${NC}"
    echo -e "     Username: ${YELLOW}admin${NC}"
    echo -e "     Password: ${YELLOW}${display_pass}${NC} ($pass_note)"
    
    echo -e "\n  ${BOLD}2. Next Step (Automated Onboarding):${NC}"
    echo -e "     Log in to the console, go to ${BOLD}Settings > API Keys${NC},"
    echo -e "     generate a new key, and then run:"
    echo -e "\n     ${GREEN}${BOLD}./kcspoc bootstrap${NC}"
    
    echo -e "\n     ${BLUE}This command will:${NC}"
    echo -e "     ${DIM}- Configure the API integration${NC}"
    echo -e "     ${DIM}- Create a default 'PoC Agent Group'${NC}"
    echo -e "     ${DIM}- Prepare the environment for './kcspoc deploy --agents'${NC}"
    echo -e "  ${BLUE}================================================================${NC}\n"
}

view_deploy_prompt_collision_proceed() {
    echo -ne "   ${YELLOW}Do you want to proceed anyway? [y/N]${NC} "
    read -r confirm
    [[ "$confirm" =~ ^[yY]$ ]]
}

view_deploy_prompt_upgrade() {
    local target_ver="$1"
    local op_type="$2"
    echo -e "   ${YELLOW}${ICON_INFO} $(printf "$MSG_DEPLOY_UPGRADE_PROMPT" "${BOLD}${target_ver}${NC}") ($op_type) [y/N]"
    read -p "   > " confirm
    [[ "$confirm" =~ ^[yY]$ ]]
}

view_deploy_prompt_install() {
    local target_ver="$1"
    local op_type="$2"
    echo -e "   ${YELLOW}${ICON_INFO} ${MSG_DEPLOY_CONFIRM} ${BOLD}${target_ver}${NC}? ($op_type) [y/N]"
    read -p "   > " confirm
    [[ "$confirm" =~ ^[yY]$ ]]
}

view_deploy_healing_immutability() {
    echo -e "      ${YELLOW}${ICON_GEAR} Immutability detected. Fixing StatefulSets...${NC}"
}
