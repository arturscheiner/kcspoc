---
description: Align TODO with Roadmap
---

## Purpose

Provide a **diagnostic comparison** between short-term TODO items and the long-term roadmap, ensuring planning coherence without making changes.

This workflow is **read-only** and exists to prevent drift between patch-level tasks and future plans.

---

## Step 1 — Identify Available Planning Artifacts

Inspect the repository to determine which planning documents exist:

* `TODO.md` (always expected)
* `.roadmap/` directory (may or may not exist depending on branch)

Do not assume both are present.

---

## Step 2 — Load TODO Items

From `TODO.md`:

* Identify unchecked (open) items
* Ignore completed, deprecated, or commented entries
* Each item of the execution TODO list must have a numbered indication

Treat TODO items as **short-term, tactical work**.

---

## Step 3 — Load Roadmap Items (If Available)

If `.roadmap/` exists:

* Scan roadmap documents for planned initiatives
* Treat roadmap items as **strategic or future-oriented work**

If `.roadmap/` does not exist, explicitly state that roadmap context is unavailable.

---

## Step 4 — Compare and Classify

For each TODO item, assess:

* **Aligned**: clearly covered by an existing roadmap item
* **Patch-only**: appropriate for stabilization and unlikely to appear in roadmap
* **Candidate for roadmap**: suggests future evolution beyond patch scope
* **Unclear**: insufficient context to determine alignment

Do not infer intent beyond available text.

---

## Step 5 — Present Findings

Summarize:

* TODOs that are already represented in the roadmap
* TODOs that appear patch-specific and correctly scoped
* TODOs that may deserve promotion to the roadmap
* Any ambiguity or missing context

Do not recommend specific implementation actions.

---

## Guardrails

* Do not modify files
* Do not create, move, or delete tasks
* Do not assume branch context
* Do not execute shell commands