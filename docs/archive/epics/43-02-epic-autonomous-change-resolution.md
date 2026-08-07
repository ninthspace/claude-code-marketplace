# Autonomous Change Resolution

**Source spec**: docs/specifications/43-spec-ralph-autonomous-stalls.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: —
**Retro applied**: 17 · Testing gaps · Applied — each new suite's header names what it does *not* test, and every `[manual]` criterion is verified by reading the edited prose in place rather than by the green count
**Retro applied**: 17 · Patterns worth reusing · Applied — every story gate here includes a deliberate end-to-end read of each edited section before any coverage row is marked, extending the epic's explicit read tasks (1.5, 5.1) to Stories 2, 3 and 4
**Retro applied**: 17 · Codebase discoveries · Applied — any assertion that asks which section a line sits in uses the fence-aware `enclosing_heading` helper from `test-reference-line-propagation.sh`, never a nearest-heading scan
**Retro applied**: 16 · Patterns worth reusing · Applied — `cpm/hooks/tests/` is surveyed for suites asserting against `do/SKILL.md`, `ralph/SKILL.md` and the Change Type Decision convention before Story 1's first edit, and each is judged rework-or-leave
**Retro applied**: 15 · Codebase discoveries · Applied — one assertion per `test_start`, so every suite this epic touches reports an honest N/N
**Retro applied**: 12 · Patterns worth reusing · Applied — Story 4's two sites land together (criterion 1's paired assertion) and each carries one site-specific sentence saying why it is there, rather than restating the rule — which is also Story 4's must-NOT

## Add the autonomous branch to the Change Type Decision gate
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR1, FR2, AD2, AD3, AD4
**Retro**: [Testing gaps] The must-NOT on `AskUserQuestion` was initially unsatisfiable-as-written: the first draft used the token in an explanatory clause ("an `AskUserQuestion` is not a session stop"), which is not an instruction to present one but which no honest grep can tell apart from one. Rewording to "a question posed mid-run" preserved the explanation and made the assertion a true structural proxy rather than a fuzzy one. A must-NOT phrased against a token constrains the prose, not just the behaviour.
**Retro**: [Codebase discoveries] `awk -v` applies escape processing to its value, so a regex passed that way arrives with `\*\*` collapsed to `**` and matches nothing — 20 of 22 assertions failed during the Step 5b pass for a reason invisible in the regex itself. Routing patterns through `ENVIRON` avoids the class entirely, and is the shape to reuse for the remaining SKILL.md slicing in Stories 2–4.

**Acceptance Criteria**:

- `do:476` carries an autonomous branch naming all three dispositions (inline edit / retro observation / amend the epic under execution) and stating `/cpm:pivot` is never invoked [integration]
- End-to-end read of the finished `:476` block: the three dispositions do not overlap or leave a change type unhandled [manual] — prose coherence has no automated oracle
- The blast radius is stated as the open epic doc plus its companion coverage matrix, with everything upstream deferred [integration]
- Amendment requires a citable contradiction — a `file:line`, a named spec requirement, or a conflicting criterion in the same epic [integration]
- A worked separating case — a criterion plausibly both wrong and unmet — is stated with its correct disposition (decline, mark blocked) [manual] — judging whether the example genuinely separates the two readings is human judgement
- must NOT introduce any `AskUserQuestion` in that gate's autonomous path [integration]
- must NOT permit amendment on evidence of the form "tests fail" or "could not implement" [manual] — the rule is prose; its violation is a model behaviour with no static oracle

### Write the autonomous-mode block at `do:476`
**Task**: 1.1
**Description**: The three dispositions and the never-invoke-`/cpm:pivot` rule. Covers criterion 1 and the `AskUserQuestion` must-NOT.
**Status**: Complete

### State the blast radius
**Task**: 1.2
**Description**: Open epic doc plus its companion coverage matrix; everything upstream deferred. Covers criterion 3.
**Status**: Complete

### Write the citable-contradiction rule
**Task**: 1.3
**Description**: Covers criterion 4 and the "tests fail / could not implement" must-NOT. This is the FR2 safety property expressed in prose.
**Status**: Complete

### Write the worked separating case
**Task**: 1.4
**Description**: A criterion plausibly both wrong and unmet, with the correct disposition stated. Covers criterion 5 — retro 20's lesson made concrete.
**Status**: Complete

