# Write-path refusals

**Number**: 05-02  
**Source spec**: 05  
**Status**: complete  

## Why this epic is shaped this way

Seven guards that have nothing in common except their shape: a write that is legal today, produces no error, and records something nobody decided. They are grouped because the property that binds them is a single one — no stored row changes how it reads — and that property is only checkable across the whole set, which is what the closing story exists for.

**Every rejection here is transcribed from the spec's own must-nots.** None was proposed by this breakdown. A rejection invented in the moment can be unsatisfiable as written, and leaves a story nobody can close.

Two orderings are real. The story that adds the closing hook to the delivery factory blocks the one that adds a second condition to it, because the second has nothing to hang on until the first lands. And all five implementation stories block the closing story, whose subject is the set rather than any member of it.

**The fixtures this epic breaks were always wrong.** A fixture that closes a story over outstanding work is asserting the behaviour the epic exists to stop; a fixture holding a ruled-out requirement with no exclusion was incomplete before the refusal existed. Both are fixed rather than the rules softened, and the exclusion case takes an added test pinning that a stored row in that state still reads as excluded — so the change is proved not to reopen settled exclusions.

## Story 1 made a sentence in /dpm:epics false, and it was amended here

`dpm/skills/epics/SKILL.md` told every run, at the step where a breakdown writes its coverage rows, that *a fragment that is not a substring of its requirement is not refused at the write — it is stored, and the integrity register reports it afterwards as a broken invariant, at a distance from the step that caused it.* FR2 makes that false, and the citation licensing the amendment is that file and line against the requirement's own text.

Left standing it would have been worse than untidy. The sentence exists to explain why Step 1 reads requirement bodies rather than labels, and it argues the point from the write being permissive — so a run that believed it would take *less* care over a fragment, in the exact step the refusal now guards. A rule describing a safety net that is no longer there teaches a run to lean on one that will not catch it, which is what ENV6 says about promising host capabilities, one layer in.

The sentence now says the fragment is refused at the write and that the refusal names the requirement whose text does contain it. `tests/body-asks.test.js` carried the same claim as an assertion — the guessed fragment stored, entry 9 reporting it — and was inverted with it: the write is refused, and the register is asserted to have **nothing** to report, which is what says the state is unreachable through the tools rather than merely discouraged.

**Resolved as an amendment rather than a pivot, with the alternatives put to a gate.** Skill-file rules are epic 05-06's subject, so the case for deferring it there was real; what decided it is that shipping 05-02 without it would release a `/dpm:epics` whose prose contradicts its own write path.

## Two requirements are delivered whole and claimed on less than the whole

FR13 and FR14 each state two obligations and carry bindings for one.

FR13 asks that a second live criterion with the same text under one story is refused, **and that the refusal names the twin's position so the caller can find it**. One binding, quoting the refusal. FR14 asks that a cross-epic delivery is refused **and that the refusal names both epics**. Two bindings, both quoting the same first clause.

Both second clauses are built and tested — the duplicate refusal names the twin's position and the test asserts it; the cross-epic refusal names both epics by slug and the test asserts each. What is missing is a coverage row quoting the clause that asks for it, so the roll-up cannot see the work.

**They are left unclaimed rather than claimed on a reading that stretches**, which is the rule the claim exists to keep: a claim says the bound fragments account for the requirement whole, and here they do not. The repair is a binding each, quoting the naming clause against the criterion that already delivers it — a breakdown's job rather than a run's, which is why this is a section and not an edit.

NFR1 is unclaimed for a different reason and not a gap at all: it promises that *no refusal this spec adds* changes how a stored row reads, and this spec is not finished adding them. Its two bindings are verified against the seven this epic added, and the promise stays open until the last one lands.

