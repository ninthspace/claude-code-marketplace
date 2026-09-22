# Repair verbs

**Number**: 05-05  
**Source spec**: 05  
**Status**: complete  

## Why this epic is shaped this way

Three verbs, three stories, no integration story: they touch different tables, share no state, and a fourth story asserting that none reaches another's rows would be asserting a fact the schema already carries.

Each answers a specific mistake a run made and could not undo. Two of them retire and one deletes, and the difference is deliberate. An observation written twice can be withdrawn and left readable, because the historical question — what did this retro hear? — is one somebody asks. A dependency edge written the wrong way round has to be *removed*: a retired edge that still constrained the graph would leave the recovery it exists for impossible, since the correct edge would close a cycle over the wrong one.

The binding deletion needs a delete-by-key on the shared write helper, because the row has a composite key rather than an id. That is the only piece of shared machinery this epic touches.

## One of the three verbs was already here, and two gaps go with it

FR11 names three undoable mistakes as though none of them had a recovery. Two did not. The third — an observation written twice — has had one since the table was built: `update_observation` takes `retired_at` and `retired_reason`, the `CHECK` pairs them so a date with no reason is refused, and `list_observation` omits withdrawn rows. Story 1's criteria were true before the epic opened.

So story 1 shipped a test file and withdrew its implementation task, on a decision taken at the gate rather than on the way past it. The alternative was a `retire_observation` verb on the `retire_coverage` model, and the reason it was not built is worth keeping: to avoid two ways of doing one thing the columns would have had to come off `update_observation`, and `/dpm:retro learn` writes the promotion link and the retirement **in a single call** on purpose, so that a lesson cannot end up retired-but-unpromoted. A surface that reads cleaner in isolation is not cleaner when a skill depends on the coupling the tidying removes.

**Two gaps stay open, and they are recorded rather than absorbed.** Retiring an observation twice silently restamps the date, so when the decision was made is lost — `retire_coverage` refuses that, and this does not. And `retired_at` is a caller-supplied timestamp, which is precisely what epic 05-03 removed from every other stamp in the project. Neither is in this spec's scope, and both are the same argument that spec made, one table over.

## Story 1 — Retire an observation

**Status**: complete — Delivered without new code, on Chris's decision at the gate. Both criteria hold against the surface as it stands — `update_observation` carries the withdrawal and `list_observation` omits withdrawn rows — so the story's work was the assertion rather than a second verb doing what the first already does. Task 1 is withdrawn and records the two gaps a verb would have closed.  
**Blocked by**: —  

### Acceptance Criteria

- An observation written twice can be withdrawn, and the withdrawn row stops appearing in the lists that gather observations. `[integration]`
- control — A live observation under the same retro is unaffected by its sibling's withdrawal and goes on being returned. `[integration]`

### Task 1 — Add the observation retirement verb

**Status**: withdrawn — Dropped on Chris's decision: the capability is already on the surface. `update_observation` takes `retired_at` and `retired_reason`, the table's CHECK pairs them so a date without a reason is refused, and `list_observation` omits retired rows unless `include_retired` asks for them — which is both of this story's criteria. Adding `retire_observation` would have been a second way to do one thing, and taking the columns off the update to avoid that would break `/dpm:retro learn`, which writes the promotion link and the retirement in one call on purpose.

Two gaps a verb would have closed and this does not, recorded for a later spec rather than absorbed here: retiring twice silently restamps the date rather than being refused, so when the decision was made is lost; and `retired_at` is a caller-supplied timestamp, which is exactly what epic 05-03 removed from every other stamp in the project an hour ago.  

Modelled on the coverage retirement that already exists, including the reason it requires. Scope is the verb; the lists that gather observations already omit retired rows.

### Task 2 — Write tests for Retire an observation

**Status**: complete — tests/observation-withdrawal.test.js — four tests against the surface as it already stands, since task 1 was withdrawn. The fixture holds three observations under one retro and a fourth under a story, because both criteria go vacuous on a corpus of one: "the withdrawn row stops appearing" cannot be told from "the list returns nothing" when the retro holds a single row.

The control names the survivors by id rather than counting them, and checks the surviving twin still carries the text it shared with the duplicate — the failure a withdrawal keyed on text rather than id would produce.

Mutation: `selectPage`'s live clause disabled so lists stop omitting withdrawn rows. Three of the four tests fail, including the control, which is right — every one of them is a claim about that clause. The fourth, which asserts the CHECK refuses a date without a reason, is untouched by it and should be.  

