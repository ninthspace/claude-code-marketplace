# Three-Column Browser and Previews

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 48-03  
**Retro applied**: 42 · Criteria gaps · Applied — FR4's "colour carrying state" is satisfied by a single style applied to every row; Story 1 asserts that distinct states render distinctly, from the rendered row rather than from the mapping table.  
**Retro applied**: 42 · Criteria gaps · Applied — FR7's story-scoping criterion is green on a fixture whose epic holds one story; Story 2's third criterion names the fixture where a wrong scope would be visible.  
**Retro applied**: 42 · Patterns worth reusing · Applied — NFR3's timing criteria are driven by a fixture server that delays its handshake, not by a delay or a hook inside the board's own code; a production seam added to make a test possible is a seam a call site can trip over.  
**Retro applied**: 42 · Scope surprises · Applied — FR1's directory picker arrives here rather than in 48-02, because the affordance needs an app to open in; recorded in both epics so neither reads as full coverage of FR1 alone.  
**Retro applied**: 49 · Testing gaps · Applied — Story 1's distinct-style criterion has the shape that let an unsorted list pass in 48-03: it can be satisfied by the mapping table alone. Asserted from the rendered row, with the style map collapsed to a single style as a mutation before the story's gate.  
**Retro applied**: 49 · Patterns worth reusing · Applied — the column, preview and state assertions read their expected rows, titles and states from the fixture that built them, so a fixture grown by a later story does not silently weaken an earlier story's test.  
**Retro applied**: 48 · Patterns worth reusing · Applied — feature tests assert the pilot's rendered text, never widget state or the mapping the render was built from; retro 48 aims this at 48-04 by name, because a pilot harness makes "what the app thinks it rendered" the easiest thing to assert.  
**Retro applied**: 48 · Scope surprises · Applied — the browser renders every project row, so it meets the `project()` fixture's unreadable database; the render path is driven against a broken project before each story's gate rather than left to 48-06.

The board a user actually looks at: Projects → Epics → Stories in Miller columns, a preview beneath the
column in focus, colour carrying the state 48-03 derives, and none of it waiting on a server to start.

## The three-column browser
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR4, ENV7

**Acceptance Criteria**:

- Projects, Epics and Stories columns render, and focus moves between them with ← / → [feature]
- The highlighted row's preview panel renders beneath its column [feature]
- Each derived state maps to a distinct style, asserted from the rendered row rather than from the mapping table, and no two states share one [feature]
- Feature-level tests drive the TUI through Textual's `run_test()` pilot [feature]