## Story 1 — Refuse a fragment that is nowhere in its requirement

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- control — A coverage write whose fragment does occur in the text of the requirement it names succeeds and stores a row. `[integration]`
- must NOT — A coverage write whose fragment occurs nowhere in the text of the requirement it names is accepted, leaving a row for the integrity register to find later. `[integration]`
- Where a sibling requirement in the same spec does contain the fragment, the refusal names that requirement as the one the fragment belongs to. `[integration]`

### Task 1 — Move the register's substring test onto the create path

**Status**: complete — `fragmentPlacement` in `src/coverage/binding.js` answers the same question entry 9 asks in SQL — `instr` there, `includes` here, read off the register's own clause — and `create_coverage` refuses on it. One write path: `update_coverage` offers only position and verification, so a fragment cannot be edited after the fact. The register keeps its copy and needs it, because a restore replays a dump as raw SQL with no tool in the path; what the write path adds is that a mistyped quote stops being something you discover later, after it has counted toward a requirement being discharged. A missing requirement deliberately returns `found`, so the foreign key produces its own refusal rather than this one reporting a fragment absent from text that does not exist.

**Forty tests failed on it**, every one a fixture binding a fragment its requirement never contained. Each was fixed rather than the rule softened, which is the epic's own position on the fixtures it breaks. The interesting ones: four fixtures in the integrity suites build entry 9's violation deliberately and now write it past the tool through the fixture seam, because a restore is the only route left to that state — which is precisely why the register keeps the check; and `tests/reading.test.js`'s paging corpus bound fifty-one invented fragments to one requirement, now one requirement each so every fragment is a verbatim slice of a text it genuinely occurs in.  

The test already exists in SQL in the integrity register. Scope is running it at write time; the register keeps its own copy for what a restore brings in.

### Task 2 — Name the sibling requirement in the refusal

**Status**: complete — The refusal searches the same spec for a requirement whose text does contain the fragment and names it — `it belongs to FR9, so bind it to that requirement` — which is NFR4's rule that a refusal names what to do instead rather than only what was wrong. Scoped to the spec rather than the database, because a fragment turning up under another project's requirement is a coincidence of wording and naming it would send the caller to a document with nothing to do with theirs. Where nothing in the spec holds it, the refusal says the quote needs checking against the text and stops: inventing a nearest match would be a guess presented as a finding, and the mistyped-quote case is the common one. The sibling search is one statement whatever the spec holds, sharing the query that already read the requirement.  

Addresses the third criterion. Searches the same spec for a requirement whose text does contain the fragment, and names it; where none does, the refusal says only that the fragment is unfound.

### Task 3 — Write tests for Refuse a fragment that is nowhere in its requirement

**Status**: complete — Four tests in `tests/coverage-fragment-refusal.test.js`. The rejection is its own test on its own rows and asserts the *absence of a row* rather than merely that something was thrown — a guard raising after the write would satisfy an exception check and leave exactly the binding it exists to prevent. The control is a separate test, so neither depends on the other's assertion order. The sibling criterion carries its own control: a refusal naming a sibling unconditionally would pass the positive assertion, so the test also drives a fragment no requirement holds and requires the message not to claim one — and then follows the refusal's own advice, binding to the named sibling, to show it points somewhere that actually works.

A fourth test compares the write path's `includes` against the register's `instr` on the same five inputs, because two spellings of one predicate is how two answers to one question begin.

Three mutations run and read for their failure text rather than their count: removing the guard fails both rejection tests with "a fragment absent from its requirement was accepted"; naming the sibling unconditionally fails only the sibling test, which is the separation the retro gate asked for; inverting the predicate fails the control, the rejection and the agreement test together. The control test also pins the two boundary cases a substring rule must admit — the requirement's whole text, and a slice starting mid-word — because the rule is occurrence rather than tidiness.  

Covers the rejection, its control and the sibling-naming criterion, with the rejection driven on its own rows so it can fail without depending on the control's assertion order.

### Retro

