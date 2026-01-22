---
description: Bugfix (Release / Patch Mode)
---

## Purpose
Guide the safe implementation of **true bug fixes** while operating on the `release/0.5` branch.

A bugfix is defined as:
- correcting incorrect behavior
- fixing regressions
- resolving runtime or logic errors

This workflow is **not** for refactors, improvements, or new behavior.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

If the branch is NOT release/0.5, STOP and explain that bugfixes for v0.5.x must be done on the release branch.

## Step 2 — Bug Validation
Before proceeding, confirm:
- The behavior is objectively incorrect
- The expected behavior already existed or was documented
- No new behavior is being introduced

If any of the above is false, STOP and redirect to another workflow.

## Step 3 — Scope Definition
Explicitly define:
- What is broken
- Where it happens (command / file / function)
- The minimal change required to fix it
Reject any proposal that:
- touches unrelated files
- changes architecture
- improves code style beyond necessity

## Step 4 — Implementation Constraints
During the fix:
- Change as little code as possible
- Preserve public interfaces
- Avoid refactoring
- Avoid renaming unless strictly necessary

## Step 5 — Validation
Ensure:
- The bug is reproducible before the fix
- The fix resolves the issue
- No side effects are introduced

Document the fix intent briefly for CHANGELOG inclusion.

## Guardrails
- Never introduce features via bugfix.
- Never refactor under the guise of a fix.
- If the fix requires structural change, STOP and escalate.