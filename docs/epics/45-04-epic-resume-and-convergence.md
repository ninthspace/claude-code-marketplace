# Partial-Set Reporting and Convergence Visibility

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: Epic 45-03-epic-phase-detection
**Retro applied**: 29 · Testing gaps · Applied — every story here is prose in `ralph/SKILL.md` or a guard script, which is the exact shape that passed while a branch was unreachable. Each story's suite builds a fixture in the situation, runs the real script for its exit code, asserts which branch that code selects, and carries a control restoring the pre-fix wording so the assertion is shown to discriminate.
**Retro applied**: 29 · Codebase discoveries · Applied — sub-numbers are `max + 1` identifiers with gaps preserved deliberately, so Story 1's NFR6 assertion must distinguish a preserved gap from a renumber, and the design is judged by what a *repeat* costs rather than only by whether it repeats.
**Retro applied**: 27 · Codebase discoveries · Applied — any story editing `ralph/SKILL.md` greps `test-ralph-promise.sh`, `test-ralph-autonomous-wiring.sh`, `test-aggregation-labelling.sh` and `test-epics-autonomous-mode.sh` **before designing**, not before editing. The stated `**Length:**` figure is 3,188 after epic 46-03 and is read by two suites with `grep -oE`, which breaks silently the moment a second figure exists.
**Retro applied**: 27 · Patterns worth reusing · Applied — Story 3's must-NOT became an ordering claim at the 2026-07-27 pivot, so Task 3.2 asserts it as a comparison of `grep -bo` offsets between the report sentence and the branch sentence, with a control that swaps them, rather than reaching for a running loop it cannot launch.

## Report a partial phase 1 rather than resuming it
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR9, NFR6

**Acceptance Criteria**:

- A phase 1 interrupted with epics already on disk reports the partial set — naming covered and uncovered requirements — and writes no duplicate epic doc [integration]
- must NOT — re-enter `/cpm:epics` over a partial set [integration]
- The partial set duplicates no epic doc and renumbers none [integration]

### Define what the loop does with a partial set
**Task**: 1.1
**Description**: Covers the first two criteria. `cpm:epics` saves incrementally — each epic doc and its matrix are written before the next epic is started — so an interrupted phase 1 always leaves a matrix on disk. That is why exit `4` (*zero matrices name this spec*) cannot fire again, and why the resume path is unreachable through the phase predicate. This task states what the loop reports instead: which requirements the partial set covers, which it does not, and that the epics on disk are left untouched.
**Status**: Complete

### Write tests for Report a partial phase 1 rather than resuming it
**Task**: 1.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Retro 29's branch-reachability shape applies and is the point of the story: build a fixture holding a partial set, run `coverage-rollup.sh --verdict` for its *real* exit code, and assert which branch of the prompt that code selects — never that a sentence exists. Add a control restoring the pre-fix wording so the assertion is shown to discriminate. Epic sub-numbers are identifiers rather than ordinals and gaps are preserved deliberately, so the no-renumber assertion has to distinguish a preserved gap from a renumber.
**Status**: Complete

---

## Detect a leftover progress file across sessions [plan]
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR12

**Acceptance Criteria**:

- Spec-mode pre-flight detects a leftover `cpm:epics` progress file for the same spec even when the guard returns `SUPPRESS` [integration]
- must NOT delete or overwrite that progress file without surfacing it [integration]

### Add the cross-session detection to spec-mode pre-flight
**Task**: 2.1
**Description**: Covers both criteria. The Stale-Progress guard prints `SUPPRESS` while `.claude/ralph-loop.local.md` exists — the FR11 autonomous carve-out, deliberate and not to be removed. This task adds a detection path that does not depend on the guard, scoped to spec mode and to a progress file naming the same spec. The shared deletion rule stands: no path auto-executes a delete.
**Status**: Complete

### Write tests for Detect a leftover progress file across sessions
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The negative control is the guard still returning `SUPPRESS` — if the change worked by weakening the guard, the carve-out is gone and other skills lose their silence during ralph runs.
**Status**: Complete

---

## Report traced and verified counts each iteration
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR11
**Retro**: FR11 asks for "the traced and verified counts", and the roll-up emits neither word — its spec-scope `SUMMARY` record carries `requirements`, `untraced`, `delivered`, `in-progress`. Deriving *traced* or *verified* from those is arithmetic, which `ralph/SKILL.md`'s "the loop relays; it does not compute" rule (NFR2) forbids. The clause prints all four verbatim instead, which satisfies the criterion's own qualifier ("it read from the roll-up") and leaves the arithmetic outside the loop. A requirement phrased in vocabulary its data source does not use is worth catching at spec time.

**Acceptance Criteria**:

- Each iteration reports the traced and verified counts it read from the roll-up [integration]
- must NOT — branch on those counts without having reported them in the same iteration [integration]

### Add the per-iteration count report
**Task**: 3.1
**Description**: Covers both criteria. The loop already runs `--verdict` at the start of every iteration and reads the `SUMMARY` record's `untraced` field and the exit code; nothing prints them. Spec 44's FR10 made the counts stable between runs, which is what makes them worth showing. The N-iteration threshold this story originally carried was **withdrawn at the 2026-07-27 pivot**: `69320ef` made exit `4` the only route into `/cpm:epics`, so a phase that cannot make progress stops rather than repeats, and a threshold on top would guard a case the loop can no longer reach.
**Status**: Complete

### Write tests for Report traced and verified counts each iteration
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The must-NOT is an ordering claim about prose, which retro 27 showed is a comparison of offsets — the report sentence's position against the branch sentence's, both read out of the clause with `grep -bo`, plus a control that swaps them. It does not need a running loop.
**Status**: Complete

---

## Notes

**Amended at the 2026-07-27 pivot on the source spec.** The epic was written before `69320ef`
shipped the phase-liveness guard, and two of its three stories asked for work that guard had already
made unreachable or unnecessary. Story 1 no longer asks for resume — a partial phase 1 always leaves
a matrix, so exit `4` cannot fire and the resume path is unreachable through the phase predicate;
it now asks the loop to report the partial set. Story 3 keeps FR11's reporting half and drops its
N-iteration threshold. Story 2 (FR12) is untouched: nothing has been near the Stale-Progress guard's
`SUPPRESS` carve-out. The filename still reads `resume-and-convergence` because it is an identifier
and the `-epic-`/`-coverage-` derivation rule depends on it.

**No integration testing story, and the reason is not that the epic is small.** Convergence (Story 3) is independent of the partial-set reporting in Stories 1–2. The one genuine cross-story case — detect a leftover progress file across sessions, then report without duplicating — requires a live loop, and nothing in this suite launches one. Asserting it structurally would produce exactly the failure retro 21 named: an assertion that confirms words exist and never that a condition was honoured.

**Story 2 carries `[plan]` because it is the only work in spec 45 that reaches into shipped safety-net behaviour.** The guard's `SUPPRESS` was designed to keep every skill silent during ralph runs; adding a path around it for one skill in one mode is a design decision worth agreeing before implementation, not during it.

**This epic is the safety net over a loop that must first exist**, which is why it is blocked by 45-03 rather than running alongside it. Stories 1 and 3 both assume a phase 1 whose partial state is *readable* — a roll-up that can be asked what the epics on disk cover — and counts that can be reported. Neither assumes a phase 1 that can be re-entered; the pivot established that it cannot be.

**Inline change**: closing note corrected — Stories 1 and 3 assume a readable partial state, not a re-enterable phase 1 (2026-07-27)
