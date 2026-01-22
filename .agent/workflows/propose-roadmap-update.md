---
description: Propose Roadmap Update
---

Propose a structured update to the kcspoc roadmap, ensuring that changes are applied **only to the correct branch and roadmap file**.

This workflow is **branch-aware** and enforces strict separation between:
- stabilization / patch work (release/0.5)
- development / future work (main)

---

## Step 1 — Understand the Requirement
- Summarize the requirement in one sentence.
- Classify it into **exactly one** category:
  - bugfix
  - patch
  - installer
  - docs
  - feature
  - refactor
  - breaking
  - future

---

## Step 2 — Determine Target Branch

Use this mapping:

- bugfix / patch / installer / docs → **release/0.5**
- feature / refactor / breaking / future → **main**

---

## Step 3 — Detect Current Branch

Run:
```bash
git branch --show-current

## Step 4 — Branch Guardrail (MANDATORY)

If the current branch is NOT release/0.5:

- STOP execution immediately.
- Clearly explain:
  -why the requirement belongs to release/0.5
  -why continuing on the current branch would be incorrect or risky
- Propose the exact corrective command:
  git checkout release/0.5
- Ask for explicit user confirmation before continuing.

❗ Do NOT proceed without confirmation.

## Step 5 — Apply Roadmap Update (Release Scope)

Only after branch alignment:

- Target roadmap file:
  .roadmap/0.5.x-stabilization.md
- Propose the roadmap change as a structured diff or patch.
- Explain the intent and impact briefly.
- Wait for explicit approval before applying any change.

## Guardrails

- Never modify roadmap files while on the wrong branch.
- Never auto-switch branches.
- Never introduce features, refactors, or breaking changes into release roadmaps.
- If classification is ambiguous, STOP and ask for clarification.
