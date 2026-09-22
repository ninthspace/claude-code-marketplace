# Server-supplied stamps

**Number**: 05-03  
**Source spec**: 05  
**Status**: complete  

## Why this epic is shaped this way

One requirement, two stories, and it is kept apart from the other refusals for a reason that is about release mechanics rather than subject matter. This is the only argument-surface break in the spec, and a suite assertion couples it to skill text: every argument a run passes must be named in that skill's body inside a code span, and the assertion's word boundary means the old argument name does not satisfy a run passing the new one. So each story's code change and its skill-text change are two tasks of one story, and splitting them across commits leaves the suite red in between.

The failure being removed is the one with no error in it. A run supplied a verification time it had never read off a clock, and nothing downstream can tell that row from a real one — while verification time is exactly what the coverage matrix publishes as proof.

The claim story follows the stamp story rather than running beside it, so the second swap is made against a pattern already proved rather than inventing it twice.

## The swap cannot be seen from inside this session, and that is the design

Both tools now take a boolean, and the MCP server this epic was worked through does not. That is not an oversight to reconcile: the server is always the *installed* plugin release, and the working tree is three directories away from it. So `update_coverage` went on accepting `verified_at` throughout, and this run's own verification writes — the six bindings above — used it.

The consequence worth stating is about *evidence* rather than about tooling. Everything asserted here is asserted by the suite, which runs the working tree's code; nothing about the swap is observable through `/dpm:` calls until the plugin is reinstalled. A later run that reaches for the tool to confirm the behaviour will find the old argument and may read it as the work not having landed.

There is nothing to do about it before the next release. It is the same version skew CLAUDE.md records for the schema, arriving at the tool boundary instead — and the reinstall that fixes one fixes both.

## Story 1 — The coverage verification stamp takes a boolean

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A verification call supplying no time records a stamp holding the server's clock at the moment of the call, with the binding hash derived alongside it exactly as it is today. `[integration]`
- must NOT — A call supplying a time for a verification is accepted and the supplied value is stored. `[integration]`
- control — The same call with the time omitted succeeds and stores a stamp, so the refusal is shown to discriminate rather than to reject every call of that shape. `[integration]`

### Task 1 — Swap the verify argument to a boolean and supply the clock

**Status**: complete  

A tool-boundary swap: the handler reads the clock where the caller used to pass one. The hash helpers are unchanged.

### Task 2 — Update the skill text naming the verify argument, in this same change

**Status**: complete — do/SKILL.md Step 5 now names `verified` and says the moment is the server's clock. The five other skills that mention `verified_at` name it as a column a run reads, not an argument it passes, so they stand — except pivot's "never write `verified_at`, and never clear one", whose second clause now has a reachable form in `verified: false`. Left alone here: pivot drives neither coverage tool in its recorded run, so nothing asserts it, and editing it would be a change to a released skill that this story's criteria do not reach. Recorded as the story's observation.  

A suite assertion requires every argument a run passes to be named in that skill's body inside a code span, and its word boundary means the old name does not satisfy a run passing the new one. Splitting this across two commits leaves the suite red in between.

### Task 3 — Write tests for The coverage verification stamp takes a boolean

**Status**: complete — tests/coverage-stamp.test.js — five tests. The pinned clock is an instant nothing in the file passes as an argument, which is what makes "the stamp is the server's" assertable rather than a coincidence of two matching strings.

Five mutations run, each asserted to have applied before its red was read. 1: update stamps a literal → criterion 1 and the control fail, naming the clock. 2: `verified_at` left on the schema beside `verified` → criterion 2 and the declaration test fail alone. 3: create hashes even when nothing was verified → 251 tests fail, which is the finding rather than the control: the guard is enforced by the table's CHECK, so the mutation is caught everywhere at once and discriminates nothing. Recorded as run and not relied on. 4: `verified: false` treated as omitted → the clear arm and substrate-amendments fail alone. 5: do/SKILL.md reverted to `verified_at` → skill-do.test.js:300 fails alone, which is the code/skill coupling asserted rather than described.  

