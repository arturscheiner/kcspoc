#!/bin/bash

# ==============================================================================
# Layer: Model
# File: logs_model.sh
# Responsibility: Filesystem access to Log directory and files
# ==============================================================================

model_logs_find_files() {
    local pattern="${1:-$LOGS_DIR}"
    find "$pattern" -name "*.log" 2>/dev/null | sort -r | head -n 10
}

model_logs_find_by_hash() {
    local hash="$1"
    find "$LOGS_DIR" -name "*${hash}.log" | head -n 1
}

model_logs_delete_all() {
    if [ -d "$LOGS_DIR" ]; then
        rm -rf "${LOGS_DIR:?}"/* &>> "$DEBUG_OUT"
        return 0
    fi
    return 1
}

model_logs_has_dir() {
    [ -d "$LOGS_DIR" ]
}

model_logs_has_target_dir() {
    [ -d "$LOGS_DIR/$1" ]
}

model_logs_get_metadata() {
    local log_file="$1"
    local status=$(grep "EXECUTION FINISHED:" "$log_file" | awk '{print $4}')
    local version=$(grep "Version:" "$log_file" | head -n1 | awk '{print $2}')
    echo "${status:-UNKNOWN}|${version:-?}"
}