### Read the finished `:476` block end to end
**Task**: 1.5
**Description**: Covers criterion 2 — the three dispositions neither overlap nor leave a change type unhandled.
**Status**: Complete

### Write tests for the autonomous branch
**Task**: 1.6
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

---

## Define the `**Pivot deferred**` breadcrumb and resolve the `do:64` contradiction
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR3, FR5, NFR7
**Retro**: [Criteria gaps] Criterion 3 named `cpm:status` as a consumer of two fields it does not read, and one of those fields (`**Retro applied**`) is read by no skill at all. The criterion was derived from spec NFR7, which names *no* consumer — the false claim was added in the paraphrase and would have been "verified" by a test asserting a behaviour nothing exhibits. A criterion asserting that consumer X still parses field Y is only checkable once X is confirmed to parse Y at all; confirm the consumer exists before writing the criterion, not when writing its test.
**Retro**: [Testing gaps] The end-to-end read at this gate caught what the green suite could not: `do:64` claimed the amendment path "leaves a `**Pivot deferred**` breadcrumb" unconditionally, while `do:502` defines one per *unreached* artefact — an amendment citing a conflicting criterion in the same epic reaches everything and leaves none. Every structural assertion passed either way, because both sites contain the token. Retro 17's read-the-prose-in-place practice has now paid at two consecutive gates.
**Inline change**: criterion 3 named `cpm:status` as a consumer of `**Retro applied**` / `**Inline change**`; it reads neither, and `**Retro applied**` is read by no skill at all. Restated as the no-regression guarantee that is actually checkable — spec NFR7 names no consumers, so nothing upstream needed correcting (2026-07-26)

**Acceptance Criteria**:

- The `**Pivot deferred**` format is defined once and names all five fields: change, target artefact, story number, date, citation [integration]
- `do:64` permits the epic-scoped amendment and still forbids edits to the spec and other upstream artefacts [manual] — the requirement is whether two sentences now agree
- The `**Retro applied**` and `**Inline change**` field definitions are unchanged, and `**Pivot deferred**` is a distinct field name that `cpm:retro`'s `**Inline change**` scan cannot match [integration]

### Define the `**Pivot deferred**` format
**Task**: 2.1
**Description**: All five fields — change, target artefact, story number, date, citation. Covers criterion 1.
**Status**: Complete

### Amend `do:64`
**Task**: 2.2
**Description**: Permit the epic-scoped amendment, keep forbidding spec and other upstream edits. Covers criterion 2 — the requirement is that this sentence and Story 1's block now agree.
**Status**: Complete

### Write tests for the breadcrumb and parser compatibility
**Task**: 2.3
**Description**: Write automated tests covering the story's `[integration]` criteria, including that the existing field definitions are unchanged and `**Pivot deferred**` cannot be mistaken for one of them.
**Status**: Complete

---

## Report amendments in the run summary
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR4
**Retro**: [Codebase discoveries] The `**Pivot deferred**` field is conditional — it exists per *unreached* artefact, so an amendment citing a conflicting criterion in the same epic writes none. Two separate sites were drafted treating it as though every amendment produced one (`do:64` in Story 2, the Report block here), and the second would have made the run summary silently omit exactly the amendment with no upstream trail. Any new site that reaches for the field as an index of amendments has the same bug; it is a record of deferrals, never a record of amendments.
**Retro**: [Testing gaps] Both instances of the above were written, asserted green, and only then caught by the gate's end-to-end read — the assertions passed because the token was present at both sites, which is all a structural proxy can see. Where a rule is conditional, the structural test can confirm the words exist and never that the condition was honoured.

**Acceptance Criteria**:

- `do` Step 8's Report step defines an amendments block distinct from the deferred-retro list [integration]
- must NOT fold amendments into the existing `**Retro applied**` deferred list [manual] — distinctness is a claim about meaning, not structure

### Add the amendments block to `do` Step 8's Report step
**Task**: 3.1
**Description**: Distinct from the deferred-retro list. Covers criterion 1 and the must-NOT.
**Status**: Complete

### Write tests for the run-summary amendments block
**Task**: 3.2
**Description**: Write automated tests covering the story's `[integration]` criterion.
**Status**: Complete

---

