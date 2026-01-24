---
description: Consult Roadmap
---

## Purpose

Provide situational awareness about the current project phase, roadmap, and source of truth,
without proposing tasks or performing any actions.

This workflow is informational only.

---

## Step 1 — Detect Current Branch

Determine the active branch:

```bash
git branch --show-current
```

---

## Step 2 — Determine Active Planning Source

Based on the branch:

* If branch is `main`:

  * The active planning source is `.roadmap/`
  * The project is in **development / evolution mode**
  * Structural changes, refactors, and new features may be planned

* If branch matches `release/*`:

  * The active planning source is `TODO.md`
  * The project is in **stabilization / patch mode**
  * Only safe bugfixes and improvements are expected

---

## Step 3 — Explain Current Phase

Clearly explain to the user:

* which phase the project is in
* what kind of work is appropriate
* what kind of work is discouraged

Do not suggest specific tasks.

---

## Step 4 — Point to Next Actions

Suggest *one or more* of the following commands, without executing them:

* `/pick-next-todo` — to choose a task aligned with the current phase
* `/refactor` — if on `main` and architectural work is intended
* `/feature` — if on `main` and new behavior is desired
* `/prepare-release` — if on a release branch and closing a patch

---

## Guardrails

* Do not modify files
* Do not switch branches
* Do not execute shell commands beyond inspection
* Do not infer tasks automatically
