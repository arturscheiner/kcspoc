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

ai_service_generate_audit_report() {
    local facts_json="$1"
    local endpoint="$2"
    local model="$3"
    local report_hash="$4"
    
    local prompt_file="$SCRIPT_DIR/lib/model/ai/prompts/readiness_checklist.md"
    local schema_file="$SCRIPT_DIR/lib/model/ai/schemas/readiness_audit_json.md"
    
    if [ ! -f "$prompt_file" ] || [ ! -f "$schema_file" ]; then
        return 1
    fi
    
    local base_prompt=$(cat "$prompt_file")
    local schema_instructions=$(cat "$schema_file")
    
    # Combine Logic (Prompt) with Formatting (JSON Schema)
    local full_prompt="
$base_prompt

---
## MANDATORY OUTPUT FORMAT (JSON ONLY)
$schema_instructions

---
## INPUT DATA (CLUSTER FACTS)
$facts_json
"
    
    # Call Model Layer
    local raw_response=$(ai_model_generate "$endpoint" "$model" "$full_prompt")
    
    # Extract JSON block using line range (first { to last })
    # 1. Strip potential Markdown code blocks first
    local stripped=$(echo "$raw_response" | sed 's/```json//g; s/```//g')
    
    # 2. Find line numbers of the outermost braces
    local first_line=$(echo "$stripped" | grep -n "{" | head -n 1 | cut -d: -f1)
    local last_line=$(echo "$stripped" | grep -n "}" | tail -n 1 | cut -d: -f1)
    
    if [ -z "$first_line" ] || [ -z "$last_line" ]; then
        [ -n "$DEBUG_OUT" ] && echo "Error: No JSON braces found in AI response" >&2
        return 1
    fi
    
    local clean_json=$(echo "$stripped" | sed -n "${first_line},${last_line}p")
    
    # Sanitize: Remove any hallucinated template placeholders from the AI content
    clean_json=$(echo "$clean_json" | sed 's/\[\[[^]]*\]\]//g')
    
    # Validate JSON structure using jq
    if ! echo "$clean_json" | jq empty &>/dev/null; then
        [ -n "$DEBUG_OUT" ] && echo "Error: AI produced invalid JSON" >&2
        # Fallback: try to see if just stripping everything except the object works
        clean_json=$(echo "$clean_json" | jq -c '.' 2>/dev/null) || return 1
    fi
    
    echo "$clean_json"
}
