# Coverage Matrix: Change-Set Resolution

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Epic**: docs/epics/42-01-epic-change-set-resolution.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

> **Partly retired 2026-07-26.** Spec 42's architecture was withdrawn — see the Retirement
> section of the source spec. **This matrix is the one that is still mostly live.** Rows 1–4
> (Story 1's fixture helper, Story 2's git-anchored resolution) are backed by
> `test-git-fixtures.sh` and `test-changeset-resolve.sh`, both of which still exist and still
> pass. Rows 5–8 cover Story 3's forward direction, whose code and suite
> (`changeset-intent.sh`, `test-changeset-intent.sh`, `stub-intent-adapter.sh`) were deleted.
> Every `✓` is left as it stands: it records what was verified on 2026-07-25, which is what
> this document is for. Rows 5–8 are not a claim about the current tree.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Test Infrastructure | this spec needs fixtures that are real repositories with known commits, trailers, branch names and co-committed planning documents, built and torn down per test | A fixture helper creates a temporary git repository with a specified commit sequence — including commit trailers, conventional-commit subjects, branch names, and co-committed files — and tears it down on exit | Story 1 | — | ✓ |
| 2 | Test Infrastructure | built and torn down per test | must NOT leave repositories or working directories behind after a suite exits, whether it passes or fails | Story 1 | — | ✓ |
| 3 | R1 | Accept an **intent-anchored** selector (a ticket, an issue, a CPM spec/epic/story — e.g. `epic 41-03`, `story 41-03.2`) *or* a **git-anchored** selector (`--since <ref>`, a commit range, a branch, the working tree). Both resolve to one change-set structure: a set of commits and a set of files. | `--since <ref>`, a commit range, a branch name, and the working tree each resolve to a change-set structure comprising a set of commits and a set of files | Story 2 | `[integration]` | ✓ |
| 4 | R1 | must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back | must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back | Story 2 | `[integration]` | ✓ |
| 5 | R1 | Accept an **intent-anchored** selector (a ticket, an issue, a CPM spec/epic/story — e.g. `epic 41-03`, `story 41-03.2`) | An intent-anchored selector (`epic 41-03`, `story 41-03.2`) resolves forward to the same change-set structure produced by git-anchored resolution | Story 3 | `[integration]` | ✓ |
| 6 | R2 | Intent-anchored selectors resolve **forward** (intent → files). Git-anchored selectors resolve **reverse** (files → intent). One join, two entry points. | An intent-anchored selector (`epic 41-03`, `story 41-03.2`) resolves forward to the same change-set structure produced by git-anchored resolution | Story 3 | `[integration]` | ✓ |
| 7 | R2 | An intent-anchored run and a git-anchored run over the same commits yield the same file set | An intent-anchored run and a git-anchored run over the same commits yield the same file set | Story 3 | `[integration]` | ✓ |
| 8 | AD5 | Intent-anchored selectors resolve forward (intent → commits → files). Git-anchored selectors resolve reverse (files → commits → intent). Both converge on one change-set structure before the join runs. | The intent-resolution interface is exercised against a stub adapter, so the real adapters in Epic 42-02 implement a contract that already has tests | Story 3 | `[integration]` | ✓ |

## Notes

**R2 is split across two epics — flagged at the Step 3d gate and carried here deliberately.** R2 has two halves. This epic covers the **forward direction only** (intent → files) plus the round-trip equivalence between the two directions. **Reverse resolution (files → intent) is impossible without adapters** and therefore lands in Epic 42-02. R2 will appear in two coverage matrices; Step 4's cross-epic gap check is where it is confirmed fully covered. Rows 6 and 7 above are not the whole of R2 and must not be read as such.

**Test Infrastructure has no Spec Test Approach entry.** The spec's Acceptance Criteria Coverage table carries no row for test infrastructure — it is stated in the Testing Strategy prose instead. Rows 1 and 2 therefore quote that prose and carry no tag from the spec. The story's own criteria are tagged `[integration]`, which is a story-originated tag rather than a propagated one.

**Story-originated criterion (no spec counterpart).** Story 1's "Fixture repositories are isolated from the host repository and require no network" has no direct spec sentence. It derives from the Offline Integrity non-functional requirement ("The join, the review and the JSON emission use only local git and local files") applied to the test harness rather than the tool, and from the practical hazard that a fixture helper operating on the host repository would be destructive.
