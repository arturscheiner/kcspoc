#!/bin/bash

# ==============================================================================
# Layer: Service
# File: extra_pack_service.sh
# Responsibility: Business logic for extra-packs (Install/Uninstall/List)
# ==============================================================================

_service_extra_get_name() {
    case "$1" in
        "registry-auth") echo "Registry Secret" ;;
        "cert-manager") echo "Cert-Manager" ;;
        "local-path-storage") echo "Local Path Storage" ;;
        "metrics-server") echo "Metrics Server" ;;
        "metallb") echo "MetalLB" ;;
        "ingress-nginx") echo "Ingress-Nginx" ;;
        "kernel-headers") echo "Kernel Headers" ;;
        *) echo "$1" ;;
    esac
}

service_extra_pack_install() {
    local pack="$1"
    local unattended="${2:-false}"
    local context
    context=$(model_cluster_get_current_context)

    case "$pack" in
        "registry-auth")
            if view_prepare_confirm_step "Registry Secret" "$MSG_PREPARE_WHY_REGISTRY_TITLE" "$MSG_PREPARE_WHY_REGISTRY_DESC" "$unattended"; then
                view_prepare_step_start "$MSG_PREPARE_STEP_1"
                if model_kubectl_create_docker_secret "kcs-registry-secret" "$NAMESPACE" "$REGISTRY_SERVER" "$REGISTRY_USER" "$REGISTRY_PASS" && \
                   model_kubectl_label "secret" "kcs-registry-secret" "$NAMESPACE" "$POC_LABEL"; then
                    view_prepare_step_stop "PASS"
                    if model_ns_check_label "secret" "kcs-registry-secret" "$NAMESPACE" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                        view_prepare_infra_status "PASS" "secret" "kcs-registry-secret"
                        model_state_record_install "$pack" "$(_service_extra_get_name "$pack")" "$context"
                    else
                        view_prepare_infra_status "FAIL" "secret" "kcs-registry-secret"
                    fi
                else
                    view_prepare_step_stop "FAIL"
                    return 1
                fi
            fi
            ;;
        "cert-manager")
            if view_prepare_confirm_step "Cert-Manager" "$MSG_PREPARE_WHY_CERT_TITLE" "$MSG_PREPARE_WHY_CERT_DESC" "$unattended"; then
                view_prepare_step_start "$MSG_PREPARE_INSTALL_CERT"
                model_cluster_delete_namespace "cert-manager"
                model_helm_repo_add "jetstack" "https://charts.jetstack.io"
                local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
                if model_helm_upgrade_install "cert-manager" "jetstack/cert-manager" "cert-manager" "300s" "$HELM_ERR" \
                    --set crds.enabled=true --set startupapicheck.enabled=false; then
                    model_kubectl_label "namespace" "cert-manager" "" "$POC_LABEL"
                    model_kubectl_label_all "deployment" "cert-manager" "$POC_LABEL"
                    view_prepare_step_stop "PASS"
                    if model_ns_check_label "namespace" "cert-manager" "" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                        view_prepare_infra_status "PASS" "namespace" "cert-manager"
                        model_state_record_install "$pack" "$(_service_extra_get_name "$pack")" "$context"
                    else
                        view_prepare_infra_status "FAIL" "namespace" "cert-manager"
                    fi
                else
                    view_prepare_step_stop "FAIL"
                    local err_msg=$(cat "$HELM_ERR" 2>/dev/null | tr '\n' ' ' | cut -c 1-120)
                    [ -n "$err_msg" ] && view_prepare_step_error "${err_msg}..."
                    cat "$HELM_ERR" >> "$DEBUG_OUT" 2>/dev/null
                    return 1
                fi
            fi
            ;;
        "local-path-storage")
            if view_prepare_confirm_step "Local Path Storage" "$MSG_PREPARE_WHY_STORAGE_TITLE" "$MSG_PREPARE_WHY_STORAGE_DESC" "$unattended"; then
                model_fs_download_artifact "local-path-provisioner" "https://github.com/rancher/local-path-provisioner.git"
                view_prepare_step_start "$MSG_PREPARE_INSTALL_LOCAL"
                model_cluster_delete_namespace "local-path-storage"
                local CHART_PATH="$ARTIFACTS_DIR/local-path-provisioner/deploy/chart/local-path-provisioner"
                if model_helm_upgrade_install_local "local-path-storage" "$CHART_PATH" "local-path-storage"; then
                    model_kubectl_patch_storageclass "local-path" '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
                    model_kubectl_label "sc" "local-path" "" "$POC_LABEL"
                    view_prepare_step_stop "PASS"
                    if model_ns_check_label "sc" "local-path" "" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                        view_prepare_infra_status "PASS" "sc" "local-path"
                        model_state_record_install "$pack" "$(_service_extra_get_name "$pack")" "$context"
                    else
                        view_prepare_infra_status "FAIL" "sc" "local-path"
                    fi
                else
                    view_prepare_step_stop "FAIL"
                    view_prepare_step_error "Helm install failed. Check logs."
                    return 1
                fi
            fi
            ;;
        "metrics-server")
            if view_prepare_confirm_step "Metrics Server" "$MSG_PREPARE_WHY_METRICS_TITLE" "$MSG_PREPARE_WHY_METRICS_DESC" "$unattended"; then
                model_fs_download_artifact "metrics-server" "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
                view_prepare_step_start "$MSG_PREPARE_INSTALL_METRICS"
                if model_kubectl_apply_file "$ARTIFACTS_DIR/metrics-server/components.yaml" && \
                   model_kubectl_patch_deployment "metrics-server" "kube-system" "json" '[
                     {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
                     {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP"}
                   ]' && \
                   model_kubectl_label "deployment" "metrics-server" "kube-system" "$POC_LABEL"; then
                    view_prepare_step_stop "PASS"
                    if model_ns_check_label "deployment" "metrics-server" "kube-system" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                        view_prepare_infra_status "PASS" "deployment" "metrics-server"
                        model_state_record_install "$pack" "$(_service_extra_get_name "$pack")" "$context"
                    else
                        view_prepare_infra_status "FAIL" "deployment" "metrics-server"
                    fi
                else
                    view_prepare_step_stop "FAIL"
                    return 1
                fi
            fi
            ;;
        "metallb")
            if view_prepare_confirm_step "MetalLB" "$MSG_PREPARE_WHY_METALLB_TITLE" "$MSG_PREPARE_WHY_METALLB_DESC" "$unattended"; then
                view_prepare_step_start "$MSG_PREPARE_STEP_3"
                model_cluster_delete_namespace "metallb-system"
                model_helm_repo_add "metallb" "https://metallb.github.io/metallb"
                local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
                if model_helm_upgrade_install "metallb" "metallb/metallb" "metallb-system" "300s" "$HELM_ERR"; then
                    model_kubectl_label "namespace" "metallb-system" "" "$POC_LABEL"
                    model_kubectl_label_all "deployment" "metallb-system" "$POC_LABEL"
                    sleep 5
                    cat <<EOF | model_kubectl_apply_stdin
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
  labels:
    $POC_LABEL_KEY: "$POC_LABEL_VAL"
