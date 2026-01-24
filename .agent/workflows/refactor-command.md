---
description: Refactor an existing kcspoc command to improve internal structure and enforce the MVC architecture.
---

# /refactor-command

Refactor an existing kcspoc command to improve internal structure and enforce the MVC architecture.

---

## Usage

```text
/refactor-command <command>
```

Examples:

```text
/refactor-command config
/refactor-command check
/refactor-command logs
```

---

## Intent

This workflow governs **pure refactoring work** on kcspoc.

Refactoring is defined as improving **internal structure, clarity, and maintainability**, with behavior preserved unless explicitly allowed by governance rules.

Refactors are expected to be applied **only on the development branch (`main`)** and primarily target the upcoming **v0.6.0+ MVC architecture**.

---

## Step 1 — Branch Validation (MANDATORY)

Confirm the current branch:

```bash
git branch --show-current
```

Rules:

* If the branch is not `main`, STOP.
* Refactors are **never allowed** on `release/*` branches.

---

## Step 2 — Refactor Qualification Check

Confirm that this work:

* does **not** introduce new CLI flags or commands
* does **not** remove or rename existing flags
* does **not** change the command purpose
* preserves user-facing behavior unless explicitly stated
* focuses on structure, boundaries, or internal organization

If any of the above are violated:
STOP and redirect to `/feature` or `/bugfix`.

---

## Step 3 — Target Definition (MANDATORY)

You are refactoring **ONLY** the following command:

```text
kcspoc <command>
```

Scope:

* Source file: `lib/cmd_<command>.sh`
* No other commands may be modified unless strictly required by shared infrastructure.

---

## Step 4 — Architectural Motivation

Explicitly describe:

* the current structural problem in `cmd_<command>.sh`
* why the current layout or coupling is harmful
* how the refactor improves maintainability, testability, or extensibility

Refactors without architectural justification are not allowed.

---

## Step 5 — MVC Impact Declaration

Declare which MVC layers are affected:

* **Controller**: orchestration, argument parsing, flow control
* **Service**: business logic coordination
* **Model**: kubectl, filesystem, environment access
* **View**: output, formatting, user interaction

At least one layer must be meaningfully improved.

---

## Step 6 — Mandatory MVC Rules

The following rules are NON-NEGOTIABLE:

### cmd file

`lib/cmd_<command>.sh` MUST remain and be reduced to a thin forwarder:

```bash
cmd_<command>() {
    <command>_controller "$@"
}
```

No logic is allowed in `cmd_<command>.sh`.

---

### Controller

* Orchestrates flow
* Parses arguments
* Calls services
* MAY call views
* MUST NOT call kubectl directly

### Service

* Contains business logic
* Coordinates models
* MUST NOT print output

### Model

* Wraps kubectl, filesystem, env
* MUST NOT print output

### View

* Handles ALL user-facing output
* MAY prompt for input
* MUST NOT contain business decisions

---

## Step 7 — Refactor Plan (No Code Yet)

Before implementation, outline:

* files to be created or modified
* logic to be moved per layer
* legacy structures to be deprecated

No code may be written before this plan is clear.

---

## Step 8 — Execution Rules

During implementation:

* keep commits small and reviewable
* do not mix refactor and feature logic
* improvements are allowed in `main` if:

  * incremental
  * non-breaking
  * architecture-aligned
* document any intentional behavior changes

---

## Step 9 — Validation

After refactoring:

* validate using:

  ```bash
  kcspoc <command>
  ```
* confirm behavior matches pre-refactor expectations
* clearly document any deviations

---

## Guardrails

* Refactor work must never be done on stable branches
* Refactor work must never silently change external behavior
* If scope drifts, STOP and ASK before proceeding
