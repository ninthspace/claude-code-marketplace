# Refusals that name a way out

**Number**: 05-04  
**Source spec**: 05  
**Status**: complete  

## Why this epic is shaped this way

Four improvements to what a refusal says, and one audit over every refusal the whole spec adds. The audit is why this epic waits on three others: a sweep asserting that every refusal names a route cannot run until the refusals exist.

The scope-id story is the one that needs designing first, and it is larger than it looks. Refusing an id that matches no row means probing it, and probing it means knowing which table the scope points at — a fact the list registry does not currently hold. Deriving it from the schema's foreign keys was considered and rejected: a foreign key names a table and the registry names a list, and the mapping back is not one-to-one, so a derived answer could say which table the id belongs to but not which list would accept it. Naming the list is most of the value, because the incident behind this was a run that read an empty page as a failed write and re-wrote ten tags.

The cost of declaring it rather than deriving it is a second place to keep in step, and the story carries a task that pins the registry against the schema so the two cannot drift silently.

The unaccepted-argument story has evidence from this project's own planning run: the spec above had its first eight writes refused for a missing field, and was told only that the parameters were invalid.

## What was built beyond the criteria, and the one requirement left unclaimed

**Two of the epic's own decisions did not survive being measured, and both changed in the same direction.** Story 2's shaping note rejected deriving a scope's parent table from the schema, accepting "a second place to keep in step" as the cost. Thirty-nine of the forty-two scope arguments turned out to be plain foreign keys, so a declaration would have restated the schema and the test pinning it would have compared a copy with the original. Derivation replaced it, and criterion 4 was restated over the property it was protecting — every scope resolves or is one of three named non-references. The epic's *other* claim, that a table does not name a list, held exactly: `document` is the parent of twenty-one scopes, and that map is built from the registry.

Story 1 was likewise bigger than its criterion. The criterion asks for the column and the table; what landed is that a run writing a severity id into a category slot is now told which slot and which vocabulary, on a call carrying four references. That came out of a defect — the first draft skipped half-defaulted references — so the bug and the feature were the same reading.

**NFR4 is delivered for every refusal that exists and is left unclaimed, because its subject is the whole spec.** Story 5's sweep drives fifteen refusals across epics 05-02, 05-04 and 05-05 and asserts each names something the caller did not supply. Epic 05-07 still carries a refusal of its own — a connection that will not open naming the capability it lacks — so the set the requirement quantifies over is not yet closed. The sweep is written to take it: the corpus is a list, and a refusal added later is one entry.

**The refusal found a live instance of its own requirement.** `tests/skill-inspect.test.js` passed a requirement id where an acceptance-criterion id belongs, so the gap query comparing what the spec asked for against what a story delivered had been reading an empty list since it was written. `skills/inspect/SKILL.md` named the two tools and never said how a run gets from one id to the other; it does now.

## Story 1 — Name the column and table in a foreign-key failure

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A write that misses a parent row returns a message naming the column whose value missed and the table that column points at, for a call carrying several ids. `[integration]`
- control — A write whose parent rows all exist succeeds unchanged, so the added handling is shown not to intercept a healthy call. `[integration]`

### Task 1 — Derive the column and its parent table from the constraint failure

**Status**: complete — `src/tools/foreign-keys.js` — `missingParent(db, table, values)` reads `PRAGMA foreign_key_list` and probes each reference the write actually made, returning the first whose parent row is not there. Called from `attempt` in crud.js only once a foreign-key failure has already fired, so the common path pays nothing and the probe is never a second enforcement point that has to agree with the database about what a reference is. `attempt`'s `wrote` now carries the connection, since both this and the retirement naming are reads against the database the statement just failed on.

Two things the first draft got wrong, both now tests rather than comments. It blamed a composite reference's leading column — and the first case it met was a review under a retro, where the leading column is the review's own `kind` and what the caller got wrong was the parent; which half is the mistake is not knowable from the failure, so both are named. And it read only the columns a call supplied, which made `finding(category_id, category_domain)` look unsupplied because the domain comes from the schema — so the probe skipped exactly the vocabulary mix-up this story is for. Defaults are now read from `PRAGMA table_info` and unwrapped.

Eleven existing assertions moved off `/FOREIGN KEY/` across eight files. Each now reads the refusal for the column and value the criterion names, which is the same restatement epic 05-05 made one layer up.  

Addresses the first criterion. The handler already catches the failure and passes the bare message through; the scope here is deriving which of a call's ids missed.

