# Retro: Launch, Attach and Live Sessions

**Date**: 2026-08-14  
**Source**: docs/epics/48-05-epic-launch-and-live-sessions.md  
**Stories**: 5/5 complete

## Summary

This epic is the half of the board that does something: four keys — launch, plain Claude, attach,
copy — a real tmux session per launch, a `● live` pill on projects that have one running, and a
board that still works with neither tmux nor `claude` installed. The board's suite went from 145 to
183; `dpm`'s Node suite stayed at 707.

Almost everything difficult here was **tmux disagreeing with its own documentation**, and every one
of those disagreements was found by probing the running server rather than by reading. `-t` means a
pane on one command and a session on another, and rejects the `=name` exact-match form on a third.
`#{session_activity}` does not move when a detached session produces output — which is precisely
what a working Claude is — so "most recently used" had to be read from windows. None of this is
visible in code review; all of it is visible in one shell.

The second theme is **absences that assert nothing**, carried forward from 48-04 and still earning
its place. Story 5's requirements are two statements that the board renders with a binary missing,
and a board that never looks for either binary renders too. The criterion that makes them
attributable — detection at the point of use — is the one the epic added, and the test that carries
it changes `PATH` while the board is running.

## Observations

### Codebase Discoveries

- **tmux's `-t` is not one thing.** `attach-session` and `has-session` take the `=name` exact-match  
  form; the option commands (`show-options`, `set-option`) reject it with "not found", which reads  
  as a missing session rather than as the wrong syntax; and `display-message -t` is a *pane* target  
  that does not take a session name at all. The board's code is inconsistent because tmux is, and  
  each call site now says which rule it is following.
- **`#{session_activity}` does not move when a detached session produces output; `#{window_activity}`  
  does.** A session running Claude in the background is exactly the case, so "most recently used"  
  read from sessions would have ranked a busy session below an idle one that was attached last. The  
  enumeration is `list-windows -a -F` and a session's activity is the maximum of its windows'.
- **`list-windows -a -F` expands session options.** `#{@dpm_launched}` is available on a window row,  
  which is what lets one call answer both "is this ours" and "how recently was it used" — and lets  
  the pill and the attach share a single reader rather than two filters that can drift apart.
- **`if-shell -F '#{@dpm_launched}' cmd` fires only where the option is set**, server-wide, with no  
  false branch to write. That is the whole return-key guard: one binding, and it does nothing in a  
  session the board did not launch.
- **Textual's `run_test()` disables notifications by default.** Every `notify()` in this suite until  
  Story 5 was recorded on the app and never painted, because `Screen._extend_compose` only inserts a  
  `ToastRack` when `app._disable_notifications` is false. A test asserting on a report has to ask  
  for them; `pilot.board()` now takes `notifications=`.
- **`App.suspend()` raises `SuspendNotSupported` unless the driver can suspend**, which under the  
  test pilot it cannot. The attach path checks `self._driver.can_suspend` rather than catching the  
  refusal, so the check is the same shape as the tmux one: ask the thing that knows, at the point of  
  use.
- **A unix socket path has a hard length limit that pytest's nested `tmp_path` exceeds.** Every tmux  
  fixture here puts `TMUX_TMPDIR` under `/tmp` instead, and the failure it avoids surfaces two  
  layers down inside tmux with no mention of length.

### Testing Gaps

- **A behaviour deliberately implemented, and nothing asserted it.** Story 5's `t` reports rather  
  than degrading to copy — a decision with a paragraph of reasoning behind it — and removing that  
  branch passed the *entire* suite. The assertion was added and the mutation replanted. **The  
  mutation that survives is the one worth the time; a set of mutations that all fail has told you  
  nothing you did not already believe.**
- **Run planted mutations against the whole suite, not the story's own file.** One mutation here  
  survived `test_degradation.py` and was caught by Story 2's open-with-a-target test. Had it been  
  run per-file it would have read as a coverage gap, and the "fix" would have been a duplicate  
  assertion in the wrong story.
- **The apparatus can carry the bug under test.** The stand-in `claude` had its record paths written  
  into its own script text, and it is installed under project directories whose names contain quotes  
  and semicolons — so the quoting defect Story 2 exists to catch was planted in the harness, where  
  it presented as the board recording nothing. The paths moved into environment variables.
- **A launch returns before the thing it launched has run.** tmux has the session as soon as  
  `new-session` returns; the shell inside still has to `cd` and exec. Assertions polled for the  
  stub's file rather than sleeping, which is what keeps the tmux tests at 1.3s and not flaky.
