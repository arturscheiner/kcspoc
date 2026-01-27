#!/bin/bash

# ==============================================================================
# Layer: Service
# File: ai_service.sh
# Responsibility: Orchestration of AI capabilities and report generation
# ==============================================================================

ai_service_generate_log_report() {
    local log_hash="$1"
    local log_content="$2"
    local endpoint="$3"
    local model="$4"
    
    local schema_file="$SCRIPT_DIR/lib/model/ai/schemas/log_report.md"
    if [ ! -f "$schema_file" ]; then
        return 1
    fi
    
    local base_instructions=$(cat "$schema_file")
    
    local full_prompt="
$base_instructions

---
## RAW LOG CONTENT TO ANALYZE
$log_content
"

    # Call Model Layer
    ai_model_generate "$endpoint" "$model" "$full_prompt"
}
