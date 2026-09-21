# Coverage reporting

**Number**: 05-01  
**Source spec**: 05  
**Status**: complete  

## Why this epic is shaped this way

The report and the requirement label sit in one epic although they land in different files, because they share a hazard rather than a module. Both are values a caller reads back, and neither is visible to any of the derived sweeps this suite carries: a new tool's registration cost has to be established by running each sweep's own reader against the intended change before a line of it is written, and a field computed after the read reaches neither the schema nor the tool registry, so no sweep can see it at all.

That second case is the sharper one and it is why the label story carries a task that looks like documentation. The only pressure on a derived response field is the skill sentence that consumes it. An answer of *no sweep covers this* is a finding to write down, not a relief.

The warnings depend on the report and could not start before it, which is the only internal ordering here. Everything else in this epic is independently schedulable.

## Story 1 — The coverage report for one spec

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Given a spec, the report returns every requirement with its standing, computed from the coverage rows bound to it. `[integration]`
- It returns, each as its own list, the criteria that are accounted for by nothing, the criteria carrying no approach tag, and the must-have criteria. `[integration]`
- It returns a block of counts, and every number in that block agrees with the list it summarises. `[unit]`
- The whole report is obtained in a single call, with no per-requirement page read behind it. `[integration]`

### Task 1 — Establish which derived sweeps read the tool registry

**Status**: complete — Census run against the intended tool before any of it was written, using each sweep's own reader imported from where the sweep imports it. Count: one of nine live, eight silent — and the live one fires only under one of three candidate declarations. Live: `naming`, whose pinned exemption list (`check_integrity`, `publish`, `search`) takes a fourth entry if the tool declares a table that is not an authored table. Silent: `parity`, `sparse` and `conformance` all enumerate `create_` tools only; `schema`, `entry-index` and `prose-columns` are schema-derived and the tool adds no DDL; `body-reads` fires only on a tool declaring `include_body`. The reader was validated by reproducing the pinned list exactly on the untouched registry first, so what it says about the intended tool is about the sweep rather than about a model of it — the first attempt used `sqlite_schema` type='table' and disagreed, because `naming` reads `authoredTables`, which excludes an FTS index and its shadow storage.  

Run each sweep's own reader against the intended tool before a line of it is written, and record the count. Addresses the registration cost, not the report's behaviour. A sweep that turns out to be silent on this surface is a finding to write down rather than a relief.

### Task 2 — Add the coverage-check module and register it

**Status**: complete — `check_coverage` is registered and reachable — the registry goes from 183 tools to 184, and the tool declares `table: 'coverage'` with five live tables in `reads`. The census's prediction held on the one live sweep: `naming` stays green, its pinned exemption list untouched, because `coverage` is a word the schema holds and so the tool takes no exemption. The module it delegates to, `src/coverage/report.js`, was written whole rather than stubbed, so tasks 3 and 4 are exercising and correcting it against real rows rather than starting from nothing.  

The module and its registration only. Scope is the tool existing and being reachable, not what it computes.

### Task 3 — Compute each requirement's standing from its coverage rows

**Status**: complete — Standing comes from the coverage rows bound to the requirement and from nothing on the requirement itself: `bound` and `verified` from a grouped left join, `standing` as unbound / partial / verified. Three states rather than two because *nothing is bound* and *bound but unverified* want different things done about them. The claim is deliberately excluded from the word — it is a judgement a person made, and folding it into a value computed from row counts would report that judgement as though the rows had produced it. The left join is what makes an unbound requirement appear at all; an inner join would answer only about requirements that are already bound. Exercised against this project's own spec 05 and independently cross-checked in SQL: 38 requirements, 79 live bindings, 4 unbound — and the four are FR24 to FR27, exactly the ones the spec records as out of scope or deferred.  

Addresses the first criterion. The standing comes from the rows bound to the requirement and from nothing on the requirement itself.

### Task 4 — Assemble the three lists and the counts block

**Status**: complete — Three lists over the live story criteria reachable from the spec, superseded ones excluded because an overtaken criterion is neither delivered nor outstanding. Every count in the block is the length of the array it summarises, taken in the same pass, so the two cannot disagree — which is the whole point: the miscount the criterion cites is a run that reported twelve of twelve over thirteen rows, two computations of one number agreeing until they did not. The set-wise reading of `accounted_for` was checked against `warrant.js`'s per-row rule over all 336 criteria of the five specs, including the nine carrying a warrant: zero disagreements, so the two answers agree rather than being trusted to. `unaccounted` is exercised by real data (4, 4, 0 and 12 across the four completed specs); `untagged` reads zero everywhere, so it has no real-data exercise and needs a planted member in task 5 — a count agreeing with an empty list is a green over nothing.  

