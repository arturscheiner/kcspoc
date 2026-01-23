---
trigger: always_on
---

# Rule: MVC Architecture Enforcement

## Purpose
Enforce a strict MVC architecture for kcspoc starting from v0.6.0 development.

This rule exists to prevent logic sprawl, script coupling, and architectural drift.

---

## Architectural Layers

### Controller
- Orchestrates command flow
- Parses CLI intent
- Calls services
- Selects views
- MUST NOT execute kubectl directly
- MUST NOT contain business logic

### Service
- Contains business rules
- Implements idempotency
- Coordinates models
- MUST NOT print output
- MUST NOT parse CLI arguments

### Model
- Abstracts system, cluster, config, and state
- Wraps kubectl and filesystem access
- MUST NOT print output

### View
- Responsible for all user-facing output
- Icons, colors, formatting, messages
- MUST NOT contain logic or state mutations

---

## Mandatory Rules
- All commands MUST flow: Controller → Service → Model → View
- No cross-layer shortcuts are allowed
- Internal scripts are implementation details, not entrypoints

---

## Guardrails
- If a change violates MVC boundaries, STOP and refactor
- Refactors are preferred over shortcuts
