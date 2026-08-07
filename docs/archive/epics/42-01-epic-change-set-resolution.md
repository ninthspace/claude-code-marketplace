# Change-Set Resolution

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Date**: 2026-07-25
**Status**: Complete — delivered 2026-07-25. Stories 1 and 2 survive as `cpm/hooks/lib/changeset.sh`, `changeset-resolve.sh` and `test-changeset-resolve.sh`; Story 3's forward direction was deleted 2026-07-26 with the adapters it was built for. See the Retirement section of the source spec.
**Blocked by**: —
**Retro applied**: 15 · Codebase Discoveries · Applied — every new suite groups related checks under one `test_start` (combined assert helpers where a call returns both a code and a reason), so all three stories report a 1:1 pass/test ratio; pre-existing inflated suites are left alone.
**Retro applied**: 19 · Testing Gaps · Applied — git fixtures produce non-deterministic SHAs, so assertions read expected values back from the fixture at run time rather than pinning literals; constrains Story 1's tests and Story 3's `[tdd]` tests before they are written.
**Retro applied**: 18 · Patterns Worth Reusing · Not relevant here — the baseline-capture lesson protects existing behaviour from an editing pass; this epic only adds new suites to a glob-discovered runner, so there is no pre-existing surface for a baseline to guard.
**Retro applied**: 18 · Codebase Discoveries · Applied — Story 1's no-leftovers must-NOT is a pure absence assertion, so it is paired with a positive control proving the fixture repo existed and was populated before teardown ran.

## Build synthetic git-repository test fixtures
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Test Infrastructure (spec Testing Strategy)
**Retro**: [Testing gap] An equality assertion between two fixtures needs a preceding assertion that they *are* two — the determinism test compared a repo against itself for a full run and passed, because `git_fixture_create`'s counter lived in a subshell and every call returned the same path.

**Acceptance Criteria**:

- A fixture helper creates a temporary git repository with a specified commit sequence — including commit trailers, conventional-commit subjects, branch names, and co-committed files — and tears it down on exit [integration]
- Fixture repositories are isolated from the host repository and require no network [integration]
- must NOT leave repositories or working directories behind after a suite exits, whether it passes or fails [integration]

### Create the fixture helper
**Task**: 1.1
**Description**: Repo init, commit sequencing and teardown. Produces the helper Stories 2 and 3 both consume; covers the creation and no-leftovers criteria.
**Status**: Complete

### Add commit-shape support
**Task**: 1.2
**Description**: Trailers, conventional-commit subjects, branch names and co-committed files. These are the shapes Epic 42-02's git-native adapter will parse, so the fixture vocabulary is fixed here rather than extended later.
**Status**: Complete

### Write tests for building synthetic git-repository fixtures
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Resolve git-anchored selectors to a change set
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R1 (git-anchored half), AD5
**Retro**: [Criteria gap] "A branch name resolves to a change-set structure" is satisfiable by several readings that differ by most of the repository, the criterion anchors none of them, and the tests I wrote passed under the wrong one — the gap was closed by Chris reading the code, not by anything in the story.
**Inline change**: Branch selectors resolve from the branch's fork point rather than the default branch tip, correcting a stacked-branch defect after Story 2's gate (2026-07-25)

**Acceptance Criteria**:

- `--since <ref>`, a commit range, a branch name, and the working tree each resolve to a change-set structure comprising a set of commits and a set of files [integration]
- must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back [integration]

### Define the change-set structure
**Task**: 2.1
**Description**: The shape both resolution directions produce. Story 3 consumes it unchanged, so it is settled here rather than negotiated across stories.
**Status**: Complete

### Resolve the four git-anchored selector forms
**Task**: 2.2
**Description**: `--since <ref>`, commit range, branch, and working tree — including the empty-match error path the must-NOT criterion requires.
**Status**: Complete

### Write tests for resolving git-anchored selectors
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Define intent resolution and the forward direction [plan]
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: R1 (intent-anchored half), R2 (forward direction), AD5
**Retro**: [Pattern worth reusing] Reading the finished contract end to end after a green suite found that `changeset_intent_answerable` counted an *erroring* adapter as having answered — a defect invisible to every assertion because the tests only exercised the two outcomes the criteria named, which is the shape a contract's untested third branch always takes.

**Acceptance Criteria**:

- An intent-anchored selector (`epic 41-03`, `story 41-03.2`) resolves forward to the same change-set structure produced by git-anchored resolution [tdd] [integration]
- An intent-anchored run and a git-anchored run over the same commits yield the same file set [tdd] [integration]
- The intent-resolution interface is exercised against a stub adapter, so the real adapters in Epic 42-02 implement a contract that already has tests [tdd] [integration]
- must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back [tdd] [integration]

**Note**: `[plan]` because this story fixes the contract Epic 42-02's adapters implement — the "API contract changes where the design needs upfront agreement" category. It exists as a separate story from 42-02 to break what would otherwise be a circular dependency: intent-anchored resolution needs an adapter to know what `epic 41-03` means, and adapters need a resolution interface to implement.

### Write tests for intent resolution and the forward direction
**Task**: 3.1
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`. Placed first — this story carries `[tdd]`, so the tests define the contract before it is built.
**Status**: Complete

### Define the intent-resolution interface
**Task**: 3.2
**Description**: The contract Epic 42-02's adapters implement. Scope is the interface only; no real adapter is written here.
**Status**: Complete

### Implement forward resolution against a stub adapter
**Task**: 3.3
**Description**: Covers the round-trip criterion — an intent-anchored run and a git-anchored run over the same commits must yield the same file set.
**Status**: Complete

---
