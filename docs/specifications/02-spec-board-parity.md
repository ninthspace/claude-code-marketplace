# Board parity — the DPM board back on the CPM board's look and keys

**Number**: 02  
**Status**: complete — Approved 2026-08-16. Built from discussion 1; FR9's parity check is the item that makes AD1's copying acceptable and belongs in the same epic as the ports.  

## Problem recap

The DPM board and the CPM board were built to the same shape and have drifted apart. A user moving between them finds the keys mean different things, the highlighted row looks different, and the panel beneath a column shows raw markdown on one board and rendered markdown on the other. Four differences are established, from reading both trees rather than from recollection.

**Keys.** The two boards agree on `q`, `l`, `o`, `t`, `c`, `space`, `←` and `→`, and diverge everywhere else. `R` is the outright collision — it clears the cache on the CPM board and forces a re-read on the DPM one. CPM's `r` (refresh), `a` (add) and `x` (remove) are respectively unbound, bound to `ctrl+n`, and palette-only on DPM; CPM's `z` (show or hide completed work) has no DPM counterpart at all. DPM additionally binds `ctrl+f` for search and `ctrl+g` for coverage gaps, neither of which CPM has anything to collide with.

**Cursor.** The CPM board subclasses `OptionList` as `InverseOptionList`, post-processing the highlighted strip into a muted, row-coloured inverse bar, and pairs it with CSS neutralising Textual's own highlight so the two do not fight. The DPM board has neither, and shows the stock blue cursor block over its state colours.

**Live pill.** The CPM board composes the projects row as a `Table.grid` with a right-justified cell, so `● live` hugs the right edge at any column width. The DPM board appends it to a plain string label, where it floats after the progress figure.

**Previews.** The CPM board rasterises a Rich `Markdown` at the panel's own width into a selectable Textual `Content`, re-rendered on resize, with soft breaks rewritten to hard ones. The DPM board puts a plain string into a `Static`, so the epic and story panels show markdown source.

The work is to close all four: CPM's keys as the base with DPM's extra capabilities on non-colliding keys, the cursor and pill rendering ported, and the epic and story previews rendered as markdown.

**One difference is examined and excluded.** The state-colour palettes are keyed on different state vocabularies — CPM on `EPICS_READY` and `SPEC_READY`, DPM on `PENDING`, `SUPERSEDED` and `WITHDRAWN` — so they are not two colour schemes to reconcile. The colours agree for the states both models have, and that is as far as parity can honestly be taken.

## Scope boundary

**In scope.** The key rebinds and the new hide-retired behaviour (FR1–FR3); the cursor and pill ports (FR4, FR5); markdown previews and the re-cut preview builders (FR6, FR6a); footer labels and palette entries for the keys that moved (FR7); the surface-by-surface comparison of the two boards (FR8); and the cross-board parity test (FR9, per AD2). Moving the tests that pin what changes is part of the work rather than a consequence of it — `test_previews.py` asserts the current plain-text preview shapes, and anything asserting today's key map moves with FR1.

**FR8's sweep is bounded to what a user can see**: bindings, footer, command palette, column layout, row composition, CSS and preview behaviour. It does not cover caching, the MCP client or the registry. Those differ because the two boards read different things — one reads files, the other queries servers — so comparing them produces findings nobody will action, and an unbounded sweep is the item most able to swallow the rest of the work.

**Out of scope.** Reconciling the state-colour palettes (FR10). **Any change to the CPM board**: parity is reached by moving DPM, and where the sweep finds a difference in which CPM is the one that ought to move, it is recorded and left. The design of the DPM-only search and gaps screens — only their keys are in scope. What the integrity badge means or when it appears — only where it sits.

**Deferred.** A shared package or merged codebase (FR11), and any CPM-side change the sweep turns up.

**Two boundary conditions worth stating before they are discovered during implementation.**

The parity test reads the CPM board's source, so it is coupled to how that source writes its bindings. If the CPM board restructures its `BINDINGS` into a shape the reader cannot parse, the test fails for a reason that is not drift. That is the correct outcome — a loud failure that needs a person — rather than a defect to design around, and it is written here so the person meeting it recognises it.

FR9 is the only item in this spec that is not visible on screen, which makes it the one most likely to slip, and it is also the item that makes AD1's copying acceptable. Delivered without it, this spec has knowingly added a third copy of a rendering idea with nothing underneath it. It belongs in the same epic as the ports rather than after them.

