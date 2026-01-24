#!/bin/bash

# ==============================================================================
# Layer: Service
# File: locale_service.sh
# Responsibility: Locale detection and loading logic
# ==============================================================================

service_locale_load() {
    # 1. Try Configured Language
    local CFG_LANG=""
    if [ -f "$CONFIG_FILE" ]; then
        CFG_LANG=$(grep "^PREFERRED_LANG=" "$CONFIG_FILE" | cut -d'"' -f2)
    fi

    # 2. Detect System Language (Fallback)
    local SYS_LANG="${CFG_LANG:-${LC_ALL:-${LC_MESSAGES:-$LANG}}}"
    
    # Extract language code (e.g., pt_BR, en_US)
    local LANG_CODE
    LANG_CODE=$(echo "$SYS_LANG" | cut -d. -f1)
    
    # Default to en_US if empty
    if [ -z "$LANG_CODE" ]; then
        LANG_CODE="en_US"
    fi
    
    # Check if we have a file for this locale
    local LOCALE_FILE="$SCRIPT_DIR/locales/${LANG_CODE}.sh"
    
    # If not found, fallback to en_US
    if [ ! -f "$LOCALE_FILE" ]; then
        LOCALE_FILE="$SCRIPT_DIR/locales/en_US.sh"
    fi
    
    # Load it
    if [ -f "$LOCALE_FILE" ]; then
        source "$LOCALE_FILE"
    else
        echo "Error: Locale file not found and en_US fallback missing."
        exit 1
    fi
}
