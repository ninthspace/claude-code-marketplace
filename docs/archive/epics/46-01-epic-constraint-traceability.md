# Environmental Constraint Traceability

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Date**: 2026-07-27
**Status**: Complete
**Blocked by**: —
**Retro applied**: 27 · Codebase discoveries · Applied — `coverage-rollup.sh` states its exclusion rules twice: a 30-line header comment (lines 300–331) and the awk guard at :396. Task 3.1 changes the guard, making the header wrong at the same moment; Task 3.2 asserts both agree.
**Retro applied**: 27 · Patterns worth reusing · Applied — Story 4's baseline diff reads the spec count out of the baseline artefact rather than pinning `46`, so a spec added tomorrow cannot silently narrow the check. Applies to controls as well as assertions.
**Retro applied**: 23 · Testing gaps · Applied — Story 3's two negative controls are this epic's load-bearing assertions. Any mutation used to prove they discriminate prints a count of what it changed before the suite runs.
**Retro applied**: 25 · Patterns worth reusing · Applied — watch for a second use during Step 5b; the environmental-class predicate and the baseline-diff helper are both promotion candidates. Promote on the second call site, not the third.

The substrate the rest of spec 46 stands on: one definition of what makes a label environmental,
and the guard that stops a Scope deferral erasing one. Entirely code, which is why it carries the
guarantees the two prose epics cannot.

## Define the environmental constraint class once [plan]
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: AD1 (label grammar), AD2 (single definition) — foundation for FR2 and FR6

**Acceptance Criteria**:

- A predicate classifying a label as environmental lives in exactly one file under `cpm/hooks/lib/`; `coverage-rollup.sh` calls it rather than restating the prefixes [unit]
- `ENV1` and `ENVX1` classify as environmental; `NFR1`, `FR1`, `ENVIRONMENT1` do not [unit]
- The predicate distinguishes the requirement class from the restriction class, so a caller can ask for either [unit]

`[plan]` because the one-definition constraint is what 46-03's FR7 correspondence assertion is
measured against, and the guard lives inside an awk program that cannot call a bash function —
so "one definition" has a real design question behind it rather than a naming convention.

**Retro**: [Codebase discovery] The single-definition mechanism AD2 asks for already existed — `_COVERAGE_AWK_LIB` in `coverage-parse.sh`, whose own header gives Margot's exact rationale — so the design question `[plan]` was raised for turned out to be a one-token change, while the real hazard was that the library is one single-quoted shell string and a lone apostrophe in a comment silently empties all of it.

### Capture the pre-change record baseline
**Task**: 1.1
**Description**: Records and exit codes from `coverage-rollup.sh --spec` for every spec under `docs/specifications/` and `docs/archive/specifications/` (46 files), committed as a fixture. Lives in Story 1 because it must precede any edit to `coverage-rollup.sh`; it is consumed by Story 4's NFR1 criterion. A baseline taken after the change compares the change to itself.
**Status**: Complete

### Add the environmental-class predicate
**Task**: 1.2
**Description**: In `cpm/hooks/lib/coverage-parse.sh`, alongside the existing label handling. Covers criteria 1 and 2 — the grammar is `ENV` or `ENVX` followed immediately by digits, per AD1's `[A-Z]+[0-9]+` constraint.
**Status**: Complete

### Consume it from coverage-rollup.sh without restating the prefixes
**Task**: 1.3
**Description**: The Scope-deferral guard lives inside an awk program, so a bash function cannot be called from it — the prefix pattern has to reach awk as data (`-v`) or as a shared awk snippet. This is the difference between one definition and two that look alike, and it is the task `[plan]` exists for.
**Status**: Complete

### Write tests for Define the environmental constraint class once
**Task**: 1.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, including the discrimination cases — `ENVIRONMENT1` must not classify, since the prefix is `ENV` followed immediately by digits.
**Status**: Complete

---

## Environmental constraints enter the untraced count
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR2, FR3 (partial — the record-level half)

**Acceptance Criteria**:

- A fixture spec carrying `ENV1` under `## Non-Functional Requirements` emits a `REQ` record and appears in `SUMMARY`'s untraced count [integration]
- must NOT — an `ENV` label is dropped silently when no matrix covers it [integration]
- `ENV` and `ENVX` labels are reported as distinguishable classes, not merged into one count [integration]
- must NOT — `SUMMARY`'s field arity changes; the classes are separable from the labels already present [integration]

The fourth criterion is retro 23's scope-surprise lesson applied ahead of the fact: `SUMMARY` has a
fixed arity consumed by `cpm:status` and `cpm:ralph`, and "reported as distinguishable classes" must
be satisfied by the label prefix already in the `REQ`/`STATE` records, not by new `SUMMARY` fields.

**Retro**: [Testing gaps] The story anticipated no production change and needed none, but writing
the arity must-NOT twice — once as a literal `6` and once as a derived comparison between a spec
with `ENV` labels and one without — was what made it discriminating: a mutation adding a seventh
field *unconditionally* is caught only by the literal, and one adding it *only when an
environmental label is present* only by the pair. A single form of the assertion would have
passed one of the two mutations.

