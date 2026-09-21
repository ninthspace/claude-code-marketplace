# Hardening the dpm Record

**Number**: 05  
**Status**: complete — Approved 2026-09-21. Twenty proposals from the Hardening dpm evidence, recorded as 27 functional, 5 non-functional and 6 environmental requirements with 32 criteria and 5 accepted decisions. B1 and K6 are deliberately out of scope and routed to /dpm:quick.  

## Problem recap

Five driven runs of the dpm skills against a deliberately weak model exposed a class of failure the tool surface permits and only skill prose discourages. A run can supply a verification timestamp it never read off a clock; bind a coverage fragment that appears nowhere in its requirement's text; close a story over a task still pending; read an empty page returned for a mistyped scope id as proof that a write never happened; and leave a won't-have carrying no recorded reason for being out.

Each of those is a legal write today. None produces an error, and several are undetectable afterwards — a fabricated `verified_at` is the stamp the coverage matrix publishes as proof, and nothing downstream can tell that row from a real one.

Separately, the same runs spent roughly nineteen minutes per closing summary hand-tallying coverage pages one at a time, because dpm has no coverage sweep. `check_integrity` is the only cross-cutting check there is, and the epics confirm step does not call it.

The thesis is one sentence: **judgement that currently lives in skill prose becomes a refusal the model cannot talk its way past, and the refusal says what to do instead.** The test for membership is whether the compensation can be stated as an invariant about the record without naming a model — which is also what excludes a model-profile overlay from this spec.

The evidence is third-party: a published page, *Hardening dpm*, at claude.ai/artifact/59GtgfJRowvbrEfY7hdoCP, written against dpm 0.7.7 from five runs over 16–18 September 2026. Every server-side claim in it was independently verified against `dpm/src/` before this spec was opened, and the verification is recorded section by section in 03.

Two proposals from that page are deliberately out of this spec's scope. B1, an inversion in the epic projection's `Blocked by` field, and K6, the skill rule on how a dependency edge is written, are routed to `/dpm:quick` as one self-contained change. They are named here only so that a reader of this spec does not go looking for them in it.

## Scope boundary

**In scope.** The eight must-have refusals and the coverage report; the seven should-have additions — the report's three warnings, the requirement label on a coverage row, three repair verbs, three write guards, and the integrity check at the breakdown skill's confirm step; and the six skill rules with the two refusal-quality improvements, on the explicit understanding that those eight are the first things cut if the iteration runs long.

Every refusal ships with a test that has been proved able to fail, by driving the state it forbids and watching that test go red on its own. That condition is in scope for all of them and is not negotiable per item, because it is the only thing separating this work from the prose it replaces.

**Explicitly out of scope.** The model-specific advice channel and the lint that would keep skill bodies free of model names: the seam only begins to pay once a second model drives these skills, and its own measurement puts the extraction at around three per cent of the conventions' length. Also out of scope, and routed to a separate small change, are the inversion in the epic projection's blocking field and the rule on how a dependency edge is written — they are one self-contained fix and do not need this spec's machinery.

And any schema migration. Where a requirement turns out to need one, it comes back as a decision rather than being absorbed into an implementation, because a migration serves this project's database read-only to the installed server until the plugin is reinstalled.

**Deferred.** A story's phase checked against its own tasks partway through, which only the exit makes unambiguous. A retrospective's trigger signals computed from the rows rather than reported by the run being reflected on — agreed to be the most valuable of the undesigned items, and undesigned. And session state enforced to accumulate across a run rather than being overwritten by its latest unit.

**Two dependencies force order without changing scope.** The report's warnings cannot start before the report exists, and the stamp change cannot land without its skill text in the same commit, because a suite assertion couples the two. Everything else is independently schedulable, which means a partial delivery of this spec is still a coherent one.

## Integration boundaries

Five seams follow from the decisions above, and each is where an integration test belongs rather than a unit one.

