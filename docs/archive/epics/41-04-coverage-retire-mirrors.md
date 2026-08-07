# Coverage Matrix: Retire the Mirrors

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Epic**: docs/epics/41-04-epic-retire-mirrors.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R1 — Delete the faithful-render mechanism | Remove the three `Faithful Render (on request)` sections (`spec/SKILL.md:209`, `architect/SKILL.md:163`, `review/SKILL.md:239`) | `grep -rn "Faithful Render" cpm/ --include="*.md"` returns zero hits | Story 1 | `[integration]` | ✓ |
| 2 | R1 — Delete the faithful-render mechanism | the `docs/{type}/html/` storage-path row from the shared convention | The `docs/{type}/html/` storage-path row is absent from the shared convention | Story 1 | `[integration]` | ✓ |
| 3 | R1 (must NOT) | must NOT delete the Companion Assets sections in `spec` or `architect` | must NOT delete the Companion Assets sections in `spec` or `architect` | Story 1 | `[integration]` | ✓ |
| 4 | R1 — Delete the faithful-render mechanism | `test-faithful-render.sh` is deleted and `run-all-tests.sh` no longer references it | `cpm/hooks/tests/test-faithful-render.sh` is deleted / The glob-based runner reports one fewer suite than the pre-story baseline | Story 2 | `[integration]` | ✓ |
| 5 | R6 — Companion assets remain repo files | `git diff` shows no change to `do/SKILL.md:272` or `epics/SKILL.md:138` | `git diff` shows no change to the companion-asset awareness block in `cpm/skills/do/SKILL.md` or the mockup-referencing-criteria block in `cpm/skills/epics/SKILL.md` | Story 3 | `[integration]` | ✓ |
| 6 | R6 (must NOT) | must NOT introduce any URL dependency into the `cpm:do` execution path | must NOT introduce any URL dependency into the `cpm:do` execution path | Story 3 | `[integration]` | ✓ |
| 7 | R6 — Companion assets remain repo files | They are not published and not replaced by artifacts. | Companion assets are still written to `docs/{type}/assets/{nn}-{slug}-{label}.html` as repo files, not published | Story 3 | `[integration]` | ✓ |

## Notes

**Fidelity divergence — row 4. Read this one.** The spec's criterion is *"`test-faithful-render.sh` is deleted and `run-all-tests.sh` no longer references it."* The second clause describes a reference that does not exist: `run-all-tests.sh` discovers suites by globbing `test-*.sh` and holds no manifest. Written as specified, the criterion would be trivially and misleadingly satisfiable — nothing to remove, so nothing to check. The story substitutes an observable equivalent: the runner reports one fewer suite than the captured baseline. This is a deliberate correction of the spec, not a weakening of it, and it is recorded here rather than fixed silently.

**Fidelity note — row 5.** The spec anchors R6 to line numbers (`do/SKILL.md:272`, `epics/SKILL.md:138`). The story anchors to the named blocks instead, because these epics edit prose across the same files and line numbers will have moved by the time Story 3 runs. Same subject, stable reference.

**Row 4 verified with a stated substitution (2026-07-25).** The criterion's second clause — "the runner reports one fewer suite than the pre-story baseline" — is arithmetically unsatisfiable by a story that also adds a suite, and Task 2.4 does. Baseline 22 − `test-faithful-render.sh` + `test-suite-prune.sh` = 22. Verified as the observable equivalent: the deleted suite is absent from the runner's output, the runner still discovers by glob with no manifest, and every `test-*.sh` on disk is one it runs. Recorded here rather than resolved silently, on the same footing as the row's original fidelity divergence below.

**Story-originated criteria (no spec counterpart).** Four, all from the surface survey:

- *Story 1* — "No `docs/specifications/html/`, `docs/architecture/html/` or `docs/reviews/html/` write path remains in any skill." The spec deletes the *sections*; each section also contains an explicit write path, and a `grep` for the section heading alone would not catch a stray path left behind.
- *Story 2* — `check_render_path` and `check_communication_path` removal, plus the no-dangling-reference sweep. The spec's testing strategy names the validators as losing their subject but does not make their removal a criterion. Removing a validator without sweeping its callers turns a green suite red for an unrelated reason.
- *Story 2* — "No *new* failures against a baseline captured before the story starts", with Task 2.1 capturing that baseline. Phrased per retro 14, whose testing gap was precisely a "the suite passes" criterion silently annexing unrelated repo maintenance.
- *Story 3* — "The companion-asset test suite passes." R6 protects a behaviour; this asserts the behaviour still works rather than only that its instructions were not edited.
