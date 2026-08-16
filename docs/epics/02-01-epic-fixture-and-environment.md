# Fixture and environment

**Number**: 02-01  
**Source spec**: 02  
**Status**: complete  
**Commit**: d018d5a  

## The host's Python floor, and why this run left it unverified

Story 2's sixth criterion — the host running the board has Python 3.11 or later, and `uv run` provisions the board from its inline block there — carries `target` and nothing else, so this run did not assess it and did not count it met. Confirming a floor of 3.11 on a machine running 3.11 is precisely the false pass the tag exists to stop, and no verdict from a development machine is worth anything about a host nobody here has.

What would settle it is one command on the deployment host: `uv run dpm/tools/board/board.py list` returning zero, on an interpreter the host provides. Until that runs there, the criterion stays open and its coverage row stays unmarked.

What this environment *could* settle was split off and is checked: the floor is stated twice — `requires-python` in `board.py`'s inline block and again in `pyproject.toml` — and `test_the_python_floor_is_stated_once_and_agrees_with_itself` asserts the two have not drifted, since `uv run board.py` reads the first and `uv run pytest` reads the second, and a disagreement provisions two different interpreters. That is a claim about what the board asks for, which is checkable here; the claim about what the host gives it is not.

## Story 1 — A fixture project holding every state

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The fixture builds, and holds at least one epic or story in each state the model defines — including `complete`, `superseded` and `withdrawn` — together with a document long enough to time a render against. `[integration]`
- must NOT — The fixture build writes anywhere outside the directory the test owns. `[integration]`

### Task 1 — Seed every state into the fixture builder

**Status**: complete  

Addresses the state-coverage half of the story's first criterion. The states are taken from the model's own vocabulary rather than a list written here, so a state added to the model later appears in the fixture without this task being revisited.

### Task 2 — Add a document long enough to time a render against

**Status**: complete  

Addresses the second half of the same criterion, and is what NFR1's 50 ms budget is measured on. Long enough that changing the render width changes the line breaks, since a document that fits on one line at any width measures nothing.

### Task 3 — Write tests for the fixture

**Status**: complete  

Covers both criteria tagged `integration`, including the must-NOT on where the build writes — which needs a sandbox the test owns and an assertion about what appeared in it, not merely that the expected file appeared.

### Retro

- The fixture this story was written to build already existed. `tests/support/fixture_database.py` had been carrying a shared project since the board's own epic 3, complete with `created`, `titles` and `titled` helpers whose docstrings say in as many words that a count written into a test is a transcription that goes stale as the fixture grows. So the story was an extension of a builder rather than a new one: four rows for the two statuses nothing reached, one long document section, and a `statuses` helper alongside the three that were already there. The suite's baseline also carried a failure nothing in this spec caused — `test_states.py` pointed at `docs/specifications/48-spec-dpm-board.md`, which the CPM-to-dpm migration parked under `docs/cpm/`, so the path was one folder out.

Recorded on the first story of the first epic, which is where the retro lesson about reading the tree first was applied. It paid immediately: the epic was planned from the spec and roughly half of what it named was already in the tree.

- Growing the shared fixture broke two tests, and the interesting one was the test that had already been written not to break. `test_client.py` held a literal `{"complete", "pending"}`, which is the transcription the fixture's helpers exist to prevent — an easy fix. `test_containment.py` had done the right thing and derived its expected figure from `CONTENT`, and it still broke, because it derived the wrong rule: it counted every story the fixture creates, while `progress` drops a retired story from both sides of the count. Deriving from the source data protects against the fixture growing; it does not protect against the derivation disagreeing with the production rule it is standing in for, and the second failure looks exactly like the board mis-counting.

Both were found by running the suite after the fixture grew, not by reading it. The pattern worth carrying is that a derived expectation needs the rule stated beside it, and the fixture is the place to reach a state that makes the two disagree.

## Story 2 — The environment this work rests on

**Status**: complete — Five criteria verified by test; the sixth is `target` — the host's Python floor — and is unverifiable in this environment. See the epic's section on it.  
**Blocked by**: —  

### Acceptance Criteria

- pytest and pytest-asyncio are present at or above the stated minimums, and the suite runs from `dpm/tools/board`. `[unit]`
- The dependency list in `pyproject.toml` and the PEP 723 inline block in `board.py` name the same packages. `[unit]`
- The markdown renderer imports, and neither dependency list has gained an entry for it. `[unit]`
- A socket opened during the suite raises and is recorded, so the run is known to have needed no network rather than assumed to have needed none. `[unit]`
- `board.py` imports nothing outside the standard library and the packages its own inline block declares. `[unit]`
- The host running the board has Python 3.11 or later, and `uv run` provisions the board from its inline block there. `[target]`