**The delivery factory and a per-table closing condition.** One factory serves both stories and tasks. The closing hook is optional and receives the resolved row, and a table that passes none behaves exactly as it does today. That last clause is the contract, and it is what makes a change to a shared factory safe — so it is asserted rather than assumed, with a test that closes a task over the changed code and finds nothing different.

**The coverage report's return shape.** The counts block exists so that a skill quotes it instead of recomputing it, which makes its shape a contract rather than an implementation detail. A renamed or dropped field breaks a consuming skill silently: a skill quoting a count that is no longer there renders an absence, and an absence reads as a section that was not needed. The report's fields are therefore pinned by a test, and a skill that quotes one names it in its own body.

**The list registry and the refusal message.** The declaration binding a scope to its parent table has two consumers — the probe that checks the id, and the message that names the list which would have taken it. Nothing derives that declaration from the schema, which is the cost the decision accepted. The failure it carries is a scope whose table is changed in the schema and not in the registry, and the test that catches it compares the two.

**Tool arguments and skill text.** A suite assertion requires every argument a run passes to be named in that skill's body inside a code span, and its word boundary means a renamed argument does not satisfy a body still carrying the old name. This is a live coupling between the server's tool surface and the skill corpus, and it is the reason the stamp change cannot be split across two commits. Any other requirement here that renames an argument inherits the same constraint.

**The shared conventions document as the only channel into a running skill.** A skill body is read verbatim and nothing appends to it, so the one document every body opens with is the only place a cross-cutting rule can arrive. Where a rule sits therefore decides what it reaches, which is what the placement decision turns on and what the six skill-rule requirements are all placements against. It also bounds them: a rule shaped as "restate this at steps 4, 7 and 9" cannot be carried this way at all, and has to be written once as a general disposition or left in the skill that needs it.

## Testing strategy

Every refusal this spec adds gets an integration test that drives the forbidden state through the same tool a run uses, paired with a control criterion whose test proves the check discriminates rather than rejecting every call of that shape. The control is a row of its own and not a clause inside the rejection's test, because a rejection sharing a test with its positive is only verified when a defect happens to fail the rejection's assertion first — assertion order inside a test is load-bearing evidence, and giving the rejection its own test with its own control row is the cheap way to stop depending on it.

**Each of those tests is checked by breaking the thing it guards and confirming it fails.** A contract test that cannot fail is the most confident kind of nothing, and three green results in this project's history were tests present, passing, and pointed somewhere else — none of them a missing test, and every one found by planting a defect and watching what stayed green.

Report arithmetic is covered at the unit level against a fixture with a known count, because the failure being guarded is a miscount rather than a mis-integration: a run reported twelve of twelve bindings for an epic whose rows numbered thirteen.

One entry is tagged for an environment nobody here has: that everything added works where the server is an installed plugin release rather than a working tree. It is not a weaker manual check — the check is mechanical and only the host is missing, and self-assessing it from this checkout would confirm it on the one machine where it cannot fail.

Three test failures are expected rather than discovered, and in each case the fixture is wrong rather than the rule. Fixtures holding a ruled-out requirement with no exclusion become invalid the moment that refusal exists, and should be given their exclusion, with a test pinning that a stored row in that state still reads as excluded. Fixtures that close a story over outstanding work are asserting the behaviour this spec exists to stop; softening the rule to keep them green gives back the whole change. And the argument rename fails the skill-text coupling before it fails anything else, which is a sequencing instruction rather than a defect.

## Functional Requirements

### FR1 (must)

The server supplies the clock for a coverage verification stamp and for a requirement's coverage claim. Neither tool accepts a time from its caller; each takes a boolean saying the thing happened, and the handler records when.

- A verification call that supplies no time records a stamp holding the server's clock at the moment of the call, and the binding hash is derived alongside it as it is today. `[integration]`
- must NOT — A call supplying a time for a verification or for a coverage claim is accepted and the supplied value is stored. `[integration]`
- control — The same call with the time omitted succeeds and stores a stamp, so the refusal is shown to discriminate rather than to reject every call of that shape. `[integration]`

