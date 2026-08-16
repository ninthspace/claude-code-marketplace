# The key map and its guard

**Number**: 02-02  
**Source spec**: 02  
**Status**: complete  

## The three interaction surfaces, and what each comparison found

Story 6's sweep. Three surfaces were compared against `cpm/tools/board/board.py` in this checkout, and each has an outcome below — a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. None is left without one, because a surface nobody compared reads afterwards exactly like one that was compared and agreed.

**Bindings — agrees, with three deliberate additions.** All thirteen keys the CPM board binds are bound here to the same capability: `q`, `r`, `R`, `a`, `x`, `z`, `space`, `c`, `l`, `o`, `t`, `←` and `→`. Four of those pairs are one capability under two names — `add_project`/`register`, `remove_project`/`unregister`, `copy`/`copy_command`, `open_plain`/`open` — and one is the same capability over a wider set of states, `toggle_complete`/`toggle_retired`, since dpm has two retired statuses CPM has no word for. All five are recorded in `SAME_MEANING` in `tests/support/key_maps.py`, which is what keeps the check reporting collisions rather than spellings. Three keys are dpm's own and CPM binds none of them: `ctrl+r` for the forced re-read, `ctrl+f` for search, `ctrl+g` for coverage gaps. The addition is the intended state rather than a drift — the check is a rejection over CPM's own keys, not an equality between the maps, and `test_a_new_capability_on_a_key_cpm_leaves_alone_keeps_the_check_passing` is what stops it becoming one.

**Footer — two differences closed, and one bug found.** `o` read "Open" and now reads "Open project"; `space` read "Select" and now reads "Ralph-select". Both were closed in story 4 against the CPM board's own words, and every one of the thirteen shared keys now carries an identical label. The bug is separate and had been shipping since the board's first story: `OptionList` inherits horizontal scroll bindings, so while a column had focus Textual answered `←` with "Scroll Left" carrying `show=False` and the footer printed neither arrow. The keys worked throughout — a column that cannot scroll sideways declines its own binding and lets it bubble — so the only symptom was two undocumented keys, and it was invisible to any test comparing `BINDINGS` with itself. A `Column(OptionList)` subclass re-declares them against the app's actions.

**Command palette — differs, and the difference is deliberate.** Nothing in spec 2 asks for palette parity; FR19's wording clause is scoped to the footer, and the two sets cannot match in any case because dpm offers four entries CPM has no equivalent of (search, coverage gaps, force refresh, copy project path) and CPM offers one dpm deliberately withholds. The differences, each with its reason:

- Seven entries are named more fully here than on the CPM board — "Launch a session" for "Launch", "Open Claude at the project" for "Open project", "Attach to a live session" for "Attach", "Copy the command" for "Copy command", "Register a project" for "Add project", "Clear the cache" for "Clear cache", "Show/hide done" for "Show/hide completed". A palette is reached by typing at it, so a longer distinctive name is worth more there than in a footer where width is scarce and the key is beside the label. "Show/hide done" is also the more accurate of the pair here, since what it hides is complete, superseded and withdrawn.
- "Quit the board" rather than "Quit", which is forced: Textual's own system command set — the one this board's provider replaces — has an entry called "Quit", and a palette asserted to hold the board's own actions is not testable against a name that appears in both lists.
- `toggle_ralph` has a key and no palette entry, where CPM offers "Ralph-select epic". The palette acts on the board as a whole and this acts on the row under the cursor, so an entry would run against whichever row the palette happened to leave highlighted rather than the one the user was looking at when they opened it.

Two entries already agree word for word — "Refresh" and "Remove project" — and were left alone.

## FR9 is verified in one direction and left unclaimed

Every coverage row under FR9 is verified and the requirement is deliberately not claimed, which is a distinction worth stating rather than leaving to be inferred from an empty field.

FR9 says a difference "fails something mechanically the next time **one board moves and the other does not**" — either board. The criterion bound to it is explicitly one-sided: *changing a DPM binding so that a key the CPM board binds does something else makes the parity check fail*, and that is what `test_a_binding_that_takes_a_cpm_key_makes_the_check_fail_and_name_the_key` runs. The check itself is symmetric — it re-reads `cpm/tools/board/board.py` on every run and compares over the intersection, so a rebinding on the CPM side fires it exactly as one here does — but symmetric-by-construction is an argument, not a verification, and nothing in this epic moves the CPM side and watches the check go red.

