# Launch, Attach and Live Sessions

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 48-04  
**Retro applied**: 42 · Criteria gaps · Applied — FR12's pill criterion is satisfied by a pill that lights up for any running tmux session; Story 4 adds the negative case, which is the only thing the `@dpm_launched` guard exists to make true.  
**Retro applied**: 42 · Criteria gaps · Applied — ENVX1 and ENVX5 assert that the board renders when a binary is absent, which is also true of a board that never looked; Story 5's third criterion pins the detection to the point of use so the degradation is attributable.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the two absences are named separately rather than as one "missing tooling" case, because they degrade differently: tmux falls back to copy, `claude` reports.  
**Retro applied**: 42 · Codebase discoveries · Applied — AD7's reasoning is CPM's launcher's, reused rather than rederived; the two distinct pieces are the session-name prefix and the guard option, which are what keep the two boards' sessions from claiming each other's.  
**Retro applied**: 50 · Testing gaps · Applied — Story 2's shell-string must-NOT and Story 4's un-guarded-session must-NOT each get a planted positive (a path whose injected fragment would create a marker file; a real tmux session in the project without the guard option), so the absence they assert is an absence that could have failed.  
**Retro applied**: 50 · Patterns worth reusing · Applied — Task 1.2 adds the four launch rows to `COMMANDS` in the same edit as their `action_*` methods, so Story 4 of 48-04's "every entry names a real action" test covers them unchanged.  
**Retro applied**: 50 · Patterns worth reusing · Applied — Story 4's pill criteria are read from the painted Projects column through `pilot.strips()`, never from a `ProjectView` field; the count is asserted as painted text.  
**Retro applied**: 50 · Testing gaps · Applied — the `● live` pill and Story 5's degrade-to-copy each get a second, wording-independent witness (the enumerated session list; the copied payload), so renaming a rendered string cannot take a criterion with it.  
**Retro applied**: 48 · Codebase discoveries · Applied — the tmux launch inherits the same scrubbed environment the server pool uses, so a session started in one project cannot carry a `DPM_DATABASE` naming another's file; asserted from the reported environment rather than from the spawn code.  
**Retro applied**: 48 · Patterns worth reusing · Applied — session existence, the `@dpm_launched` option, the return binding and the working directory are read back with real `tmux` calls and never from the board's own record of what it did; teardown asks tmux too.

The half of the board that does something. Four keys — launch, plain Claude, attach, copy — with the
target following whichever column has focus, every tmux call an argv list, and a pill telling the user
which projects already have a session running.

## Launch targets follow the focused column
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR8

**Acceptance Criteria**:

- Each focused column produces its documented launch target as an argv list [tdd] [unit]
- The Projects column produces a bare `/dpm:do`; the Epics and Stories columns produce the highlighted candidate's own command — `/dpm:do <epic>`, `/dpm:epics <spec>`, `/dpm:retro <epic>` [tdd] [unit]
- `l`, `o`, `t` and `c` reach launch, plain Claude, attach and copy respectively, from the board and from the palette [feature]

### Target resolution per column and candidate kind
**Task**: 1.1  
**Description**: `[tdd]` per the spec's tag. Four cases and they are not symmetric: the Projects column has no candidate and produces a bare command, while the other two produce the highlighted candidate's own — which means the candidate's *kind* decides the command, not the column.  
**Status**: Complete  
**Note**: `launcher.py` — `launch_target(column, candidate)` returning argv, with `CANDIDATE_COMMANDS` keyed on 48-03's `CANDIDATE_KINDS` so a kind added to the model has no command here and is refused rather than defaulted. `Candidate`'s own docstring made the handoff explicit ("the command each maps to is FR8's and belongs to the launcher"), and `retro_missing` carries the *epic's* id — which is what `/dpm:retro` takes, and the reason the argument comes off the candidate rather than off the row. A row with no candidate raises `NoTarget` instead of falling back to the project's bare `/dpm:do`: that fallback launches a session about something the user was not pointing at, with nothing on screen saying so. `EpicView` gained `candidate`, filled in `read_view` from `candidates()` — two more unscoped reads (`list_spec`, `list_retro`, both already declared) rather than a second implementation of FR9's rule in the view.

### The four key bindings and their palette entries
**Task**: 1.2  
**Description**: `l`, `o`, `t`, `c`. Present in the palette as well as bound, so the capability is discoverable — a key binding nobody knows about is not an affordance.  
**Status**: Complete  
**Note**: Four `COMMANDS` rows added in the same edit as their `action_*` methods (retro 50), so 48-04's "every entry names an action the app has" test covered them without being touched. Launching is injected — `BoardApp(launch=…)` receives `(intent, project, target)` — because the app owns no tmux server any more than it owns a pool; Story 2 binds the real one. `open` and `attach` carry no target by definition: they are about the project, not about a row.