### The app shell and Miller-column layout
**Task**: 1.1  
**Description**: Three columns, with the preview panel beneath the Epics and Stories columns per FR4. Forked from `cpm/tools/board`'s view module per AD2 — the layout and focus helpers transfer, the content behind them does not.  
**Status**: Complete  
**Retro**: New `board_view.py` (Textual-free, AD2's module) and `BoardApp` in `board.py`; `textual>=0.80` declared in the PEP 723 block and `pyproject.toml` together, which the pyproject's own comment required. **The installed Textual is 8.2.8, not the 0.80 CPM's board was written against**, and the fork is of the module *split* rather than of the code: `Static.renderable` is gone, so a test cannot read a widget's own account of what it holds. `Widget.render_lines()` returns the strips actually painted, text and per-segment style together — which is the outside witness retro 48 asked for, arriving because the convenient wrong thing no longer exists.

### Focus movement and selection propagation
**Task**: 1.2  
**Description**: ← / → between columns, and a selection in one column driving the contents of the next. The case worth care is a selection that becomes invalid — an epic that vanishes from a refreshed list while its stories are on screen.  
**Status**: Complete  
**Retro**: **CPM's board guards its cascade with a `_suppress` flag, and forking that pattern hung the app in an unbreakable loop.** Textual delivers `OptionHighlighted` through the message pump, so the event the app's own write raised arrives *after* the flag is cleared: painting a column triggered a repaint that painted it again. The guard is now that the index actually changed, which cannot come apart from the pump's timing — an event agreeing with where the cursor already is has nothing to propagate. The vanishing-epic case is handled by clamping every index on each rebuild rather than remembering the row: a dropped epic moves the cursor the least it can instead of emptying the column below it.

### State to style
**Task**: 1.3  
**Description**: One style per derived state, from 48-03's enumeration rather than a parallel list. Distinctness is the criterion: a mapping where blocked and in-progress resolve to the same colour satisfies "colour carries state" and tells the user nothing.  
**Status**: Complete  
**Retro**: 48-03 had the seven states as five constants and a `RETIRED` pair but no single enumeration, so `EPIC_STATES` was added there and `STATE_STYLE` is keyed on it — a state added to the model now has no style and `style_for` refuses it rather than returning a default, which on screen is a row indistinguishable from every other row. Live work bright, retired work dim, and `style_collisions()` returns complaints so the must-NOT drives the real check over a planted mapping. Textual resolves `dim green` to its own RGB (`#046419`) rather than a dim flag, so all seven states differ as *rendered colours* — the assertion never has to read the map it is checking.

### The `run_test()` harness
**Task**: 1.4  
**Description**: ENV7's pilot harness, established once here and used by every `[feature]` criterion in this epic and in 48-05 and 48-07.  
**Status**: Complete  
**Retro**: `tests/support/pilot.py`, landed with Task 1.5 rather than ahead of it — a harness written before anything drives it is a guess at what the assertions will need, and the two defects 1.5 found were both about *what was painted*, which is what fixed its shape. Every accessor reads `Widget.render_lines()`; `styles()` compares foreground colour only, because the highlighted row is painted on the cursor's background and comparing whole styles would make one row differ for a reason that is not its state. Story 2 added an injected `reader`, so a preview test drives the panel through the same harness.

### Write tests for Story 1
**Task**: 1.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. The style criterion is asserted from the rendered row's classes, and the distinctness half by comparing the full state-to-style map for collisions.  
**Status**: Complete  
**Retro**: `tests/support/pilot.py` and `tests/test_browser.py`, 11 tests, suite 124. Writing them found two defects the smoke runs had not: the epic preview never moved when the epics cursor did (the handler painted the column below and not the panel beneath), and the Projects column appeared to clip its longest row — the row of a project that could not be read, rendering `no-databas`. **That second diagnosis was wrong and was corrected in Story 5**: the clipping was `pilot.painted()` cropping one cell short, not `width: auto`. The CSS workaround has been undone. Four mutations, three caught. **The fourth survived and was the more useful result**: deleting `Selection.clamp()` left every test green, because `OptionList` clamps `highlighted` itself and raises a highlight event when it does, so the app recovers a stale index through the message pump and the screen ends up identical. The feature test could not see the model's rule at all; a unit test on `Selection` now asserts it, and the difference the two mechanisms leave is *when* — everything painted between the refresh and the event came from an index pointing outside its list.

---

## Previews from rows
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR7

**Acceptance Criteria**:

- Preview text for an epic, spec or retro equals what the read tool returned for it [integration]
- A story's preview renders that story's own acceptance criteria and tasks, not the whole epic [integration]
- A story whose epic has several stories previews only the selected one, asserted against a fixture where another story's criteria would be visible if the scope were wrong [integration]
- must NOT open a projected `.md` file to build any preview [unit]

### Epic, spec and retro previews
**Task**: 2.1  
**Description**: `read_*` with `include_body`, and `preview_document_kind`. The `include_body` argument is the one to get right — a read without it returns the row and no prose, and the preview renders empty rather than failing.  
**Status**: Complete  
**Retro**: **The task's premise was half wrong, and reading the surface is what found it.** `read_epic` takes an `id` and nothing else — a document row has no withheld columns, so there is no `include_body` on it. The prose is in `document_section` rows, and *those* withhold `body`; the flag belongs on `list_document_section`, where leaving it off returns every heading and no text. `preview_document_kind` was deliberately not used: its only sensible place here is under an empty Epics column, and Story 1 already verified that panel renders empty for a project with nothing to show. The read tool is named for the kind, so `kind` sits on the row rather than being guessed from the id — `read_spec` refuses an epic's id rather than answering for it.

### The story preview from its own rows
**Task**: 2.2  
**Description**: That story's acceptance criteria and tasks as rows, scoped to the story. Not the epic's body, and not the epic's whole criterion set filtered client-side — the scoping belongs in the call.  
**Status**: Complete  
**Retro**: `story_id` goes in the call to both `list_story_criterion` and `list_task`, with `include_body` on each because the withheld column *is* the content in both cases — a criterion's `text` is the criterion. `list_task` was already declared for the CLI's row counts, so the arguments were added to that one declaration rather than a second: `SURFACE` is keyed on the tool name and a second `declare("list_task", …)` leaves whichever module imported last. The fixture grew a dedicated epic with three stories, and that broke a *transcribed* title set in `test_candidates.py` — retro 49's lesson arriving the same day it was written. Fixed at the transcription: `titled("open_epic", …)` names the fixture rows by the role they were built for, so a new row joins an expectation only when someone says it plays that part.

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The fixture epic holds at least three stories with distinguishable criteria, so an unscoped preview is visibly wrong rather than coincidentally right.  
**Status**: Complete  
**Retro**: `tests/test_previews.py`, 6 tests, suite 131. Two defects, both only reachable from an integration test. The retro's section had been written on the *epic that parents it* rather than on the retro row, so the retro preview was empty and correct-looking — the two are separate documents and the fixture had never made them distinguishable. And the panel test raised `read() called while another coroutine is already waiting for incoming data`: the browser builds an epic's preview and a story's in **separate workers over one project's client**, which `StreamReader` refuses outright. Id-matching was not enough, because the reply a second call waits for is on a pipe it may not read; `_receive` now serialises on a lock and the holder reads everyone's replies into `_unmatched`. Six mutations, five caught immediately. **The must-NOT survived, and vacuously**: the fixture project has no projected `.md` at all — dpm's write tools write rows, not files — so "opens no projected file" was asserted against a project with nothing to open. The test now plants projected files first, and checks both the recorded opens and the absence of their content from the preview text.

---

## Off the UI thread
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: NFR3

**Acceptance Criteria**:

- The Projects column renders before any spawned server has completed its handshake [feature]
- Over ten registered projects the Projects column renders without waiting on server startup [feature]
- must NOT block the UI thread on a server spawn or a tool call [feature]

### Spawn and read as workers
**Task**: 3.1  
**Description**: Spawning and reading happen off the UI thread, with results applied back on it. The registry is on disk and needs no server, which is why the Projects column can render first at all.  
**Status**: Complete  
**Retro**: `_browse` no longer reads anything: `registry_views()` builds the whole Projects column from the registry file, and `BoardApp` takes an injected `survey` alongside the `reader` Story 2 gave it. **A worker per project rather than one over the list** — a single worker keeps the UI thread just as free and still makes the tenth project wait on the first nine, which is the ten-project criterion failing while the one-project criterion passes. Two things fell out. `ServerNotFound` was raised past the old survey and printed as a board-level error; from a worker it is a traceback with no screen to land on, so it is now the row state `SERVER_MISSING` and every failure `survey_project` can meet is a returned row. And an arriving project repaints only the columns that show it — a full repaint per arrival would re-request the highlighted row's preview once per registered project, for a panel whose contents did not change.

### A pending state per row while a read is in flight
**Task**: 3.2  
**Description**: The visible consequence of the above, and the thing that distinguishes "not loaded yet" from "no epics". Without it, a board that is working correctly looks like a board reporting an empty project.  
**Status**: Complete  
**Retro**: `pending` on `ProjectView`, rendered as `reading…` in `READING_STYLE`. **A word, not a blank** — the figure a *read* project shows in place of a count it does not have is `NOTHING`, so a pending row left to the default would render the same `—` as a project with no epics, which is the confusion the task exists to prevent. The row starts pending only if its directory is still there: nothing is going to arrive for one that is gone, and a row that stayed pending after its read finished would report the board as busy over work that is done. Every exit from `survey_project` clears it, including the two that return an unreadable state.

### Write tests for Story 3
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. Driven by a fixture server that delays its handshake — a fixture the test controls, not a delay or hook added to the board's own code.  
**Status**: Complete  
**Retro**: `tests/test_off_thread.py`, 4 tests, suite 135. The delay is `RECORDING_DELAY` on the stand-in, so the board meets a server that is simply slow and cannot tell it from a real one. **The ten-project criterion earned its place immediately**: it failed, and the cause was `ServerPool`'s single `_spawning` lock, held across the spawn, the handshake *and* the surface reconciliation — so a board opening on twelve projects started their servers strictly one after another, each waiting on every project registered before it. One lock per root; the twelve-project test went from timing out at 10s to 4.8s for the file. The rule the lock enforces was always about one root at a time, and anything wider than that is a queue. Three mutations, all caught. The must-NOT is driven rather than timed — keystrokes are pressed *while* every server is mid-handshake and where the cursor ended up is read from the rendered column, because a bound alone passes against a board that paints early and then freezes. Criterion 1 gained a third witness that does not depend on the `reading…` label: a `tools/call` cannot arrive before the handshake it follows, so an empty call log in the transcript at first paint says the handshake was still outstanding.

---

## Command palette
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR18

**Acceptance Criteria**:

- `Ctrl+P` opens the palette directly on the board's own actions [feature]
- The palette lists the board's actions and not Textual's default system commands [feature]

### The command provider
**Task**: 4.1  
**Description**: The board's own actions — register, remove, refresh, launch, attach, copy, search.  
**Status**: Complete  
**Retro**: A `COMMANDS` table of `Command(name, help, action)` and a `BoardCommands(Provider)` that yields from it and from nothing else, with `action_refresh`, `action_copy_path` and `action_unregister` on the app. **Four of the task's seven actions are deliberately not listed**: register lands in Story 5 of this epic, launch and attach in 48-05, search in 48-07 — and a palette entry that opens and does nothing is worse than an absent one, because it reports a capability the board does not have and sends the user looking for why it failed. The table is where a later epic adds its entry, beside the `action_*` it lands, so both halves are one edit. Refresh rebuilds the rows *from the registry* rather than re-pending the ones on screen, which is what makes it retry a project that was unreadable — the state a user reaches for refresh from. `reload` and `unregister` are injected like `reader` and `survey` before them: the app owns no registry file, so a test drives every action without one and a defaulted fallback cannot reach the user's own projects.

### Bind `Ctrl+P` to open on it directly
**Task**: 4.2  
**Description**: "Directly" is the requirement: opening the palette on Textual's default command set and making the user filter down to the board's actions is the behaviour FR18 exists to replace.  
**Status**: Complete  
**Retro**: `COMMAND_PALETTE_BINDING = "ctrl+p"` and `COMMAND_PALETTE_DISPLAY = "^p"` on the app. **Textual 8's default binding is already `ctrl+p`, and that is exactly why it is stated here**: a default that happens to agree with the requirement is not the requirement being met, and the board's key would move the day the framework moved its own with nothing in this repo to notice. The display was `None`, which falls back to the binding's own name and prints `ctrl+p` in a footer where every other key is written `^`-style. "Directly" itself was delivered in 4.1 by replacing the provider set rather than adding to it; there is nothing to bind here that would open on the system commands.

### Write tests for Story 4
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. The second criterion is the one that fails on a default palette, which is what an unconfigured provider gives.  
**Status**: Complete  
**Retro**: `tests/test_palette.py`, 5 tests, suite 140. `pilot.palette()` reads the palette's own `OptionList` through `render_lines`, so both criteria are asserted from what a user sees rather than from the provider — asking `BoardCommands` what it yields would be asking the thing under test to grade itself, and a correct provider inside a palette configured to show Textual's is a passing unit test and a failing requirement. The system commands are **derived** (`App.get_system_commands()`) rather than transcribed, so the absence assertion goes on meaning what it means when Textual's set changes. That derivation is what forced `Quit` to become `Quit the board`: Textual's own set has a `Quit`, and a list asserted to be the board's own is not testable against a name in both. Rows are matched exactly for the same reason — a substring test lets `Quit` match `Quit the board` in either direction. Three mutations, all caught: extending the provider set instead of replacing it, dropping the explicit `ctrl+p`, and pointing a command at an action the app does not have.

---

## Register a project from inside the TUI
**Story**: 5  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR1

**Acceptance Criteria**:

- A directory picker reached from the board registers a project, and the new project appears in the Projects column without a restart [feature]
- The picker refuses a directory that is not a dpm project with the same message the CLI gives [feature]

### The picker screen
**Task**: 5.1  
**Description**: FR1's second affordance. Reached from the palette and from a key binding, so the capability is discoverable rather than only bindable.  
**Status**: Complete  
**Retro**: `PickerScreen(ModalScreen)` over a `ProjectTree` (a `DirectoryTree` filtered to directories, dot-directories dropped — `.dpm` is the marker being looked *for*, not a place to look). Reached from `ctrl+n` and from the palette's new "Register a project": only-bindable is found by reading the footer at the moment you need it, only-in-the-palette costs two keystrokes forever. The refusal message moved into one `refusal(path)` used by both affordances, because FR1 is covered only across the CLI and the picker and two copies of that sentence are two explanations of one condition. A refusal renders *in* the picker and leaves it open — the user's next move is to pick a different directory, and a modal that closes to say so has thrown away what they were doing it from. **`self._register` is a method on Textual's `App`**, and assigning the injected callable over it broke every screen mount in the suite with a traceback naming only Textual's code; `_unregister` is one too and had been shadowed since 4.1 without a failing test. Both are now `_add_project` / `_drop_project`.

### Register and refresh the column in place
**Task**: 5.2  
**Description**: "Without a restart" is the criterion. A registration that lands in the file and not in the view is the failure mode, and it looks like the picker not working.  
**Status**: Complete  
**Retro**: `registered()` writes through the injected `register` and then `rescan()`. **The rows come back from the registry, not from the picker's answer** — the registry normalises the path it stores, so a row built here from the chosen path would be a second and quietly different account of the same project, and the two would disagree the first time a symlink or a `~` was involved. Rows already read are kept by path and only genuinely new ones are surveyed, which is what "in place" buys: a registration adds one project, and `action_refresh`'s whole-board re-read would put every other row back to `reading…` and re-spawn its server for a change that touched one of them. `start_survey` took an optional set of indices to make that possible; refresh still passes none and means all.

### Write tests for Story 5
**Task**: 5.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. The shared refusal message is asserted against 48-02's CLI message rather than restated, so the two cannot drift into two different explanations of the same problem.  
**Status**: Complete  
**Retro**: `tests/test_picker.py`, 5 tests, suite 145. The refusal is asserted by **running `run_cli(["add", …])` in the same test** and comparing what it printed with what the picker painted, so the two affordances cannot drift; a transcribed message would be a third copy that went on passing after both real ones changed. Registration is asserted against the registry file *and* the column, because the two failures look nothing alike from outside — a row without an entry is lost at the next launch, and an entry without a row is the failure the story names. "In place" is asserted as row *identity*, since a re-survey replaces rows with equal-looking ones that a value comparison accepts. Three mutations, all caught. **The harness had been cropping one cell short all along**: `painted()` reset a content-sized region to the widget's origin, which sits outside the padding, so the rightmost character of any full-width row was never read. That is what truncated `no-database` to `no-databas` in Story 1 — the CSS was innocent, the `width: auto` workaround has been undone, and Story 1's note is corrected in place.

---

## Notes

**Step 3c — integration testing story: skipped.** The seams this epic crosses are already covered
end-to-end elsewhere: Board ↔ MCP server by 48-02's Story 6 and again by Story 2's preview criteria
against the real tools, and Contract ↔ consumers by 48-03's Stories 4 and 5. What remains here is the
view over state that already exists, and the five stories are parallel features of one app rather than
components that must interoperate. The one genuine cross-story risk — a failure in one project's read
taking the whole board down — is NFR2's, and it is verified in 48-06 where the failure states are built.

**FR1 is covered only across two epics.** The CLI affordance is 48-02 Story 1's third criterion; the
directory picker is Story 5 here. Neither epic covers the requirement alone, and both matrices say so.

**Story 1's third criterion is added.** FR4 requires "colour carrying state" and its criteria assert that
columns and previews render. A stylesheet applying one class to every row satisfies both. The added
criterion asserts distinctness from the rendered rows, and compares the whole state-to-style map for
collisions — the enumeration coming from 48-03's derived state set, so a state added later has no style
by default and fails rather than silently sharing one.

**Story 2's third criterion is added.** FR7's "not the whole epic" is unfalsifiable against an epic with
one story, which is what a minimal fixture has. Naming the fixture in the criterion is what makes the
scoping assertion mean something.

**NFR3's criteria are driven from a fixture, not a seam.** A delay or an injection point added to the
board so a test can observe pre-handshake rendering would be production code that exists for the test,
and a call site could then trip over it. The delay lives in a fixture server the test spawns instead.
