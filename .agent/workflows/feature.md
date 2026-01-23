---
description: Feature Development (Development Mode)
---

# Workflow: Feature (Development / MVC Mode)

## Purpose
Guide the design and implementation of **meaningful features** in the `main` branch for kcspoc v0.6.0+.

A feature represents a **new capability, flow, or structural evolution** of the product — not a minor tweak or patch.

---

## Step 1 — Validate Branch and Intent
Confirm the current branch:
  git branch --show-current
If the branch is NOT main, STOP and explain that features must be developed on the development branch.

## Step 2 — Validate Feature Scope
Before proceeding, confirm that this proposal:
  - introduces new behavior or capability
  - affects one or more CLI commands in a meaningful way
  - requires coordination across MVC layers
If the change is:
  - small
  - localized
  - purely internal
  - cosmetic

STOP and redirect to a refactor or task-level change.

## Step 3 — Roadmap Alignment
Check alignment with:
  - .roadmap/0.6.0-dev.md
  - .roadmap/principles.md
If the feature is not represented:
  - STOP
  - Propose a roadmap update via /propose-roadmap-update

No feature should be implemented without roadmap alignment.

## Step 4 — MVC Impact Analysis
Explicitly describe how the feature affects each layer:
  - Controller: command flow and orchestration changes
  - Service: business logic or rules introduced
  - Model: new or modified domain/state abstractions
  - View: user-facing messages, prompts, or output
If any layer is bypassed or unclear, STOP and redesign.

## Step 5 — Implementation Plan (High Level)
Before writing code, outline:
  - files to be created or modified per layer
  - new responsibilities introduced
  - potential risks or breaking changes
Do NOT write code yet.

## Step 6 — Execution Rules
During implementation:
  - respect MVC boundaries strictly
  - avoid shortcuts between layers
  - prefer clarity over cleverness
  - refactor existing code when necessary to preserve architecture

## Step 7 — Validation
After implementation:
  - validate behavior exclusively via:
  - kcspoc <command>
  - observe user-facing behavior
  - ensure no regressions in flow or UX

## Guardrails
  - Never implement features on release branches
  - Never bypass MVC layers
  - Never mix feature work with patch or bugfix work
