# Retro: The Three-Column Browser and Previews

**Date**: 2026-08-14  
**Source**: docs/epics/48-04-epic-browser-and-previews.md  
**Stories**: 5/5 complete

## Summary

This epic built the thing a user actually looks at: Projects → Epics → Stories in Miller columns,
previews built from rows beneath them, reads off the UI thread, a command palette, and a directory
picker. The board's suite went from 103 to 145.

Every defect worth recording here was found by a test and not by running the board, and every one of
them lived in a seam a unit test cannot reach. Two coroutines on one pipe. One lock held across a
handshake. An attribute name the framework already owned. A test harness reading one cell short of
what was painted. None of these is visible in the shape of the code; all four are visible the first
time something drives the app for real.

The other theme is **must-NOTs that pass without asserting anything**. Two of them shipped green and
were rebuilt: one checked that no projected `.md` was opened, in a fixture project that has no `.md`
files at all; the other checked that Textual's system commands were absent, against a name both
lists contained. A must-NOT is the criterion most easily satisfied by an absence that was never in
question, and neither of these would have been caught by reading the test.

## Observations

### Codebase Discoveries

- **The installed Textual is 8.2.8, not the 0.80 CPM's board was written against.** AD2's fork is of  
  the module *split*, not of the code. `Static.renderable` is gone, so a test cannot read a widget's  
  own account of what it holds — which turned out to be the right constraint rather than a problem:  
  `Widget.render_lines()` returns what was actually painted, text and per-segment style together.  
  The convenient wrong thing no longer exists.
- **`self._register` and `self._unregister` are methods on Textual's `App`.** Assigning injected  
  callables over them replaces the framework's node registration, and the first screen then fails to  
  mount in a traceback naming only Textual's code. `_unregister` had been shadowed for an entire  
  story with nothing failing, because the path that uses it was not on any test's route. An app  
  subclass shares one namespace with a large framework and nothing warns.
- **`ServerPool` held one spawn lock for the whole pool, across the spawn, the handshake and the  
  surface reconciliation.** The rule being enforced — two coroutines must not spawn the same root —  
  is about one root at a time; anything wider is a queue. Twelve projects started their servers  
  strictly one after another, each waiting on the startup of every project registered before it.
- **`asyncio.StreamReader.read()` refuses a second concurrent waiter outright.** The client's  
  id-matching already tolerated out-of-order replies, and that is not enough on its own: the reply a  
  second call is waiting for is on a pipe it is not allowed to read. Serialising the *read* is the  
  fix, and it is deadlock-free because the holder keeps reading until its own reply arrives and a  
  request that already has one never takes the lock.
- **`read_epic` / `read_spec` / `read_retro` take an `id` and nothing else.** A document row has no  
  withheld columns. The prose is in `document_section` rows and *those* withhold `body`; the  
  `include_body` flag belongs on the list tools. Task 2.1's premise had it on the read tools, and  
  reading the declared surface is what found it.
- **The read tool is named for the kind and refuses an id of another kind.** So the kind belongs on  
  the row rather than being guessed — `read_spec` answers "that is a spec, not an epic" rather than  
  answering for the wrong document.
- **dpm's write tools put rows in the database and nothing on disk.** The fixture project contains  
  `.dpm/dpm.db` and a `.gitignore`, and no projected markdown at all.

### Testing Gaps

- **A must-NOT about not reading files, asserted against a project with no files to read.** "must  
  NOT open a projected `.md` file to build any preview" was green, and a planted mutation that  
  globbed `docs/epics/*.md` and read every hit stayed green — there was nothing there to open. The  
  test now plants projected files first and checks both the recorded opens *and* the absence of  
  their content from the preview text, so a read by some route other than `open` is caught too.  
  **The condition a must-NOT forbids has to be available before its absence means anything.**
- **A palette absence check that both lists satisfied.** Textual's system command set contains  
  `Quit`, and so did the board's. A substring test let the board's own `Quit` match the system one  
  in either direction; the assertion was structurally incapable of failing on the entry it named.  
  Renaming the board's to `Quit the board` and matching rows exactly fixed it.
- **The pilot harness was cropping one cell short, and it looked like a CSS bug.** `painted()` sized  
  its crop to the widget's content region and started it at the widget's origin — outside the  
  padding — so the rightmost character of any full-width row was never read. In Story 1 that  
  presented as the Projects column truncating `no-database` to `no-databas`, was diagnosed as  
  `width: auto` losing to the padding, and was worked around in CSS. **The workaround passed its  
  test, which is why it survived three stories.** Found in Story 5 only because a long absolute path  
  made the loss happen four times in one message and the missing characters spelled something.
