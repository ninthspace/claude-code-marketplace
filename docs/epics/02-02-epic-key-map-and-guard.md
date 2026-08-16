# The key map and its guard

**Number**: 02-02  
**Source spec**: 02  
**Status**: pending  

## Story 1 — CPM's key meanings restored

**Status**: complete  
**Blocked by**: Story 5, Story 6  

### Acceptance Criteria

- Driving a running board: `r` re-reads every registered project, `R` empties the cache, `a` opens the register picker, and `x` unregisters the highlighted project. `[feature]`
- Refresh and unregister are reachable by key, not only through the command palette as they are today. `[feature]`
- must NOT — No key the CPM board binds does something different on the DPM board. `[integration]`

### Task 1 — Rebind r, R, a and x to CPM's meanings

**Status**: complete  

Addresses the first two criteria. `R` takes clear-cache back from the forced re-read, which moves in story 3; `r` and `x` are new bindings rather than moved ones, because refresh and unregister exist on this board today as palette entries with no key.

### Task 2 — Write tests for CPM's key meanings restored

**Status**: complete  

Covers the criteria tagged `feature` and `integration`. The rejection is the cross-board one, so it uses story 5's reader — which means this task lands its full weight only once story 5 exists.

### Retro

- The parity rejection needed a translation table before it could say anything, and that is the finding worth carrying into story 5. The two boards name the same capability differently — `add_project` here is `register` there, `remove_project` is `unregister`, `copy` is `copy_command`, `open_plain` is `open` — so a check comparing raw action names reports four disagreements that are only spellings, and goes on reporting them after somebody fixes the real ones, until nobody reads the output. `tests/support/key_maps.py` therefore carries a `SAME_MEANING` map, and the comparison is over the *intersection* of the two maps rather than an equality between them, which is also what story 5's own must-NOT asks for.

Three of this board's keys had to give way, and one piece of reasoning had to be overruled rather than reconciled: this board bound `R` to the forced re-read on the argument that a shifted key is the deliberate one and an unshifted `r` would spawn a dozen servers on a typo. The CPM board binds `r` to refresh and `R` to clear-cache. The reasoning is good and it loses, because agreement between the two boards is the thing being asked for and a board deciding for itself which key is the careful one is exactly how they came apart. The forced re-read is now unbound until story 3 gives it `ctrl+r`, so `test_cache.py` drives it by action for one story.

## Story 2 — Hide retired work

**Status**: complete  
**Blocked by**: Story 6  

### Acceptance Criteria

- A board opened over a project holding complete, superseded, withdrawn and live rows shows only the live ones; `z` reveals all four groups; `z` again returns to the first state. `[feature]`
- Each press says which way it went, so a board that was already showing everything is distinguishable from one that has just been told to. `[feature]`
- must NOT — No row in a live state — ready, in progress, blocked or pending — is removed by the filter, with one case per live state rather than one case for the set. `[unit]`
- control — With the filter widened to hide a live state, the case above fails and names the state it lost — so a filter that removed nothing at all could not pass it. `[unit]`

### Task 1 — Add the retired filter over the model's own grouping

**Status**: complete  

Reads `status_model.RETIRED` plus `complete` rather than restating `superseded` and `withdrawn` where the board can drift from the model. Addresses the filter, not the key.

### Task 2 — Bind z, open hidden, and report each press

**Status**: complete  

Addresses the toggle and the notification. Opening hidden is the CPM default and means this board shows fewer rows on first run than it does today — expected, not a regression.

### Task 3 — Write tests for hide retired work

**Status**: complete  

Covers all four criteria, including the control that widens the filter to hide a live state — without it, the must-NOT passes equally against a toggle that hides nothing at all.

### Retro

- Changing a default that seven existing tests had silently baked in cost more than the feature did. The filter itself is two properties and a module tuple; the work was in `test_browser.py` and `test_containment.py`, where fixtures built to exercise "every state" or "the project read whole" now render a subset by default. Every one of those tests was correct and none was about the filter, so the fix was to make each say out loud that it is looking at a board showing everything — a `show_everything(pilot)` helper that presses `z`, rather than reaching into `app.selection`. Two follow-on discoveries: `found()` enumerated the unfiltered `project.epics` to set a cursor index into what is now a filtered column, which was an off-by-n waiting for the first search hit past a complete epic; and a search result landing on a hidden row had to reveal the filter rather than be dropped, since the search reads every epic the project holds and would otherwise offer a row the board then refused to move to. Neither was in the story's tasks — both came out of asking which callers read the column by index.

