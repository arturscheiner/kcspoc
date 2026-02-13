#!/bin/bash

# ==============================================================================
# Layer: Service
# File: pull_service.sh
# Responsibility: Business logic for artifact downloads and listing
# ==============================================================================

service_pull_list_local() {
    view_pull_local_list_header
    
    local kcs_artifact_base="$ARTIFACTS_DIR/kcs"
    local versions
    versions=$(model_fs_list_artifact_versions "$kcs_artifact_base")

    if [ -n "$versions" ]; then
        view_pull_local_list_table_header
        for ver in $versions; do
            local date_file="$kcs_artifact_base/$ver/.downloaded"
            local ddate="---"
            [ -f "$date_file" ] && ddate=$(cat "$date_file")
            
            local is_active="false"
            [ "$ver" == "$KCS_VERSION" ] && is_active="true"
            
            view_pull_local_list_item "$ver" "$ddate" "$kcs_artifact_base/$ver" "$is_active"
        done
    else
        view_pull_local_list_empty
    fi
    echo ""
}

service_pull_perform() {
    local force_version="$1"

    # 0. Check Dependencies
    service_base_require_dependencies "helm" "sed" "grep"

    # 1. Registry Login
    view_pull_auth_start
    if model_helm_login "$REGISTRY_SERVER" "$REGISTRY_USER" "$REGISTRY_PASS" > /dev/null; then
        service_spinner_stop "PASS"
    else
        service_spinner_stop "FAIL"
        view_pull_login_error
        exit 1
    fi

    # 2. Determine Version
    local target_ver
    if [ -n "$force_version" ]; then
        target_ver="$force_version"
        view_pull_version_source_flag "$target_ver"
    elif [ -n "$KCS_VERSION" ] && [ "$KCS_VERSION" != "latest" ]; then
        target_ver="$KCS_VERSION"
        view_pull_version_source_config "$target_ver"
    else
        target_ver="latest"
        view_pull_version_source_default
    fi
    
    local helm_args=""
    [ "$target_ver" != "latest" ] && helm_args="--version $target_ver"

    local artifact_path="$ARTIFACTS_DIR/kcs/$target_ver"

    # 3. Cache Check
    if [ "$target_ver" != "latest" ] && ls "$artifact_path"/kcs-*.tgz &>/dev/null; then
        view_pull_cache_hit "$target_ver"
        return 0
    fi

    # 4. Target Path Setup
    mkdir -p "$artifact_path" &>> "$DEBUG_OUT"

    # 5. Helm Pull
    view_pull_download_start
    if model_helm_pull "$REGISTRY_SERVER" "$helm_args" "$artifact_path" > /dev/null; then
        service_spinner_stop "PASS"
        
        # 6. Resolve Real Version
        local tgz_file
        tgz_file=$(ls -t "$artifact_path"/kcs-*.tgz 2>/dev/null | head -n 1)
        
        if [ -f "$tgz_file" ]; then
            local real_ver
            real_ver=$(basename "$tgz_file" | sed -E 's/kcs-([0-9.]+)\.tgz/\1/')
            
            if [ "$target_ver" == "latest" ]; then
                local final_path="$ARTIFACTS_DIR/kcs/$real_ver"
                if [ "$artifact_path" != "$final_path" ]; then
                    [ -d "$final_path" ] && rm -rf "$final_path"
                    model_fs_move_artifact "$artifact_path" "$final_path"
                    artifact_path="$final_path"
                    tgz_file="$artifact_path/$(basename "$tgz_file")"
                fi
                
                model_fs_update_config_version "$real_ver"
                view_pull_config_updated "$real_ver"
                target_ver="$real_ver"
            fi

            model_fs_save_download_metadata "$artifact_path"
            view_pull_success_file "$(basename "$tgz_file")"

            # 7. Fetch Remote Template
            _service_pull_fetch_templates "$target_ver" "$artifact_path"
        else
            view_pull_error_file_missing
            exit 1
        fi
    else
        service_spinner_stop "FAIL"
        view_pull_error_fail
        exit 1
    fi
}

_service_pull_fetch_templates() {
    local ver="$1"
    local artifact_path="$2"

    local template_url="https://raw.githubusercontent.com/arturscheiner/kcspoc/refs/heads/main/templates/values-core-$ver.yaml"
    local template_dest="$artifact_path/values-core-$ver.yaml"
    
    view_pull_template_fetch_start "$ver"
    if model_fs_fetch_remote_file "$template_url" "$template_dest"; then
        service_spinner_stop "PASS"
        view_pull_template_cached "values-core-$ver.yaml"
    else
        service_spinner_stop "WARN"
        view_pull_template_fallback_hint
        model_fs_fetch_remote_file "https://raw.githubusercontent.com/arturscheiner/kcspoc/refs/heads/main/templates/values-core-latest.yaml" "$artifact_path/values-core-latest.yaml"
    fi
}