### Write tests for Story 1
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [unit]` and `[feature]`. The enumeration criterion covers all four target shapes; asserting one column's target would pass on a resolver that ignores the column entirely.  
**Status**: Complete  
**Note**: `tests/test_launch_targets.py`, 12 tests; board suite 145 → 157. The four shapes are asserted as one dict rather than as four tests, because the requirement is the enumeration and a per-shape set makes one wrong command a green suite with a red line in it. Six planted defects, each failing: the column ignored when a candidate exists; a missing candidate defaulting to the project's target; `" ".join` in place of `shlex.join`; a candidate kind with no command; `c` bound to `launch`; and `read_view` carrying no candidate — the last of which nothing else would have caught, since every other test builds its own rows. The palette half is driven through the palette's own UI (typed, highlighted, entered) rather than by dispatching the action, because an entry whose callable was built wrongly runs nothing.

---

## Create the tmux session
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR8, NFR4, ENV6, AD7

**Acceptance Criteria**:

- A launch creates a tmux session named `dpm-<project>-<id>` running in the project directory [integration]
- The launch and attach paths create and tear down a real tmux session during the suite [integration]
- A `Ctrl-b o` return binding is set on the launched session and guarded on a `@dpm_launched` session option, so a session the board did not launch is untouched [integration]
- A project path containing spaces, quotes and a semicolon produces a correct argv and executes nothing extra [unit]
- must NOT construct any tmux invocation as a shell string [unit]

### Argv-list tmux invocation throughout
**Task**: 2.1  
**Description**: NFR4: no shell at any layer of the board's own code. The one string tmux is given is the `cd … && claude …` command it runs itself, and the path and command are quoted into it — that is the single place quoting happens, which is what makes it reviewable.  
**Status**: Complete  
**Note**: `tmux_plan()` returns the four invocations a launch makes as argv lists and `run_plan()` runs them, raising `LaunchFailed` with what tmux said. The plan is *returned* rather than run so a launch is comparable rather than only observable. `new-session` carries the project directory as an argv element (`-c`) as well as in the command's own `cd`: tmux reads `-c` for `#{session_path}`, and the `cd` is what makes the copied line runnable on its own.

### Session naming and the `@dpm_launched` guard
**Task**: 2.2  
**Description**: `dpm-<project>-<id>` per AD7. The distinct prefix and the distinct guard option are the whole reason the two boards can run side by side without claiming each other's sessions; a shared name or a shared option would make each board's pills and attach behaviour wrong about the other's work.  
**Status**: Complete  
**Note**: `session_name()` sanitises the project's directory name to tmux's character set (`.` and `:` are address separators) and falls back to a word on each side, because an empty result gives `dpm--` — a name about nothing that every later launch collides with. The `@dpm_launched` guard is set on the session and tested by the `Ctrl-b o` binding through `if-shell -F`, which is server-wide with no false branch. tmux's own targeting is inconsistent and the code has to be: `attach` and `has-session` take the `=name` exact-match form, while the option commands reject it with "not found".

### Quote the path and command into the single command string
**Task**: 2.3  
**Description**: The adversarial input is in the criterion for a reason: a path with a semicolon in it is the case where a string-built invocation runs something extra, and it is a path a user can plausibly have.  
**Status**: Complete  
**Note**: `launch_command()` is the only place a value is interpolated into text in the whole launch path: the project path and the target go through `shlex.quote`, the target as a *single* argument (`claude '/dpm:do 48-05'`), and everything else tmux is handed is an argv element no shell sees. `c` now copies this same line rather than the target alone — a target on its own is not a command anyone can run, and a second builder would be a second set of quoting rules to get wrong.

### Write tests for Story 2
**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The "executes nothing extra" half needs a positive marker — a file the injected command would create — rather than an absence of errors.  
**Status**: Complete  
**Note**: `tests/test_tmux.py`, 10 tests, 1.3s; suite 157 → 167. Real tmux on a server of the suite's own — `TMUX_TMPDIR` in the inherited environment, so the launcher runs the argv it runs in production and no user session can be seen, named or killed. A stand-in `claude` on `PATH` records its arguments and its directory, which is how "quoted correctly" is asserted from the far side of the shell tmux runs rather than from the string the board built; its record paths arrive as environment variables, because the project directories here contain quotes and a path interpolated into the stub's own script is the very bug being tested, planted in the apparatus. The guard is checked twice — the binding's text carries `#{@dpm_launched}`, and the same expression is *run* against a launched session and a stranger session, one firing and one not. Five planted defects, each failing: `new-session` without `-c`; the option not set; the binding unguarded; the path unquoted; the target unquoted (which arrives at Claude as two arguments). The shell sweep carries its own planted control.

