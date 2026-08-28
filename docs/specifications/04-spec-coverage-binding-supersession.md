# Coverage binding supersession

**Number**: 04  
**Status**: complete  

## Problem recap

DPM's coverage model has one lifecycle state: a binding is sound, or it does not exist. Three real states have no home.

**A binding that became wrong.** `/dpm:pivot` rewrites a requirement's `text` and a bound `spec_fragment` is no longer a substring of it. The fragment is part of the natural key `(requirement_id, spec_fragment, story_criterion_id)`, so re-binding is correctly refused; `update_coverage` accepts `position` and `verified_at` only; there is no `delete_coverage` or `retire_coverage`, and `coverage` carries no `retired_at`, `archived_at` or status column. The row is immortal short of cascading from its requirement or its criterion, and integrity entry 9 reports it for as long as the project lives.

**A criterion an amendment falsified.** `story_criterion` has `id`, `story_id`, `text`, `polarity`, `position` and no status column, though `story` and `task` both have one. A criterion that was a true statement of what an epic delivered, and that a later amendment made wrong, can only be rewritten — which makes the epic's record claim it delivered a rule it did not, in order to tidy a matrix.

**A criterion that can never be bound.** Its warrant is an accepted ADR rather than requirement text, and `coverage.requirement_id` admits only a requirement. Such a criterion is written, tested and verified, and is invisible to the coverage roll-up — indistinguishable from one nobody got round to binding. Retro 02 found four instances across two epics and recorded the shape rather than acting on it, on the explicit grounds that the fix is a change to the coverage model. This spec is that change.

One sentence underneath all three: **`011-decay.sql` models a binding becoming *unproven*, and nothing models a binding becoming *wrong*, or a warrant the coverage graph cannot express.** Decay is right and is not what this is about — the triggers clearing `verified_at` when either bound text moves say *this binding is unproven*, which is a claim about evidence. What a pivot can also produce is *this binding is nonsense*, which is a claim about the binding itself, and there is no column for it.

**A contributing factor worth designing against.** `/dpm:epics` Step 3d refuses a fragment it cannot trace to spec text, but says nothing about which clause to quote. In the reported incident five of the six fragments a pivot broke were bound to connective wording — "The first is…", "the second is…", "or silently clamped to zero" — and every fragment quoted from the clause carrying the obligation survived the same rewrites untouched.

**One correction to the source report, because it changes what a fix has to touch.** The report states that a requirement with a broken row can never be claimed again, because `coverage_claimed_at` needs every row on the requirement verified. That gate does not exist at the tool layer: `claimComplete` writes whenever asked and never inspects `verified_at`. "A requirement whose rows are all verified" is prose in `dpm:do`, so it is a skill-wording question rather than a code one.

## Scope boundary

`check_integrity` on this repository is clean — fourteen entries checked, entry 9 holds, no orphans, no version skew. The change is preventive here, and the incident that prompted it happened in another project. That is worth stating before any breakdown, because nothing in this repository will demonstrate the bug and every test for it therefore has to construct the state.

## In scope

- Migration `025`. `coverage` is rebuilt: the retirement pair added, the `UNIQUE` table constraint replaced by a partial unique index over live rows, `coverage_story` rescued and restored around the rebuild, and six triggers dropped and recreated. `story_criterion` gains `superseded_at`, `superseded_reason` and `warrant_adr_id`.
- A `retire_coverage` tool, and supersession and warrant reachable through `update_story_criterion`.
- `claimHash` qualified to live rows; a fifth unclaim trigger watching `retired_at`; a trigger that retires the bindings of a criterion as it is superseded.
- Integrity: entry 9 narrowed to live bindings, and a new entry naming a binding retired while its fragment was still a substring and its criterion still live.
- `list.js`: `live: 'retired_at'` for `coverage`, and `include_superseded` for `story_criterion`, both derived from the column names.
- Skills: the retirement step in `dpm:pivot`, the fragment guidance in `dpm:epics` Step 3d, and the roll-up wording and warrant awareness in `dpm:do`.
- The derived sweeps, and the regenerated dump.

## Out of scope

- A `delete_coverage` tool, and un-retirement of anything. Both are ruled out by accepted decisions rather than by preference, and each decision records why.
- Binding a coverage row to an ADR with a verbatim fragment. Rejected on the null paths it opens through machinery that already works, and named in that decision as the thing to revisit if warrants go stale.
- Repairing broken rows in other projects. The tools ship; each project runs its own pivot.
- Any change to the three `coverage_unverify_*` decay triggers. Decay is correct, and the whole point of this spec is that decay and supersession are different states.

