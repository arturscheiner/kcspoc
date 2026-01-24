# ==============================================================================
# Layer: Facade
# File: common.sh
# Responsibility: Legacy initialization and standard library entrypoint
# ==============================================================================

# --- LOCALE & I18N ---

load_locale() {
    service_locale_load
}

# Call it immediately when common is sourced to ensure messages are available
load_locale

# --- MVC LAYER HELPERS (RETAINED FOR CLI_LOGIC IN KCSPOC.SH) ---

init_logging() {
    service_exec_init_logging "$1" "$VERSION"
}
