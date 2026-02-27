#!/bin/bash

# ==============================================================================
# Layer: Model
# File: base_model.sh
# Responsibility: Data, System, and Cluster Abstraction
# ==============================================================================

# --- Global Configuration Paths ---
export CONFIG_DIR="$HOME/.kcspoc"
export CONFIG_FILE="$CONFIG_DIR/config"
export ARTIFACTS_DIR="$CONFIG_DIR/artifacts"
export LOGS_DIR="$CONFIG_DIR/logs"

# --- Global Execution State ---
export EXEC_HASH=""
export EXEC_LOG_FILE=""
export EXEC_CMD=""
export EXEC_STATUS="UNKNOWN"
export DEBUG_OUT="/dev/null"
export KCS_DEBUG=false

# --- PoC Labels ---
export POC_LABEL_KEY="kcspoc.io/managed-by"
export POC_LABEL_VAL="kcspoc"
export POC_LABEL="${POC_LABEL_KEY}=${POC_LABEL_VAL}"

# --- Extras Labels ---
export EXTRAS_LABEL_KEY="kcspoc.io/component"
export EXTRAS_LABEL_VAL="extras"
export EXTRAS_LABEL="${EXTRAS_LABEL_KEY}=${EXTRAS_LABEL_VAL}"