spec:
  addresses:
  - $IP_RANGE
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
  labels:
    $POC_LABEL_KEY: "$POC_LABEL_VAL"
spec:
  ipAddressPools:
  - first-pool
EOF
                    view_prepare_step_stop "PASS"
                    if model_ns_check_label "namespace" "metallb-system" "" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                        view_prepare_infra_status "PASS" "namespace" "metallb-system"
                        model_state_record_install "$pack" "$(_service_extra_get_name "$pack")" "$context"
                    else
                        view_prepare_infra_status "FAIL" "namespace" "metallb-system"
                    fi
                else
                    view_prepare_step_stop "FAIL"
                    local err_msg=$(cat "$HELM_ERR" 2>/dev/null | tr '\n' ' ' | cut -c 1-120)
                    [ -n "$err_msg" ] && view_prepare_step_error "${err_msg}..."
                    cat "$HELM_ERR" >> "$DEBUG_OUT" 2>/dev/null
                    return 1
                fi
            fi
            ;;
        "ingress-nginx")
            if view_prepare_confirm_step "Ingress-Nginx" "$MSG_PREPARE_WHY_INGRESS_TITLE" "$MSG_PREPARE_WHY_INGRESS_DESC" "$unattended"; then
                view_prepare_step_start "$MSG_PREPARE_STEP_4"
                model_cluster_delete_namespace "ingress-nginx"
                model_helm_repo_add "ingress-nginx" "https://kubernetes.github.io/ingress-nginx"
                local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
                if model_helm_upgrade_install "ingress-nginx" "ingress-nginx/ingress-nginx" "ingress-nginx" "300s" "$HELM_ERR"; then
                    model_kubectl_label "namespace" "ingress-nginx" "" "$POC_LABEL"
                    model_kubectl_label_all "deployment" "ingress-nginx" "$POC_LABEL"
                    view_prepare_step_stop "PASS"
                    if model_ns_check_label "namespace" "ingress-nginx" "" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                        view_prepare_infra_status "PASS" "namespace" "ingress-nginx"
                        model_state_record_install "$pack" "$(_service_extra_get_name "$pack")" "$context"
                    else
                        view_prepare_infra_status "FAIL" "namespace" "ingress-nginx"
                    fi
                else
                    view_prepare_step_stop "FAIL"
                    local err_msg=$(cat "$HELM_ERR" 2>/dev/null | tr '\n' ' ' | cut -c 1-120)
                    [ -n "$err_msg" ] && view_prepare_step_error "${err_msg}..."
                    cat "$HELM_ERR" >> "$DEBUG_OUT" 2>/dev/null
                    return 1
                fi
            fi
            ;;
        "kernel-headers")
            if view_prepare_confirm_step "Kernel Headers" "$MSG_PREPARE_WHY_HEADERS_TITLE" "$MSG_PREPARE_WHY_HEADERS_DESC" "$unattended"; then
                view_prepare_step_start "$MSG_PREPARE_STEP_5"
                if model_system_install_headers; then
                    view_prepare_step_stop "PASS"
                    model_state_record_install "$pack" "$(_service_extra_get_name "$pack")" "host"
                else
                    view_prepare_step_stop "FAIL"
                    return 1
                fi
            fi
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