Closing it needs one more control: a copy of the CPM board's source with a binding changed, read by the same reader, and the check run against it. That is a small test and it was left out of this epic rather than forgotten, because the natural home for it is beside the reader's own cases in `tests/test_parity.py` and it belongs to whoever next has reason to touch that file.

The other seven requirements this epic delivers — FR1, FR2, FR3, FR7, FR8, ENV4 and ENVX3 — are claimed: each one's bound fragments account for its text whole.

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

**Status**: complete  
**Blocked by**: Story 5, Story 6  

### Acceptance Criteria

- Driving a running board: `ctrl+r` re-reads every project ignoring the cache, `ctrl+f` opens search, `ctrl+g` opens coverage gaps. `[feature]`
- must NOT — No capability the DPM board has and the CPM board lacks is bound to a key that appears in the CPM board's map, read from that board's source by the same reader story 1 uses. `[integration]`

### Task 1 — Move the forced re-read to ctrl+r

**Status**: complete  

Frees `R` for story 1's clear-cache and leaves `ctrl+k` unused. Search and gaps keep the keys they have; this task is only the eviction.

### Task 2 — Write tests for DPM's extras

**Status**: complete  

Covers the three extra keys driven through a running board, and the rejection read from CPM's map by story 5's reader.

### Retro

- A must-NOT over a comparison between two sets needs a floor assertion or it verifies nothing, and the floor has to name the specific things expected in the set rather than assert it is non-empty. "No dpm extra sits on a CPM key" is what an empty extras set says too, and there are several plausible ways for that set to empty itself by accident — the AST reader failing to find CPM's class, a `SAME_MEANING` entry swallowing a capability CPM does not actually have. Naming `force_refresh`, `search` and `coverage_gaps` and asserting each is being read as an extra is what distinguishes a rejection that holds from one that has stopped looking. The planted control confirmed it: binding `force_refresh` to `z` produced "`z` is this board's force_refresh and the cpm board binds it to toggle_complete", which names the key and both meanings rather than reporting that two maps differ.

## Story 4 — Footer and palette wording

**Status**: complete  
**Blocked by**: Story 6  

### Acceptance Criteria

- The footer shows every bound key, using the CPM board's wording wherever the action is the same one. `[feature]`
- must NOT — No footer label or palette entry describes a key that is not bound, and no bound key is missing from the footer — both directions, because either alone is satisfied by a board that documents nothing. `[unit]`

### Task 1 — Align the footer labels with CPM's wording

**Status**: complete  

Only where the action is the same one — DPM-only capabilities keep their own labels, having nothing on the other board to match.

### Task 2 — Update the palette entries for actions that now have keys

**Status**: complete — No entry needed rewording. Every palette help string was checked against the keys stories 1 and 3 added: none names a key, none claims a capability is palette-only, and every entry's action resolves to a method on the app. The obligation now sits in a test rather than in prose — `test_nothing_is_documented_that_no_key_or_entry_reaches` fails if a palette entry ever starts describing something nothing reaches.  

Refresh and unregister gained keys in story 1, so their palette entries now describe a capability reachable two ways. Addresses the palette half of the must-NOT.

### Task 3 — Write tests for footer and palette wording

**Status**: complete  

Covers both directions of the must-NOT — no label for an unbound key, and no bound key without a label. Either alone is satisfied by a board that documents nothing.

### Retro

- Reading the footer from the widgets it built rather than from `BINDINGS` found a bug that had been shipping since the board's first story: `OptionList` inherits horizontal scroll bindings, and while a column has focus they sit nearer the focused widget than the app's own, so Textual answered `left` with "Scroll Left" carrying `show=False` and the footer printed neither arrow. Both keys worked — a column that cannot scroll sideways declines its own binding and lets it bubble — so every existing test passed and the only symptom was two undocumented keys. A `Column(OptionList)` subclass re-declaring `left`/`right` against the app's actions puts the board's meaning at the near end of the chain, where the footer reads. The general lesson: when a criterion is about what a user *sees*, the artefact to read is the one the framework built, not the table the framework was built from — a comparison between the table and itself reports a footer that never appeared. The same shape would hide a shadowed binding in any Textual app with a focusable scrolling widget.

