---
description: Feature Development (BLOCKED ON RELEASE BRANCH)
---

# Purpose
This workflow exists to **explicitly prevent feature development** while operating on the `release/0.5` branch.

Feature work is **not allowed** during stabilization or patch phases.

---

## Step 1 — Detect Current Branch

Confirm the active branch:
```bash
git branch --show-current

## Step 2 — Enforce Guardrail
If the current branch is release/0.5:
- STOP execution immediately.
- Clearly explain:
  - Feature development introduces risk and instability.
  - The release/0.5 branch is restricted to bugfixes and stabilization.

- Provide clear guidance:
  git checkout main

## Step 3 — Redirect the Operator
Explain that feature work must:
- Be planned in the development roadmap
- Be executed from the main branch
- Follow the /feature workflow defined for development mode

## Guardrails
- Never perform feature work on a release branch.
- Never bypass this restriction.
- If feature work is requested on a release branch, always redirect to main.