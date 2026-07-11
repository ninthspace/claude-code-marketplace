# Coverage Matrix: status Tracking Dashboard

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Epic**: docs/epics/34-01-epic-status-tracking-dashboard.md
**Date**: 2026-06-02

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Validation-first | The value is unproven. The first story is a prototype evaluated against "does the full-picture document materially help tracking versus the inline narrative?" Full build is gated on that outcome. | A prototype standalone HTML dashboard is produced from a real `status` scan and evaluated against "does the full-picture document materially help tracking versus the inline narrative?" | Story 1 | `[manual]` | ✓ |
| 2 | Validation-first | (as above — "Full build is gated on that outcome.") | The full build must NOT proceed until the prototype evaluation records a go decision | Story 1 | `[manual]` | ✓ |
| 3 | Standalone full-picture HTML document | `cpm2:status` can *additionally* generate a self-contained standalone HTML document presenting the comprehensive project picture: full epic/story completion grid, in-progress + blocked panel, RAG indicators, recent git activity, and recommended next steps. HTML-native ... | `cpm2:status` can additionally generate a self-contained full-picture HTML document presenting epic/story completion grid, in-progress + blocked panel, RAG indicators, recent git activity, and recommended next steps, using the Spec 1 shared template | Story 2 | `[manual]` | ✓ |
| 4 | Standalone full-picture HTML document / Build-free output | (HTML-native, self-contained) / Each document is a single self-contained file (inline CSS/SVG ...) — no framework, bundler, server, or build step. | The document is self-contained — a single file with no external script/CSS references — and uses the shared template, not a forked stylesheet | Story 2 | `[integration]` | ✓ |
| 5 | Standalone full-picture HTML document | ... synthesised directly from the same read-only scan, no Markdown intermediate ... The HTML holds the detail the one-screen narrative intentionally omits. | The document's completion counts agree with the data the stdout narrative reports | Story 2 | `[integration]` | ✓ |
| 6 | status inline output unchanged | `cpm2:status` continues to generate its existing terse stdout narrative as the default, primary behaviour — no regression. | `cpm2:status` still produces its stdout narrative; the default path is unchanged | Story 2 | `[integration]` | ✓ |
| 7 | Saved on request, ephemeral by default | The HTML document isn't persisted unless the user asks; otherwise it's regenerated on demand, matching `status`'s stateless nature. | The HTML document must NOT be saved unless the user asks (ephemeral default) | Story 2 | `[manual]` | ✓ |