- **Reading painted output after the app has exited raises, not fails.** `pill_of(app)` in an  
  assertion *message* threw `ScreenStackError` from outside the `async with`, replacing a legible  
  failure with a traceback. Every witness in this epic's tests is captured inside the block, message  
  strings included.

### Patterns Worth Reusing

- **Isolate through the environment, not through a seam in the code.** `TMUX_TMPDIR` and `PATH` are  
  set with `monkeypatch`, so the launcher runs the exact argv it runs in production and no user  
  session can be seen, named or killed. The first draft of `tmux_launcher` took `run=` and  
  `environment=` parameters that only tests passed; both were removed (retro 48).
- **Change the environment *while the app runs*.** The point-of-use criterion is unassertable from a  
  fixture that can only be arranged before startup. Three phases against one board — tmux absent,  
  present, absent — separate a board that decides at startup (fails phase two) from one that caches  
  the answer (fails phase three).
- **Give the middle of a three-phase test its own witness.** "tmux came back and the key used it" is  
  not provable from the clipboard, which a no-op launch also leaves untouched. The tmux stub records  
  its arguments, and `new-session` in that record is the positive evidence.
- **Degrade to an existing key's behaviour.** `c` needs neither binary, so it is what everything else  
  falls back to. A separate fallback path would be a second implementation of the command-building  
  rules, reachable only when tmux is missing — which is to say, almost never exercised.
- **One filter, one place.** The `@dpm_launched` check lives in `parse_sessions` alone, so the pill  
  and the attach cannot disagree about which sessions belong to this board. Two filters that must  
  match are a defect waiting for one of them to be edited.
- **Record rather than re-learn, when the point is to notice a change.** The pill drops on a window  
  id change because the board remembers the id it first saw and never updates it. Re-learning would  
  restore the pill one poll later and report a stranger's window as the board's own work.
- **Refuse rather than default, again.** A highlighted row with no candidate raises `NoTarget`  
  instead of falling back to the project's bare `/dpm:do`: the fallback launches a session about  
  something the user was not pointing at, and nothing on screen says so.
- **Name a fixture's sessions so the wrong rule cannot be right.** Story 3 uses three sessions a  
  second apart and *uses* the middle one, so newest-created and oldest-created are both wrong;  
  Story 4 asserts the count at three, because `● live 2` and a pill appending the count of anything  
  agree at two.

### Scope Surprises

- **Story 3's terminal handover is not covered by a test, and is recorded as a gap on the task.** A  
  real attach needs a controlling terminal; a test with one asserts on pytest's tty. What is covered  
  is the choice of session, the argv's target resolving against a real server, and `t` reaching the  
  launcher — the one line that hands the terminal over is not.
- **The pill needed the board to have memory, which no criterion implied.** "Dropped when the window  
  id changes" reads like a property of a poll and is not: a replaced session has the same name, the  
  same guard and the same directory, so nothing in a single poll distinguishes it.
- **`c` changed meaning mid-epic.** Story 1 copied the target; Story 2 made it copy the whole  
  `cd … && claude …` line, because a target alone is not a command anyone can run and a second  
  builder is a second set of quoting rules to get wrong. Story 5 then depends on that: the fallback  
  is only useful because what `c` copies is runnable.

## Recommendations

- **48-06 and 48-07 should keep the "ask at the point of use" habit for anything environmental.**  
  It cost nothing here — `shutil.which` per keypress — and it is the difference between a board that  
  is wrong for a session and one that is wrong for a keystroke.
- **When a tmux (or any external-tool) format string does not behave, probe the running server  
  before reasoning about it.** Two of this epic's three tmux surprises were documented behaviour  
  read correctly and still wrong for the case at hand.
- **Plant a mutation for every branch a task's note argues for.** The `t`-reports decision had a  
  paragraph of reasoning and no test; the reasoning is what should have prompted the check.
- **Prefer one enumeration answering several questions over one filter per consumer.** The pill and  
  the attach share `parse_sessions`; the next feature that asks "which sessions are ours" should  
  join them rather than add a third reader.
- **Check what the test harness turns off before concluding the app did not do something.** The  
  first sign that notifications were disabled was a toast query returning nothing, which reads  
  exactly like a board that never reported. No assertion had depended on them before, so the default  
  had cost nothing until the first criterion about what the user was *told*.
