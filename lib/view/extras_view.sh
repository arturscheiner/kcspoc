#!/bin/bash

# ==============================================================================
# Layer: View
# File: extras_view.sh
# Responsibility: UI and Output for Extras Command
# ==============================================================================

view_extras_banner() {
    view_ui_banner "$VERSION" "$EXEC_HASH"
}

view_extras_catalog_header() {
    view_ui_section_header "Extras: Available Component Catalog"
    echo -e "   Showing online extra-packs available for installation.\n"
}

view_extras_catalog_table_header() {
    view_ui_table_header \
        "ID:20" \
        "Name:25" \
        "Description:50"
}

view_extras_catalog_item() {
    local id="$1"
    local name="$2"
    local desc="$3"

    view_ui_table_row \
        "${BRIGHT_CYAN}${id}${NC}:20" \
        "${BOLD}${name}${NC}:25" \
        "${DIM}${desc}${NC}:50"
}

view_extras_catalog_footer() {
    echo ""
    view_ui_line
    echo -e "   ${DIM}To install a pack, run: ${NC}kcspoc extras --install <id>\n"
}

view_extras_install_start() {
    local pack="$1"
    view_ui_section_header "Installing Extra-Pack: $pack"
}

view_extras_uninstall_start() {
    local pack="$1"
    view_ui_section_header "Removing Extra-Pack: $pack"
}