- **A criterion that only one artefact can witness is a criterion with one point of failure.** Story  
  3's first criterion was carried entirely by the `reading…` label until a second witness was added:  
  a `tools/call` cannot arrive before the handshake it follows, so an empty call log in the  
  transcript at first paint says the handshake was outstanding, without reference to any label.
- **The ten-project criterion was not padding.** NFR3's single-project criterion passes against a  
  board that serialises; only the twelve-project one fails. It found a real defect on its first run.

### Patterns Worth Reusing

- **Assert from the rendered strips, never from the widget's own account.** Every reader in  
  `tests/support/pilot.py` goes through `render_lines()`. The palette is read from its `OptionList`  
  rather than from `BoardCommands`, because a correct provider inside a palette configured to show  
  Textual's commands is a passing unit test and a failing requirement.
- **Derive the other side of a comparison by running it.** The picker's refusal is checked against  
  what `run_cli(["add", …])` actually printed, in the same test. A transcribed message would be a  
  third copy of the sentence, and it would go on passing after both real ones had changed. Likewise  
  the system commands are asked of `App.get_system_commands()` rather than copied.
- **Inject what the app does not own.** `reader`, `survey`, `reload`, `register`, `unregister`,  
  `picker_root` — the app owns no pool and no registry file, so every test drives it without either,  
  and no default can reach the user's own projects. The pilot's `board()` passes them through rather  
  than enumerating them, so a story that adds one does not have to edit the harness.
- **Stamp the request, check it on the answer.** `_awaited[kind] = row.id` before a preview read and  
  again when it returns: a slow read for a row the cursor has left cannot paint over the row it is  
  on now. "Whichever read finished last" is a different rule and a wrong one.
- **A declarative table beside the code it dispatches to.** `COMMANDS` holds name, help and action;  
  a test checks every entry names an action the app actually has. A later epic adds its row beside  
  its `action_*` and both halves are one edit.
- **Assert "unchanged" as identity, not as equality.** The in-place registration test compares row  
  objects by `is`, because a re-survey replaces them with equal-looking rows that `==` accepts.
- **Refuse rather than default.** `style_for()` raises on an unknown state; a default would render  
  the row exactly like every other row, which on screen is indistinguishable from a working board.
- **Name the fixture rows by role.** `titled("open_epic", …)` rather than a transcribed title set —  
  a row added later joins an expectation only when someone says it plays that part.

### Scope Surprises

- **Story 1's second defect was misdiagnosed, and the wrong fix passed its test.** The `no-database`  
  truncation was the harness, not the CSS. The workaround was real code, shipped, with a comment  
  confidently stating a false cause; it took until Story 5 to find, and only because an unrelated  
  test made the same bug louder. Both the CSS and the epic's note have been corrected.
- **Four of Task 4.1's seven named actions were deliberately not built.** Register arrived in Story 5  
  of this epic, launch and attach belong to 48-05, search to 48-07. A palette entry that opens and  
  does nothing reports a capability the board does not have, and the user's next move is to find out  
  why nothing happened.
- **Story 2's task premise was half wrong** — `include_body` on the read tools, which have no such  
  argument. The task was still the right task; the surface it named was not the surface that exists.
- **CPM's `_suppress` cascade guard cannot be forked into Textual 8.** The app's own writes raise  
  `OptionHighlighted` through the message pump, so the event arrives *after* the flag is cleared and  
  a repaint that painted a column triggers a repaint that paints it again, without end. Guarding on  
  whether the index actually changed cannot come apart from the pump's timing.

## Recommendations

- **48-05 adds launch and attach to `COMMANDS`; add the `action_*` in the same edit.** The table is  
  the board's enumeration of what it can do, and the test that every entry names a real action is  
  what keeps a dead entry from shipping.
- **When a rendering assertion fails by one character, suspect the reader before the layout.** The  
  cost of the wrong guess here was a CSS workaround that lived three stories and a note in an epic  
  that was wrong for a day. `pilot.painted()` is now correct; the lesson is the order of suspicion.
- **For every must-NOT, ask what would have to exist for it to fail.** If nothing in the fixture  
  could trigger the forbidden behaviour, the test asserts nothing. Two of this epic's shipped green  
  and neither was visible by reading it — only by planting the behaviour and watching the test not  
  care.
- **Give a criterion a second witness when the first is a rendered string.** A label can be renamed  
  or removed and take a whole criterion's tests with it. Story 3's transcript check costs two lines  
  and does not depend on any wording.
- **A lock in `mcp_client.py` should be checked for what it is keyed on, not only for whether it is  
  held.** Both concurrency defects here were locks or their absence at the wrong granularity: one  
  missing per client, one too coarse per pool. 48-05 spawns processes of a different kind and will  
  meet the same question.
- **Run `node --test` in `dpm/` at the end of any epic that touched `dpm/`, even a board-only one.**  
  It stayed at 707 throughout, which is the point — the cost of knowing is one command.
