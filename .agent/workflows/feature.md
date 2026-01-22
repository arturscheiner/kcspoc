---
description: Feature Development (Development Mode)
---

Steps:
1. Ask for the feature description.
2. Propose a minimal design aligned with existing architecture.
3. Implement the feature incrementally.
4. Highlight potential backward compatibility concerns.
5. Suggest a CHANGELOG.md entry (do not apply automatically).

Constraints:
- Do not modify install.sh unless explicitly requested.
- Do not assume the feature will be released immediately.

## Purpose
Guide the design and implementation of **new features** while operating on the `main` branch.

This workflow ensures features are planned, scoped, and aligned with the development roadmap.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

If the branch is NOT main, STOP and instruct the operator to switch to main.


## Step 2 — Feature Definition

- Summarize the feature in one sentence.
- Identify the primary motivation (user value or technical need).
- Classify the feature:
  - user-facing
  - internal
  - architectural
  - tooling

## Step 3 — Roadmap Alignment

- Check alignment with:
  - .roadmap/0.6.0-dev.md
  - .roadmap/future-capabilities.md
- If not aligned, propose a roadmap update instead of immediate implementation.

## Step 4 — Scope & Risk Assessment

- Identify impacted components or commands.
- Highlight potential risks:
  - breaking changes
  - backward compatibility
  - installer impact
- Determine if a feature flag or staged rollout is required.

## Step 5 — Implementation Proposal
Propose:
- A high-level implementation plan
- Files likely to be touched
- Testing and validation strategy

Ask for explicit confirmation before coding.

## Guardrails
- Never introduce feature work into release branches.
- Always validate roadmap alignment before implementation.
- If the feature implies breaking behavior, escalate explicitly.