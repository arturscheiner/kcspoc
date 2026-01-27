#!/bin/bash

# ==============================================================================
# Layer: Service
# File: ai_service.sh
# Responsibility: Orchestration of AI capabilities and report generation
# ==============================================================================

ai_service_generate_log_report() {
    local log_id="$1"
    local log_content="$2"
    local endpoint="$3"
    local model="$4"
    local report_hash="$5"
    local parent_exec_id="$6"
    
    local schema_file="$SCRIPT_DIR/lib/model/ai/schemas/log_report.md"
    if [ ! -f "$schema_file" ]; then
        return 1
    fi
    
    local base_instructions=$(cat "$schema_file")
    
    # Pre-process instructions with actual context metadata
    local full_prompt="
$base_instructions

---
## METADATA FOR YOUR REPORT
- Report ID: $report_hash
- Log ID: $log_id
- Parent Execution ID: $parent_exec_id

---
## RAW LOG CONTENT TO ANALYZE
$log_content
"

    # Call Model Layer
    ai_model_generate "$endpoint" "$model" "$full_prompt"
}
