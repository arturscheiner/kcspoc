---
description: Propose Roadmap Update
---

## Purpose

Evaluate a new idea, requirement, or observation and determine **where it belongs** in the project planning system, without executing changes automatically.

This workflow decides **scope and destination**, not implementation.

---

## Step 1 — Capture the Proposal

Clearly restate the proposed idea in neutral terms:

* what problem it addresses
* what outcome is desired
* whether it affects users, architecture, or internal process

Do not classify yet.

---

## Step 2 — Mandatory Work Classification

Classify the proposal as exactly one of:

* **Bugfix** — Corrects incorrect or broken behavior
* **Feature** — Introduces new user-visible capability or workflow
* **Refactor** — Improves internal structure or architecture without intentional behavior change

Provide a short justification and explain why the other two do NOT apply.

---

## Step 3 — Determine Target Branch

Based on classification:

* **Bugfix** → target is the active `release/*` branch (or the latest stable release branch)
* **Feature** → target is `main`
* **Refactor** → target is `main`

If the current branch does not match the target, clearly recommend a branch switch.
Do not execute `git checkout` automatically.

---

## Step 4 — Determine Planning Artifacts

Based on the target branch:

* **If target is `main` (Standard for v0.6.0+ Development):**
  * The proposal requires updating two distinct artifacts in `.roadmap/`:
    1. **High-Level Roadmap** (e.g., `0.6.0-dev.md`): Captures the **desired feature** or capability.
       - **Rule**: This file must NOT contain checkboxes `[ ]` or task markers. It is a list of goals, not an execution checklist.
    2. **Execution-Level TODOs** (e.g., `0.6.0-execution-todos.md`): Captures the **granular tasks** required to implement the feature.
       - **Rule**: This file uses checkboxes `[ ]` to track implementation progress.
  
* **If target is `release/*`:**
  * The proposal belongs directly in the root `TODO.md` (or the specific release TODO).

---

## Step 5 — Propose the Update

Describe the specific changes for both levels:

1. **For the Roadmap**: Suggested wording for the new capability (feature-oriented).
2. **For the Execution TODOs**: Break down the feature into 3-5 actionable sub-tasks (implementation-oriented).

Do not modify files automatically.

---

## Step 6 — Confirm Next Action

Ask the user to confirm one of the following:

* approve the roadmap/TODO update
* adjust the wording or classification
* cancel the proposal

---

## Guardrails

* Do not modify files without confirmation
* Do not execute git commands automatically
* Do not mix planning with implementation
* Do not assume branch changes