## Deferred

- Warrant decay — a quoted fragment of an accepted decision's text, expiring when that text is amended, exactly as a `spec_fragment` does. Deferred until warrants are observed going stale.
- Warrants that are not decisions: a discussion, an audit finding. That is the general `criterion_warrant` table, and it costs a new table before it does anything.

## Sequencing this implies

Everything waits on `025`. The rebuild is what forces the order, not the scope, so a breakdown that runs stories in parallel will discover it late. The two should-haves and the could-have are separable from the musts: if the rebuild proves worse than estimated, FR7 to FR9 come out and the spec still delivers what the report asked for.

## Integration boundaries

Six seams, drawn from the accepted decisions rather than from the file layout. Each is a place where two things have to agree and nothing forces them to.

**Schema and tool, on the retirement pair.** The paired `CHECK` enforces that a retirement carries a reason; `retire_coverage` offers the only supported way to write one. A tool that refuses while the schema permits is a hole, and it is the reason FR4 carries a tool arm and a schema arm rather than one criterion covering both.

**The trigger set and the claim hash.** `claimHash` selects the bound set with a `WHERE`; five triggers decide when the claim over that set is withdrawn. The contract is that the set the hash reads and the set the triggers watch are the same set — a binding leaving by retirement has to move both — and the two live in different files with nothing but this boundary holding them level.

**A column name and its derived flag.** `includeFlag` derives `include_retired` and `include_superseded` from the column names, while `list.js`'s `live` entry declares which column carries liveness. Two mechanisms reading two different things, which is what makes a table that forgot its declaration *fail* rather than quietly exclude itself from its own check.

**Supersession and retirement.** The one path where a retirement is written by the schema rather than by a caller. The contract is that a reason the trigger composes satisfies exactly the constraint a caller's reason satisfies — the same rule, with nobody there to be told they missed an argument.

**The skill and the tools.** The pivot calls `list_coverage`, performs the substring comparison itself, and calls `retire_coverage` once per approval. Neither side infers the other's work: the server never scans for broken bindings, and the skill never writes a column. That division is what keeps the skill's gate meaningful — a server that retired on its own would make the gate decorative.

**The migration path and the create path.** One set of numbered files with two entry points, asserted identical object for object. Every migration has relied on that assertion; this is the first that rebuilds `coverage`, which is where it earns its keep.

## Reconciliation against the constraints

The approaches assigned are `unit`, `integration`, `feature`, `manual` and `target`. ENV1 supplies the runner and the SQLite binding that every automated criterion needs; ENV2 supplies the in-process scratch database that every `integration` criterion stands up. `feature` here means a driven skill run, which needs nothing beyond those two — the existing pivot suite drives one already. No criterion was tagged `tdd`, so no constraint about a fast red-green loop is implied. Nothing returned to Step 3a.

## Testing strategy

The tagged criteria are rows under their requirements; what follows is the shape they took and the two habits that decided it.

**One control arm per path the rejected behaviour could take, not one per criterion.** Retro 02 found this twice in one epic: a must-NOT control survived its own mutation because the code path it drove returned before reaching the line being rejected. Two criteria here carry the consequence directly. FR4 splits into a tool arm and a schema arm, because a retirement without a reason can be written by a caller or by a direct update and refusing one proves nothing about the other. FR6a carries a control of its own for the supersession-driven retirement, which is the single path where no caller supplies the reason and a tool-only test would never reach it.

**A control that separates "the thing worked" from "the check stopped looking".** Almost every group here carries one, and they are not decoration. Entry 9 going quiet after a retirement is equally consistent with an entry that reads nothing, so a second broken binding stays live beside it. A claim surviving a migration is equally consistent with claims that are never cleared, so a retired binding is shown to clear one. A pivot naming no broken bindings is equally consistent with a step that never ran, so a run whose fragments all survive is driven alongside. The byte-identical control on FR6 is the one the existing decay suite already uses, and it exists because a trigger that fired is indistinguishable from a trigger that fires on every write.

**The partial index has a control the ordinary tests would miss.** NFR3 asserts that two *retired* bindings on one triple can coexist — retire, re-create, retire again. A `UNIQUE` somebody moved rather than qualified passes every other criterion in that group.

## Where each approach is used

