# Release

**Number**: 04-06  
**Source spec**: 04  
**Status**: pending  

## Story 1 — The derived sweeps judge every new column and tool

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Every TEXT column this change adds carries a prose-columns classification, reconciled in both directions so a column added later fails until judged and an entry for a column the schema no longer has fails too. `[unit]`
- The retirement tool is registered and reached by the parity sweeps without an exemption. `[unit]`
- must NOT — No column or tool this change adds is exempted from a derived sweep. `[unit]`

### Task 1 — Classify every TEXT column this change adds in prose-columns

**Status**: complete — Already satisfied when the task was reached: `coverage.retired_reason` and `story_criterion.superseded_reason` are both classified in `tests/support/prose-columns.js`, and `story_criterion.warrant_adr_id` is in the not-prose list. No edit was needed — the sweep reconciles in both directions and is green.  

retired_reason and superseded_reason are judged as prose or not, reconciled in both directions. The sweeps are not discoverable from a migration file, which is why this is budgeted rather than found.

### Task 2 — Run the parity sweeps over the new tool and resolve what they name

**Status**: complete — Ran `parity`, `conformance`, `vocabulary-tools` and `prose-columns` over the registry: 31 pass, 0 fail, nothing outstanding. `retire_coverage` is registered and reached by conformance's whole-registry sweep with no exemption; `parity.test.js`'s `NO_CREATE_TOOL` does not name `coverage`. The one place `coverage` is named is `NOT_A_VOCABULARY` in `tests/vocabulary-tools.test.js:84`, and that is a statement that a binding is not offered from a roster rather than an exemption for a missing tool — its own doc comment says so, and `coverage` now has both `create_` and `retire_` tools, so the skip conceals nothing. Task 3 asserts that positively rather than leaving it read from a comment.  

Registered and reached without an exemption. Retro 05's lesson applies to the estimate: read what each sweep reads before budgeting, because a cost carried over from a differently-shaped change is a guess.

### Task 3 — Write tests for The derived sweeps judge every new column and tool

**Status**: complete  

Covers the three criteria. Where a check reads the suite's own sources, assemble any forbidden string rather than writing it, so the control stays real and the file stays inside its own corpus.

### Retro

- Two of the three tasks were already satisfied when they were reached, and the third found the real defect — which is an argument for reading what a sweep reads before budgeting for it. Task 1's columns were classified and reconciled already; task 2's sweeps came back clean. But driving the mutation showed that `NOT_A_VOCABULARY` in `tests/vocabulary-tools.test.js` was concealing something: with `retire_coverage` filtered out of the registry, the enumeration that exists to name a vocabulary the registry cannot retire stayed green, because `coverage` is skipped before it is judged. The skip is correct in what it says — a binding is not offered from a roster — and it was still hiding a missing tool from the one check that would have named it. A named exclusion that reads as a statement about meaning is still an exclusion from a mechanical check, and the two have to be shown apart rather than argued apart: criterion 3's test now deletes the entry, runs the check over `coverage` on its own merits, and drives the control that proves the answer is not simply an empty enumeration.

## Story 2 — The release and the reinstall

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- After the schema version bumps, reinstalling the plugin from this working tree restores write access to this project's database, which the integrity report describes as skew until it happens. `[manual]`

### Task 1 — Regenerate the committed dump

**Status**: pending  

The dump the pre-commit guard compares, and the vocabulary self-hosting.test.js reads. No requirement states it; the guard is what checks it, which is why it is a task rather than a criterion.

### Task 2 — Reinstall the plugin and confirm write access returns

**Status**: pending  

This project's database migrates past the installed release's target and is served read-only until the reinstall. That is version skew reported as designed, not a fault to diagnose.

## Retro Applied

- 05 · codebase-discoveries · applied — Read what parity, parity-integration, conformance, sparse and prose-columns each key on before running task 2, rather than carrying an estimate over from a differently-shaped change.
- 06 · codebase-discoveries · applied — Where a column or tool this change added is reached by no sweep, that is reported as criterion 3's subject rather than passed over as clean.
- 05 · patterns-worth-reusing · applied — Any string a new check forbids is built by concatenation in task 3, and a first run reporting offenders gets a narrower reading rather than an allow-list or a by-name exemption.
- 07 · testing-gaps · applied — Criterion 3's must-NOT gets a control inside its own test, and the mutation is run to confirm it goes red independently of criteria 1 and 2.
