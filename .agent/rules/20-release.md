---
trigger: always_on
---

Release and versioning rules:

- Semantic Versioning is mandatory.
- Patch releases (x.y.Z) must only include bug fixes or safe internal changes.
- Stable versions must be published as GitHub Releases.
- Git tags (vX.Y.Z) represent official releases.
- install.sh must always install the latest stable GitHub Release.
- install.sh must never download code from the main branch.
