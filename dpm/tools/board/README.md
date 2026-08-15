# DPM board

A cross-project DPM status board and launcher — a standalone terminal UI that shows
the state of every project you register and launches the right `/dpm:*` session for
each one without leaving the board.

**It is an MCP client and nothing else.** Everything it knows about a project arrives
as a `tools/call` response from a `bin/dpm-mcp.js` spawned at that project's root. It
opens no SQLite connection, reads no file under a project's `docs/` or `.dpm/`, and
parses no markdown. That is what makes its answers exact rather than inferred: a
blocked epic *names* its blocker from a `dependency` row instead of having one guessed
from a `**Blocked by**` line.

**Observing a project leaves it byte-identical.** The server is spawned with
`DPM_READ_ONLY=1`, no mutating tool is ever called, and a project with no
`.dpm/dpm.db` is not spawned against at all — so pointing the board at a directory
never brings a database into existence there. The only two things the board writes
are its registry and its cache, both under the XDG config directory.

## Running it

There is no install step — `board.py` is a PEP 723 single-file script and `uv`
provisions it on first run.

```sh
uv run dpm/tools/board/board.py            # the TUI
uv run dpm/tools/board/board.py list
uv run dpm/tools/board/board.py add PATH
uv run dpm/tools/board/board.py remove PATH
```

Registration also works from inside the TUI (`Ctrl+N` opens a directory picker). The
registry lives at `$XDG_CONFIG_HOME/dpm-board/registry.json` (or
`~/.config/dpm-board/…`); a registered path that is no longer a directory is pruned on
launch.

**Requires:** Python 3.11 or later and `uv`, plus Node 22.5.0 or later for the servers
it spawns.

## The three columns

A Miller-columns browser — Projects → Epics → Stories — with a preview panel beneath
the Epics and Stories columns:

```
┌ Projects ─────────────┬ Epics ──────────────────────┬ Stories ─────────────────┐
│ marketplace · 41/44   │ 48-08 · Coverage gaps · 0/4 │ Story 1 · Derive gaps    │
│   ● live  ⚠ integrity 2│ 49-01 · Deferred create·3/3│ Story 2 · Render them    │
│ planwise · 12/30      │ 50-spec-… needs epics       │                          │
│                       ├─────────────────────────────┼──────────────────────────┤
│                       │ # Coverage gaps             │ ## Story 2               │
│                       │ …read_epic with include_body│ …this story's criteria   │
└───────────────────────┴─────────────────────────────┴──────────────────────────┘
```

- **Projects** — every registered project as `name · stories done/total`, with colour
  carrying state: green *ready*, yellow *in progress*, red *blocked*.
- **Epics** — the selected project's launchable candidates, ordered: ready epics
  first, then specs with no epics, then complete epics with neither a retro nor a
  recorded waiver. The preview renders what `read_*` and `preview_document_kind`
  return, never a projected `.md` file.
- **Stories** — the selected epic's outstanding stories; the preview renders that
  story's own acceptance criteria and tasks as rows.

Two markers can appear on a project row. `● live` means a board-launched session is
running (with a count when several are), and `⚠ integrity 2` is what `check_integrity`
reported for that project's database — a count of broken register rows and orphaned
rows together. A project with nothing wrong carries neither.

A project the board cannot read is a **state, not a crash**: a missing database, a
schema version ahead of the server, a Node below DPM's floor, a server that failed to
start, a server that is not installed, and a tool surface that does not match each
render as a named state carrying its remedy, and every other project still renders.

## Keys

| Key | What it does |
|---|---|
| `l` | Launch the focused column's command in a tmux session |
| `o` | Open Claude at the project with no command |
| `t` | Attach this terminal to a running session |
| `c` | Copy the focused column's command to the clipboard |
| `space` | Select a runnable epic — while the selection is non-empty the launch keys build one `/dpm:ralph <epics…>` instead |
| `Ctrl+F` | Search prose across every registered project, navigable back to the project and epic it came from |
| `Ctrl+G` | Coverage gaps — every requirement no coverage row names, with the spec it belongs to |
| `Ctrl+N` | Register a project |
| `Ctrl+P` | Command palette, opening straight to the board's own actions |
| `R` | Re-read every project, ignoring the cache |
| `Ctrl+K` | Clear the cache, here and on disk |
| `q` | Quit |

The launch target follows the focused column: a bare `/dpm:do` from the Projects
column, and the highlighted candidate's own command — `/dpm:do <epic>`,
`/dpm:epics <spec>`, `/dpm:retro <epic>` — from Epics or Stories.

## The cache

Derived per-project status is cached at `$XDG_CONFIG_HOME/dpm-board/cache.json` and
invalidated by the database file's own mtime and size, so a project whose database has
not moved is not re-read. `R` forces a re-read anyway; `Ctrl+K` forgets everything.

## Development

```sh
cd dpm/tools/board
uv run pytest
```

`pyproject.toml` provisions the test harness only — what ships is `board.py`,
provisioned by the PEP 723 block at the top of it. The dependency lists in the two
files are held identical by the suite, because a package the tests have and the board
does not is how an import that works everywhere in CI fails on the first real run.

The derivation rules the board implements are written down in
[`dpm/shared/status-model.md`](../../shared/status-model.md) and reconciled against the
code in both directions: a rule with no implementation fails, and an implementation
with no rule fails.

Spec: `docs/specifications/48-spec-dpm-board.md`, built across `docs/epics/48-*`.