Addresses the second and third criteria. The counts are derived from the lists in the same pass, so the two cannot disagree.

### Task 5 — Write tests for The coverage report for one spec

**Status**: complete — Five tests in `tests/coverage-report.test.js` over a purpose-built fixture in `tests/support/coverage-corpus.js`, written entirely through the create tools. Four control mutations were run rather than described, and all four were killed: a per-requirement standing lookup takes the large corpus from 10 statements to 50 and fails the bound; dropping the warrant from the unaccounted rule turns finished work into a gap; widening the must-have rule from `moscow = 'must'` to any priority sweeps in the should-only criterion; inverting the tagged test reports the wrong criteria. Each planted member belongs to exactly one list, so an assertion rests on one column rather than on an overlap — the untagged criterion had to be bound to make that true, since an untagged criterion is naturally unaccounted for as well. The fixture reaches an accepted ADR the long way round, through create-option-accept, because register entry 8 refuses the shortcut and a fixture building a row the tools cannot produce would be the wrong corpus to read.  

Covers the criteria tagged integration and unit, including the single-call criterion, which is checked by counting the reads the call makes rather than by timing it.

### Retro

- The sweep census this story opens with paid for itself twice, and the second time was not what it was written for. Its stated job was to budget the registration cost, and the answer — one of nine sweeps live, eight silent — turned out to be a design constraint rather than a number: `naming` pins the list of tools exempt from its vocabulary rule to exactly three names and says in a comment that a fourth is a decision, so `table: 'coverage'` was chosen because *coverage* is a word the schema holds, where `check_integrity` had to take the exemption because *integrity* is not. The prediction then held exactly, and the whole story cost zero existing assertions across 981 tests. The second payment was methodological: the first census disagreed with the pinned list on the untouched registry, because it read `sqlite_schema` where `naming` reads `authoredTables`, which excludes an FTS index and its shadow storage. Reproducing the baseline before asking about the intended tool is what caught it — without that step the census would have reported a confident number about a model of the sweep rather than about the sweep, and it would have been believed.

## Story 2 — The epic roll-up

**Status**: complete  
**Blocked by**: Story 1  

### Acceptance Criteria

- Given a spec and an epic, the report adds a roll-up of that epic's stories, its bindings and its verified bindings. `[integration]`
- On a fixture whose bindings number thirteen, the roll-up says thirteen and agrees with the lists it summarises. `[unit]`

### Task 1 — Add the epic roll-up branch

**Status**: complete — `epic_id` is an optional argument that adds an `epic` roll-up and narrows nothing else — the spec-level figures are identical with and without it, which was checked rather than assumed. The roll-up reaches bindings through the criterion that quotes them rather than through the requirement, because a requirement belongs to the spec and may be shared across epics: counting by requirement would credit one epic with another's work. Bindings are fetched as rows and counted by length, the same discipline the spec-level block follows, so the roll-up's number and the rows it describes cannot disagree. The field is `null` rather than absent when no epic was named, so a consuming skill reads one shape either way. Exercised against epic 05-01 itself: 5 stories, 15 bindings, 4 verified — and the four verified are the ones this run marked at story 1's gate.  

Addresses the roll-up criterion. Scope is the added branch when an epic is named; the spec-level report is Story 1's and is not changed here.

### Task 2 — Write tests for The epic roll-up

**Status**: complete — Three tests. The thirteen-binding fixture is the uneven shape plus eight fillers, and thirteen is asserted against a direct count of the rows in the table as well as against the roll-up — the miscount behind this criterion was a run reporting twelve of twelve over thirteen rows, so the figure is checked against the table rather than against the fixture's own arithmetic. A third test builds a second epic under the same spec binding the same requirement: it is the only thing that catches a roll-up reaching bindings through the requirement instead of the criterion, and the mutation proving that was run. Two control mutations, both killed — the by-requirement join fails the neighbour test alone, and counting verified off the wrong column fails two.  

Covers both criteria, with a fixture whose binding count is known and is not the count any earlier fixture uses.

### Retro

- The roll-up's real hazard was not in either criterion, and the criteria would both have passed over it. A binding belongs to an epic because the criterion quoting it does, but the obvious join reaches it through the requirement — which belongs to the spec and may be shared by any number of epics. Written that way the roll-up credits every epic under a spec with every other epic's bindings, and it is invisible in a fixture holding one epic, which is what every fixture in this story held until a test was written specifically to hold two. The mutation confirmed it: reaching through the requirement fails only the neighbour test and leaves both of the story's own criteria green. That is the shape retro 07 named from the other side — a rejection whose evidence lives in a criterion that can move — arriving here as a defect no stated criterion was watching for, found by asking what a wrong answer would look like rather than by checking the answer.

