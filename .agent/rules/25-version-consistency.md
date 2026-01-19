---
trigger: always_on
---

Version consistency rules for kcspoc:

- The project version must be defined consistently across the repository.
- Any version bump (release or pre-release) must update all version references.

Mandatory version references include (but are not limited to):
- CHANGELOG.md
- README.md
- CLI version output (if applicable)
- Any VERSION variable or constant in scripts

Rules:
- The agent must never bump a version partially.
- If a version bump is requested, the agent must identify and update all version references.
- If the agent is unsure where versions are defined, it must ask before proceeding.
