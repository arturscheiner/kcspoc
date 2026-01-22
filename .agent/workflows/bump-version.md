---
description: Bump Version (Development Mode)
---

## Purpose
Guide **minor or major version bumps** while operating on the `main` branch.

This workflow ensures version changes reflect **intentional development milestones**, not incidental changes.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

If the branch is NOT main, STOP and instruct the operator to switch to main.

## Step 2 — Validate Allowed Version Change

Allowed version changes here:
- minor (e.g. 0.5 → 0.6)
- major (future)

Patch-only bumps (e.g. 0.5.7 → 0.5.8) should be done on release/0.5.

## Step 3 — Intent Validation

Before bumping:
- Confirm this version bump corresponds to:
  - new features
  - architectural changes
  - breaking behavior

- Ensure roadmap alignment:
  - .roadmap/0.6.0-dev.md

If not aligned, STOP and propose a roadmap update.

## Step 4 — Version Alignment
Guide updates to:
- lib/common.sh
- CHANGELOG.md
- documentation where needed

Present a clear list of expected changes.

## Step 5 — Release Strategy
Explain next steps:
- merging into release branches (when applicable)
- tagging strategy
- compatibility expectations

Do NOT create tags automatically.

## Guardrails
- Never perform patch-only bumps on main.
- Never bump versions without roadmap justification.
- Never mix version bump with unrelated changes.