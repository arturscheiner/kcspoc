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

model_kubectl_get_current_context() {
    kubectl config current-context 2>/dev/null || echo "unknown-cluster"
}

model_kubectl_delete_namespace() {
    local ns="$1"
    local timeout="${2:-120s}"
    kubectl delete namespace "$ns" --timeout="$timeout" &>> "$DEBUG_OUT"
}

model_kubectl_delete_pvc_all() {
    local ns="$1"
    local timeout="${2:-60s}"
    kubectl delete pvc --all -n "$ns" --timeout="$timeout" &>> "$DEBUG_OUT"
}

model_kubectl_delete_certificate_all() {
    local ns="$1"
    local timeout="${2:-30s}"
    kubectl delete certificate --all -n "$ns" --timeout="$timeout" &>> "$DEBUG_OUT"
}

model_kubectl_get_pv_by_ns() {
    local ns="$1"
    kubectl get pv -o json 2>> "$DEBUG_OUT" | jq -r ".items[] | select(.spec.claimRef.namespace==\"$ns\") | .metadata.name"
}

model_kubectl_delete_pv() {
    local name="$1"
    local timeout="${2:-30s}"
    kubectl delete pv "$name" --timeout="$timeout" &>> "$DEBUG_OUT"
}

model_kubectl_delete_webhook() {
    local type="$1" # validating or mutating
    local name="$2"
    kubectl delete "${type}webhookconfiguration" "$name" --ignore-not-found &>> "$DEBUG_OUT"
}

model_kubectl_delete_clusterrole() {
    local names="$1"
    kubectl delete clusterrole $names --ignore-not-found &>> "$DEBUG_OUT"
}

model_kubectl_delete_clusterrolebinding() {
    local names="$1"
    kubectl delete clusterrolebinding $names --ignore-not-found &>> "$DEBUG_OUT"
}

model_kubectl_delete_orphaned_secrets() {
    local ns_arg="$1" # "-A" or "-n ns"
    local pattern="$2"
    local ORPHANED_SECRETS=$(kubectl get secrets $ns_arg --no-headers 2>> "$DEBUG_OUT" | grep "$pattern" | awk '{print $2 " -n " $1}')
    if [ -n "$ORPHANED_SECRETS" ]; then
        echo "$ORPHANED_SECRETS" | xargs -I {} bash -c 'kubectl delete secret {} &>> /dev/null'
    fi
}
