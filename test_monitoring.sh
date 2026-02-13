#!/bin/bash

# Verification test for E-102 Refinement - ALL MONITORING

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
    echo "$payload" > /tmp/kcspoc_payload_all.json
    echo '{"id": "group-verified-all"}'
    return 0
}

# Mock UI
service_spinner_start() { :; }
service_spinner_stop() { :; }

echo "Verifying Corrected Payload (Monitoring: all)..."
ID=$(bootstrap_service_create_poc_group "kcs.lab" "token" "scope-id" "test-group")

PAYLOAD=$(cat /tmp/kcspoc_payload_all.json)
MONITORING=$(echo "$PAYLOAD" | jq -r '.fileThreatProtectionMonitoring')

echo "Detected Monitoring: $MONITORING"

if [[ "$MONITORING" == "all" ]]; then
    echo "PASS: fileThreatProtectionMonitoring is set to 'all'."
else
    echo "FAIL: Unexpected value: $MONITORING"
    exit 1
fi
rm /tmp/kcspoc_payload_all.json
