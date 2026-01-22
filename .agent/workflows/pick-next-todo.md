---
description: Pick Next TODO
---

Purpose:
Help decide which TODO item to work on next, based on impact, complexity, and roadmap alignment.

This workflow is advisory only.
It MUST NOT modify any file or start implementation.

Steps:
1. Read TODO.md.
2. Identify the current branch context:
   - release/* → stabilization & bugfix
   - main → development & roadmap evolution
3. Classify TODO items by:
   - Scope (installer, operator UX, tooling, config, deploy, docs)
   - Risk (low / medium / high)
   - Complexity (low / medium / high)
   - Alignment (current roadmap vs future)
4. Exclude TODOs that do not align with the current branch.
5. Propose:
   - 1 primary TODO to work on today
   - 1 backup TODO (in case the first is blocked)

Output format:
## Context
- Current branch:
- Active roadmap phase:

## Recommended TODO (Primary)
- TODO item:
- Why this one now:
- Expected complexity:
- Risk level:

## Alternative TODO (Backup)
- TODO item:
- Why it’s a good fallback:

## Notes
- Dependencies or prerequisites
- Warnings or suggestions before starting