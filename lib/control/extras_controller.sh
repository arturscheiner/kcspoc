#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: extras_controller.sh
# Responsibility: Argument parsing and orchestration for Extras Hub
# ==============================================================================

extras_controller() {
    local list=false
    local install_pack=""
    local uninstall_pack=""
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --list)
                list=true
                ;;
            --install)
                install_pack="$2"
                shift
                ;;
            --uninstall)
                uninstall_pack="$2"
                shift
                ;;
            --help|help)
                view_ui_help "extras" "$MSG_HELP_EXTRAS_DESC" "$MSG_HELP_EXTRAS_OPTS" "$MSG_HELP_EXTRAS_EX" "$VERSION"
                return 0
                ;;
            *)
                # Unrecognized flag
                ;;
        esac
        shift
    done

    # 1. Feature: List Catalog
    if [ "$list" = true ]; then
        view_extras_catalog_header
        
        # Fetch remote catalog (with local fallback)
        model_catalog_fetch_remote || true
        
        local catalog_json
        catalog_json=$(model_catalog_get_list)
        
        if [ -n "$catalog_json" ]; then
            view_extras_catalog_table_header
            # Loop through JSON array using jq
            local count
            count=$(echo "$catalog_json" | jq '. | length')
            for (( i=0; i<$count; i++ )); do
                local id name desc
                id=$(echo "$catalog_json" | jq -r ".[$i].id")
                name=$(echo "$catalog_json" | jq -r ".[$i].name")
                desc=$(echo "$catalog_json" | jq -r ".[$i].description")
                view_extras_catalog_item "$id" "$name" "$desc"
            done
            view_extras_catalog_footer
        else
            echo -e "   ${RED}${ICON_FAIL} Error: Could not load extra-packs catalog.${NC}"
        fi
        return 0
    fi

    # 2. Feature: Install Pack
    if [ -n "$install_pack" ]; then
        # Check if config exists (requirement for installation)
        if ! model_fs_load_config &>> "$DEBUG_OUT"; then
            echo -e "${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
            return 1
        fi
        
        view_extras_install_start "$install_pack"
        if service_extra_pack_install "$install_pack" "false"; then
            echo -e "\n${BRIGHT_GREEN}${ICON_OK} $install_pack installed successfully.${NC}"
        else
            echo -e "\n${BRIGHT_RED}${ICON_FAIL} $install_pack installation failed.${NC}"
            return 1
        fi
        return 0
    fi

    # 3. Feature: Uninstall Pack
    if [ -n "$uninstall_pack" ]; then
        # Check if config exists
        if ! model_fs_load_config &>> "$DEBUG_OUT"; then
            echo -e "${RED}${ICON_FAIL} ${MSG_ERROR_CONFIG_NOT_FOUND}${NC}"
            return 1
        fi
        
        view_extras_uninstall_start "$uninstall_pack"
        service_extra_pack_uninstall "$uninstall_pack"
        echo -e "\n${BRIGHT_GREEN}${ICON_OK} $uninstall_pack removed successfully.${NC}"
        return 0
    fi

    # Default if no args
    view_ui_help "extras" "$MSG_HELP_EXTRAS_DESC" "$MSG_HELP_EXTRAS_OPTS" "$MSG_HELP_EXTRAS_EX" "$VERSION"
}
