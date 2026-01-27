#!/bin/bash

# ==============================================================================
# Layer: View
# File: check_view.sh
# Responsibility: UI and Output for Check Command
# ==============================================================================

view_check_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

view_check_section_title() {
    local title="$2"
    view_ui_section_header "${title}"
}

view_check_step_start() {
    service_spinner_start "$1"
}

view_check_step_stop() {
    service_spinner_stop "$1"
}

view_check_error_skip_cluster() {
    echo -e "      ${BRIGHT_RED}${MSG_CHECK_LABEL_FAIL:-Error}:${NC}"
    echo -e "      Skipping cluster checks due to prerequisite failures."
}

view_check_namespace_prep_start() {
    local ns="$1"
    service_spinner_start "Creating management namespace: $ns"
}

view_check_namespace_prep_stop() {
    local status="$1"
    service_spinner_stop "$status"
}

view_check_info_ctx() {
    local ctx="$1"
    echo -e "      ${BLUE}${ctx}${NC}"
    echo -e "      ${DIM}$MSG_CHECK_CTX_DESC${NC}"
}

view_check_conn_error() {
    local msg="$1"
    echo -e "      [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${BRIGHT_RED}${BOLD}${MSG_CHECK_CONN_ERR}:${NC}"
    echo -e "      ${BRIGHT_RED}${msg}${NC}"
}

view_check_k8s_ver_info() {
    local ver="$1"
    local status="$2" # PASS or FAIL
    if [ "$status" == "PASS" ]; then
        echo -e "      Version: ${BRIGHT_CYAN}${ver}${NC} [ ${BRIGHT_GREEN}${ICON_OK}${NC} ] ${DIM}(1.25 - 1.34)${NC}"
    else
        echo -e "      Version: ${BRIGHT_RED}${ver}${NC} [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${DIM}(Supported: 1.25 - 1.34)${NC}"
    fi
}

view_check_arch_mixed_warn() {
    echo -e "      [ ${BRIGHT_YELLOW}${ICON_WARN}${NC} ] ${BRIGHT_YELLOW}$MSG_CHECK_ARCH_MIXED${NC}"
    echo -e "      ${DIM}${ICON_ARROW} $MSG_CHECK_ARCH_WARN${NC}"
}

view_check_arch_none_err() {
    echo -e "      [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${BRIGHT_RED}$MSG_CHECK_ARCH_NONE${NC}"
}

view_check_runtime_info() {
    echo -e "      ${BLUE}$1${NC}"
}

view_check_runtime_ver_status() {
    local name="$1"
    local ver="$2"
    local min="$3"
    local status="$4"
    if [ "$status" == "ok" ]; then
        echo -e "      - ${name} ${ver} [ ${BRIGHT_GREEN}${ICON_OK}${NC} ] ${DIM}(Min: ${min}+)${NC}"
    else
        echo -e "      - ${name} ${ver} [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${DIM}(Min: ${min}+)${NC}"
    fi
}

view_check_runtime_docker_warn() {
    echo -e "      - docker ${YELLOW}($MSG_CHECK_LABEL_WARN)${NC}"
}

view_check_runtime_unknown() {
    echo -e "      - $1 ${DIM}(Unknown)${NC}"
}

view_check_cni_info() {
    echo -e "      ${DIM}($1)${NC}"
}

view_check_cni_warn() {
    echo -e "      [ ${BRIGHT_YELLOW}${ICON_WARN}${NC} ] ${BRIGHT_YELLOW}$MSG_CHECK_CNI_WARN${NC}"
}

view_check_infra_header() {
    echo -e "   ${DIM}$MSG_CHECK_INFRA_DESC${NC}\n"
}

view_check_infra_item() {
    local label="$1"
    local status="$2" # INSTALLED or MISSING
    printf "   %-25s " "$label"
    if [ "$status" == "INSTALLED" ]; then
        echo -e "[ ${BRIGHT_GREEN}${ICON_OK}${NC} ] ${DIM}(${MSG_CHECK_INFRA_INSTALLED})${NC}"
    else
        echo -e "[ ${BRIGHT_YELLOW}${ICON_WARN}${NC} ] ${DIM}(${MSG_CHECK_INFRA_MISSING})${NC}"
    fi
}