## Integration boundaries

Four seams, each following from a decision in Section 4, and each the place integration coverage belongs rather than unit coverage.

**`board_view.py` → `board.py`, and the contract is a string of markdown.** AD3 puts the preview builders on one side and the rasteriser on the other, so the interface between them is markdown source. Unit tests on either side hold up their own end — the builders emit headings and lists, the raster draws them — and neither says the two are connected. The integration claim is the whole path: a row is highlighted, the builder composes source for it, the raster renders it at the panel's width, and the panel shows it.

**The DPM board's suite → the CPM board's source.** AD2's check reads the other tree, so it depends on how that tree writes its `BINDINGS`. This is the seam most likely to fail for a reason that is not drift, and the scope boundary states the expected behaviour when it does: a loud failure that needs a person, not a fallback.

**`board.py` → `status_model.RETIRED`.** FR2's filter reads the grouping the model already names rather than restating `superseded` and `withdrawn` where the board can drift from it. The boundary is worth a test of its own: a state joining `RETIRED` should change what `z` hides with nothing in the board edited.

**`board.py` → Textual's `OptionList` render path.** The inverse cursor of FR4 post-processes rendered strips, which is a coupling to a version rather than to a documented interface — Textual can move the render path under it, and the failure would be visual rather than an exception. It is recorded here because the coverage that catches it has to assert on what a rendered row *looks* like, which is a different kind of test from the rest of FR4.

## Functional Requirements

### FR1 (must)

Every key the CPM board binds carries the same meaning on the DPM board: `r` refreshes, `R` clears the cache, `a` registers a project, `x` unregisters the highlighted one, `z` shows or hides retired work, and the eight already shared — `q`, `l`, `o`, `t`, `c`, `space`, `←` and `→` — keep theirs. A capability the DPM board reaches only through the command palette today gains its CPM key.

- Driving a running board: `r` re-reads every registered project, `R` empties the cache, `a` opens the register picker, `x` unregisters the highlighted project, and `z` toggles retired work. `[feature]`
- For every action the CPM board binds, read from that board's own source, the DPM board binds the same action to the same key. The claim is stated over CPM's map as the source rather than as an equality between the two maps, so a key either board legitimately gains does not fail it. `[integration]`
- must NOT — No key the CPM board binds does something different on the DPM board. `[integration]`

### FR2 (must)

Retired work is hidden when the board opens and `z` toggles it, where retired means `complete` together with the two states `status_model.RETIRED` already names — `superseded` and `withdrawn`. Each press says which way it went, as the CPM board's does.

- A board opened over a project holding complete, superseded, withdrawn and live rows shows only the live ones; `z` reveals all four groups; `z` again returns to the first state. `[feature]`
- Each press says which way it went, so a board that was already showing everything is distinguishable from one that has just been told to. `[feature]`
- must NOT — No row in a live state — ready, in progress, blocked or pending — is removed by the filter, with one case per live state rather than one case for the set. `[unit]`
- control — With the filter widened to hide a live state, the case above fails and names the state it lost — so a filter that removed nothing at all could not pass it. `[unit]`

### FR3 (must)

Every capability the DPM board has and the CPM board lacks is bound to a key that collides with nothing in the CPM map. The forced re-read gives up `R` and takes `ctrl+r`; search and coverage gaps keep `ctrl+f` and `ctrl+g`.

- Driving a running board: `ctrl+r` re-reads every project ignoring the cache, `ctrl+f` opens search, `ctrl+g` opens coverage gaps. `[feature]`
- must NOT — No capability the DPM board has and the CPM board lacks is bound to a key that appears in the CPM board's map, read from that board's source by the same reader FR1 uses. `[integration]`

### FR4 (must)

The highlighted row renders as a muted bar in the row's own colour, blended partway toward the background, as the CPM board's `InverseOptionList` paints it — and Textual's default highlight block does not show through it.

- The strip rendered for the highlighted row carries that row's own colour blended toward the background — a red row and a green row highlight differently, and neither highlights in a fixed accent colour. `[unit]`
- must NOT — Textual's own highlight style appears on no rendered row, whether or not the list has focus. `[unit]`
- control — With the CSS override removed, the criterion above fails — so a board rendering no highlight at all could not satisfy it by having nothing to find. `[unit]`

