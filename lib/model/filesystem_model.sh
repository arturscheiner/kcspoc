#!/bin/bash

# ==============================================================================
# Layer: Model
# File: filesystem_model.sh
# Responsibility: Generic Filesystem and Network operations for artifacts
# ==============================================================================

model_fs_download_artifact() {
    local name="$1"
    local source="$2" # URL or Git Repo
    local dest_dir="$ARTIFACTS_DIR/$name"
    local type="file"
    
    if [[ "$source" == *.git ]]; then
        type="git"
    fi

    [ -d "$ARTIFACTS_DIR" ] || mkdir -p "$ARTIFACTS_DIR"

    if [ ! -d "$dest_dir" ]; then
        service_spinner_start "Downloading $name"
        if [ "$type" == "git" ]; then
            git clone "$source" "$dest_dir" &>> "$DEBUG_OUT"
        else
            mkdir -p "$dest_dir"
            curl -L "$source" -o "$dest_dir/$(basename "$source")" &>> "$DEBUG_OUT"
        fi
        service_spinner_stop "PASS"
    else
        # This is UI, but fits better here as a hint for now to match old behavior
        echo -e "      ${DIM}${ICON_INFO} Using cached artifact: $name${NC}"
    fi
}

model_fs_load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}
