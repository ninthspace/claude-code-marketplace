# A named epic is checked against its blockers, and an unattended run sequences behind them

**Number**: 13  
**Status**: complete — Closed with all eight criteria met. The refusal and the partition are prose in two skill files, so both bind a run that performs its startup read and nothing else — the limitation quick 12 recorded, unchanged here.  

**Closed**: 2026-09-07T09:20:00.000Z  

## What is changing, and why a refusal

The symptom as reported was that `dpm:do` looks only at stories and never at epic-level dependencies. Half of that is wrong and the correction matters, because it locates the hole: Input step 2, the path taken when no epic is named, already calls `list_epic` with `ready: true`, and `dpm/src/dependency/readiness.js` handles the document-to-document pairing correctly. Story-level readiness is sound too, including the case of a story held by a whole epic, which `ENDS.story`'s second pairing covers.

**The hole is Input step 1.** An epic named as an argument goes through `resolve_reference` and straight into the loop. Nothing reads its edges. The readiness query is reachable only on the path where the user names nothing, and `dpm/tests/skill-do.test.js` exercises only that path — so the defect was never in view of a check.

**`ralph` step 1a is the same defect, unattended.** Epic mode calls `list_epic` with a high limit and keeps everything whose status is `pending`, with no readiness filter anywhere. An autonomous multi-epic run therefore works blocked epics in whatever order the list returns, with nobody watching. `dpm/tests/skill-ralph.test.js` mirrors that filter faithfully, which means the test encodes the defect rather than catching it — it has to change with the skill.

**Why a refusal rather than a gate.** A gate was the obvious shape and is the wrong one. `do`'s Autonomous mode section opens with the rule that when no human is present the gates do not block, so a gate here would hold in exactly the case where someone is watching and fail in the case where nobody is. A refusal is not a gate: it behaves the same either way and needs no autonomous branch. There is precedent in the same file — Input step 3 already stops, rather than gating, when the ready list comes back empty.

The cost is that a user who deliberately wants to work an epic ahead of its blocker is refused. That is the right default here, because the edge exists only if someone authored it and chose a kind whose `gates_work` is set. Withdrawing or completing the blocker, or authoring the relationship over a non-gating kind, are all ways to say what was meant.

**Why held epics stay in ralph's scope.** Filtering the pre-flight set to ready-only was the tempting shape and would break a property the skill already promises: step 2 states that phase is re-read every iteration and never carried, so that a resumed run is correct. A blocker completing mid-run releases its epic, and an epic dropped at pre-flight cannot come back without a relaunch. So the partition reports rather than narrows — the run's scope stays the pending set, and the sequencing is what changes.

## Files affected

- `dpm/skills/do/SKILL.md` — Input step 1 gains the readiness check and its refusal.
- `dpm/skills/ralph/SKILL.md` — step 1a gains the partition and the held-epic report.
- `dpm/tests/skill-do.test.js` — a test over the refusal on the named path.
- `dpm/tests/skill-ralph.test.js` — the epic-set mirror updated to partition rather than filter on status alone, with an assertion over the partition.
- `dpm/.claude-plugin/plugin.json`, `dpm/package.json`, `README.md`, `.claude-plugin/marketplace.json` — the version to 0.7.6, and the marketplace's own version with it.

No source under `dpm/src/` changes. The readiness query, the `ENDS` pairings and the `gates_work` column all already do what is needed; what was missing was a skill reaching for them on one of its two input paths.

## What changed, and how it was verified

`do` Input step 1 now reads the edges into a named epic — `list_dependency` with it as `target_document_id`, `list_dependency_kind` for which kinds carry `gates_work`, and each blocker's own row for `complete` — and refuses when a gating blocker is short of complete, naming each one with its status and stopping. `ralph` step 1a keeps its pending set and adds a second `list_epic` with `ready: true` to partition it, reporting one line per held epic with what holds it. Nothing under `dpm/src/` changed: the readiness query, the `ENDS` pairings and the `gates_work` column already answered the question, and what was missing was a skill asking it on one of its two input paths.

**The `do` test caught a defect in itself before it caught one in the skill.** The first assertion matched `/refuse/i` against the collapsed Input section, and softening the instruction from *refuse* to *gate on it* left the test green — because the word also appears in the paragraph explaining why this is a refusal rather than a gate. That is precisely the failure the `GATES` pattern in `tests/support/skills.js` documents one scope over: a check on a bare word is satisfied by a sentence *about* the thing. Re-matched on the operative clause including `stop`, the same planted defect turns it red. `stop` is the discriminating word, because a gate in this corpus names `AskUserQuestion` and carries on — and absence of a gate cannot be asserted over the section as a whole, since step 2 uses one legitimately to choose among several ready epics.

