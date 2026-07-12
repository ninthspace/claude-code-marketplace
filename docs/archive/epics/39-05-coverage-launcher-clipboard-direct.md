# Coverage Matrix: Launcher: Clipboard & Direct

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Epic**: docs/epics/39-05-epic-launcher-clipboard-direct.md
**Date**: 2026-07-11

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Security (hard must) | the clipboard string is `shlex.quote()`d; direct launch uses an argument array (no shell string). A path with spaces, quotes, or shell metacharacters must neither break the command nor inject. | The clipboard string is `shlex.quote()`d; direct launch uses an argument array (no shell string); must NOT emit or execute a command built by unescaped string interpolation of a path | Story 1 | `[unit]` | ✓ |
| 2 | Two launch modes (clipboard) | (a) copy the recommended `cd /path && claude "/cpm:do …"` to the clipboard as a shell-safe string | A copy action puts the **selected candidate's** command on the clipboard via `pbcopy`, defaulting to the project's primary action when none is explicitly selected | Story 2 | `[feature]` | ✓ |
| 3 | Two launch modes (direct) | (b) launch the session directly from the board. | A launch action spawns the session for the **selected candidate** in the right cwd | Story 2 | `[manual]` | ✓ |
| 4 | Two launch modes (multi-action guard) | (a) copy the recommended `cd /path && claude "/cpm:do …"`; (b) launch the session directly from the board. | must NOT launch or copy for an `attention:unblock` candidate (it has no command) — the action is disabled/ignored for those | Story 2 | `[feature]` | ✓ |
