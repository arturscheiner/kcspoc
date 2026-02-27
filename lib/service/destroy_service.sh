#!/bin/bash

# ==============================================================================
# Layer: Service
# File: destroy_service.sh
# Responsibility: Business logic for coordinated resource destruction
# ==============================================================================

service_destroy_run() {
    local target_ns="$1"
    local cleanup_deps="$2"
    local release_name="${3:-kcs}"

    # Phase I: Transition Signaling
    model_ns_update_state "$target_ns" "cleaning" "destroy" "$EXEC_HASH" "$(model_config_get_hash)" ""

    view_destroy_start_msg

    # 1. Helm Release
    if model_helm_status "$release_name" "$target_ns" &>/dev/null; then
        view_destroy_step_start "[1/8] $MSG_DESTROY_STEP_1"
        model_helm_uninstall "$release_name" "$target_ns"
        view_destroy_step_stop "PASS"
    else
        view_destroy_info "[1/8] $release_name: $MSG_DESTROY_NOT_FOUND"
    fi

    # 2. PVC Purge
    view_destroy_step_start "[2/8] Mandatory PVC Purge"
    model_kubectl_delete_pvc_all "$target_ns" "60s"
    view_destroy_step_stop "PASS"

    # 3. Namespace & Certificates
    view_destroy_step_start "[3/8] $MSG_DESTROY_STEP_2"
    model_kubectl_delete_certificate_all "$target_ns" "30s"
    model_kubectl_delete_namespace "$target_ns" "120s"
    service_exec_wait_and_force_delete_ns "$target_ns" 5
    view_destroy_step_stop "PASS"

    # 4. PVs (Orphaned)
    view_destroy_step_start "[4/8] $MSG_DESTROY_STEP_4"
    local kcs_pvs=$(model_kubectl_get_pv_by_ns "$target_ns")
    if [ -n "$kcs_pvs" ]; then
        for pv in $kcs_pvs; do
            model_kubectl_delete_pv "$pv" "30s"
        done
        view_destroy_step_stop "PASS"
    else
        view_destroy_step_stop "PASS"
        view_destroy_dim_info "$MSG_DESTROY_NOT_FOUND"
    fi

    # 5. Global Webhooks
    view_destroy_step_start "[5/8] $MSG_DESTROY_STEP_5"
    local webhook_name="kcs-admission-controller"
    model_kubectl_delete_webhook "validating" "$webhook_name"
    model_kubectl_delete_webhook "mutating" "$webhook_name"
    view_destroy_step_stop "PASS"

    # 6. Global RBAC
    view_destroy_step_start "[6/8] $MSG_DESTROY_STEP_6"
    local target_rbac="kcs-admission-controller kcs-agent-broker kcs-scanner"
    model_kubectl_delete_clusterrole "$target_rbac"
    model_kubectl_delete_clusterrolebinding "$target_rbac"
    view_destroy_step_stop "PASS"

    # 7. Sanity Check (Orphaned Secrets)
    view_destroy_step_start "[7/8] Sanity Check"
    model_kubectl_delete_orphaned_secrets "-A" "sh.helm.release.v1.kcs"
    view_destroy_step_stop "PASS"

    # 8. Infrastructure Dependencies (Optional)
    if [ "$cleanup_deps" == "true" ]; then
         view_destroy_infra_header
         
         # Ingress
         view_destroy_step_start "$MSG_DESTROY_DEPS_INGRESS"
         model_helm_uninstall "ingress-nginx" "ingress-nginx"
         model_kubectl_delete_namespace_nowait "ingress-nginx"
         service_exec_wait_and_force_delete_ns "ingress-nginx" 3
         view_destroy_step_stop "PASS"
 
         # MetalLB
         view_destroy_step_start "$MSG_DESTROY_DEPS_METALLB"
         model_helm_uninstall "metallb" "metallb-system"
         model_kubectl_delete_namespace_nowait "metallb-system"
         service_exec_wait_and_force_delete_ns "metallb-system" 3
         view_destroy_step_stop "PASS"
         
         # Cert-Manager
         view_destroy_step_start "$MSG_DESTROY_DEPS_CERT"
         model_helm_uninstall "cert-manager" "cert-manager"
         model_kubectl_delete_namespace_nowait "cert-manager"
         service_exec_wait_and_force_delete_ns "cert-manager" 3
         view_destroy_step_stop "PASS"
         
         # Storage & Metrics
         view_destroy_step_start "$MSG_DESTROY_DEPS_STORAGE"
         model_kubectl_delete_deployment "metrics-server" "kube-system" || true
         model_helm_uninstall "local-path-storage" "local-path-storage" || true
         model_kubectl_delete_namespace_nowait "local-path-storage" || true
         service_exec_wait_and_force_delete_ns "local-path-storage" 3 || true
         view_destroy_step_stop "PASS"

         # KCSPOC Isolation Namespace
         local kcspoc_ns="${KCSPOC_NAMESPACE:-kcspoc}"
         view_destroy_step_start "Cleaning $kcspoc_ns"
         model_kubectl_delete_namespace_nowait "$kcspoc_ns"
         service_exec_wait_and_force_delete_ns "$kcspoc_ns" 3
         view_destroy_step_stop "PASS"
    else
         view_destroy_infra_skipped
    fi

    view_destroy_success
    return 0
}