---

## Attach to a live session
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR8, ENV6

**Acceptance Criteria**:

- `t` attaches to the most recently used live session for the selected project [integration]
- With several live sessions for one project, `t` picks the most recently used and not the first or last created [integration]

### Enumerate live sessions by name and activity
**Task**: 3.1  
**Description**: Scoped to the board's own session-name prefix and guard option. "Most recently used" is tmux's activity, not creation order — the distinction only shows up with three or more sessions.  
**Status**: Complete  
**Note**: `live_sessions()` reads `list-windows -a`, not `list-sessions`: **`#{session_activity}` does not move when a detached session produces output**, and a detached session producing output is exactly what a working Claude is — `#{window_activity}` does move, and a session's activity is its windows'. Scoping is by `#{session_path}` rather than by the project name inside the session's own name, because two registered projects can share a directory basename and the name would put one project's sessions on the other's row. The guard-option filter lives in `parse_sessions` alone, so the pill (FR12) and the attach cannot disagree about which sessions are the board's. No tmux server exits non-zero and so does a missing tmux; both are "no live sessions" rather than an error, or `t` would report a failure every time it was pressed before anything was launched.

### Attach this terminal
**Task**: 3.2  
**Description**: Attach rather than launch, so the user's current terminal joins the running session.  
**Status**: Complete  
**Note**: The app hands the terminal over — `BoardApp._foreground` wraps only the attach intent in `App.suspend()`, because two programs painting one screen is neither readable — and the launcher runs `tmux attach` with output *not* captured, since the point of the call is that tmux draws on this terminal. Inside tmux the argv is `switch-client` instead: a client cannot nest.  
**Gap**: the one line that hands the terminal over is not driven by a test. A real attach needs a controlling terminal, and a test with one would be asserting on pytest's own tty. What is covered is the choice (`attach_target` over a real three-session server), the argv's target resolving against that server (Story 2), and `t` reaching the launcher with the selected project.

### Write tests for Story 3
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The fixture needs three sessions where most-recently-used is neither the first nor the last created, because with two of them the wrong rule is right half the time.  
**Status**: Complete  
**Note**: `tests/test_attach.py`, 6 tests; suite 167 → 173. The three sessions are created a second apart because tmux's activity clock counts whole seconds, and the middle one is *used* — `send-keys`, the way a user makes a session recent — after all three exist, so newest-created and oldest-created are both wrong. The stranger-session control shares the project directory and is newer than the board's own, so every rule but the guard would choose it. Three planted defects, each failing: ordering by name; the guard filter dropped; the project scope dropped.

---

## Live session pills
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR12

**Acceptance Criteria**:

- A project with a running launched session shows a `● live` pill, carrying a count when several run [integration]
- The pill is dropped when the session ends or its window id changes [integration]
- A running tmux session the board did not launch produces no pill [integration]

### Poll live sessions off the UI thread
**Task**: 4.1  
**Description**: Per NFR3's rule, which applies to this read as much as to a tool call. Scoped by the guard option, so a CPM board session in the same project is not counted.  
**Status**: Complete  
**Note**: One `tmux list-windows` answers for the whole board, in a worker over `asyncio.to_thread` — a spawn on the UI thread is a board that stops repainting while it happens, which is NFR3's rule about tool calls holding for the same reason. Polled on a 2s interval rather than driven by the board's own launches: the answer changes without the board doing anything, and a pill that only moved when a key was pressed would go on reporting a session the user quit. The reader is injected like the survey is, and for a sharper reason — with a default, every test that stands the app up would ask the *user's* tmux server what is running and paint whatever it found.

### Pill rendering with count
**Task**: 4.2  
**Description**: `● live`, with a count when several run. Dropped on session end or window-id change — the second is what catches a session that was replaced rather than closed.  
**Status**: Complete  
**Note**: The count appears only above one: `● live 1` invites the reader to work out what the other number would have been. The window-id half needs *memory* rather than a count — a replaced session has the same name, the same guard option and the same project, so nothing about the current poll distinguishes it. The board records each session's window id on first sighting and never updates it: re-learning the new id would put the pill back a poll later and report someone else's window as the board's own work. A board restarted while sessions run re-learns them, which is what keeps the pill useful across restarts.

### Write tests for Story 4
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The negative case is the load-bearing one: create a tmux session in the project without the guard option and assert no pill appears.  
**Status**: Complete  
**Note**: `tests/test_pills.py`, 6 tests; suite 173 → 179. Every criterion is read from the *painted* Projects column (retro 50). The negative case has the forbidden condition actually present — a real session, running, in the project's own directory, missing only the mark — and a positive control in the same test, so an absent pill cannot be a poll that never ran. The count is asserted at three: `● live 2` and a pill that appends the count of anything agree at two. Two planted defects, each failing: window ids untracked (the replacement keeps its pill); a single poll instead of an interval (nothing is ever dropped).

