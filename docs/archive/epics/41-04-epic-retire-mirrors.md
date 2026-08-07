# Retire the Mirrors

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Date**: 2026-07-25
**Status**: Complete
**Blocked by**: Epic 41-02-epic-pivot-interpretations
**Retro applied**: 16 · Scope surprises · Applied — `cpm/hooks/tests/` is surveyed before Story 1's deletions rather than at Story 2, and the two inheritances retro 16 named for this epic get an explicit rework-or-delete decision: `test-dashboard-export.sh` (breaks when `check_uses_shared_template` is pruned) and `check_counts_agree` (callerless since `test-status-dashboard.sh` was deleted in 41-02).
**Retro applied**: 17 · Patterns worth reusing · Applied — each story's verification gate includes reading the edited region in place. Story 1 deletes three sections from mid-file; surrounding prose may reference or assume the deleted section, which no zero-hit grep can see.
**Retro applied**: 15 · Testing gaps · Applied — Task 1.3's and 2.4's slices anchor to heading syntax (`^## ` / `^### `) and assert each range spans a real region. Deleting a section changes what a loose range matches next, which is this epic's specific exposure to that failure.
**Retro applied**: 14 · Testing gaps · Applied — Task 2.1's baseline is captured before any deletion so "no *new* failures" is measured against a known state, and the new assertions test absence structurally (zero hits, validator undefined) rather than pinning suite counts or literals.

## Delete the three faithful-render sections
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R1
**Inline change**: Task 1.2 found no work to do. The `docs/{type}/html/` storage row was already removed by epic 41-01, which reduced the convention's storage table to the companion-asset row alone, and `test-html-convention.sh` has asserted its absence since. The criterion is verified rather than delivered — recorded here so a reader does not look for a deletion in this epic's diff. (2026-07-25)
**Inline change**: `architect`'s frontmatter still advertised *"an on-request HTML render"* after the section was deleted — a secondary site the epic did not name, found by the retro-17 end-to-end read rather than by any criterion. Rewritten to describe the artifact publish that replaced it. The new suite asserts no skill frontmatter advertises a render, so the class of defect is now covered rather than just this instance. (2026-07-25)

**Acceptance Criteria**:

- `grep -rn "Faithful Render" cpm/ --include="*.md"` returns zero hits [integration]
- The `docs/{type}/html/` storage-path row is absent from the shared convention [integration]
- No `docs/specifications/html/`, `docs/architecture/html/` or `docs/reviews/html/` write path remains in any skill [integration]
- must NOT delete the Companion Assets sections in `spec` or `architect` [integration]

### Delete the faithful-render sections from spec, architect and review
**Task**: 1.1
**Description**: Covers the first and third criteria. Three sections (`spec:209`, `architect:163`, `review:239`), each carrying its own copy of the publishing reference line, which goes with its host. Per the spec's architecture decision these are deletions, not rewrites — a faithful render is a mirror by definition, so replacing it in a new medium would reproduce the fault.
**Status**: Complete

### Remove the faithful-render storage row
**Task**: 1.2
**Description**: Covers the storage-row criterion. Scope boundary: the companion-asset row stays — it is the only row the convention retains after Epic 41-01.
**Status**: Complete

### Write tests for faithful-render deletion
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Verification** (2026-07-25): `cpm/hooks/tests/test-faithful-render-retired.sh` — 17/17 passed; `run-all-tests.sh` green. `grep -rn "Faithful Render" cpm/ --include="*.md"` returns zero hits. No `docs/{specifications,architecture,reviews}/html/` write path survives in any skill, checked both per-skill and by a generic `docs/[a-z]+/html/` sweep. The convention's storage table holds one body row, the companion-asset row. Both Companion Assets sections survive with their assets/ paths and earns-its-place heuristic intact. The publishing reference line placed in 41-03 is unaffected at all ten sites — `test-reference-line-propagation.sh` still reports one unique string ×10 without modification, which is what coverage row 2b of epic 41-03 existed to guarantee.

