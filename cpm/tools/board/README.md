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
│ planwise · 103/… │ 94-03 · Device Registry · 0/3│ Story 1 · Schema         │
│ marketplace · 1… │ 31-06 · Structure Tests · 2/3│ Story 2 · Endpoint       │
│                  │ 01-spec-… needs epics        │                          │
│                  ├──────────────────────────────┼──────────────────────────┤
│                  │ # Device Registry            │ ## Story 2               │
│                  │ **Status**: In Progress      │ **Status**: In Progress  │
│                  │ …the epic/spec/retro file…   │ …this story's section    │
└──────────────────┴──────────────────────────────┴──────────────────────────┘
```

- **Projects** — every registered project, `name · progress`. Colour carries the
  state (see the legend below).
- **Epics** — for the selected project, the ordered launchable candidates (plus
  spec-breakdown and, with `z`, completed epics). Below the list, a **preview
  panel** renders the highlighted row's source file — its epic / spec / retro
  `.md` — as markdown; for a **blocked** epic it is prefaced with what the epic is
  waiting on.
- **Stories** — for the selected epic, its outstanding stories. Below the list, a
  preview panel renders the highlighted story's own `##` section from the epic
  doc (just that section, not the whole file) as markdown.

Both preview panels are **selectable**: drag with the mouse to highlight, then
`Ctrl+C` to copy (`Cmd+C` is intercepted by the terminal on macOS — use `Ctrl+C`).

### Colour legend

The Epics column header shows it, and the Projects column uses the same palette:

| Colour  | Meaning                                             |
| ------- | --------------------------------------------------- |
| green   | ready to pick up                                    |
| yellow  | in progress                                          |
| red     | blocked (waiting on a dependency)                   |
| cyan    | complete, but no retrospective written yet (`retro`)|
| magenta | specs exist but no epics yet (`needs epics`)        |
| blue    | epics column: ralph-selected for a `/cpm:ralph` run · projects column: a `● live` pill on a project with a running launched session (both below) |
| dim     | done / no planning artifacts                        |

Colour conveys status, so the status word is not repeated in the row text.

## Requirements

