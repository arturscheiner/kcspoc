# SCHEMA: KCS READINESS AUDIT (STRUCTURED JSON)

Produce a valid JSON object. You MUST include ALL keys defined below. 
Do not skip any structural nesting.

```json
{
  "audit_summary": {
    "verdict": "PASS | FAIL | WARN",
    "rationale": "string"
  },
  "evaluation": {
    "cluster_info": {
      "k8s_version": "string",
      "architecture": "string",
      "cri_runtime": "string",
      "helm_version": "string",
      "cni_plugin": "string"
    },
    "resources": {
      "cpu_cores": { "available": number, "required": 12, "status": "PASS|FAIL" },
      "ram_gib": { "available": number, "required": 20, "status": "PASS|FAIL" },
      "disk_gib": { "available": number, "required": 40, "status": "PASS|FAIL" }
    },
    "infrastructure": [
      { "name": "string", "status": "INSTALLED | MISSING", "notes": "string" }
    ],
    "nodes": [
      {
        "name": "string",
        "role": "master | worker",
        "kernel": "string",
        "ebpf_status": "READY | UNKNOWN | INCOMPATIBLE",
        "headers_status": "INSTALLED | MISSING",
        "privileged_required": true
      }
    ]
  },
  "critical_gaps": [
    { "id": "string", "description": "string", "impact": "BLOCKER | WARNING" }
  ],
  "remediation": [
    {
      "title": "string",
      "description": "string",
      "command": "string",
      "category": "NETWORK | STORAGE | SECURITY | ARCH"
    }
  ]
}
```

## VALIDATION RULES
1. **JSON ONLY**: Do not add any text before or after the JSON block.
2. **STRICT HIERARCHY**: Ensure `evaluation` contains `resources`, `infrastructure`, and `nodes`.
3. **NO TRAILING COMMAS**: Ensure valid JSON syntax.
