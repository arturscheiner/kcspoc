# kcspoc – Short-term TODOs

This file tracks short-term improvements for upcoming patch releases.
Items here are expected to be promoted to GitHub Issues or removed once completed.

## Installer / Release
- [ ] Align all version references to v0.5.4
- [ ] Improve install.sh staging cleanup
- [ ] Validate install vs upgrade messaging
- [ ] Ensure .install-state is always written atomically

## Developer Tooling
- [ ] Finalize helper scripts under .scripts/
- [ ] Add safety checks for working on release branches
- [ ] Add script to prepare next patch release

## kcspoc config
- [ ] Add configuration to detect and fix kubectl context
- [ ] Reorder config file to have the most important information first as well group related information together

## kcspoc check
- [ ] Add message to inform the operator that the kcspoc namespace will be created if it doesn't exist when running deep-check and connectivity-check
- [ ] Do not remove kcspoc namespace when/after running deep-check and connectivity-check (only when running destroy)

## kcspoc prepare
- [ ] Remove kcs namespace creation from the prepare as it is being done in the deploy command
- [ ] For each step in prepare, first detect if the dependecies exists on the cluster and if exist check it as present if it doesn't exist ask the operator if he wants to install it and show the exact command that kcspoc will run to install it

## kcspoc deploy
- [ ] Add message to inform the operator that the kcspoc namespace will be created if it doesn't exist

## kcspoc destroy
- [ ] Add message to inform the operator that the kcspoc namespace is being deleted

## Documentation
- [ ] Update README with new install flow description
- [ ] Clarify stable vs development branches
