#!/bin/bash

# Visual Identity & Constants (Legacy Facade)
# These are now hosted in lib/view/base_view.sh
# They will be available once base_view.sh is sourced by the main script.


CONFIG_DIR="$HOME/.kcspoc"
CONFIG_FILE="$CONFIG_DIR/config"
ARTIFACTS_DIR="$CONFIG_DIR/artifacts"
LOGS_DIR="$CONFIG_DIR/logs"
VERSION="0.5.5"

# Execution Globals
EXEC_HASH=""
EXEC_LOG_FILE=""
EXEC_CMD=""
EXEC_STATUS="UNKNOWN"

init_logging() {
    local cmd_name="$1"
    EXEC_CMD="$cmd_name"
    
    # Generate random 6-char hash
    EXEC_HASH=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 6 | head -n 1)
    
    # Setup Log Dir
    local cmd_log_dir="$LOGS_DIR/$cmd_name"
    [ -d "$cmd_log_dir" ] || mkdir -p "$cmd_log_dir"

    # Define Log File: YYYYMMDD-HHMMSS-HASH.log
    local timestamp=$(date +'%Y%m%d-%H%M%S')
    EXEC_LOG_FILE="$cmd_log_dir/${timestamp}-${EXEC_HASH}.log"

    # Global Debug Output override
    DEBUG_OUT="$EXEC_LOG_FILE"
    
    # Init Log Header
    {
        echo "--- KCS EXECUTION LOG ---"
        echo "Date: $(date)"
        echo "Command: $cmd_name"
        echo "Hash: $EXEC_HASH"
        echo "Version: $VERSION"
        echo "-------------------------"
    } > "$EXEC_LOG_FILE"
}

save_log_status() {
    local status="$1" # SUCCESS or FAIL
    echo "--- EXECUTION FINISHED: $status ---" >> "$EXEC_LOG_FILE"
}

_update_state() {
    local ns="$1"
    local status="$2"
    local operation="$3"
    local execution_id="$4"
    local config_hash="$5"
    local kcs_ver="$6"
    local status_progress="${7:-0}"

    # Only attempt if namespace exists
    if kubectl get ns "$ns" &>/dev/null; then
        kubectl label ns "$ns" \
          "kcspoc.io/managed-by=kcspoc" \
          "kcspoc.io/status=$status" \
          "kcspoc.io/last-operation=$operation" \
          "kcspoc.io/execution-id=$execution_id" \
          "kcspoc.io/config-hash=$config_hash" \
          "kcspoc.io/kcs-version=$kcs_ver" \
          "kcspoc.io/status-progress=$status_progress" --overwrite &>> "$DEBUG_OUT"
    fi
}


# Helper: MD5 Hashing
get_config_hash() {
    # Generate a unique hash of sensitive local configuration values
    # These values are critical for data encryption and system stability.
    if [ -n "$APP_SECRET" ]; then
        echo -n "${APP_SECRET}${POSTGRES_PASSWORD}${MINIO_ROOT_PASSWORD}${CLICKHOUSE_ADMIN_PASSWORD}" | md5sum | awk '{print $1}'
    else
        echo "none"
    fi
}

# Debugging Defaults
DEBUG_OUT="/dev/null"
KCS_DEBUG=false

setup_debug() {
    local cmd_name="$1"
    if [ "$KCS_DEBUG" = true ]; then
        [ -d "$CONFIG_DIR" ] || mkdir -p "$CONFIG_DIR"
        DEBUG_OUT="$CONFIG_DIR/debug-${cmd_name}.log"
        echo "--- KCS DEBUG START: $(date) ---" > "$DEBUG_OUT"
        echo "Command: $cmd_name" >> "$DEBUG_OUT"
        echo "--------------------------------" >> "$DEBUG_OUT"
    fi
}

# --- LOCALE & I18N ---
load_locale() {
    # 1. Try Configured Language
    local CFG_LANG=""
    if [ -f "$CONFIG_FILE" ]; then
        # Extract PREFERRED_LANG safely without sourcing entire file if we want to be strict,
        # but sourcing is standard for this tool.
        # We'll detect it by grep to not accidentally overwrite other vars if called early?
        # Actually, just sourcing is easiest/safest given we control the file format.
        # However, let's just grep it to avoid side effects during early init.
        CFG_LANG=$(grep "^PREFERRED_LANG=" "$CONFIG_FILE" | cut -d'"' -f2)
    fi

    # 2. Detect System Language (Fallback)
    # Priorities: Config > LC_ALL > LC_MESSAGES > LANG
    local SYS_LANG="${CFG_LANG:-${LC_ALL:-${LC_MESSAGES:-$LANG}}}"
    
    # Extract language code (e.g., pt_BR, en_US)
    local LANG_CODE=$(echo "$SYS_LANG" | cut -d. -f1)
    
    # Default to en_US if empty
    if [ -z "$LANG_CODE" ]; then
        LANG_CODE="en_US"
    fi
    
    # Check if we have a file for this locale
    local LOCALE_FILE="$SCRIPT_DIR/locales/${LANG_CODE}.sh"
    
    # If not found, try generic language check (e.g. pt_PT -> pt_BR mapping if needed, or default)
    # For now, if exact match fails, fallback to en_US
    if [ ! -f "$LOCALE_FILE" ]; then
        LOCALE_FILE="$SCRIPT_DIR/locales/en_US.sh"
    fi
    
    # Load it
    if [ -f "$LOCALE_FILE" ]; then
        source "$LOCALE_FILE"
    else
        # Critical Fallback if en_US is missing (should not happen in dist)
        echo "Error: Locale file not found and en_US fallback missing."
        exit 1
    fi
}
# Call it immediately when common is sourced
load_locale