## Story 3 — The three warnings

**Status**: complete  
**Blocked by**: Story 1  

### Acceptance Criteria

- A requirement whose every binding is verified and whose claim was never made is reported as claimable. `[integration]`
- An in-scope requirement that carries no acceptance criterion at all is reported, which is a state no gap computed from criteria can ever show. `[integration]`
- One criterion text, whitespace-normalised, live under two different stories is reported as duplicated. `[integration]`
- must NOT — One of the three new findings is reported as a gap rather than as a warning. `[integration]`
- control — An epic that closes cleanly before the warnings exist still closes with all three present and firing, so the refusal to call them gaps is shown to hold where it matters. `[integration]`

### Task 1 — Report a requirement whose bindings are all verified and whose claim is unmade

**Status**: complete — The condition is over the bound set and the claim stamp: bindings above zero, every one verified, and no claim made. `bound > 0` is load-bearing rather than defensive — without it a requirement nothing binds satisfies "every binding is verified" vacuously, and the warning would invite a claim that the fragments account for a requirement no fragment quotes. The mutation dropping that guard was run and is caught. Whether a claim already made still describes what is bound is deliberately not this warning: `claimHash` is taken over the bound fragments and their criterion ids, so rewording a criterion clears its binding's verification and leaves the claim reading current — an asymmetry retro 06 recorded, and a stale claim is its own finding rather than one of FR9's three. Fires once on this project's spec 05 and twice on spec 04.  

Addresses the claimable warning. The condition is over the bound set and the claim stamp, and it is a warning in every case.

### Task 2 — Report an in-scope requirement carrying no acceptance criterion

**Status**: complete — An `EXISTS` over `acceptance_criterion` folded into the standings query, so the warning costs no statement of its own and the single-call bound still holds. Restricted to requirements in scope, because one ruled out of the iteration is supposed to carry nothing — the mutation dropping that restriction reports the excluded one and is caught. The criterion's claim that no gap can ever show this state is structural rather than incidental, and the test asserts it the only way it can be asserted: a gap is computed from criteria and a requirement with no criteria contributes none to that population, so the gap list is shown empty on the very corpus where this warning fires. It fires fifteen times on this project's own spec 05, which is the first time anything has reported that.  

Addresses the second warning. This state can never surface as a gap, because a gap is computed from criteria and this requirement has none — which is why it needs its own detection rather than a widened gap rule.

### Task 3 — Report one criterion text live under two stories

**Status**: complete — Grouped on whitespace-normalised text over live criteria, and reported only where the group spans more than one story. Normalisation collapses runs of whitespace and trims, and goes no further: case and punctuation folding would start merging criteria that are genuinely different, reporting work as duplicated when it is not. The two mutations were run — comparing exact text misses the planted pair entirely, and dropping the two-story condition reports a text repeated under one story, which is a position collision the `UNIQUE` constraint already owns and would arrive here under this warning's name. Computed from rows the report had already fetched, so it costs no statement. Fires ten times on this project's spec 04.  

Addresses the third warning. Comparison is on whitespace-normalised text over live criteria only.

### Task 4 — Write tests for The three warnings

**Status**: complete — Five tests on a second fixture, `specWithWarnings`, built for the opposite property to `unevenSpec`: this one is clean, so the gap lists are empty and all three warnings still fire — which is the only corpus on which the rejection and its control mean anything. The rejection reads the refused thing first and has its own test; the control has its own test and its own rows, per the two retro lessons this run applied.

**The mutations found a real weakness in the rejection and it was fixed.** Both it and the control originally pinned `warnings.counts` to exactly one of each, so every mutation that changed which rows a warning held made the rejection go red for somebody else's reason — its own evidence was never tested. Weakened to *the warnings fired at all*, the five mutations now separate cleanly: leaking a warning into the gap list fails the rejection and the control; the vacuous-claim, exclusion and one-story mutations each fail only the test that owns them. That is the retro 08 lesson arriving as a defect in this run's own work rather than as a rule followed.  

Covers the three detections, the rejection that none of them is a gap, and its control — an epic that closes today closing with all three firing. The control is its own test with its own rows, not a line inside the rejection's.

### Retro

