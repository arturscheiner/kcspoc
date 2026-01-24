---
description: Feature Development
---

## Purpose

Guide the design and implementation of **new user-visible capabilities** in kcspoc.

A feature introduces **new behavior, options, or workflows** and is allowed **only on the development branch (`main`)**.

This workflow enforces architectural discipline, MVC alignment, and clear separation from refactors and bugfixes.

---

## Step 1 — Branch Validation

Determine the active branch:

```bash
git branch --show-current
```

* If the branch is NOT `main`, STOP.
* Feature development is never allowed on `release/*` branches.

---

## Step 2 — Mandatory Work Classification

Confirm explicitly:

* This work is a **feature** (new user-visible behavior)

Provide a short justification explaining:

* what new capability the user gains
* why this is not a bugfix
* why this is not a refactor

If classification is unclear, STOP.

---

## Step 3 — Feature Definition

Clearly describe:

* the problem being solved
* the target user or operator
* the expected behavior and outcomes

This description must be understandable without reading code.

---

## Step 4 — MVC Impact Mapping

Declare how the feature affects each layer:

* **Controller**: new command, flag, or execution path
* **Service**: new or extended business logic
* **Model**: new or updated domain/state representation
* **View**: new or modified user-facing output

At least one layer must change. If not, STOP and reclassify.

---

## Step 5 — Architectural Fit Check

Validate that the feature:

* fits within the planned MVC structure
* does not introduce cross-layer coupling
* does not bypass service or model layers

If the feature requires structural reorganization first, STOP and redirect to `/refactor`.

---

## Step 6 — Implementation Plan

Before coding, outline:

* files/modules to be created or modified
* new flags, commands, or config entries
* potential backward-compatibility concerns

Do not write code yet.

---

## Step 7 — Implementation Rules

During implementation:

* keep feature commits isolated from refactors
* prefer incremental, testable changes
* maintain consistency with existing CLI patterns
* update documentation or help output as needed

---

## Step 8 — Validation

After implementation:

* validate the feature via:

```bash
kcspoc <command>
```

* confirm existing behavior remains unchanged
* document the feature if user-facing

---

## Guardrails

* Never implement features on stable branches
* Never mix feature and refactor work in the same commit
* If scope expands unexpectedly, STOP and reassess