- [`uv`](https://docs.astral.sh/uv/) — runs the board and provisions its
  dependencies. Install with `curl -LsSf https://astral.sh/uv/install.sh | sh`.
- Python 3.11+ (uv will fetch a suitable interpreter if needed).
- The `claude` CLI on your `PATH` — only needed for **launching** sessions (`l`).
  Viewing the board does not require it.
- `tmux` on your `PATH` — the launch backend on every platform. Launches run as
  tmux sessions (`l`/`o`); without tmux those keys fall back to copy (`c`).
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
| Ctrl+C  | Copy text selected (mouse-drag) in a preview panel          |
| Ctrl+P  | Command palette — opens straight to the board's actions     |
| `l`     | Launch the target as a tmux session (see below)             |
| `o`     | Open a plain Claude at the selected project's directory     |
| `t`     | Attach this terminal to the project's running session       |
| `c`     | Copy the launch command to the clipboard                    |
| `space` | Ralph-select the highlighted epic (toggle; see below)       |
| `a`     | Add a project — opens a directory picker (browse, don't type)|
| `x`     | Remove the highlighted project (confirm)                    |
| `z`     | Show / hide completed epics & stories                       |
| `r`     | Refresh — force a re-derive, bypassing the freshness cache  |
| `R`     | Clear the cache entirely, then rebuild                      |
| `q`     | Quit                                                        |

### Launch (`l`), open (`o`), and copy (`c`)

**`l` — launch a session.** The target opens as a **tmux session**
(`cpm-<project>-<id>`) and **always lands you in it**: if the board is itself running
inside tmux, `l` switches you into the new session; otherwise the board suspends its
UI and attaches in the foreground. Either way, `Ctrl-b o` returns you to the board
(see below), where the project keeps a **`● live` pill** (see further below) while its
session runs. Without tmux on your `PATH`, `l`/`o` show a notice; use copy (`c`).

`c` copies the same command to the clipboard instead. `l` and `c` pick their
target by the **focused column**, mirroring how `/cpm:do` handles its own argument:

- **Projects column** → a bare `/cpm:do` (no epic) for the selected project —
  `cpm:do` discovers the next story itself.
- **Epics / Stories column** → the highlighted epic candidate's own command
  (`/cpm:do <epic>`, `/cpm:epics <spec>`, or `/cpm:retro <epic>`). A blocked or
  reference-only row falls back to a bare `/cpm:do`.

**`o` — open the project.** Opens a **plain** `claude` — no `/cpm` command — as a
tmux session at the selected project's directory. Use it when you just want a
Claude session in that project, not a specific CPM step. `o` ignores the focused
column and any ralph selection.

**`t` — attach within the TUI.** Attach hands the board's own terminal to the
highlighted project's running session, instead of opening a separate window. If the
board is itself inside tmux it switches you to the session; otherwise it **suspends**
its UI, runs `tmux attach` in the foreground, and resumes when you return. It targets
the newest live session the board launched for that project. This is the "launch
within the TUI" flow: fully interactive, no extra window, tmux owns the session's
lifetime. (Because `l` already always attaches, `t` is mainly for re-attaching to a
session you've since left.)

**Getting back to the board.** From inside a launched session, **`Ctrl-b` then `o`**
returns you to the board — in both run modes. Each launched session pins a
` C-b o → cpm board ` reminder to its tmux status line.

It's a **prefix** binding (`o` in tmux's prefix key table) on purpose: a bare key
would be swallowed inside the session — Claude would lose it — and `Ctrl-Space` (an
earlier attempt) is intercepted by macOS as "select previous input source" before the
terminal ever sees it. Going through the `Ctrl-b` prefix costs one extra keystroke but
never shadows any of Claude's own keys. The binding is guarded on the `@cpm_launched`
session option so `Ctrl-b o` acts only inside sessions the board launched (a no-op
elsewhere); inside one it `switch-client`s back to the board (board inside tmux) or
`detach-client`s to resume the suspended board UI (board outside tmux). It persists
for the tmux server's lifetime and is harmless outside launched sessions.

**`● live` — running sessions.** After you return to the board from a launched
session (`Ctrl-b o`), the project it was launched for shows a blue `● live` pill so
you can see the session is still running — press `t` to jump back in. On its watch tick the
board polls `tmux list-windows`, capturing each session's native `#{window_id}`
handle and dropping the pill when the session ends (Claude exits → the tmux session
closes) or its window id changes (the name was reused). The pill tracks sessions
**this** board instance launched; restarting the board forgets them (the sessions
keep running — reattach with `tmux attach`, or list them with `tmux ls`).

Everything runs in the selected project's working directory. Each command is built
shell-safely — the project path and command are `shlex.quote()`d into a single
`cd … && claude …` string, which tmux runs via its own shell. There is no shell at
any layer of *our* code and every `tmux` call is an argv list rather than a shell
string, so a path with spaces or metacharacters can neither break the command nor
inject.

### Ralph — autonomous multi-epic runs (`space` + launch)

`/cpm:ralph` runs several epics autonomously, one after another. To launch one
from the board, **ralph-select** the epics first: in the Epics column, press
`space` on each epic you want (only runnable `do` epics — the green/yellow ones —
qualify; blocked, retro and needs-epics rows can't be selected). Selected epics
turn **blue**; `space` again toggles one off. The selection is scoped to the
project in the Epics column and clears if you switch project.

While the selection is non-empty, `l` (and `c`) retarget: they build a single
**`/cpm:ralph <selected epics…>`** (paths project-relative, sorted into numeric
order) instead of a single-epic `/cpm:do`, and launch it as a tmux session ralph
runs unattended in. A launch consumes the selection. Select nothing and the keys
behave exactly as before. Each epic path is `shlex.quote()`d for ralph's own argument
parse, on top of the shell layer, so the multi-epic command is built with no
unescaped interpolation.

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
