#!/bin/bash

# ==============================================================================
# Layer: Model
# File: state_model.sh
# Responsibility: Manage persistent state of managed components
# ==============================================================================

_STATE_FILE="$ARTIFACTS_DIR/installed-packs.json"

model_state_init() {
    if [ ! -f "$_STATE_FILE" ]; then
        mkdir -p "$(dirname "$_STATE_FILE")"
        echo "[]" > "$_STATE_FILE"
    fi
}

model_state_get_all() {
    model_state_init
    cat "$_STATE_FILE"
}

model_state_record_install() {
    local id="$1"
    local pack_name="$2"
    local context="$3"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    model_state_init
    
    # Remove existing entry for same ID+context to avoid duplicates
    local temp_file="${_STATE_FILE}.tmp"
    jq "del(.[] | select(.id == \"$id\" and .context == \"$context\"))" "$_STATE_FILE" > "$temp_file"
    
    # Append new entry
    jq ". += [{
        \"id\": \"$id\",
        \"name\": \"$pack_name\",
        \"context\": \"$context\",
        \"installed_at\": \"$timestamp\"
    }]" "$temp_file" > "$_STATE_FILE"
    
    rm -f "$temp_file"
}

model_state_record_uninstall() {
    local id="$1"
    local context="$2"

    model_state_init
    
    local temp_file="${_STATE_FILE}.tmp"
    jq "del(.[] | select(.id == \"$id\" and .context == \"$context\"))" "$_STATE_FILE" > "$temp_file"
    mv "$temp_file" "$_STATE_FILE"
}

model_state_get_installed_in_context() {
    local context="$1"
    model_state_get_all | jq -r ".[] | select(.context == \"$context\") | .id"
}