### FR5 (must)

The live pill and the integrity badge sit against the right edge of the projects column whatever width that column has, rather than following the progress figure, and each keeps its own colour over the row's status colour.

- A projects row rendered at column width 24 and again at 48 puts the pill's last character in the row's last column both times. `[unit]`
- The pill and the badge each render in their own colour rather than the row's status colour, on a row whose status colour differs from both. `[unit]`
- must NOT — Neither pill nor badge is truncated on a row too narrow to hold everything: the project name is what gives. `[unit]`

### FR6 (must)

The epic and story preview panels render markdown rather than showing its source: headings, emphasis, lists and tables draw as the CPM board draws them, at the panel's own width, re-rendered when the panel is resized, with the rendered text still selectable.

- Source containing a heading, emphasis, a list and a table renders each as a styled construct rather than as its source characters. `[unit]`
- The same source rendered at two panel widths breaks its lines differently, so the render is using the panel's width rather than a default. `[unit]`
- Resizing the panel re-renders its contents at the new width. `[feature]`
- The panel's renderable is built from styled text rather than being a live markdown widget, which is what leaves the rendered preview selectable. `[unit]`
- must NOT — No markdown marker survives into the rendered output for a construct that was rendered — no `##` before a heading, no `- ` before a list item, no `**` around emphasis. `[unit]`

### FR6a (must)

The preview builders emit markdown source rather than plain text, so that the structure they compose from rows — the document's title, each section's heading, a story's criteria and tasks — renders as headings and lists rather than as prose that happens to begin with a dash.

- `document_preview` returns the document's title as a markdown heading and each section's heading as a heading beneath it. `[unit]`
- `story_preview` returns the story's criteria and tasks as markdown lists, with a task's description subordinate to the task rather than beside it. `[unit]`
- must NOT — No plain-text scaffolding label survives in either builder's output — a bare `Acceptance criteria:` line renders as prose and is the shape this requirement exists to remove. `[unit]`

### FR7 (should)

The footer labels and the command-palette entries describe the keys as they stand after FR1 and FR3, and use the CPM board's wording wherever the action is the same one.

- The footer shows every bound key, using the CPM board's wording wherever the action is the same one. `[feature]`
- must NOT — No footer label or palette entry describes a key that is not bound, and no bound key is missing from the footer — both directions, because either alone is satisfied by a board that documents nothing. `[unit]`

### FR8 (must)

The two boards are compared surface by surface beyond the four differences already established, and every further difference found is either closed or recorded as deliberate. A difference nobody has looked at is neither.

- Each of the seven bounded surfaces — bindings, footer, command palette, column layout, row composition, CSS, preview behaviour — has a recorded outcome: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. `[manual]`
- must NOT — No surface is left with no outcome recorded. A surface nobody compared reads exactly like one that was compared and agreed, and the record is the only thing that separates them. `[manual]`

### FR9 (must)

A difference of the kind this spec closes fails something mechanically the next time one board moves and the other does not, rather than waiting to be noticed by a user moving between them. What that mechanism is, is decided in Section 4.

- Changing a DPM binding so that a key the CPM board binds does something else makes the parity check fail, and the failure names the key. `[integration]`
- An unreadable CPM tree makes the check fail rather than skip, and the failure names what it could not read. `[integration]`
- must NOT — The check does not assert equality between the two key maps: binding a new DPM-only capability to a key the CPM board does not use leaves it passing. `[integration]`

### FR10 (wont) — out_of_scope

The two boards' state-colour palettes are not reconciled. They are keyed on different state vocabularies rather than being two colour schemes over one, and the colours already agree for the states both models have.

### FR11 (wont) — deferred

The two boards are not merged into one codebase and share no installable package. Each stays a self-provisioning single-file script, and FR9's mechanism has to work within that.

## Non-Functional Requirements

### NFR1 (must)

Moving the cursor through a list stays responsive. Rendering the highlighted row's preview does not block key handling, and a held arrow key does not queue one render per row passed over. The markdown raster is new CPU work on a path that already runs per highlighted row, and it is width-specific, so it runs again on every resize.

- A render for a row the cursor has since left is discarded rather than painted, so moving quickly through a list leaves the panel showing the row the cursor is on. `[feature]`
- Rendering the largest document in the fixture at 80 columns completes within 50 ms. `[unit]`