- Moving a check from the register onto the write path cost forty failing tests, and every one was a fixture asserting the state the check now forbids — which is the honest measure of how long that state had been reachable. Three kinds, and they wanted different fixes. Most were paraphrases where a verbatim slice would have done, including two written by this same session eight hours earlier; those were simply corrected. One was a paging corpus binding fifty-one invented fragments to a single requirement, fixed by giving each row its own requirement so every fragment quotes a text it genuinely occurs in. The interesting four build the violation deliberately, for the integrity register's own tests, and they could no longer go through the tool at all — they now write through the fixture seam, which is exactly right: after this story a restore is the only route to a broken binding, and that is precisely why the register keeps a check the write path duplicates. The generalisable part is that a guard's fixture cost is not noise to be minimised. Each failure named a place where the codebase had written down, as a test, that the forbidden thing was allowed — and the four that had to keep doing so are the ones that told us what the register is now for.

## Story 2 — Refuse a story close over outstanding tasks

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A story with a task still outstanding beneath it is set finished. `[integration]`
- The refusal lists every outstanding task beneath that story, so it performs the reconciliation rather than asking for one. `[integration]`
- control — The same story with every task beneath it finished is set finished without objection. `[integration]`
- control — A task is set finished exactly as it is today, the closing hook being one that a task passes none of. `[integration]`

### Task 1 — Add the optional closing hook to the delivery update factory

**Status**: complete — `deliveryTools` takes an optional `closing` hook, called before the write when a call sets `status: 'complete'` and refusing by throwing. Three decisions, each of which could have gone the other way and each written into the code rather than left to be inferred. Only `complete` fires it, because `superseded` and `withdrawn` say the work was replaced or dropped — decisions to stop rather than claims to have finished — and refusing them would block the legitimate way to retire a story with work still under it. The hook receives the **resolved** row, the stored row merged with the call's changes, so a condition can be satisfied by a column already stored rather than one restated in the closing call; judging the arguments would refuse a row for failing to repeat what it already says, which is retro 02's rule. And it runs before the write, like every other guard here.

A table passing no hook reaches the same `update` call it always did, which is the contract the task path is held to.  

The seam only: a hook asked for when a call sets the finished status, receiving the resolved row. A table that passes none behaves exactly as it does today, and that is the contract the task path asserts.

### Task 2 — Give the story its outstanding-task condition

**Status**: complete — `storyClosing` in the new `src/tools/spine/closing.js`, passed where `story` is registered; `task` passes nothing and is untouched. Outstanding means `pending` and nothing else — a task that is `superseded` or `withdrawn` has been decided about, and counting those would refuse a story whose every open question is settled, which is the state the check exists to reach. The refusal lists each outstanding task by number and title rather than counting them, so it performs the reconciliation the run did not: a message saying three tasks are outstanding leaves the caller where they started.

In its own module rather than inline in the registry, because the registry's job is saying which tables get which tools, and a paragraph about outstanding work inside a registration is one neither file's reader expects to meet.

**The fixture cost was one test, against several predicted.** The plan named `skill-do.test.js:402` as confirmed breakage; it does not break, because that fixture completes every task before closing the story — it models what the loop actually does. The one that broke is a test of the status vocabulary walking a story through all four values while a task sat pending beneath it, which had no interest in stories or tasks at all.  

Addresses the first two criteria. The condition names every outstanding task in the refusal; the task table passes no hook and is untouched.

### Task 3 — Write tests for Refuse a story close over outstanding tasks

**Status**: complete — Five tests, and the fifth exists because running the mutations found two controls that could not fail.

Of the four mutations the plan named, three survived the first pass. One had not applied at all — the edit silently matched nothing — which is retro 01's lesson arriving on this run's own work; every mutation since asserts it landed before its result is read. The other two survived honestly, and both were real gaps. Judging the call's arguments instead of the resolved row changed nothing any assertion looked at, because the condition only needs the id; asserting that the refusal names the story's **number**, which a caller setting only `status` never supplies, kills it — and story 3 depends on that resolution outright. Handing the hook to `task` as well is inert by construction, since no task is the parent of a task, so no behavioural test can ever catch it; that one is asserted structurally, by reading the registration and requiring it to carry no `closing`, with a control proving the same reading does find one on the story.

