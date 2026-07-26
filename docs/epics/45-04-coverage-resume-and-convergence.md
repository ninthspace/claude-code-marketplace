# Coverage Matrix: Resume and Convergence

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Epic**: docs/epics/45-04-epic-resume-and-convergence.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR9 | A run interrupted mid-phase-1 **resumes without restarting or double-writing** epics already on disk. | Re-entering phase 1 with epics already on disk continues rather than restarting, and writes no duplicate epic doc | Story 1 | `[integration]` | |
| 2 | NFR6 | **Idempotent resume.** Re-entering phase 1 over a partially-generated set neither duplicates an epic nor renumbers one. | Resume duplicates no epic doc and renumbers none | Story 1 | `[integration]` | |
| 3 | FR12 | **Cross-session relaunch detects a leftover `cpm:epics` progress file** for the same spec, even when the Stale-Progress guard returns `SUPPRESS`, and passes it back as resume state. | Spec-mode pre-flight detects a leftover `cpm:epics` progress file for the same spec even when the guard returns `SUPPRESS` | Story 2 | `[integration]` | |
| 4 | FR12 (must NOT) | must NOT delete or overwrite that progress file without surfacing it | must NOT delete or overwrite that progress file without surfacing it | Story 2 | `[integration]` | |
| 5 | FR11 | **Non-convergence is visible.** Each iteration reports traced and verified counts, and a run whose counts are unchanged across N consecutive iterations stops and reports rather than continuing. | Each iteration reports traced and verified counts; a run whose counts are unchanged across N consecutive iterations stops and reports | Story 3 | `[integration]` | |
| 6 | FR11 (must NOT) | must NOT continue past the non-convergence threshold without reporting | must NOT continue past the non-convergence threshold without reporting | Story 3 | `[integration]` | |

## Notes

**Rows 1 and 2 are close but not redundant.** Row 1 is about *continuing* — the loop picks up where it stopped rather than starting over. Row 2 is about the *artefacts* — no duplicate doc, no renumbering. A resume that correctly declines to restart could still write a second epic doc for a work area already covered, satisfying row 1 and failing row 2.

**Row 2's renumbering clause needs care to test.** `cpm:epics` treats sub-numbers as identifiers rather than ordinals and preserves gaps from deleted sub-numbers deliberately, so an assertion that "the numbers are contiguous" would fail on correct behaviour. What row 2 forbids is a resume that *changes* an already-assigned number, not a sequence with a hole in it.

**Row 3 must be satisfied without weakening the guard.** `SUPPRESS` is the FR11 autonomous carve-out from spec 40 — it keeps every CPM skill's Stale-Progress Check silent during ralph runs. Satisfying row 3 by making the guard return something else would break that carve-out for every other skill, so the negative control is that the guard's own behaviour is unchanged.

**No row for an integration story.** Convergence is independent of resume, and the one genuine cross-story case — resume across sessions, then converge without duplicating — needs a live loop that nothing in this suite can launch. Recorded here so a later reader sees the omission was decided rather than overlooked.
