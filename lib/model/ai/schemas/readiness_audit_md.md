# SCHEMA: KCS READINESS AUDIT (MARKDOWN)

Produce a professional Markdown document using GFM (GitHub Flavored Markdown).

## MANDATORY DATA POINTS
1. **AUDIT SUMMARY**: Verdict [PASS/FAIL/WARN] and short rationale.
2. **DETAILED EVALUATION**: (Use Markdown Tables)
   - Cluster Identity: Version, Architecture, CRI, Helm.
   - Resource Capacity: Total Metrics vs Requirements.
   - Node Matrix: Per-node metrics, Kernel, eBPF, Headers.
   - Infrastructure Checklist: Component status (SC, Ingress, cert-manager, etc).
3. **CRITICAL GAPS**: Bulleted list of blockers.
4. **CONFIGURATION TIPS**: Triple-backtick code blocks.

## FORMATTING RULES
- Use `##` and `###` headers.
- Use `**bold**` for results.
- Use standard Markdown tables `| Column | Column |`.