## Wire the behaviour into `cpm:ralph`
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR6, FR12, NFR6, AD5
**Retro**: [Patterns worth reusing] FR12's drift was fixable in a way that cannot recur: state the figure, then assert it against the thing it measures. `test-ralph-autonomous-wiring.sh` extracts the stated length from `ralph/SKILL.md` and compares it to the actual template line, so any edit to the prompt fails the suite until the figure is corrected. Anywhere a document states a number about its own content — a character budget, a row count, a list length — the same two-line assertion converts silent rot into a red test.
**Retro**: [Testing gaps] The first negative control written for that assertion checked that the real template is not 1,100 characters long. It passed, it looked like a control, and it controlled nothing — it shared no logic with the assertion it was guarding. The replacement runs the identical extract-and-compare against a fixture whose stated figure has been mutated. A negative control that does not exercise the same code path as the thing it guards is decoration, and reads as rigour on review.
**Retro**: [Codebase discoveries] Of the two sites this story touched, only the prompt template is operative — the stop hook feeds that line back verbatim each iteration and the loop never reads `ralph`'s override table. The table is maintainer documentation. Anything that must change loop behaviour has to land in the template; a table-only change documents a behaviour the loop does not have, which is exactly why criterion 1 demanded the paired assertion.

**Acceptance Criteria**:

- `ralph`'s override table has a Change Type Decision row **and** `ralph:91`'s generated prompt contains the clause — asserted together in one test, so neither can land alone [integration]
- The prompt clause names the behaviour and its guard, with detail deferred to `cpm:do` [manual] — "names without restating" is an editorial judgement
- `ralph:91`'s stated character budget matches its actual length [integration]
- The generated prompt remains a pure function of its interpolated variables — same epics plus same config yields the same prompt [manual]
- must NOT restate the full rule in the generated prompt [manual] — paired with the criterion above; same oracle

### Add the Change Type Decision row to `ralph`'s override table
**Task**: 4.1
**Description**: The sixteenth row. Covers half of criterion 1.
**Status**: Complete

### Add the prompt clause to `ralph:91`
**Task**: 4.2
**Description**: Names the behaviour and its guard, detail deferred to `do`. Covers the other half of criterion 1, criterion 2, and the restatement must-NOT. This is the operative site — the loop receives this text, not the table.
**Status**: Complete

### Reconcile the stated character budget with the actual length
**Task**: 4.3
**Description**: Covers criterion 3. Either bring the prompt under ~1100 chars or restate the target honestly; 1,477 against a claimed 1,100 is the drift.
**Status**: Complete

### Write tests for the ralph wiring
**Task**: 4.4
**Description**: Write automated tests covering the story's `[integration]` criteria — the paired table-plus-prompt assertion, so neither can land alone.
**Status**: Complete

---

## Verify cross-story integration for autonomous change resolution
**Story**: 5
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3, Story 4
**Satisfies**: FR6 (cross-site coherence)
**Retro**: [Testing gaps] The four-site paired assertion guards *presence*, not *agreement* — and those fail differently. The cross-site read done alongside it found the `ralph` override row asserting that an amendment "leaves a `**Pivot deferred**` breadcrumb" unconditionally, contradicting `do:504`'s per-unreached-artefact rule. All four sites were present; all suites were green; the sites disagreed. A paired-presence test is the right guard against a partial landing and no guard at all against a partial *understanding*, and this epic needed both.
**Retro**: [Scope surprises] The same unconditional-breadcrumb error was written three separate times across three stories — `do:64`, `do` Step 8's block, and the `ralph` table row — each time by a different route, each time caught only by that story's end-to-end read. One conditional rule with a memorable name (`**Pivot deferred**`) drew every downstream site into stating it as unconditional. Where a rule is conditional, the condition needs to travel with the name at every site that mentions it, because the name alone reads as a guarantee.

**Acceptance Criteria**:

- A single end-to-end read of `do:476`, `do:64`, `do` Step 8, the `ralph` override row and the `ralph:91` prompt clause confirms they describe one coherent behaviour with no contradiction between sites [manual] — retro 03's drift defect and retro 17's five-times-confirmed practice, at epic scale
- The four encoding sites are asserted present together in one test, so a partial landing fails [integration]

### Read all five sites together end to end
**Task**: 5.1
**Description**: `do:476`, `do:64`, `do` Step 8, the override row, the prompt clause. Covers criterion 1.
**Status**: Complete

### Add the four-site paired assertion
**Task**: 5.2
**Description**: So a partial landing fails. Covers criterion 2. No auto-generated testing task for this story — its entire content is tests.
**Status**: Complete

---
