#!/bin/bash

# ==============================================================================
# Script: kcspoc.sh
# Description: CLI tool for Kaspersky Container Security PoC management.
#              Provides interactive configuration, environment checking, and preparation.
# Environment: Linux (Ubuntu/Debian preferred), K8s
# ==============================================================================

# Resolve Script Directory to find libs (Handles Symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
LIB_DIR="$SCRIPT_DIR/lib"

# Check lib existence
if [ ! -d "$LIB_DIR" ]; then
    echo "Error: Library directory not found at $LIB_DIR"
    exit 1
fi

# Source MVC Components (v0.6.0+)
for layer in model view service control; do
    if [ -d "$LIB_DIR/$layer" ]; then
        for component in "$LIB_DIR/$layer"/*.sh; do
            [ -f "$component" ] && source "$component"
        done
    fi
done

# Initialize Infrastructure (v0.6.0+)
VERSION=$(model_version_get)
service_locale_load
service_exec_register_traps

# Hand off to Base Controller
base_controller_dispatch "$@"
