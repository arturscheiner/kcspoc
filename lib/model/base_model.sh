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
