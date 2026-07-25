# Coverage Matrix: Gap Queries

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Epic**: docs/epics/42-03-epic-gap-queries.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R3 | Report files in the change set that no adapter can link to any intent record. This is where unreviewed scope creep hides. | A file with no adapter link appears in the orphan list; a file with a declared link does not | Story 1 | `[integration]` | ✓ |
| 2 | R3 | must NOT list a file as an orphan when any active adapter resolves it | must NOT list a file as an orphan when any active adapter resolves it | Story 1 | `[integration]` | ✓ |
| 3 | R4 | Report intent records marked done or verified with no test naming them. This is the inverse gap, and the one `/cpm:do` structurally cannot catch because it self-assesses. | An intent record marked verified with no test naming it is listed as an unbacked claim | Story 2 | `[integration]` | ✓ |
| 4 | R4 | must NOT report an empty unbacked list as "none found" when the active adapters cannot answer the query — "none found" and "not answerable" must render differently | must NOT report an empty unbacked list as "none found" when the active adapters cannot answer the query — "none found" and "not answerable" must render differently | Story 2 | `[integration]` | ✓ |
| 5 | R9 | In a repository with no recognised intent source, the review still runs and every file is reported as an orphan. Absence of provenance is never a failure. | A repository with no CPM artifacts and no trailers still produces a review, with every file reported as an orphan | Story 3 | `[integration]` | ✓ |
| 6 | R9 | must NOT hard-fail when no adapter resolves anything | must NOT hard-fail when no adapter resolves anything | Story 3 | `[integration]` | ✓ |

## Notes

**All six rows quote spec text verbatim on both sides.** Rows 2, 4 and 6 are the spec's own must-NOT clauses carried through without alteration, per the spec's framing of them as defensive boundaries rather than suggestions.

**R4's answerability clause is why Story 2 stands apart from Story 1.** The spec states the reasoning directly: "Commit trailers and branch names record *why* a change happened; they never record *and here is the criterion it satisfies, marked verified*. R4 is answerable only through an adapter that carries verification claims — in this iteration, the CPM adapter alone." Row 4 is therefore not a general property of the tool but a conditional one, and the criterion's wording makes the condition observable rather than implicit.

**Row 5's "still produces a review" reaches beyond this epic.** The review itself is built in Epic 42-04. This epic delivers the degradation path — zero adapters resolving nothing, every file an orphan, no hard failure — but the criterion's full observable outcome requires 42-04's review to exist. Step 4's cross-epic check should confirm the pair; until 42-04 lands, Story 3 is verifiable only as far as "the run completes and every file is an orphan".

**Resolved 2026-07-25 — the deferred half now holds.** Epic 42-05 Story 3 closes it, and against a single invocation rather than a hand-composed sequence: `inspect_run` over a repository with no `docs/`, no coverage matrices and no commit trailers completes at exit 0, resolves no links, reports all three files as orphans, reports R4 as `unanswerable` rather than clean, selects every file for review, marks the selection complete, and accepts a finding emitted over the degraded run (`cpm/hooks/tests/test-inspect-pipeline.sh`). The paired row is 42-05's row 11. Both are now ✓, which is what that matrix's note requires for R9 to be covered.

**No integration story.** Story 3 exercises Stories 1 and 2 together under the zero-adapter condition, which is this epic's only genuine cross-story interaction. A dedicated integration story would restate criteria already present.
