# Phase Detection and the Completion Promise

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: Epic 45-01-epic-autonomous-epic-generation, Epic 45-02-epic-spec-mode-input
**Retro applied**: 24 · Testing gap · Applied — Story 5 extracts all four codes the prompt branches on and compares them to the codes the extracted command actually returns, rather than asserting the script's behaviour and the prompt's prose separately.
**Retro applied**: 26 · Codebase discovery · Applied — before each template edit in Stories 3 and 6, grep the suites for the sentence being changed; `test-ralph-promise.sh` and `test-ralph-autonomous-wiring.sh` both pin template text verbatim, and Task 3.3 re-measures a figure they assert.
**Retro applied**: 26 · Pattern worth reusing · Applied — for each of Story 5's four codes and Story 6's two must-NOTs, write the concrete wrong edit first, then choose the assertion that changes under it.
**Retro applied**: 21 · Testing gap · Applied — Story 6's first must-NOT already says "the tag" rather than naming `[plan]`; every negative assertion is scoped to the phase-2 branch where the token would be an instruction, with the boundary asserted positively elsewhere.

## Add the fourth `--verdict` exit code
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR7
**Retro**: The script stated its exit codes in three places — the header comment, the usage text, and the branches that return them — and adding a fourth code made all three wrong at once. Two were repaired and only one was asserted; the refactoring pass found the header comment sitting unasserted beside a correspondence assertion that already existed for the usage text. Retro 26's "two readers of the same thing" generalises to two *writers*: when a change makes a documented set stale, count the copies before assuming the one you edited was the only one.

**Acceptance Criteria**:

- `--verdict` returns a distinct exit code when the spec is readable and zero matrices name it [tdd] [unit]

### Write tests for Add the fourth `--verdict` exit code
**Task**: 1.1
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. Placed first because the story carries `[tdd]` — the failing test comes before the implementation. The negative control that matters: an unreadable spec must still return the read-failure code, or the new code has simply absorbed the old one.
**Status**: Complete

### Add the exit code to the `--verdict` path only
**Task**: 1.2
**Description**: Covers the criterion. Confined to the `--verdict` branch so default behaviour stays byte-identical — the containment spec 44 used for `--verdict` itself, and the reason `cpm:status` and the existing suite are untouched by this story. Verified today: an empty matrix dir prints `coverage-rollup: no matrix in <dir> names <spec> as its source spec` and exits 1, the same code as a genuine read failure.
**Status**: Complete

---

## Make the roll-up the phase predicate
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR8, NFR2
**Retro**: Two nets fired on the contract statement and both were pinning wording rather than behaviour — a file-wide ban on the token `untraced`, and a verbatim assertion that spec scope was "deferred". The retro 26 disposition found both by grepping before the edit, which is the first time that discipline paid in advance rather than in hindsight. The durable lesson is in the *replacement*: a ban on a token the contract has to write was rewritten against the **inputs a derivation would need** (a requirement list, the matrices, the Verified column) instead of the words it would use, and the discriminating assertion for "which field does the loop read" came from varying tracing and verification independently — `untraced` is the only `SUMMARY` field that moves with the first and holds still under the second, so naming `delivered` instead fails on real output rather than on a grep.

**Acceptance Criteria**:

- The phase judgement comes from the roll-up's records [integration]
- must NOT infer phase from the presence or count of epic files [integration]
- The loop relays named record fields; it counts no rows itself [integration]
- must NOT derive traced or verified state from the records [integration]

### State the AD1 predicate contract at the site that consumes it
**Task**: 2.1
**Description**: Covers all four criteria. AD1's contract is that 0 untraced ends phase 1 and all-rows-verified ends phase 2, with no marker file — so what this task adds is the statement of *where the judgement comes from*, at the site that acts on it. Retro 21: the site that acts is the prompt template, not the override table.
**Status**: Complete

### Write tests for Make the roll-up the phase predicate
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The two must-NOTs are negative structural checks — no glob over `docs/epics/`, no row counting — and are evidence rather than proof; say so in the suite header.
**Status**: Complete

---

