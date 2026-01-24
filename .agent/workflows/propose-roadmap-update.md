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

## Step 4 — Determine Planning Artifact

Based on the target branch:

* If target is `main`:

  * The proposal belongs in `.roadmap/`
  * Identify the most appropriate roadmap file (e.g. `0.6.0-dev.md`, `future-capabilities.md`)

* If target is `release/*`:

  * The proposal belongs in `TODO.md`

---

## Step 5 — Propose the Update

Describe:

* what file should be updated
* what section the item belongs to
* suggested wording for the new entry

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