Covers the withdrawal and the control that a live sibling goes on being returned, so the test cannot pass against a list that returns nothing.

### Retro

- The story asked for a verb that already existed under another name, and finding that out cost one grep and changed what the story was. FR11 groups three undoable mistakes together and reads as though none of them has a recovery; two do not, but an observation written twice has had one since the table was built — `update_observation` carries `retired_at` and `retired_reason`, and `list_observation` omits withdrawn rows. What was actually missing was the evidence: nothing asserted the recovery *as a recovery*, because the existing coverage of those columns is about the CHECK that pairs them and about what a skill's prose says, and neither would notice `list_observation` starting to return withdrawn rows. So the story became a test file and a withdrawn task.

The alternative that looked tidier was worth rejecting out loud. Adding `retire_observation` on the `retire_coverage` model, and taking the columns off the update to avoid two ways of doing one thing, would have broken `/dpm:retro learn` — which sets the promotion link and the retirement in a single call deliberately, so a lesson cannot end up retired-but-unpromoted. A surface that reads cleaner in isolation is not cleaner when a skill depends on the coupling the tidying removes.

What the mutation showed is worth keeping separately. Disabling `selectPage`'s live clause failed three of the four tests including the control, and that is the correct result rather than an over-tight control: every one of those three is a claim about that clause, and the fourth — the CHECK refusing a date with no reason — is untouched because it is about a different mechanism. A mutation that fails a control is only evidence of over-specification when the control is about something else.

## Story 2 — Delete a dependency

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A dependency edge written the wrong way round can be removed, and the correct edge can then be written without the first closing a cycle over it. `[integration]`
- control — Removing one edge leaves every other edge of that kind in place and readable. `[integration]`

### Task 1 — Add the dependency deletion verb

**Status**: complete — `delete_dependency({id})` on `dependencyTools`, returning the row as it was — a delete is the one call with nothing left to look at afterwards. It re-checks nothing: removing an edge can only shrink what is reachable, so neither a cycle nor an endpoint violation can be introduced by one leaving, which is why `create_dependency` needs its own transaction and this does not.

One existing assertion moved, and it is the "rejection asserted by enumeration fires on the first legitimate change" lesson arriving on schedule. `coverage-retirement-tool.test.js` pinned the whole registry's deleters to `['delete_session']` and filtered by `table.startsWith('coverage')` — which would call story 3's `delete_coverage_story` a coverage deleter, and it is not one. Restated over the table the criterion is about (`table === 'coverage'`), with both sweeps now required to find something so neither can report clean by never matching.  

Deletion rather than retirement, because an edge written the wrong way round has to stop constraining the graph — a retired edge that still closed a cycle would leave the recovery it exists for impossible.

### Task 2 — Write tests for Delete a dependency

**Status**: complete — tests/dependency-deletion.test.js — four tests. Criterion 1 drives the actual recovery rather than asserting a row is gone: it writes the reversed edge, **drives the refusal** that the correct edge would otherwise meet (without which the fixture proves nothing — the wrong edge would not have been in the way), deletes, writes the right edge, and checks register entry 1 is clean afterwards.

The control fixture carries four edges across four stories, two kinds, and a pair of ends that exists under both kinds — so a delete keyed on the ends rather than the id fails it. Survivors are named by id, not counted.

Two mutations. `deleteById` widened to take every row of the table: the control fails **alone**, which is what makes it load-bearing rather than decorative. `delete_dependency` made a no-op that reports the row: all four fail, correctly — every test in the file is a claim about the row going.  

Covers removing a reversed edge and then writing the correct one, plus the control that other edges survive. Drives the actual recovery rather than asserting the row is gone.

## Story 3 — Delete a coverage-story binding

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A binding attached to the wrong story can be removed, and the count at the place that reads bindings falls by exactly one. `[integration]`
- control — The coverage row itself and its bindings to other stories survive the removal unchanged. `[integration]`

### Task 1 — Add the delete-by-key for a coverage-story binding

**Status**: complete — `deleteByKey(db, table, key, where)` in `src/tools/crud.js`, with `deleteById` now delegating to it — written as the general form rather than a second statement beside it, because two DELETEs in that file would be two places for the read-before rule to live and one of them to forget it. It refuses a key of no columns outright: a delete with no key is a delete of the whole table.

