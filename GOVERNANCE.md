# kcspoc – Project Governance

This document defines **how work is planned, classified, and executed** in the kcspoc repository.
It is the single source of truth for contributors (human or AI) on *how to work* in this project.

---

## 🎯 Core Principles

* **Clarity over speed**: work must be correctly classified before implementation
* **Architecture before features**: structural integrity enables long-term velocity
* **Separation of concerns**: planning, execution, and release are distinct activities
* **Branch discipline**: each branch has a clear purpose
* **No silent automation**: all impactful actions require explicit intent

---

## 🌿 Branch Strategy

### `main`

* Development and evolution branch
* Used for:

  * new features
  * architectural refactors (MVC)
  * roadmap-driven work

### `release/*`

* Stabilization and patch branches
* Used for:

  * bugfixes
  * safety improvements
  * release preparation

No feature or refactor work is allowed on release branches.

---

## 🧠 Work Classification (Mandatory)

Every change must be classified **before any implementation**:

* **Bugfix** — Corrects broken or incorrect behavior
* **Feature** — Introduces new user-visible capability
* **Refactor** — Improves internal structure without intentional behavior change

If classification is unclear, work must STOP until clarified.

---

## 🗺️ Planning Artifacts

### TODO.md

* Short-term, tactical work
* Used primarily on `release/*` branches

### `.roadmap/`

* Strategic and long-term planning
* Used on `main`
* Contains versioned and thematic roadmaps

---

## 🔄 Standard Workflows

### Context & Direction

* `/consult-roadmap` — understand current phase and planning source
* `/pick-next-todo` — select the next appropriate task

### Governance

* `/align-todo-with-roadmap` — ensure planning coherence
* `/propose-roadmap-update` — decide where new ideas belong
* `/consistency-check` — verify repository health

### Execution

* `/refactor` — structural improvements (main only)
* `/feature` — new behavior (main only)
* `/bump-version` — semantic version updates
* `/prepare-release` — finalize a patch release

---

## 🧱 Architectural Direction

kcspoc is transitioning toward a **Model–View–Controller (MVC)** architecture:

* **Controllers**: command routing and orchestration
* **Services**: business logic and workflows
* **Models**: domain state and configuration
* **Views**: user-facing output and messaging

Structural changes must follow the `/refactor` workflow.

---

## 🚨 Guardrails

* No workflow may execute destructive actions without confirmation
* No workflow may modify files unless explicitly approved
* No branch switching without user consent
* No mixing of feature, refactor, and bugfix in the same commit

---

## 🧭 Final Note

This governance exists to:

* reduce cognitive load
* prevent accidental drift
* make collaboration with AI predictable and safe

If in doubt, STOP and consult the roadmap or governance rules.
