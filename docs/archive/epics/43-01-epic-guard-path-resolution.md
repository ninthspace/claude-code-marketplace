# Guard Path Resolution

**Source spec**: docs/specifications/43-spec-ralph-autonomous-stalls.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: —
**Retro applied**: 15 · Codebase discoveries · Applied — each new `test_start` covers one assertion (or asserts token-and-reason together), so the suites touched here report an honest N/N rather than adding to the 22/10 problem
**Retro applied**: 20 · Testing gaps · Applied — Story 5's "both locate the same `docs/plans/`" gets a preceding distinctness assertion, so it cannot pass by comparing one thing to itself
**Retro applied**: 20 · Testing gaps · Applied — all three guard tokens (`SUPPRESS`, `SKIP`, `RUN`) are covered under the unset environment, not only the two the criteria name
**Retro applied**: 20 · Patterns worth reusing · Applied — both helpers draw root resolution from one shared implementation, so "they resolve identically" is true by construction and the test is a regression net

## Add an unset-environment fixture to the test harness
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR10 (enabling prerequisite)
**Retro**: [Pattern worth reusing] Implementing the fixture with `env -u` (a child process) rather than saving and restoring the caller's environment made the no-leak criterion true by construction, so its test is a regression net instead of the only thing holding it — the same move retro 20 recommends, arrived at from the implementation side.

**Acceptance Criteria**:

- `test-helpers.sh` provides a helper that runs a command with named environment variables **removed** from its environment, not set to empty [integration]
- The helper's own test asserts a probe sees the variable as genuinely unset (`${VAR+set}` expands empty), distinguishing unset from empty-string [integration]
- must NOT leave the calling shell's environment altered after the helper returns [integration]

### Add the run-with-unset-env helper to `test-helpers.sh`
**Task**: 1.1
**Description**: Covers criteria 1 and 3; produces the helper that Stories 2–5 all consume.
**Status**: Complete

### Write tests for the unset-environment fixture
**Task**: 1.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` — specifically criterion 2's unset-vs-empty probe and the no-leak assertion.
**Status**: Complete

---

## Resolve the project root inside the helpers
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: AD1, NFR1, NFR2
**Retro**: [Codebase discoveries] Two tests passed on the first red run for the wrong reason — the RALPH_STATE override test and the resolver's `rm` check both "passed" because the thing they depended on was missing entirely. A red phase only proves the tests are wired up if every test that *should* fail does; the ones that pass need a second look before the green phase starts, not after.
**Retro**: [Patterns worth reusing] Fixture paths were resolved with `pwd -P` at creation. On macOS `$TMPDIR` sits under `/var`, a symlink to `/private/var`, and `git rev-parse --show-toplevel` reports the physical path — so a logical fixture path would have failed the git-resolution assertions for a reason unrelated to the code under test.

**Acceptance Criteria**:

- `cleancheck-guard.sh` and `progress-classify.sh` each resolve their project root in the order `$CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `$PWD` [tdd] [integration]
- `RALPH_STATE` accepts an argument override [tdd] [integration]
- The resolved root is validated (exists, is a directory) and echoed to stderr [tdd] [integration]
- An unresolvable project root yields `SUPPRESS` and a stderr warning naming the resolution attempt [tdd] [integration]
- Resolution succeeds in a non-git directory by falling through to `$PWD`, and uses no command outside the shell already in use [integration]
- must NOT change behaviour when `CLAUDE_PROJECT_DIR` is set — hook-context callers are unaffected [integration]
- must NOT introduce any deletion path — the guard still never deletes anything [integration]

### Write tests for project-root resolution
**Task**: 2.1
**Description**: Write automated tests covering the story's `[integration]` criteria. Placed first because the story carries `[tdd]` — these fail against today's helpers, which is the red phase.
**Status**: Complete

### Add project-root resolution to `cleancheck-guard.sh`
**Task**: 2.2
**Description**: Resolution chain, validation, stderr echo, suppress-on-unknown. Covers criteria 1, 3 and 4.
**Status**: Complete

### Add the `RALPH_STATE` argument override
**Task**: 2.3
**Description**: Covers criterion 2. The override exists so tests can drive the ralph-detection path directly rather than through a real state file.
**Status**: Complete

### Mirror project-root resolution in `progress-classify.sh`
**Task**: 2.4
**Description**: Covers criterion 1 for the classifier; keeps the two helpers' resolution identical rather than letting them diverge.
**Status**: Complete

### Read the finished helpers end to end against their hook-context callers
**Task**: 2.5
**Description**: Covers both must-NOTs. The end-to-end read made an explicit task rather than left to a verification disposition (retro 17, confirmed five times).
**Status**: Complete

---

