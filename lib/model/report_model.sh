#!/bin/bash

# ==============================================================================
# Layer: Model
# File: report_model.sh
# Responsibility: Management of generated reports storage (~/.kcspoc/reports)
# ==============================================================================

REPORTS_BASE_DIR="$CONFIG_DIR/reports"

model_report_init() {
    [ -d "$REPORTS_BASE_DIR" ] || mkdir -p "$REPORTS_BASE_DIR"
}

# Saves a report artifact
# Usage: model_report_save <command> <hash> <content_file> [suffix]
model_report_save() {
    local cmd="$1"
    local hash="$2"
    local src_file="$3"
    local suffix="${4:-txt}"
    
    local cmd_dir="$REPORTS_BASE_DIR/$cmd"
    [ -d "$cmd_dir" ] || mkdir -p "$cmd_dir"
    
    local report_file="$cmd_dir/${hash}.${suffix}"
    cp "$src_file" "$report_file"
    
    # Optional: Log the report in a central index for faster --list
    _model_report_index_add "$cmd" "$hash" "$suffix"
}

# Internal helper to maintain a metadata index
_model_report_index_add() {
    local cmd="$1"
    local hash="$2"
    local suffix="$3"
    local index_file="$REPORTS_BASE_DIR/index.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    [ -f "$index_file" ] || echo "[]" > "$index_file"
    
    local temp_file="${index_file}.tmp"
    jq ". += [{
        \"hash\": \"$hash\",
        \"command\": \"$cmd\",
        \"timestamp\": \"$timestamp\",
        \"extension\": \"$suffix\"
    }]" "$index_file" > "$temp_file"
    mv "$temp_file" "$index_file"
}

model_report_get_index() {
    local index_file="$REPORTS_BASE_DIR/index.json"
    if [ -f "$index_file" ]; then
        cat "$index_file"
    else
        echo "[]"
    fi
}
