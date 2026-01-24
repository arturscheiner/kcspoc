#!/bin/bash

# ==============================================================================
# Layer: Model
# File: deploy_model.sh
# Responsibility: KCS specific deployment data and artifact discovery
# ==============================================================================

model_deploy_count_local_artifacts() {
    local kcs_artifact_base="$ARTIFACTS_DIR/kcs"
    if [ ! -d "$kcs_artifact_base" ]; then
        echo 0
        return
    fi
    find "$kcs_artifact_base" -maxdepth 2 -name "kcs-*.tgz" | wc -l
}

model_deploy_get_installed_version() {
    local ns="$1"
    local ver=""

    # 1. Try infraconfig ConfigMap (IMAGE_TAG_MIDDLEWARE)
    ver=$(kubectl get configmap infraconfig -n "$ns" -o jsonpath='{.data.IMAGE_TAG_MIDDLEWARE}' 2>/dev/null)
    if [ -n "$ver" ]; then
        echo "$ver"
        return
    fi

    # 2. Try Middleware POD image tag
    local img=$(kubectl get pod -n "$ns" -l app.kubernetes.io/name=middleware -o jsonpath='{.items[0].spec.containers[*].image}' 2>/dev/null)
    if [ -n "$img" ]; then
        # Extract tag after last colon, remove leading 'v'
        ver=$(echo "$img" | awk -F':' '{print $NF}' | sed 's/^v//')
        [ -n "$ver" ] && echo "$ver" && return
    fi

    # 3. Check namespace label kcspoc.io/kcs-version
    ver=$(kubectl get ns "$ns" -o jsonpath='{.metadata.labels.kcspoc\.io/kcs-version}' 2>/dev/null)
    if [ -n "$ver" ]; then
        echo "$ver"
        return
    fi
    
    # 4. Check helm release metadata
    ver=$(helm list -n "$ns" -o json | jq -r '.[] | select(.name=="kcs") | .app_version' 2>/dev/null)
    if [ -n "$ver" ] && [ "$ver" != "null" ]; then
        echo "$ver"
        return
    fi

    echo "unknown"
}

model_deploy_find_global_instances() {
    local target_ns="$1"
    local found_instances=""

    # 1. Search for Helm releases
    local helm_instances=$(helm list -A -o json 2>/dev/null | jq -r '.[] | select(.name=="kcs") | .namespace' 2>/dev/null)
    if [ -n "$helm_instances" ]; then
        for ns in $helm_instances; do
            [ "$ns" == "$target_ns" ] && continue
            found_instances+="      → $ns (Helm Release)\n"
        done
    fi

    # 2. Search for infraconfig ConfigMap (Strong Signal)
    local cm_ns=$(kubectl get cm -A --no-headers 2>/dev/null | grep "infraconfig " | awk '{print $1}' | sort | uniq)
    if [ -n "$cm_ns" ]; then
        for ns in $cm_ns; do
            [ "$ns" == "$target_ns" ] && continue
            [[ "$found_instances" == *"$ns"* ]] && continue
            found_instances+="      → $ns (KCS ConfigMap: infraconfig)\n"
        done
    fi

    # 3. Search for Middleware component (The Brain)
    local middleware_ns=$(kubectl get pods -A -l app.kubernetes.io/name=middleware -o jsonpath='{.items[*].metadata.namespace}' 2>/dev/null | tr ' ' '\n' | sort | uniq)
    if [ -n "$middleware_ns" ]; then
        for ns in $middleware_ns; do
            [ "$ns" == "$target_ns" ] && continue
            [[ "$found_instances" == *"$ns"* ]] && continue
            found_instances+="      → $ns (Active Middleware Detected)\n"
        done
    fi

    echo -ne "$found_instances"
}

model_deploy_process_values() {
    local template="$1"
    local output="$2"
    local target_ver="$3"
    local local_hash="$4"
    local provision_ver="$5"
    
    cp "$template" "$output"
    
    # Apply Configuration
    [ -n "$DOMAIN" ] && sed -i "s|\$DOMAIN_CONFIGURED|$DOMAIN|g" "$output"
    [ -n "$PLATFORM" ] && sed -i "s|\$PLATFORM_CONFIGURED|$PLATFORM|g" "$output"
    [ -n "$CRI_SOCKET" ] && sed -i "s|\$CRI_SOCKET_CONFIG|$CRI_SOCKET|g" "$output"
    [ -n "$REGISTRY_SERVER" ] && sed -i "s|\$REGISTRY_SERVER_CONFIG|$REGISTRY_SERVER|g" "$output"
    [ -n "$REGISTRY_USER" ] && sed -i "s|\$REGISTRY_USER_CONFIG|$REGISTRY_USER|g" "$output"
    [ -n "$REGISTRY_PASS" ] && sed -i "s|\$REGISTRY_PASS_CONFIG|$REGISTRY_PASS|g" "$output"
    [ -n "$REGISTRY_EMAIL" ] && sed -i "s|\$REGISTRY_EMAIL_CONFIG|$REGISTRY_EMAIL|g" "$output"
    [ -n "$target_ver" ] && sed -i "s|\${KCS_VERSION}|$target_ver|g" "$output"
    
    # Metadata
    sed -i "s|\$PROVISION_HASH_CONFIG|$local_hash|g" "$output"
    sed -i "s|\$PROVISION_VERSION_CONFIG|$provision_ver|g" "$output"

    # Secrets
    [ -n "$POSTGRES_USER" ] && sed -i "s|\$POSTGRES_USER_CONFIG|$POSTGRES_USER|g" "$output"
    [ -n "$POSTGRES_PASSWORD" ] && sed -i "s|\$POSTGRES_PASS_CONFIG|$POSTGRES_PASSWORD|g" "$output"
    [ -n "$MINIO_ROOT_USER" ] && sed -i "s|\$MINIO_USER_CONFIG|$MINIO_ROOT_USER|g" "$output"
    [ -n "$MINIO_ROOT_PASSWORD" ] && sed -i "s|\$MINIO_PASS_CONFIG|$MINIO_ROOT_PASSWORD|g" "$output"
    [ -n "$CLICKHOUSE_ADMIN_PASSWORD" ] && sed -i "s|\$CH_ADMIN_PASS_CONFIG|$CLICKHOUSE_ADMIN_PASSWORD|g" "$output"
    [ -n "$CLICKHOUSE_WRITE_PASSWORD" ] && sed -i "s|\$CH_WRITE_PASS_CONFIG|$CLICKHOUSE_WRITE_PASSWORD|g" "$output"
    [ -n "$CLICKHOUSE_READ_PASSWORD" ] && sed -i "s|\$CH_READ_PASS_CONFIG|$CLICKHOUSE_READ_PASSWORD|g" "$output"
    [ -n "$MCHD_USER" ] && sed -i "s|\$MCHD_USER_CONFIG|$MCHD_USER|g" "$output"
    [ -n "$MCHD_PASS" ] && sed -i "s|\$MCHD_PASS_CONFIG|$MCHD_PASS|g" "$output"
    [ -n "$APP_SECRET" ] && sed -i "s|\$APP_SECRET_CONFIG|$APP_SECRET|g" "$output"
}
