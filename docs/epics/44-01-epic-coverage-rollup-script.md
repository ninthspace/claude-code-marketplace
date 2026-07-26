# Coverage Roll-Up Script

**Source spec**: docs/specifications/44-spec-coverage-rollup.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: —
**Retro applied**: 20 · testing gaps · Applied — fixture builders use `mktemp -d` per call with a guard that two creates yield different paths; Story 4's two-run determinism test asserts the runs are distinct invocations before comparing output.
**Retro applied**: 21 · codebase discoveries · Applied — Tasks 2.1 and 2.2 route every `**`-bearing pattern through `ENVIRON[...]`, never `awk -v`.
**Retro applied**: 19 · testing gaps · Applied — Story 4's partition and Story 6's invariant assertions read expected values from the spec and matrices at run time rather than pinning them.
**Retro applied**: 21 · testing gaps · Applied — every negative control runs the identical code path against a mutated fixture, and each states what it would catch.
**Retro applied**: 20 · patterns worth reusing · Applied — Story 4 derives traced and untraced from one enumeration, so the partition holds by construction and the assertion is a regression net.

## Establish coverage fixture builders under `TEST_TMPDIR`
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Test Infrastructure — "fixture specs and matrices built under `TEST_TMPDIR`, so partition and fail-closed cases can be constructed rather than found"

**Acceptance Criteria**:

- A fixture builder writes a spec file under `TEST_TMPDIR` with requirements under Must Have / Should Have / Won't Have headings, and a test asserts the written file contains each requirement label it was asked for [unit]
- A fixture builder writes a coverage matrix under `TEST_TMPDIR` with a caller-supplied `**Source spec**` field and caller-supplied rows, and a test asserts each row's label, spec text and Verified cell appear as given [unit]
- The matrix builder can produce a row marked `✓`, an unverified row, a label carrying a qualifier, and a `(story-originated)` row with `—` spec text [unit]
- Builders are sourced by suites the same way `test-helpers.sh` and `git-fixture-helpers.sh` are, and `run-all-tests.sh` needs no change to pick up a suite that uses them [unit]
- must NOT write outside `TEST_TMPDIR` [unit]

### Create `cpm/hooks/tests/coverage-fixture-helpers.sh` with the spec builder
**Task**: 1.1
**Description**: Covers criterion 1 and the MoSCoW heading shapes. Scoped to writing a fixture spec; matrices are Task 1.2.
**Status**: Complete

### Add the coverage matrix builder to the same helper file
**Task**: 1.2
**Description**: Covers criteria 2 and 3 — the four row variants the later stories need: verified, unverified, qualifier-bearing label, and `(story-originated)` with `—` spec text.
**Status**: Complete

### Write tests for Establish coverage fixture builders
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`.
**Status**: Complete

**Retro**: [Testing gap] Mutating the builder and re-running the suite is what proved the controls were controls — three mutations (containment check disabled, every Verified cell rendered `✓`, `mktemp` replaced by a fixed name) each failed the assertion *and* its paired control, which no amount of reading the control would have established.
**Inline change**: dropped the unused `coverage_fixture_destroy` / `coverage_fixture_destroy_all` from the helper library, and added the missing Verified-cell assertion criterion 2 names explicitly (2026-07-26)

---

## Extract requirement labels from a spec and rows from a matrix
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR4; the parsing half of FR1

**Acceptance Criteria**:

- `FR1 (must NOT)` and `FR6 (cross-site)` resolve to `FR1` and `FR6`; a `(story-originated)` row with `—` spec text is reported separately, not as a requirement [unit]
- Requirement labels extracted from a spec include every `- **FRn**` bullet under every MoSCoW heading, and each label carries the heading it appeared under [unit]
- A matrix row's requirement label is read from column 2 and its verification state from the Verified column, with `✓` the only value read as verified [unit]
- must NOT treat a label whose base differs — `FR10` against `FR1` — as the same requirement [unit]

### Add spec requirement extraction
**Task**: 2.1
**Description**: Covers criterion 2. Every pattern containing `**` routes through `ENVIRON[...]`, never `awk -v`, which applies escape processing and collapses `\*\*` to `**` (retro 21).
**Status**: Complete

### Add matrix row extraction and label qualifier resolution
**Task**: 2.2
**Description**: Covers criteria 1 and 3 and the base-label must-NOT. Label from column 2, state from the Verified column, `✓` the only verified value.
**Status**: Complete

### Write tests for Extract requirement labels from a spec and rows from a matrix
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`.
**Status**: Complete

