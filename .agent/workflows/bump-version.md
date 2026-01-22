---
description: Bump Version (Patch Mode)
---

## Purpose
Safely bump the **patch version** while operating on the `release/0.5` branch.

This workflow enforces strict **Semantic Versioning discipline** and prevents invalid version changes during stabilization.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

If the branch is NOT release/0.5, STOP and explain that patch bumps must be done from the release branch.

## Step 2 — Validate Allowed Version Change
Only the following version changes are allowed here:
- 0.5.X → 0.5.(X+1)
If the requested bump is:
- minor
- major
- cross-line (e.g. 0.5 → 0.6)

STOP and explain that this must be done on main.

## Step 3 — Pre-flight Checks

Before bumping:
- Ensure working tree is clean
- Ensure CHANGELOG.md has an entry for the new version
- Ensure the change corresponds to:
  - bugfix
  - installer hardening
  - documentation
  - internal safe cleanup

## Step 4 — Version Alignment

Guide the operator to update:
- lib/common.sh
- CHANGELOG.md
- any version references required by rules

Do NOT apply changes automatically.
Present the expected diffs.

## Step 5 — Tagging & Release Guidance
After approval:
- Recommend using /prepare-release
- Then /tag-release

Do NOT create tags automatically.

## Guardrails
- Never bump minor or major versions here.
- Never skip CHANGELOG updates.
- Never create tags implicitly.