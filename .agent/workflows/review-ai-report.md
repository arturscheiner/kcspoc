---
description: 
---

## Intent

This workflow reviews **AI-generated kcspoc reports** to ensure they strictly comply
with the kcspoc AI reporting contract and governance model.

It verifies that the AI acted as an **analyst and narrator only**, never as a judge,
evaluator, or source of truth.

This workflow is **read-only** and does not modify code or data.

---

## Inputs Required

The review MUST be performed against the following inputs:

1. `kcs_baseline.json`
2. `environment_evaluation.json`
3. `readiness_checklist.md`
4. The generated AI report (MD, TXT, or HTML)

If any input is missing, STOP.

---

## Step 1 — Role Boundary Validation

Confirm that the AI respected its role:

- Did NOT recompute compliance
- Did NOT override boolean evaluations
- Did NOT infer missing data
- Did NOT introduce new requirements

If any violation is detected, mark as ❌ **Contract Breach**.

---

## Step 2 — Compliance Integrity Check

Verify that:

- All compliance statements match `evaluation.compliant`
- Mandatory failures are clearly labeled as mandatory
- Severity levels are not softened or exaggerated
- Confidence levels are not invented or altered

No reinterpretation is allowed.

---

## Step 3 — Baseline Fidelity Check

Validate that:

- Every requirement mentioned exists in `kcs_baseline.json`
- No undocumented requirement appears
- Official references are preserved or omitted (never invented)

If new requirements appear → ❌ violation.

---

## Step 4 — Remediation Validity Check

Confirm that:

- All remediation suggestions come directly from `remediation.actions`
- No new actions are proposed
- Language remains advisory, not speculative

AI must not act as an architect or decision-maker.

---

## Step 5 — Language & Tone Audit

Check for forbidden language patterns:

- “Likely”, “possibly”, “might indicate”
- “In my assessment”
- “The system should be considered acceptable”

Reports must be:
- Deterministic
- Evidence-backed
- Professional and neutral

---

## Step 6 — Structure & Completeness

Verify required sections exist and are ordered correctly:

1. Executive Summary
2. Key Findings
3. Compliance Breakdown
4. Required Remediations
5. Observations & Notes (only if supported)

Missing or reordered sections must be flagged.

---

## Findings Report

Produce a review summary with:

### ✅ Compliant Aspects
What the AI did correctly.

### ⚠️ Minor Deviations
Non-critical wording or formatting issues.

### ❌ Contract Violations
Clear breaches with:
- Section reference
- Rule violated
- Why it matters

---

## Guardrails

- Do NOT re-evaluate KCS readiness
- Do NOT suggest new requirements
- Do NOT rewrite the report
- Do NOT relax the contract
- Default to strict interpretation

---

## Definition of Done

The review is complete when:
- All contract boundaries are checked
- Violations (if any) are clearly identified
- Trustworthiness of the report is explicitly stated