view_check_cloud_provider_info() {
    local name="$1"
    local prov_id="$2"
    local region="$3"
    local zone="$4"
    local os_img="$5"
    echo -e "   ${ICON_INFO} ${BRIGHT_CYAN}${MSG_CHECK_CLOUD_PROVIDER}:${NC} ${BRIGHT_GREEN}${name}${NC}"
    echo -e "      ${DIM}- ProviderID : ${prov_id:-N/A}${NC}"
    echo -e "      ${DIM}- ${MSG_CHECK_CLOUD_REGION}   : ${NC}${region:-N/A}"
    echo -e "      ${DIM}- ${MSG_CHECK_CLOUD_ZONE}     : ${NC}${zone:-N/A}"
    echo -e "      ${DIM}- ${MSG_CHECK_CLOUD_OS} : ${NC}${os_img:-N/A}"
}

view_check_cri_detecting() {
    echo -e "\n   ${BOLD}${ICON_GEAR} $MSG_CHECK_CRI_DETECTING${NC}"
}

view_check_cri_info() {
    local type="$1"
    local ver="$2"
    local socket="$3"
    echo -e "      ${ICON_INFO} ${BRIGHT_CYAN}$MSG_CHECK_CRI_FOUND${NC} ${BRIGHT_GREEN}${type} (${ver})${NC}"
    if [ -n "$socket" ]; then
        echo -e "      ${ICON_INFO} ${BRIGHT_CYAN}$MSG_CHECK_CRI_SOCKET${NC} ${BRIGHT_GREEN}${socket}${NC}"
        echo -e "      ${DIM}$MSG_CHECK_CRI_HINT${NC}"
    fi
}

view_check_cri_confirmed() {
    local socket="$1"
    echo -e "      ${ICON_OK} ${BRIGHT_CYAN}$MSG_CHECK_CRI_CONFIRMED${NC} ${BRIGHT_GREEN}${socket}${NC}"
}

view_check_deep_run_info() {
    local ns="$1"
    # Output on the same line as the spinner message
    echo -ne " ${DIM}(Using isolated namespace: ${ns})${NC}"
}

view_check_deep_skip_info() {
    echo -e "   ${ICON_INFO} ${DIM}${MSG_CHECK_DEEP_SKIP}${NC}\n"
}

view_check_node_table_header() {
    view_ui_table_header \
        "NODE:25" \
        "ROLE:12" \
        "CPU(A/T):10" \
        "RAM(A/T):10" \
        "DISK(A/T):15" \
        "eBPF:10" \
        "HEADERS:10"
}

view_check_node_table_row() {
    local name="$1"
    local role="$2"
    local cpu="$3"
    local ram="$4"
    local disk="$5"
    local ebpf="$6"
    local headers="$7"
    
    view_ui_table_row \
        "$name:25" \
        "$role:12" \
        "$cpu:10" \
        "$ram:10" \
        "$disk:15" \
        "$ebpf:10" \
        "$headers:10"
}

view_check_audit_header() {
    echo -e "   ${BOLD}$MSG_AUDIT_REF_TABLE:${NC}"
    view_ui_table_header \
        "$MSG_AUDIT_RES:20" \
        "$MSG_AUDIT_MIN:15" \
        "$MSG_AUDIT_IDEAL:15"
    view_ui_table_row \
        "$MSG_AUDIT_CPU:20" \
        "4 Cores:15" \
        "12 Cores:15"
    view_ui_table_row \
        "$MSG_AUDIT_RAM:20" \
        "8 GB:15" \
        "20 GB:15"
    view_ui_table_row \
        "$MSG_AUDIT_DISK:20" \
        "80 GB:15" \
        "150 GB:15"
    echo ""
}

