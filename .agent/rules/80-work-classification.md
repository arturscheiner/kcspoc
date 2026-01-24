---
trigger: always_on
---

# Rule: Mandatory Work Classification

## Purpose
Ensure that **every code change** is explicitly classified before implementation to avoid scope confusion and architectural drift.

---

## Mandatory Classification
Before proposing or executing any change, the agent MUST explicitly declare **one and only one** of the following modes:

- **/bugfix** — Corrects incorrect or broken behavior in stable or development code.
- **/feature** — Introduces new user-visible behavior, capability, or workflow.
- **/refactor** — Improves internal structure or architecture without intentional user-visible behavior changes.

---

## Justification Requirement
The agent MUST provide a short justification explaining:
- why this classification applies
- why the other two classifications do NOT apply

If justification is unclear or contradictory, STOP and ask for clarification.

---

## Branch Enforcement
- `/bugfix` → allowed on `release/*` and `main`
- `/feature` → allowed ONLY on `main`
- `/refactor` → allowed ONLY on `main`

If the current branch violates these rules, STOP and instruct the correct branch switch.

---

## Guardrail
No implementation, file edits, or command execution may occur until classification is complete and accepted by the user.