`integration` carries most of it: the schema, the triggers, the claim arithmetic and the tools all need a database, and ENV2's in-process scratch database is what stands one up. `unit` covers the sweeps that read declarations and source text rather than rows — the tool surface, the prose-column classification, the derived flags, and the skill files. `feature` covers the four driven skill criteria, following the existing pivot suite, which drives a run and approves one proposal of two so that a batch would land both. `manual` covers ENV3 alone, because reinstalling a plugin is not something the suite can drive. `target` covers ENV4 and ENVX3, which are claims about a host nobody here has.

`tdd` is unused, and that is a statement rather than an omission: nothing in this spec is a red-green loop over logic being discovered. The work is a schema change, a tool, and the queries that read them.

## Functional Requirements

### FR1 (must)

A coverage binding can be retired, carrying the reason it was retired, and a retired binding stays readable as the record that the binding once existed. Retirement is not deletion: the row is not removed, and what changes is that the binding is no longer offered as live.

- retire_coverage sets retired_at and retired_reason together on a live binding, and read_coverage on that id returns both. `[integration]`
- list_coverage omits a retired binding by default and returns it when include_retired is passed. `[integration]`
- must NOT — update_coverage does not set retired_at or retired_reason. Retirement is its own tool, as it is for every other retirable thing in the surface. `[unit]`
- control — update_coverage still sets position and verified_at on the same row, so the refusal above is specific to the retirement columns rather than a tool that updates nothing. `[unit]`
- must NOT — No tool in the registered surface deletes a coverage row. `[unit]`

### FR2 (must)

A binding whose fragment its requirement no longer contains is reported while it remains unretired, and stops being reported once it has been knowingly retired. The integrity register goes on naming the bindings somebody still has to decide about, and stops naming the ones somebody already decided.

- A binding whose fragment its requirement no longer contains is named by integrity entry 9 while that binding is live. `[integration]`
- Retiring that same binding removes it from entry 9, which then reports held true, with nothing else in the database changed. `[integration]`
- must NOT — Entry 9 does not name a retired binding whose fragment is still a substring of its requirement. `[integration]`
- control — A second live binding, broken in the same requirement, is still named after the first is retired, so entry 9 going quiet is the retirement rather than the entry ceasing to look. `[integration]`

### FR3 (must)

A retired binding leaves the set that a completeness claim accounts for, and a claim standing over that set at the moment of retirement is withdrawn. A requirement whose bindings have changed shape is one whose claim has to be made again over what remains.

- Retiring one of three bindings on a claimed requirement clears coverage_claimed_at and coverage_claim_hash together. `[integration]`
- A claim made after the retirement hashes over the remaining bindings only, and claimState reports that claim current. `[integration]`
- must NOT — A retired binding does not count toward the bound total claimState reports. `[integration]`
- control — Retiring a binding on one requirement leaves another requirement's standing claim intact, so the withdrawal is scoped rather than a trigger that unclaims everything. `[integration]`
- control — A live binding on the same requirement still counts toward the bound total, so the exclusion above is the retirement rather than a count that returns zero. `[integration]`

### FR4 (must)

A retirement without a stated reason is refused, so a binding leaving the matrix is a decision on the record rather than a tidy-up. "The pivot deleted the clause this quoted" and "this criterion was superseded by epic 4" are the same column and different facts, and only a reason separates them.

- retire_coverage called with no reason is refused, and the row is unchanged afterwards. `[integration]`
- That refusal is a boundary rejection naming the missing argument, rather than an internal error surfacing from the schema. `[unit]`
- must NOT — A row must not exist with retired_at set and retired_reason null, whatever writes it. The tool is one path to that state and a direct write is another. `[integration]`
- control — retire_coverage with a reason succeeds on the same binding, so the refusals above are the missing reason rather than a tool that refuses everything. `[integration]`

### FR5 (must)

The pivot names the bindings its own amendment broke, at the point of the edit, and gates the retirement of each one separately. The knowledge is there and nowhere else: the skill holds the text before and the text after, so a silent future integrity failure becomes a decision made by the person doing the amending.

- A pivot run amending a requirement's text names every binding whose fragment the amended text no longer contains, and names no others. `[feature]`
- Each named binding is offered under its own approval: a run that approves one of two retires that one. `[feature]`
- must NOT — The pivot does not retire a binding the run did not approve. `[feature]`
- control — A run amending a requirement whose bound fragments all survive names no binding and offers no retirement, so naming nothing is the amendment rather than a step that never ran. `[feature]`
- must NOT — The pivot does not recover the bindings by reading a generated markdown file instead of calling the list tool. `[unit]`

### FR6 (must)

A story criterion an amendment has overtaken can be marked superseded rather than rewritten, so the epic goes on recording what it actually delivered. Rewriting the text to match an amended requirement makes the epic claim it delivered a rule it did not, and that trade must not be the only option on offer.

