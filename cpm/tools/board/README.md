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
| blue    | ralph-selected for a `/cpm:ralph` run (see below)   |
| dim     | done / no planning artifacts                        |

Colour conveys status, so the status word is not repeated in the row text.

## Requirements

- [`uv`](https://docs.astral.sh/uv/) — runs the board and provisions its
  dependencies. Install with `curl -LsSf https://astral.sh/uv/install.sh | sh`.
- Python 3.11+ (uv will fetch a suitable interpreter if needed).
- The `claude` CLI on your `PATH` — only needed for **launching** sessions (`l`).
  Viewing the board does not require it.

The board is a [PEP 723](https://peps.python.org/pep-0723/) single-file script:
its runtime dependency (Textual) is declared inline and provisioned by `uv` on
first run. There is no separate install
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
| `l`     | Launch the target in a **new terminal window** (see below)  |
| `o`     | Open a plain Claude at the selected project's directory     |
| `c`     | Copy the launch command to the clipboard                    |
| `space` | Ralph-select the highlighted epic (toggle; see below)       |
| `a`     | Add a project — opens a directory picker (browse, don't type)|
| `x`     | Remove the highlighted project (confirm)                    |
| `z`     | Show / hide completed epics & stories                       |
| `r`     | Refresh — force a re-derive, bypassing the freshness cache  |
| `R`     | Clear the cache entirely, then rebuild                      |
| `q`     | Quit                                                        |

### Launch (`l`), open (`o`), and copy (`c`)

**`l` — launch in a new window.** The target session opens in a **new terminal
window** (macOS `osascript` + Terminal.app), so the board never blocks — good for
running several sessions at once. `c` copies the same command to the clipboard
instead. Both pick their target by the **focused column**, mirroring how `/cpm:do`
handles its own argument:

- **Projects column** → a bare `/cpm:do` (no epic) for the selected project —
  `cpm:do` discovers the next story itself.
- **Epics / Stories column** → the highlighted epic candidate's own command
  (`/cpm:do <epic>`, `/cpm:epics <spec>`, or `/cpm:retro <epic>`). A blocked or
  reference-only row falls back to a bare `/cpm:do`.

**`o` — open the project.** Opens a **plain** `claude` — no `/cpm` command — in a
new window at the selected project's directory. Use it when you just want a Claude
session in that project, not a specific CPM step. `o` ignores the focused column
and any ralph selection.

Everything runs in the selected project's working directory. Each command is built
shell-safely — the project path and command are `shlex.quote()`d, and a second
AppleScript-string escaping layer is added, with no shell at any layer — so a path
with spaces or metacharacters can neither break the command nor inject. On
platforms without new-window support yet, `l`/`o` show a notice; use copy (`c`).

### Ralph — autonomous multi-epic runs (`space` + launch)

`/cpm:ralph` runs several epics autonomously, one after another. To launch one
from the board, **ralph-select** the epics first: in the Epics column, press
`space` on each epic you want (only runnable `do` epics — the green/yellow ones —
qualify; blocked, retro and needs-epics rows can't be selected). Selected epics
turn **blue**; `space` again toggles one off. The selection is scoped to the
project in the Epics column and clears if you switch project.

While the selection is non-empty, `l` (and `c`) retarget: they build a single
**`/cpm:ralph <selected epics…>`** (paths project-relative, sorted into numeric
order) instead of a single-epic `/cpm:do`, and launch it in a new window — the
board stays free while ralph runs unattended. A launch consumes the selection.
Select nothing and the keys behave exactly as before. Each epic path is
`shlex.quote()`d for ralph's own argument parse, on top of the shell/AppleScript
layers, so the multi-epic command is built with no unescaped interpolation.

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
- `registry.py` — the XDG-aware project registry and its CLI.
- `cache.py` — the freshness cache.
- `board.py` — the Textual TUI that wires it all together.