### Task 2 — Write tests for Name the column and table in a foreign-key failure

**Status**: complete — tests/foreign-key-naming.test.js — five tests. Criterion 1 drives a `create_coverage` carrying four ids with one wrong, and asserts both that the refusal names the bad column and its table **and** that it does not name the ids that were right: a refusal listing every reference on the call is the bare message with extra words. The two first-draft defects have tests of their own — the composite named whole, and the half-defaulted reference probed.

The control drives the insert path and the update path, since a probe wired to the insert alone would pass every assertion above and leave every update on the bare message. It also checks that a reference the call never made is not a reference that missed.

Three mutations, each asserted to have applied. A null reference probed as though it had been made → the unit test fails alone. The composite reporting only its leading column → six tests across four files, which is the first-draft bug caught in every place it showed. `settled` reduced to reading the supplied value → four tests, including the half-defaulted case and three real vocabulary mix-ups in the skill suites.  

Covers the message on a call carrying several ids, and the control that a healthy write is untouched.

### Retro

- Two defects in one short function, and both were found by running the change against the corpus rather than by reading it. The probe blamed a composite reference's leading column, which is defensible in the abstract and wrong on the very first case it met: a review under a retro fails `document(kind, parent_kind)`, whose leading column is the review's own kind — so the refusal said the kind was unknown when what the caller got wrong was the parent. And it read only the columns a call supplied, which made `finding(category_id, category_domain)` look unsupplied, because the domain comes from the schema — so the probe silently skipped exactly the vocabulary mix-up the story was written for, and that case fell through to SQLite's own words. Neither is visible from the function; both are obvious the moment eight real suites run against it.

The eleven assertions that had to move are the more interesting cost, and they are the same shape epic 05-05 found one layer up. Every one read `/FOREIGN KEY/` — pinned to the message the database happens to produce rather than to the thing being claimed, which is that a bad call reaches the caller as a refusal naming what was wrong. Improving the message broke them all, and every one was restated in a line. That is a cheap failure and a correct one: the tests were asserting about SQLite, and they now assert about dpm.

The improvement is bigger than the criterion states, and worth recording before a later run reads it as scope creep. The criterion asks for the column and the table. What actually lands is that a run writing a severity id into a category slot is now told *which slot* and *which vocabulary*, on a call carrying four references — a message that identifies the mistake rather than its class. That came out of the half-defaulted case, which is to say out of the second defect. The bug and the feature were the same reading.

## Story 2 — Refuse a scope id that names no row

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A list given a scope id that matches no row returns an empty page. `[integration]`
- control — A list given a scope id naming a real row that holds nothing still returns an empty page, so a scope that is genuinely empty is shown to be distinguishable from one that does not exist. `[integration]`
- Where the id belongs to a different table, the refusal names that table and names the list that takes the id as a scope. `[integration]`
- Every scope in the list registry declares the table it points at, and a declaration that disagrees with the schema is caught by a test rather than by a caller. `[integration]`

### Task 1 — Declare each scope's parent table in the list registry

**Status**: withdrawn — Dropped on Chris's decision at the plan gate, and the reasoning is the measurement that prompted it. The epic rejected deriving a scope's parent table and accepted "a second place to keep in step" as the cost — but thirty-nine of the forty-two scope arguments are plain foreign keys whose parent the schema already names. Declaring them would restate the schema thirty-nine times, and task 4's pin would compare a hand-written copy against the original, which is the hazard `tests/support/conformance.js` exists to warn about.

`scopeParents` in src/tools/scope.js derives it from `PRAGMA foreign_key_list` instead — the same reading `childLists` already uses to derive `within`. The epic's argument still holds for the *other* direction, which is genuinely not derivable from the schema: a table does not name a list, and `document` is the parent of twenty-one of the forty-two scopes. That map is built from the registry by `listsByParent`.  

The declaration only. Every scoped list gains the table its scope points at, which is what lets the refusal name both the table and the list that takes the id.

### Task 2 — Probe the scope id and refuse when it matches nothing

**Status**: complete — `refuseUnknownScope` runs in every list handler **before** `selectPage`. A refusal derived from an empty result would fire on the scope that is genuinely empty, which is the one state a list must go on returning a page for — the distinction the story exists to draw, destroyed by the check meant to draw it.

