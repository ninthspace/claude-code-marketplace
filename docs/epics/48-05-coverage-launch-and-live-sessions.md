# Coverage Matrix: Launch, Attach and Live Sessions

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-05-epic-launch-and-live-sessions.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR8 | "Each focused column produces its documented launch target as an argv list" | "Each focused column produces its documented launch target as an argv list" | Story 1 | `[tdd] [unit]` | |
| 2 | FR8 (added) | "The target follows the focused column: a bare `/dpm:do` from the Projects column, and the highlighted candidate's own command — `/dpm:do <epic>`, `/dpm:epics <spec>`, `/dpm:retro <epic>` — from the Epics or Stories column." | "The Projects column produces a bare `/dpm:do`; the Epics and Stories columns produce the highlighted candidate's own command — `/dpm:do <epic>`, `/dpm:epics <spec>`, `/dpm:retro <epic>`" | Story 1 | `[tdd] [unit]` | |
| 3 | FR8 (added) | "Launch as a tmux session (`l`), open a plain Claude at the project (`o`), attach this terminal to a running session (`t`), or copy the command (`c`)." | "`l`, `o`, `t` and `c` reach launch, plain Claude, attach and copy respectively, from the board and from the palette" | Story 1 | `[feature]` | |
| 4 | FR8 | "A launch creates a tmux session named `dpm-<project>-<id>` running in the project directory" | "A launch creates a tmux session named `dpm-<project>-<id>` running in the project directory" | Story 2 | `[integration]` | |
| 5 | ENV6 | "The launch and attach paths create and tear down a real tmux session during the suite" | "The launch and attach paths create and tear down a real tmux session during the suite" | Story 2 | `[integration]` | |
| 6 | AD7 | "tmux sessions named `dpm-<project>-<id>`, a `Ctrl-b o` return binding guarded on a `@dpm_launched` session option, and argv-list invocation throughout" | "A `Ctrl-b o` return binding is set on the launched session and guarded on a `@dpm_launched` session option, so a session the board did not launch is untouched" | Story 2 | `[integration]` | |
| 7 | NFR4 | "A project path containing spaces, quotes and a semicolon produces a correct argv and executes nothing extra" | "A project path containing spaces, quotes and a semicolon produces a correct argv and executes nothing extra" | Story 2 | `[unit]` | |
| 8 | NFR4 (must NOT) | "must NOT construct any tmux invocation as a shell string" | "must NOT construct any tmux invocation as a shell string" | Story 2 | `[unit]` | |
| 9 | FR8 | "`t` attaches to the most recently used live session for the selected project" | "`t` attaches to the most recently used live session for the selected project" | Story 3 | `[integration]` | |
| 10 | FR8 (added) | "attach this terminal to a running session (`t`)" | "With several live sessions for one project, `t` picks the most recently used and not the first or last created" | Story 3 | `[integration]` | |
| 11 | FR12 | "A project with a running launched session shows a `● live` pill, carrying a count when several run" | "A project with a running launched session shows a `● live` pill, carrying a count when several run" | Story 4 | `[integration]` | |
| 12 | FR12 | "The pill is dropped when the session ends or its window id changes" | "The pill is dropped when the session ends or its window id changes" | Story 4 | `[integration]` | |
| 13 | FR12 (added) | "A project with a running board-launched session shows a `● live` pill" | "A running tmux session the board did not launch produces no pill" | Story 4 | `[integration]` | |
| 14 | ENVX1 | "With tmux absent from `PATH`, the board renders and the launch keys degrade to copy" | "With tmux absent from `PATH`, the board renders and the launch keys degrade to copy" | Story 5 | `[integration]` | |
| 15 | ENVX5 | "With `claude` absent from `PATH`, the board renders and the launch keys report the absence" | "With `claude` absent from `PATH`, the board renders and the launch keys report the absence" | Story 5 | `[integration]` | |
| 16 | ENVX1, ENVX5 (added) | "Must not require tmux to view the board." / "Must not require a running Claude Code session or the `claude` CLI to view the board." | "Both absences are detected at the point of use and reported per project, not as a startup refusal" | Story 5 | `[integration]` | |

## Notes

**Rows 1 and 2 are the requirement and its enumeration.** Row 1 says each column produces "its documented
launch target", and the document is FR8's own body. A resolver that ignores the column and returns one
correct target passes row 1. Row 2 names all four shapes, including the asymmetry that matters — the
Projects column has no candidate, so the command comes from the column, while the other two take it from
the highlighted candidate's *kind*.

**Row 3 is FR8's reachability half.** Rows 1, 2, 4 and 9 are all about what the board computes and does;
none of them says a user can reach it. The four keys are named in FR8's body and asserted here, in the
palette as well as bound.

**Row 6 maps to AD7 rather than to a requirement,** because the guard option is an architecture decision
with no `FRn`. It is load-bearing rather than incidental: the distinct name prefix and distinct guard are
what keep this board and CPM's from claiming each other's sessions, and row 13 is where that becomes
observable.

**Row 13 is the negative case FR12 omits.** Rows 11 and 12 are satisfied by a pill that counts any running
tmux session in the project — which is what a board without the guard check does, and it would light up for
a CPM board's session. The requirement says *board-launched*; row 13 is the only row that tests that word.

**Row 7's "executes nothing extra" needs a positive marker.** An absence of errors is what a
correctly-quoted invocation and a silently-failing one both produce. The assertion is on a file the
injected command would have created, not on the command's exit status.

**Row 10's fixture needs three sessions.** "Most recently used" and "last created" agree whenever there are
two, and they are different rules. Row 9 keeps FR8's wording; row 10 is the case that distinguishes them.

**Row 16 is what makes rows 14 and 15 attributable.** Both assert that the board renders with a binary
absent, and a board that never looks for either binary renders too. Pinning detection to the point of use
rules out the startup check, which would satisfy neither restriction while appearing to satisfy both.

**NFR3 is not in this matrix although Story 4 obeys it.** The pill poll happens off the UI thread for the
same reason a tool call does, but NFR3's criteria are verified in
`docs/epics/48-04-coverage-browser-and-previews.md`. No row here claims that coverage.