All four now land and all four are killed, each failing only the test that owns it. The rejection asserts the story's stored status rather than the throw, because a guard refusing after the write would satisfy an exception check and leave exactly the state this removes.  

Covers the rejection and both controls, the second being the task path proved unchanged. Existing fixtures that close a story over outstanding work are fixed rather than the rule softened — they assert the behaviour this story removes.

### Retro

- Four control mutations were planned and three survived the first pass, for three different reasons that wanted three different fixes — which is a better argument for running them than any of them is alone. One had silently not applied: the edit matched nothing and the suite went green, so the "survival" was a fact about my sed and not about the code. That is retro 01's lesson landing on the run that had adopted it four hours earlier, and every mutation since asserts it changed the file before its result is read. The second survived honestly because nothing any assertion looked at came from the thing being mutated — swapping the resolved row for the call's arguments left the condition working, since it only needs an id; making the refusal name the story's *number*, which a caller setting only `status` never supplies, is what turned that into a check. The third cannot be caught behaviourally at all: handing the story's closing hook to `task` as well is inert, because the condition reads the tasks whose parent is the row being closed and no task is the parent of a task. It is wrong the moment any closing condition looks at something a task has, and no test driving the surface will ever see it — so that control reads the registration instead, with its own control proving the same reading finds the hook on the story. The generalisable shape: "the mutation survived" has at least three meanings, and only one of them is "the code is right".

## Story 3 — Require a note when a story closes over an unverified binding

**Status**: complete  
**Blocked by**: Story 2  

### Acceptance Criteria

- must NOT — A story carrying an unverified bound coverage row and no status note is set finished. `[integration]`
- control — The same story with a status note is set finished, so the unverified binding is shown not to be what was refused. `[integration]`
- A status note already stored on the row satisfies the condition without being restated in the closing call, and a note of whitespace alone does not satisfy it. `[integration]`

### Task 1 — Add the unverified-binding condition to the story's closing hook

**Status**: complete — A second condition on the same hook, checked after the outstanding-tasks one. It refuses the **missing note**, never the unverified binding: a story can legitimately finish over work somebody else verifies, so what FR4 forbids is the silent close, and the refusal says so — "which is allowed, so record why in status_note and the close proceeds". The unverified bindings are named by their requirement's label rather than an id, so the run reading the refusal can check it against the spec in front of it.

The stored-note case needs no code of its own: the hook receives the resolved row, so a story already recording why it closes early satisfies the condition without repeating itself in the closing call. That is the half of story 2's seam this story was waiting on, and it was confirmed by closing a story whose note was set at create time with a call carrying only `status`. Whitespace alone does not satisfy it — an empty note that looks like a full one is the one way to pass this rule while saying nothing.

Retired bindings are excluded: a withdrawal carries its own reason, so somebody has already decided.

**The fixture cost was one test, and a telling one.** `skill-do.test.js` models the loop and closed its story straight after finishing the tasks — skipping Step 5, where the loop records a ✓ on each binding. It now verifies before closing, which is the order the real loop works in and what the fixture meant to model.  

Addresses all three criteria. It refuses the missing note, never the unverified binding, and reads a note already on the row rather than requiring the closing call to carry one.

### Task 2 — Write tests for Require a note when a story closes over an unverified binding

**Status**: complete — Five tests. The control carries the **same** unverified binding as the rejection and differs only in the note, and asserts afterwards that the binding is still unverified — which is what says the note was the condition rather than something having changed about the binding. Without that pairing the rejection would be equally satisfied by a rule refusing every close over unverified work, a stricter rule FR4 explicitly does not want and that no assertion about the refusal alone could distinguish.

The whitespace case drives three shapes rather than one, because a guard checking only the empty string admits the other two and reads as working; its control on the same rows is a single full stop, a reason badly given but given. A fifth test pins that a retired binding is not something to close over, since a withdrawal already carries its reason and counting it would demand a second reason for the same decision.

