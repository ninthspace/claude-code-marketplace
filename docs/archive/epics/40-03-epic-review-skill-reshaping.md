# Review Skill Re-shaping

**Source spec**: docs/specifications/40-spec-opus-5-alignment.md
**Date**: 2026-07-24
**Status**: Complete
**Blocked by**: Epic 40-01-epic-shared-conventions-realignment
**Retro applied**: 12 · Codebase discovery · Applied — check what each "2–5 findings" site actually feeds before rewording it, so Story 2 moves where curation happens rather than swapping a sentence that matches the phrasing.
**Retro applied**: 12 · Pattern worth reusing · Applied — Story 3's gate is treated as a real cross-story check, not a formality; its criteria span Story 1's spawn cap and Story 2's find/filter split, which no per-story gate can evaluate.
**Retro applied**: 11 · Codebase discovery · Applied — grep `review/SKILL.md` for every site stating the finding cap (per-agent step, output template, guidelines) before editing, rather than trusting the epic's single named site.

Two independent Opus 5 changes to `cpm/skills/review/SKILL.md`: the fan-out spawn cap (R1, review half) and the find/filter separation (R8). Both target known sites — the Subagent fan-out paragraph and the per-agent "Produce 2-5 findings" step. The shape R8 points at is `audit`'s existing framing: "the sweep is the finding stage, and its job is maximum coverage rather than curation… Filtering and ranking happen later, only when the Executive Summary is assembled."

## Cap `review` subagent fan-out
**Story**: 1
**Status**: Complete — delivered during epic 40-01 (see note)
**Blocked by**: —
**Satisfies**: R1 (review half) — Subagent delegation re-balanced for Opus 5; Maintainability NFR (reversal naming)

**Acceptance Criteria**:

- "fan-out is the expected path here, not an optional optimisation" is removed from the Subagent fan-out paragraph [manual]
- A spawn cap tied to the selected agent count is imposed — one subagent per selected reviewer agent, never more [manual]
- The change names spec 32's R1 as what it reverses and why [manual]
- must NOT remove the inline-execution path for 2-agent selections or fan-out-unavailable cases [manual]

**Inline change**: Story 1 delivered early, during epic 40-01's Story 6 verification gate (2026-07-24). The gate found `review/SKILL.md:142` contradicting the amended shared `Subagent Delegation` convention; Chris chose to close it there rather than leave the inconsistency standing until 40-03 ran. All four criteria met and coverage rows 1–4 marked verified. 40-03 Story 2 (find/filter separation) and Story 3 (integration) remain outstanding.

### Rewrite the Subagent fan-out paragraph
**Task**: 1.1
**Description**: Covers all four criteria; a single paragraph edit that leaves the adjacent inline-execution path untouched.
**Status**: Complete

---

## Separate `review` finding from filtering
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R8 *(should-have)* — `review` conservative-instruction reframing; Maintainability NFR (reversal naming)

**Acceptance Criteria**:

- The per-agent review step reports all findings rather than producing 2-5 [manual]
- Curation happens at a named filtering step, matching the find/rank separation `audit` already has, targeting the depth guidance already in the file — 3-8 findings for a single-story review, 5-15 for an epic review [manual]
- The finding step carries coverage-first framing in `audit`'s idiom — report everything found, do not suppress or pre-rank [manual]
- The change names spec 32's Won't-Have as what it revisits and why [manual]
- must NOT change the review document schema or the autofix handoff [manual]

**Inline change**: Criterion 2's curation target re-scoped from "2–5 findings" to the file's existing depth guidance — 3-8 for a story review, 5-15 for an epic review (2026-07-25). The 2–5 was a **per-agent** cap at `review/SKILL.md:149`; applied literally at a filtering step that sees the consolidated set it would have cut totals below today's 6–20 and below `:465`'s own guidance, making R8 reduce what surfaces when R8 exists to increase it. Coverage matrix row 6 updated to match.

*Decision (2026-07-24): uncurated findings are not persisted into the review document. Unlike `audit`, which keeps a comprehensive table and curates only its Executive Summary, `review`'s schema is frozen by R8's must-NOT — so the full finding set lives in-session, is read by the filtering step, and is not written to disk. Confirmed with Chris.*

**Retro**: [Codebase discovery] The cap the epic named as a single site was stated at three, and the third held a *different* set of numbers scoped to totals rather than per-agent — surveying before editing is what turned a silent inversion of R8's purpose into a decision instead of a defect.

### Reframe the per-agent review step as coverage-first
**Task**: 2.1
**Description**: Covers criteria 1 and 3 — step 2 of the per-agent list drops the 2-5 cap and adopts `audit`'s report-everything framing.
**Status**: Complete

### Add the named filtering step before presentation
**Task**: 2.2
**Description**: Covers criteria 2 and 4; curation lands between finding consolidation and the grouped-by-concern-type presentation.
**Status**: Complete

### Hold the document schema and autofix handoff steady
**Task**: 2.3
**Description**: Covers criterion 5. The `**Findings**` header count and severity grouping must reflect the curated set without the schema itself changing.
**Status**: Complete

**Verification outcome (2026-07-25)**: no edit needed. `git diff -U0` on `review/SKILL.md` places every changed hunk in the finding step, the new Step 2b/2c, the progress-file template, or Guidelines. The review document template block — `**Findings**: {total count}`, `## Findings`, and the per-concern-type sections — and the entire Step 4 autofix section carry no diff hunks at all. Both now read against the curated set because Step 2b sits upstream of Step 3, not because either was rewritten.

---

## Verify cross-story integration for Review Skill Re-shaping
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: Integration Boundaries — Review find → filter; Consistency NFR

**Acceptance Criteria**:

- The full finding set is captured somewhere the filtering step can read before curation happens [manual]
- The spawn cap does not reduce the finding set below what the filtering step expects [manual]
- `review`'s fan-out framing is consistent with the re-balanced shared Subagent Delegation convention from Epic 40-01 [manual]

**Inline change**: The subagent prompt-contents list at `review/SKILL.md:142` gained the coverage-first instruction (2026-07-25). Criterion 1 initially failed: the list named the artifact, persona, dimensions, severity scheme, and finding format, but not the report-everything framing — so a spawned subagent would still curate on its own and the set reaching Step 2b would be pre-filtered. Fixed in place; the gap lived only where Story 1's fan-out paragraph meets Story 2's finding step.

**Retro**: [Pattern worth reusing] The cross-story seam was invisible to both stories that created it — Story 1 owned the subagent prompt list, Story 2 owned the finding instruction, and neither gate could see that the first never carried the second.

### Verify the find → filter boundary and fan-out consistency
**Task**: 3.1
**Description**: Covers all three criteria in one reading pass over the amended file plus the shared convention.
**Status**: Complete

---
