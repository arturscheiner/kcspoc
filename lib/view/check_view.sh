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
    local num="$1"
    local title="$2"
    view_ui_section "${num}. ${title}"
}

view_check_step_start() {
    service_spinner_start "$1"
}

view_check_step_stop() {
    service_spinner_stop "$1"
}

view_check_error_skip_cluster() {
    echo -e "   ${RED}${ICON_FAIL} Skipping cluster checks due to prerequisite failures.${NC}"
}

view_check_info_ctx() {
    local ctx="$1"
    echo -e "      ${BLUE}${ctx}${NC}"
    echo -e "      ${DIM}$MSG_CHECK_CTX_DESC${NC}"
}

view_check_conn_error() {
    local msg="$1"
    echo -e "      ${RED}${BOLD}${MSG_CHECK_CONN_ERR}:${NC}"
    echo -e "      ${RED}${msg}${NC}"
}

view_check_k8s_ver_info() {
    local ver="$1"
    local status="$2" # PASS or FAIL
    if [ "$status" == "PASS" ]; then
        echo -e "      ${BLUE}${ver}${NC} ${DIM}(1.25 - 1.34)${NC}"
    else
        echo -e "      ${RED}${ver}${NC} ${DIM}(Supported: 1.25 - 1.34)${NC}"
    fi
}

view_check_arch_mixed_warn() {
    echo -e "      ${YELLOW}$MSG_CHECK_LABEL_WARN: $MSG_CHECK_ARCH_MIXED${NC}"
    echo -e "      ${DIM}$MSG_CHECK_ARCH_WARN${NC}"
}

view_check_arch_none_err() {
    echo -e "      ${RED}$MSG_CHECK_ARCH_NONE${NC}"
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
        echo -e "      - ${name} ${ver} ${GREEN}(OK - ${min}+)${NC}"
    else
        echo -e "      - ${name} ${ver} ${RED}(FALHA - Min ${min})${NC}"
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
    echo -e "      ${YELLOW}$MSG_CHECK_LABEL_WARN: $MSG_CHECK_CNI_WARN${NC}"
}

view_check_infra_header() {
    echo -e "   ${DIM}$MSG_CHECK_INFRA_DESC${NC}\n"
}

view_check_infra_item() {
    local label="$1"
    local status="$2" # INSTALLED or MISSING
    printf "   %-25s " "$label"
    if [ "$status" == "INSTALLED" ]; then
        echo -e "[ ${GREEN}${MSG_CHECK_INFRA_INSTALLED}${NC} ]"
    else
        echo -e "[ ${YELLOW}${MSG_CHECK_INFRA_MISSING}${NC} ]"
    fi
}

view_check_cloud_provider_info() {
    local name="$1"
    local prov_id="$2"
    local region="$3"
    local zone="$4"
    local os_img="$5"
    echo -e "   ${ICON_INFO} ${BLUE}${MSG_CHECK_CLOUD_PROVIDER}:${NC} ${GREEN}${name}${NC}"
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
    echo -e "      ${ICON_INFO} ${BLUE}$MSG_CHECK_CRI_FOUND${NC} ${GREEN}${type} (${ver})${NC}"
    if [ -n "$socket" ]; then
        echo -e "      ${ICON_INFO} ${BLUE}$MSG_CHECK_CRI_SOCKET${NC} ${GREEN}${socket}${NC}"
        echo -e "      ${DIM}$MSG_CHECK_CRI_HINT${NC}"
    fi
}

view_check_cri_confirmed() {
    local socket="$1"
    echo -e "      ${ICON_OK} ${BLUE}$MSG_CHECK_CRI_CONFIRMED${NC} ${GREEN}${socket}${NC}"
}

view_check_deep_run_info() {
    local ns="$1"
    echo -e "      ${DIM}(Using isolated namespace: ${ns})${NC}"
}

view_check_deep_skip_info() {
    echo -e "   ${ICON_INFO} ${DIM}${MSG_CHECK_DEEP_SKIP}${NC}\n"
}

