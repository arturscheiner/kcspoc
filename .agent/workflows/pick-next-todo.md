---
description: Pick Next TODO (Release / Patch Mode)
---

Select the next **safe and relevant task** to work on while operating in the `release/0.5` branch.

This workflow is strictly limited to **stabilization, bugfixes, installer hardening, and documentation**.  
It must never propose feature work or refactors.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

If the branch is NOT release/0.5, STOP and explain that this workflow is intended only for patch work.

## Step 2 — Load Sources of Truth

Use the following inputs:
- TODO.md
- .roadmap/0.5.x-stabilization.md

Ignore:
- .roadmap/0.6.0-dev.md
- .roadmap/future-capabilities.md

## Step 3 — Filter Eligible TODOs

Only consider TODO items that:
- Are marked as:
  - bugfix
  - patch
  - installer
  - docs
- Do NOT imply:
  - architectural change
  - refactor
  - new feature
  - breaking behavior

## Step 4 — Prioritization Logic
Rank candidates using this order:
 1.Installer correctness & safety
 2.Data integrity / state consistency
 3.User-facing clarity (messages, docs)
 4.Internal cleanup with zero behavior change

Ask for confirmation before starting

## Step 5 — Propose the Next Task
Present:
- The selected TODO item
- Why it is safe for release/0.5
- What files are likely to be touched
- A rough estimate of complexity

Ask for confirmation before starting.

## Guardrails
- Never propose features or refactors.
- Never suggest changes that require schema or behavior changes.
- If no safe TODO exists, say so explicitly and STOP.