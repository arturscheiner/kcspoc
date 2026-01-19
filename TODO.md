# kcspoc – Patch Release TODOs

This file tracks immediate, short-term improvements for the `v0.5.x` release line.
Items listed here are actionable and intended for upcoming patch releases.

## 🚀 Installer & Release (User-Facing)
- [ ] Implement atomic writing for `~/.kcspoc/bin/.install-state` to prevent file corruption during interrupted installs.
- [ ] Audit and refine installer messaging to clearly distinguish between "Fresh Install" and "Upgrade" flows.
- [ ] Ensure `install.sh` performs a rigorous cleanup of the `temp/` staging directory even if extraction or copy fails.

## ⚙️ Operator Experience (User-Facing)
- [ ] Add `kubectl` context detection to `kcspoc config` with suggestions for fixing invalid configurations.
- [ ] Refactor `kcspoc check` to inform the operator when the `kcspoc` management namespace is being created.
- [ ] Change `kcspoc check` behavior to persist the `kcspoc` namespace after execution (defer deletion to `kcspoc destroy`).
- [ ] Implement infrastructure dependency detection in `kcspoc prepare` to identify existing cluster components before prompting for installation.
- [ ] Add clear "Namespace Deletion" status messages to the `kcspoc destroy` command.

## 🛠️ Maintainer & Internal (Internal)
- [ ] Reorganize the `~/.kcspoc/config` file structure to group related variables and prioritize critical configuration at the top.
- [ ] Remove redundant namespace creation logic from `kcspoc prepare` and centralize it within the `deploy` command.
- [ ] Enhance `.scripts/` helper tools with automated CHANGELOG comparison link verification (nice-to-have).