**The composite half is what makes it discriminate, and the first cut missed it.** `story.epic_id` is one column of `(epic_id, epic_kind) → document(id, kind)`, so probing the id alone finds a *spec* — a document — and waves through exactly the mistake FR8 is about. The pinned half is read from the table's own default, reusing `settled` and `referencesOf` from story 1's `foreign-keys.js` rather than a second copy. Where the companion has no default (ten scopes, `document.parent_kind` among them, whose kind the tool derives per call) the id is probed alone: less discriminating, still correct.

Found a real defect on its first run, which is the requirement's own case: `tests/skill-inspect.test.js` passed a **requirement** id as `list_criterion_approach({criterion_id})`, so `asked` was a list that could never hold anything. Fixed, and `skills/inspect/SKILL.md` amended — it said `list_criterion_approach` "says what the spec asked for" without saying how a run reaches the criterion ids from a requirement, which is what let the wrong id in. New site registered in `tests/support/body-reads.js`.  

Addresses the rejection and its control. A scope naming a real but empty parent must go on returning an empty page, which is the distinction the whole story exists to draw.

### Task 3 — Name the other table and the list that takes the id

**Status**: complete — The refusal names what the row actually is — a document by its kind rather than by the word "document" — and the lists that would take it, **narrowed by that kind**. `list_task({story_id: <an epic id>})` now says it is an epic and that `list_story (epic_id)`, `list_retro (parent_id)`, `list_review (parent_id)` and `list_coverage_matrix (parent_id)` take one.

The narrowing is the difference between an answer and a dump: twenty-one scopes point at `document`, and offering all of them — including `list_requirement (spec_id)`, which refuses an epic for the same reason the original call did — would be the bare empty page with extra words. A scope pinned to a kind is offered only for that kind; a `parent_id` scope is offered only where `document_kind_parent` admits the pair, read from the same table `documentLists` uses to decide which kinds have a parent scope at all.

Where the id is found nowhere the refusal says so plainly and tells the caller to check the id rather than read the empty page as a scope with nothing in it. Story 3's unique-prefix offer is what improves that case.  

Addresses the third criterion. This is the sentence the incident needed: a run read an empty page as a failed write and re-wrote ten tags.

### Task 4 — Pin the registry declarations against the schema

**Status**: complete — Restated, because task 1 was withdrawn and there is no declaration left to pin. The criterion's purpose survives: a scope that is silently never probed is the failure it was protecting against, and that is now asserted directly — **every scope argument of every list tool resolves to a parent table, or is one of three named non-references**, and the named set is asserted to be exactly `list_session.skill`, `list_session.updated_before` and `list_taxonomy.domain`.

A scope added with a typo, or one whose foreign key a migration drops, appears in that list and fails the test. Proved by mutation: one scope made unprobeable fails this sweep along with two behavioural tests.

Its own control sits beside it — `scopeParents` asked about an argument that is not a column answers with nothing rather than inventing a parent, so a sweep whose lookup matched everything would fail rather than report a clean registry.  

Addresses the fourth criterion. Nothing derives the declaration from the schema, which is the cost the decision accepted; this test is what stops the two drifting silently.

### Task 5 — Write tests for Refuse a scope id that names no row

**Status**: complete — tests/scope-refusal.test.js — five tests. The rejection and its control run on the same fixture one test apart, because the control is the story: a real parent holding nothing must go on returning a page.

Five mutations, and two of them are worth recording as null results rather than evidence. Probing only when the page comes back empty: the whole suite stayed green, because for correctness that is identical — the plan predicted a failure and was wrong, and the honest reading is that it is a performance choice, not a behavioural one. Refusing every scoped call: 105 tests failed, which says the probe is load-bearing and discriminates nothing.

The three that were evidence. Reading an empty page as a missing scope — **the control fails**, which is exactly what it is for. Dropping the kind narrowing so all twenty-one document scopes are offered — the naming test fails alone. Making one scope silently unprobeable — three fail, including the criterion-4 sweep, which is the whole reason that sweep replaced the withdrawn declaration.  

Covers the rejection, its control, the refusal's contents and the registry-against-schema check.

### Retro

- The refusal found a real instance of its own requirement on its first run, in this project's own suite. `tests/skill-inspect.test.js` passed a requirement id as `list_criterion_approach({criterion_id})` — so the `asked` list was empty whatever the project held, and the gap query that compares what the spec asked for against what the story delivered had been reading nothing since it was written. It passed every test, because an empty list is a legal answer. That is FR8's argument stated as an incident rather than as a sentence, and the sentence was in the epic all along.

