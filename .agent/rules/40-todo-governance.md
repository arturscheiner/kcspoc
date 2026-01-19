---
trigger: always_on
---

# TODO Governance Rule

This project uses TODO.md as a live source of truth for short-term work.

Mandatory behavior:
- Any approved and completed task MUST result in an update to TODO.md.
- The agent must NEVER assume a task is completed unless the user explicitly confirms it.
- After a task is implemented and committed, the agent MUST remind the user to update TODO.md.

Restrictions:
- Do NOT automatically mark TODO items as completed.
- Do NOT add new TODO items unless explicitly requested.
- Do NOT modify TODO.md without user approval.

Expected behavior:
- If a task plan is approved → mention that TODO.md will need to be updated after completion.
- If implementation is finished → prompt the user to run the TODO update workflow.