## Fix the `/cpm:clean` invocation
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR9
**Retro**: [Patterns worth reusing] The test extracts the invocation from `clean/SKILL.md` and runs it verbatim rather than re-typing it. A re-typed copy would have kept passing after the documented command drifted — which is precisely how this defect survived months of a green suite.
**Retro**: [Testing gaps] Paired the positive criterion with a control that runs the *old* argument form and asserts zero records. Without it, "the new form emits N records" is true for reasons that need not include the fix.

**Acceptance Criteria**:

- With N progress files present and `CLAUDE_PROJECT_DIR` unset, `clean`'s documented invocation emits N records [integration]
- must NOT pass a path argument that an unset variable renders as a bare `/docs/plans` prefix [integration]

### Drop the explicit path argument from `clean/SKILL.md:28`
**Task**: 3.1
**Description**: Covers the must-NOT; the argument would otherwise override the working resolution with an empty-prefixed one.
**Status**: Complete

### Write tests for the `/cpm:clean` invocation
**Task**: 3.2
**Description**: Write automated tests covering the story's `[integration]` criteria — extract the documented command from the skill file and run it against N fixture files.
**Status**: Complete

---

## Cover the skills' calling convention across the guard suites
**Story**: 4
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR7, FR8, FR10
**Retro**: [Codebase discoveries] Story 2's stderr diagnostic put ~90 lines of noise through the runner's output across seven suites, none of which the story's own tests could see. A production requirement (NFR2, report every degraded path) had a cost that only showed up in a different deliverable — the human-readable test output. Suppressing at each suite's shared invocation helper kept the diagnostic where it is asserted and out of everywhere else.
**Retro**: [Testing gaps] `test-progress-classify.sh` reports 33/26, `test-orphan-detection.sh` 33/18 and `test-hooks-integration.sh` 17/9 — pre-existing multi-assertion tests this story left alone rather than expand scope into. `test-cleancheck-guard.sh`'s single instance was split (now 19/19) because it was one test. The residue is named here rather than silently carried.

**Acceptance Criteria**:

- With `.claude/ralph-loop.local.md` present and `CLAUDE_PROJECT_DIR` unset, the guard invoked as `shared/skill-conventions.md` documents returns `SUPPRESS` [integration]
- Two guard calls, same `CPM_SESSION_ID`, `CLAUDE_PROJECT_DIR` unset → `RUN` then `SKIP` [integration]
- Every guard/classifier suite contains at least one case run with `CLAUDE_PROJECT_DIR` unset [integration]
- must NOT export `CLAUDE_PROJECT_DIR` in those cases — the unset case *is* the requirement [integration]

### Add the SUPPRESS-under-unset case to `test-cleancheck-guard.sh`
**Task**: 4.1
**Description**: Covers criterion 1, the requirement's core case — the FR11 autonomous carve-out that has never fired.
**Status**: Complete

### Add the RUN→SKIP-under-unset case to `test-cleancheck-guard.sh`
**Task**: 4.2
**Description**: Covers criterion 2 — the once-per-session guarantee, which currently fails silently because the sentinel write goes to an unwritable path.
**Status**: Complete

### Sweep the remaining three suites for an unset case each
**Task**: 4.3
**Description**: `test-progress-classify.sh`, `test-hooks-integration.sh`, `test-orphan-detection.sh`. Covers criteria 3 and 4. No auto-generated testing task for this story — its entire content is tests.
**Status**: Complete

---

## Verify cross-story integration for guard path resolution
**Story**: 5
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3, Story 4
**Satisfies**: NFR3
**Retro**: [Patterns worth reusing] Retro 20's distinctness rule generalised well here. Before asserting the two arms agree, the fixture asserts that they *are* two arms (one probe per arm, on the variable that distinguishes them) and that each located something. Four cheap assertions turn "both locate the same `docs/plans`" from a claim that can pass on two empty results into one that cannot.

**Acceptance Criteria**:

- A single fixture exercises both paths against one project root: the hook-context call (variable set) and the skill-context call (variable unset), and both locate the same `docs/plans/` [integration]
- `session-start.sh`, `session-start-compact.sh` and `post-compact.sh` behaviour is unchanged — existing suites pass untouched [integration]
- The full run of `run-all-tests.sh` is green [integration]

### Build the dual-path fixture in `test-hooks-integration.sh`
**Task**: 5.1
**Description**: One project root, both call shapes, asserting they locate the same `docs/plans/`. Covers criterion 1.
**Status**: Complete

### Run `run-all-tests.sh` and confirm the full suite is green
**Task**: 5.2
**Description**: Covers criteria 2 and 3 — the NFR3 regression check. No auto-generated testing task for this story; its entire content is tests.
**Status**: Complete

---
