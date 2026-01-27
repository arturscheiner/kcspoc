---
description: This workflow governs bugfix work in the kcspoc project.
---

## Intent

This workflow governs **bugfix work** in the `kcspoc` project.

A bugfix is defined as a change that:

* Corrects incorrect behavior
* Fixes regressions
* Resolves errors, crashes, or incorrect output
* Improves correctness without changing intended functionality

Bugfixes are allowed on **both development (`main`) and release (`release/*`) branches**, with strict rules depending on the branch.

---

## Step 1 — Branch Validation

Identify the current branch:

```bash
git branch --show-current
```

Rules:

* If on `release/*`, only **patch-level fixes** are allowed
* If on `main`, broader internal fixes are allowed
* If on any other branch, STOP

---

## Step 2 — Bug Qualification Check

Confirm that the issue qualifies as a bugfix:

* The current behavior is incorrect or broken
* The expected behavior is already defined or documented
* No new CLI flags or commands are introduced
* No architectural refactors are included

If the change introduces new behavior, STOP and redirect to `/feature` or `/refactor`.

---

## Step 3 — Scope Declaration

Explicitly state:

* What is broken
* Where the bug occurs (command, file, function)
* How it manifests (error message, wrong output, crash)
* Which users or flows are affected

---

## Step 4 — Impact & Risk Assessment

Declare:

* Whether the fix affects user-facing behavior
* Whether the fix affects data, state, or cluster resources
* Whether the fix is safe for stable branches

If the risk is unclear on `release/*`, STOP.

---

## Step 5 — Implementation Rules

During implementation:

* Keep changes minimal and localized
* Avoid refactors unless strictly required
* Preserve existing UI patterns and visual identity
* Follow MVC boundaries

On `release/*` branches:

* Do NOT modify View structure
* Do NOT introduce new helper abstractions
* Do NOT change output wording unless fixing a typo or incorrect message

---

## Step 6 — Validation

Validate the fix by:

* Reproducing the bug before the fix
* Verifying the bug no longer occurs
* Running the affected command(s):

```bash
kcspoc <command>
```

If applicable, test both success and failure paths.

---

## Step 7 — Commit Message Convention

Use the following format:

```text
fix(<scope>): <concise description>
```

Examples:

* `fix(config): handle empty kubectl context gracefully`
* `fix(check): prevent namespace deletion during diagnostics`

---

## Guardrails

* Never mix bugfix and refactor in the same change
* Never introduce new features under a bugfix
* Never relax validation or safety checks
* If the fix requires architectural changes, STOP and escalate

---

## Definition of Done

A bugfix is complete when:

* The incorrect behavior is resolved
* No new behavior is introduced
* Existing workflows and commands still function correctly
* The change respects branch and UI constraints
