#!/bin/bash

# ==============================================================================
# Layer: Model
# File: network_model.sh
# Responsibility: Network connectivity checks (External Repo)
# ==============================================================================

model_network_verify_repo_connectivity() {
    local ns="$1"
    local url="${2:-https://repo.kcs.kaspersky.com}"
    
    kubectl run -i --rm --image=curlimages/curl --restart=Never kcspoc-repo-connectivity-test -n "$ns" -- curl -m 5 -I "$url" &>> "$DEBUG_OUT"
}
