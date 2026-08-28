# The integrity register

**Number**: 04-04  
**Source spec**: 04  
**Status**: complete — Both stories delivered. Story 2 carries one outstanding task — attaching warrant_adr_id to its five criteria — blocked on the plugin reinstall rather than on the work; its criteria are verified.  

## Story 2's criteria are warranted by a decision, not by a requirement

The new register entry — the one that names a retirement made while the binding was still sound — has no requirement of its own. It was decided in 04-05, which settled that entry 9 narrows to live bindings and that the case it stops covering becomes a separate entry rather than a widened one.

So story 2's four criteria were authored here rather than transcribed, and none of them carries a coverage row. The warrant is the decision, and it is attached where a reader will find it: task 2 of that story exists to set `warrant_adr_id` on each criterion to that ADR, which is the column this spec is adding for exactly this case.

Two consequences worth stating. The story is verified like any other, but it discharges no requirement, so it never appears in the coverage roll-up. And it is the reason this epic waits on the supersession epic rather than only on the retirement one: `warrant_adr_id` is a column that epic adds.

## Story 1 — Entry 9 narrows to live bindings

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A binding whose fragment its requirement no longer contains is named by integrity entry 9 while that binding is live. `[integration]`
- Retiring that same binding removes it from entry 9, which then reports held true, with nothing else in the database changed. `[integration]`
- must NOT — Entry 9 does not name a retired binding whose fragment is still a substring of its requirement. `[integration]`
- control — A second live binding, broken in the same requirement, is still named after the first is retired, so entry 9 going quiet is the retirement rather than the entry ceasing to look. `[integration]`

### Task 1 — Narrow entry 9 to live bindings

**Status**: complete  

The entry goes on naming what somebody still has to decide about, and stops naming what somebody already decided. Scoped to the reading; the second entry belongs to story 2.

### Task 2 — Write tests for Entry 9 narrows to live bindings

**Status**: complete  

Covers all four criteria. The second broken binding is what separates an entry that stopped naming one row from an entry that stopped reading.

### Retro

- The mutation control the retro gate committed to was run, and it drew a line between the two rejections that the criteria do not. Reverting `AND coverage.retired_at IS NULL` fails criteria 2 and 4 and leaves criterion 3 green — because a sound retired binding is named by neither the narrowed query nor the un-narrowed one. Criterion 3 is therefore not a test of the narrowing at all: what it asserts is that entry 9 was still looking while it stayed silent about that row, and the only thing carrying that claim is the live broken binding created on the next line. A must-NOT whose control lives in a different criterion reads as verified when the criterion it depends on is the one that moved.

The reusable half is `everyBrokenBinding` — entry 9's `WHERE` without the narrowing, held as a query in the test file rather than as an edit to `register.js`. It runs on every pass and says, on the same row, "still in the table, still broken, and named by the wider reading" — so the difference between the two lists is provably the narrowing rather than anything the retirement destroyed. A control that exists only while somebody is hand-editing the source is one the next reader takes on trust.

Also: `read_coverage` withholds `spec_fragment` without `include_body`, so the first draft of "nothing else changed" compared the expected string against `undefined` — and passed, on the exact defect it was written to catch. That is the second time this run; the same shape cost epic 04-01 story 5 a red run on `read_story_criterion`.

## Story 2 — The register names a retirement made while sound

**Status**: complete — All five criteria verified, each with its mutation control run. Task 2 — attaching warrant_adr_id to the five criteria, naming accepted ADR 04-05 — is outstanding and blocked on the plugin reinstall: the warrant arm landed in this working tree as epic 04-01 story 5, and the server is the installed 0.6.0 release. Closed on Chris's call that the criteria are the story's measure.  
**Blocked by**: —  

### Acceptance Criteria

- A binding retired while its fragment was still a substring of its requirement, and while its criterion was still live, is named by an integrity entry of its own, which is advisory: reported, and never blocking a restore. `[integration]`
- That entry and entry 9 are separate: a broken live binding is named by entry 9 and not by the new one. `[integration]`
- must NOT — The new entry does not name a binding retired while its fragment no longer matched its requirement. `[integration]`
- control — Retiring a sound binding still succeeds, so the new entry reports the retirement rather than refusing it. `[integration]`
- A dump holding a binding retired while sound restores, and the advisory entry is reported rather than refused. `[integration]`