**Retro**: [Scope surprise] The end-to-end read caught `architect`'s frontmatter still advertising *"an on-request HTML render"* — the fifth consecutive epic where the named sites were not the only sites, and the second where a skill's own frontmatter description was the straggler (41-02 hit the same thing in `status`). The pattern is specific enough to act on: a SKILL.md's frontmatter `description` summarises the skill's outputs, so any story that adds or removes an output has a frontmatter edit in it whether the criteria say so or not. Separately, Task 1.2 turned out to have no work — the storage row was removed two epics earlier — which is the benign version of the same defect: the breakdown's model of the file was one epic stale.

---

## Prune the test suite
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R1
**Inline change**: The suite-count criterion ("one fewer suite than the pre-story baseline") is arithmetically unsatisfiable by this story, because Task 2.4 — inside the same story — adds a suite. Baseline 22, minus `test-faithful-render.sh`, plus `test-suite-prune.sh`, equals 22. Verified as the observable equivalent instead: the deleted suite is absent from the runner's output, the runner still discovers suites by glob with no manifest (so deleting a file *is* the removal), and every `test-*.sh` on disk is one the runner runs. The count itself is not asserted as a literal, per retro 14. (2026-07-25)
**Inline change**: `check_counts_agree` removed alongside the two validators the criterion names. It lost its only caller when `test-status-dashboard.sh` was deleted in epic 41-02, and its subject — a local `status` dashboard stating "{complete} of {total} epics complete" — was retired by the same pivot. Retro 16 recommended handling it here; a validator with no caller and no subject reads as coverage while testing nothing. (2026-07-25)
**Inline change**: `test-dashboard-export.sh` reworked rather than left alone (retro 16's recommendation, and the applied disposition at this epic's gate). Its fixture built a local document from `template.html` and asserted `check_uses_shared_template` / `check_valid_html` — the retired shape. Re-pointed at a body fragment at the convention's scratch path, validated by `check_valid_fragment`; the two shape assertions were dropped and everything covering the surviving affordances kept (payload well-formedness, inline-JS-only, no write-back, source immutability). Two assertions added: that the fixture is a fragment rather than a document, and that the handler guards on `navigator.clipboard` and not on `permissions.query`, which the 41-02 probe found unsupported on an engine where `writeText` worked. Its reported count was also corrected from 19/15 to 15/15 (retro 15). Retro 16's stated premise for the rework — that 41-04 would prune `check_uses_shared_template` — turned out to be wrong: that validator keeps a live caller in `test-companion-assets.sh`, since companion assets retain the shared template under R6. The suite needed reworking for a different reason than predicted, and survives. (2026-07-25)

**Acceptance Criteria**:

- `cpm/hooks/tests/test-faithful-render.sh` is deleted [integration]
- The glob-based runner reports one fewer suite than the pre-story baseline [integration]
- `check_render_path` and `check_communication_path` are removed from `html-test-helpers.sh` [integration]
- No remaining test file references a deleted validator [integration]
- No *new* failures against a baseline captured before the story starts [integration]

### Capture the pre-story baseline
**Task**: 2.1
**Description**: Run the suite and record which suites pass and which already fail, before any deletion. Retro 14: a criterion phrased "the suite passes" silently annexes whatever maintenance the repo already owes — this task is what makes the "no new failures" criterion satisfiable by this story's own work.
**Status**: Complete

### Delete test-faithful-render.sh and the dead validators
**Task**: 2.2
**Description**: Covers the deletion criteria. `run-all-tests.sh` globs `test-*.sh` and holds no manifest, so deleting the file is sufficient — no runner edit is needed or wanted.
**Status**: Complete

### Sweep for references to the deleted validators
**Task**: 2.3
**Description**: Covers the no-dangling-reference criterion. `check_communication_path` is referenced by `present`'s test suite; `check_render_path` by the render tests. Removing a validator without sweeping its callers turns a green suite red for an unrelated reason.
**Status**: Complete

