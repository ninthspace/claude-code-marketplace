# cpm board

A cross-project CPM status board & launcher — a standalone terminal UI (TUI) that
shows the state of every project you register and lets you launch the right
`/cpm:*` session for each one without leaving the board.

It reads each project's `docs/` planning artifacts **read-only** (specs, epics,
retros) and derives an overall state, progress, and an ordered list of candidate
next actions. Nothing here ever writes to, stages, or mutates a tracked repo.

## The three columns

A Miller-columns (ranger-style) browser:

```
┌ Projects ────────┬ Epics ───────────────────────┬ Stories ─────────────────┐
│ planwise · 103/… │ 94-03 · Device Registry · 0/3│ Blocked by:              │
│ marketplace · 1… │ 31-06 · Structure Tests · 2/3│ Epic waiting on 94-02-…  │
│                  │ 01-spec-… needs epics        │ Story 2 waiting on …     │
└──────────────────┴──────────────────────────────┴──────────────────────────┘
```

- **Projects** — every registered project, `name · progress`. Colour carries the
  state (see the legend below).
- **Epics** — for the selected project, the ordered launchable candidates (plus
  spec-breakdown and, with `z`, completed epics).
- **Stories** — for the selected epic, its outstanding stories. For a
  `needs epics` row it shows a preview of the spec file; for a **blocked** epic it
  shows what the epic is waiting on.

### Colour legend

The Epics column header shows it, and the Projects column uses the same palette:

| Colour  | Meaning                                             |
| ------- | --------------------------------------------------- |
| green   | ready to pick up                                    |
| yellow  | in progress                                          |
| red     | blocked (waiting on a dependency)                   |
| cyan    | complete, but no retrospective written yet (`retro`)|
| magenta | specs exist but no epics yet (`needs epics`)        |
| dim     | done / no planning artifacts                        |

Colour conveys status, so the status word is not repeated in the row text.

## Requirements