Covers the stamp, the rejection of a supplied time and its control. The stamp is asserted against a clock the test controls, not against a literal.

### Retro

- The epic predicted the code/skill coupling and the prediction held exactly, but the blast radius it did not predict was four times larger and entirely mechanical: 65 tests across 14 files, against a shaping note that named one skill sentence. Every one was a call site passing a timestamp the tool no longer accepts, and grep could not have separated them from the column read-backs beside them — the suite did, in one run. That is the sharper form of the retro lesson this epic adopted at its gate: the mechanism transfers and the arithmetic does not, and the cheapest way to get the arithmetic is to make the change and read the failures rather than to count first.

The more interesting half is what the port revealed about the assertions it touched. Five existing tests asserted `verified_at` against the literal they had just supplied — a shape that says nothing, because the run and the assertion were reading the same string. Making the server supply it forced each of them to pin a clock, and pinning a clock forced the question of whether the pinned value was distinguishable from anything the test passes in. In three files it was not, until it was changed. So a swap undertaken for FR1's reason — a time nobody read off a clock is indistinguishable from a real one — turned out to remove the same indistinguishability from the tests that watched it, which is not something the requirement claimed and not something the epic planned for.

Mutation 3 is worth recording as a null result rather than a control. Making `create_coverage` hash an unverified row failed 251 tests, because the paired-null `CHECK` catches it at every insert in the suite. The guard is real and it is in the right place — but a mutation the schema catches everywhere discriminates nothing, and reading it as evidence for this story's criterion would have been reading somebody else's assertion. Four mutations were evidence; this one was a fact about the table.

Outside scope and recorded rather than done: 24 test files each define their own six-line `refused()` helper. It is a settled idiom rather than this story's duplication, and consolidating it is a quick record, not a refactoring pass.

## Story 2 — The requirement coverage claim takes a boolean

**Status**: complete  
**Blocked by**: Story 1  

### Acceptance Criteria

- A claim call supplying no time records the claim with the server's clock, and the claim hash is computed over the bound set exactly as it is today. `[integration]`
- must NOT — A call supplying a time for a coverage claim is accepted and the supplied value is stored. `[integration]`
- control — The same call with the time omitted succeeds and records the claim. `[integration]`

### Task 1 — Swap the claim argument to a boolean and supply the clock

**Status**: complete  

The same swap on the requirement side. The claim hash goes on being computed over the bound set, which was never the caller's to supply.

### Task 2 — Update the skill text naming the claim argument, in this same change

**Status**: complete — One skill names the claim, not several: `do` Step 8 is the only place in the corpus that ever wrote `coverage_claimed_at`, which the grep confirmed rather than assumed. It now says `coverage_claimed` set to true, and adds that the moment is the server's.  

Same coupling as Story 1's second task, on the skills that make a claim.

### Task 3 — Write tests for The requirement coverage claim takes a boolean

**Status**: complete — tests/requirement-claim-stamp.test.js — four tests, the clock pinned to an instant the file passes as an argument nowhere. Beyond the three criteria it drives the ordering the swap could have broken: `claimComplete` runs after the edits, because `requirement_unclaim_on_text_edit` clears a claim written first, so amending the text and claiming in one call must end claimed.

Four mutations, each asserted to have applied. A: the claim dated by a literal → the three clock assertions fail and nothing else, which also establishes that no existing suite depended on the claim date. B: `coverage_claimed: false` treated as leave-alone → the withdrawal arm fails alone. C: the claim written before the edits → the ordering assertion fails alone, and only that one. D: do/SKILL.md reverted → skill-do.test.js:300 fails alone.  

Covers the claim, the rejection of a supplied time and its control.

### Retro