**Retro**: [Testing gap] Eight real-document assertions sat behind an `if [ -r "$REAL_SPEC" ]` guard, and the mutation run — not the suite — is what exposed them: the copied tree reported 38/38 against the repo's 46/46, with no failure to point at. A readability guard converts a moved or renamed document into assertions that quietly stop running, and a passing count is the only thing left to notice it by. Assert readability explicitly instead, so the cause is named.
**Retro**: [Codebase discovery] The library's own prose claimed the shared awk helpers were "prepended to every awk program in this file" while one of the two call sites used a bare `awk '` and duplicated the trimming inline. Neither the tests nor either code path could have caught it — only an end-to-end read of the finished file. Comments asserting an invariant across call sites are worth re-reading against the call sites at the gate.
**Inline change**: replaced the `if [ -r ... ]` guards around the real-document assertions with explicit readability assertions; routed `coverage_spec_requirements` through `_COVERAGE_AWK_LIB` and replaced its inline trimming with `cov_trim` (2026-07-26)

---

## Emit records under both scopes [plan]
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR1; AD2; AD3; NFR3; NFR4

**Acceptance Criteria**:

- Given a spec path, the script emits one record per requirement in that spec, sourced only from matrices whose `**Source spec**` names it [integration]
- Given epic paths, the script emits row-state records for those epics' matrices and no untraced section [integration]
- must NOT include rows from a matrix belonging to a different spec [integration]
- Records are tab-separated and emitted via `printf` — the record format `progress-classify.sh` already uses [integration]
- The script runs under bash 3.2 using `grep`, `awk` and `sed` only — no `jq`, no Python [integration]
- The script emits one output format only — plain tab-separated text with no markup or escape sequences requiring a renderer [integration]

### Create `cpm/hooks/lib/coverage-rollup.sh` and source `resolve-project-root.sh`
**Task**: 3.1
**Description**: The entry point and argument shape. Sourcing the shared resolver is AD5 — it is what makes the documented invocation work with `CLAUDE_PROJECT_DIR` unset, which is spec 43's defect.
**Status**: Complete

### Implement spec scope — matrix discovery by `**Source spec**`
**Task**: 3.2
**Description**: Covers criterion 1 and the must-NOT. Discovery reads the field; never a filename prefix (AD2).
**Status**: Complete

### Implement epic scope — row-state records, no untraced section
**Task**: 3.3
**Description**: Covers criterion 2. Untraced detection is meaningless without a requirement list, so epic scope must not emit one.
**Status**: Complete

### Define and emit the tab-separated record format
**Task**: 3.4
**Description**: Covers criteria 4, 5 and 6. This is the contract both 44-02 and 44-03 consume, not an implementation detail — which is why the story carries `[plan]`. One format serves both readers (NFR4); there is no second rendering mode.
**Status**: Complete

### Write tests for Emit records under both scopes
**Task**: 3.5
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

**Retro**: [Testing gap] Two assertions in the first draft were phrased against the coverage matrix's *Story Criterion* column — text no record type carries — so they held whatever the script did. One of them was the only check on matrix discovery, and the mutation run is what exposed it: disabling `rollup_is_matrix_name` entirely left the suite at 33/33. When a component deliberately drops a column, every assertion phrased in terms of that column is vacuous, and it reads as a perfectly good test.
**Retro**: [Codebase discovery] `read` with `IFS=<tab>` collapses runs of tabs, because tab is IFS *whitespace*. A tab-separated record with an empty field — which is exactly what a story-originated row's empty base is — silently shifts every later field left and still looks well-formed. Splitting by hand with `${x%%$tab*}` is the fix; the record format itself is fine.
**Retro**: [Codebase discovery] `*-coverage-*.md` is not a coverage-matrix glob. `44-01-epic-coverage-rollup-script.md` is an *epic* whose slug begins with "coverage", and epic docs carry a `**Source spec**` field too, so the field match does not catch what the glob lets through — the epic's rows were reported a second time. A matrix is distinguished by `-coverage-` following the numeric prefix and nothing else.
**Inline change**: implemented three fail-closed exits early — unreadable spec, unreadable matrix, and zero matrices matching the spec — because discovery cannot function without them and a spec with no matrices reported as a clean run is complete-by-default. Story 5 still owns their acceptance criteria and test coverage. Also added a refusal for `--matrix-dir` in epic scope, which would otherwise be silently ignored (2026-07-26)
**Story**: 4
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: FR2, FR3, FR10

**Acceptance Criteria**:

- A requirement present in the spec with no matching row in any matrix is reported as untraced [integration]
- Traced and untraced requirements together account for every requirement in the spec — asserted as a partition, not a count [integration]
- All rows `✓` reports *delivered*; none reports *in progress*; a mix reports *in progress*, never a proportion [integration]
- Two runs over an unchanged repository emit an identical record set, so a count that has not moved between iterations is attributable to the work rather than to the report [integration]
- Requirements in the spec's Non-Functional section participate in untraced detection on the same terms as the functional ones [integration]
- A requirement the spec has ruled out under Won't Have is reported as excluded, not as untraced [integration]

### Derive per-requirement state from row-level `✓`
**Task**: 4.1
**Description**: Covers criterion 3. A mix is *in progress*; no proportion is computed or emitted anywhere.
**Status**: Complete

### Detect untraced requirements and emit them as the headline section
**Task**: 4.2
**Description**: Covers criteria 1 and 2. The partition is the criterion, so the output has to make traced ∪ untraced checkable from the records alone.
**Status**: Complete

### Write tests for Derive requirement states and detect untraced requirements
**Task**: 4.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`, including the two-run determinism criterion behind FR10.
**Status**: Complete

