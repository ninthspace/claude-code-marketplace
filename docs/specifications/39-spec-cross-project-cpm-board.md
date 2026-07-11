# Spec: Cross-project CPM status board & launcher

**Date**: 2026-07-11
**Brief**: [Discussion 25 — cross-project CPM dashboard](../discussions/25-discussion-cross-project-cpm-dashboard.md)

## Problem Summary

Running many CPM projects means repeatedly asking "which projects need me, and what's the next move on each?" — a manual sweep through every repo's epic statuses. `/cpm:status` answers this for a *single* project but there is no *cross-project* view and no path from "that one" straight into the work. This spec defines a standalone, terminal-invoked TUI that reads an opt-in registry of projects, derives each project's CPM status itself (no Claude dependency), stays fresh by construction, renders a cross-project roll-up with drill-down, and launches the recommended next action — either by copying a shell-safe command to the clipboard or spawning the session directly.

## Functional Requirements

### Must Have

- **Opt-in registry** — `add` / `remove` / `list` the projects the board tracks. Explicit only; nothing auto-discovered.
- **Cross-project roll-up** — one screen, one row per project: name, overall state, story progress (e.g. 4/7), and its primary recommended next action. A project can have several candidate next actions at once (see the multi-action model in `cpm/shared/status-model.md`); the row shows the primary plus a count of any additional candidates, and drill-down lists the full ordered set.
- **Independent status derivation** — read each project's `docs/` + git directly to compute state per the shared status contract; zero Claude/skill invocation.
- **Freshness by construction** — on each run/tick, re-derive any project whose `git HEAD` or max `docs/` mtime changed since last seen; paint unchanged projects from cache.
- **Per-project drill-down** — expand a row in place to see its epics/stories and their statuses without leaving the board.
- **Two launch modes** — for the selected candidate action (defaulting to the project's primary): (a) copy the `cd /path && claude "/cpm:do …"` to the clipboard as a shell-safe string; (b) launch the session directly from the board. `attention:unblock` candidates have no command and are not launchable.
- **Watch mode** — auto-refresh on an interval using the cheap HEAD+mtime invalidation (not a full re-parse each tick).
- **RAG colour indicators** — green / amber / red per project state for at-a-glance scanning.
- **Attention-first ordering** — projects needing action (blocked, in-progress, spec-waiting-on-epics) sort above idle/complete ones.
- **Manual refresh** — a keypress forces a full re-derive, bypassing the cache.
- **Graceful degradation** — unreachable registry path → "unreachable" row; unparseable/half-written artifact → `?` state. One bad project never aborts the sweep.
- **Shared status contract** — a `cpm/shared/status-model.md` document authored alongside the board, defining the state vocabulary and derivation rules so the board never drifts from `/cpm:status`.

### Should Have
*(none held back — the should-haves from facilitation were promoted into Must Have: attention-first ordering, manual refresh.)*

### Could Have

- Configurable registry location (env var / flag)

### Won't Have (this iteration)

- Auto-discovery / filesystem scan for projects (registry is opt-in by design)
- Any Solo MCP / Solo-internal integration (Solo only hosts the process)
- Any mutation of project state (the board is strictly read-only)
- HTML / dashboard output (stays `/cpm:status`'s job)
- Multi-user / remote / networked operation
- Cross-platform clipboard (Windows/Linux) — macOS `pbcopy` first

## Non-Functional Requirements

### Performance

- Cached paint feels instant (sub-100ms perceived) for a dozen-plus projects.
- A changed project's re-derive (parse its `docs/` + one or two git calls) stays well under a second; a full cold sweep of ~15 projects stays in the low seconds.
- The render never blocks on the slowest project — degrade or defer, never stall the whole board.

### Reliability / Correctness

- Strictly read-only against every tracked repo: no writes, no git mutations, no lock contention with an active session running in that repo. Safe to run mid-work.

### Usability

- Keyboard-driven; legible over SSH and on a phone (Solo). No mouse dependency. Renders cleanly in an 80-column terminal.

### Portability

- Runs with `uv` and `git` on PATH. Dependency footprint managed by `uv` (single-file PEP 723 script) so "clone and run" holds.

### Security (hard must)

- The board interpolates registry paths and epic filenames into a launch command. The emitted command must be **shell-injection-safe**: the clipboard string is `shlex.quote()`d; direct launch uses an argument array (no shell string). A path with spaces, quotes, or shell metacharacters must neither break the command nor inject.

## Architecture Decisions

### 4.1 Runtime & UI framework
**Choice**: Python + [Textual](https://textual.textualize.io/) TUI framework, run via `uv` as a single-file PEP 723 script (inline dependency metadata; `uv run` provisions the env transparently).
**Rationale**: A true TUI needs an alternate screen buffer, raw-mode input, a flicker-free full-screen render loop, and resize handling. Textual is the strongest TUI platform in any language; `uv` makes a Python tool genuinely clone-and-run. The board is a standalone leaf sharing no code with the JS plugins, so language-consistency with the marketplace is a non-constraint — the repo's real ethos is zero *build step*, which `uv` + a pure-Python stack honours.
**Alternatives considered**: JS `blessed`/`terminal-kit` (dated, lower ceiling) — rejected as inferior TUI platforms chosen only for repo language-consistency, which is a fake constraint here. JS `Ink` (React/JSX) — rejected: needs a build step. Hand-rolled zero-dep ANSI — rejected: reimplements a TUI framework at high cost and lower UX ceiling.

### 4.2 Location & packaging
**Choice**: Bundle the code in the marketplace repo at `cpm/tools/board/`, for development convenience; extractable to its own repo later. Planning docs (this spec, its epics) live in the marketplace `docs/` tree.
**Rationale**: Start coupled, split on demand. Keeping it here during dev is simpler; nothing forces a separate repo yet. The `${CLAUDE_PLUGIN_ROOT}`-resolution caveat (retro 06) does not apply — the CLI is invoked directly and locates itself via the runtime, not from a skill's Bash.
**Alternatives considered**: Own repo from the start — deferred; the honest home for a standalone app eventually, but premature now.

### 4.3 Anti-drift status contract
**Choice**: Author `cpm/shared/status-model.md` defining the state vocabulary (`no-artifacts` / `spec-ready` / `epics-ready` / `in-progress` / `blocked` / `complete` / `unknown`), how epic `**Status**:` + story counts map to a state, and how the recommended next command is chosen (mirroring `/cpm:status`'s decision table). The board *implements* it in code; `/cpm:status` *references* it in prose.
**Rationale**: Two independent derivations of "status" will drift. Share the *definition*, not the code — one source of truth for state, separate implementations.
**Alternatives considered**: Reuse `/cpm:status`'s logic directly — rejected: a TUI can't block on a Claude skill invocation to compute a story count.

### 4.4 Freshness & cache storage
**Choice**: A single central cache under XDG (`~/.cache/cpm-board/`), keyed by project path. Freshness stamp = `git rev-parse HEAD` + max mtime under `docs/`. Re-derive only changed projects; manual refresh forces a full re-derive.
**Rationale**: Cache-with-cheap-invalidation gives "always fresh" and fast paint with no daemon and no per-repo hooks. A central cache keeps tracked repos' working trees clean.
**Alternatives considered**: Per-project manifest written into each repo's `docs/plans/` — rejected: litters tracked repos and needs a `.gitignore` chore everywhere. Note: mtime can miss a sub-second edit, mitigated by pairing with HEAD and the always-available manual refresh.

### 4.5 Registry
**Choice**: A JSON file at `~/.config/cpm-board/registry.json` (XDG), a list of `{ path, label? }`, managed by `add` / `remove` / `list` subcommands.
**Rationale**: Simple, explicit, opt-in; lives in user config, not in any tracked repo.
**Alternatives considered**: Auto-scan under a root — explicitly out of scope (opt-in by design).

### 4.6 Launch model
**Choice**: Both modes. Direct launch = `subprocess.run(['claude', '/cpm:do', epic_path], cwd=project_path)` — argument array, no shell. Clipboard = the same invocation built as a `shlex.quote()`d shell string, copied via `pbcopy`.
**Rationale**: Arg-array exec and `shlex.quote()` are stdlib and injection-safe by construction, directly satisfying the security hard-must. Clipboard suits Solo/mobile paste-into-new-pane; direct launch suits any terminal.
**Alternatives considered**: Exec-handover (replace the board process) — rejected: worse fit for Solo's pane model and mobile. Shell-string spawn — rejected: violates the security must.

## Scope

### In Scope

- Registry `add` / `remove` / `list` (opt-in projects only)
- Cross-project roll-up: per project — state, story progress, recommended next action
- Independent status derivation per `status-model.md` (no Claude dependency)
- Fresh-by-construction: git HEAD + `docs/` mtime invalidation, central XDG cache
- Per-project drill-down (expand to epics/stories)
- Two launch modes: shell-safe clipboard copy **and** direct `subprocess` launch
- Watch mode / auto-refresh on an interval
- RAG colour indicators
- Attention-first ordering
- Manual refresh keybinding
- Graceful degradation (unreachable path → row state; unparseable artifact → `?`)
- The shared `cpm/shared/status-model.md` contract doc (authored alongside)

### Out of Scope

- Auto-discovery / filesystem scan for projects
- Any Solo MCP / Solo-internal integration
- Any mutation of project state (strictly read-only)
- HTML / dashboard output
- Multi-user / remote / networked operation

### Deferred (future iterations)

- Extraction to its own repo
- Cross-platform clipboard (Windows/Linux) — macOS `pbcopy` first
- Configurable registry location (env var / flag)

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| Status derivation | Given a project's `docs/` tree + git state, produces the correct state + story counts per `status-model.md` | `[unit]` |
| Status derivation | Board and `/cpm:status` agree on state for the same project (contract conformance) | `[integration]` |
| Recommended next action | Emits the correct next command for each state (spec-ready→epics, epics-ready→do, etc.) | `[unit]` |
| Launch safety | Clipboard string is `shlex.quote()`d; direct launch uses an argument array | `[unit]` |
| Launch safety | must NOT emit or execute a command built by unescaped string interpolation of a path | `[unit]` |
| Freshness | Re-derives a project after its HEAD or `docs/` mtime changes; serves cache when unchanged | `[unit]` |
| Freshness | must NOT show stale state after a tracked project changes (bounded by watch interval / refresh) | `[integration]` |
| Graceful degradation | Unreachable registry path → "unreachable" row; malformed front-matter → `?` state | `[unit]` |
| Graceful degradation | must NOT abort the whole sweep because one project is bad | `[unit]` |
| Registry | `add` / `remove` / `list` persist correctly to the XDG registry file | `[unit]` |
| Read-only guarantee | A full sweep performs no writes/git mutations in any tracked repo | `[integration]` |
| Roll-up + drill-down + RAG | List renders, a row expands to epics/stories, RAG colours map to state | `[feature]` |
| Watch mode | Auto-refreshes on interval; screen updates without full reprint/flicker | `[manual]` — live-refresh *feel* is visual judgement automation can't confirm |
| Launcher end-to-end | Selecting a project spawns the session in the right cwd | `[manual]` — spawning a real `claude` session is external-process behaviour |

### Integration Boundaries

1. **Board ↔ `status-model.md` contract** — the conformance seam; the `[integration]` test that keeps board and `/cpm:status` from drifting.
2. **Board ↔ git + filesystem** — HEAD reads and `docs/` mtime stamping (driven by fixture repos).
3. **Board ↔ launch surface** — clipboard write and `subprocess` spawn (argument array).

### Test Infrastructure
This is the repo's first Python test setup. Items below become stories in `cpm:epics`:

- **pytest** as the runner.
- **Fixture project trees** — small fake repos with known `docs/` + git states, to drive derivation tests deterministically.
- **Textual Pilot** for the `[feature]` TUI test; optionally `pytest-textual-snapshot`.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