### FR2 (must)

A coverage row whose fragment does not occur in the text of the requirement it names is refused when it is written, rather than reported later by the integrity register. Where a sibling requirement in the same spec does contain the fragment, the refusal names that requirement as the one the fragment belongs to.

- control — A coverage write whose fragment does occur in the text of the requirement it names succeeds and stores a row. `[integration]`
- must NOT — A coverage write whose fragment occurs nowhere in the text of the requirement it names is accepted, leaving a row for the integrity register to find later. `[integration]`
- Where a sibling requirement in the same spec does contain the fragment, the refusal names that requirement as the one the fragment belongs to. `[integration]`

### FR3 (must)

A story cannot be marked finished while any task beneath it is still outstanding. The refusal lists the outstanding tasks, so that it performs the reconciliation the run did not.

- must NOT — A story with a task still outstanding beneath it is set finished. `[integration]`
- The refusal lists every outstanding task beneath that story, so the caller is handed the reconciliation rather than told to go and find it. `[integration]`
- control — The same story with every task beneath it finished is set finished without objection. `[integration]`

### FR4 (must)

A story finishing while a coverage row bound to it remains unverified must carry a status note explaining why, and a note already on the row counts. What is refused is the silent close, never the unverified binding itself — a story can legitimately finish over work someone else verifies.

- must NOT — A story carrying an unverified bound coverage row and no status note is set finished. `[integration]`
- control — The same story with a status note is set finished, so the unverified binding is shown not to be what was refused. `[integration]`
- A status note already stored on the row satisfies the condition without being restated in the closing call, and a note of whitespace alone does not satisfy it. `[integration]`

### FR5 (must)

A coverage report answers, for a spec and optionally one epic, each requirement's standing, which criteria are accounted for by nothing, which carry no approach tag, which are must-haves, and a block of counts that a skill quotes rather than computes. Given an epic it adds a roll-up of that epic's stories, bindings and verified bindings.

- Given a spec, the report returns every requirement with its standing, the criteria accounted for by nothing, the criteria carrying no approach tag, the must-have criteria, and a counts block. `[integration]`
- Given a spec and an epic, the same report adds a roll-up of that epic's stories, its bindings and its verified bindings. `[integration]`
- On a fixture whose bindings number thirteen, the counts block says thirteen and agrees with the lists it summarises — the miscount that motivates this being a run reporting twelve of twelve over thirteen rows. `[unit]`

### FR6 (must)

A requirement ruled out of an iteration is refused unless it records what rules it out. The obligation falls on that priority alone; the other three carry no such duty. The refusal applies to writes only, so a stored row already in that state goes on reading as excluded everywhere it is read.

- must NOT — A create or an update that would leave a requirement ruled out with no exclusion recorded is accepted. `[integration]`
- control — The same call carrying an exclusion succeeds, and a requirement at any other priority with no exclusion succeeds too. `[integration]`
- An update naming only the priority is judged against the exclusion already stored on the row rather than against the absence of one in its own arguments, so a row that already records its reason is not refused for failing to repeat it. `[integration]`

### FR7 (must)

A write that misses a parent row names the column that missed and the table it points at, instead of returning the database's bare constraint message. A call carrying several ids currently gives no way to tell which one was wrong.

- A write that misses a parent row returns a message naming the column whose value missed and the table that column points at, for a call carrying several ids. `[integration]`

### FR8 (must)

A list refuses a scope id that matches no row, rather than returning an empty page that cannot be told apart from a scope which is genuinely empty. Where the id belongs to a different table, the refusal names that table and the list that takes it.

- must NOT — A list given a scope id that matches no row returns an empty page. `[integration]`
- control — A list given a scope id that names a real row holding nothing still returns an empty page, so a scope that is genuinely empty is shown to be distinguishable from one that does not exist. `[integration]`
- Where the id belongs to a different table, the refusal names that table and names the list that takes the id as a scope. `[integration]`

