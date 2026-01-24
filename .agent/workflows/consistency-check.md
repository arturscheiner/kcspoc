---
description: Consistency Check
---

## Purpose

Perform a **read-only sanity check** of the repository to detect structural inconsistencies, drift, or incomplete release states.

This workflow exists to answer one question:

> "Is the repository in a coherent and healthy state right now?"

It never fixes problems — it only reports them.

---

## Step 1 — Detect Current Branch

Identify the active branch:

```bash
git branch --show-current
```

This information is used only for contextual messaging.

---

## Step 2 — Version Consistency

Verify that version references are coherent:

* `lib/model/version_model.sh` VERSION_BASE matches the latest version entry in `CHANGELOG.md`
* No conflicting or duplicated version declarations exist

If a mismatch is detected, report it clearly.

---

## Step 3 — CHANGELOG Sanity

Inspect `CHANGELOG.md` for:

* `[TBD]` placeholders
* missing sections for recent versions
* malformed or duplicated headers

Report any anomalies.

---

## Step 4 — Planning Artifacts Presence

Check for planning context:

* `TODO.md` exists
* If branch is `main`, `.roadmap/` directory exists

If expected artifacts are missing, report it.

---

## Step 5 — Branch Hygiene Indicators

Without enforcing rules, report if:

* feature-related workflows are present on `release/*` branches
* patch-only workflows are missing from `release/*` branches

This step is informational only.

---

## Step 6 — Summary Report

Produce a concise summary including:

* overall repository health: OK / WARN / ATTENTION
* list of detected inconsistencies
* suggested next workflows (e.g. `/prepare-release`, `/bump-version`, `/align-todo-with-roadmap`)

Do not execute any actions.

---

## Guardrails

* Do not modify files
* Do not execute shell commands beyond inspection
* Do not enforce branch policy
* Do not propose code changes