- The retro lesson this story was planned around turned up as a defect in the story's own tests, which is a better outcome than following it would have been. Retro 08's rule — give a rejection its own test with its own control row — was applied at the start, and the rejection still ended up unable to fail for its own reason: both it and the control closed by pinning the warning counts to exactly one of each, so every mutation that changed which rows a warning held made the rejection go red on somebody else's evidence. Five mutations were run and the pattern in the output is what showed it, not the code. Weakening both closing assertions from an exact count to *the warnings fired at all* separated them: the leak mutation now fails the rejection alone among the membership mutations, and the vacuous-claim, exclusion and one-story mutations each fail only the test that owns them. The general shape worth keeping: a control that pins an exact figure is a change detector wearing a control's clothes, and it makes the assertion it guards fail for reasons that have nothing to do with it.

## Story 4 — The requirement label on coverage rows

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A coverage row read back carries the label of the requirement it binds, so the read-back can be checked against a label rather than against an id held from an earlier call. `[integration]`
- The label is present on rows the coverage report returns as well as on rows read directly, and the skill text that quotes it names the field. `[integration]`

### Task 1 — Derive the requirement label on the coverage read path

**Status**: complete — `src/coverage/label.js` derives `requirement_label` on the read path, declared on `read_coverage` alone — the list takes the derivation from the read tool, so the two cannot answer differently. Read-side rather than stored, so relabelling a requirement moves the label with it rather than leaving a plausible stale copy; the test asserts that by relabelling and reading back. One query per page rather than per row, following `warrant.js`. `null` where the requirement is missing, because a row whose requirement has gone is a broken binding and the integrity register's business, and an empty string would look like a label while naming nothing. The report's roll-up joins the label rather than reusing this module — that query already reaches the requirement, so riding the join costs nothing where the read tools have no join to ride.  

Addresses the first criterion. A read-side derivation, so it is not stored and there is no second place for it to arrive from.

### Task 2 — Name the label field in the skill text that reads it

**Status**: complete — A rule added to `/dpm:do`'s Recording the verification step: say which requirement a row binds by its `requirement_label`, never by its `requirement_id`, because an id is checkable only against an id the run held from an earlier call — which confirms two calls agree rather than that either is right. That sentence is the field's only pressure and the test says so in as many words: a value computed after the read reaches neither the schema nor the tool registry, so every derived sweep in this suite is blind to it. The mutation deleting the sentence was run and the test goes red, which is what makes this a load-bearing line rather than the documentation task it looks like.  

Addresses the second criterion, and it is the only pressure this field has. A value computed after the read reaches neither the schema nor the tool registry, so no derived sweep in this suite can see it — the skill sentence that consumes it is what holds it in place.

### Task 3 — Write tests for The requirement label on coverage rows

**Status**: complete — Three tests. The read-back is checked against a literal label rather than against an id kept from the create call, which is the whole point of the field; `include_body` is passed on the read whose value an assertion consumes. A control asserts the label is not the id under a friendlier name, and another relabels the requirement and reads back, which a stored copy would fail. Three mutations run and killed: echoing the id, removing the derivation from `read_coverage`, and deleting the skill sentence.

Retro 05's prediction was right in shape and wrong in number. It expected an additive read-side field to cost exactly one deep-equal assertion; it cost **zero** across 994 tests. The reason is the same one the observation gives — the sweeps read declarations rather than row shapes — plus one it could not have known: the assertion it predicted deep-equals a *document* row against its read-back, and nothing in this suite does that for a coverage row.  

Covers both criteria. The read-back assertion asks for the withheld column explicitly — a comparison written without it compares undefined against undefined and passes on the defect it was written to catch.

### Retro

- The incorporated retro prediction was right in shape and wrong in number, and the gap between the two is the useful part. Retro 05 said an additive read-side field costs exactly one deep-equal assertion and no derived sweep can see it; this field cost zero across 994 tests. The sweep half held exactly — nothing in the suite noticed the field arriving, which is why the story carries a task putting its name into a skill sentence and why the test for that task says in as many words that the sentence is the field's only pressure. The count differed because the assertion retro 05 predicted deep-equals a *document* row against its read-back, and nothing in this suite does that for a coverage row: the prediction was about the mechanism and the number was about which tables happened to have that kind of test. Worth carrying forward as the sharper form of the lesson — a retro's mechanism transfers and its arithmetic does not, and a run that had expected the one failure and gone looking for it would have spent the time on nothing.

## Story 5 — Verify cross-story integration for Coverage reporting

**Status**: complete  
**Blocked by**: Story 1, Story 2, Story 3, Story 4  

### Acceptance Criteria