- The epic's ordering decision paid off in the way it predicted and by a larger margin than it claimed. Sequencing the claim after the stamp was justified as "the second swap is made against a pattern already proved rather than inventing it twice" — and the second swap cost 28 failures against the first's 65, seven call sites against twenty, and no design questions at all, because every one had been settled two hours earlier. Running them in parallel would have paid the design cost twice and would have had the two stories editing the same SKILL.md section.

What the second story found that the first could not is an ordering nobody would have tested for its own sake. `update_requirement` writes the claim *after* the field edits, because `requirement_unclaim_on_text_edit` clears a claim written first — a subtlety that predates this epic and that the swap sits directly on top of, since moving the clock read to the top of the handler is the obvious tidy and would have written the claim early. It is not in any criterion. It came out of reading the handler before editing it, and the mutation that proves it is the one mutation in either story whose failure is confined to a single assertion.

The asymmetry between the two stories' fixtures is worth keeping. Story 1's binding test needed a fresh criterion per row, because the natural key is fragment-and-criterion and the first draft collided against it on the second call. Story 2's claim test needed two bindings for the opposite reason: with one, "the digest covers what is bound" cannot be told from "the digest covers the only row there is". Both are the same question asked of a set — could the fixture have told me if the answer were wrong — and both were answered by the fixture rather than by the assertion.

## Dependencies

- blocks → 05-04
- blocks → 05-07

## Retro Applied

- 10 · A control pinning an exact figure is a change detector wearing a control's clothes · applied — Both stories' must-NOTs are schema rejections — an argument the tool no longer accepts — and the temptation is to pin the refusal's whole message, which `additionalProperties: false` generates and which will move the day FR23 lands and makes that refusal list the arguments it does accept. So the controls assert that the call was refused and that nothing was written, and where the message is read at all it is read for the argument's name, not for the sentence.
- 10 · A retro's mechanism transfers and its arithmetic does not · applied — Written last night, from epic 05-01's own story 4. This epic is the mirror of it — where that story added a read-side field nothing could see, this one *renames a written argument*, and the prediction that no derived sweep notices does not carry: `conformance` reads every argument that declares an enum, `parity` enumerates the registry, and the skills binding reads the SKILL.md against what a run passes. So story 1 opens by measuring the call sites rather than predicting them: 33 sites pass `verified_at` and 11 pass `coverage_claimed_at` by grep, and the number that matters is how many of those are *arguments* rather than column read-backs, which grep cannot tell apart. The count is established by running the suite after the swap, not before it.
- 10 · An assertion that leaves something alone is vacuous when the fixture holds one of it · applied — The sharpest risk in both stories, and it is the fixture rather than the assertion. "The stamp holds the server's clock" asserted against a pinned `now` passes just as well if the handler stored a caller-supplied value — whenever the two are the same string. So the pinned clock in these tests is a value no test supplies as an argument anywhere, and the must-NOT drives a *different* time and asserts the stored stamp is the clock's rather than merely that the call was refused. The question is not whether the assertion was written but whether the fixture could have told it it was wrong.
- 10 · Reproduce the sweep's own baseline before asking it about the intended change · applied — The census that paid for itself twice in 05-01 story 1. Here the sweep that matters is the skills binding in `tests/support/skills.js`: `valuedArguments` covers every *optional* argument of a write tool, and its match is `` `argument\b `` inside a code span — so `` `verified_at` `` does not satisfy a run passing `verified`, which is exactly the coupling this epic's shaping note names. That reading is confirmed against the untouched tree before the swap, so the red that follows is known to be the binding rather than something else.
- 10 · The roll-up's real hazard was in neither criterion · deferred — Deferred rather than applied. Its method — ask what a wrong answer would look like, not whether the answer is right — is sound and is already carried by the fixture lesson above. What it found was a join reaching through the wrong parent, and this epic writes no query at all: it moves a value from an argument to a clock. There is no equivalent wrong-shaped answer to go looking for, and applying it here would be a disposition written to look diligent.