## Write the two-phase conditional prompt
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: FR6, FR7, NFR1, NFR5
**Retro**: Four existing suites locate the prompt template by grepping its opening sentence, and one reads a single stated `**Length:**` figure — so the shape of this change was decided by the test surface before any prose was written. Substituting two clauses into the one template kept every one of those extractors working; a second template, or quoting the opening sentence while describing the substitution, would have broken them, and the first draft did exactly that and was caught by "there is exactly one prompt template line". Worth carrying: when several suites key off one string, that string is an interface, and the design question is which change leaves it intact rather than how many assertions to update.

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
**Status**: Complete

**Inline change**: the file-wide `untraced` allowlist net in `test-ralph-promise.sh` was deleted rather than extended. Spec mode's phase predicate makes the untraced count a legitimate subject throughout the skill, so the allowlist needed a new phrasing per sentence — a net in that state passes on anything already written and fails only on wording. Its purpose survives in the three structural nets beside it (no matrix glob, no Verified column, no requirement list) and in `test-ralph-phase-predicate.sh`'s sentence-scoped predicate. Scanning the whole file that way was tried and abandoned: "an untraced count" and "count the rows" differ by part of speech, not by tokens.

### Add the phase-2 branch and the exit-code gate
**Task**: 3.2
**Description**: Covers the remaining branch criteria. Four codes now, not three — delivered, outstanding, phase-1-not-started, and cannot-read — and the last two must not collapse into each other. That collapse is the must-NOT.
**Status**: Complete

### Correct the stated prompt length
**Task**: 3.3
**Description**: Covers the last criterion. The figure is 2,858 characters today — epic 45-01 Task 1.2 added 122 and corrected the stated figure at the time — and AD3 costs roughly 700 more, with AD6's strip clause (Story 6) on top of that. The estimate is therefore a rough floor rather than a target: this task's job is to re-measure and correct, not to hit a predicted number. Retro 24: state a number, then assert it against what it measures — the suite fires on this change, which is the point of stating it.
**Status**: Complete

**Note**: AD3's cost landed somewhere the criterion does not look. Substituting two clauses left the epic-mode template line at 2,858 — the figure the existing suite asserts — while the *assembled spec-mode* prompt is 3,364, against AD3's estimate of "roughly 3,400". Both new blocks state their own measured lengths (692 and 844) and Task 3.4 asserts them; the assembled figure is recorded in the skill because a reader checking only the asserted number would conclude the two-phase prompt was free.

### Write tests for Write the two-phase conditional prompt
**Task**: 3.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

---

## Add the spec-mode promise tag
**Story**: 4
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: FR10
**Retro**: `{completion_promise}` was interpolated into the state file by Step 3 and never bound anywhere — `ALL_EPICS_COMPLETE` reached the frontmatter only because the template happened to name it. A variable with a use and no definition reads as fine in every review; what exposed it was needing a *second* value. The suite now compares the mapping in the variable table against the token each clause actually emits, which is the same correspondence shape as the exit codes and catches the half-edit that changes one side.

**Acceptance Criteria**:

- Spec mode's `completion_promise` differs from epic mode's, is fixed at launch, and the emitted tag matches it exactly [integration]
- must NOT put evidence inside the promise tag [integration]

### Add the per-mode tag to Step 2 and the state-file write
**Task**: 4.1
**Description**: Covers both criteria. `completion_promise` is per-run frontmatter, so the tag differs by mode without anyone being offered a choice — which is what preserves the discussion's one-promise argument. The stop hook compares tag contents to the frontmatter with literal string equality after whitespace normalisation, so evidence goes beside the tag, never inside it; spec 44 found this the hard way when AD4 turned out to be unimplementable as written.
**Status**: Complete

### Write tests for Add the spec-mode promise tag
**Task**: 4.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Retro 23's shape applies: any existing assertion phrased per-*skill* about "the promise" now has two subjects where it had one.
**Status**: Complete

---

