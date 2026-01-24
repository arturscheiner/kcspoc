#!/bin/bash

# ==============================================================================
# Layer: Model
# File: kubeconfig_model.sh
# Responsibility: Filesystem and Cluster State for Configuration
# ==============================================================================

kubeconfig_load() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

kubeconfig_save() {
    local content="$1"
    mkdir -p "$CONFIG_DIR"
    echo "$content" > "$CONFIG_FILE"
}

kubeconfig_update_version() {
    local version="$1"
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s|KCS_VERSION=.*|KCS_VERSION=\"$version\"|g" "$CONFIG_FILE"
        return 0
    fi
    return 1
}

kubeconfig_get_suggested_cri() {
    local current_cri="$1"
    if [ -n "$current_cri" ]; then
        echo "$current_cri"
        return
    fi

    local rt_ver
    rt_ver=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}' 2>/dev/null)
    
    if [[ "$rt_ver" == *"containerd"* ]]; then
        echo "/run/containerd/containerd.sock"
    elif [[ "$rt_ver" == *"cri-o"* ]]; then
        echo "/run/crio/crio.sock"
    elif [[ "$rt_ver" == *"docker"* ]]; then
        echo "/var/run/cri-dockerd.sock"
    else
        echo ""
    fi
}
