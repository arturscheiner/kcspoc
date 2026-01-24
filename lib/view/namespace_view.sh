#!/bin/bash

# ==============================================================================
# Layer: View
# File: namespace_view.sh
# Responsibility: UI for Kubernetes Namespace operations
# ==============================================================================

view_ns_check_start() {
    local label_key="$1"
    local label_val="$2"
    echo -ne "      ${ICON_GEAR} Checking Label ($label_key=$label_val)... "
}

view_ns_check_ok() {
    echo -e "[ ${GREEN}${ICON_OK}${NC} ]"
}

view_ns_check_fail() {
    echo -e "[ ${RED}${ICON_FAIL}${NC} ]"
}
