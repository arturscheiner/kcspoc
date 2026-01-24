#!/bin/bash

# ==============================================================================
# Layer: Model
# File: version_model.sh
# Responsibility: Version information for kcspoc (Dynamic SHA tagging)
# ==============================================================================

VERSION_BASE="0.6.0-dev"

model_version_get() {
    local sha="unknown"

    # 1. Try to read from persisted SHA (if installed)
    if [ -f "${SCRIPT_DIR}/.version_sha" ]; then
        local candidate
        candidate=$(cat "${SCRIPT_DIR}/.version_sha")
        if [[ -n "$candidate" ]] && [[ "$candidate" != "unknown" ]]; then
            sha="$candidate"
        fi
    fi

    # 2. Fallback to Git (if sha is still unknown and in source tree)
    if [[ "$sha" == "unknown" ]] && command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    fi
    
    # Return base + SHA
    echo "${VERSION_BASE}+${sha}"
}
