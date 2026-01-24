#!/bin/bash

# ==============================================================================
# Layer: Model
# File: config_model.sh
# Responsibility: Configuration data and hashing
# ==============================================================================

model_config_get_hash() {
    # Decoupled from facade arguments; use global secrets directly
    if [ -n "$APP_SECRET" ]; then
        echo -n "${APP_SECRET}${POSTGRES_PASSWORD}${MINIO_ROOT_PASSWORD}${CLICKHOUSE_ADMIN_PASSWORD}" | md5sum | awk '{print $1}'
    else
        echo "none"
    fi
}

model_config_set_api_token() {
    local token="$1"
    if [ -f "$CONFIG_FILE" ]; then
        # Remove existing token if present
        sed -i '/^ADMIN_API_TOKEN=/d' "$CONFIG_FILE"
        # Append new token
        echo "ADMIN_API_TOKEN=\"$token\"" >> "$CONFIG_FILE"
        return 0
    fi
    return 1
}
