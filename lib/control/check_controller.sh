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

    local error=0

    # 1. Prerequisites
    view_check_section_title "" "Prerequisites"
    if ! service_check_validate_prereqs; then
        error=1
    fi

    local deep_enabled="${deep_override:-$ENABLE_DEEP_CHECK}"
    local deep_ns="kcspoc"

    # 2. Cluster Context
    view_check_section_title "" "Cluster Context"
    if [ "$error" -eq 1 ]; then
        view_check_error_skip_cluster
    else
        if ! service_check_context; then
            error=1
        else
            # Prep Deep Namespace isolation
            view_check_namespace_prep_start "$deep_ns"
            model_cluster_delete_namespace "$deep_ns" "true" &>/dev/null || true # Ignore if doesn't exist
            if model_cluster_create_namespace "$deep_ns"; then
                view_check_namespace_prep_stop "PASS"
            else
                view_check_namespace_prep_stop "FAIL"
                error=1
            fi

            # 3. Cluster Topology
            view_check_section_title "" "Cluster Topology"
            service_check_topology || error=1

            # 4. Infrastructure Status
            view_check_section_title "" "$MSG_CHECK_INFRA_TITLE"
            service_check_infrastructure

            # 5. Cloud Provider & Topology
            view_check_section_title "" "$MSG_CHECK_CLOUD_TITLE"
            service_check_cloud_and_cri

            # 6. Node Resources & Health (includes Audit as section 7 internally)
            view_check_section_title "" "$MSG_CHECK_NODE_RES_TITLE"
            service_check_resources "$deep_enabled" "$deep_ns"

            # 8. Repository Connectivity
            view_check_section_title "" "Repository Connectivity"
            service_check_repo_connectivity "$deep_ns" || error=1
        fi
    fi

    # Results
    view_check_section_title "" "Summary Results"
    service_check_summary || error=1

    # Cleanup
    if [ "$error" -eq 0 ] || [ -d "$CONFIG_DIR" ]; then
        view_check_cleanup_start
        model_cluster_delete_namespace "$deep_ns" "false" &>/dev/null || true
        view_check_cleanup_stop "PASS"
    fi

    if [ $error -eq 0 ]; then
        view_check_all_pass
    else
        view_check_final_fail
        return 1
    fi
}