### FR9 (should)

The coverage report also warns where every binding on a requirement is verified but the claim was never made, where an in-scope requirement carries no acceptance criterion at all, and where one criterion text lives under two different stories. All three are warnings and never gaps, so no epic that closes today stops closing.

### FR10 (should)

A coverage row carries the label of the requirement it binds, so that a read-back can be checked against a label rather than against an id remembered from an earlier call.

### FR11 (should)

Three mistakes a run can make are undoable: an observation written twice, a dependency edge written the wrong way round, and a binding attached to the wrong story. With no withdrawal verb the only recovery is a second row, and two rows saying one thing is a miscount at the only place that reads them.

### FR12 (should)

A tradeoff naming an option that does not exist is refused, and the refusal lists the options the decision actually holds. This is where an invented option id gets caught, which is the same class of failure as a supplied timestamp: a plausible value in place of a read one.

### FR13 (should)

A second live acceptance criterion with the same text under one story is refused, and the refusal names the twin's position so the caller can find it.

### FR14 (should)

A binding that would attach a coverage row to a story in a different epic is refused, and the refusal names both epics.

### FR15 (should)

The breakdown skill's confirm step runs the integrity check and treats every violation not marked advisory as a gap, reporting it with the rows it names. The gap check reads what the rows say; integrity reads whether they hold, and the confirm step currently does only the first.

### FR16 (could)

A gate is written as two steps and performed as two steps: the draft is rendered as its own items in the same message that asks the question, never worked out in reasoning the user cannot see and never left in an earlier message that is no longer the one being answered. Nothing a gate decides is written before it is answered.

### FR17 (could)

A criterion recording a rejected outcome names that outcome as though it had happened, because the document supplies the negation around it. Written as a denial it reads as a double negative, and a clause that only restates the denial is dropped rather than inverted — inverting one reverses what the spec says.

### FR18 (could)

A binding quotes the clause the criterion actually tests, not the nearest verbatim one, and a requirement counts as covered only as far as its own criteria go. A criterion rejecting an outcome quotes the clause whose outcome it rejects.

### FR19 (could)

On a resume, and after a compaction, the rows say what was written and the session state does not. Before a resumed step writes anything it lists the rows that step writes, under the parent it writes them to, and proposes only what is missing — never a row a list has just returned. Each skill carries an ordered read for its own step, and a step whose rows exist for some parents and not others resumes at the first parent without them.

### FR20 (could)

A run of writes is read back before the next unit begins, and the read-backs are batched into one message rather than one message per row. Each row is checked by its label rather than by an id remembered from an earlier call, and every count in a closing tree comes from the last report rather than from a tally of the calls sent.

### FR21 (could)

Four smaller rules hold in the execution skill: one observation per story and further categories added to the existing row; an unmet criterion rendered in full with what the assessment found, before any gate asking whether to accept the shortfall; coverage pages never added up by hand; and scratch files left where the repository's ignore rules account for them and removed once the check is made.

### FR22 (could)

Where an id matches no row but is an unambiguous prefix of exactly one, the refusal offers that row rather than reporting only that nothing was found. A truncated id currently reads as a missing row.

### FR23 (could)

A refusal for an argument a tool does not accept names the arguments it does accept. The schema rejection currently says only that a property is not allowed, which leaves a caller nothing to correct towards — as this spec's own first write demonstrated, having been refused for a missing label without being told which field was missing.

### FR24 (wont) — out_of_scope

A model-specific advice channel appended to the shared conventions at read time, with one directory per model release and a lint forbidding model names in skill bodies. Excluded because the seam only pays once a second model drives the skills, and its own measurements put the extraction at around three per cent of the conventions' length. Two of its findings are kept without it: an accommodation belongs to the model it was measured on, so provenance travels with a rule that moves; and a delegated sweep over-reported by roughly a third, so a finding is spot-checked in the file before it is acted on.