- update_story_criterion sets superseded_at and superseded_reason together, and the criterion's own text is unchanged by that call. `[integration]`
- list_story_criterion omits a superseded criterion by default and returns it when include_superseded is passed. `[integration]`
- must NOT — A row must not exist with superseded_at set and superseded_reason null. `[integration]`
- must NOT — Superseding a criterion must not clear the verification of bindings on other criteria of the same story. `[integration]`
- control — The same call passing the criterion's text back byte-identical leaves its bindings' verification standing, so a cleared mark is the supersession rather than a trigger firing on any write. `[integration]`

### FR6a (must)

A superseded criterion's bindings stop counting toward its requirement's coverage without the rows being destroyed. The criterion and the bindings that hang off it go quiet together, because a binding to a criterion nobody is claiming any more is a binding that accounts for nothing.

- Superseding a criterion retires every binding hanging off it, each carrying a reason that names the supersession. `[integration]`
- Those bindings are still readable under include_retired, with their spec_fragment intact. `[integration]`
- must NOT — A superseded criterion's bindings must not remain in the set a completeness claim hashes over, so a requirement claimed before the supersession is unclaimed by it. `[integration]`
- control — Bindings on a live criterion of the same story are untouched, so the retirement follows the criterion rather than the story. `[integration]`
- control — The supersession-driven retirement satisfies the paired-reason constraint, which is the one retirement path where no caller supplies the reason. `[integration]`

### FR7 (should)

A story criterion whose warrant is an accepted decision rather than requirement text is traceable, and the roll-up separates it from a criterion nobody bound. A decision constrains a story exactly as a requirement does, and a criterion that is written, tested and verified must not read as an unbound gap because the only anchor the coverage graph offers is a requirement.

- update_story_criterion sets warrant_adr_id, and refuses an id that does not name an accepted decision. `[integration]`
- The roll-up reads a criterion carrying a warrant and no binding as accounted for, and one carrying neither as unbound. `[integration]`
- must NOT — A criterion carrying a warrant must not be reported as an unbound gap. `[integration]`
- control — A criterion carrying neither a warrant nor a live binding is reported as an unbound gap, so the exemption above is the warrant rather than the report going quiet. `[integration]`
- control — A criterion carrying both a warrant and a live binding still counts its binding, so a warrant does not substitute for a binding where requirement text exists to quote. `[integration]`

### FR8 (should)

The breakdown steers a fragment toward the clause carrying the obligation rather than the connective wording around it. Connective phrasing is what an amendment rewrites while the obligation stays put, so a fragment quoted from it is the one most likely to be broken by an edit that changed nothing the criterion was about.

- The breakdown skill's coverage step instructs that a fragment be quoted from the clause carrying the obligation, and says why connective phrasing is the fragment an amendment breaks. `[unit]`
- must NOT — That instruction must not weaken the existing refusal of a fragment traceable to no spec text. `[unit]`
- A breakdown run over a requirement whose obligation and connective wording are separable binds the obligation clause. `[feature]`

### FR9 (could)

The execution roll-up says whether a requirement's remaining bindings are verified, rather than implying every binding ever made was. A count taken over a set that has had rows retired out of it describes what is left, and the sentence reporting it says so.

- The execution roll-up's sentence names the remaining bindings rather than implying every binding ever made was verified. `[unit]`
- must NOT — The roll-up must not report a count that includes retired bindings. `[integration]`

## Non-Functional Requirements

### NFR1 (must)

Every coverage row and story criterion in an existing database migrates live and untouched, so a project with no broken bindings sees no change in what is reported, counted or claimed.

- A database at the previous schema version, holding coverage rows and story criteria, migrates with every one of them live: retired_at and superseded_at are null throughout. `[integration]`
- The claim hash over a requirement with no retired bindings returns the same digest before and after the migration, so every standing claim survives it. `[integration]`
- must NOT — Migrating must not drop a coverage_story row, an index or a trigger. `[integration]`
- must NOT — A migrated schema and a freshly created one must not differ, object for object. `[integration]`
- control — A coverage_story row present before the rebuild is present after it, carrying the same pair, so the rescue put back what it took aside. `[integration]`

### NFR2 (must)

Where the change alters what a completeness claim is computed over, the resulting invalidation of every existing claim is stated in the release rather than discovered in the first project to migrate. A cost taken deliberately and written down is a different thing from the same cost met by surprise.

