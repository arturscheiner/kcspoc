#!/bin/bash

# ==============================================================================
# Layer: Model
# File: helm_model.sh
# Responsibility: Wrapper for Helm CLI operations
# ==============================================================================

model_helm_login() {
    local server="$1"
    local user="$2"
    local pass="$3"
    
    echo "$pass" | helm registry login "$server" --username "$user" --password-stdin 2>&1
}

# The oci:// prefix is specific to the KCS repo in the current implementation
model_helm_pull() {
    local server="$1"
    local version_args="$2" # e.g. "--version 2.3.0"
    local destination="$3"

    helm pull "oci://$server/charts/kcs" $version_args --destination "$destination" 2>&1
}

model_helm_repo_add() {
    local name="$1"
    local url="$2"
    helm repo add "$name" "$url" --force-update &>> "$DEBUG_OUT"
}

model_helm_upgrade_install() {
    local release="$1"
    local chart="$2"
    local ns="$3"
    local timeout="${4:-300s}"
    local err_file="$5"
    shift 5
    # Pass all remaining arguments to helm
    helm upgrade --install "$release" "$chart" \
        --namespace "$ns" --create-namespace \
        --wait --timeout "$timeout" "$@" &> "$err_file"
}

model_helm_upgrade_install_local() {
    local release="$1"
    local chart_path="$2"
    local ns="$3"
    local values_file="$4"
    local val_args=""
    [ -n "$values_file" ] && val_args="-f $values_file"

    helm upgrade --install "$release" "$chart_path" \
        --namespace "$ns" --create-namespace $val_args
}

model_helm_uninstall() {
    local release="$1"
    local ns="$2"
    helm uninstall "$release" -n "$ns" &>> "$DEBUG_OUT"
}

model_helm_status() {
    local release="$1"
    local ns="$2"
    helm status "$release" -n "$ns" &>> "$DEBUG_OUT"
}
