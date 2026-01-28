# SCHEMA: KCS READINESS AUDIT (PLAIN TEXT)

Produce a simple, terminal-friendly text document. 

## MANDATORY DATA POINTS
1. **AUDIT SUMMARY**: Verdict [PASS/FAIL/WARN] and short rationale.
2. **DETAILED EVALUATION**: (Use bullet points, NO TABLES)
   - Control Plane: Version, CRI, Architecture.
   - Hardware: Total resources and node headroom.
   - Nodes: Per-node Kernel/eBPF/Headers.
   - Utilities: SC, Ingress, cert-manager, connectivity.
3. **CRITICAL GAPS**: Numbered list of items.
4. **CONFIGURATION TIPS**: Descriptive text with command examples.

## FORMATTING RULES
- Use `:: Header ::` style.
- Use `*` or `-` for lists.
- Keep lines under 80 characters.
- Use indentation for hierarchy.