- The migration file states what the claim hash now excludes, and states that no existing claim is invalidated by it because no row is retired at migration time. `[unit]`
- must NOT — No project is required to re-make a claim it had already made, as a consequence of this change. `[integration]`
- control — A requirement with a retired binding is unclaimed, so claims surviving a migration is the migration leaving them alone rather than claims never being cleared at all. `[integration]`

### NFR3 (must)

A binding retired in error can be put right without destroying its requirement or its criterion, and the natural key must not make a mistaken retirement permanent. A retired row still occupies its triple, so nothing may leave a project unable to re-create a binding it retired by accident.

- After retiring a binding, create_coverage with the same requirement, fragment and criterion succeeds and yields a live row. `[integration]`
- The retired row and its live replacement coexist, and only the live one counts toward the bound total. `[integration]`
- must NOT — Two live bindings on the same triple must not exist: creating a second while the first is live is still refused. `[integration]`
- control — Two retired bindings on the same triple can exist — retire, re-create, retire again — so the index constrains live rows rather than the table. `[integration]`
- must NOT — Recovering from a mistaken retirement must not require destroying the requirement or the criterion the binding hangs between. `[integration]`

### NFR4 (should)

New columns follow the shapes this schema already carries, rather than a third spelling of either: the retired_at and retired_reason pair as on artifact and observation, and the status and status_note pair as on story and task.

- The retirement columns on coverage carry the same paired CHECK that artifact and observation carry, read from the live schema rather than transcribed into the test. `[integration]`
- The supersession column on story_criterion yields an include_superseded flag and the retirement column on coverage yields an include_retired flag, both derived from the column name rather than declared. `[unit]`
- must NOT — No column this change adds introduces a third spelling of retirement or of supersession. `[integration]`

### NFR5 (should)

Every TEXT column and every tool this change adds is judged by the derived sweeps before release rather than exempted from them. The sweeps are not discoverable from a migration file, so the budget for a schema change includes a second pass through them.

- Every TEXT column this change adds carries a prose-columns classification, reconciled in both directions so a column added later fails until judged and an entry for a column the schema no longer has fails too. `[unit]`
- The retirement tool is registered and reached by the parity sweeps without an exemption. `[unit]`
- must NOT — No column or tool this change adds is exempted from a derived sweep. `[unit]`

## Environmental Requirements

### ENV1 (must)

Node.js 22.5.0 or later is available on the development machine, providing the DatabaseSync class of node:sqlite and the node --test runner.

- The suite runs to completion on Node 22.5.0 or later using node --test, with DatabaseSync imported from node:sqlite. `[integration]`

### ENV2 (must)

A scratch database can be created and migrated in-process from the numbered schema files, so migration behaviour is testable without writing to the project's own planning database.

- A test creates a database at the previous schema version and migrates it in-process, without opening the project's own planning database. `[integration]`

### ENV3 (must)

The dpm plugin can be reinstalled from this working tree once the schema version bumps. The MCP server is always the installed plugin, so a project database migrated past the installed release's target is served read-only until that reinstall happens.

- After the schema version bumps, reinstalling the plugin from this working tree restores write access to this project's database, which the integrity report describes as skew until it happens. `[manual]`

### ENV4 (must)

A project database at the current schema version upgrades to the next on first start after the release, in one transaction, on a host where only the SQLite built into Node is present.

- A project database at the previous schema version reaches the new one on first start, in a single transaction, with no SQLite beyond the one built into Node. `[target]`

## Environmental Restrictions

### ENVX1 (must)

A third-party test runner, assertion library, migration tool or SQLite binary must not be required. dpm ships no dependencies and no devDependencies, and a contributor installs nothing to run the suite.

- must NOT — The suite runs with no dependencies and no devDependencies installed, and the manifest declares none. `[integration]`

### ENVX2 (must)

The project's own planning database must not be required to be writable while the suite runs. Every test that needs a database builds a scratch one.

- must NOT — No test in the suite opens the project's own planning database for writing. `[integration]`

### ENVX3 (must)

A project must not be required to run a command, edit a file, or repair its data by hand in order to migrate. The upgrade is what the server does on starting, or it has not been delivered.

- must NOT — Migrating must not require a project to run a command, edit a file or repair a row by hand. `[target]`

## Architecture Decisions

### 04-01 — How a coverage binding leaves the live set

**Decision status**: accepted  

A coverage binding leaves the live set by retirement — a retired_at and retired_reason pair set by a retire_coverage tool — and never by deletion, so the record that the binding once existed survives it.

#### Retirement pair and a retire_coverage tool — chosen

