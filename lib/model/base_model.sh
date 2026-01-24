#!/bin/bash

# ==============================================================================
# Layer: Model
# File: base_model.sh
# Responsibility: Data, System, and Cluster Abstraction
#
# Rules:
# 1. Wraps kubectl, filesystem, and system state access.
# 2. Provides a clean interface for external data/state.
# 3. MUST NOT print output directly.
# 4. MUST NOT contain business logic or orchestration.
# ==============================================================================