---

## Degrade without tmux or claude
**Story**: 5  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: ENVX1, ENVX5

**Acceptance Criteria**:

- With tmux absent from `PATH`, the board renders and the launch keys degrade to copy [integration]
- With `claude` absent from `PATH`, the board renders and the launch keys report the absence [integration]
- Both absences are detected at the point of use and reported per project, not as a startup refusal [integration]

### Detect each absence at the point of use
**Task**: 5.1  
**Description**: Not at startup. A board that refuses to start without tmux violates ENVX1 directly, and one that caches the answer at startup is wrong for the user who installs tmux while it is open.  
**Status**: Complete  
**Note**: `available(binary)` — `shutil.which` asked inside the launch closure, on every keypress, and the answer never kept. Both checks live at the top of `tmux_launcher`'s `launch()` rather than anywhere the app can reach: the board has no detector to be wrong, and there is nothing to invalidate when tmux is installed while it is open. Claude is checked *before* tmux, which is an ordering with a consequence: with both absent, a tmux-first check would put a command on the clipboard that cannot run wherever it is pasted, and would say the wrong thing about why.

### The two degraded behaviours
**Task**: 5.2  
**Description**: They differ. Without tmux the launch keys still do something useful — copy the command — because the command is still correct. Without `claude` there is nothing useful to fall back to, so the keys report.  
**Status**: Complete  
**Note**: `Degraded` carries the command and the project it is about and is *not* a `LaunchFailed` — the command was built successfully and is still right, so the board copies it and warns rather than reporting an error. `c` is deliberately what everything degrades to: it needs neither binary, so the fallback is an existing key's behaviour rather than a second path. `t` is the exception and reports in both cases: a command on the clipboard is not an attach, and without tmux there is no session to join.

### Write tests for Story 5
**Task**: 5.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Driven with a `PATH` the test controls; the assertions are on what the keys *do*, since "the board renders" is also true of a board that never looked for either binary.  
**Status**: Complete  
**Note**: `tests/test_degradation.py`, 4 tests; suite 179 → 183. `PATH` points at a directory holding exactly the stubs a test provides, and it is rewritten *while the board runs* — the point-of-use test goes tmux-absent, tmux-present, tmux-absent against one running board, which is what separates a board that decides at startup (fails the second phase) from one that caches the first answer (fails the third). The middle phase has a witness of its own, because a launch that quietly did nothing would leave the clipboard untouched too. Reports are read from the painted toasts rather than from `app._notifications`, which meant `pilot.board()` gained a `notifications` flag: `run_test` disables them by default, so every report in this suite until now was recorded and never painted. Six planted defects. Four failed as written: availability cached; tmux checked before claude; the degraded arm notifying without copying; and the report dropping the project's name. Two did not, and each says something. `t` degrading to copy survived the *whole* suite — a behaviour deliberately implemented in Task 5.2 that nothing asserted, so an assertion was added and the mutation replanted to confirm it bites. The intent ignored when building the command survived this file but was caught by Story 2's open-with-a-target test, which is only visible because the mutations were run against the whole suite rather than against the story's own.

---

## Notes

**Step 3c — integration testing story: skipped.** *Board ↔ tmux* is one of the spec's five integration
boundaries and it is this epic's entire subject — Stories 2, 3 and 4 each drive a real tmux session per
ENV6, which is what a cross-story integration story would do. The stories are sequential rather than
components that must interoperate, and the one cross-cutting property, argv-list construction, is
asserted in Story 2 over every invocation rather than per call site.

**Story 4's third criterion is added.** FR12's criteria are satisfied by a pill that appears for any
running tmux session in the project, which is exactly what a board without the `@dpm_launched` guard
does — and it would then light up for a CPM board's session. AD7 names the guard; nothing in FR12's own
criteria makes it load-bearing.

**Story 5's third criterion is added.** ENVX1 and ENVX5 both assert that the board renders when a binary
is absent, and a board that never looks for either binary renders too. Pinning detection to the point of
use makes the degradation attributable to the absence, and it rules out the startup check — which would
satisfy neither requirement while appearing to satisfy both.

**Story 1's second criterion enumerates what "documented" means.** FR8's criterion says each column
produces "its documented launch target", and the document is FR8's own body. Enumerating the four shapes
in the criterion is what stops the assertion being satisfied by one column's target resolved correctly and
three ignored.

**Story 3's fixture needs three sessions, not two.** "Most recently used" and "last created" agree
whenever there are two, and they are different rules. The criterion names the case where they differ.
