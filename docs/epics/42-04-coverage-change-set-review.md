# Coverage Matrix: Change-Set Review

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Epic**: docs/epics/42-04-epic-change-set-review.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R5 | Produce findings with `file:line` citations. | Findings carry `file:line` citations | Story 1 | `[integration]` | ✓ |
| 2 | AD3 | The review consumes the join's **data**, never its **labels**. | The review consumes the join's data, never its confidence labels | Story 1 | — | ✓ |
| 3 | R5 | When the change set overflows one pass, the files not examined are listed explicitly | When the change set overflows one pass, the files not examined are listed explicitly | Story 2 | `[integration]` | ✓ |
| 4 | R5 | must NOT present a partial review as complete | must NOT present a partial review as complete | Story 2 | `[integration]` | ✓ |
| 5 | NFR — Behaviour at Scale | the tool reviews what fits — prioritised by provenance signal, orphans first — and **prints an explicit list of the files it did not examine** | When the gap queries are available, unexamined-file selection prioritises orphans first; when they are not, it falls back to a deterministic file order | Story 2 | — | ✓ |

## Notes

**Row 5 is a deliberate widening of the spec text, not a drift.** The spec says prioritisation is "by provenance signal, orphans first" without qualification. Taken literally that makes this epic depend on Epic 42-03, contradicting the parallelism the dependency graph claims. The story criterion adds the fallback — deterministic file order when the gap queries are unavailable — so the epic can be built and verified end-to-end on its own. The spec's intent is preserved: when orphan data exists, it drives the ordering.

**Rows 2 and 5 carry no Spec Test Approach.** AD3 is an architecture decision and the scale requirement is non-functional; neither appears in the spec's Acceptance Criteria Coverage table, which tags only R1–R9 criteria. Both rows quote the authoritative prose instead, and the story-level tags are story-originated.

**AD3 is verified here rather than in Epic 42-02.** The 42-02 coverage matrix records why: the join *produces* confidence labels but nothing there *consumes* them, so the split cannot be asserted at the point of production. This epic is the only place a violation could occur, which makes it the only place the property is testable.

**R5's usefulness is not covered by any row, and that is a known gap.** Every criterion here is structural — citations present, overflow disclosed, boundary respected. Whether the findings are *good* has no automatable oracle, and no `[manual]` criterion was added to cover it. This was raised at the Step 3 gate and the epic was approved as presented. Recorded here so the untested surface is visible rather than implied.