**Retro**: [Criteria gap] Untraced detection was built over the spec's `## Functional Requirements` only, because that is what Story 2's criterion named. Running it against spec 44 showed the matrices already carry `NFR1`–`NFR5` rows that no requirement record could ever match, so an untraced NFR was undetectable — a hole in the one measurement the whole spec calls load-bearing. The measurement's scope needed stating as a requirement, not inherited from whichever parser was written first.
**Retro**: [Codebase discovery] Requirement bullets have three shapes across this repository's specs — `- **FR1** — text`, `- **NFR1 — Read-only.** text`, and `- **NFR5 Net reduction** in text` — differing in whether the em dash sits inside or outside the bold span, and whether there is one at all. Specs 40–42 also label requirements `R1`, not `FR1`. Reading the label off the front of the bullet as `[A-Z]+[0-9]+` covers all of them; matching on a known prefix list would not have.
**Inline change**: extended `coverage_spec_requirements` to the non-functional section and added `--nfr` / `--wont-labelled` to the fixture spec builder, after the user chose "extend to NFRs only" over covering architecture decisions as well — an AD is a choice the spec records, not a requirement to be delivered. Two acceptance criteria and matrix rows 27 and 28 added to carry the new behaviour (2026-07-26)

---

## Fail closed on every incomplete computation
**Story**: 5
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: FR5; NFR2

**Acceptance Criteria**:

- Missing spec, unreadable matrix, and zero matrices found each exit non-zero and name what could not be read [integration]
- must NOT exit zero on any path where the computation did not complete [integration]
- Each failure path names the file it could not read, so a failure is distinguishable from a pass that found nothing [integration]
- A spec whose requirement list comes out empty exits non-zero, naming the spec [integration]

### Add fail-closed exits for missing spec, unreadable matrix, and zero matrices found
**Task**: 5.1
**Description**: Covers all three criteria. Each path names the file it could not read; the exit code is the verdict (AD4).
**Status**: Complete