### FR25 (wont) — deferred

A story's phase checked against the state of its own tasks partway through, rather than only at the close. Deferred because a run has legitimate reasons to look at a phase out of order and only the exit is unambiguous; FR3 closes the exit and leaves the middle open.

### FR26 (wont) — deferred

A retrospective's trigger signals computed from the rows rather than reported by the run that is being reflected on — tool errors, phase order, tasks closed with no preceding write or command, criteria met only on a second pass. Deferred as agreed to be worth design time and not yet designed: what the signal set contains, where it is computed, and whether it is a new tool or an addition to an existing report are all open. Three runs closed with no signal fired while logging eight tool errors between them.

### FR27 (wont) — deferred

Session state enforced to accumulate across a run rather than being overwritten by the latest unit. The per-unit record is meant to build up and nothing checks that it does; one run's own closing summary reported that its state held only the last story's outcome. Deferred pending a decision on what enforcement of an uninterpreted blob could even mean.

## Non-Functional Requirements

### NFR1 (must)

No refusal added by this spec changes how a stored row reads. Every new refusal sits on the write path only, so a row already in a state that would now be refused goes on reading exactly as it does today, everywhere it is read.

- For each refusal this spec adds, a row written into the now-refused state before the change reads identically through every tool after it — same columns, same values, same standing in any report that mentions it. `[integration]`

### NFR2 (must)

No epic that closes cleanly before this work stops closing after it. Everything the coverage report newly reports is a warning rather than a gap, so the standing that lets an epic close keeps exactly the meaning it has today.

- Every epic in the committed corpus that reaches a clean close before the change still reaches one after it, and the standing computed for each of its requirements is unchanged. `[integration]`

### NFR3 (must)

A closing coverage summary for one epic is answered by a single call rather than by one page read per requirement. Two such summaries took nineteen minutes each, almost all of it spent paging results back one at a time.

- A closing coverage summary for one epic is obtained in a single tool call, with no per-requirement page read behind it. `[integration]`

### NFR4 (must)

Every refusal this spec adds names what to do instead — the right requirement, the right table, the list that takes the id, or the options that exist — and not only what was wrong. A refusal that reports a fault without a route out is the prose rule it replaced, moved one layer down.

- Every refusal message this spec adds names a requirement, a table, a list or an option that the caller can act on, and not only the fault that was found. `[unit]`

### NFR5 (must)

The change set requires no schema migration. Where a requirement turns out to need one, it is raised rather than absorbed: a schema bump serves this project's own database read-only to the installed server until the plugin is reinstalled, which is a cost taken deliberately and never discovered.

- The schema version recorded by the release before this change set and by the release after it are the same number. `[integration]`

## Environmental Requirements

### ENV1 (must)

Node 22.5.0 or later on the development machine, with `node:sqlite`'s `DatabaseSync` available and its SQLite built with FTS5. The manifest declares the floor and the connection asserts both capabilities at open time.

- The connection refuses to open, with a message naming which capability is missing, where the runtime has no synchronous SQLite binding or its SQLite lacks FTS5; and the manifest declares the Node floor that supplies both. `[integration]`

### ENV2 (must)

The suite runs under Node's own test runner, invoked as `node --test`, which the manifest's test script names. It is the only runner, and every test this spec adds runs under it.

- The manifest's test script invokes the runtime's own test runner, and every test this spec adds is discovered and run by it with no other runner present. `[integration]`

### ENV3 (must)

The repository's pre-commit hook resolves to the guard in this working tree rather than to a path under the plugin cache, so the guard and the schema it checks are the same checkout. A suite assertion already pins this and is the only thing standing between a plugin reinstall and a guard gone stale.

- The existing suite assertion that the repository's pre-commit hook resolves into this checkout rather than into the plugin cache passes after this change set. `[integration]`

### ENV5 (must)