view_check_audit_node_rejected() {
    local name="$1"
    local fail_reasons="$2"
    local avail_str="$3"
    local total_str="$4"
    echo -e "   ${BOLD}$MSG_AUDIT_NODE_EVAL: ${name}${NC} [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${BRIGHT_RED}${MSG_AUDIT_REJECTED:-REJECTED}${NC}"
    echo -e "$fail_reasons" | while IFS='|' read -r reason cause; do
         [ -z "$reason" ] && continue
         echo -e "      ${BRIGHT_RED}${ICON_FAIL}${NC} ${reason}"
         [ -n "$cause" ] && echo -e "        ${DIM}${ICON_ARROW} ${cause#CAUSE:}${NC}"
    done
    echo -e "      ${DIM}Available: ${avail_str}${NC}"
    echo -e "      ${DIM}Total    : ${total_str}${NC}"
    view_ui_line
}

view_check_audit_success() {
    echo -e "   [ ${BRIGHT_GREEN}${ICON_OK}${NC} ] ${BRIGHT_GREEN}$MSG_AUDIT_SUCCESS${NC}"
}

view_check_audit_fail() {
    echo -e "   [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${BRIGHT_RED}$MSG_AUDIT_FAIL${NC}"
    echo -e "   ${BRIGHT_YELLOW}${ICON_ARROW} $MSG_AUDIT_REC${NC}"
}

view_check_global_totals() {
    local cpu="$1"
    local mem="$2"
    local status="$3" # PASS or FAIL
    local msg="$4"
    echo -ne "   ${ICON_INFO} $MSG_CHECK_GLOBAL_TOTALS: "
    echo -e "${BRIGHT_CYAN}${cpu} vCPUs / ${mem} GB RAM${NC}"
    if [ "$status" == "FAIL" ]; then
         echo -e "      [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${BRIGHT_RED}${msg}${NC}"
    else
         echo -e "      [ ${BRIGHT_GREEN}${ICON_OK}${NC} ] ${DIM}${msg}${NC}"
    fi
}

view_check_cleanup_start() {
    service_spinner_start "Cleaning residue"
}

view_check_cleanup_stop() {
    service_spinner_stop "$1"
}

view_check_all_pass() {
    echo -e "\n${BRIGHT_GREEN}${BOLD}[ ${ICON_OK} ] $MSG_CHECK_ALL_PASS${NC}"
    echo -e "${DIM}   Your cluster is ready for Kaspersky Container Security installation.${NC}\n"
}

view_check_final_fail() {
    echo -e "\n${BRIGHT_RED}${BOLD}[ ${ICON_FAIL} ] $MSG_CHECK_FINAL_FAIL${NC}\n"
}

view_check_prereq_config_fix() {
    echo -e "      ${DIM}${ICON_ARROW} ${BRIGHT_YELLOW}$MSG_CHECK_CONFIG_FIX${NC}"
}

view_check_prereq_config_create() {
    echo -e "      ${DIM}${ICON_ARROW} ${BRIGHT_YELLOW}$MSG_CHECK_CONFIG_CREATE${NC}"
}

view_check_prereq_kubeconfig_fail() {
    echo -e "      [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${BRIGHT_RED}${MSG_CHECK_KUBECONFIG_FAIL}${NC}"
}

view_check_prereq_tools_fail() {
    local tools="$1"
    echo -e "      [ ${BRIGHT_RED}${ICON_FAIL}${NC} ] ${BRIGHT_RED}${MSG_CHECK_TOOLS_FAIL}:${NC} ${tools}"
}

view_check_report_start() {
    local model="$1"
    echo -e "\n   ${BOLD}${ICON_GEAR} Generating AI Readiness Audit (Model: ${model})...${NC}"
}

view_check_report_success() {
    local hash="$1"
    echo -e "   ${ICON_OK} ${BRIGHT_GREEN}AI Readiness Audit generated: ${BOLD}${hash}${NC}"
    echo -e "      ${DIM}View with: ./kcspoc reports --show ${hash}${NC}"
}