### Write tests for Fail closed on every incomplete computation
**Task**: 5.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

**Retro**: [Testing gap] Each criterion here asks for two things — a non-zero exit *and* a message naming the file — and the first draft captured both from a helper called inside `$(...)`. The status came back; the message was set in a subshell and vanished, so six assertions read an empty string. They failed loudly, but the shape is worth remembering: a helper that returns one value by printing and another by assignment only works when it is not called in a substitution.
**Inline change**: added the empty-requirement-list exit and its criterion. FR5 names three failure shapes; a spec that parses to no requirements is a fourth with the same signature — nothing untraced because nothing was compared — and it was reachable without it (2026-07-26)

**Deferred to 44-03**: the exit code currently means *the computation completed*, not *the spec is delivered*. AD4 wants the promise tag gated on delivery, which needs a third exit code so a read failure stays distinguishable from an honest report of incomplete work. That is FR8's design call and it is recorded on the script itself, at the dispatch.

---

## Assert the read-only guarantee and the input invariants
**Story**: 6
**Status**: Complete
**Blocked by**: Story 4, Story 5
**Satisfies**: NFR1; Invariants

**Acceptance Criteria**:

- The repository is byte-identical before and after a run — `git status` reports no change [integration]
- Every present matrix's `**Source spec**` resolves to a file that exists [integration]
- A `✓` appears only on rows whose criterion text is unchanged since verification — the matrix's own stated rule [manual] — text identity over time has no in-repo oracle

### Assert the read-only guarantee against a run that produced output
**Task**: 6.1
**Description**: NFR1. `git status` reporting no change is satisfied equally by a correct script and by one that never ran, so the same test asserts the run emitted records (retro 22's paired-inverse rule).
**Status**: Complete

### Assert every present matrix's `**Source spec**` resolves to a file that exists
**Task**: 6.2
**Description**: Runs against the repository's real matrices, not fixtures. This is an assertion about the input the script trusts, so a fixture cannot stand in for it.
**Status**: Complete

**Manual criterion resolved.** "A `✓` appears only on rows whose criterion text is unchanged since verification" holds for this epic by inspection: every `✓` was placed at its story's gate, immediately after the criterion as written was verified, and no criterion text was edited afterwards. The three criteria added mid-run — Story 3's one-output-format, Story 4's two, Story 5's one — were written before their rows were marked, not after. There is no in-repo oracle for text identity over time, which is why the criterion is `[manual]`; this is the inspection, recorded rather than assumed.
**Inline change**: relocated `rollup_matrix_source_spec` and `rollup_is_matrix_name` from `coverage-rollup.sh` into `coverage-parse.sh` as `coverage_matrix_source_spec` and `coverage_is_matrix_name`. Both answer document-shape questions, which is what that library is for, and Task 6.2's assertion has to ask the same questions the script asks — a re-typed copy of the name rule in the test would be the AD5 failure mode in miniature (2026-07-26)

---

## Notes

**No generated testing task on Story 6.** Its deliverable *is* the tests — Tasks 6.1 and 6.2 are the assertions — so a "Write tests for…" task would duplicate the story. Its `[manual]` criterion is resolved at the story's verification gate, where `[manual]` criteria are always resolved.

**No integration testing story.** Stories 3–6 already exercise the assembled script end to end, and Story 6 runs it against the repository's real matrices. The genuine cross-component seams — script ↔ `cpm:status` and script ↔ `cpm:ralph` — are integration boundaries 3 and 4, which live in epics 44-02 and 44-03.

**NFR5 and AD5 are deliberately not claimed here.** NFR5 ("`cpm:status` and `cpm:ralph` call the script; neither reimplements…") has no oracle in this epic — it is demonstrated by the consumers, in 44-02 and 44-03. AD5's testable half is the documented invocation running with `CLAUDE_PROJECT_DIR` unset, and the documented invocation lives in `status/SKILL.md` — that is FR6's criterion, in 44-02. Task 3.1 still sources the resolver so the consumer epics have something to assert against.
