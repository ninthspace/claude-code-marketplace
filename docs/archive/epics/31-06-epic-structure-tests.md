# Test Infrastructure & Smoke Verification

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Date**: 2026-04-25
**Status**: Partial — Story 1 Complete; Story 2 Blocked (interactive runtime required)
**Blocked by**: Epic 31-04-epic-deliverable-generation, Epic 31-05-epic-pipeline-handoffs

## Test harness for skill structural assertions
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Inline change**: Renamed `test_audit_skill.sh` → `test-audit-skill.sh` throughout this epic to match the existing runner's discovery glob (`test-*.sh` in `cpm2/hooks/tests/run-all-tests.sh`). The underscore form would never be discovered. Also note the harness was authored incrementally during Epics 31-01..05 (per the prior retro recommendation to write tests alongside implementation), so the file already exists with all structural tests integrated by the time this epic runs (2026-04-26).
**Satisfies**: Spec §6d (test infrastructure) — provides the harness that hosts the auto-generated structural tests from prior epics.

**Acceptance Criteria**:

- `cpm2/hooks/tests/test-audit-skill.sh` exists and is executable using existing `test-helpers.sh` patterns `[manual]` ✓ — file exists at `cpm2/hooks/tests/test-audit-skill.sh`, executable, sources `test-helpers.sh`. Renamed from spec's `test_audit_skill.sh` to match runner glob (see Inline change above).
- Auto-generated structural tests from Epics 31-01..05 (commit SHA capture, deliverable structure, citation format, scale values, no-padding placeholder absence, scoped consistency, effort aggregates, plugin version, library wrapper path) are integrated into the suite `[manual]` ✓ — all 23 tests live in `cpm2/hooks/tests/test-audit-skill.sh`, organised by epic in commented sections.
- Test suite is discovered and runs cleanly via the existing test runner `[manual]` ✓ — `bash cpm2/hooks/tests/run-all-tests.sh` discovers and runs the suite (`test-audit-skill.sh` matches the runner's `test-*.sh` glob).
- All structural tests pass after Epics 31-01..05 are complete `[manual]` ✓ — 23/23 audit-suite tests passing as of commit b8e2527.
- Auto-generated structural tests from Epics 31-01..05 (commit SHA capture, deliverable structure, citation format, scale values, no-padding placeholder absence, scoped consistency, effort aggregates, plugin version, library wrapper path) are integrated into the suite `[manual]`
- Test suite is discovered and runs cleanly via the existing test runner `[manual]`
- All structural tests pass after Epics 31-01..05 are complete `[manual]`

### Create test harness file
**Task**: 1.1
**Description**: Create `cpm2/hooks/tests/test-audit-skill.sh` using the same patterns as the existing `test_*.sh` files in that directory — source `test-helpers.sh`, define test functions with descriptive names, register them with the runner. Covers the harness-existence criterion.
**Status**: Complete

### Integrate auto-generated structural tests
**Task**: 1.2
**Description**: Move or link the auto-generated structural tests from Epics 31-01..05 into `test-audit-skill.sh` so they live in one suite. Tests cover: commit SHA header (1.5 in 31-02), deliverable path (1.2 in 31-04), deliverable structure (2.2 in 31-04), citation format (3.2 in 31-04), scale values (4.2 in 31-04), no-padding placeholder absence (5.3 in 31-04), scoped consistency (6.2 in 31-04), effort aggregates (7.2 in 31-04), plugin version (1.4 + 2.3 in 31-01), library wrapper path (1.4 in 31-05). Covers the integration criterion.
**Status**: Complete

### Verify suite runs cleanly via existing test runner
**Task**: 1.3
**Description**: Confirm that the existing test runner in `cpm2/hooks/tests/` discovers and runs `test-audit-skill.sh` without modification. If discovery requires an update (e.g. an explicit registration), make the minimal change. Run the full suite and confirm pass status. Covers the runner-discovery and pass criteria.
**Status**: Complete

---

## Manual smoke verification
**Story**: 2
**Status**: Blocked — requires interactive runtime
**Blocked by**: Story 1
**Satisfies**: Spec §6 (testing strategy) — covers the dominant `[manual]` verification surface for behavioural criteria.

**Acceptance Criteria**:

- `/cpm2:audit` runs successfully on this repository (claude-code-marketplace), producing a deliverable at `docs/audits/{nn}-audit-{slug}.md` `[manual]`
- `/cpm2:audit` runs successfully on a Laravel fixture project, detecting Laravel + PHP and invoking appropriate tooling `[manual]`
- `/cpm2:audit` runs successfully on a Python fixture project, detecting Python and invoking appropriate tooling `[manual]`
- Non-negotiables verified during smoke runs: `file:line (symbol)` citations present, "Things that look bad but are actually fine" section present, no-padding rule observed (no "Nothing material" placeholders), no-rewrites rule observed (no full-rewrite phrasings) `[manual]`
- All four pipeline handoff options (library, spec, quick, done) exercised at least once across the smoke runs `[manual]`

### Prepare Laravel and Python fixture projects
**Task**: 2.1
**Description**: Identify or create Laravel and Python fixture projects suitable for smoke testing. The fixtures should have at least one stack-tool gap (e.g. missing `larastan` or `mypy`) to exercise graceful degradation. Document the fixture paths.
**Status**: Blocked — no fixture projects available in autonomous loop

### Run smoke test on this repository
**Task**: 2.2
**Description**: Run `/cpm2:audit` on the claude-code-marketplace repo. Inspect the produced deliverable for orient phase coverage, sweep completeness, citation format, structure, and non-negotiables. Document observed findings count, durations, and any gaps. Covers criteria 1 and 4.
**Status**: Blocked — requires interactive AskUserQuestion flows
**Self-assessment**: This repo is a multi-skill plugin marketplace (no `package.json`, no `composer.json` at the root). Stack detection would yield "no stacks detected", so the smoke run is degenerate without first preparing a fixture or running on a real consumer project. Recommend running on a downstream cpm2 consumer once they exist.

### Run smoke test on Laravel fixture
**Task**: 2.3
**Description**: Run `/cpm2:audit` on the Laravel fixture. Confirm Laravel + PHP both detected; confirm `larastan`/`pint`/`composer audit` invocation (or graceful degradation if any missing). Document results. Covers criterion 2.
**Status**: Blocked — no Laravel fixture available
**Self-assessment**: Stack detection logic for Laravel (`composer.json` + `artisan` → Laravel overlay) is documented in SKILL.md §1f and structurally testable, but end-to-end Laravel smoke requires an actual Laravel repo.

### Run smoke test on Python fixture
**Task**: 2.4
**Description**: Run `/cpm2:audit` on the Python fixture. Confirm Python detected; confirm `pip-audit`/`ruff`/`mypy` invocation (or graceful degradation). Document results. Covers criterion 3.
**Status**: Blocked — no Python fixture available
**Self-assessment**: Stack detection logic for Python (`pyproject.toml`/`requirements.txt`/`setup.py` → Python) is documented in SKILL.md §1f and structurally testable, but end-to-end Python smoke requires an actual Python repo.

### Verify non-negotiables and exercise all four pipeline handoffs
**Task**: 2.5
**Description**: Across the three smoke runs, exercise each handoff option (library, spec, quick, done) at least once. Confirm: library handoff produces wrapper entry; spec handoff invokes `/cpm2:spec` with the audit path; quick handoff invokes `/cpm2:quick` with the audit path; done ends cleanly. Document handoff outcomes. Covers criterion 5.
**Status**: Blocked — depends on smoke runs (2.2/2.3/2.4)
**Self-assessment**: Non-negotiables (citations, "looks bad but fine" section presence, no-padding, no-rewrites) are structurally enforced by the test suite for any audit deliverable that lands in `docs/audits/` (vacuous-pass today, format-check on first real run). The four-handoff exercise requires interactive runtime; SKILL.md §4 documents each option's behaviour and library wrapper path is structurally tested.

---

## Lessons

### Smooth Deliveries

- Story 1: All four [manual] criteria delivered cleanly because tests were authored incrementally during Epics 31-01..05 (the prior retro's recommendation paid off — final-epic harness story became a verification gate, not a heavy lift).

### Criteria Gaps

- Story 1 (and Epic 31-06 spec text): the spec named the test file `test_audit_skill.sh` (underscores), but the runner's discovery glob is `test-*.sh` (hyphens). Renamed throughout to `test-audit-skill.sh` as an inline change.
- Story 2: All five [manual] tasks require interactive runtime + multi-stack fixture projects, neither of which are available in the autonomous loop. Marked Blocked with self-assessment notes for each criterion. Recommend running `/cpm2:audit` interactively on a real Laravel/Python project once available, and folding the results into a follow-up retro.

### Patterns Worth Reusing

- "Write tests alongside each implementation story rather than batching them into a final test-suite story" — confirmed effective again. Final-epic test integration becomes pure verification rather than a heavy lift. Reuse for any future cpm2 epic with `[unit]` criteria.

