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
