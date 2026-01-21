# Future Capabilities (Exploratory)

This document captures potential future capabilities for kcspoc.

These items are:
- Not commitments
- Not scheduled
- Not guaranteed
- Not tied to a specific release

They exist to:
- Capture valid ideas observed during real PoCs
- Provide long-term direction hints
- Prevent future ideas from polluting TODO.md or active roadmaps

Any capability listed here requires explicit approval before becoming a roadmap item.

---

## 🧠 Operator Intelligence & Reporting

Potential capabilities related to insight generation and reporting.

Examples:
- Structured post-deployment reports (environment, readiness, risks)
- Exportable summaries (Markdown, JSON)
- “PoC Health Report” after deploy or check
- Comparison between expected vs detected cluster state

---

## 🤖 AI-Assisted Workflows

Exploratory ideas involving AI or automated reasoning.

Examples:
- Automatic analysis of kcspoc logs
- Suggestions based on failed checks
- AI-assisted incident or PoC analysis
- Guided troubleshooting explanations

Constraints:
- AI must never hide information
- AI output must be explainable and optional

---

## 🎓 Educational & Guided Mode

Capabilities focused on teaching and clarity.

Examples:
- Step-by-step guided PoC execution
- Explanations of why checks exist
- Educational output for first-time users
- “Explain this failure” mode

---

## 🔎 Advanced Validation & Drift Detection

Capabilities around continuous validation.

Examples:
- Detect configuration drift after deployment
- Warn if cluster state diverges from validated PoC state
- Periodic re-validation mode

---

## 📊 Observability & Visibility

Capabilities related to deeper visibility.

Examples:
- Extended metrics collection (non-invasive)
- Better logs structuring
- Timeline-style execution summaries

---

## 🔌 Extensibility (Carefully Scoped)

Ideas related to extension without compromising simplicity.

Examples:
- Optional hooks
- Profile-based execution (strict vs permissive)
- External validation adapters

Constraints:
- No plugin system without explicit approval
- Bash-first principle must be preserved

---

## 🚫 Explicit Non-Goals

The following are explicitly not goals unless the roadmap changes:

- Rewriting kcspoc in another language
- Turning kcspoc into a long-running daemon
- Managing production clusters
- Replacing official Kaspersky tooling