## Story 3 — DPM's extras moved clear

**Status**: pending  
**Blocked by**: Story 5, Story 6  

### Acceptance Criteria

- Driving a running board: `ctrl+r` re-reads every project ignoring the cache, `ctrl+f` opens search, `ctrl+g` opens coverage gaps. `[feature]`
- must NOT — No capability the DPM board has and the CPM board lacks is bound to a key that appears in the CPM board's map, read from that board's source by the same reader story 1 uses. `[integration]`

### Task 1 — Move the forced re-read to ctrl+r

**Status**: pending  

Frees `R` for story 1's clear-cache and leaves `ctrl+k` unused. Search and gaps keep the keys they have; this task is only the eviction.

### Task 2 — Write tests for DPM's extras

**Status**: pending  

Covers the three extra keys driven through a running board, and the rejection read from CPM's map by story 5's reader.

## Story 4 — Footer and palette wording

**Status**: pending  
**Blocked by**: Story 6  

### Acceptance Criteria

- The footer shows every bound key, using the CPM board's wording wherever the action is the same one. `[feature]`
- must NOT — No footer label or palette entry describes a key that is not bound, and no bound key is missing from the footer — both directions, because either alone is satisfied by a board that documents nothing. `[unit]`

### Task 1 — Align the footer labels with CPM's wording

**Status**: pending  

Only where the action is the same one — DPM-only capabilities keep their own labels, having nothing on the other board to match.

### Task 2 — Update the palette entries for actions that now have keys

**Status**: pending  

Refresh and unregister gained keys in story 1, so their palette entries now describe a capability reachable two ways. Addresses the palette half of the must-NOT.

### Task 3 — Write tests for footer and palette wording

**Status**: pending  

Covers both directions of the must-NOT — no label for an unbound key, and no bound key without a label. Either alone is satisfied by a board that documents nothing.

## Story 5 — The cross-board parity check

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- Changing a DPM binding so that a key the CPM board binds does something else makes the parity check fail, and the failure names the key. `[integration]`
- An unreadable CPM tree makes the check fail rather than skip, and the failure names what it could not read. `[integration]`
- The CPM board's source is readable at `cpm/tools/board/` relative to the marketplace checkout root, from the directory the suite runs in. `[integration]`
- The board starts, paints its columns and answers its keys with no CPM tree anywhere on its path. `[feature]`
- must NOT — The check does not assert equality between the two key maps: binding a new DPM-only capability to a key the CPM board does not use leaves it passing. `[integration]`
- must NOT — The check reads the CPM board from the installed plugin cache. The cache is overwritten on update, so a check reading it asserts against a copy nobody edits and stays green while the repository source diverges. `[integration]`

### Task 1 — Write the reader that extracts a key map from a board's source

**Status**: pending  

One reader, run against both boards, and the thing stories 1 and 3 lean on for their rejections. It reads the repository source rather than the installed plugin cache.

### Task 2 — Write the check as a category claim over CPM's map

**Status**: pending  

Every key CPM binds means the same here; DPM's extras touch nothing in that set. Addresses the must-NOT that this is not an equality — a whole-map comparison fires the first time either board legitimately grows a key.

### Task 3 — Run the mutation and the unreadable-tree case, and read what each failure says

**Status**: pending  

An activity rather than an artefact, and deliberately so: the failure has to name the key, or the tree it could not read, rather than merely being red. A mutation that fails for the wrong reason is not yet a control.

### Task 4 — Assert the board runs with no CPM tree present

**Status**: pending  

The production restriction, checked here because the environment is reproducible: a board launched from a copy with no sibling starts, paints and answers keys. Keeps the sideways reach in the suite and out of the board.

## Story 6 — Sweep the interaction surfaces

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- Bindings, footer and command palette each have a recorded outcome: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. `[manual]`
- must NOT — None of bindings, footer or command palette is left with no outcome recorded. A surface nobody compared reads exactly like one that was compared and agreed. `[manual]`

### Task 1 — Compare bindings, footer and palette, and record an outcome for each

**Status**: pending  

Three surfaces, three outcomes: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. A surface with no outcome recorded is the failure this story exists to prevent.
