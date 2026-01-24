#!/bin/bash

# ==============================================================================
# Layer: Model
# File: config_model.sh
# Responsibility: Configuration data and hashing
# ==============================================================================

model_config_get_hash() {
    local app_secret="$1"
    local pg_pass="$2"
    local minio_pass="$3"
    local ch_admin_pass="$4"

    if [ -n "$app_secret" ]; then
        echo -n "${app_secret}${pg_pass}${minio_pass}${ch_admin_pass}" | md5sum | awk '{print $1}'
    else
        echo "none"
    fi
}
