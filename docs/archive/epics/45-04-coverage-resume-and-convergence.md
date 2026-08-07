# Coverage Matrix: Partial-Set Reporting and Convergence Visibility

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Epic**: docs/epics/45-04-epic-resume-and-convergence.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR9 | A run interrupted mid-phase-1 **reports the partial set rather than restarting or double-writing it**. The loop stops with the covered and uncovered requirements named; the partial epics stay on disk untouched, and completing them is a deliberate act. | A phase 1 interrupted with epics already on disk reports the partial set — naming covered and uncovered requirements — and writes no duplicate epic doc | Story 1 | `[integration]` | ✓ |
| 2 | FR9 (must NOT) | must NOT re-enter `/cpm:epics` over a partial set | must NOT — re-enter `/cpm:epics` over a partial set | Story 1 | `[integration]` | ✓ |
| 3 | NFR6 | **Idempotent resume.** Re-entering phase 1 over a partially-generated set neither duplicates an epic nor renumbers one. | The partial set duplicates no epic doc and renumbers none | Story 1 | `[integration]` | ✓ |
| 4 | FR12 | **Cross-session relaunch detects a leftover `cpm:epics` progress file** for the same spec, even when the Stale-Progress guard returns `SUPPRESS`, and passes it back as resume state. | Spec-mode pre-flight detects a leftover `cpm:epics` progress file for the same spec even when the guard returns `SUPPRESS` | Story 2 | `[integration]` | ✓ |
| 5 | FR12 (must NOT) | must NOT delete or overwrite that progress file without surfacing it | must NOT delete or overwrite that progress file without surfacing it | Story 2 | `[integration]` | ✓ |
| 6 | FR11 | **Non-convergence is visible.** Each iteration reports the traced and verified counts it read from the roll-up, so a run that is neither stalled nor finished can be seen to be so while it is happening. | Each iteration reports the traced and verified counts it read from the roll-up | Story 3 | `[integration]` | ✓ |
| 7 | FR11 (must NOT) | must NOT branch on those counts without having reported them in the same iteration | must NOT — branch on those counts without having reported them in the same iteration | Story 3 | `[integration]` | ✓ |

## Notes

**Amended at the 2026-07-27 pivot on the source spec.** Rows 1, 3, 6 and 7 were rewritten and row 2
added when FR9 was restated against the real failure mode and FR11 narrowed to its reporting half.
Every row was unverified at the time, so no `✓` was invalidated. The old row numbering shifted by
one from FR12 onward; nothing outside this file cites those numbers.

**Rows 1 and 3 are close but not redundant.** Row 1 is about what the loop *says* — it names which
requirements the partial set covers and which it does not, rather than starting over. Row 3 is about
the *artefacts* — no duplicate doc, no renumbering. A loop that correctly declines to restart could
still write a second epic doc for a work area already covered, satisfying row 1 and failing row 3.

**Row 2 is the reachability claim, not a restatement of row 1.** FR9's resume path is unreachable
through the phase predicate: `cpm:epics` writes each epic doc and its matrix before starting the
next, so a partial phase 1 always leaves a matrix and exit `4` — *zero matrices name this spec* —
cannot fire. Row 2 forbids re-opening a second route, which is what would reinstate the
fifty-generation spin the liveness guard removed.

**Row 3's renumbering clause needs care to test.** `cpm:epics` treats sub-numbers as identifiers
rather than ordinals and preserves gaps from deleted sub-numbers deliberately, so an assertion that
"the numbers are contiguous" would fail on correct behaviour. What row 3 forbids is a change to an
already-assigned number, not a sequence with a hole in it.

**Row 4 must be satisfied without weakening the guard.** `SUPPRESS` is the FR11 autonomous carve-out from spec 40 — it keeps every CPM skill's Stale-Progress Check silent during ralph runs. Satisfying row 4 by making the guard return something else would break that carve-out for every other skill, so the negative control is that the guard's own behaviour is unchanged.

**No row for an integration story.** Convergence is independent of the partial-set reporting, and the one genuine cross-story case — detect a leftover progress file across sessions, then report without duplicating — needs a live loop that nothing in this suite can launch. Recorded here so a later reader sees the omission was decided rather than overlooked.