- [`uv`](https://docs.astral.sh/uv/) — runs the board and provisions its
  dependencies. Install with `curl -LsSf https://astral.sh/uv/install.sh | sh`.
- Python 3.11+ (uv will fetch a suitable interpreter if needed).
- The `claude` CLI on your `PATH` — only needed for **launching** sessions (`l`).
  Viewing the board does not require it.

The board is a [PEP 723](https://peps.python.org/pep-0723/) single-file script:
its runtime dependencies (Textual, and `pyte` for the embedded launch pane) are
declared inline and provisioned by `uv` on first run. There is no separate install
step.

## Running it

From the board directory (`cpm/tools/board/`):

```bash
uv run --script board.py            # launch the TUI
uv run --script board.py add PATH   # register a project (existence not required)
uv run --script board.py add PATH --label "My Label"
uv run --script board.py remove PATH
uv run --script board.py list       # list registered projects
uv run --script board.py refresh    # force-rebuild the status cache
uv run --script board.py refresh --clear   # delete the cache entirely
```

You can also register / remove projects from inside the TUI (`a` / `x`) — no need
to drop back to the shell. `a` opens a directory picker (browse with ↑/↓, `space`
to open a folder, `Enter` to select) so you never type a path by hand. It starts
from the selected project's parent directory — so sibling repos are right there —
falling back to your home directory when nothing is selected.

## Set up a shortcut

Running `uv run --script /long/path/board.py` every time is tedious. Add a shell
alias or function so you can just type `cpm-board`.

### bash / zsh

Add to `~/.bashrc` or `~/.zshrc` (adjust the path to where you cloned the repo):

```bash
# A function forwards arguments, so `cpm-board`, `cpm-board add ~/foo`,
# `cpm-board list` etc. all work.
cpm-board() {
  uv run --script "$HOME/Work/git/claude-code-marketplace/cpm/tools/board/board.py" "$@"
}
```

Or, if you prefer a plain alias (arguments still pass through):

```bash
alias cpm-board='uv run --script "$HOME/Work/git/claude-code-marketplace/cpm/tools/board/board.py"'
```

Then reload your shell (`exec $SHELL`) and use it from anywhere:

```bash
cpm-board add ~/Work/git/planwise
cpm-board                       # open the board
```

### fish

Add to `~/.config/fish/config.fish`:

```fish
function cpm-board
    uv run --script "$HOME/Work/git/claude-code-marketplace/cpm/tools/board/board.py" $argv
end
```

### Optional: run it directly

`board.py` has a `uv` shebang, so you can also make it executable and run it by
path:

```bash
chmod +x cpm/tools/board/board.py
./cpm/tools/board/board.py
```

## Keys (in the TUI)

| Key     | Action                                                      |
| ------- | ----------------------------------------------------------- |
| ↑ / ↓   | Move within the focused column                              |
| ← / →   | Move focus between columns                                  |
| Ctrl+P  | Command palette — opens straight to the board's actions     |
| `l`     | Launch **here** — embedded pane over epics + stories (below)|
| `i`     | Launch **full-screen** — suspend the board, run inline      |
| `L`     | Launch in a **new window** — detached terminal (see below)  |
| `c`     | Copy the launch command to the clipboard                    |
| F10     | Close the embedded session pane (when one is open)          |
| `a`     | Add a project — opens a directory picker (browse, don't type)|
| `x`     | Remove the highlighted project (confirm)                    |
| `z`     | Show / hide completed epics & stories                       |
| `r`     | Refresh — force a re-derive, bypassing the freshness cache  |
| `R`     | Clear the cache entirely, then rebuild                      |
| `q`     | Quit                                                        |

### Launch (`l` / `i` / `L`) and copy (`c`)

All four pick their target by the **focused column**, mirroring how `/cpm:do`
handles its own argument:

- **Projects column** → a bare `/cpm:do` (no epic) for the selected project —
  `cpm:do` discovers the next story itself. Launch straight from the project list
  without stepping into the Epics column.
- **Epics / Stories column** → the highlighted epic candidate's own command
  (`/cpm:do <epic>`, `/cpm:epics <spec>`, or `/cpm:retro <epic>`). A blocked or
  reference-only row falls back to a bare `/cpm:do`.

Three launch modes on that target:

- **`l` — launch here (embedded).** The session runs in a pane covering the epics
  + stories columns while the projects column and the board stay live. The pane is
  a real embedded terminal (PTY + `pyte`). Press **F10**, or exit the session, to
  close the pane and restore the columns. Best when you want the session and the
  board on screen together.
- **`i` — launch full-screen (inline).** The board suspends, `claude` runs
  full-size in this same terminal, and the board is restored exactly where you
  left it when the session exits. Best for a focused, one-at-a-time flow with no
  pane cramping.
- **`L` — launch in a new window (detached).** On macOS (`osascript` +
  Terminal.app) the session opens in its own window and the board never blocks —
  good for running several sessions at once. On platforms without detached
  support yet, `L` shows a notice; use `l`/`i` or copy (`c`) instead.

Everything runs in the selected project's working directory. Each command is built
shell-safely — the project path and command are `shlex.quote()`d, and the detached
path adds a second AppleScript-string escaping layer, with no shell at any layer —
so a path with spaces or metacharacters can neither break the command nor inject.

> **Note:** the embedded pane (`l`) is a spike. The core pipeline (colour, cursor,
> keys, resize, alt-screen, F10 close) works, but nesting a heavyweight full-screen
> child like `claude` inside a sub-pane can still show rough edges vs. `i`/`L`.

## Where its data lives

- **Registry** (the projects you've added):
  `$XDG_CONFIG_HOME/cpm-board/registry.json` (default
  `~/.config/cpm-board/registry.json`).
- **Status cache** (per-project derived status, keyed by absolute path):
  `$XDG_CACHE_HOME/cpm-board/` (default `~/.cache/cpm-board/`). Freshness is
  stamped on git `HEAD` + `docs/` mtimes; a schema bump invalidates old entries.
  Clear it with `R` in the TUI or `refresh --clear` on the CLI.

## Development

The `pyproject.toml` exists for development and testing only — it provisions the
test harness. Run the suite from this directory:

```bash
uv run pytest -q
```

The code is split so the security- and logic-critical parts are Textual-free and
unit-tested without a UI event loop:

- `status_model.py` — read-only derivation engine (state, progress, next actions).
- `board_view.py` — pure view helpers (labels, colours, row projections).
- `launcher.py` — shell-safe launch command / argv generation.
- `embedded_terminal.py` — the PTY terminal widget for the embedded launch pane (`l`).
- `registry.py` — the XDG-aware project registry and its CLI.
- `cache.py` — the freshness cache.
- `board.py` — the Textual TUI that wires it all together.
