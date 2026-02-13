#!/bin/bash

# Verification test for E-102 Refinement - FIXED

export SCRIPT_DIR="$(pwd)"
source "lib/model/base_model.sh"
source "lib/model/config_model.sh"
source "lib/model/kcs_api_model.sh"
source "lib/service/base_service.sh"
source "lib/service/config_service.sh"
source "lib/view/base_view.sh"
source "lib/view/bootstrap_view.sh"
source "lib/service/bootstrap_service.sh"

# Mock configuration
export REGISTRY_SERVER="repo.kcs.kaspersky.com"
export REGISTRY_USER="poc-user"
export NAMESPACE="prod-kcs"
export DOMAIN="kcs.lab"

# Mock API Model
model_kcs_api_create_agent_group() {
    local payload="$3"
    # We want to verify the payload, so we'll output it as part of the JSON response
    # to be extracted by the caller's jq -r '.id' (hacky) or just use a temporary file.
    echo "$payload" > /tmp/kcspoc_payload.json
    echo '{"id": "group-verified"}'
    return 0
}

# Mock UI
service_spinner_start() { :; }
service_spinner_stop() { :; }

echo "Verifying Corrected Payload..."
ID=$(bootstrap_service_create_poc_group "kcs.lab" "token" "scope-id" "test-group")

if [ "$ID" != "group-verified" ]; then
    echo "FAIL: Function failed or returned wrong ID: '$ID'"
    exit 1
fi

PAYLOAD=$(cat /tmp/kcspoc_payload.json)
echo "$PAYLOAD" | jq .

# Assertions
REG_URL=$(echo "$PAYLOAD" | jq -r '.kcsRegistryUrl')
KCS_NS=$(echo "$PAYLOAD" | jq -r '.kcsNamespace')

echo "Detected URL: $REG_URL"
echo "Detected NS: $KCS_NS"

if [[ "$REG_URL" == "repo.kcs.kaspersky.com/images" ]] && [[ "$KCS_NS" == "prod-kcs" ]]; then
    echo "PASS: Registry URL and Namespace are correct."
else
    echo "FAIL: Unexpected values."
    exit 1
fi
rm /tmp/kcspoc_payload.json
