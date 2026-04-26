# Deliverable Generation

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Date**: 2026-04-25
**Status**: Pending
**Blocked by**: Epic 31-03-epic-sweep-and-tooling

## Numbered output via shared Numbering
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: #12 (numbered deliverable)

**Acceptance Criteria**:

- Output is written to `docs/audits/{nn}-audit-{slug}.md` where `{nn}` is assigned by the shared Numbering procedure `[unit]`
- Skill creates `docs/audits/` directory if it doesn't exist `[unit]`

### Document deliverable path and Numbering reference
**Task**: 1.1
**Description**: Document the output path `docs/audits/{nn}-audit-{slug}.md` in SKILL.md, referencing the shared Numbering procedure for `{nn}` assignment. Include the directory creation behaviour. Covers both criteria.
**Status**: Complete

### Write tests for numbered deliverable path
**Task**: 1.2
**Description**: Write automated tests asserting that audit output paths follow the `docs/audits/{nn}-audit-{slug}.md` shape with integer-comparison numbering, and that re-running on the same project produces a new (incremented) number rather than overwriting.
**Status**: Complete

---

## Deliverable structure
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: #13 (deliverable structure)

**Acceptance Criteria**:

- Deliverable contains header section with date, commit SHA, and declared scope `[unit]`
- Deliverable contains executive summary section (max 10 bullets ranked by impact) `[unit]`
- Deliverable contains architectural mental model section (1–2 paragraphs) `[unit]`
- Deliverable contains findings table with columns: ID, Category, Citation, Severity, Effort, Description, Recommendation `[unit]`
- Deliverable contains "Top 5 priorities" section with concrete refactor outlines `[unit]`
- Deliverable contains "Quick wins" section as a checklist `[unit]`
- Deliverable contains "Things that look bad but are actually fine" section (required, non-negotiable) `[unit]`
- Deliverable contains "Open questions" section `[unit]`

### Document deliverable structure
**Task**: 2.1
**Description**: Document the full deliverable structure in SKILL.md: header, executive summary, mental model, findings table with column specification, top-5 priorities, quick wins, "looks bad but actually fine" (with required-non-negotiable callout), open questions. Covers all eight criteria.
**Status**: Complete

### Write tests for deliverable structure
**Task**: 2.2
**Description**: Write automated tests asserting that audit documents contain all required section headings (`## Executive Summary`, `## Architectural Mental Model`, `## Findings`, `## Top 5 Priorities`, `## Quick Wins`, `## Things that look bad but are actually fine`, `## Open Questions`), and that the findings table column header row matches the documented columns.
**Status**: Complete

---

## Citation format
**Story**: 3
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: #11 (citation format)

**Acceptance Criteria**:

- Every concrete finding in the table cites a location in `file:line (symbol)` format (e.g. `src/auth/login.ts:42 (authenticate)`) `[unit]`
- (must NOT) Citations must NOT quote actual secret values, even for security-hygiene findings — citation is the location only `[unit]`

### Document citation format
**Task**: 3.1
**Description**: Document the `file:line (symbol)` citation format in SKILL.md with multiple examples spanning languages (TS, PHP, Python, Rust, Go). Document the must-NOT-quote-secrets rule prominently as a non-negotiable. Covers both criteria.
**Status**: Pending

### Write tests for citation format
**Task**: 3.2
**Description**: Write automated tests asserting that every row in the findings table's Citation column matches the regex `^[^\s:]+:\d+( \([^)]+\))?$` and contains no obvious secret patterns (e.g. high-entropy strings, common API key prefixes).
**Status**: Pending

---

## Severity and effort scales
**Story**: 4
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: #14 (severity and effort scales)

**Acceptance Criteria**:

- Findings table uses Critical/High/Medium/Low for severity values `[unit]`
- Findings table uses S/M/L for effort values `[unit]`

### Document severity and effort scales
**Task**: 4.1
**Description**: Document the severity scale (Critical/High/Medium/Low) and effort scale (S/M/L) in SKILL.md with brief calibration guidance. Covers both criteria.
**Status**: Pending

### Write tests for scale values
**Task**: 4.2
**Description**: Write automated tests asserting that every row in the findings table has a Severity value drawn from the set {Critical, High, Medium, Low} and an Effort value from {S, M, L}.
**Status**: Pending

---

## No-rewrites and no-padding rules
**Story**: 5
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: #15 (no-rewrites rule), #16 (no-padding rule)

**Acceptance Criteria**:

- Recommendations describe scoped changes only `[manual]`
- (must NOT) Recommendations must NOT include phrases like "rewrite", "replace entirely", or full-module replacement guidance `[manual]`
- Empty dimension sections are removed entirely from the deliverable `[manual]`
- (must NOT) Deliverable must NOT contain "Nothing material" placeholders or filler content for empty categories `[unit]`

### Document no-rewrites rule
**Task**: 5.1
**Description**: Document the no-rewrites rule in SKILL.md with examples of acceptable scoped recommendations and counter-examples (forbidden full-rewrite phrasings). Mark as a non-negotiable. Covers the no-rewrites criteria.
**Status**: Pending

### Document no-padding rule
**Task**: 5.2
**Description**: Document the no-padding rule in SKILL.md: empty dimension sections are omitted from the deliverable rather than padded with placeholder content. Include the must-NOT-contain-"Nothing material" clause prominently. Covers the no-padding criteria.
**Status**: Pending

### Write tests for no-padding placeholder absence
**Task**: 5.3
**Description**: Write automated tests asserting that audit documents do not contain the string "Nothing material" or other padding indicators (e.g. "N/A — no findings", "Empty section").
**Status**: Pending

---

## Scoped audit consistency
**Story**: 6
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: #17 (scoped audit consistency)

**Acceptance Criteria**:

- When scope hint is provided, deliverable header records `**Scope**: <hint>` `[unit]`
- Out-of-scope dimensions are omitted from the deliverable (no "Nothing material" placeholders) `[unit]`
- Deliverable structure stays identical to a full-sweep deliverable (same sections, just fewer dimensions) `[unit]`

### Document scoped audit handling
**Task**: 6.1
**Description**: Document in SKILL.md how scope-hint runs are handled: declared scope recorded in header, out-of-scope dimensions omitted under the no-padding rule, deliverable structure preserved. Covers all three criteria.
**Status**: Pending

### Write tests for scoped audit consistency
**Task**: 6.2
**Description**: Write automated tests asserting that scoped audit deliverables contain `**Scope**: <hint>` in the header and that the section structure (executive summary, mental model, findings, top-5, quick wins, "looks bad but fine", open questions) is identical to full-sweep deliverables.
**Status**: Pending

---

## Effort aggregates in executive summary
**Story**: 7
**Status**: Pending
**Blocked by**: Story 4
**Satisfies**: #20 (effort aggregates)

**Acceptance Criteria**:

- Executive summary includes a line summarising effort totals (e.g. `Effort: S×12, M×7, L×3`) `[unit]`

### Document effort aggregates format
**Task**: 7.1
**Description**: Document the effort aggregates line in SKILL.md as part of the executive summary specification. Format: `Effort: S×<count>, M×<count>, L×<count>`. Covers the sole criterion.
**Status**: Pending

### Write tests for effort aggregates
**Task**: 7.2
**Description**: Write automated tests asserting that the executive summary contains a line matching the pattern `Effort: S×\d+, M×\d+, L×\d+` and that the counts equal the actual S/M/L counts in the findings table.
**Status**: Pending

---
