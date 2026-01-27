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

ai_model_generate() {
    local endpoint="$1"
    local model="$2"
    local prompt="$3"
    
    # Use the generate endpoint for simple completion
    # We use -N to avoid buffering and get the result as a stream of JSON objects
    # but for simplicity in a controller/service, we'll collect it.
    # Note: /api/generate is the correct endpoint for non-chat completion.
    
    local data
    data=$(jq -n \
        --arg model "$model" \
        --arg prompt "$prompt" \
        '{model: $model, prompt: $prompt, stream: false}')
    
    curl -s -f --connect-timeout 60 \
        -X POST "$endpoint/api/generate" \
        -d "$data" | jq -r '.response'
}