# --- HELPER FUNCTIONS ---

ui_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}


ui_section() {
    view_ui_section "$1"
}


ui_step() {
    view_ui_step "$1" "$2" "$3" "$4"
}


ui_input() {
    view_ui_input "$1" "$2" "$3" "$4"
}


# --- UI SPINNER ---

_SPINNER_PID=0

# Ensure spinner is killed on script exit
# Ensure spinner is killed on script exit
_ui_spinner_cleanup() {
    local exit_code=$?
    
    # 1. Spinner Cleanup
    if [ "$_SPINNER_PID" -ne 0 ]; then
        kill "$_SPINNER_PID" &>/dev/null || true
        wait "$_SPINNER_PID" &>/dev/null || true
        _SPINNER_PID=0
        view_ui_spinner_cleanup "$exit_code"
    fi

    # 2. Log Finalization (If logging was active)
    if [ -n "$EXEC_LOG_FILE" ]; then
        local status="SUCCESS"
        [ $exit_code -ne 0 ] && status="FAIL"
        
        save_log_status "$status"
        view_ui_log_info "$EXEC_HASH"
    fi
}

trap _ui_spinner_cleanup EXIT

ui_spinner_start() {
    view_ui_spinner_start "$1"
    
    (
        local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        while true; do
            for frame in "${frames[@]}"; do
                echo -ne "${CYAN}${frame}${NC}"
                sleep 0.1
                echo -ne "\b"
            done
        done
    ) &
    _SPINNER_PID=$!
}


ui_spinner_stop() {
    view_ui_spinner_stop "$1"
    _SPINNER_PID=0
}


check_k8s_label() {
    local res_type="$1"
    local res_name="$2"
    local ns="$3"
    local label_desc="Checking Label ($POC_LABEL_KEY=$POC_LABEL_VAL)"
    
    # Construct kubectl args
    local args=("$res_type" "$res_name" "--show-labels")
    if [ -n "$ns" ]; then
        args+=("-n" "$ns")
    fi
    
    echo -ne "      ${ICON_GEAR} $label_desc... "
    # We don't use the spinner here because it's a quick check usually, 
    # and we want it indented.
    
    if kubectl get "${args[@]}" 2>> "$DEBUG_OUT" | grep -q "$POC_LABEL_KEY=$POC_LABEL_VAL"; then
        echo -e "[ ${GREEN}${ICON_OK}${NC} ]"
        return 0
    else
        echo -e "[ ${RED}${ICON_FAIL}${NC} ]"
        return 1
    fi
}

download_artifact() {
    local name="$1"
    local source="$2" # URL or Git Repo
    local dest_dir="$ARTIFACTS_DIR/$name"
    local type="file"
    
    if [[ "$source" == *.git ]]; then
        type="git"
    fi

    [ -d "$ARTIFACTS_DIR" ] || mkdir -p "$ARTIFACTS_DIR"

    if [ ! -d "$dest_dir" ]; then
        ui_spinner_start "Downloading $name"
        if [ "$type" == "git" ]; then
            git clone "$source" "$dest_dir" &>> "$DEBUG_OUT"
        else
            mkdir -p "$dest_dir"
            curl -L "$source" -o "$dest_dir/$(basename "$source")" &>> "$DEBUG_OUT"
        fi
        ui_spinner_stop "PASS"
    else
        echo -e "      ${DIM}${ICON_INFO} Using cached artifact: $name${NC}"
    fi
}

force_delete_ns() {
    local ns="$1"
    local status=$(kubectl get namespace "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    
    if [ "$status" == "Terminating" ]; then
        echo -e "[ $(date) ] Forcing deletion of namespace: $ns" >> "$DEBUG_OUT"
        kubectl get namespace "$ns" -o json 2>>"$DEBUG_OUT" | jq 'del(.spec.finalizers)' 2>>"$DEBUG_OUT" | kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f - &>> "$DEBUG_OUT"
        sleep 2
    fi
}

wait_and_force_delete_ns() {
    local ns="$1"
    local timeout=${2:-5}
    
    # Wait up to 'timeout' seconds for normal deletion
    for i in $(seq 1 $timeout); do
        local status=$(kubectl get namespace "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
        if [ "$status" == "NotFound" ]; then
            return 0
        fi
        sleep 1
    done
    
    # If still there (likely Terminating), force it
    force_delete_ns "$ns"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

ui_help() {
    view_ui_help "$1" "$2" "$3" "$4" "$VERSION"
}

