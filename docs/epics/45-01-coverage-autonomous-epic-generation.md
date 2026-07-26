# Coverage Matrix: Autonomous Epic Generation

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Epic**: docs/epics/45-01-epic-autonomous-epic-generation.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR4 | An **autonomous branch for `cpm:epics`**, covering all six `AskUserQuestion` sites (`:81` epic grouping, `:155` must-NOT clauses, `:178` stories, `:214` tasks, `:231` integration-testing story, `:282` final confirmation). | Each of `:81`, `:178`, `:214`, `:231`, `:282` has a stated autonomous disposition | Story 1 | `[integration]` | |
| 2 | FR4 | The branch is defined in `cpm:epics`; `cpm:ralph`'s prompt references it rather than restating it | The branch is defined in `cpm:epics`; `cpm:ralph`'s prompt references it rather than restating it | Story 1 | `[integration]` | |
| 3 | FR4 | Every one of the six gate sites has a stated autonomous disposition | Every one of the six gate sites has a stated autonomous disposition | Story 4 | `[integration]` | |
| 4 | FR4 (must NOT) | must NOT leave any gate site without a stated autonomous disposition | must NOT leave any gate site without a stated autonomous disposition | Story 4 | `[integration]` | |
| 5 | FR5 | A rule for the **must-NOT gate at `epics:155`**, the one gate where auto-accepting your own defensive boundary is the self-marking problem 43-02 solved with the citable-contradiction rule. | Spec-originated must-NOT clauses are propagated; others are recorded as proposed-unreviewed rather than attached | Story 2 | `[integration]` | |
| 6 | FR5 (must NOT) | must NOT attach a must-NOT clause that cannot be traced to a line in the source spec | must NOT attach a must-NOT clause that cannot be traced to a line in the source spec | Story 2 | `[integration]` | |
| 7 | NFR3 | **Bounded write surface for the autonomous `epics` phase.** It writes epic docs, coverage matrices, and its progress file. **It never edits the source spec.** | An autonomous run writes nothing under `docs/specifications/` | Story 3 | `[integration]` | |
| 8 | NFR3 (must NOT) | must NOT write to `docs/specifications/` during an autonomous run | must NOT write to `docs/specifications/` during an autonomous run | Story 3 | `[integration]` | |
| 9 | NFR4 | **Auditable without re-running.** Every autonomous gate decision leaves a breadcrumb naming *which* gate and *what* was chosen. | Each autonomous gate decision leaves a breadcrumb naming the gate and the choice | Story 3 | `[integration]` | |

## Notes

**Rows 1 and 3 divide FR4's site list on purpose.** Row 1 is the five approve-your-own-proposal gates, which Story 1 delivers. Row 3 is all six, which is only true once Story 2 adds the `:155` rule — so it is carried by the integration story rather than by either implementation story. A single row spanning both would be satisfiable while the set was incomplete.

**Rows 2, 3, 4, 6 and 8 quote the spec's Acceptance Criteria Coverage table rather than its requirements section**, because those criteria are stated there and nowhere else — FR4's single-source clause and every `must NOT` line originate in the testing strategy. Rows 1, 5, 7 and 9 quote the requirements section, which is authoritative where the two differ.

**Row 8's must-NOT names a path, not a concept.** `must NOT write to docs/specifications/` is checkable against a filesystem; a must-NOT phrased against the word "spec" would also match every explanatory sentence in the branch that mentions the source spec. Retro 21 recorded this failing in exactly this form — the `AskUserQuestion` must-NOT was unsatisfiable as first written because the prose that explained the rule used the token the rule forbade.