Four mutations, all asserted to have applied and all killed: refusing the binding rather than the missing note; accepting whitespace; counting retired bindings; dropping the requirement label from the refusal. The last three each fail only the test that owns them.  

Covers the rejection, its control and the stored-note case, including a note of whitespace alone failing to satisfy it.

### Retro

- The one fixture this story broke was the one modelling the loop it constrains, and it broke because the model was a step short. `skill-do.test.js` finishes a story's tasks and then closes it — but the real loop records a verification on each binding at Step 5 before Step 6 sets the status, and the fixture skipped straight from one to the other. FR4 caught that: closing over unverified bindings with nothing said. The fix was to verify first, which is what the fixture meant all along. Worth keeping because of what it says about where a guard's cost lands. Across three stories the counts were forty, one and one, and the pattern is not size — it is whether the codebase's habits already matched the rule. Story 1's forty were fixtures inventing fragments nobody had ever checked; story 2's one was a status-vocabulary test with no interest in stories or tasks at all; this one's is a simulation of the very loop the rule governs, and it was wrong in a way that mattered. A guard that breaks the fixture modelling its own subject has found something; a guard that breaks forty unrelated ones has found a habit.

## Story 4 — Refuse a ruled-out requirement with no exclusion

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A create or an update that would leave a requirement ruled out with no exclusion recorded is accepted. `[integration]`
- control — The same call carrying an exclusion succeeds, and a requirement at any other priority with no exclusion succeeds too. `[integration]`
- An update naming only the priority is judged against the exclusion already stored on the row rather than against the absence of one in its own arguments. `[integration]`

### Task 1 — Guard the create handler

**Status**: complete — `refuseUnexplainedExclusion` judges the row the write would leave, and `create_requirement` assembles that row before judging it rather than reading the arguments — so this path and the update path ask one question of one shape. The refusal names the field and the values it may take, which is what makes it actionable rather than a report that something was wrong.  

Addresses the rejection on the create path, naming the field that is missing.

### Task 2 — Guard the update handler against the resolved row

**Status**: complete — Resolved against the stored row, and only consulted when the call names `moscow` or `exclusion` — an edit touching neither is none of this guard's business, even on a row already in the state, which is the narrow half of NFR1's promise.

**Three ways in, not one, and the third is the one a create-side guard misses entirely.** A create can leave the state; an update can walk a legal row into it by naming only the priority; and an update can clear the exclusion off a row already ruled out, because an explicit `null` is a value meaning *clear this* and it arrives at the same place. All three are refused and each has its own arm in the tests. The mutation restricting the guard to the create path is caught only by the update arm — which is retro 02's lesson arriving exactly where it said it would.

The same resolution is what makes the third criterion work rather than needing code of its own: an update naming only the priority is judged on the exclusion already stored, so a row that records its reason is never asked to repeat it.  

Addresses the third criterion. The judgement is on the state the edit would leave, not on the arguments the call carries, so a row already recording its reason is not refused for failing to repeat it.

### Task 3 — Give the existing fixtures their exclusion

**Status**: complete — **No fixture needed fixing.** The task anticipated that any fixture holding a ruled-out requirement with no exclusion would become invalid; none does — the guard landed with the suite at 1015 passing and it stayed there. The prediction was reasonable and simply did not hold, which is worth recording rather than passing over: unlike story 1's forty, this rule was one the corpus already kept.

What the task also asked for does still matter and is done: a test pinning that a stored row in that state goes on reading as excluded. It writes the row through the fixture seam, past the tool that can no longer produce it — which is the state a restore or a pre-FR6 dump brings in — and asserts the row reads unchanged through `read_requirement` with its body, through the listing a report actually uses, and that an edit touching neither column still succeeds. That is NFR1's promise, and it is the assertion that proves this change does not reopen settled exclusions.  

