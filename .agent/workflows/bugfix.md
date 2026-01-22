---
description: Bugfix (Blocked on Development Branch)
---

## Purpose
Prevent patch-level bugfix work from being executed on the `main` branch.

Bugfixes for released versions must be applied on the appropriate release branch.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

## Step 2 — Enforce Guardrail
If the branch is main:
- STOP immediately.
- Explain:
  - Patch-level bugfixes belong to release/0.5
  - Applying them on main risks divergence and confusion
- Propose the correct action:
  git checkout release/0.5

## Step 3 — Redirect
Explain that:
- main is for feature and refactor work
- Patch fixes must be stabilized and released before merging forward

## Guardrails
- Never perform patch-level bugfixes on main.
- Always redirect to the appropriate release branch.