## Verify cross-story integration for Phase Detection
**Story**: 5
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3, Story 4
**Satisfies**: FR6, FR7
**Retro**: The assertion that carries this story is not "the code is 4" but "the code a spec with no matrix *returns* is the code whose branch says go back to phase 1" — a lookup from a fixture, through a real run, into the prompt's own branch text. Building one fixture per *situation the prompt names*, rather than one per exit code, is what makes the comparison meaningful: the fixture encodes the situation, the script decides the code, and the prompt is asked whether it agrees. The 44-03 defect (a branch on a code nothing returns) fails this by construction, and the two mutation controls show it.

**Acceptance Criteria**:

- The command the prompt names, extracted from the prompt and executed, returns the exit codes the prompt's own branches name — for all four codes [integration]

### Write integration tests for Phase Detection
**Task**: 5.1
**Description**: The single most valuable assertion in the epic, and the one retro 24 was written for. Extract the command from the prompt rather than re-typing it (AD5 of spec 43), run it against fixtures built to produce each of the four outcomes, and compare the returned codes to the codes the prompt's branches name.
**Status**: Complete

---

## Strip `[plan]` at the phase transition
**Story**: 6
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: FR13
**Retro**: The ordering must-NOT — "do not begin phase 2 while a generated epic still carries the tag" — reads like a claim only a live loop could test, and it is one *offset comparison* away from being checkable: the strip sentence must start before the phase-2 sentence, and both positions come from the clause itself. Swapping them moves the number. Worth carrying to the next ordering claim about prose: a sentence's position in its block is data, and a rule about what happens first is often assertable without executing anything.

**Acceptance Criteria**:

- Epics generated during phase 1 are stripped before phase 2 begins, by the same rule Step 1b applies at pre-flight [integration]
- must NOT begin phase 2 while an epic the run generated still carries the tag [integration]
- must NOT strip tags from epic docs the run did not generate [integration]

### Add the strip clause to the phase transition
**Task**: 6.1
**Description**: Covers all three criteria. AD6 puts the strip at the point of use rather than at generation, so `cpm:epics` is untouched and the clause goes in the prompt template beside Story 3's phase-2 branch. Keep it to a sentence by *referencing* Step 1b's procedure rather than restating it — the same single-source shape epic 45-01 used for the `cpm:epics` autonomous branch, and the reason NFR5's budget survives this.
**Status**: Complete

### Write tests for Strip `[plan]` at the phase transition
**Task**: 6.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The first must-NOT deliberately says "the tag" rather than naming it, because the clause explaining the rule has to write it — assert positively that the clause states the boundary, and scope any negative to the phase-2 branch where the tag would be an instruction rather than a caution (retro 21). The second must-NOT is the more interesting one: the strip is bounded to the epics phase 1 wrote, so a fixture with a pre-existing epic doc beside the generated ones is the control worth building.
**Status**: Complete

---

## Notes

**Story 5 exists because spec 44 proved the halves can both be right and still disagree.** Changing that template's `on 3` to `on 4` — a code the script never returns — left every assertion green: the script still exited 3, the prose still read correctly, and the branch could never fire. Four codes make the same failure four times as available.

**Story 1 is the only `[tdd]` story in spec 45**, which is why its testing task is numbered 1.1 rather than last. It is also the only `[unit]` criterion — everything else in this spec is prose asserted across a boundary.

**Blocked by two epics, for two different reasons.** 45-01 because Task 3.1's phase-1 branch references an autonomous branch that must exist to be referenced; 45-02 because a prompt that branches on mode is meaningless until a spec path resolves to one.

**Story 6 postdates Story 5, which is why it sits after the integration story rather than before it.** FR13 and AD6 were added by a pivot on 2026-07-26, after this epic was written — the gap was found during epic 45-02's Story 1 context load, not during planning. Appending rather than inserting keeps every `Covered by Story N` reference in the coverage matrix stable. The consequence is that Story 5's four-code integration assertion does **not** cover FR13; Story 6 carries its own end-to-end control, and the combination — a phase transition that both branches correctly *and* strips — is not asserted anywhere. Recorded so a later reader sees the omission was decided rather than overlooked.

**What this epic cannot test.** Whether the loop actually stops. Nothing in the suite launches one. What is checkable is that the instruction is in the operative site, that the command it names returns what the prompt claims, and that the tag stays exactly what the stop hook compares against.
