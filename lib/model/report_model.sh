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

model_report_generate_hash() {
    cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 6 | head -n 1
}

# Saves a report artifact
# Usage: model_report_save <command> <hash> <content_file> [suffix] [type] [ai_model] [orig_log_id] [orig_exec_id]
model_report_save() {
    local cmd="$1"
    local hash="$2"
    local src_file="$3"
    local suffix="${4:-txt}"
    local type="${5:-template}"
    local ai_model="${6:-}"
    local orig_log_id="${7:-}"
    local orig_exec_id="${8:-}"
    
    local cmd_dir="$REPORTS_BASE_DIR/$cmd"
    [ -d "$cmd_dir" ] || mkdir -p "$cmd_dir"
    
    local report_file="$cmd_dir/${hash}.${suffix}"
    
    # Prepend AI metadata if it's an AI report
    if [ "$type" == "ai" ]; then
        {
            echo "<!-- origin: ai | model: ${ai_model:-?} | log_id: ${orig_log_id:-?} | exec_id: ${orig_exec_id:-?} | report_id: $hash -->"
            echo ""
        } > "$report_file"
        cat "$src_file" >> "$report_file"
    else
        cp "$src_file" "$report_file"
    fi
    
    # Update index
    _model_report_index_add "$cmd" "$hash" "$suffix" "$type" "$ai_model" "$orig_log_id" "$orig_exec_id"
}

# Internal helper to maintain a metadata index
_model_report_index_add() {
    local cmd="$1"
    local hash="$2"
    local suffix="$3"
    local type="$4"
    local ai_model="$5"
    local orig_log_id="$6"
    local orig_exec_id="$7"
    local index_file="$REPORTS_BASE_DIR/index.json"
    local timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
    
    [ -f "$index_file" ] || echo "[]" > "$index_file"
    
    local temp_file="${index_file}.tmp"
    jq ". += [{
        \"hash\": \"$hash\",
        \"command\": \"$cmd\",
        \"timestamp\": \"$timestamp\",
        \"extension\": \"$suffix\",
        \"type\": \"$type\",
        \"ai_model\": \"$ai_model\",
        \"orig_log_id\": \"$orig_log_id\",
        \"orig_exec_id\": \"$orig_exec_id\"
    }]" "$index_file" > "$temp_file"
    mv "$temp_file" "$index_file"
}

model_report_find_by_hash() {
    local hash="$1"
    local index=$(model_report_get_index)
    # Select all matching entries, and pick the last one (most recent)
    local entry=$(echo "$index" | jq -c "map(select(.hash == \"$hash\")) | last")
    
    if [ "$entry" != "null" ] && [ -n "$entry" ]; then
        local cmd=$(echo "$entry" | jq -r '.command')
        local ext=$(echo "$entry" | jq -r '.extension')
        echo "$REPORTS_BASE_DIR/$cmd/${hash}.${ext}"
    else
        echo ""
    fi
}

model_report_get_index() {
    local index_file="$REPORTS_BASE_DIR/index.json"
    if [ -f "$index_file" ]; then
        cat "$index_file"
    else
        echo "[]"
    fi
}

model_report_delete() {
    local cmd_filter="$1" # Optional
    local index_file="$REPORTS_BASE_DIR/index.json"
    
    if [ -z "$cmd_filter" ]; then
        # Delete everything
        rm -rf "${REPORTS_BASE_DIR:?}"/* &>/dev/null
        echo "[]" > "$index_file"
    else
        # Delete specific command directory
        rm -rf "$REPORTS_BASE_DIR/$cmd_filter" &>/dev/null
        
        # Filter index
        if [ -f "$index_file" ]; then
            local temp_file="${index_file}.tmp"
            jq "map(select(.command != \"$cmd_filter\"))" "$index_file" > "$temp_file"
            mv "$temp_file" "$index_file"
        fi
    fi
}

model_report_export() {
    local src_file="$1"
    local dest_path="$2"
    
    # Ensure parent directory exists
    local dest_dir=$(dirname "$dest_path")
    [ -d "$dest_dir" ] || mkdir -p "$dest_dir"
    
    cp "$src_file" "$dest_path"
}
