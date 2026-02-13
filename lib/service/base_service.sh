#!/bin/bash

# ==============================================================================
# Layer: Service
# File: base_service.sh
# Responsibility: Business Logic and Coordination
#
# Rules:
# 1. Implements business rules and idempotency.
# 2. Coordinates Models to achieve high-level operations.
# 3. MUST NOT print output directly (use Views instead).
# 4. MUST NOT parse CLI arguments.
# ==============================================================================

service_base_require_dependencies() {
    local missing
    missing=$(model_system_get_missing_dependencies "$@")
    
    if [ -n "$missing" ]; then
        view_ui_missing_dependency_error "$missing"
        exit 1
    fi
    return 0
}