### Write tests for Environmental constraints enter the untraced count
**Task**: 2.1
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. No production change is anticipated — AD1 chose the NFR-heading mechanism precisely because `ENV`/`ENVX` labels parse today, verified empirically before this epic was written. The deliverable is the regression net: nothing in the repo currently asserts that the property AD1 depends on still holds. State in the suite header that these assertions are regression nets over working behaviour, not oracles for new work (retro 23). If the tests find the property does not hold, add an implementation task then — from evidence, not anticipation.
**Status**: Complete

---

## A Scope deferral cannot exclude an environmental constraint
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR6

**Acceptance Criteria**:

- A fixture spec naming `ENV1` in a `### Deferred` bullet leaves `ENV1` untraced, not `EXCLUDED` [integration]
- control — an ordinary `NFR1` named the same way **is** still excluded [integration]
- control — an `ENV1` under a `Won't Have` heading **is** still excluded; only the Scope route is blocked [integration]

The two controls are what stop a guard that excludes nothing at all from passing the first criterion.
The third also pins the boundary AD2 draws: `Won't Have` is the explicit ruling-out and stays
legitimate; the Scope route is the silent one.

**Retro**: [Criteria gaps] The third criterion is written about an `ENV1`-shaped label under
`Won't Have`, and the suite first covered that route with `ENVX1` only — the restriction class, not
the requirement class the criterion names. Nothing failed; the code was right either way. The gap
was that a criterion naming one class had been verified against the other, and it was caught at the
gate by re-reading the criterion text against the fixture rather than against the passing run. A
second Won't Have label (`ENV2`) closed it, because `ENV1` was already spoken for by the Scope route
and one label cannot sit under two MoSCoW headings.

### Add the environmental clause to the Scope-deferral guard
**Task**: 3.1
**Description**: `coverage-rollup.sh:396` — a third condition on the `deferred` disjunct only, leaving the `is_wont` route untouched. Covers criterion 1; criterion 3 is the assertion that this task did not overreach.
**Status**: Complete

### Write tests for A Scope deferral cannot exclude an environmental constraint
**Task**: 3.2
**Description**: Write automated tests covering all three acceptance criteria, including both negative controls.
**Status**: Complete

---

## Verify cross-story integration for Environmental Constraint Traceability
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3
**Satisfies**: NFR1, NFR4, NFR5

**Inline change**: criterion 1 split into a durable half (`REQ`/`EXCLUDED`/exit codes, asserted permanently) and a volatile half (matrix-dependent records, a within-change diff only), plus a new control criterion that reads the spec count from the baseline artefact rather than pinning it (2026-07-27)

**Acceptance Criteria**:

- `REQ` and `EXCLUDED` records, and exit codes, are byte-identical before and after across every spec under `docs/specifications/` **and** `docs/archive/specifications/` (46 files) [integration]
- control — the baseline still covers every spec on disk, its count read from the artefact rather than pinned [integration]
- `REQ = STATE ∪ EXCLUDED` is an exact partition with `ENV`/`ENVX` in play, asserted against the repo's real specs and not only fixtures [integration]
- Suites pass with failing `jq` and `python3` stubs first on `PATH` [integration]

The first criterion departs from spec 46's wording deliberately. NFR1 says "all 45 existing specs in
`docs/specifications/`"; that directory holds 7, and the other 39 are in
`docs/archive/specifications/`. A baseline over 7 files would pass while 39 regressed silently.

The second criterion carries Bella's constraint from the spec's Section 5 perspectives: run the
partition assertion against the repo's real specs, not just fixtures — that is what caught the
spec 45 regression.

**The first criterion was rewritten during Story 4, and this is why.** As drafted it asked for
*every* record to be byte-identical across all 46 specs. That cannot hold in a committed fixture:
the baseline covers spec 46 itself, whose records move every time this epic ticks a row in its own
coverage matrix — Stories 1 and 2 already took `FR2` from `in-progress` to `delivered` and the
`SUMMARY` from `16 0 0 16` to `16 0 1 15`. The artefact was measuring the epic as well as the
parser, and every future epic in this repo would break it the same way.

The split is by what each record depends on. `REQ` and `EXCLUDED` are functions of the **spec
document** alone — which requirements exist, and which the spec ruled out — and that is exactly
what NFR1 says: *"a spec written before this change produces the same `REQ` set"*. `STATE`,
`SUMMARY`, `ROW`, `MATRIX` and `CRITERION` depend on **matrix contents**, which are work in
progress, not parser behaviour. So the durable half is asserted permanently and the volatile half
is a before/after diff taken at the moment of a change, which is the only moment it means anything.
That diff **was** taken, at Task 3.1: the other 45 specs were byte-identical across all record
types, 527 records, and every line of spec 46's drift traced to `✓` marks rather than to the guard.

**Retro**: [Scope surprises] A verification artefact captured *inside* the change it verifies can
end up measuring the change. The 46-spec baseline was taken at Task 1.1, before any code moved,
which was right — but it covered spec 46, whose records the epic then edited by ticking its own
coverage matrix. Nothing about that was visible when the criterion was written; it surfaced at
Task 3.1 when the diff came back dirty for a reason that was not a regression. The general form:
when a baseline covers the repository, check whether the work is going to change part of the
repository the baseline is reading. Splitting records by what they depend on — document versus
matrix — is what made the fixture durable rather than perishable.

### Write integration tests for Environmental Constraint Traceability
**Task**: 4.1
**Description**: Diffs against the Task 1.1 baseline, asserts the partition against real specs, and runs the dependency-stub check. Covers all three acceptance criteria.
**Status**: Complete

---
