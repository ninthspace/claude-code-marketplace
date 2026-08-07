# Coverage Matrix: Review Skill Re-shaping

**Source spec**: docs/specifications/40-spec-opus-5-alignment.md
**Epic**: docs/epics/40-03-epic-review-skill-reshaping.md
**Date**: 2026-07-24

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | R1 — Subagent delegation | "Amend `skills/review/SKILL.md` to drop "fan-out is the expected path here, not an optional optimisation"" | ""fan-out is the expected path here, not an optional optimisation" is removed from the Subagent fan-out paragraph" | Story 1 | `[manual]` | ✓ |
| 2 | R1 — Subagent delegation | "and impose a spawn cap tied to the selected agent count" | "A spawn cap tied to the selected agent count is imposed — one subagent per selected reviewer agent, never more" | Story 1 | `[manual]` | ✓ |
| 3 | Maintainability NFR | "Reversals of prior specs (R1, R8) name the spec they reverse and why, so the 29 → 32 → 40 chain reads as a deliberate sequence rather than churn." | "The change names spec 32's R1 as what it reverses and why" | Story 1 | — | ✓ |
| 4 | — *(story-originated)* | — | "must NOT remove the inline-execution path for 2-agent selections or fan-out-unavailable cases" | Story 1 | — | ✓ |
| 5 | R8 — Review reframing *(should)* | "Opus 5 follows conservative review instructions literally and reports less as a result; the documented remedy is to report everything and filter in a separate pass." | "The per-agent review step reports all findings rather than producing 2-5" | Story 2 | `[manual]` | ✓ |
| 6 | R8 — Review reframing *(should)* | "`review`'s 2–5 finding curation should move from the finding step to a filtering step, matching the find/rank separation `audit` already has." | "Curation happens at a named filtering step, matching the find/rank separation `audit` already has, targeting the depth guidance already in the file — 3-8 findings for a single-story review, 5-15 for an epic review" | Story 2 | `[manual]` | ✓ |
| 7 | R8 — Review reframing *(should)* | "the documented remedy is to report everything and filter in a separate pass" | "The finding step carries coverage-first framing in `audit`'s idiom — report everything found, do not suppress or pre-rank" | Story 2 | `[manual]` | ✓ |
| 8 | Maintainability NFR | "Reversals of prior specs (R1, R8) name the spec they reverse and why" | "The change names spec 32's Won't-Have as what it revisits and why" | Story 2 | — | ✓ |
| 9 | R8 — Review reframing *(should)* | "must NOT change the review document schema or the autofix handoff" | "must NOT change the review document schema or the autofix handoff" | Story 2 | `[manual]` | ✓ |
| 10 | Integration Boundaries — Review find → filter | "R8 introduces the same two-stage boundary `audit` has. The full finding set must be captured somewhere the filtering step can read before curation happens." | "The full finding set is captured somewhere the filtering step can read before curation happens" | Story 3 | — | ✓ |
| 11 | — *(story-originated)* | — | "The spawn cap does not reduce the finding set below what the filtering step expects" | Story 3 | — | ✓ |
| 12 | Consistency NFR | "Load-bearing changes land in `shared/skill-conventions.md` so per-skill edits stay thin." | "`review`'s fan-out framing is consistent with the re-balanced shared Subagent Delegation convention from Epic 40-01" | Story 3 | — | ✓ |

## Notes

- **Rows 4, 11** — story-originated, fencing each change against over-application in the way the spec's own must-NOT clauses do elsewhere.
- **Rows 3, 8, 10, 12** — trace to NFRs and integration boundaries rather than numbered requirements, so the spec's Acceptance Criteria Coverage table assigns them no tag.
- **Row 9 confirmed binding (2026-07-24)**: uncurated findings are not persisted into the review document. Unlike `audit`, `review`'s schema is frozen, so the full finding set is read by the filtering step in-session and not written to disk.
