# Phase Detection and the Completion Promise

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Date**: 2026-07-26
**Status**: Pending
**Blocked by**: Epic 45-01-epic-autonomous-epic-generation, Epic 45-02-epic-spec-mode-input

## Add the fourth `--verdict` exit code
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR7

**Acceptance Criteria**:

- `--verdict` returns a distinct exit code when the spec is readable and zero matrices name it [tdd] [unit]

### Write tests for Add the fourth `--verdict` exit code
**Task**: 1.1
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. Placed first because the story carries `[tdd]` — the failing test comes before the implementation. The negative control that matters: an unreadable spec must still return the read-failure code, or the new code has simply absorbed the old one.
**Status**: Pending

### Add the exit code to the `--verdict` path only
**Task**: 1.2
**Description**: Covers the criterion. Confined to the `--verdict` branch so default behaviour stays byte-identical — the containment spec 44 used for `--verdict` itself, and the reason `cpm:status` and the existing suite are untouched by this story. Verified today: an empty matrix dir prints `coverage-rollup: no matrix in <dir> names <spec> as its source spec` and exits 1, the same code as a genuine read failure.
**Status**: Pending

---

## Make the roll-up the phase predicate
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: FR8, NFR2

**Acceptance Criteria**:

- The phase judgement comes from the roll-up's records [integration]
- must NOT infer phase from the presence or count of epic files [integration]
- The loop relays named record fields; it counts no rows itself [integration]
- must NOT derive traced or verified state from the records [integration]

### State the AD1 predicate contract at the site that consumes it
**Task**: 2.1
**Description**: Covers all four criteria. AD1's contract is that 0 untraced ends phase 1 and all-rows-verified ends phase 2, with no marker file — so what this task adds is the statement of *where the judgement comes from*, at the site that acts on it. Retro 21: the site that acts is the prompt template, not the override table.
**Status**: Pending

### Write tests for Make the roll-up the phase predicate
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The two must-NOTs are negative structural checks — no glob over `docs/epics/`, no row counting — and are evidence rather than proof; say so in the suite header.
**Status**: Pending

---

## Write the two-phase conditional prompt
**Story**: 3
**Status**: Pending
**Blocked by**: Story 1, Story 2
**Satisfies**: FR6, FR7, NFR1, NFR5

**Acceptance Criteria**:

- The prompt states phase 1's predicate (0 untraced) and phase 2's (all rows verified) separately [integration]
- must NOT emit the completion tag while any requirement is untraced [integration]
- The prompt branches on that code as "phase 1 not started" and on the read-failure code as "stop" [integration]
- must NOT treat a read failure as phase 1 not started [integration]
- Every phase decision defaults to *not complete* when the roll-up cannot compute [integration]
- The template's stated `**Length: N characters**` figure matches its actual length [integration]

### Add the phase-1 branch and its instruction to run `/cpm:epics` autonomously
**Task**: 3.1
**Description**: Covers the first criterion's phase-1 half and the fail-closed criterion. The branch references epic 45-01's autonomous branch rather than restating it, which is why this epic is blocked by that one. AD3 chose one static conditional prompt over a mid-loop rewrite: the stop hook re-reads the state file each iteration, so a rewrite is possible, but it deletes the file if the body ever reads empty.
**Status**: Pending

### Add the phase-2 branch and the exit-code gate
**Task**: 3.2
**Description**: Covers the remaining branch criteria. Four codes now, not three — delivered, outstanding, phase-1-not-started, and cannot-read — and the last two must not collapse into each other. That collapse is the must-NOT.
**Status**: Pending

### Correct the stated prompt length
**Task**: 3.3
**Description**: Covers the last criterion. The figure is 2,736 characters today and AD3 costs roughly 700 more. Retro 24: state a number, then assert it against what it measures — the suite fires on this change, which is the point of stating it.
**Status**: Pending

### Write tests for Write the two-phase conditional prompt
**Task**: 3.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Add the spec-mode promise tag
**Story**: 4
**Status**: Pending
**Blocked by**: Story 3
**Satisfies**: FR10

**Acceptance Criteria**:

- Spec mode's `completion_promise` differs from epic mode's, is fixed at launch, and the emitted tag matches it exactly [integration]
- must NOT put evidence inside the promise tag [integration]

### Add the per-mode tag to Step 2 and the state-file write
**Task**: 4.1
**Description**: Covers both criteria. `completion_promise` is per-run frontmatter, so the tag differs by mode without anyone being offered a choice — which is what preserves the discussion's one-promise argument. The stop hook compares tag contents to the frontmatter with literal string equality after whitespace normalisation, so evidence goes beside the tag, never inside it; spec 44 found this the hard way when AD4 turned out to be unimplementable as written.
**Status**: Pending

### Write tests for Add the spec-mode promise tag
**Task**: 4.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Retro 23's shape applies: any existing assertion phrased per-*skill* about "the promise" now has two subjects where it had one.
**Status**: Pending

---

## Verify cross-story integration for Phase Detection
**Story**: 5
**Status**: Pending
**Blocked by**: Story 1, Story 2, Story 3, Story 4
**Satisfies**: FR6, FR7

**Acceptance Criteria**:

- The command the prompt names, extracted from the prompt and executed, returns the exit codes the prompt's own branches name — for all four codes [integration]

### Write integration tests for Phase Detection
**Task**: 5.1
**Description**: The single most valuable assertion in the epic, and the one retro 24 was written for. Extract the command from the prompt rather than re-typing it (AD5 of spec 43), run it against fixtures built to produce each of the four outcomes, and compare the returned codes to the codes the prompt's branches name.
**Status**: Pending

---

## Notes

**Story 5 exists because spec 44 proved the halves can both be right and still disagree.** Changing that template's `on 3` to `on 4` — a code the script never returns — left every assertion green: the script still exited 3, the prose still read correctly, and the branch could never fire. Four codes make the same failure four times as available.

**Story 1 is the only `[tdd]` story in spec 45**, which is why its testing task is numbered 1.1 rather than last. It is also the only `[unit]` criterion — everything else in this spec is prose asserted across a boundary.

**Blocked by two epics, for two different reasons.** 45-01 because Task 3.1's phase-1 branch references an autonomous branch that must exist to be referenced; 45-02 because a prompt that branches on mode is meaningless until a spec path resolves to one.

**What this epic cannot test.** Whether the loop actually stops. Nothing in the suite launches one. What is checkable is that the instruction is in the operative site, that the command it names returns what the prompt claims, and that the tag stays exactly what the stop hook compares against.
