#!/bin/bash

# Mock test for bootstrap redundant prompt fix (/bugfix)

# Source required components
export SCRIPT_DIR="$(pwd)"
source "lib/model/base_model.sh"
source "lib/model/config_model.sh"
source "lib/service/base_service.sh"
source "lib/service/config_service.sh"
source "lib/view/base_view.sh"
source "lib/view/bootstrap_view.sh"
source "lib/service/bootstrap_service.sh"

# 1. Test scenario: Token NOT configured
echo "Scenario 1: Token NOT configured (Should prompt)"
ADMIN_API_TOKEN=""
# Mock view_bootstrap_prompt_token to avoid interactive wait
view_bootstrap_prompt_token() {
    echo "   [MOCK] Prompting for token..."
    eval "$1=\"mocked-token-1234567890\""
}
service_bootstrap_run

# 2. Test scenario: Token ALREADY configured
echo -e "\nScenario 2: Token ALREADY configured (Should skip prompt)"
ADMIN_API_TOKEN="configured-token-9999"
# Mock config_service_load to act like it's successfully loaded
config_service_load() { return 0; }

service_bootstrap_run