### NFR2 (must)

A preview the renderer cannot make sense of — malformed markdown, a pathological table, a body that is one very long line — renders as something and does not take the board down. The board is a viewer over projects it did not write, and one bad row in one project must not close it for the others.

- A preview whose source is malformed, pathologically nested, or a single very long line renders something and leaves the board running. `[unit]`
- control — With the guard removed, the same input takes the board down — so the criterion above cannot pass against a renderer that was never at risk from it. `[unit]`

### NFR3 (must)

The highlighted row and the pill stay legible on a terminal that does not report truecolor. The cursor blends two colours and the raster asks for a colour system by name, so both are assumptions about the terminal rather than about the code.

- With the console limited to 256 colours, the highlighted row is still distinguishable from an unhighlighted one, and the pill from the row's own colour. `[unit]`

## Environmental Requirements

### ENV1 (must)

Development: `uv run pytest` from `dpm/tools/board` runs the suite, with pytest 8 or later, pytest-asyncio 0.24 or later, and `asyncio_mode = "auto"`.

- pytest and pytest-asyncio are present at or above the stated minimums, and the suite runs from `dpm/tools/board`. `[unit]`

### ENV2 (must)

Development: Textual 0.80 or later, with the dependency list in `pyproject.toml` and the PEP 723 inline block at the top of `board.py` naming the same packages. A package in one and not the other is one the suite has and the board does not.

- The dependency list in `pyproject.toml` and the PEP 723 inline block in `board.py` name the same packages. `[unit]`

### ENV3 (must)

Development: a markdown renderer importable from a package the board already declares. Rich arrives with Textual, so FR6 adds nothing to either dependency list.

- The markdown renderer imports, and neither dependency list has gained an entry for it. `[unit]`

### ENV4 (must)

Development: the CPM board's source is readable at `cpm/tools/board/` relative to the marketplace checkout root, which is what FR8's comparison and FR9's mechanism read.

- The CPM board's source is readable at `cpm/tools/board/` relative to the marketplace checkout root, from the directory the suite runs in. `[integration]`

### ENV5 (must)

Production: Python 3.11 or later on the machine the board runs on, provisioned by `uv run` from the inline block.

- The host running the board has Python 3.11 or later, and `uv run` provisions the board from its inline block there. `[target]`

### ENV6 (must)

Development: a fixture project whose database holds epics and stories in every state the model defines, retired ones included, and at least one document long enough to time a render against. FR2's hide-retired criteria and NFR1's timing criterion both assume it, and neither can be checked without it.

- The fixture builds, and holds at least one epic or story in each state the model defines — including `complete`, `superseded` and `withdrawn` — together with a document long enough to time a render against. `[integration]`

## Environmental Restrictions

### ENVX1 (must)

Development: the suite must not require network access. The guard that enforces it is autouse, so this is a property of every test rather than of the one that remembered to ask for it.

- A socket opened during the suite raises and is recorded, so the run is known to have needed no network rather than assumed to have needed none. `[unit]`

### ENVX2 (must)

Development: this work must not require a package outside `board.py`'s inline block, and dpm itself must gain no dependency from it.

- `board.py` imports nothing outside the standard library and the packages its own inline block declares. `[unit]`

### ENVX3 (must)

Production: the board must not require the CPM plugin to be installed or readable. It runs from the plugin cache, where only its own tree exists, so FR9's mechanism cannot be something the board reaches for at runtime.

- The board starts, paints its columns and answers its keys with no CPM tree anywhere on its path. `[feature]`

### ENVX4 (must)

Production: the board must not require a truecolor terminal. The cursor blends two colours and the raster names a colour system, and neither may be the thing that decides whether the board is legible.

- The board renders against a console reporting 256 colours without error, and the render is not silently a monochrome one. `[unit]`

## Architecture Decisions

### 02-01 — How the CPM board's rendering code reaches the DPM board

**Decision status**: accepted  

The cursor and markdown rendering are copied into the DPM board's own `board.py`, and the copy is kept honest by the cross-board check of AD2 rather than by a shared artefact.

#### Copy into the DPM board — chosen

Each board stays a self-provisioning single-file script, which is what FR11 preserves and what lets either be run straight from a plugin cache with no install step. The cost — a third copy of a rendering idea, and copies drift — is exactly the defect this spec repairs, so the copy is accepted only because AD2 puts a mechanical check under it.