Tracing it back gave the skill a correction it needed independently: `inspect`'s prose said `list_criterion_approach` "says what the spec asked for" and never said how a run gets from a requirement to its acceptance criteria. The two tools take different ids, and the file left the join to be guessed. A test written from that prose guessed wrong, which is about as direct a demonstration as a skill file can get that an instruction which cannot be followed mechanically will be followed some other way.

Two mutations were null results and both are worth keeping as such. Probing the scope only when the page comes back empty left the entire suite green — the plan predicted a failure and was wrong, because for correctness the two are the same and only the cost differs. Refusing every scoped call failed 105 tests, which establishes that the probe is load-bearing and distinguishes nothing. The three that were evidence each failed something specific, and the sharpest was reading an empty page as a missing scope: **the control failed**, alone among the behavioural tests, which is precisely the job a control exists for and the reason this story's rejection and control share a fixture.

The design also moved on a measurement rather than on an argument. The epic had rejected deriving a scope's parent table and accepted a declaration's upkeep as the cost; thirty-nine of the forty-two scopes turned out to be plain foreign keys, so the declaration would have restated the schema and its pin would have compared a copy with the original. What survived the measurement was the epic's *other* claim — that a table does not name a list — and that half is genuinely underivable, so it is built from the registry. A rejected alternative can be right about one direction and wrong about the other, and re-measuring is what separates them.

## Story 3 — Offer a unique-prefix match

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Where an id matches no row but is an unambiguous prefix of exactly one, the refusal offers that row. `[integration]`
- must NOT — An id that is a prefix of two or more rows has one of them offered. `[integration]`
- control — A full id that matches a row is resolved exactly as it is today, with no prefix search behind it. `[integration]`

### Task 1 — Add unique-prefix resolution to the refusal path

**Status**: complete — `src/tools/prefix.js` — `uniquePrefix` runs a single `LIKE ? ESCAPE '\'` against the front of the key column with `LIMIT 2`, and `didYouMean` wraps it as a suffix rather than a message, because the refusals it joins already say what was wrong and are not the same sentence.

`LIMIT 2` is the must-NOT in one statement: the second row is fetched not for its value but for the fact that it is there, so "exactly one" is the answer rather than "the first of several".

**Three refusal sites, and the third was the one easiest to miss.** `readByKey` and `readById` carry the offer, and so does `updateByKey`'s zero-changes branch — an update naming a truncated id changes nothing and reports it in the same words as a row that is not there. Plus the scope refusal story 2 explicitly left this for: an id that is nowhere at all now offers the row it nearly named.

On a composite key the offer is made over the **first** column alone. The second is a pin the caller did not choose, and a prefix search over it would suggest a row by way of a value nobody typed.  

Addresses all three criteria. The search runs only after an exact match has failed, so a full id never pays for it, and an ambiguous prefix offers nothing rather than guessing.

### Task 2 — Write tests for Offer a unique-prefix match

**Status**: complete — tests/prefix-offer.test.js — four tests. The ambiguity is built rather than hoped for: two ids written past the tools through the fixture seam so they genuinely share a front. ULIDs share a time-ordered prefix, but not reliably enough to depend on, and a fixture whose collision is a coincidence stops testing the day the clock moves.

**Two assertions were strengthened after a mutation showed they could not fail**, which is the whole value of running them rather than reasoning. Removing the escaping survived the suite: a bare `%` matches all three stories, so ambiguity answers `null` whether the value is escaped or not. Restated over a real prefix carrying a `%` — escaped it names nothing, unescaped it finds the row and offers an id nobody holds. Removing the empty-value guard survived for the same reason, so it is now asserted against a table holding exactly one row, where the guard is the only thing between an empty string and a row being offered for it.

