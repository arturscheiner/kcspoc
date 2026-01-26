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

    _should_run() {
        local comp="$1"
        [[ ",$list," == *",$comp,"* ]] && return 0
        return 1
    }

    # 1. Docker Registry Secret
    if _should_run "registry-auth"; then
        if view_prepare_confirm_step "Registry Secret" "$MSG_PREPARE_WHY_REGISTRY_TITLE" "$MSG_PREPARE_WHY_REGISTRY_DESC" "$UNATTENDED"; then
            view_prepare_step_start "$MSG_PREPARE_STEP_1"
            if model_kubectl_create_docker_secret "kcs-registry-secret" "$NAMESPACE" "$REGISTRY_SERVER" "$REGISTRY_USER" "$REGISTRY_PASS" && \
               model_kubectl_label "secret" "kcs-registry-secret" "$NAMESPACE" "$POC_LABEL"; then
                view_prepare_step_stop "PASS"
                if model_ns_check_label "secret" "kcs-registry-secret" "$NAMESPACE" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                    view_prepare_infra_status "PASS" "secret" "kcs-registry-secret"
                else
                    view_prepare_infra_status "FAIL" "secret" "kcs-registry-secret"
                fi
            else
                view_prepare_step_stop "FAIL"
                PREPARE_ERROR=1
            fi
        fi
    fi

    # 2. Cert-Manager
    if _should_run "cert-manager"; then
        if view_prepare_confirm_step "Cert-Manager" "$MSG_PREPARE_WHY_CERT_TITLE" "$MSG_PREPARE_WHY_CERT_DESC" "$UNATTENDED"; then
            view_prepare_step_start "$MSG_PREPARE_INSTALL_CERT"
            model_cluster_delete_namespace "cert-manager" # Legacy behavior preserved
            
            local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
            model_helm_repo_add "jetstack" "https://charts.jetstack.io"
            
            if model_helm_upgrade_install "cert-manager" "jetstack/cert-manager" "cert-manager" "300s" "$HELM_ERR" \
                --set crds.enabled=true --set startupapicheck.enabled=false; then
                
                # Label
                model_kubectl_label "namespace" "cert-manager" "" "$POC_LABEL"
                model_kubectl_label_all "deployment" "cert-manager" "$POC_LABEL"
                
                view_prepare_step_stop "PASS"
                if model_ns_check_label "namespace" "cert-manager" "" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                    view_prepare_infra_status "PASS" "namespace" "cert-manager"
                else
                    view_prepare_infra_status "FAIL" "namespace" "cert-manager"
                fi
            else
                view_prepare_step_stop "FAIL"
                local err_msg=$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)
                view_prepare_step_error "${err_msg}..."
                cat "$HELM_ERR" >> "$DEBUG_OUT"
                PREPARE_ERROR=1
            fi
        fi
    fi

    # 3. Local Path Storage
    if _should_run "local-path-storage"; then
        if view_prepare_confirm_step "Local Path Storage" "$MSG_PREPARE_WHY_STORAGE_TITLE" "$MSG_PREPARE_WHY_STORAGE_DESC" "$UNATTENDED"; then
            download_artifact "local-path-provisioner" "https://github.com/rancher/local-path-provisioner.git"
            
            view_prepare_step_start "$MSG_PREPARE_INSTALL_LOCAL"
            model_cluster_delete_namespace "local-path-storage"
            local CHART_PATH="$ARTIFACTS_DIR/local-path-provisioner/deploy/chart/local-path-provisioner"
            
            if model_helm_upgrade_install_local "local-path-storage" "$CHART_PATH" "local-path-storage"; then
                model_kubectl_patch_storageclass "local-path" '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
                model_kubectl_label "sc" "local-path" "" "$POC_LABEL"
                view_prepare_step_stop "PASS"
                if model_ns_check_label "sc" "local-path" "" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                    view_prepare_infra_status "PASS" "sc" "local-path"
                else
                    view_prepare_infra_status "FAIL" "sc" "local-path"
                fi
            else
                view_prepare_step_stop "FAIL"
                view_prepare_step_error "Helm install failed. Check logs."
                PREPARE_ERROR=1
            fi
        fi
    fi

    # 4. Metrics Server
    if _should_run "metrics-server"; then
        if view_prepare_confirm_step "Metrics Server" "$MSG_PREPARE_WHY_METRICS_TITLE" "$MSG_PREPARE_WHY_METRICS_DESC" "$UNATTENDED"; then
            download_artifact "metrics-server" "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
            
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
                else
                    view_prepare_infra_status "FAIL" "deployment" "metrics-server"
                fi
            else
                view_prepare_step_stop "FAIL"
                PREPARE_ERROR=1
            fi
        fi
    fi

    # 5. MetalLB
    if _should_run "metallb"; then
        if view_prepare_confirm_step "MetalLB" "$MSG_PREPARE_WHY_METALLB_TITLE" "$MSG_PREPARE_WHY_METALLB_DESC" "$UNATTENDED"; then
            view_prepare_step_start "$MSG_PREPARE_STEP_3"
            model_cluster_delete_namespace "metallb-system"
            
            local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
            model_helm_repo_add "metallb" "https://metallb.github.io/metallb"
            
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
                else
                    view_prepare_infra_status "FAIL" "namespace" "metallb-system"
                fi
            else
                view_prepare_step_stop "FAIL"
                local err_msg=$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)
                view_prepare_step_error "${err_msg}..."
                cat "$HELM_ERR" >> "$DEBUG_OUT"
                PREPARE_ERROR=1
            fi
        fi
    fi

    # 6. Ingress-Nginx
    if _should_run "ingress-nginx"; then
        if view_prepare_confirm_step "Ingress-Nginx" "$MSG_PREPARE_WHY_INGRESS_TITLE" "$MSG_PREPARE_WHY_INGRESS_DESC" "$UNATTENDED"; then
            view_prepare_step_start "$MSG_PREPARE_STEP_4"
            model_cluster_delete_namespace "ingress-nginx"
            
            local HELM_ERR="/tmp/kcspoc_helm_err.tmp"
            model_helm_repo_add "ingress-nginx" "https://kubernetes.github.io/ingress-nginx"
            
            if model_helm_upgrade_install "ingress-nginx" "ingress-nginx/ingress-nginx" "ingress-nginx" "300s" "$HELM_ERR"; then
                model_kubectl_label "namespace" "ingress-nginx" "" "$POC_LABEL"
                model_kubectl_label_all "deployment" "ingress-nginx" "$POC_LABEL"
                view_prepare_step_stop "PASS"
                if model_ns_check_label "namespace" "ingress-nginx" "" "$POC_LABEL_KEY" "$POC_LABEL_VAL"; then
                    view_prepare_infra_status "PASS" "namespace" "ingress-nginx"
                else
                    view_prepare_infra_status "FAIL" "namespace" "ingress-nginx"
                fi
            else
                view_prepare_step_stop "FAIL"
                local err_msg=$(cat "$HELM_ERR" | tr '\n' ' ' | cut -c 1-120)
                view_prepare_step_error "${err_msg}..."
                cat "$HELM_ERR" >> "$DEBUG_OUT"
                PREPARE_ERROR=1
            fi
        fi
    fi

    # 7. Kernel Headers
    if _should_run "kernel-headers"; then
        if view_prepare_confirm_step "Kernel Headers" "$MSG_PREPARE_WHY_HEADERS_TITLE" "$MSG_PREPARE_WHY_HEADERS_DESC" "$UNATTENDED"; then
            view_prepare_step_start "$MSG_PREPARE_STEP_5"
            if model_system_install_headers; then
                view_prepare_step_stop "PASS"
            else
                view_prepare_step_stop "FAIL"
                PREPARE_ERROR=1
            fi
        fi
    fi

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

    _should_uninstall() {
        local comp="$1"
        [[ ",$list," == *",$comp,"* ]] && return 0
        return 1
    }

    view_prepare_section "Infrastructure Removal"

    # 1. Ingress-Nginx
    if _should_uninstall "ingress-nginx"; then
        view_prepare_step_start "Removing Ingress-Nginx"
        model_helm_uninstall "ingress-nginx" "ingress-nginx"
        model_kubectl_delete_namespace "ingress-nginx" "false"
        service_exec_wait_and_force_delete_ns "ingress-nginx" 3
        view_prepare_step_stop "PASS"
    fi

    # 2. MetalLB
    if _should_uninstall "metallb"; then
        view_prepare_step_start "Removing MetalLB"
        model_helm_uninstall "metallb" "metallb-system"
        model_kubectl_delete_namespace "metallb-system" "false"
        service_exec_wait_and_force_delete_ns "metallb-system" 3
        view_prepare_step_stop "PASS"
    fi

    # 3. Metrics Server
    if _should_uninstall "metrics-server"; then
        view_prepare_step_start "Removing Metrics Server"
        kubectl delete deployment metrics-server -n kube-system &>> "$DEBUG_OUT" || true
        view_prepare_step_stop "PASS"
    fi

    # 4. Local Path Storage
    if _should_uninstall "local-path-storage"; then
        view_prepare_step_start "Removing Local Path Storage"
        model_helm_uninstall "local-path-storage" "local-path-storage"
        model_kubectl_delete_namespace "local-path-storage" "false"
        service_exec_wait_and_force_delete_ns "local-path-storage" 3
        view_prepare_step_stop "PASS"
    fi

    # 5. Cert-Manager
    if _should_uninstall "cert-manager"; then
        view_prepare_step_start "Removing Cert-Manager"
        model_helm_uninstall "cert-manager" "cert-manager"
        model_kubectl_delete_namespace "cert-manager" "false"
        service_exec_wait_and_force_delete_ns "cert-manager" 3
        view_prepare_step_stop "PASS"
    fi

    # 6. Registry Secret
    if _should_uninstall "registry-auth"; then
        view_prepare_step_start "Removing Registry Secret"
        kubectl delete secret kcs-registry-secret -n "$NAMESPACE" &>> "$DEBUG_OUT" || true
        view_prepare_step_stop "PASS"
    fi

    view_prepare_summary_header
    echo -e "${BRIGHT_GREEN}${ICON_OK} Infrastructure cleanup completed.${NC}"
}
