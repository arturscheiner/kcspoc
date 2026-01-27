#!/bin/bash

# ==============================================================================
# Layer: Model
# File: ai_model.sh
# Responsibility: Ollama API interaction and model management
# ==============================================================================

ai_model_check_endpoint() {
    local endpoint="$1"
    
    if ! command -v curl &>/dev/null; then
        return 127 # Curl missing
    fi
    
    # Check if endpoint is reachable and returns a success code
    # /api/tags should return 200 OK and contain "models"
    local response
    response=$(curl -s -f --connect-timeout 5 "$endpoint/api/tags" 2>/dev/null)
    local status=$?
    
    if [ $status -ne 0 ]; then
        return 1 # Connectivity/HTTP error
    fi
    
    [[ "$response" == *"models"* ]]
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
