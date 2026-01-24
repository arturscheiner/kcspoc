---
description: Refactor (Architecture / MVC)
---

## Intent

This workflow governs **pure refactoring work** on kcspoc. Refactoring is defined as a change that improves **internal structure, clarity, and maintainability** without intentionally altering user-facing behavior.

Refactors are expected to be applied **only on the development branch (`main`)** and primarily target the upcoming **v0.6.0+ MVC architecture**.

---

## Step 1 — Branch Validation

Confirm the current branch:

```bash
git branch --show-current
```

* If the branch is not `main`, STOP.
* Refactors are **never allowed** on `release/*` branches.

---

## Step 2 — Refactor Qualification Check

Before proceeding, confirm that the work:

* does **not** introduce new CLI flags, commands, or workflows
* does **not** change documented behavior
* does **not** alter user-visible output semantics
* focuses on structure, boundaries, or code organization

If any of the above are violated, STOP and redirect to `/feature` or `/bugfix`.

---

## Step 3 — Architectural Motivation

Explicitly describe:

* the current structural problem
* why the existing layout or coupling is harmful
* how the refactor improves maintainability or extensibility

Refactors without architectural justification are not allowed.

---

## Step 4 — MVC Impact Declaration

State clearly which layers are affected and how:

* **Controller**: command routing, orchestration, or flow control
* **Service**: business logic extraction, reuse, or simplification
* **Model**: domain representation, state, or configuration handling
* **View**: output formatting, UX consolidation, messaging boundaries

At least one layer must be meaningfully improved.

---

## Step 5 — Refactor Plan (No Code Yet)

Before writing code, outline:

* files or modules to be moved, split, or renamed
* new directories or boundaries to be introduced
* legacy structures to be removed or deprecated

No implementation should occur before this plan is clear.

---

## Step 6 — Execution Rules

During implementation:

* keep commits small and reviewable
* avoid mixing refactor and feature logic
* preserve behavior unless explicitly documented
* maintain version consistency

---

## Step 7 — Validation

After refactoring:

* validate affected commands using:

```bash
kcspoc <command>
```

* confirm behavior matches pre-refactor expectations
* document any intentional deviations

---

## Guardrails

* Refactor work must never change release behavior
* Refactor work must never be done on stable branches
* If behavior changes, STOP and reclassify the work