**The ralph test needed the step-1a reading extracted before it could be exercised twice.** `preflight` drives startup, so calling it a second time in one test first tried to adopt a session as its own predecessor and then collided on the session id. The reading moved into `workingSet`, which is what a run repeats every iteration and what a second `preflight` call cannot represent. Planting the narrowing — `epics` filtered to the ready ones — turns the new test red and leaves the other three green.

Both plants were reverted. The suite is 971 of 971, the 969 standing before this increment plus its two tests. Version 0.7.6 across the four pinned sites, marketplace 3.22.5.

**What this does not cover.** The refusal is prose in a skill file, so it binds a run that reads the file and nothing else — the same limitation quick 12 recorded about the narration rule, and the reason both tests assert the prose rather than an enforced behaviour. A run that skips its startup read has neither rule. Nothing here changes that, and no check in this repository can observe it.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | An epic named as an argument and held by an incomplete blocker over a `gates_work` edge is refused rather than worked, with each blocker and its status named. | `do` Input step 1 now reads `list_dependency` with the epic as `target_document_id`, `list_dependency_kind` for which kinds carry `gates_work`, and each blocker's own row for `complete`, and refuses with each blocker and its status named. The behavioural half is asserted against the fixture's `durability`, which waits on `lifecycle`. |
| ✓ | That check is a refusal and not a gate, so it holds identically under Autonomous mode — where the section's own rule that gates do not block would have let a held epic through. | The step says "refuse: name each one with its status and stop", and carries the reason as prose so a later edit cannot soften it without failing the assertion. `stop` is the discriminating word — a gate in this corpus names `AskUserQuestion` and carries on. |
| ✓ | The readiness answer comes from the edges — `list_dependency` scoped to the epic, with each blocker's own row read for whether it is complete — and never from a status column on the epic. | Asserted behaviourally rather than by reading the prose: the test completes the blocker and re-runs the same reading, and the epic reads as unheld. A refusal that outlived its blocker would have been a status in disguise, and that is the assertion which would catch it. |
| ✓ | `ralph` step 1a partitions the pending epics into those ready now and those held, keeps both in the run's scope, and reports one line per held epic naming what holds it. | `ralph` step 1a keeps the pending set and adds a second `list_epic` with `ready: true` to partition it, reporting one line per held epic from `list_dependency`. The test asserts the working set still holds all pending epics while only the unheld one is offered first, and that a blocker completing releases the held one on a later pass. |
| ✓ | A test asserts `do` refuses a named held epic and turns red when the refusal is removed, verified by planting that removal rather than by reading the assertion. | Met, and the planting is what made it so. The first version of the assertion matched `/refuse/i`, and softening the instruction to "gate on it" left it green — it was matching the paragraph explaining why this is a refusal rather than the instruction itself, which is the trap the `GATES` pattern in `tests/support/skills.js` documents for the word "gate". Re-matched on the operative clause including `stop`, the same planted defect turns it red. Defect reverted. |
| ✓ | A test asserts ralph's partition, replacing the mirror in `dpm/tests/skill-ralph.test.js` that filters the epic set on status alone and so currently encodes the defect. | The step-1a reading was extracted from `preflight` into `workingSet`, so the partition can be re-read without driving startup a second time — which is what a run does every iteration and what a repeated `preflight` call cannot represent, as two session errors demonstrated. Verified by planting: narrowing `epics` to the ready ones turns the new test red and leaves the other three green. Defect reverted. |
| ✓ | Story-level readiness is untouched, including a story held by a whole epic through the document pairing in `ENDS.story`. | Nothing under `dpm/src/` is in this increment's diff, so `readiness.js`, the `ENDS` pairings and `gates_work` are untouched. The existing test `story readiness comes from the edges, and releases when the blocker completes` still passes, including its assertion that a story held by a whole epic over a non-gating kind is not treated as blocked. |
| ✓ | The full suite passes, and the version reads 0.7.6 at the four pinned sites with the marketplace's own version advanced alongside. | 971 of 971 pass, 0 fail — 969 before this increment plus its two tests. Version 0.7.6 at `dpm/.claude-plugin/plugin.json`, `dpm/package.json`, `README.md` and the marketplace's dpm entry, with the marketplace's own version at 3.22.5. |