### Write tests for the suite prune
**Task**: 2.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Verification** (2026-07-25): baseline captured before any deletion — 22 suites, all green, runner exit 0. After: 22 suites (see the count inline change), all green, exit 0, **no new failures**. `cpm/hooks/tests/test-suite-prune.sh` — 22/22. `test-faithful-render.sh` is gone; `check_render_path`, `check_communication_path` and `check_counts_agree` are no longer defined and no file in `cpm/hooks/tests/` calls them; the nine surviving validators are asserted present by name, so an over-prune cannot pass as a clean one; `html-test-helpers.sh` parses. The one dangling reference the sweep found was a historical comment in `test-present-artifact-pivot.sh` naming `check_communication_path` — rewritten, since a comment naming a symbol that no longer exists sends the next reader looking for a phantom.

**Retro**: [Criteria gap] Two of this story's five criteria could not be verified as written. The suite-count criterion ("one fewer than baseline") ignores that Task 2.4, inside the same story, adds a suite — the arithmetic was written for a story that only deletes. And Task 2.3's premise, that `check_communication_path` "is referenced by `present`'s test suite", was one epic stale: the caller was `test-present-html.sh`, deleted in 41-02. Both are the same defect as the epic-level one — a breakdown reasoning about a repo state that had already moved — and both were cheap to catch and cheap to fix, which is the argument for verifying a criterion's *premises* at hydration rather than discovering them at the gate.

---

## Verify the companion-asset carve-out held
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: R6
**Inline change**: The `git diff` criterion was verified as written *and* converted into five durable assertions appended to `test-companion-assets.sh`. A diff-based guard stops meaning anything the moment the work is committed, which is when the carve-out actually becomes vulnerable — it is an exception left standing inside a pivot, the shape a later tidying sweep removes. The assertions name the rules each block exists to carry (design-target-not-parser in `do`, manual-not-markup-oracle in `epics`, repo-files-not-published in the convention, plus its rationale) rather than pinning line numbers or wording, and each was negative-controlled against a stripped copy. (2026-07-25)

**Acceptance Criteria**:

- `git diff` shows no change to the companion-asset awareness block in `cpm/skills/do/SKILL.md` or the mockup-referencing-criteria block in `cpm/skills/epics/SKILL.md` [integration]
- The companion-asset test suite (`test-companion-assets.sh`) passes [integration]
- Companion assets are still written to `docs/{type}/assets/{nn}-{slug}-{label}.html` as repo files, not published [integration]
- must NOT introduce any URL dependency into the `cpm:do` execution path [integration]

### Verify the two protected consumer sites are untouched
**Task**: 3.1
**Description**: Covers the diff and URL-dependency criteria. `cpm:do` opens companion assets as visual design targets mid-execution; a URL would make a pipeline step depend on network reachability. Deletion is precisely when these sites are at risk, which is why this guard sits in this epic rather than standing alone.
**Status**: Complete

### Confirm the companion-asset path survives intact
**Task**: 3.2
**Description**: Covers the suite and storage-path criteria. Companion assets are the one HTML role the pivot retains, and the shared template exists to serve them.
**Status**: Complete

**Verification** (2026-07-25): `cpm/skills/do/SKILL.md` does not appear in `git diff` at all — untouched across all four epics of this chain. `cpm/skills/epics/SKILL.md` is modified, but every hunk sits at lines 3, 19 and 359–383; a byte-compare of the mockup-referencing block against `HEAD` reports identical. No URL of any kind appears in `do/SKILL.md`, so no network dependency entered the execution path. `test-companion-assets.sh` — 36 assertions, 0 failures, including the five new carve-out guards. The convention still carries the companion-asset storage row, the not-published rule, and its rationale. Full runner: 22 suites, 0 failures, exit 0.

**Retro**: [Smooth delivery] The carve-out held without intervention. Worth noting *why*, because it was not luck: R6 was written as a boundary with a stated mechanism ("a URL would make a pipeline step depend on network reachability"), not as a preference, and the three earlier epics each had a criterion pointing at it. A boundary that explains itself survives contact with the sweep that would otherwise tidy it away.

---