Any fixture holding a ruled-out requirement with no exclusion becomes invalid when the refusal exists. It was always incomplete; add a test pinning that a stored row in that state still reads as excluded, so the change is proved not to reopen settled exclusions.

### Task 4 — Write tests for Refuse a ruled-out requirement with no exclusion

**Status**: complete — Five tests, with the rejection split across the two write paths rather than written once for the criterion — retro 02's rule, applied where this epic's breakdown had already predicted it would be needed. The create arm asserts no row was inserted; the update arm drives both of its routes, the priority moved onto a legal row and the exclusion cleared off a ruled-out one.

The control carries the rejection's own call differing in one field, and then exercises the other three priorities plus no priority at all — because a guard reading "an exclusion is required" rather than "required at this priority" would refuse all of those, and no assertion about the refusal alone would notice.

Four mutations, each asserted to have applied, all killed: restricting the guard to the create path is caught **only** by the update arm; judging the arguments rather than the resolved row fails the update arm and the stored-exclusion test; widening the obligation off `wont` fails the control; removing the create guard fails the create arm alone.  

Covers the rejection, its control including the other three priorities, and the update judged against the stored row.

### Retro

- The retro lesson this story was chosen to exercise paid out exactly where it said it would, and then once more where it did not. Retro 02's rule is that a must-NOT control needs one arm per code path that could reach the rejected state, not one per criterion — and the epic's breakdown had already split create and update into separate tasks, so the arms were planned. The mutation restricting the guard to the create path is caught by the update arm and by nothing else, which is the rule demonstrating itself. What the plan did not name is a third route on the same path: an update clearing the exclusion off a row already ruled out, which reaches the forbidden state as surely as an omission at create because an explicit null is a value meaning *clear this*. That one came from asking the retro's own question — where could this be written from — rather than from the criteria, which describe two paths and not three. The transferable form is narrower than "count the paths": count the ways the *state* is reachable, which is not the same number. A column can be left empty at create, moved into emptiness by an edit, and emptied directly, and only the first two look like paths from the outside.

## Story 5 — Three guards on unrelated writes

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A tradeoff naming an option the decision does not hold is accepted. `[integration]`
- The refusal lists the options the decision actually holds, so the caller is handed the real set rather than told the one it named is wrong. `[integration]`
- must NOT — A second live acceptance criterion with the same text under one story is accepted. `[integration]`
- must NOT — A binding attaching a coverage row to a story in a different epic is accepted. `[integration]`
- control — Each of the three guards admits its legitimate neighbour: a tradeoff on an option the decision holds, a criterion whose text differs from its siblings, and a binding to a story within the same epic. `[integration]`

### Task 1 — Guard a tradeoff against an option the decision does not hold

**Status**: complete — **FR12 was ambiguous as written and was resolved at a gate.** The refusal must "list the options the decision actually holds", but a tradeoff row names only an option and an axis — so an invented option id identifies no decision to ask. Chris chose to take the criterion at its word: the call now names the decision, `adr_id`, checked and never stored.

That reading catches strictly more. A wholly invented id was already refused by the foreign key, badly; an id belonging to a *different* ADR is accepted today and quietly assesses somebody else's option, which no constraint can reach and which the test drives directly.

`adr_id` is not a column — the option already names its ADR, and a copy on the tradeoff would be one fact in two places. So `entityTools` gained an `extra` seam: arguments a create accepts, validates and does not store, reaching the guard as its third argument so the documented contract that a guard sees the resolved row is undisturbed. Create only, since an argument deciding whether a write is legal has nothing to say about an edit that cannot change it.

**The boundary break cost nine call sites**, eight fixtures and one production caller — `src/preview/example.js`, which builds the example ADR every template preview renders.  

Addresses the first two criteria. The refusal lists the decision's real options, which is where an invented option id is caught.

### Task 2 — Guard a duplicate live criterion under one story

