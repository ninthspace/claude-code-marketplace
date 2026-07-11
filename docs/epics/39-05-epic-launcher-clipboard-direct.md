# Launcher: Clipboard & Direct

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Date**: 2026-07-11
**Status**: Complete
**Blocked by**: Epic 39-02-epic-status-derivation-engine, Epic 39-04-epic-tui-rollup-drilldown-watch
**Retro applied**: 09 · Patterns worth reusing · Applied — shell-safe command generation lives in a Textual-free `launcher.py`, unit-tested directly without the TUI.
**Retro applied**: 10 · Patterns worth reusing · Applied — Story 2 injects the clipboard writer + subprocess runner so copy/launch paths are tested with stubs; real `pbcopy`/`claude` spawn stays behind the seam.
**Retro applied**: 10 · Codebase discoveries · Applied — Story 2's [feature] copy test uses the known Textual 8.x accessors, not re-discovered ones.

## Shell-safe launch command generation [plan]
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Two launch modes, Launch safety (security hard-must)

**Acceptance Criteria**:

- The clipboard string is `shlex.quote()`d [unit]
- Direct launch uses an argument array (no shell string) [unit]
- must NOT emit or execute a command built by unescaped string interpolation of a path [unit]

### Build the shlex-quoted clipboard string
**Task**: 1.1
**Description**: Covers the clipboard-safety criterion — assemble the `cd <path> && claude "/cpm:do <epic>"` string with every interpolated path `shlex.quote()`d.
**Status**: Complete

### Build the argument array for direct execution
**Task**: 1.2
**Description**: Covers the direct-launch-safety criterion — produce the `['claude', '/cpm:do', epic]` arg vector and cwd for `subprocess`, never a shell string.
**Status**: Complete

### Write tests for launch safety
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit] — assert quoting and arg-array construction against paths containing spaces, quotes, and shell metacharacters; assert no unescaped interpolation path exists.
**Status**: Complete

**Retro**: [Pattern worth reusing] Keeping the two launch forms as pure functions in a Textual-free `launcher.py` let the security hard-must be proved with a `shlex.split` round-trip and a "differs from naive interpolation" assertion — no event loop, no subprocess spawn. The `command is None` guard (`NoCommandError`) puts the `attention:unblock` no-op contract on the module boundary rather than trusting each caller.

---

## Wire launch modes into TUI selection
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Two launch modes

**Acceptance Criteria**:

- A copy action puts the **selected candidate's** command on the clipboard via `pbcopy`, defaulting to the project's primary action when none is explicitly selected [feature]
- A launch action spawns the session for the **selected candidate** in the right cwd [manual] — spawning a real `claude` session is external-process behaviour outside the test harness
- must NOT launch or copy for an `attention:unblock` candidate (it has no command) — the action is disabled/ignored for those [feature]

### Bind the clipboard-copy action
**Task**: 2.1
**Description**: Covers the copy criterion — a keybinding that writes the shell-safe string for the selected candidate action (primary by default) to the clipboard via `pbcopy`; a no-op for `attention:unblock` candidates.
**Status**: Complete

### Bind the direct-launch action
**Task**: 2.2
**Description**: Covers the launch criterion — a keybinding that spawns the selected candidate's session via `subprocess.run([...], cwd=project_path)` with the arg array from Story 1; a no-op for `attention:unblock` candidates.
**Status**: Complete

### Write tests for the copy path
**Task**: 2.3
**Description**: Write automated tests covering the [feature] criterion — trigger copy under Textual Pilot with a stubbed clipboard and assert the correct command is written. (The real-session spawn criterion is `[manual]`.)
**Status**: Complete

**Retro**: [Pattern worth reusing] The injectable `clipboard_writer` + `runner` seams (retro 10) let the copy path and the launch *wiring* be asserted under Pilot with plain list-append stubs — no system clipboard, no real `claude` spawn — while the `command is None` guard in `_selected()` made the `attention:unblock` no-op a single check that both actions share, tested by pressing `c` and `l` on a blocked project and asserting neither stub fired.

---
