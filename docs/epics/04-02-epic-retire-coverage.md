# Retiring a binding

**Number**: 04-02  
**Source spec**: 04  
**Status**: complete — Story 1 was superseded during the pivot and delivered as epic 04-01 story 4 — the write arm had to land with the column it reaches. The promise stands as kept; stories 2, 3 and 4 were delivered here. FR1 is left unclaimed: five coverage rows bound to story 1's superseded criteria are still unverified, and retiring them needs retire_coverage, which this project's database does not have until the plugin is reinstalled past schema 25.  

## One criterion here was proposed rather than transcribed

Story 3's fifth criterion — that retiring one binding does not clear `verified_at` on any other live binding of the same requirement — is not in the spec. It was proposed at that story's gate under the rule that a story touching data mutation may be offered one or two further rejections, and it was accepted.

It carries no coverage row, and that is the reason rather than an oversight. A coverage row binds a criterion to a verbatim fragment of a requirement's own text, and no requirement states this; binding it to the nearest-sounding clause would put a fragment in the row that does not support the criterion, which the integrity register reports later as a broken invariant rather than as the guess it was.

It is verified like any other criterion. What it does not do is discharge a requirement, so the coverage roll-up at the end of the epic should read it as work done and not as coverage.

## Story 1 — The retire_coverage tool

**Status**: superseded — Moved into epic 04-01 as story 4. The write arm has to land with the column it reaches: three derived sweeps require every state the schema admits to be reachable from the corpus, and the corpus is built by driving tools, so a column in 04-01 and its tool in 04-02 leaves 04-01's own suite failing.  
**Blocked by**: —  

### Acceptance Criteria

- retire_coverage sets retired_at and retired_reason together on a live binding, and read_coverage on that id returns both. `[integration]`
- list_coverage omits a retired binding by default and returns it when include_retired is passed. `[integration]`
- must NOT — update_coverage does not set retired_at or retired_reason. Retirement is its own tool, as it is for every other retirable thing in the surface. `[unit]`
- must NOT — No tool in the registered surface deletes a coverage row. `[unit]`
- control — update_coverage still sets position and verified_at on the same row, so the refusal above is specific to the retirement columns rather than a tool that updates nothing. `[unit]`

### Task 1 — Register retire_coverage and write its handler

**Status**: pending  

Sets the retirement pair together on a live binding. Addresses the schema-and-tool boundary: the tool must not refuse what the schema permits, so a sound binding retires as readily as a broken one.

### Task 2 — Hold update_coverage to position and verified_at

**Status**: pending  

The refusal is the tool's declared arguments rather than a guard inside the handler. Addresses the rejected path, not the happy path.

### Task 3 — Write tests for The retire_coverage tool

**Status**: pending  

Covers the criteria tagged unit and integration, including the control that update_coverage still updates what it is meant to.

## Story 2 — A retirement carries its reason

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- retire_coverage called with no reason is refused, and the row is unchanged afterwards. `[integration]`
- That refusal is a boundary rejection naming the missing argument, rather than an internal error surfacing from the schema. `[unit]`
- must NOT — A row must not exist with retired_at set and retired_reason null, whatever writes it. The tool is one path to that state and a direct write is another. `[integration]`
- control — retire_coverage with a reason succeeds on the same binding, so the refusals above are the missing reason rather than a tool that refuses everything. `[integration]`

### Task 1 — Give the tool a boundary rejection naming the missing argument

**Status**: complete — Already delivered by epic 04-01 story 4: retire_coverage declares reason required with minLength 1, and validate() answers every omission shape by name. No production code written; the work was the assertion.  

The caller sees a rejection at the boundary rather than a CHECK constraint surfacing from the schema. Scoped to the error path.

### Task 2 — Write tests for A retirement carries its reason

**Status**: complete  

One arm per path to the rejected state — the tool and a direct write — because refusing one proves nothing about the other, and a control that the tool succeeds with a reason.

### Retro

- The whole story was already delivered, and the retro lesson that predicted it was the one applied to a different story. Task 1 asked for a boundary rejection naming the missing argument; `retire_coverage` already had it, because epic 04-01 story 4 declared `required: ['id', 'reason']` with `minLength: 1` and `validate()` in `src/tools/convention.js` answers every omission shape by name — `'reason' is required` for absent, undefined and explicit null, `'reason' must not be empty` for the empty string. No production code was written. The lesson from retro 01 ("read the tree before building; expect the ratio to favour already-there") was dispositioned onto story 4 of this epic at the gate, and story 2 turned out to be the one it described.