retired_at and retired_reason, paired by a CHECK, exactly as artifact carries them since 019 and observation before it, set by a retire_coverage tool rather than by update. The row stays readable, so a reader asking why a requirement's coverage changed shape mid-project has an answer. It is also the only option compatible with FR1 as written.

| Axis | Assessment |
| --- | --- |
| consistency | Matches the retirement pair artifact and observation already carry, so nothing new has to be learned. |
| history | Kept. The row and its reason stay readable, so why a requirement's coverage changed shape is answerable later. |

#### A delete_coverage tool

The simplest thing that clears the row, and deleteById already exists in tools/crud.js wired only to delete_session. requirement_unclaim_on_coverage_delete already fires on it, so the claim behaviour would come free. Rejected because it destroys the record that the binding existed, which FR1 requires be kept, and because a delete tool over a spine table is a much wider capability than the problem needs.

| Axis | Assessment |
| --- | --- |
| cost | Lowest of the three. deleteById exists and the unclaim-on-delete trigger already fires. |
| history | Lost. Nothing afterwards can say the binding existed, which is the question a shifting matrix raises. |

#### A status column matching story and task

status and status_note as 020 gave them to story and task. Rejected because that vocabulary is about work progress — pending, complete, superseded, withdrawn — and a binding does not progress. Borrowing it would put two unrelated meanings on one column name and make a query over statuses answer a question nobody asked.

| Axis | Assessment |
| --- | --- |
| consistency | Superficially matching and semantically wrong: the status vocabulary describes work progressing, and a binding does not progress. |

### 04-02 — How a mistaken retirement is undone

**Decision status**: accepted  

Retirement frees the natural key: coverage is rebuilt with its UNIQUE table constraint replaced by a partial unique index over live rows only, so re-binding a retired triple is an ordinary create rather than a special verb.

#### Free the triple with a partial unique index — chosen

Rebuild coverage, replacing the UNIQUE table constraint with a unique index over the same three columns qualified WHERE retired_at IS NULL. A retired row keeps its triple in the table and releases it in the index, so re-binding is create_coverage and nothing else. The shape is already in this schema — 017 creates observation_retro_position as a partial unique index, and its comment records that partial indexes were first documented against coverage.

| Axis | Assessment |
| --- | --- |
| cost | Highest. A table rebuild: coverage_story rescued and restored, and six triggers dropped and recreated because two of them mention coverage in bodies that the RENAME reparses. |
| precedent | Already set twice. 017 and 020 both rebuild tables, and 017 creates a partial unique index of exactly this shape. |
| reversibility | Full. A retirement made in error is undone by creating the binding again, through the tool that made it in the first place. |

#### An unretire_coverage tool

ALTER TABLE ADD COLUMN twice and one more verb that clears the pair. Materially cheaper, and no rebuild. Rejected because dpm has no un-retirement anywhere — agent, dependency_kind, taxonomy, test_approach and artifact all retire one way — so it introduces a precedent, and because it makes restoring a binding a special act while creating one is ordinary. The asymmetry is what a reader would have to learn.

| Axis | Assessment |
| --- | --- |
| cost | Two ADD COLUMNs and one verb. No rebuild, no trigger work, no index change. |
| precedent | New. Five retirable things in dpm and not one of them can be un-retired; this would be the first. |

#### Both the index and an un-retire verb

The partial index for re-binding, plus un-retirement for a caller who wants the original row back with its history rather than a new one beside it. Rejected as more surface than the problem carries: two ways to reach one state, and a caller with no rule for choosing between them.

| Axis | Assessment |
| --- | --- |
| complexity | Two routes to one state, with nothing telling a caller which to take. |

### 04-03 — Whether a sound binding may be retired

**Decision status**: accepted  

Any binding may be retired with a stated reason, and the integrity register names a retirement whose fragment was still sound and whose criterion is still live — reported rather than refused, which is how the register already treats a broken binding.

#### Unconditional, and reported — chosen

Retirement is always available, and the integrity register gains an entry naming a retired binding whose fragment was a substring of its requirement and whose criterion was not superseded. That is the only option that both admits the legitimate reasons nobody enumerated and leaves something able to notice an illegitimate one — a stated reason is checkable by nothing, because a person writes any string they like. It is also the house style: entry 9 reports a broken binding rather than the create tool refusing to make one.

| Axis | Assessment |
| --- | --- |
| cost | One more register entry beside the one FR2 already changes. No refusal path and no enumeration to maintain. |
| observability | An unwarranted retirement is named by the register. Nothing else in the three options can see one. |

#### Unconditional, reason only

