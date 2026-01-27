#!/bin/bash

# ==============================================================================
# Layer: Model
# File: ai_model.sh
# Responsibility: Ollama API interaction and model management
# ==============================================================================

ai_model_check_endpoint() {
    local endpoint="$1"
    # Try to get the version from the endpoint as a health check
    curl -s --connect-timeout 5 "$endpoint/api/tags" &>/dev/null
}

ai_model_list_local() {
    local endpoint="$1"
    # List models from Ollama
    curl -s --connect-timeout 5 "$endpoint/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4
}

ai_model_verify_presence() {
    local endpoint="$1"
    local model="$2"
    
    local found=1
    for m in $(ai_model_list_local "$endpoint"); do
        if [[ "$m" == "$model" ]] || [[ "$m" == "$model:latest" ]] ; then
            found=0
            break
        fi
    done
    return $found
}