Four omission shapes, not one, and the four-shape sweep is what makes criterion 2 an assertion about *which layer answers* rather than about a message. Absent, `undefined`, explicit `null` and `''` reach three different branches of the validator, and each is asserted to name the tool, name the argument, and contain no `CHECK constraint` or `SQLITE_` text. The explicit-null case is the interesting one: `validate()` treats null as "clear this column" everywhere else, and refuses it for a required argument precisely so the caller does not meet a NOT NULL failure naming a column they never wrote.

Criterion 3's "whatever writes it" needed four statements, and asserting two would have been the same false pass the criterion is aimed at. The tool's `required` list stops a caller and says nothing about a migration or a fixture; the column's `CHECK ((retired_at IS NULL) = (retired_reason IS NULL))` is what holds for every writer. So the half-set state is attempted on the UPDATE path in both directions and on the INSERT path in both directions, and closed with the audit query a reviewer would actually run — zero rows where the two columns disagree about being null.

## Story 3 — The claim over a retired set

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Retiring one of three bindings on a claimed requirement clears coverage_claimed_at and coverage_claim_hash together. `[integration]`
- A claim made after the retirement hashes over the remaining bindings only, and claimState reports that claim current. `[integration]`
- must NOT — A retired binding does not count toward the bound total claimState reports. `[integration]`
- must NOT — No project is required to re-make a claim it had already made, as a consequence of this change. `[integration]`
- must NOT — Retiring one binding does not clear verified_at on any other live binding of the same requirement. `[integration]`
- control — Retiring a binding on one requirement leaves another requirement's standing claim intact, so the withdrawal is scoped rather than a trigger that unclaims everything. `[integration]`
- control — A live binding on the same requirement still counts toward the bound total, so the exclusion above is the retirement rather than a count that returns zero. `[integration]`
- control — A requirement with a retired binding is unclaimed, so claims surviving a migration is the migration leaving them alone rather than claims never being cleared at all. `[integration]`

### Task 1 — Qualify claimHash to live rows

**Status**: complete  

The set the hash reads. Addresses one half of the trigger-set-and-claim-hash boundary; the other half is task 2, and the contract is that both name the same set.

### Task 2 — Add the fifth unclaim trigger watching retired_at

**Status**: complete  

Withdraws the claim standing over a set a retirement has changed. Scoped to the requirement the binding belongs to, which is what the sibling-claim control checks.

### Task 3 — Exclude retired rows from claimState's bound total

**Status**: complete  

The count a reader sees, as distinct from the set the hash covers.

### Task 4 — Write tests for The claim over a retired set

**Status**: complete  

Four positives and three controls, plus the rejection that a retirement must not clear a sibling binding's verification. Each control separates the behaviour working from the check having stopped looking.

### Retro

- The three production changes landed as planned and the story's own suite passed on its first run. What the story cost extra was two assertions elsewhere that pinned the newest schema version as a literal — `integration.test.js` asserting `targetVersion() === 25`, and `coverage-retirement-environment.test.js` asserting `migrate` applied exactly `[PREVIOUS + 1]`. Neither was about the behaviour under test: the first compared a number in a test file against a number in the schema directory and asked neither database anything, and the second was a copy of the schema directory's contents. Both were rewritten to derive — read the version from each database and compare to `targetVersion()`, and assert only that the fixture was built one migration behind. A migration that is additive should cost no test changes at all; the two it cost were the ones that had written down what the files say instead of reading it.

The same class of assertion had already been corrected once inside this epic, in coverage-retirement-migration.test.js, so this is the third instance and the pattern is worth stating: a test naming the current schema version goes red on the next migration for a reason unrelated to what it protects.

## Story 4 — Freeing the natural key

**Status**: complete — Delivered without production code: migration 025's partial index and epic 04-01's retire_coverage already carried the behaviour, and epic 04-01 story 4 had asserted two of the five criteria. The new suite tests/coverage-key-reuse.test.js holds the other three open — the two rows coexisting, the count following the column rather than the table, and the same triple retired twice, which is the one behaviour a plain UNIQUE cannot express.  
**Blocked by**: —  

