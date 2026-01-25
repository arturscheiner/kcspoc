---
description: Performs a UI/UX compliance review for a specific kcspoc command
---

## Intent

This workflow performs a **UI/UX compliance review** for a specific `kcspoc` command,
ensuring it strictly follows the visual identity and interaction rules defined in:

* `.agent/rules/40-ui-visual-identity.md`

It is a **read-only, analytical workflow**.
No code execution or modification is allowed.

---

## Step 1 — Command Selection

Ask the user which command should be reviewed.

Examples:

* `kcspoc config`
* `kcspoc check`
* `kcspoc prepare`
* `kcspoc deploy`

If no command is provided, STOP.

---

## Step 2 — Scope Definition

Clarify the scope of the review:

* Only user-facing output
* Only the selected command
* Only UI structure, colors, icons, and messaging
* Ignore internal logic unless it affects UI rendering

Do NOT evaluate business logic correctness.

---

## Step 3 — Visual Identity Checklist

Review the command output against the following mandatory checkpoints:

### 3.1 Banner Compliance

* Is the standard kcspoc banner rendered once?
* Does it include:

  * Tool name
  * Version
  * Execution ID
* Is the separator line using `=` characters?

### 3.2 Section Heading Compliance

* Are section headers rendered using:

  ```
  :: Section Title ::
  ----------------------------------------------------------------------------------------------------
  ```
* Is the heading text using **bright orange**?
* Are headings used only for structural blocks?

### 3.3 Section Description Compliance

* Is there a short explanation after headings where appropriate?
* Is the description rendered in **bright white**?
* Are descriptions concise and icon-free?

### 3.4 Action Line Compliance

* Are all operational steps rendered as action lines?
* Do action lines follow the exact format:

  ```
     ⚙ Action Description... [ ✔ | ✘ | ! ]
  ```
* Are action verbs explicit (Checking, Verifying, Creating, etc.)?
* Is the ellipsis (`...`) present before the status?

### 3.5 Status Indicator Compliance

* Are success, failure, and warning symbols correct?
* Are colors consistent with the rule?

### 3.6 Error & Detail Block Compliance

* On failures, are details rendered below the action line?
* Are error details indented?
* Is raw error output visually separated from status lines?

---

## Step 4 — MVC Boundary Validation (UI Perspective)

Verify that:

* No UI formatting appears in Controllers
* No UI formatting appears in Services
* No UI formatting appears in Models
* All UI rendering is delegated to the View layer

If violations exist, list them explicitly.

---

## Step 5 — Findings Report

Produce a structured report with the following sections:

### ✅ Compliant Elements

List aspects that correctly follow the visual identity.

### ⚠️ Minor Inconsistencies

List deviations that do not break UX but should be corrected.

### ❌ Violations

List clear rule violations with:

* File name
* Function or block
* Rule reference (from 40-ui-visual-identity)

---

## Step 6 — Improvement Suggestions (Optional)

If violations are found, suggest:

* Which View helper should be used or created
* How to refactor the output to match the rule
* Whether the issue is best solved in View, Service, or Controller

Suggestions must be concrete and minimal.

---

## Guardrails

* Do NOT execute the command
* Do NOT modify code
* Do NOT invent new UI patterns
* Do NOT relax or reinterpret the rule
* If uncertain, default to the stricter interpretation

---

## Definition of Done

This workflow is complete when:

* All relevant UI aspects are reviewed
* Findings are clearly categorized
* The output references the visual identity rule explicitly
