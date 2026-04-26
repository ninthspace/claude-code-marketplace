# Coverage Matrix: Deliverable Generation

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Epic**: docs/epics/31-04-epic-deliverable-generation.md
**Date**: 2026-04-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 11 | Citation format | Every concrete finding cited as `file:line (symbol)`. Non-negotiable. | Every concrete finding in the table cites a location in `file:line (symbol)` format (e.g. `src/auth/login.ts:42 (authenticate)`) | Story 3 | `[unit]` | |
| 11 | Citation format | (same) | (must NOT) Citations must NOT quote actual secret values, even for security-hygiene findings — citation is the location only | Story 3 | `[unit]` | |
| 12 | Numbered deliverable | Output to `docs/audits/{nn}-audit-{slug}.md` via shared Numbering. | Output is written to `docs/audits/{nn}-audit-{slug}.md` where `{nn}` is assigned by the shared Numbering procedure | Story 1 | `[unit]` | |
| 12 | Numbered deliverable | (same) | Skill creates `docs/audits/` directory if it doesn't exist | Story 1 | `[unit]` | |
| 13 | Deliverable structure | Deliverable structure: header (date, commit SHA, scope), executive summary (max 10 bullets), architectural mental model, findings table (30–80 rows: ID, Category, Citation, Severity, Effort, Description, Recommendation), Top 5 priorities (concrete refactor outlines), Quick wins (checklist), "Things that look bad but are actually fine" (required), Open questions. | Deliverable contains header section with date, commit SHA, and declared scope | Story 2 | `[unit]` | |
| 13 | Deliverable structure | (same) | Deliverable contains executive summary section (max 10 bullets ranked by impact) | Story 2 | `[unit]` | |
| 13 | Deliverable structure | (same) | Deliverable contains architectural mental model section (1–2 paragraphs) | Story 2 | `[unit]` | |
| 13 | Deliverable structure | (same) | Deliverable contains findings table with columns: ID, Category, Citation, Severity, Effort, Description, Recommendation | Story 2 | `[unit]` | |
| 13 | Deliverable structure | (same) | Deliverable contains "Top 5 priorities" section with concrete refactor outlines | Story 2 | `[unit]` | |
| 13 | Deliverable structure | (same) | Deliverable contains "Quick wins" section as a checklist | Story 2 | `[unit]` | |
| 13 | Deliverable structure | (same) | Deliverable contains "Things that look bad but are actually fine" section (required, non-negotiable) | Story 2 | `[unit]` | |
| 13 | Deliverable structure | (same) | Deliverable contains "Open questions" section | Story 2 | `[unit]` | |
| 14 | Severity and effort scales | Severity: Critical/High/Medium/Low. Effort: S/M/L. | Findings table uses Critical/High/Medium/Low for severity values | Story 4 | `[unit]` | |
| 14 | Severity and effort scales | (same) | Findings table uses S/M/L for effort values | Story 4 | `[unit]` | |
| 15 | No-rewrites rule | No-rewrites rule (non-negotiable): recommendations describe scoped changes only. | Recommendations describe scoped changes only | Story 5 | `[manual]` | |
| 15 | No-rewrites rule | (same) | (must NOT) Recommendations must NOT include phrases like "rewrite", "replace entirely", or full-module replacement guidance | Story 5 | `[manual]` | |
| 16 | No-padding rule | No-padding rule (non-negotiable): empty categories removed entirely; no "Nothing material" placeholders. | Empty dimension sections are removed entirely from the deliverable | Story 5 | `[manual]` | |
| 16 | No-padding rule | (same) | (must NOT) Deliverable must NOT contain "Nothing material" placeholders or filler content for empty categories | Story 5 | `[unit]` | |
| 17 | Scoped audit consistency | Scoped audit consistency: deliverable structure stays identical when scope hint is provided; declared scope recorded in header; out-of-scope dimensions omitted. | When scope hint is provided, deliverable header records `**Scope**: <hint>` | Story 6 | `[unit]` | |
| 17 | Scoped audit consistency | (same) | Out-of-scope dimensions are omitted from the deliverable (no "Nothing material" placeholders) | Story 6 | `[unit]` | |
| 17 | Scoped audit consistency | (same) | Deliverable structure stays identical to a full-sweep deliverable (same sections, just fewer dimensions) | Story 6 | `[unit]` | |
| 20 | Effort aggregates | Executive summary includes effort aggregates (e.g. `Effort: S×12, M×7, L×3`). | Executive summary includes a line summarising effort totals (e.g. `Effort: S×12, M×7, L×3`) | Story 7 | `[unit]` | |
