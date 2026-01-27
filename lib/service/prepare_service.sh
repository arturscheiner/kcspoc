#!/bin/bash

# ==============================================================================
# Layer: Service
# File: prepare_service.sh
# Responsibility: Business logic for infrastructure preparation
# ==============================================================================

service_prepare_run_all() {
    local list="$1"
    local PREPARE_ERROR=0

    # Expand 'all' or empty to full list
    if [ "$list" == "all" ] || [ -z "$list" ]; then
        list="registry-auth,cert-manager,local-path-storage,metrics-server,metallb,ingress-nginx,kernel-headers"
    fi

    # Convert comma-separated string to array
    IFS=',' read -ra ADDR <<< "$list"
    for pack in "${ADDR[@]}"; do
        if ! service_extra_pack_install "$pack" "$UNATTENDED"; then
            PREPARE_ERROR=1
        fi
    done

    # 8. Verification & Summary
    view_prepare_summary_header
    sleep 5
    local ingress_ip=$(model_kubectl_get_ingress_ip)

    if [ "$PREPARE_ERROR" -eq 1 ]; then
        view_prepare_summary_fail
        return 1
    else
        view_prepare_summary_success "$ingress_ip" "$DOMAIN"
        return 0
    fi
}

service_prepare_uninstall() {
    local list="$1"
    
    # Expand 'all' to full list
    if [ "$list" == "all" ]; then
        list="ingress-nginx,metallb,metrics-server,local-path-storage,cert-manager,registry-auth"
    fi

    view_prepare_section "Infrastructure Removal"

    # Convert comma-separated string to array
    IFS=',' read -ra ADDR <<< "$list"
    for pack in "${ADDR[@]}"; do
        service_extra_pack_uninstall "$pack"
    done

    view_prepare_summary_header
    echo -e "${BRIGHT_GREEN}${ICON_OK} Infrastructure cleanup completed.${NC}"
}
