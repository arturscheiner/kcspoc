---
description: Bump Version
---

## Purpose

Control **semantic version updates** in kcspoc in a predictable, branch-aware, and safe manner.

This workflow governs *when* and *how* versions may be bumped, and prevents accidental or premature version changes.

---

## Step 1 — Detect Current Branch

Determine the active branch:

```bash
git branch --show-current
```

---

## Step 2 — Determine Allowed Version Scope

Based on the branch:

* **release/* branch**:

  * Allowed: **PATCH** bumps only (X.Y.Z → X.Y.Z+1)
  * Forbidden: MINOR or MAJOR bumps

* **main branch**:

  * Allowed: MINOR or MAJOR bumps
  * PATCH bumps are discouraged unless explicitly justified

If the requested bump violates these rules, STOP.

---

## Step 3 — Justify the Version Change

Before proceeding, clearly explain:

* what changes since the last version justify the bump
* why this is the correct semantic increment

If justification is vague or unclear, STOP.

---

## Step 4 — Identify Version Sources

List all locations where the version must be updated:

* `lib/model/version_model.sh`
* `CHANGELOG.md`
* any additional version references (if applicable)

Do not update files yet.

---

## Step 5 — CHANGELOG Readiness Check

Validate that:

* the target version has an entry in `CHANGELOG.md`
* no `[TBD]` placeholders remain
* the entry accurately reflects the included changes

If the CHANGELOG is not ready, STOP.

---

## Step 6 — Execution Plan

Describe the exact steps that will be taken:

1. Update version constants
2. Finalize CHANGELOG entry
3. Commit with a clear, semantic message

No commands should be executed yet.

---

## Step 7 — Execution

After user confirmation:

* run the appropriate version bump script or manual edits
* commit the changes

Tagging and release creation are **out of scope** for this workflow.

---

## Guardrails

* Never bump versions without CHANGELOG alignment
* Never bump versions on the wrong branch
* Never mix version bumps with feature or refactor commits
* If unsure, STOP and ask
