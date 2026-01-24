#!/bin/bash

# ==============================================================================
# Layer: Model
# File: version_model.sh
# Responsibility: Version information for kcspoc (Dynamic SHA tagging)
# ==============================================================================

VERSION_BASE="0.6.0-dev"

model_version_get() {
    local sha="unknown"
    # Try to get short SHA if inside a git repo
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    fi
    
    # Return base + SHA
    echo "${VERSION_BASE}+${sha}"
}