`delete_coverage_story({coverage_id, story_id})` in `src/tools/spine/coverage.js`, written by hand rather than produced by `entityTools`. A `deletable` flag on the factory would hand every join a delete tool, and which rows may be removed rather than withdrawn is a per-table decision — `coverage` itself must never have one, and a criterion in epic 04-02 says so. Both key halves are required, because either alone names a set rather than a row.  

The binding has a composite key rather than an id, so this needs a delete-by-key on the shared write helper. Scope is that helper and the one verb using it.

### Task 2 — Write tests for Delete a coverage-story binding

**Status**: complete — tests/coverage-story-deletion.test.js — four tests. The count is asserted as a delta against the reading taken before the removal, never against a literal, because the criterion states a figure and a figure pinned to a number is a change detector the day the fixture grows.

"The place that reads bindings" is driven twice: `list_coverage_story`, and the rendered coverage matrix's "Covered by" cell — a delete that satisfied the list and left the projection alone would be a row that is gone and still printed. The cell is found by its column heading rather than by a position, after the first draft read the neighbouring column and reported the declaring story as having vanished.

The fixture attaches two extra deliveries to one binding and one to another, by the same story — so a delete keyed on `story_id` alone fails the control. Both criteria are vacuous against a single delivery.

Two mutations: keyed on `coverage_id` alone, taking every delivery, fails criterion 1 and the control; `deleteByKey` no longer reading before it writes fails both refusal tests here and in the dependency suite, which is the read-before rule shown to be load-bearing across both verbs.  

Covers the removal and the count falling by exactly one, plus the control that the coverage row and its other bindings survive.

### Retro

- The two verbs this epic actually built cost one shared function between them, and the epic predicted exactly that — "the only piece of shared machinery this epic touches" was right to the line. What it did not predict is the assertion that broke, and the shape of the break is the more useful finding. `coverage-retirement-tool.test.js` enforced "nothing deletes a coverage row" by pinning the registry's whole deleter list to `['delete_session']` and filtering tables with `startsWith('coverage')`. Adding any delete verb anywhere failed the first; adding `delete_coverage_story` would have failed the second while doing nothing the criterion forbids, because `coverage_story` is the join saying a second story also delivers a binding and is not the binding. An enumeration standing in for a category, firing on the first legitimate change — restated over `table === 'coverage'`, with both sweeps now required to find *something* so neither can report clean by never matching.

The projection is where the second half of story 3's criterion actually lives, and reading it took two attempts. "The count at the place that reads bindings" is `list_coverage_story` and it is also the matrix's "Covered by" cell, which is where a person sees it — a delete satisfying the list and leaving the projection alone would be a row that is gone and still printed. The first draft found the cell by column index, read the neighbour, and reported the declaring story as having vanished. Finding it by its heading is the fix and the general rule: a test that locates a cell by position asserts about a table shape nobody promised it.

Worth recording about the mutations rather than the code: the one that removed `readByKey` from the delete path failed tests in *both* stories' files, which is what says the read-before rule is one rule serving two verbs rather than a habit each happened to follow. A mutation crossing story boundaries is evidence the shared helper is genuinely shared.

## Dependencies

- blocks → 05-04
- blocks → 05-07

## Retro Applied

- 10 · A control pinning an exact figure is a change detector wearing a control's clothes · applied — Story 3's criterion states a count outright — "the count at the place that reads bindings falls by exactly one" — so the figure is the criterion rather than a control's habit. It is asserted as a *delta* against the count read before the removal, not against a literal, which keeps it true when the fixture grows. The survivors are named by id rather than counted, for the same reason.
- 10 · A retro's mechanism transfers and its arithmetic does not · applied — Applied before the first line was written, and it paid immediately. This epic adds three recovery verbs, and reading the tree first found that one of them already exists: `update_observation` takes `retired_at` and `retired_reason`, and `list_observation` omits retired rows, so both of story 1's criteria hold against the tree as it stands. Chris's call was to close the story as delivered and verify it rather than add a second way to do the same thing. Two stories of code, not three — a number no estimate would have produced.
- 10 · An assertion that leaves something alone is vacuous when the fixture holds one of it · applied — The governing rule for all three stories, because every one of their controls is of exactly this shape: a live sibling observation still returned, every other edge of that kind still in place, the coverage row and its other bindings surviving. Each is an assertion that a removal left something alone, and each is vacuous if the fixture holds one of the thing being removed. So every fixture here carries at least two of whatever the verb deletes, and the control names the survivor rather than counting the set.
