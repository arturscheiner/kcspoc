#!/bin/bash

# ==============================================================================
# Layer: Controller
# File: base_controller.sh
# Responsibility: Orchestration and Flow Control
#
# Rules:
# 1. Orchestrates the flow between Services and Views.
# 2. Parses CLI intent and arguments.
# 3. MUST NOT execute business logic or kubectl commands directly.
# 4. MUST NOT contain system state mutations.
# ==============================================================================
