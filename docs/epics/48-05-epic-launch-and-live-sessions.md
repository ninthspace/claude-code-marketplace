# Launch, Attach and Live Sessions

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 48-04  
**Retro applied**: 42 · Criteria gaps · Applied — FR12's pill criterion is satisfied by a pill that lights up for any running tmux session; Story 4 adds the negative case, which is the only thing the `@dpm_launched` guard exists to make true.  
**Retro applied**: 42 · Criteria gaps · Applied — ENVX1 and ENVX5 assert that the board renders when a binary is absent, which is also true of a board that never looked; Story 5's third criterion pins the detection to the point of use so the degradation is attributable.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the two absences are named separately rather than as one "missing tooling" case, because they degrade differently: tmux falls back to copy, `claude` reports.  
**Retro applied**: 42 · Codebase discoveries · Applied — AD7's reasoning is CPM's launcher's, reused rather than rederived; the two distinct pieces are the session-name prefix and the guard option, which are what keep the two boards' sessions from claiming each other's.

The half of the board that does something. Four keys — launch, plain Claude, attach, copy — with the
target following whichever column has focus, every tmux call an argv list, and a pill telling the user
which projects already have a session running.

## Launch targets follow the focused column
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR8

**Acceptance Criteria**:

- Each focused column produces its documented launch target as an argv list [tdd] [unit]
- The Projects column produces a bare `/dpm:do`; the Epics and Stories columns produce the highlighted candidate's own command — `/dpm:do <epic>`, `/dpm:epics <spec>`, `/dpm:retro <epic>` [tdd] [unit]
- `l`, `o`, `t` and `c` reach launch, plain Claude, attach and copy respectively, from the board and from the palette [feature]

### Target resolution per column and candidate kind
**Task**: 1.1  
**Description**: `[tdd]` per the spec's tag. Four cases and they are not symmetric: the Projects column has no candidate and produces a bare command, while the other two produce the highlighted candidate's own — which means the candidate's *kind* decides the command, not the column.  
**Status**: Pending

### The four key bindings and their palette entries
**Task**: 1.2  
**Description**: `l`, `o`, `t`, `c`. Present in the palette as well as bound, so the capability is discoverable — a key binding nobody knows about is not an affordance.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [unit]` and `[feature]`. The enumeration criterion covers all four target shapes; asserting one column's target would pass on a resolver that ignores the column entirely.  
**Status**: Pending

---

## Create the tmux session
**Story**: 2  
**Status**: Pending  
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
**Status**: Pending

### Session naming and the `@dpm_launched` guard
**Task**: 2.2  
**Description**: `dpm-<project>-<id>` per AD7. The distinct prefix and the distinct guard option are the whole reason the two boards can run side by side without claiming each other's sessions; a shared name or a shared option would make each board's pills and attach behaviour wrong about the other's work.  
**Status**: Pending

### Quote the path and command into the single command string
**Task**: 2.3  
**Description**: The adversarial input is in the criterion for a reason: a path with a semicolon in it is the case where a string-built invocation runs something extra, and it is a path a user can plausibly have.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The "executes nothing extra" half needs a positive marker — a file the injected command would create — rather than an absence of errors.  
**Status**: Pending

---

## Attach to a live session
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR8, ENV6

**Acceptance Criteria**:

- `t` attaches to the most recently used live session for the selected project [integration]
- With several live sessions for one project, `t` picks the most recently used and not the first or last created [integration]

### Enumerate live sessions by name and activity
**Task**: 3.1  
**Description**: Scoped to the board's own session-name prefix and guard option. "Most recently used" is tmux's activity, not creation order — the distinction only shows up with three or more sessions.  
**Status**: Pending

### Attach this terminal
**Task**: 3.2  
**Description**: Attach rather than launch, so the user's current terminal joins the running session.  
**Status**: Pending

### Write tests for Story 3
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The fixture needs three sessions where most-recently-used is neither the first nor the last created, because with two of them the wrong rule is right half the time.  
**Status**: Pending

---

## Live session pills
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR12

**Acceptance Criteria**:

- A project with a running launched session shows a `● live` pill, carrying a count when several run [integration]
- The pill is dropped when the session ends or its window id changes [integration]
- A running tmux session the board did not launch produces no pill [integration]

### Poll live sessions off the UI thread
**Task**: 4.1  
**Description**: Per NFR3's rule, which applies to this read as much as to a tool call. Scoped by the guard option, so a CPM board session in the same project is not counted.  
**Status**: Pending

### Pill rendering with count
**Task**: 4.2  
**Description**: `● live`, with a count when several run. Dropped on session end or window-id change — the second is what catches a session that was replaced rather than closed.  
**Status**: Pending

### Write tests for Story 4
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The negative case is the load-bearing one: create a tmux session in the project without the guard option and assert no pill appears.  
**Status**: Pending

---

## Degrade without tmux or claude
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: ENVX1, ENVX5

**Acceptance Criteria**:

- With tmux absent from `PATH`, the board renders and the launch keys degrade to copy [integration]
- With `claude` absent from `PATH`, the board renders and the launch keys report the absence [integration]
- Both absences are detected at the point of use and reported per project, not as a startup refusal [integration]

### Detect each absence at the point of use
**Task**: 5.1  
**Description**: Not at startup. A board that refuses to start without tmux violates ENVX1 directly, and one that caches the answer at startup is wrong for the user who installs tmux while it is open.  
**Status**: Pending

### The two degraded behaviours
**Task**: 5.2  
**Description**: They differ. Without tmux the launch keys still do something useful — copy the command — because the command is still correct. Without `claude` there is nothing useful to fall back to, so the keys report.  
**Status**: Pending

### Write tests for Story 5
**Task**: 5.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Driven with a `PATH` the test controls; the assertions are on what the keys *do*, since "the board renders" is also true of a board that never looked for either binary.  
**Status**: Pending

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