view_check_node_table_header() {
    printf "   ${BOLD}%-25s %-12s %-10s %-10s %-15s %-15s %-15s${NC}\n" "NODE" "ROLE" "CPU(A/T)" "RAM(A/T)" "DISK(A/T)" "eBPF" "HEADERS"
    printf "   ${DIM}%s${NC}\n" "----------------------------------------------------------------------------------------------------"
}

view_check_node_table_row() {
    local name="$1"
    local role="$2"
    local cpu="$3"
    local ram="$4"
    local disk="$5"
    local ebpf="$6"
    local headers="$7"
    printf "   %-25s %-12s %-10s %-10s %-15b %-15b %-15b\n" "$name" "$role" "$cpu" "$ram" "$disk" "$ebpf" "$headers"
}

view_check_audit_header() {
    echo -e "   ${BOLD}$MSG_AUDIT_REF_TABLE:${NC}"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_RES" "$MSG_AUDIT_MIN" "$MSG_AUDIT_IDEAL"
    printf "   %-20s | %-15s | %-15s\n" "--------------------" "---------------" "---------------"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_CPU" "4 Cores" "12 Cores"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_RAM" "8 GB" "20 GB"
    printf "   %-20s | %-15s | %-15s\n" "$MSG_AUDIT_DISK" "80 GB" "150 GB"
    echo ""
}

view_check_audit_node_rejected() {
    local name="$1"
    local fail_reasons="$2"
    local avail_str="$3"
    local total_str="$4"
    echo -e "   ${BOLD}$MSG_AUDIT_NODE_EVAL: ${name}${NC} ${RED}$MSG_AUDIT_REJECTED${NC}"
    echo -e "$fail_reasons"
    echo -e "      ${DIM}Available: ${avail_str}${NC}"
    echo -e "      ${DIM}Total    : ${total_str}${NC}"
    echo "   ----------------------------------------------------"
}

view_check_audit_success() {
    echo -e "   ${GREEN}$MSG_AUDIT_SUCCESS${NC}"
}

view_check_audit_fail() {
    echo -e "   ${RED}$MSG_AUDIT_FAIL${NC}"
    echo -e "   ${YELLOW}$MSG_AUDIT_REC${NC}"
}

view_check_global_totals() {
    local cpu="$1"
    local mem="$2"
    local status="$3" # PASS or FAIL
    local msg="$4"
    echo -ne "   ${ICON_INFO} $MSG_CHECK_GLOBAL_TOTALS: "
    echo -e "${BLUE}${cpu} vCPUs / ${mem} GB RAM${NC}"
    if [ "$status" == "FAIL" ]; then
         echo -e "      ${RED}$MSG_CHECK_LABEL_FAIL${NC} ${RED}${msg}${NC}"
    else
         echo -e "      ${GREEN}$MSG_CHECK_LABEL_PASS${NC} ${DIM}${msg}${NC}"
    fi
}

view_check_cleaning_residue() {
    echo -ne "   ${ICON_GEAR} Cleaning residue... "
}

view_check_cleaning_done() {
    echo -e "${DIM}Done${NC}"
}

view_check_all_pass() {
    echo -e "${GREEN}${BOLD}${ICON_OK} $MSG_CHECK_ALL_PASS${NC}"
    echo -e "${DIM}Your cluster is ready for Kaspersky Container Security installation.${NC}"
}

view_check_final_fail() {
    echo -e "${RED}${BOLD}${ICON_FAIL} $MSG_CHECK_FINAL_FAIL${NC}"
}

view_check_prereq_config_fix() {
    echo -e "      ${YELLOW}$MSG_CHECK_CONFIG_FIX${NC}"
}

view_check_prereq_config_create() {
    echo -e "      ${YELLOW}$MSG_CHECK_CONFIG_CREATE${NC}"
}

view_check_prereq_kubeconfig_fail() {
    echo -e "      ${RED}${MSG_CHECK_KUBECONFIG_FAIL}${NC}"
}

view_check_prereq_tools_fail() {
    local tools="$1"
    echo -e "      ${RED}${MSG_CHECK_TOOLS_FAIL}:${tools}${NC}"
}
