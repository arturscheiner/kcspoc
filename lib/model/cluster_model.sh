#!/bin/bash

# ==============================================================================
# Layer: Model
# File: cluster_model.sh
# Responsibility: Kubernetes Cluster information (Version, Runtime, Provider)
# ==============================================================================

model_cluster_get_current_context() {
    kubectl config current-context 2>/dev/null || echo "None"
}

model_cluster_verify_connectivity() {
    local err_file="$1"
    kubectl get nodes &> "$err_file"
}

model_cluster_get_version() {
    local ver
    ver=$(kubectl version -o json 2>/dev/null | grep gitVersion | grep -v Client | head -n 1 | awk -F'"' '{print $4}')
    if [ -z "$ver" ]; then
        ver=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}')
    fi
    echo "$ver"
}

model_cluster_get_architectures() {
    kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' | tr ' ' '\n' | sort | uniq -c
}

model_cluster_get_runtimes() {
    kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}' | tr ' ' '\n' | sort | uniq
}

# Returns: prov_id|region|zone|os_image
model_cluster_get_raw_provider_data() {
    kubectl get nodes -o jsonpath='{.items[0].spec.providerID}|{.items[0].metadata.labels.topology\.kubernetes\.io/region}|{.items[0].metadata.labels.topology\.kubernetes\.io/zone}|{.items[0].status.nodeInfo.osImage}' 2>/dev/null
}

model_cluster_get_cni_pods() {
    kubectl get pods -A --no-headers | grep -E "calico|flannel|cilium|weave|antrea|kube-proxy" | grep "Running" || true
}

model_cluster_get_infrastructure_status() {
    local type="$1"
    local name="$2"
    local ns="$3"
    
    if [ "$type" == "namespace" ]; then
        kubectl get ns "$name" &>/dev/null
    elif [ "$type" == "deployment" ]; then
        kubectl get deployment "$name" -n "$ns" &>/dev/null
    fi
}

model_cluster_create_namespace() {
    local ns="$1"
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT"
}

model_cluster_delete_namespace() {
    local ns="$1"
    local wait="${2:-false}"
    kubectl delete namespace "$ns" --wait="$wait" &>> "$DEBUG_OUT"
}