- The spec report and the epic roll-up return one response shape, so a skill quoting a count names one field whichever scope it asked for. `[integration]`
- The three warnings appear alongside the standings in the same response and change no standing that response computes. `[integration]`

### Task 1 — Write the cross-story integration tests for Coverage reporting

**Status**: complete — Three tests over the two seams no earlier story could see from inside itself. The response contract is pinned by name — every key of the top-level object, of `counts`, of `epic` and of `epic.counts` — because the counts block exists so a skill quotes a number instead of deriving one, which makes each field name a promise whose breach is silent: a skill quoting a count that is no longer there renders an absence, and an absence reads as a section that was not needed. The rename mutation was run and fails three tests.

**The second mutation found a hole and the hole was real.** Filtering the criteria by the named epic survived the entire suite, because every fixture to that point held one epic and scoping to the only epic there is narrows nothing — so every assertion that an epic argument narrows nothing else was passing against a report that narrowed everything. A two-epic fixture was added, the mutation now fails it, and the test carries a control proving the fixture really does span two epics.  

Covers the two cross-story criteria: one response shape across both scopes, and the warnings coexisting with the standings without altering one.

### Retro

- The cross-story story earned its place on a defect every earlier story's suite was structurally unable to see. "Naming an epic narrows nothing else" was asserted in story 2 and passed, and it went on passing under a mutation that filtered the criteria by the named epic — because every fixture built up to that point held exactly one epic, and scoping to the only epic there is narrows nothing. The claim was true of the fixture and untested as a claim. A two-epic corpus makes the mutation fail, and the test carries a control proving the fixture really does span two. The generalisable shape: an assertion that an argument leaves something alone is vacuous whenever the fixture has only one of the thing that argument selects, and the one-of-a-kind fixture is the normal case early in an epic — so the check is not "did I assert it" but "could the fixture have told me if it were false".

## Dependencies

- blocks → 05-07

## Retro Applied

- 06 · A fixture with no rows satisfies a claim about rows, and verification and the completeness claim decay on different inputs · applied — The second half bears directly on Story 3: the claimable warning is a condition over the bound set and the claim stamp, and those two move on different inputs — rewording a criterion clears a row's verification and leaves the claim current, because the claim hash is over fragment and criterion id rather than criterion text. So the warning is built against that asymmetry rather than against the intuitive reading that both move together. The first half is carried as a fixture rule for the whole epic: every counting and list assertion runs against a fixture holding real rows, because a count agreeing with an empty list is a green over nothing.
- 07 · A must-NOT whose control lives in another criterion reads as verified when that criterion moves · applied — Story 3 carries a must-NOT and a separately-stated control criterion, which is the arrangement this describes. Applied as two rules for that story: the control gets its own rows rather than borrowing the rejection's, so the rejection cannot read as verified on the strength of a criterion that moved; and where the verification needs a wider reading of a query to show the difference is the narrowing rather than something destroyed, that query is held in the test file and runs on every pass, never as a hand-edit to the source that the next reader takes on trust.
- 08 · A rejection sharing a test with its positive is verified only if the mutation fails its assertion first · applied — This is the reasoning behind Story 3 Task 4's instruction that the control is its own test with its own rows rather than a line inside the rejection's, so the task is carried out for the reason rather than by the letter. The rejection's test reads its refused row first and asserts the approved sibling afterwards purely as control, which is what makes both go red independently under one mutation. Assertion order inside a shared test is load-bearing evidence, and this epic does not depend on it anywhere.
- 06 · A withheld column compared without include_body passes on the defect it was written to catch · applied — Story 4 Task 3 already names this trap and retro 07 records it costing a third red run, so it is carried across every story rather than left to the one task that mentions it: every read-back assertion in this epic asks for the withheld column explicitly, and `read_coverage` withholding `spec_fragment` is the specific case Story 1 and Story 4 both touch. The companion half is carried too — where a guarantee belongs to a column's CHECK rather than to the tool boundary, it is asserted through both, because a boundary-only assertion is satisfied by a handler guard that every other writer routes around.
- 05 · An additive read-side field costs one deep-equal assertion, and no derived sweep can see it · applied — Story 4 adds a derived field to the coverage read path, which is the same shape. Carried two ways: the breakage is expected on deep-equal assertions over read-back rows and nowhere else, so a wider failure is a real defect rather than this prediction; and it is the evidence behind Story 1 Task 1, which runs each sweep's own reader against the intended tool rather than assuming registration is covered. The observation's own warning that `table` does not answer whether a tool returns document rows is the reason that task counts rather than reasons.
