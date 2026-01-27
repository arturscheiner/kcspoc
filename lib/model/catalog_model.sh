#!/bin/bash

# ==============================================================================
# Layer: Model
# File: catalog_model.sh
# Responsibility: Fetch and parse the extra-packs catalog (online/local)
# ==============================================================================

_CATALOG_REMOTE_URL="https://raw.githubusercontent.com/arturscheiner/kcspoc/main/.extra-packs.json"
_CATALOG_LOCAL_CACHE="$CONFIG_DIR/.extra-packs.json"

model_catalog_fetch_remote() {
    # If we are in the source tree, use the local file as source for faster dev
    if [ -f "$SCRIPT_DIR//.extra-packs.json" ] && [ "$KCS_DEBUG" == "true" ]; then
        cp "$SCRIPT_DIR//.extra-packs.json" "$_CATALOG_LOCAL_CACHE"
        return 0
    fi

    # Otherwise, fetch from remote
    if curl -sSf "$_CATALOG_REMOTE_URL" -o "$_CATALOG_LOCAL_CACHE" &>> "$DEBUG_OUT"; then
        return 0
    fi
    
    return 1
}

model_catalog_get_list() {
    if [ ! -f "$_CATALOG_LOCAL_CACHE" ]; then
        # Try one last fetch
        model_catalog_fetch_remote || return 1
    fi
    
    cat "$_CATALOG_LOCAL_CACHE"
}

model_catalog_get_pack_ids() {
    model_catalog_get_list | jq -r '.[].id'
}

model_catalog_get_pack_by_id() {
    local id="$1"
    model_catalog_get_list | jq -r ".[] | select(.id == \"$id\")"
}