**Status**: complete — Composed with the warrant rule already on `story_criterion` rather than given a seam of its own — `criterionTools` offers one guard, and two rules on one table is what a guard is for. The refusal names the twin's position, which is what the caller goes and looks at.

**Live only, and the exclusion is asked of the schema rather than assumed.** A superseded criterion keeps its text, so restating one an amendment overtook is the ordinary way of correcting a criterion; counting those would make that impossible. But `superseded_at` arrived in a later migration than the table, and naming it unconditionally turned this guard into a hard error on a database opened at an earlier version — which a fixture in this suite does build. It now asks `pragma_table_info` whether the column is there. That is library 02's rule, that a new call is guarded by the schema's own answer and not by a version written into the fixture, and it cost a red run before it was applied.

**Exact text, where the coverage report's duplicate *warning* normalises whitespace.** The asymmetry is deliberate: a refusal stops a caller, so it takes the narrow reading and catches only what is unarguably the same sentence; the warning advises, so it takes the wide one. A refusal on the wide reading would block two criteria differing only in how they were wrapped.  

Addresses the third criterion, naming the twin's position. Live criteria only — a superseded one with the same text is not a duplicate.

### Task 3 — Guard a binding across epics

**Status**: complete — `coverage_story` records that a story *also* delivers a binding — "Covered by: Story 2, Story 4" — and both stories are meant to be doing one epic's work. The guard compares the epic of the story being attached against the epic of the story whose criterion the binding quotes, and refuses where they differ, naming **both** epics by slug: the caller cannot see from two ids which of the two they got wrong, and either might be. Through `entityTools`' existing guard seam, so nothing new was needed at the factory.

Either end missing is left to the foreign key, since refusing here would name the wrong fault for a row that has a different problem.  

Addresses the fourth criterion, naming both epics in the refusal.

### Task 4 — Write tests for Three guards on unrelated writes

**Status**: complete — Six tests: each rejection on its own rows with its own test, and each paired with the legitimate neighbour it must admit. The pairing is what stops a guard being too wide — two stories owing the same obligation, a criterion restating a superseded twin, a sibling story delivering the same binding — and none of those would be noticed by an assertion about the refusal alone.

Every rejection also asserts the row count afterwards rather than only the throw.

Four mutations, each asserted to have applied, all killed, and the separation held: disabling each of the three guards fails exactly one test. The fourth mutation drops the superseded exclusion from the duplicate rule, and it is caught **only** by the control — which is the clearest case in this epic of a control earning its place, since every rejection stays green under it.  

Covers the three rejections and the control that each admits its legitimate neighbour. Each rejection is driven on its own rows, so no one of the three can pass because another failed first.

### Retro

- A criterion can be unsatisfiable as written without being wrong, and FR12 was: it asks the refusal to list the options the decision holds, while the row being written names only an option and an axis — so the invented id it exists to catch identifies no decision to ask. The epic's own shaping note says every rejection here was transcribed from the spec rather than invented by the breakdown, precisely so a story would not be left unclosable; this one still needed a human to choose between three readings, and the one chosen turned a wording problem into a better guard. Taking the criterion at its word meant adding the decision to the call, which then catches the case no constraint can reach — a tradeoff assessing an option that exists, under a different ADR, accepted silently today. The generalisable part is where the ambiguity showed up: not while reading the criterion, which reads fine, but while trying to write the refusal's *message*. The message is what forced the question of what the guard could know. A rule stated as "refuse X" hides this; a rule stated as "refuse X and say Y" cannot, because Y has to come from somewhere. Worth writing criteria that way for that reason alone.

## Story 6 — Verify cross-story integration for Write-path refusals

**Status**: complete  
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5  

### Acceptance Criteria

- For each refusal this epic adds, a row written into the now-refused state before the change reads identically through every tool after it — same columns, same values, same standing in any report that mentions it. `[integration]`
- Each refusal is shown able to fail: the state it forbids is driven, and the test guarding it goes red on its own rather than behind a sibling assertion. `[integration]`

