# Behavior Changes (0.6-dev only)

These are philosophical changes and MUST NOT be backported.

- kcspoc no longer assumes an empty cluster
- prepare becomes reuse-first
- Label mismatches are not fatal if functional checks pass
- deploy always validates resources
- Silent failures become impossible
