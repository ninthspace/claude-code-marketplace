# Coverage Gaps and the Integrity Badge

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-15  
**Status**: Complete  
**Blocked by**: —  
**Retro applied**: 53 · Patterns worth reusing · Applied — three declarations land this epic (`list_requirement`, `list_coverage`, `check_integrity`); each will fail every stand-in test as a surface mismatch until `recording_server.py`'s `DEFAULT_TOOLS` advertises it, and Tasks 1.2 and 3.1 expect that failure rather than reading it as a defect.  
**Retro applied**: 52 · Testing gaps · Applied — Task 2.3 exists only for this: the new palette entry is driven in `session.run`, which satisfies 48-06's two-way `COMMANDS` reconciliation and puts the gaps view inside FR10's whole-session proof (Story 4's first criterion).  
**Retro applied**: 49 · Codebase discoveries · Applied — Task 1.3 edits `dpm/skills/status/SKILL.md`, so `cd dpm && node --test` runs after it; the board's pytest suite cannot see the corpus sweeps that guard skill files.  
**Retro applied**: 49 · Testing gaps · Applied — Story 1's reconciliation parses the contract's `###` headings rather than searching its text, and the `dpm:status` disposition is keyed on the rule name rather than asserted by grepping the skill for words its own Phase 3b prose already contains.  
**Retro applied**: 50 · Testing gaps · Applied — Story 2's must-NOT needs a fixture holding both kinds of untraced requirement, one whose spec the Epics column holds and one whose it does not; asserted over a fixture where none resolves, it passes for a view that resolves nothing at all.

## Derive untraced requirements under the contract [plan]

**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR16, AD5, NFR5

**Acceptance Criteria**:

- The derivation returns exactly those requirements with no coverage row, over a fixture holding both traced and untraced requirements in one project [tdd] [unit]
- The rule is registered in `DERIVATIONS` under a name that exists as a `###` heading in `dpm/shared/status-model.md`, and the reconciliation passes in both directions [unit]
- `list_requirement` and `list_coverage` appear in the contract's Inputs table, and both are reached through `declare()` rather than as bare strings at a call site [unit]
- A read that comes back with `more` set is followed to the next offset rather than reported as the answer [unit]
- `dpm:status`'s Phase 3b is dispositioned against the new rule in `docs/maintenance/README.md`, saying whether the skill conforms, was amended, or deliberately differs [unit]
- must NOT call any tool whose name is a mutating verb, in any code path [unit]

### Add the rule to the derivation contract

**Task**: 1.1  
**Description**: Covers the second and third criteria — the `###` rule in `dpm/shared/status-model.md` and the two new rows in its Inputs table. The rule name is the reconciliation's key, so it is chosen here and every other artefact in this story refers to it rather than restating it.  
**Status**: Complete  
**Notes**: The rule is `untraced requirements`, placed between *progress counts* and *candidate ordering*. The paragraph counting the model's own derivations went from two to three — left at two it would have contradicted the rule below it. The truncated-read rule already in the preamble is not restated.

### Declare the two tools and write the derivation

**Task**: 1.2  
**Description**: Covers the first and fourth criteria. Both declarations go in `status_model.py` beside the other seven, because `SURFACE` is keyed on the tool name and a second `declare()` for the same name elsewhere would leave whichever module imported last.  
**Status**: Complete  
**Notes**: `untraced_requirements()` returns rows rather than ids — Story 2 needs each row's `label` and `spec_id`, and both arrive already. The fixture had no requirements and no coverage rows at all, so it gained three requirements and one coverage row: without the traced one, "returns the untraced ones" is satisfied by returning everything. The two untraced ones sit under different specs — one with epics, one without — which is the boundary Story 2's must-NOT needs and cannot assert over a fixture where every gap resolves or none does. `labelled()` joins `titled()` in the fixture support, because a requirement has no title.

### Disposition `dpm:status` against the new rule

**Task**: 1.3  
**Description**: Covers the fifth criterion. The skill's Phase 3b already reports Untraced from `list_requirement` and per-requirement `list_coverage` calls; this task reads it against the rule and records the disposition, amending the skill only where it contradicts the contract.  
**Status**: Complete  
**Notes**: Disposition is **conformed; the two shapes differ deliberately**. Phase 3b was read against the finished rule line by line and contradicts none of it — it was already deriving the rule before the contract stated it, in the contract's own words. `dpm/skills/status/SKILL.md` is therefore unchanged, which is what *amend only where it contradicts* asks for. The record carries the shape difference (scoped per requirement over one spec, versus unscoped and project-wide) so the next reader does not find two shapes and assume one is a bug.

### Write tests for Story 1

**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[tdd] [unit]`. The paging criterion needs a fixture whose requirement count exceeds one page — build it by lowering the bound rather than by seeding hundreds of rows, so it stays true as defaults change.  
**Status**: Complete  
**Notes**: Four new tests in `tests/test_coverage_gaps.py`, plus `REQUIRED` and the Inputs-call tuple in `tests/test_contract.py`. Two criteria are carried by tests that predate this story — the contract reconciliation and the mutating-verb sweep — and both read live registries this story's code joins (`DERIVATIONS`, `SURFACE`), so neither is restated. Mutation-checked: a derivation ignoring `coverage` fails two of the four; renaming the rule in the contract alone fails the reconciliation in both directions; the missing disposition row was observed failing four tests before Task 1.3 wrote it.

---

## Build the coverage-gaps view

**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR16, NFR2

**Acceptance Criteria**:

- `ctrl+g` and a palette entry both open a view listing every untraced requirement across registered projects [feature]
- Each row carries its project and the requirement's own label, and selecting one moves the cursor to that project [integration]
- A project with no untraced requirements contributes no rows, and an empty result renders as *no gaps* distinctly from *not read yet* [integration]
- A project whose server cannot start contributes no rows and does not stop the other projects' rows appearing [integration]
- must NOT resolve a row to a spec the Epics column does not hold — where there is no row to move to, the result carries its project and no document [unit]

### Build the screen and its results

**Task**: 2.1  
**Description**: Covers the first three criteria's rendering half. The search screen is the nearest existing shape — a modal over a fan-out across every registered project — and the empty state is the part it does not already answer.  
**Status**: Complete  
**Notes**: `Gap` in `board_view.py` mirrors `Result` field for field, because it is the same kind of answer; `resolve_gaps`, `gaps_project` and `gaps_projects` mirror the three search functions including both containment arms. `GapsScreen` differs from `SearchScreen` in one way that matters: with no query the read starts on mount, so `results` is `None` until it lands rather than `[]` — which is what lets a reader and a driver both tell *still reading* from *nothing to report*. `found()` now serves both screens rather than being copied.

### Add the binding, the `COMMANDS` row and the action in one edit

**Task**: 2.2  
**Description**: Covers the first criterion's reachability half. `COMMANDS` is the board's enumeration of what it can do and a test asserts every entry names a real action, so the row and the `action_*` are one edit or the epic ships a dead palette entry.  
**Status**: Complete  
**Notes**: `ctrl+g`, the `Coverage gaps` palette entry and `action_coverage_gaps` landed together. `ctrl+g` rather than a bare `g`: the single letters are FR8's working set and every one of them acts on the row under the cursor, which this does not.

### Drive the view in the session driver

**Task**: 2.3  
**Description**: Covers no criterion of its own and is not optional: 48-06's session driver reconciles what it ran against `COMMANDS` in both directions, so a new entry either gets driven in `session.run` or needs a reason written in `NOT_IN_A_SESSION`. Driving it is also what puts this path inside FR10's whole-session proof.  
**Status**: Complete  
**Notes**: Driven rather than excluded — `_coverage_gaps` presses `ctrl+g` and waits on `results is not None`, so the session provably made the two reads rather than provably opened a modal. `NOT_IN_A_SESSION` is unchanged.

### Write tests for Story 2

**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`, `[integration]` and `[unit]`. The containment case registers the failing project ahead of the healthy one, so a fan-out that stopped at the first failure returns nothing at all.  
**Status**: Complete  
**Notes**: Eleven tests in `tests/test_gaps_view.py`. **The retro-50 breadcrumb above was right about the risk and wrong about the mechanism**, and the correction is worth recording: the Epics column holds epics and a requirement names a spec, so no fixture can produce a gap that resolves — asserting `document is None` over real data passes equally for a correct membership test and for a hard-coded `None`. The must-NOT is therefore planted on both sides, with a `ProjectView` whose Epics column holds a row carrying the spec's own id. Both mutations were checked: writing the `spec_id` in unconditionally fails the first half, returning `None` always fails the second. The empty-state test gates the fan-out on an `asyncio.Event` so the pending state is observed rather than raced for, and `FULLY_TRACED` is a project built with its own content — the shared fixture cannot be gap-free without ceasing to be what it is for.

---

## Surface the integrity badge

**Story**: 3  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR17, NFR2

**Acceptance Criteria**:

- A project whose `check_integrity` reports violations shows a badge on its row carrying the count; a project reporting `ok` shows none [integration]
- The badge's marker is distinct from the `● live` pill and the `▸` ralph marker [unit]
- The badge's value comes from the `check_integrity` tool, asserted from the calls made [integration]
- A project whose check fails renders its FR11 state, and every other project still renders its badge [integration]

### Declare `check_integrity` and add it to the survey

**Task**: 3.1  
**Description**: Covers the first and third criteria. Reading it inside the per-project survey is what puts it behind the freshness cache; a read outside the survey would be uncached and would re-run on every repaint.  
**Status**: Complete  
**Notes**: `check_integrity` is the only declaration on the board that takes no arguments at all, and it is read through `pool.read` rather than `rows()` — it is not a `list_*` tool and dpm serves it unbounded on purpose. `violations()` carries no `@derivation`, which is the decision the epic's Notes record: one consumer, so a contract rule would fail the reconciliation from the other side. **The read surfaced a pre-existing defect in the shared fixture**: its non-gating decoy edge was `builds_on` between two epics, which register entry 6 admits only between two specs — so every project the board's suite reads was carrying an integrity violation. Changed to `supersedes`, which has `gates_work = 0` like `builds_on` and no restriction on its ends, so the decoy plays the same part in a project that is now clean.

### Render the badge on the project row

**Task**: 3.2  
**Description**: Covers the second criterion and the rendering half of the first. A row whose shape changed to hold a blank would put a gap in every clean project's row, so the badge is a suffix present only when there is one — the same rule the live pill follows.  
**Status**: Complete  
**Notes**: `⚠ integrity {n}` — a third marker, distinct from `●` and `▸`, with the word beside it for the reason the live pill has one. The count is always shown, unlike the pill's: one running session is ordinary and one integrity violation is not, so the number is the size of the problem rather than a detail beside it. An unreadable project carries no badge — a count beside an FR11 state would be a claim about a database nobody opened.

### Write tests for Story 3

**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The healthy row is the discriminator: a survey that reads a project and reports nothing of it passes every failure-side assertion.  
**Status**: Complete  
**Notes**: Seven tests in `tests/test_integrity_badge.py`, over projects built with a *real* violation — register entry 6, not an invented corruption. **Writing them changed the count.** The first version counted failed register entries, and the two-violation case exposed it: two bad edges break one invariant, so the badge read `1` for a project with two things to fix. It now counts rows, and the counting is split into a pure `violation_count(report)` so the orphan arm can be driven at all — dpm's write tools enforce the keys an orphan breaks, so no fixture can produce one. Mutation-checked: dropping the orphan term and reusing the `●` marker each fail exactly one test.

---

## Verify cross-story integration for coverage gaps and the integrity badge

**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 1, Story 2, Story 3  
**Satisfies**: FR10, FR13

**Acceptance Criteria**:

- A full board session that opens the gaps view and renders badges for every project leaves each project byte-identical [integration]
- Both new reads are served from the cache on a second survey within the freshness window, rather than reaching the server again [integration]

### Write integration tests for the epic

**Task**: 4.1  
**Description**: Covers both criteria. The first extends 48-06's whole-tree comparison over a session that definitely exercised both new paths; the second asserts the call counts across two surveys, which is the only thing that distinguishes a cached read from a fast one.  
**Status**: Complete  
**Notes**: Two tests in `tests/test_gaps_integration.py`. The FR10 comparison asserts `"coverage_gaps" in observed.ran` as its floor — without it, a comparison over a session that skipped the view would pass while proving nothing. **The second criterion's wording assumes all three reads are survey reads, and they are not**: `check_integrity` is inside the survey, and `list_requirement`/`list_coverage` are in the gaps fan-out, which is an action rather than part of a repaint. The criterion is about the wire, so both entry points are driven twice and every call is counted off one transcript; the invalidation half is asserted too, so a survey that cached nothing but was only ever called once cannot pass. Mutation-checked: making the integrity read `fresh=True` fails it.

---

## Notes

**FR16 and FR17 were deferred and are being built deliberately.** Spec 48 lists both under *Could
Have* and again under *Scope › Deferred* — "both cheap over the tool surface, neither needed for the
board to earn its place". The decision to build them was taken after 48-07 closed and is recorded
here rather than by editing the spec, which is `/cpm:pivot`'s to do. A reader who finds this epic
building deferred requirements is reading it correctly.

**FR16 is not one declaration over an existing surface, and the reason is AD5.** `dpm:status`'s
Phase 3b already reports **Untraced** — "no coverage rows at all" — from `list_requirement` and
per-requirement `list_coverage` calls. That gives the derivation the two consumers AD5 exists to
keep from drifting, so it needs a rule in `dpm/shared/status-model.md`, a registration in
`DERIVATIONS`, and a disposition. 48-03's reconciliation fails in both directions, so this is
enforced by tests that already exist rather than by anyone remembering.

**The board's derivation is deliberately not the skill's.** `dpm:status` scopes `list_coverage` by
`requirement_id`, once per requirement; the board reads coverage once, unscoped, and takes the set
difference. Both answer the same question and the contract's rule is what binds them — Task 1.3
records the difference as conformance rather than leaving the next reader to find two shapes and
assume one is wrong.

**FR17 takes no contract rule, and that is a decision rather than an omission.** No dpm skill calls
`check_integrity`, so the badge has one consumer. Registering a derivation with no rule fails the
same reconciliation from the other side, and a rule nothing else conforms to would be a contract
entry written for a single reader.

**Neither requirement has a row in the spec's Acceptance Criteria Coverage table**, so no test
approach was propagated and no must-NOT was inherited. Every criterion here is newly written and the
two must-NOTs were proposed rather than transcribed — the coverage matrix records this in the Spec
Test Approach column rather than leaving the blanks to read as an oversight.
