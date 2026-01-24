#!/bin/bash

# ==============================================================================
# Layer: Model
# File: kubectl_model.sh
# Responsibility: Wrapper for Kubectl CLI operations
# ==============================================================================

model_kubectl_create_namespace() {
    local ns="$1"
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT"
}

model_kubectl_create_docker_secret() {
    local name="$1"
    local ns="$2"
    local server="$3"
    local user="$4"
    local pass="$5"
    
    kubectl create secret docker-registry "$name" \
        --docker-server="$server" \
        --docker-username="$user" \
        --docker-password="$pass" \
        -n "$ns" --dry-run=client -o yaml | kubectl apply -f - &>> "$DEBUG_OUT"
}

model_kubectl_label() {
    local type="$1"
    local name="$2"
    local ns="$3"
    local label_pair="$4"
    
    if [ -n "$ns" ]; then
        kubectl label "$type" "$name" -n "$ns" $label_pair --overwrite &>> "$DEBUG_OUT"
    else
        kubectl label "$type" "$name" $label_pair --overwrite &>> "$DEBUG_OUT"
    fi
}

model_kubectl_label_all() {
    local type="$1"
    local ns="$2"
    local label_pair="$3"
    kubectl label "$type" -n "$ns" --all $label_pair --overwrite &>> "$DEBUG_OUT"
}

model_kubectl_patch_storageclass() {
    local sc_name="$1"
    local patch="$2"
    kubectl patch storageclass "$sc_name" -p "$patch" &>> "$DEBUG_OUT"
}

model_kubectl_apply_file() {
    local file_path="$1"
    local ns="$2"
    if [ -n "$ns" ]; then
        kubectl apply -f "$file_path" -n "$ns" &>> "$DEBUG_OUT"
    else
        kubectl apply -f "$file_path" &>> "$DEBUG_OUT"
    fi
}

model_kubectl_patch_deployment() {
    local name="$1"
    local ns="$2"
    local type="$3"
    local patch="$4"
    kubectl patch deployment "$name" -n "$ns" --type="$type" -p="$patch" &>> "$DEBUG_OUT"
}

model_kubectl_apply_stdin() {
    kubectl apply -f - &>> "$DEBUG_OUT"
}

model_kubectl_get_ingress_ip() {
    kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>> "$DEBUG_OUT" || echo "Pending..."
}