Three mutations in total: `LIMIT 1` so the first of several is offered (the must-NOT and the control's helper assertions fail), no escaping, and no empty guard. The last two fail only since the restatements.  

Covers the suggestion, the rejection of an ambiguous prefix and the control that a full id resolves as before.

### Retro

- Two of this story's assertions were written, passed, and could not have failed — and only running the mutations showed it. Both had the same cause: the fixture held three rows, so any prefix matching "everything" came back ambiguous and answered null whether the code under test was right or not. The escaping assertion used a bare `%`, which matches all three; the empty-value assertion used an empty string, which matches all three. Removing the escaping and removing the guard each left the whole suite green. Restated — a real prefix with a `%` on the end, and a table holding exactly one row — both mutations now fail. The general shape is the one 05-01's retro named from the other side: an assertion is vacuous whenever the corpus cannot distinguish the right answer from the wrong one, and a corpus of three is as capable of hiding that as a corpus of one.

The third refusal site is the finding about the code. `readById` and `readByKey` are the obvious homes for "did you mean", and `updateByKey`'s zero-changes branch is not — but it produces the same sentence for the same reason, because an update naming a truncated id changes nothing and reports it exactly as a missing row. Finding it took writing the test for the read path and then asking which other code says those words. A grep for the message, not for the function.

The ambiguity itself had to be constructed rather than found, which is worth keeping as a rule. ULIDs share a time-ordered front, so two minted in the same millisecond nearly collide — nearly, and not dependably. A must-NOT resting on that would pass today and stop testing on a slower machine or a faster clock. Two ids written past the tools through the fixture seam make the collision a fact of the test rather than a property of the runtime.

## Story 4 — Name the arguments a tool accepts

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A refusal for an argument a tool does not accept names the arguments it does accept. `[integration]`
- A refusal for a missing required argument names which argument is missing. `[integration]`
- control — A call carrying only valid arguments succeeds unchanged. `[integration]`

### Task 1 — Name the accepted arguments in the schema rejection

**Status**: complete — `accepts(schema)` in src/tools/convention.js, appended to `validate`'s unknown-argument refusal: `unknown argument 'labell' — it takes spec_id, label, class, text, position (required) and moscow, exclusion, parent_id (optional)`.

**Required and optional are separated because they answer different questions.** Mistyping one of four required arguments is a different mistake from reaching for a capability the tool does not have, and an alphabetical merge of the two serves neither. Declaration order rather than alphabetical, because `inputSchema` leads with the identifying arguments and the schema is what a caller was shown.

An empty clause is dropped rather than printed — `create_story_criterion_approach` requires both of its two, and "and (optional)" would read as a truncated message. A tool taking nothing at all says so, since `check_integrity` is that shape.

The message is built from the **augmented** schema `defineTool` publishes, so the convention's own `include_body`, `limit` and `offset` are named as optional on the tools that carry them — which is right: a caller was shown them, and a list built from the declared properties alone would have reported them as unknown.  

Addresses the first criterion. The rejection currently says only that a property is not allowed, which leaves the caller nothing to correct towards.

### Task 2 — Name the missing required argument

**Status**: complete — Already true and now asserted, which is the honest shape — `validate` has named the missing argument since it was written (`'label' is required`), and what the spec's evidence describes is the *unknown*-argument half being silent.

Eleven tests across seven files turn out to depend on the naming, which the mutation proved: removing the argument's name from the message fails all of them. So this was delivered and load-bearing, and the story's contribution is a test that says so directly rather than eleven that lean on it incidentally.

The assertion also covers the explicit-null case, which is refused with the omission and named the same way: below this point `null` means *clear this column*, and a required column is one there is no legal way to clear.  

Addresses the second criterion. This spec's own first eight writes were refused for a missing label and told only that the parameters were invalid.

### Task 3 — Write tests for Name the arguments a tool accepts

**Status**: complete — tests/argument-refusal.test.js — four tests. Every required and optional argument is named individually rather than counted, because a message listing three of four sends the caller back for the fourth; and the accepted clause is read on its own to check the unknown name is not offered back as something the tool takes.

The control carries the rejection's own call with the typo corrected, a call using every optional argument (a validator that had confused the two sets would refuse it), and a read carrying `limit` and `include_body` — the convention's injected arguments, which a message built from the declared properties alone would have called unknown.

Three mutations: required and optional merged (the naming test fails alone); the empty clause printed anyway (the all-required test fails alone); the missing argument no longer named (eleven tests across seven files, which is how much of the suite was already leaning on criterion 2 without stating it).  

Covers both messages and the control that a valid call is unchanged.

## Story 5 — Verify cross-story integration for Refusals that name a way out

**Status**: complete  
**Blocked by**: Story 1, Story 2, Story 3, Story 4  

### Acceptance Criteria

- Every refusal this spec adds names a requirement, a table, a list, an option or an argument that the caller can act on, and not only the fault that was found. `[unit]`
- control — A refusal message reduced to naming only the fault makes that sweep fail, so the sweep is shown to be reading the messages rather than passing over them. `[unit]`

### Task 1 — Write the sweep over every refusal message this spec adds

**Status**: complete — tests/refusal-routes.test.js — fifteen refusals driven on one database, spanning epic 05-02's seven guards, this epic's four messages and epic 05-05's two recovery verbs.

**"Names a way out" is made mechanical by what the criterion itself lists** — a requirement, a table, a list, an option or an argument, all of which are names the project holds. The sweep builds that vocabulary from the live schema (tables, columns, and the values every `CHECK` enum admits) and the built registry (tool names), then asks whether a refusal still names one of them **with the caller's own supplied values removed**.

That subtraction is what makes it discriminate, and a looser reading would have dropped it: `unknown argument 'labell'` carries a quoted token and looks specific, and with `labell` taken out there is nothing left. The control drives that directly — a message echoing an argument the caller named is not a route out, and one naming a column they did not supply is.

Problems are collected and reported together rather than asserted one at a time, so a change breaking two messages shows both.

**The criterion's control was run live as well as synthesised.** `refuseUnfoundFragment` was reduced to "the fragment was not found"; the sweep failed and nothing else in the suite did. The synthesised control stays because it reaches the predicate's edges — an echoed argument, a tool name that does not exist — which no single live mutation shows.  

Covers both criteria. The sweep is then broken deliberately — one message reduced to naming only the fault — and confirmed to fail, because a contract test that cannot fail is the most confident kind of nothing.

### Retro

- The cross-story story turned a prose criterion into a computation, and the useful part is where the definition came from. "Names a way out" reads as a judgement, and the criterion itself had already enumerated what counts — a requirement, a table, a list, an option or an argument — all of which are names the *project* holds. So the sweep builds that vocabulary from the live schema and the built registry and asks whether a refusal still names one, and the criterion turned out to be mechanical because somebody had written it precisely rather than evocatively.

The half that makes it discriminate is subtraction, and it is the half a looser reading drops. `unknown argument 'labell'` carries a quoted token and reads as specific; with the caller's own supplied values removed there is nothing left of it. Every refusal in this spec is judged on what survives the caller's own words, which is the only reading under which "it echoed your bad value back" counts as silence — and echoing the bad value back is exactly what the pre-spec messages did.

Running the control live as well as in the suite was worth the extra step. A synthesised message fed through the predicate proves the predicate; reducing a real refusal in `src/` to "the fragment was not found" proves the sweep is reading the messages the project actually produces. The two answer different questions, and only the second would have caught a sweep that drove the wrong calls. The synthesised one stays because it reaches edges no single live mutation shows — an echoed argument, a tool name that does not exist.

Fifteen refusals across three epics in one fixture, which is the other thing worth keeping: the set only exists because 05-02 and 05-05 were finished first, and the epic's own note said so as the reason this story waited on three others. That ordering was right, and the evidence is that the sweep had thirteen-plus real messages to read rather than the four this epic added.

## Dependencies

- blocks → 05-07

## Retro Applied

- 10 · A control pinning an exact figure is a change detector wearing a control's clothes · applied — The governing lesson for this epic, because every story here changes a *message*, and a message is the most tempting thing in the codebase to pin whole. Epic 05-05 has just paid for the same mistake one layer up — an enumeration of the registry's deleters standing in for the category "nothing deletes a coverage row". So each assertion here reads a refusal for the thing the criterion names — the column, the table, the list, the arguments — and never for its sentence. Story 5's sweep is the one at risk of being written as an exact-message check, and it is stated over what a message must *contain* instead.
- 10 · Reproduce the sweep's own baseline before asking it about the intended change · applied — Story 2 is the one this bears on. Its epic note says the list registry does not hold which table each scope points at, and that deriving it from the schema's foreign keys was considered and rejected — so before anything is declared, the registry and the foreign keys are read against each other to establish what the mapping actually looks like today. The story carries a task pinning the two together precisely because a declared fact is a second place to keep in step, and a pin written against a model of the registry rather than the registry is the failure 05-01 found.
- 10 · The cross-story story earned its place on a defect every earlier story was unable to see · applied — This epic has exactly that story — story 5, a sweep over every refusal the whole spec adds — and the observation is the reason it is worth writing rather than a formality. The specific hazard it names is the one story 5 is exposed to: an assertion is vacuous whenever the corpus holds one of the thing it quantifies over. So story 5's sweep is checked against the *real* refusal corpus, which by then spans 05-02's seven guards and this epic's four messages, and it carries a planted control — a refusal reduced to naming only the fault — so a sweep that had stopped reading fails rather than reporting clean.
