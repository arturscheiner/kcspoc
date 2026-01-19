---
description: Update kcspoc version consistently across the repository.
---

Steps:
1. Ask for the target version (e.g., v0.5.1, v0.6.0-dev).
2. Locate all existing version references.
3. Update all references consistently.
4. Verify CHANGELOG.md contains an entry for the target version.
5. Report all updated files.

Constraints:
- Do not modify functional code unless version references require it.
- Do not create Git tags or releases.