Everything added works where the server is an installed plugin release reading a project's own database, rather than a working tree. A refusal that depends on a path only this checkout has is a refusal that does not exist for anybody running the plugin.

- Every tool added here works where the server is an installed plugin release reading a project's own database, with no path that exists only in this checkout. `[target]`

## Environmental Restrictions

### ENV4 (must)

No runtime or development dependency may be required. The manifest declares both dependency sets empty and they stay empty, so nothing here may be built on a package a contributor has to install.

- Both dependency sets in the manifest are empty after this change set, and the suite runs on a checkout with no package installation step. `[integration]`

### ENV6 (must)

No host capability the harness does not have. No rule may claim that a badly-formed gate is refused, that a thinking level can be pinned per skill, or that a turn can end by handing off to a fresh context. A rule promising a safety net that is not there teaches a run to lean on one that will not catch it, which is worse than the rule's absence.

- must NOT — A skill body or a document a skill reads at startup claims that the host refuses a badly-formed gate, that a thinking level can be pinned per skill, or that a turn can end by handing off to a fresh context. `[integration]`
- control — A claim of that form planted in a skill body makes the check fail, so the check is shown to discriminate rather than to pass over a corpus it is not reading. `[integration]`

## Architecture Decisions

### 05-01 — Where a story's closing conditions live

**Decision status**: accepted  

A story's closing conditions are an optional hook on the shared delivery update factory, asked only when a call sets the finished status.

#### A closing hook on the delivery factory — chosen

The factory already serves both story and task, so the hook is optional and a task simply passes none. It runs inside the tool boundary, which means the refusal can list the outstanding tasks by name — the reconciliation the run never performed — and a test can drive the refused state directly through the same tool a run uses. It needs no new table and no integrity register entry.

| Axis | Assessment |
| --- | --- |
| blast radius | The factory is shared with task, so the hook has to be optional by construction. That is the cost, and it is contained: a task passes none and behaves exactly as before. |
| testability | Highest. The refused state is driven through the same tool a run uses, so the test that proves the refusal fires is the test that proves it can fail. |

#### A database trigger

Unavoidable by construction, and it holds against a direct write as well as a tool call. Rejected because it is invisible from the tool layer and its message cannot name the pending tasks: the caller learns a constraint failed and nothing about which work is outstanding, which fails the rule that a refusal names what to do instead.

| Axis | Assessment |
| --- | --- |
| blast radius | Largest. It is a schema change, which serves this project's database read-only to the installed server until the plugin is reinstalled — a cost NFR5 exists to avoid. |
| testability | Workable but indirect. A test asserts that a constraint failed, not that the caller was told which tasks were outstanding — so the half of the behaviour that matters most is the half no test can reach. |

#### An integrity register entry

Cheapest to add and consistent with how several related invariants are already recorded. Rejected because it reports after the fact and only when someone runs the check, which is the exact failure mode being removed: all three incidents that motivate this were closes nobody looked at again.

| Axis | Assessment |
| --- | --- |
| blast radius | Smallest. Nothing that writes today changes, which is also why it fixes nothing that writes today. |
| testability | Easy to test and the test proves the wrong thing: that the register reports the state, not that the state cannot be reached. |

### 05-02 — Whether the coverage report extends the integrity check or stands alone

**Decision status**: accepted  

The coverage report is a new cross-cutting tool of its own, not an extension of the integrity check.

#### A new cross-cutting tool — chosen

Integrity asks whether the rows hold; coverage asks what they say. They are different questions with different scopes — integrity takes none and coverage takes a spec and optionally an epic — so keeping them apart means neither call pays for the other, and a skill can ask the one it needs.

| Axis | Assessment |
| --- | --- |
| cost per call | Each caller pays only for the question it asked. A skill wanting the gap analysis does not run an integrity sweep, and a skill wanting integrity does not page the coverage graph. |

#### Extend the integrity check

One cross-cutting check rather than two, and a skill running one would get both. Rejected because it puts a per-spec scope on a tool that currently takes none, and makes every integrity call pay for a coverage sweep it did not ask for.