service_extra_pack_uninstall() {
    local pack="$1"
    local context
    context=$(model_cluster_get_current_context)
    
    case "$pack" in
        "ingress-nginx")
            view_prepare_step_start "Removing Ingress-Nginx"
            model_helm_uninstall "ingress-nginx" "ingress-nginx"
            model_kubectl_delete_namespace "ingress-nginx" "false"
            service_exec_wait_and_force_delete_ns "ingress-nginx" 3
            view_prepare_step_stop "PASS"
            model_state_record_uninstall "$pack" "$context"
            ;;
        "metallb")
            view_prepare_step_start "Removing MetalLB"
            model_helm_uninstall "metallb" "metallb-system"
            model_kubectl_delete_namespace "metallb-system" "false"
            service_exec_wait_and_force_delete_ns "metallb-system" 3
            view_prepare_step_stop "PASS"
            model_state_record_uninstall "$pack" "$context"
            ;;
        "metrics-server")
            view_prepare_step_start "Removing Metrics Server"
            kubectl delete deployment metrics-server -n kube-system &>> "$DEBUG_OUT" || true
            view_prepare_step_stop "PASS"
            model_state_record_uninstall "$pack" "kube-system" # Special case or default context
            ;;
        "local-path-storage")
            view_prepare_step_start "Removing Local Path Storage"
            model_helm_uninstall "local-path-storage" "local-path-storage"
            model_kubectl_delete_namespace "local-path-storage" "false"
            service_exec_wait_and_force_delete_ns "local-path-storage" 3
            view_prepare_step_stop "PASS"
            model_state_record_uninstall "$pack" "$context"
            ;;
        "cert-manager")
            view_prepare_step_start "Removing Cert-Manager"
            model_helm_uninstall "cert-manager" "cert-manager"
            model_kubectl_delete_namespace "cert-manager" "false"
            service_exec_wait_and_force_delete_ns "cert-manager" 3
            view_prepare_step_stop "PASS"
            model_state_record_uninstall "$pack" "$context"
            ;;
        "registry-auth")
            view_prepare_step_start "Removing Registry Secret"
            kubectl delete secret kcs-registry-secret -n "$NAMESPACE" &>> "$DEBUG_OUT" || true
            view_prepare_step_stop "PASS"
            model_state_record_uninstall "$pack" "$context"
            ;;
    esac
}