Any binding retires with a stated reason and nothing examines the warrant. Smallest surface, and rejected because it makes retirement a way to leave a requirement looking well covered by removing the rows that were inconvenient, with nothing anywhere that would ever say so.

| Axis | Assessment |
| --- | --- |
| observability | None. A reason is a free string and no query can tell a good one from a convenient one. |

#### Warranted only

The tool refuses unless the fragment is no longer a substring of its requirement or its criterion is superseded. Fails closed, which is this project's instinct elsewhere. Rejected because it enumerates the legitimate reasons in advance — a fragment bound to the wrong criterion, a duplicate binding, a restructured spec — and every reason left out recreates the immortal row this spec exists to remove, one layer up.

| Axis | Assessment |
| --- | --- |
| completeness | Partial by construction. Every legitimate reason left out of the enumeration becomes a binding nothing can retire. |
| reversibility | Low. Widening the enumeration later is a schema or handler change; a register entry is a query. |

### 04-04 — How an overtaken story criterion is marked, and what becomes of its bindings

**Decision status**: accepted  

A story criterion an amendment has overtaken carries superseded_at and superseded_reason, following the word 018 chose for document_section, and a trigger retires the bindings hanging off it so that one column answers whether a binding counts.

#### superseded_at and superseded_reason, bindings retired by trigger — chosen

018 settled the word for exactly this meaning — a statement folded into something that now says it better, rather than something spent or out of the working set — and includeFlag derives include_superseded from the column name with nothing further to declare. Paired with a reason, unlike 018, because that file left its column unpaired on the grounds that the reconciled body is the reason and is a row; nothing here points at what superseded a criterion, so the sentence has nowhere else to live. The bindings are retired by trigger so that whether a binding counts is answered by one column in every query that asks — the same column FR1 already requires.

| Axis | Assessment |
| --- | --- |
| complexity | One condition for every reader, at the price of one fact held in two places. |
| consistency | Uses 018's word for 018's meaning, and inherits its opt-out flag from the column name. |

#### status and status_note, matching story and task

020 rebuilt story and task to carry this pair, so a criterion could have it too. Rejected for the reason a status column was rejected on coverage: the enum is about work progressing — pending, complete, superseded, withdrawn — and two of its four values say nothing about a criterion. Whether a criterion is met is coverage.verified_at, not a status, and putting a second answer beside it invites the two to disagree.

| Axis | Assessment |
| --- | --- |
| consistency | Matches two tables and contradicts the reasoning that kept the same column off a third. |

#### A superseded_by pointer to the replacement

Names the criterion that took over, which is richer than a sentence and queryable. Rejected because an amendment that narrows a rule usually overtakes a criterion without replacing it — the tolerance band in the reported incident made a criterion wrong and put no new criterion in its place — so the column would be null in the common case and the reason would still have to be written somewhere.

| Axis | Assessment |
| --- | --- |
| completeness | Null in the common case, because a narrowing amendment overtakes a criterion without replacing it. |

#### superseded_at, with a join condition rather than a trigger

The criterion's own column stays the single source of truth, and every place that counts a binding joins through to it. Rejected on the count: claimHash, claimState, integrity entry 9, list_coverage, the coverage-matrix projection and the execution roll-up all ask whether a binding counts, and a condition omitted from any one of them produces a silently wrong number rather than an error. The duplication a trigger introduces is repairable — the previous decision made re-binding an ordinary create — and a forgotten WHERE is not.

| Axis | Assessment |
| --- | --- |
| complexity | No duplicated fact, and no view in this schema to hold the two conditions in one place. |
| correctness | Six readers must each remember the join; one that forgets returns a wrong count and no error. |

### 04-05 — Where the integrity register draws the line on a broken binding

**Decision status**: accepted  

Entry 9 narrows to live bindings, and a separate entry names a binding retired while its fragment was still a substring and its criterion still live — two entries, because they ask a reader for two different things. The second entry is **advisory**: it is reported and it never blocks a restore. That distinction is new to the register, which until now held one class of entry, every member of which refuses a dump holding it.

#### Why the second entry has to be advisory

Every one of the register's thirteen entries names a state that should not exist. `restore` relies on that: it runs `checkIntegrity` inside the transaction and throws on any violation (`src/restore/index.js:108`), and `tests/restore.test.js` asserts the property in both directions — a fixture per entry, each refused on restore and each naming its rows, plus a parity test that a fixture with no entry and an entry with no fixture are the same gap.