| Axis | Assessment |
| --- | --- |
| cost per call | Every integrity call pays for a coverage sweep it did not ask for, and the tool acquires a scope argument that means nothing to half its callers. |

### 05-03 — How the verification and claim arguments change without leaving two ways to write one row

**Decision status**: accepted  

The timestamp arguments are replaced by booleans in place, with the skill text landing in the same change rather than after it.

#### Swap in place, skill text in the same change — chosen

There is exactly one way to stamp a row afterwards, and the fabricable form stops existing. The sequencing is already forced by a suite assertion that requires every argument a run passes to be named in that skill's body inside a code span — its word boundary means the old argument name does not satisfy a run passing the new one — so the two have to land together whichever option is taken.

| Axis | Assessment |
| --- | --- |
| ways to write one row | One. The fabricable form stops existing, which is the point of the change. |

#### Accept both forms for a deprecation window

Gentler on any caller outside this repository. Rejected because it leaves two ways to write one row, one of which is the fabrication the change exists to remove — and a window with nothing scheduled to close it is a permanent second path.

| Axis | Assessment |
| --- | --- |
| ways to write one row | Two, for as long as the window lasts — and nothing is scheduled to close it, so in practice permanently. |

#### A new verb beside the old one

Leaves existing callers untouched and makes the new path opt-in. Rejected for the same reason as the window, with an extra cost: two verbs doing one thing is a roster a skill has to choose between, and the wrong choice is the one that still fabricates.

| Axis | Assessment |
| --- | --- |
| ways to write one row | Two, permanently and by design, plus a choice a skill has to make correctly every time — where one of the two answers is the fabrication. |

### 05-04 — Where the scope-id check learns which table a scope points at

**Decision status**: accepted  

Each scope declares its parent table beside itself in the list registry, so the refusal can name both the table and the list that takes the id.

#### Declare the parent table beside each scope — chosen

Explicit and greppable, and it is what lets the refusal name the list that takes the id rather than only the table it belongs to. Naming the list is most of the value: the incident was a run that read an empty page as a failed write and rewrote ten tags, and what it needed was the other list's name.

| Axis | Assessment |
| --- | --- |
| what the refusal can say | The table the id belongs to and the list that takes it, which is the sentence the incident needed. |

#### Derive it from the schema's foreign keys

Nothing to declare and nothing to keep in step, since the schema already holds the relationship. Rejected because a foreign key names a table and the registry names a list, and the mapping from table back to list is not one-to-one — so the refusal could say which table the id belongs to but not which list would accept it.

| Axis | Assessment |
| --- | --- |
| what the refusal can say | The table only. Table to list is not one-to-one, so the half the caller needs cannot be derived. |

### 05-05 — Where a skill rule lands so that it reaches the runs it is written for

**Decision status**: accepted  

A rule goes in the shared section its consumers already cite, and only a rule with a single consumer goes in that skill's own body.

#### Into the shared section its consumers already cite — chosen

Reach is not established by a rule existing. The ban on speaking an id aloud sat in its own shared section from 0.6.0 and went on being broken because one skill of twenty-three cited that section; the fix was one sentence placed inside a section all twenty-three already cite. Placement is the whole mechanism, and a rule with several consumers has a section that all of them read.

| Axis | Assessment |
| --- | --- |
| reach | Every run of every skill that cites the host section, with no per-skill edit and nothing to keep in step. |

#### A new shared section per rule

Each rule gets a name a skill can reference, and the shared file stays readable as a list of named procedures. Rejected on the same evidence: a section nothing cites is a rule nothing reads, and adding one produces a document that looks complete while reaching nobody.

| Axis | Assessment |
| --- | --- |
| reach | Only the skills that are separately edited to cite it — measured at one in twenty-three the last time this was tried, with no diagnostic saying so. |

## Dependencies

- builds_on → 03