### Task 1 — Add the entry naming a retirement made while sound

**Status**: complete — Landed as entry 14 with `advisory: true`, the class the pivot on ADR 04-05 added: checkIntegrity leaves `ok` alone for an advisory finding, check_integrity carries the flag per entry, and restore needed no change because it reads `ok`.  

Two entries rather than one, because they ask a reader for two different things. Reports rather than refuses, which is how the register already treats a broken binding.

### Task 2 — Attach the warrant to this story's criteria

**Status**: pending  

Each of the four criteria traces to the register's own decision rather than to requirement text, so each carries warrant_adr_id naming it. Without this the story reads afterwards as four criteria nobody got round to binding.

### Task 3 — Write tests for The register names a retirement made while sound

**Status**: complete  

Covers all four criteria, including the control that a sound binding still retires rather than being refused.

### Retro

- The advisory class cost less than the pivot implied, and the reason is worth keeping: `restore` reads `ok`, and `ok` is a computed answer rather than a stored one. Moving the computation — `violations.every(v => v.advisory)` instead of `violations.length === 0` — meant `src/restore/index.js` was never touched, and the property still lives on the register entry where the ADR wanted it. The two mutations run confirm the seam: dropping `advisory: true` fails four tests across three suites, including the restore one, and dropping the supersession exclusion fails exactly the test written for it.

What the entry cost instead was the set of things that iterate the register, and there were five: `checkIntegrity`, the `check_integrity` tool's per-entry list, `integrity.test.js`'s transcription-parity, `restore.test.js`'s refusal loop, and `sparse.test.js`'s corpus assertion. Two of those held literals — `REGISTER.length, 13` and `report.checked, 14` — which is the fifth and sixth instance of that class this run; both were rewritten to derive, one against `REGISTER_ENTRIES.size` because the transcription is the independent copy the criterion is actually about.

The sharpest evidence came free. `sparse.test.js` failed the moment entry 14 landed, because the ended corpus already retires a binding whose fragment still matched — so the state the entry names was reachable, and being produced, before anything was written to name it. A new entry that fires on the existing corpus is the strongest available answer to "is this check about anything?", and it arrived as a red test rather than as a claim.

- The story's own criteria were consistent, the ADR behind them was consistent, and the conflict was in neither: it was in what every existing member of the register already implied. `restore` throws on any violation `checkIntegrity` reports (`src/restore/index.js:108`), and `tests/restore.test.js` requires a refusal fixture per entry in both directions — so "the register grows an entry" silently meant "a dump holding this state is refused". Thirteen entries all named corruption, so the coupling had never had to be stated, and the ADR that decided to add a fourteenth could not see it because the property lives one module over from anything the decision names.

Found by reading the consumers of the thing being added before writing it, which was the disposition of retro 06's codebase-discoveries lesson taken at this epic's gate. The lesson was about which sweeps read a surface; what it actually caught here was a consumer, not a sweep. The generalisable form is wider than the one recorded: before adding a member to any set the codebase enumerates — a register, a tool list, a taxonomy — read what iterates it, because a property every current member happens to share is a contract nobody wrote down and the next member is where it breaks.

The remedy is a class on the entry rather than a condition in `restore`, for the reason the ADR now states: `restore` asking "is this entry 14?" would be the decision written a second time, in the module least likely to be read when a fifteenth arrives.

## Dependencies

- blocks → 04-06

## Retro Applied

- 06 · codebase-discoveries · applied — Read entry-index.test.js before writing story 2's new register entry, so whatever registration that sweep requires lands with the entry rather than being discovered two stories later.
- 04 · criteria-gaps · applied — Both must-NOT criteria in this epic get their control run as a real mutation — break the narrowing in the entry's own query, watch the assertion go red, restore — rather than a control described in prose beside a passing test.
- 03 · criteria-gaps · applied — Each rejection asserts a named set — which binding ids the entry returns — rather than "the entry is quiet", so an entry that has stopped looking fails it by a nameable amount.
- 06 · patterns-worth-reusing · applied — Establish first whether entry 9 already narrows to live bindings. If it does, the story is the criterion that distinguishes narrowed from never-looked, and that is stated rather than code being written to reach an outcome already in place.