A binding retired while it was still sound is not that kind of state. It is a decision somebody made, carrying the reason they made it, and epic 04-03's supersession trigger produces retirements routinely. An entry naming it under the existing rules would make a project's own dump un-restorable the first time anyone retired a binding deliberately — the register would be reporting a legitimate row as corruption, and the report would arrive as a refusal one layer over.

So the register grows a second class. An advisory entry is checked, reported and located exactly as the others are; what it does not do is stop a restore. The property belongs on the entry rather than on the restore path, because `restore` asking "is this entry number 14?" would be the decision written a second time, in the module least likely to be read when a fifteenth entry is added.

**What this does not decide.** Whether `check_integrity`'s own report separates the two classes for a human reader — a section, a count, a differently worded verdict — is left open. The property makes that possible and does not require it, and nothing downstream of this decision reads the report that way today.

#### Narrow entry 9, add a second entry — chosen

Entry 9 keeps its invariant and gains a live-rows qualifier, so it goes on naming exactly the bindings somebody still has to decide about. A separate entry names the other case — a binding retired while its fragment was still a substring and its criterion still live. Two entries because they ask the reader for two different things: the first is work outstanding, the second is a judgement to look at. One entry answering both would report a decision somebody already made alongside one nobody has.

| Axis | Assessment |
| --- | --- |
| signal | Each entry fails only when its own reader has something to do, so neither trains anyone to skip it. |

#### One entry with a column saying which

Entry 9 keeps both cases and each row carries whether it was retired. Fewer entries in the register. Rejected because an entry is the unit a reader acts on, and an entry that fails when nothing is wrong — a knowingly retired binding — trains people to read past it, which costs the entry its other half.

| Axis | Assessment |
| --- | --- |
| signal | One entry fails on a settled decision as well as an open one, and a reader learns to read past both. |

### 04-06 — How a criterion warranted by a decision becomes traceable

**Decision status**: accepted  

A story criterion carries a nullable warrant_adr_id naming the accepted decision that warrants it, so the roll-up reads a criterion as accounted for when it has either a live binding or a warrant, and as unbound only when it has neither.

#### warrant_adr_id on story_criterion — chosen

One nullable column with a foreign key into adr, placed on the criterion rather than on the binding. coverage is untouched, so claimHash, the unclaim triggers, claimState and entry 9 all keep their non-null requirement_id and need no null path. The roll-up gets its distinction from one condition: a criterion with no live binding and no warrant is unbound, and one with a warrant is accounted for. It gives up the verbatim-fragment discipline for such a criterion, which is the deliberate trade — a criterion warranted by a decision is proved by its tests, and FR7 asks for traceability and separation rather than for a second verification surface.

| Axis | Assessment |
| --- | --- |
| cost | One nullable column and one condition in the roll-up. No table rebuilt, no trigger touched. |
| rigour | Lower than a binding. No quoted fragment and no verification mark, so nothing detects a warrant naming a decision that no longer says what the criterion assumes. |

#### A nullable adr_id on coverage

A second anchor beside requirement_id with a CHECK that exactly one is set, so a fragment of adr.decision binds and verifies like any other row. Keeps the fragment discipline, and the marginal schema cost is near zero because coverage is being rebuilt anyway. Rejected on the surface it opens rather than the schema: claimHash, the four unclaim triggers, claimState.bound and entry 9's substring check are every one written against a non-null requirement_id, and each would need a null path — a large change to the machinery that already works, in service of a should-have.

| Axis | Assessment |
| --- | --- |
| complexity | A null path through claimHash, four unclaim triggers, claimState and entry 9 — the machinery that already works. |
| rigour | Highest. The fragment decays with the decision's text exactly as it does with a requirement's. |

#### dpm:spec emits a requirement when a decision constrains a story

One of the two candidates retro 02 named, and the only one needing no schema change at all. Rejected because it copies the decision's text into a requirement, leaving one fact in two rows with nothing keeping them equal — the shape this schema removes wherever it finds it, and the reason review carries no reviewed_id beside its parent_id.

| Axis | Assessment |
| --- | --- |
| cost | Nil in schema, paid in duplication: the decision's text in two rows nothing keeps equal. |

#### A criterion_warrant table

A join binding a story criterion to any document, with a fragment, so a warrant could be a decision, a discussion or an audit finding. The most general answer and the one that would not need revisiting. Rejected as premature: a new table costs five derived-sweep registrations before it does anything, and the only warrant anybody has produced in this corpus is an accepted decision.

| Axis | Assessment |
| --- | --- |
| cost | A new table, which retro 02 measured at five derived-sweep registrations before it does anything. |
| generality | Highest, and unused: the only warrant this corpus has produced is an accepted decision. |
