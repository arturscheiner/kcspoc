# SCHEMA: KCS READINESS AUDIT (HTML)

Produce a complete, self-contained HTML 5 document. 
Use clean embedded CSS for a professional look (Kaspersky-themed branding: Green, White, Black).

## MANDATORY DATA POINTS
1. **AUDIT SUMMARY**: Verdict [PASS/FAIL/WARN] and short rationale.
2. **DETAILED EVALUATION**: (Use HTML Tables)
   - Cluster Identity: Version, Architecture, CRI, Helm.
   - Resource Capacity: Total CPU/RAM/Disk vs Minimums.
   - Node Breakdown: Per-node resources, Kernel version, eBPF/Headers status.
   - Infrastructure: StorageClass, Ingress, cert-manager, MetalLB, connectivity.
3. **CRITICAL GAPS**: Unordered list of blocking issues.
4. **CONFIGURATION TIPS**: Code blocks with specific commands.

## VISUAL STYLE
- Success: Green background for Pass.
- Failure: Red background for Fail.
- Warning: Yellow/Orange for Warm.
- Fonts: Sans-serif (Roboto/Inter).
- Borders: Clean 1px table borders.
