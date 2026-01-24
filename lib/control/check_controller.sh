#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: check_controller.sh
# Responsibility: Argument parsing and orchestration for Check Command
# ==============================================================================

check_controller() {
    local deep_override=""
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -d|--deep) deep_override="true"; shift ;;
            --help|help)
                view_ui_help "check" "$MSG_HELP_CHECK_DESC" "$MSG_HELP_CHECK_OPTS" "$MSG_HELP_CHECK_EX" "$VERSION"
                return 0
                ;;
            *)
                view_ui_help "check" "$MSG_HELP_CHECK_DESC" "$MSG_HELP_CHECK_OPTS" "$MSG_HELP_CHECK_EX" "$VERSION"
                return 1
                ;;
        esac
    done

    view_check_banner
    local error=0

    # 1. Prerequisites
    view_check_section_title "1" "Prerequisites"
    if ! service_check_validate_prereqs; then
        error=1
    fi

    local deep_enabled="${deep_override:-$ENABLE_DEEP_CHECK}"
    local deep_ns="kcspoc"

    # 2. Cluster Context
    view_check_section_title "2" "Cluster Context"
    if [ "$error" -eq 1 ]; then
        view_check_error_skip_cluster
        return 1
    fi

    if ! service_check_context; then
        error=1
        return 1
    fi

    # Prep Deep Namespace isolation
    model_cluster_delete_namespace "$deep_ns" "true" # force clean
    model_cluster_create_namespace "$deep_ns"

    # 3. Cluster Topology
    view_check_section_title "3" "Cluster Topology"
    service_check_topology || error=1

    # 4. Infrastructure Status
    view_check_section_title "4" "$MSG_CHECK_INFRA_TITLE"
    service_check_infrastructure

    # 5. Cloud Provider & Topology
    view_check_section_title "5" "$MSG_CHECK_CLOUD_TITLE"
    service_check_cloud_and_cri

    # 6. Node Resources & Health (includes Audit as section 7 internally to match old layout)
    view_check_section_title "6" "$MSG_CHECK_NODE_RES_TITLE"
    service_check_resources "$deep_enabled" "$deep_ns"

    # 8. Repository Connectivity
    view_check_section_title "8" "Repository Connectivity"
    service_check_repo_connectivity "$deep_ns" || error=1

    # Results
    view_check_section_title "Results" "Summary Results"
    service_check_summary || error=1

    # Cleanup
    view_check_cleaning_residue
    model_cluster_delete_namespace "$deep_ns" "false"
    view_check_cleaning_done

    echo ""
    if [ $error -eq 0 ]; then
        view_check_all_pass
    else
        view_check_final_fail
        exit 1
    fi
}