### Acceptance Criteria

- After retiring a binding, create_coverage with the same requirement, fragment and criterion succeeds and yields a live row. `[integration]`
- The retired row and its live replacement coexist, and only the live one counts toward the bound total. `[integration]`
- must NOT — Two live bindings on the same triple must not exist: creating a second while the first is live is still refused. `[integration]`
- must NOT — Recovering from a mistaken retirement must not require destroying the requirement or the criterion the binding hangs between. `[integration]`
- control — Two retired bindings on the same triple can exist — retire, re-create, retire again — so the index constrains live rows rather than the table. `[integration]`

### Task 1 — Write tests for Freeing the natural key

**Status**: complete  

The partial unique index landed in epic 1 and is exercised here for the first time. The two-retired-rows-on-one-triple control is what separates a UNIQUE somebody moved from one somebody qualified; without it every other criterion in the story passes either way.

### Retro

- The story needed no production code — the partial index shipped in migration 025 and `retire_coverage` in epic 04-01 already delivered it, and two of the five criteria were already asserted. What the story was actually for is the control: two retired rows sharing one triple. Every other criterion here passes against a plain `UNIQUE` on the table, because "a replacement can take the key" is satisfied by a schema that deleted the first row and "a duplicate is refused" is satisfied by a schema that refuses all of them. Only the retire-twice cycle distinguishes a constraint somebody narrowed from one somebody moved. The refactoring pass then found five near-copies of the same coverage fixture across the suite and merged the three with identical shape into `boundCoverage` in `tests/fixtures/planning.js`, leaving `decay.test.js` and `integration.test.js` alone because theirs create a verified row and return no argument factory.

Generalisable: a story whose criteria are already satisfied by earlier work is not necessarily an empty story. The question is whether any criterion distinguishes the delivered design from the one it replaced — here exactly one did, and it had never been exercised.

## Dependencies

- blocks → 04-04
- blocks → 04-05

## Retro Applied

- 02 · Codebase Discoveries · applied — "A shape that was right for one detector had to change when the second arrived." claimHash was right while every binding counted; story 3 adds a second kind of binding and the shape has to move rather than be special-cased at the call site. Carried into Step 1's exploration of src/coverage/claim.js.
- 02 · Complexity Underestimates · applied — "Adding a table to this schema costs five registrations, not one." Epic 04-01 paid exactly this: a state added by migration 025 broke three derived sweeps that read a tool-driven corpus, and two stories went red before the write arm landed. Applied here as the lens on story 3, which changes what claimHash is computed over — every existing claim invalidates, and the sweeps that judge claim state have to be walked before the story is called done rather than after.
- 05 · Complexity Underestimates · applied — "The additive field cost exactly one assertion in 837, and it is the one the spec predicted." The counterpart lesson: an additive change is cheap and a change to a derived value is not. Story 3 is the second kind — it moves what a hash is taken over — so this run does not carry 04-01's smooth additive experience into it as an expectation.
- 01 · Scope Surprises · applied — "Read the tree before building; expect the ratio to favour already-there." Story 4 (Freeing the natural key) is very likely already delivered: migration 025 made coverage_binding a partial unique index over live rows, and epic 04-01 story 4 asserted a retired binding frees its key. This run reads that before writing anything, and if the criteria are already true the work is the assertion rather than the code — which is what 04-01's stories 4 and 5 both turned out to be in part.
- 02 · Testing Gaps · applied — "A must-NOT control found a hole in itself, and only because the mutation was run rather than described." Story 2's third criterion is a must-NOT about a row that must not exist whatever writes it, and story 4's is about a natural key that must not make a mistaken retirement permanent. Both get a control that is executed — a planted write watched being refused — rather than an argument that the schema would refuse it.
- 05 · Testing Gaps · applied — "A sweep that reads the suite's own sources will find its own planted controls." Epic 04-01 hit this twice more — an include-flag literal sweep matched the prose explaining the rule, and a deleteById sweep needed comments stripped. Applied here to any source sweep story 3 or 4 needs: strip comments and strings first, and give the sweep a planted positive control in the same test.
