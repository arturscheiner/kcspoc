---
trigger: always_on
---

## Intent

This rule defines the **mandatory visual identity and UI consistency contract** for the `kcspoc` CLI.

Any change, refactor, new command, or feature **MUST follow these rules**.
Deviations are not allowed without explicit approval.

This rule applies to **all user-facing output** produced by the View layer.

---

## 1️⃣ Global UI Principles (MANDATORY)

* Output must be **clear, structured, and visually scannable**
* Bright colors MUST be used to guide attention
* Every command execution must feel **predictable and familiar**
* UI output must never be improvised per command

---

## 2️⃣ Application Banner (MANDATORY)

Every command execution MUST start with the standard banner:

```
Kaspersky Container Security PoC Tool - vX.Y.Z
Execution ID: ABC123
====================================================
```

Rules:

* Banner is rendered **once per execution**
* Must include:
  * Tool name
  * Version
  * Execution ID
* Separator line must use `=` characters
* Banner rendering is owned by the **View layer only**

---

## 3️⃣ Section Headings (MANDATORY)

Section headings MUST follow this exact format:

```
:: Section Title ::
----------------------------------------------------------------------------------------------------
```

Rules:

* Heading text must be rendered in **bright orange**
* Separator line must use `-` characters
* Headings are **structural**, not decorative

---

## 4️⃣ Section Description (MANDATORY)

Immediately after a section heading, an optional description MAY be rendered:

```
This wizard generates the ~/.kcspoc/config file.
```

Rules:

* Description text must be rendered in **bright white**
* Used to explain the purpose of the block
* Must be concise (1–2 lines)
* No icons in descriptions

---

## 5️⃣ Action Lines (MANDATORY)

Any operational action (e.g. checking, verifying, creating, updating, upgrading, loading) MUST use the following format:

```
   ⚙ Verifying Cluster Connectivity... [ ✔ ]
```

Rules:

* Must start with the ⚙ (gear) icon
* Action verb must be **explicit and active**
* Ellipsis (`...`) is mandatory before the status
* Status indicator MUST be enclosed in `[ ]`

### Status Symbols

* Success: `[ ✔ ]` (green)
* Failure: `[ ✘ ]` (red)
* Warning: `[ ! ]` (yellow, if applicable)

---

## 6️⃣ Error & Detail Blocks (MANDATORY)

When an action fails, additional context MUST be rendered **below the action line**, indented:

```
   ⚙ Verifying Cluster Connectivity... [ ✘ ]
      Connectivity Error:
      Unable to connect to the server: dial tcp 172.16.1.21:6443: connect: no route to host
```

Rules:

* Details must be indented
* Error title should be concise
* Raw system errors are allowed but must be visually separated

---

## 7️⃣ Command-Specific Identity (ALLOWED, CONTROLLED)

Different commands MAY have different **semantic identities**, but must still respect this rule.

Example:

* `kcspoc config` → wizard-oriented, explanatory, interactive
* `kcspoc check` → diagnostic-oriented, step-by-step verification

Rules:

* The *tone* may differ
* The *structure* must remain identical
* No command may invent a new visual pattern

---

## 8️⃣ MVC Enforcement (CRITICAL)

* Controllers MUST NOT render UI
* Services MUST NOT render UI
* Models MUST NOT render UI
* **All formatting, colors, icons, and layout belong to the View layer**

If UI logic is detected outside View components, the change MUST be rejected.

---

## 9️⃣ Non-Negotiable Guardrails

* Never mix multiple visual styles in the same command
* Never change icons arbitrarily
* Never introduce new colors without updating this rule
* Never bypass View helpers with raw `echo` / `printf`

---

## 10️⃣ Definition of Done (UI Changes)

Any UI-related change is considered complete only if:

* Output follows all rules above
* Visual consistency matches existing commands
* No raw output bypasses the View layer
* Behavior is predictable across executions
