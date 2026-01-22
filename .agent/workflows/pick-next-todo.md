---
description: Pick Next TODO (Development Mode)
---

## Purpose
Select the next **high-value development task** to work on while operating in the `main` branch.

This workflow favors **features, refactors, and roadmap-driven improvements**, while excluding patch-only work.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

If the branch is NOT main, STOP and explain that this workflow is intended for development work only.

## Step 2 — Load Sources of Truth
Use the following inputs:
- TODO.md
- .roadmap/0.6.0-dev.md
- .roadmap/future-capabilities.md
Ignore:
- .roadmap/0.5.x-stabilization.md

## Step 3 — Filter Eligible TODOs
Prefer TODO items that involve:
- feature development
- refactoring
- architectural improvements
- long-term maintainability

Deprioritize or ignore:
- small bugfixes
- installer-only tweaks
- patch-level work

## Step 4 — Prioritization Logic
Rank candidates using this order:
1. Roadmap-aligned development tasks
2. Tasks that unblock multiple future items
3. Refactors with clear ROI
4. Developer-experience improvements

## Step 5 — Propose the Next Task
Present:
- The selected TODO item
- Why it fits the main branch
- Which roadmap goal it supports
- Expected scope and risks

Ask for confirmation before starting.

## Guardrails
- Never suggest patch-only work.
- Never downgrade stabilization tasks into dev scope.
- If all TODOs are patch-level, recommend switching to release/0.5.