## Story 5 — The cross-board parity check

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Changing a DPM binding so that a key the CPM board binds does something else makes the parity check fail, and the failure names the key. `[integration]`
- An unreadable CPM tree makes the check fail rather than skip, and the failure names what it could not read. `[integration]`
- The CPM board's source is readable at `cpm/tools/board/` relative to the marketplace checkout root, from the directory the suite runs in. `[integration]`
- The board starts, paints its columns and answers its keys with no CPM tree anywhere on its path. `[feature]`
- must NOT — The check does not assert equality between the two key maps: binding a new DPM-only capability to a key the CPM board does not use leaves it passing. `[integration]`
- must NOT — The check reads the CPM board from the installed plugin cache. The cache is overwritten on update, so a check reading it asserts against a copy nobody edits and stays green while the repository source diverges. `[integration]`

### Task 1 — Write the reader that extracts a key map from a board's source

**Status**: complete — Written in story 1 as `tests/support/key_maps.py` and finished here: `binding_tuples` now gates every read through `readable`, which refuses a path under an installed plugin cache before opening it and asserts — naming the path — when the tree is absent.  

One reader, run against both boards, and the thing stories 1 and 3 lean on for their rejections. It reads the repository source rather than the installed plugin cache.

### Task 2 — Write the check as a category claim over CPM's map

**Status**: complete  

Every key CPM binds means the same here; DPM's extras touch nothing in that set. Addresses the must-NOT that this is not an equality — a whole-map comparison fires the first time either board legitimately grows a key.

### Task 3 — Run the mutation and the unreadable-tree case, and read what each failure says

**Status**: complete — Both cases run, and both read for what they said rather than for red. The mutation put `quit` on `x` — CPM's unregister — and the check answered "`x` is remove_project on the cpm board and quit here". The absent tree answered with the path it wanted and the reason a skip would be wrong. The activity is now also a standing test in `tests/test_parity.py`, so neither case depends on having been run once by hand.  

An activity rather than an artefact, and deliberately so: the failure has to name the key, or the tree it could not read, rather than merely being red. A mutation that fails for the wrong reason is not yet a control.

### Task 4 — Assert the board runs with no CPM tree present

**Status**: complete  

The production restriction, checked here because the environment is reproducible: a board launched from a copy with no sibling starts, paints and answers keys. Keeps the sideways reach in the suite and out of the board.

### Retro

- A check that compares this repository against another file has four ways to be green and only one of them is agreement: the second file was never opened, the wrong second file was opened, the comparison cannot fail as written, or the two really do agree. Three of those are only distinguishable by breaking something and reading what comes back, so this story's tests are mostly plants — an absent tree, a cache-shaped path, a mutated binding, a new capability on a free key. Two things made them worth the effort. First, importing `test_keys`' own parity test and running it under a substituted `BoardApp.BINDINGS` exercises the assertion that actually runs in the suite, where a re-implementation could satisfy every criterion while the real check had quietly stopped working. Second, the isolation criterion could only be answered in a subprocess from a copied tree: this process has already imported the board from a checkout that does have a cpm tree beside it, so no assertion made in-process can tell a board that never reaches sideways from one that reached and found what it wanted.

## Story 6 — Sweep the interaction surfaces

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Bindings, footer and command palette each have a recorded outcome: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. `[manual]`
- must NOT — None of bindings, footer or command palette is left with no outcome recorded. A surface nobody compared reads exactly like one that was compared and agreed. `[manual]`

### Task 1 — Compare bindings, footer and palette, and record an outcome for each

**Status**: complete  

Three surfaces, three outcomes: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. A surface with no outcome recorded is the failure this story exists to prevent.

### Retro

- "Recorded as deliberate" turned out to be the outcome that earned this story, and it was the one most at risk of being skipped. Bindings and footer both ended in agreement, which a run could have reported in a sentence; the palette differs on ten of its entries, and the temptation was either to close those differences (making a change nothing in the spec asks for — FR19's wording clause is scoped to the footer, and the two sets cannot match anyway since dpm has four entries CPM lacks) or to say nothing about them at all. Writing the reason per entry surfaced that one of the differences is forced rather than chosen: "Quit the board" cannot be renamed to CPM's "Quit" without breaking an existing test, because Textual's own system command set — the one this board's provider replaces — already has an entry by that name. A sweep that reported "the palette differs" and moved on would have left that indistinguishable from a difference somebody could close on a slow afternoon.