### Task 1 — Write the cross-story integration tests for Write-path refusals

**Status**: complete — Two tests over one database holding an instance of every state the epic now refuses, each written past the tools through the fixture seam — which is how a restore brings them in and, after this epic, the only way they arise at all.

The NFR1 test reads them back through the tools rather than from the table, because the promise is about how a row *reads* and a guard leaking onto a read path would leave the table right. It also checks the coverage report's standing for the same rows, which reaches them by a different route, and that integrity entry 9 still names the unquoted binding — the write path refusing a state does not excuse the register from reporting one that arrived anyway.

The second test drives all seven refusals in one place and requires each to name its own subject, since a set of guards refusing with one message would pass a count and tell a caller nothing. The closing-note rule is driven last and separately, because a story refused for its outstanding tasks never reaches it. Its control closes the same story once it says why, so none of the seven is a guard that simply refuses everything.

**What this test cannot show is stated rather than implied**: that each refusal goes red *alone* was established by running the mutations story by story, one rule at a time, and is recorded there. A test cannot edit the source it runs against.  

Covers both criteria: every stored row in a now-refused state reading unchanged, and every refusal proved able to fail. The read-back comparisons ask for withheld columns explicitly — a comparison written without that compares undefined against undefined and passes on the exact defect it was written to catch, which has cost this project two red runs.

### Retro

- The closing story's second criterion asks for something a test cannot do, and the useful move was to say so rather than to find a form of words that looked like compliance. "Each refusal is shown able to fail: the test guarding it goes red on its own rather than behind a sibling assertion" is a property of the suite under mutation, and a test cannot edit the source it runs against. What the test can do is narrower and still worth having — drive all seven forbidden states in one place and require each refusal to name its own subject, which shows every rule is live and distinguishable. The rest was established by running the mutations story by story and recorded in those tasks. Worth keeping because the temptation was real: a test asserting "seven refusals fired" would have read as satisfying the criterion while proving only that something threw seven times, which is precisely the vacuous shape this epic's retro gate was about. The general form: when a criterion is about the *suite* rather than the system, the honest artefact is a record of what was run, and the test that stands beside it should claim only what it checks.

## Dependencies

- blocks → 05-04
- blocks → 05-07

## Retro Applied

- 01 · A control mutation must reach the path it aims at, and its failure text must name the harm · applied — Seven refusals means seven mutations, and each is checked for landing in the guard it targets before its red is believed. Reading which tests went red is not the check; the failure text is, because a mutation that fails to compile into the path produces a true verdict about the wrong harm — the retro's own case was a ReferenceError from an unimported symbol, which turned three tests red and proved nothing about the criterion.
- 10 · A control pinning an exact figure is a change detector, and makes its rejection fail for others' reasons · applied — Written today, from this same defect found in epic 05-01's own tests. Controls here assert the shape that matters — the row exists, the refusal names the field, the neighbour is admitted — rather than exact counts or whole message strings, so a mutation somewhere else cannot turn a rejection red for a reason that has nothing to do with it. The test is whether each of the seven mutations fails only the test that owns it.
- 02 · A must-NOT control needs one arm per code path that could reach the rejected behaviour · applied — Story 4's refusal is reachable from two write paths and the epic already splits them into separate tasks, so it gets a control arm on each rather than one for the criterion. Every other guard is asked the same question before its control is written — where could the forbidden state be written from, and does this reach each of those places — rather than the weaker one of whether a single control would have caught the case the author had in mind. The retro's own hole passed a control because the mutated line sat after a throw the control's fixture always took.
- 08 · A rejection sharing a test with its positive is verified only if the mutation fails its assertion first · applied — The epic's tasks already say each rejection is driven on its own rows, so this is carried out for its reason rather than by its letter — story 5's three rejections get three tests rather than one test with three assertions, and each reads its refused row before its control. Assertion order inside a shared test is load-bearing evidence, and nothing in this epic is allowed to depend on it.
