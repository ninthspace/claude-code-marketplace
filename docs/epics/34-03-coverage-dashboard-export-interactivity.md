# Coverage Matrix: Dashboard Export & Interactivity

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Epic**: docs/epics/34-03-epic-dashboard-export-interactivity.md
**Date**: 2026-06-02

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Interactive affordances (optional enhancement) | Where it adds value, the HTML document offers copy-as-prompt / copy-as-JSON export turning a selection (e.g. "next: `/cpm2:do docs/epics/05-…`") into copy-pasteable text — the article's "stay in the loop" pattern. | When present, an export action produces a valid, copy-pasteable prompt / well-formed JSON | Story 1 | `[integration]` | |
| 2 | Build-free output | Each document is a single self-contained file (inline CSS/SVG, and inline vanilla JS only where interactive) — no framework, bundler, server, or build step. | Export uses inline vanilla JS only — no external script, framework, or build artifact | Story 1 | `[integration]` | |
| 3 | Read-only, export-only behaviour | The document never writes back to epic docs; the only way state leaves it is an export. Mutation of epic docs stays exclusively with `cpm2:do`. | No document interaction writes back to any source doc (read-only/export-only) | Story 1 | `[integration]` | |
| 4 | Interactive affordances (optional enhancement) | (copy-as-prompt / copy-as-JSON export turning a selection into copy-pasteable text) | Clicking export in a browser copies the expected content | Story 1 | `[manual]` | |