| Axis | Assessment |
| --- | --- |
| cost | Low to apply and permanent to carry: the port is one afternoon, and the duplication is paid at every future change to either renderer. |
| reversibility | Fully reversible. Extracting a shared module later is strictly easier from two copies that are known to agree than from two that have drifted. |

#### A vendored file kept in step by a sync script

Makes the duplication explicit and mechanical rather than hand-made. Rejected because it adds a build step to two plugins that currently have none, and the script is itself a thing that can be forgotten — it converts "did anyone copy the change across" into "did anyone run the script", which is the same question wearing different clothes.

| Axis | Assessment |
| --- | --- |
| complexity | Adds a build step to two plugins that have none, and a script whose being run is itself unchecked. |

#### A shared installable package

The structurally correct answer to duplication, and ruled out by FR11 rather than on its merits: it would give both boards a dependency neither can satisfy from a PEP 723 inline block, and end the property that a board is one file you can run.

### 02-02 — What stops the two boards drifting apart again

**Decision status**: accepted  

A test in the DPM board's suite reads the CPM board's source and asserts that every key CPM binds carries the same meaning on DPM, treating an unreadable CPM tree as a failure rather than a skip.

#### Cross-board test, absent tree is a failure — chosen

ENV4 states the CPM tree is readable where development happens, so a checkout without it is a broken environment rather than an excused one, and saying so out loud is the difference between a check and a check-shaped thing. What it asserts is stated over the category rather than as an equality: every key CPM binds means the same on DPM, DPM's extra keys touch nothing in that set. An equality over the whole map would fire the first time either board legitimately grows a key — the shape retro 1 named as a change detector wearing a rejection's clothes.

| Axis | Assessment |
| --- | --- |
| complexity | Couples the DPM board's suite to the CPM tree's path, which ENV4 states and ENVX3 confines to development. The board itself gains no such reach. |
| cost | One test in one suite. The work is in stating the assertion over the category rather than as an equality, not in reaching the other tree. |

#### Cross-board test that skips when the tree is absent

Runs anywhere, which is the whole of its appeal. Rejected because a test that stops checking without saying so is worse than no test: the green run afterwards means something different from the green run before it, and nothing in the output distinguishes them. This project has already been bitten by a check that passed while exercising a short circuit.

| Axis | Assessment |
| --- | --- |
| reversibility | Easy to change later and hard to notice needing it: a skipped check reports the same green as a passing one. |

#### A key-map fixture checked into each tree

Each suite asserts its own board against its own fixture, with no suite reaching sideways. Rejected because nothing then compares the two fixtures with each other: it detects a board drifting from its own declaration and is blind to the two declarations drifting apart, which is the failure actually being guarded against.

#### A maintenance record and no test

Cheapest, and honest about being a note rather than a check. Rejected because the drift this spec repairs happened under exactly these conditions — two boards, no check, and no record either. Retro 1 also found that a warning written in one file did not prevent a second occurrence in another, because a warning is only read where the reader already is.

### 02-03 — Where the preview's markdown boundary sits

**Decision status**: accepted  

`board_view.py`'s preview builders emit markdown source and stay free of Textual and Rich; the rasteriser that turns it into a renderable lives in `board.py` with the widgets.

#### Builders emit markdown source; board.py rasterises — chosen

Keeps `board_view.py` free of Textual and Rich, which is what makes its existing tests plain string assertions, and confines the width-specific, resize-driven work to the module that owns the widgets. The preview tests stay what they are — markdown source is still a string — and the raster gets tests of its own about width and selection.

| Axis | Assessment |
| --- | --- |
| complexity | Holds the existing module boundary rather than moving it. The one new concept is that a preview builder's output is markdown, which is what FR6a states. |
| cost | The existing preview tests move rather than being rewritten — they assert on strings before and after. |

#### Rasterise inside board_view

One module would own the whole preview path. Rejected because it pulls Rich into the only module in the board that has no rendering dependency, and turns every preview assertion into a rendering assertion — a test about which criteria appear would then fail when a heading style changed.

#### Builders return structured objects

Typed preview objects formatted by `board.py`. Rejected as a layer bought for nothing: markdown is already the interchange format both boards use, the CPM renderer takes a string, and the structure would exist solely to be flattened into one on the other side of the boundary.

## Dependencies

- builds_on → 01
