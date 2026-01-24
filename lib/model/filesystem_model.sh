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

model_fs_list_artifact_versions() {
    local base_path="$1"
    if [ -d "$base_path" ]; then
        ls -F "$base_path" 2>/dev/null | grep "/" | sed 's|/||g' | sort -V
    fi
}

model_fs_save_download_metadata() {
    local path="$1"
    date +'%Y-%m-%d %H:%M' > "$path/.downloaded"
}

model_fs_move_artifact() {
    local src="$1"
    local dest="$2"
    mv "$src" "$dest"
}

model_fs_fetch_remote_file() {
    local url="$1"
    local dest="$2"
    curl -sSf "$url" -o "$dest" &>> "$DEBUG_OUT"
}

model_fs_update_config_version() {
    local ver="$1"
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s|KCS_VERSION=.*|KCS_VERSION=\"$ver\"|g" "$CONFIG_FILE"
        return 0
    fi
    return 1
}