### Task 1 — Assert the runner, the dependency agreement and the import surface

**Status**: complete  

Addresses the four claims expected to hold already: the pytest and pytest-asyncio minimums, the agreement between `pyproject.toml` and the inline block, the network guard, and `board.py`'s import surface. Expect these to pass on the first run; the value is that they keep holding.

### Task 2 — Assert the markdown renderer imports with no new dependency

**Status**: complete  

Addresses the renderer criterion only, and is the one claim in this story not already true — nothing in the board imports Rich directly today. The assertion has two halves: the import succeeds, and neither dependency list gained an entry for it.

### Task 3 — State the host's Python floor and why it cannot be checked here

**Status**: complete  

Addresses the `target` criterion. Records the condition and what would settle it rather than self-assessing it on a machine that satisfies it — confirming a version floor where the floor is met is the false pass `target` exists to stop.

### Retro

- Task 2's description said "nothing in the board imports Rich directly today" and `board.py` line 40 reads `from rich.text import Text`. The task was written from the spec, and the spec was written about a renderer nobody had reached for yet; the board had been importing Rich for its own text styling since the TUI landed. This is the second time in one epic that a task planned from the spec described a tree that had moved on — and it cost nothing here only because the task's own criterion was checkable against the tree rather than against the description.

It also changed what the import-surface criterion can mean. Read literally — "nothing outside the standard library and the packages its own inline block declares" — `board.py` fails it today, because the block declares Textual and not Rich. The reading that holds is the one the renderer criterion forces two lines above it: what the block *provisions*, transitively. So the check resolves the closure of the declared distributions through `importlib.metadata.requires` rather than comparing against `{"textual"}`, which would have been a change detector green on the day it was written.

Two of this story's six criteria turned out to be already true, three needed a test written against code that was already correct, and one is `target`. The story's real product is that the four standing claims now have something holding them.

## Dependencies

- blocks → 02-02
- blocks → 02-04

## Retro Applied

- 02 · A criterion can read as the natural test of a rule and have no purchase on it · deferred — Autonomous run: testing gap, so deferred. Named here because story 1's fixture criterion is of that shape — the fixture building is not the same claim as the fixture holding every state — and a human re-planning it is the sanctioned response.
- 02 · A criterion warranted by an ADR carries no coverage rows and is invisible to the roll-up · deferred — Autonomous run: criteria gap, so deferred. It has already recurred in this spec — epic 2 story 5 carries three such criteria, recorded deliberately at breakdown — and the fix it points at is a change to the coverage model, which is nothing this run should decide.
- 02 · A must-NOT control needs one arm per code path that could reach the rejected behaviour · deferred — Autonomous run: testing gap, so deferred. It bears on story 1's must-NOT about where the fixture build writes, which has more than one way to be reached; a human should decide whether that criterion wants a second control arm before the epic is called done.
- 01 · A must-NOT stated as an equality is a change detector wearing a rejection's clothes · applied — Autonomous run: a pattern worth reusing, so applied. Story 2's ENVX2 criterion is about the import surface, which is exactly the shape that bit in retro 1 — it is stated over the category (standard library plus the inline block's own packages, everything else a relative path) rather than as an exact list.
- 01 · Check a control mutation compiles into the path it is aimed at before believing the red · deferred — Autonomous run: a testing gap implies a re-planning call that belongs to a human, so it is deferred rather than applied. The same discipline still binds this run through the library document scoped to do, which carries it as standing guidance — this row records that the retro lesson itself was not re-planned against.
- 01 · Read the tree before building; expect the ratio to favour already-there · applied — Autonomous run: codebase discoveries are additive and low-ambiguity, so this one is applied. It changes Step 1 of every task in this epic — the board already has 36 test files, a tests/support/fixture_database.py and a conftest carrying sandbox, netguard and built_fixture, so each criterion is checked against the tree before anything is written.
- 01 · Stubbed tests and a real one are not the same test at different fidelities · applied — Autonomous run: a pattern worth reusing, so applied. Story 1's fixture is the thing that makes the real end of that pair possible for this spec — its criteria are tagged integration precisely because a stubbed database would assert the contract and never that the board and the database are connected.
