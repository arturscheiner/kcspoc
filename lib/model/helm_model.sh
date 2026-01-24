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
