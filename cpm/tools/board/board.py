#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "textual>=0.80",
# ]
# ///
"""cpm board — a cross-project CPM status board & launcher.

Run directly with uv (deps are provisioned from the PEP 723 block above):

    uv run cpm/tools/board/board.py            # launch the TUI
    uv run cpm/tools/board/board.py add PATH   # manage the opt-in registry
    uv run cpm/tools/board/board.py list
    uv run cpm/tools/board/board.py refresh    # rebuild the status cache
    uv run cpm/tools/board/board.py refresh --clear   # delete the cache

With no subcommand this launches the Textual TUI: a three-column
projects → epics → stories browser (Miller / ranger style). Selecting a project
populates its epics; selecting an epic populates its stories. Launch (`l`) opens
the target as a tmux session (a `● live` pill marks a project with a running
launched session); attach (`t`) hands this terminal to that session; open (`o`)
opens a plain Claude at the selected project's directory; copy (`c`) copies the
launch command. The
``add`` / ``remove`` / ``list`` subcommands manage the opt-in project registry
(see ``registry.py``). Status derivation conforms to ``cpm/shared/status-model.md``.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import time
from collections.abc import Iterable
from contextlib import AbstractContextManager
from pathlib import Path
from typing import Callable

from rich.color import Color
from rich.color_triplet import ColorTriplet
from rich.console import Console
from rich.markdown import Markdown
from rich.segment import Segment
from rich.style import Style
from rich.text import Text
from textual.app import App, ComposeResult
from textual.content import Content
from textual.command import DiscoveryHit, Hit, Hits, Provider
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.screen import ModalScreen
from textual.strip import Strip
from textual.widgets import DirectoryTree, Footer, Header, Input, Label, OptionList, Static
from textual.widgets.option_list import Option

import board_view
import cache
import launcher
import registry
from cache import derive_project_cached
from registry import RegistryEntry, load_registry
from status_model import NextAction, story_section

_REGISTRY_COMMANDS = {"add", "remove", "list"}
_COLUMN_IDS = ("projects", "epics", "stories")

#: Foreground for an epic ralph-selected via `space`. Blue is outside the epic
#: status palette (green/yellow/red/cyan/magenta/dim), so it reads as "selected"
#: without a marker glyph — and because InverseOptionList blends the cursor bar
#: from the row's own colour, the selection stays visible under the cursor too.
_RALPH_STYLE = "bold blue"


def _pbcopy(text: str) -> None:
    """Default clipboard writer — pipe the shell-safe string to macOS ``pbcopy``."""
    subprocess.run(["pbcopy"], input=text, text=True, check=True)


def _default_session_suffix() -> str:
    """A short per-launch token so repeated tmux launches of one project don't
    collide on the shared server. A whole-second timestamp is enough to separate
    interactive launches; the seam is injectable so tests pin it deterministically."""
    return str(int(time.time()))


def _query_tmux_windows() -> dict[str, str]:
    """Live tmux windows as ``session_name → window_id`` (default liveness poller,
    and the source of captured window-id handles for the "live" pill).

    ``tmux list-windows`` exits non-zero when no server is running; that and any
    spawn failure (tmux absent, etc.) both mean "no live windows" — never an error
    that reaches the watch tick."""
    try:
        result = subprocess.run(
            launcher.tmux_list_windows_argv(), capture_output=True, text=True
        )
    except OSError:
        return {}
    if result.returncode != 0:
        return {}
    return launcher.parse_tmux_windows(result.stdout)


def _query_tmux_activity() -> dict[str, int]:
    """Live sessions as ``session_name → last-attached epoch`` (default attach-order
    poller). Read once when ``t`` is pressed so attach targets the session the user
    most recently used — including one they switched to natively with ``Ctrl-b s``.

    Same failure contract as :func:`_query_tmux_windows`: a missing server (non-zero
    exit) or an absent tmux (``OSError``) both mean "no activity data", and attach
    falls back to newest-launched order."""
    try:
        result = subprocess.run(
            launcher.tmux_list_sessions_activity_argv(), capture_output=True, text=True
        )
    except OSError:
        return {}
    if result.returncode != 0:
        return {}
    return launcher.parse_tmux_activity(result.stdout)


def _clamp(index: int | None, length: int) -> int:
    """Keep a preserved highlight index within ``[0, length)`` (0 when unset)."""
    if index is None:
        return 0
    return max(0, min(index, length - 1))


def _blend(fg: ColorTriplet, bg: ColorTriplet, weight: float) -> ColorTriplet:
    """Mix ``fg`` into ``bg`` by ``weight`` (0 → all ``bg``, 1 → all ``fg``)."""
    return ColorTriplet(
        round(fg.red * weight + bg.red * (1 - weight)),
        round(fg.green * weight + bg.green * (1 - weight)),
        round(fg.blue * weight + bg.blue * (1 - weight)),
    )


def _luminance(c: ColorTriplet) -> float:
    """Perceived luminance (Rec. 709), used to pick a legible foreground."""
    return 0.2126 * c.red + 0.7152 * c.green + 0.0722 * c.blue


class HardBreakMarkdown(Markdown):
    """Rich ``Markdown`` that renders a single newline as a line break (GitHub-style),
    so consecutive metadata lines (``**Field**: value``) keep their own lines instead
    of collapsing into one run-on paragraph. CommonMark treats a lone newline as a
    *soft* break (a space); the CPM epic/story docs rely on line structure, so we
    rewrite soft breaks to hard breaks in the parsed token stream. Paragraph wrapping
    at the panel width is unaffected — that is display wrapping, not a break token."""

    def __init__(self, markup: str, **kwargs: object) -> None:
        super().__init__(markup, **kwargs)
        for token in self.parsed:
            for child in token.children or []:
                if child.type == "softbreak":
                    child.type = "hardbreak"


def markdown_content(markup: str, width: int, *, preface: Text | None = None) -> Content:
    """A rendered markdown document as a selectable Textual ``Content``.

    Textual only lets you select/copy text from a ``Static`` whose renderable is a
    ``Text``/``Content`` — a live Rich ``Markdown`` renders to strips with no
    selection mapping, so a markdown panel is otherwise un-highlightable. We rasterise
    the markdown to styled segments at the panel width and rebuild them as a
    ``Content``, keeping every heading / emphasis / list / table Rich would draw while
    restoring selection. Because the raster is width-specific, the caller re-renders on
    resize. Trailing pad is stripped per line so a copied selection has no run-on
    whitespace. ``preface`` (e.g. a red "Blocked by" note) is placed above the doc."""
    text = Text()
    if preface is not None:
        text.append_text(preface)
        text.append("\n\n")
    render_width = max(width, 10)
    console = Console(width=render_width, color_system="truecolor")
    segments = console.render(HardBreakMarkdown(markup), console.options.update_width(render_width))
    for line in Segment.split_lines(segments):
        line_text = Text()
        for segment in line:
            if segment.control:
                continue
            line_text.append(segment.text, style=segment.style)
        line_text.rstrip()
        text.append_text(line_text)
        text.append("\n")
    text.rstrip()
    return Content.from_rich_text(text)


class InverseOptionList(OptionList):
    """An ``OptionList`` whose cursor is a soft, row-coloured bar rather than a
    fixed blue block.

    Textual drops ``text-style: reverse`` in the option render path and an
    option's own foreground always wins over the component-class colour, so the
    highlight can't be had from CSS alone. We post-process the highlighted strip:
    read the row's own colour and background, then paint a **muted** bar — the row
    colour blended partway toward the background so it never glares — with a
    foreground picked by luminance so the text stays legible on any status colour
    (a full inverse turned bright rows, e.g. yellow, into an unreadable glare). A
    blurred column gets a fainter bar, so the selection stays visible when the
    cursor is elsewhere. Every board row is a single colour, so painting one bar
    across it is lossless; per-segment click metadata is preserved.
    """

    def render_line(self, y: int) -> Strip:
        strip = super().render_line(y)
        line_number = self.scroll_offset.y + y
        try:
            option_index, _ = self._lines[line_number]
        except IndexError:
            return strip
        if option_index != self.highlighted:
            return strip

        row_colour: ColorTriplet | None = None
        surface: ColorTriplet | None = None
        for seg in strip:
            if seg.style is None:
                continue
            if row_colour is None and seg.text.strip() and seg.style.color:
                row_colour = seg.style.color.get_truecolor()
            if surface is None and seg.style.bgcolor:
                surface = seg.style.bgcolor.get_truecolor()
        if surface is None:
            surface = ColorTriplet(18, 18, 18)
        if row_colour is None:
            row_colour = ColorTriplet(224, 224, 224)

        # Muted bar: enough colour to read as "selected", not the full-saturation
        # glare of a true inverse. Blurred columns fade further.
        weight = 0.42 if self.has_focus else 0.22
        bg = _blend(row_colour, surface, weight)
        fg = surface if _luminance(bg) > 128 else ColorTriplet(230, 230, 230)
        bar = Style(color=Color.from_triplet(fg), bgcolor=Color.from_triplet(bg))
        segments = [
            Segment(seg.text, bar + Style(meta=seg.style.meta) if seg.style else bar, seg.control)
            for seg in strip
        ]
        return Strip(segments, strip.cell_length)


class DirectoryOnlyTree(DirectoryTree):
    """A ``DirectoryTree`` that lists directories only — a project *is* a
    directory, so files (and cluttering dotfiles) are filtered out of the picker."""

    def filter_paths(self, paths: Iterable[Path]) -> Iterable[Path]:
        return [p for p in paths if not p.name.startswith(".") and self._safe_is_dir(p)]


class AddProjectScreen(ModalScreen[tuple[str, str | None] | None]):
    """Modal that picks a project directory (and optional label) to register.

    A :class:`DirectoryOnlyTree` browses the filesystem so the path is *selected*,
    not typed. Selecting a directory (Enter) dismisses with ``(path, label)``; Esc
    dismisses with ``None``. It never touches the registry itself — that stays in
    the Textual-free ``registry`` module; the app applies the result. Path
    normalisation is ``registry.add_project``'s job, unchanged.
    """

    BINDINGS = [
        ("escape", "cancel", "Cancel"),
        ("backspace", "go_up", "Up a level"),
    ]

    DEFAULT_CSS = """
    AddProjectScreen {
        align: center middle;
    }
    #add-dialog {
        width: 76;
        height: 28;
        padding: 1 2;
        background: $panel;
        border: thick $primary;
    }
    #add-dialog Label {
        margin-bottom: 1;
    }
    #add-dialog DirectoryTree {
        height: 1fr;
        border: solid $surface;
        margin-bottom: 1;
    }
    """

    def __init__(self, root: Path | None = None) -> None:
        super().__init__()
        self._root = root or Path.home()
        # The directory the tree is currently rooted at. Starts at the initial
        # root and follows ``action_go_up``; the app reads it after the modal
        # closes to resume the next open from where browsing left off.
        self.final_root = self._root

    def compose(self) -> ComposeResult:
        with Vertical(id="add-dialog"):
            yield Label(
                "Add project — ↑↓ move · space open folder · ⌫ up a level · Enter select · Esc cancel"
            )
            yield DirectoryOnlyTree(str(self._root), id="add-tree")
            yield Input(placeholder="Label (optional)", id="add-label")

    def on_mount(self) -> None:
        self.query_one("#add-tree", DirectoryTree).focus()

    def on_directory_tree_directory_selected(self, event: DirectoryTree.DirectorySelected) -> None:
        """Enter on a directory registers it; the label input is optional."""
        label = self.query_one("#add-label", Input).value.strip()
        self.dismiss((str(event.path), label or None))

    def on_input_submitted(self, event: Input.Submitted) -> None:
        # Enter in the label field just returns focus to the tree to pick a folder.
        self.query_one("#add-tree", DirectoryTree).focus()

    def action_go_up(self) -> None:
        """Re-root the tree at its parent so the picker can climb above its start
        directory — a DirectoryTree only ever descends from its root. Assigning
        ``path`` triggers ``watch_path`` to reset the root node and reload. When
        the label input is focused it consumes backspace itself, so this fires
        only from the tree."""
        tree = self.query_one("#add-tree", DirectoryTree)
        current = Path(tree.path)
        parent = current.parent
        if parent != current:  # at the filesystem root there is nothing above
            tree.path = str(parent)
            self.final_root = parent

    def action_cancel(self) -> None:
        self.dismiss(None)


class ConfirmRemoveScreen(ModalScreen[bool]):
    """Confirm unregistering a project. Dismisses ``True`` to remove, else ``False``.

    Removal only unregisters — it never deletes files — so the copy says so and a
    single ``y`` confirms.
    """

    BINDINGS = [
        ("escape", "cancel", "Cancel"),
        ("n", "cancel", "Cancel"),
        ("y", "confirm", "Remove"),
    ]

    DEFAULT_CSS = """
    ConfirmRemoveScreen {
        align: center middle;
    }
    #confirm-dialog {
        width: 64;
        height: auto;
        padding: 1 2;
        background: $panel;
        border: thick $error;
    }
    #confirm-dialog Label {
        margin-bottom: 1;
    }
    """

    def __init__(self, name: str) -> None:
        super().__init__()
        self._name = name

    def compose(self) -> ComposeResult:
        with Vertical(id="confirm-dialog"):
            yield Label(f"Remove “{self._name}” from the board?")
            yield Label("This only unregisters it — no files are deleted.")
            # markup=False: the "[y]" hint would otherwise be parsed as Rich
            # console markup (an unknown style tag) and silently swallowed.
            yield Label("[y] remove    [n / Esc] cancel", markup=False)

    def action_confirm(self) -> None:
        self.dismiss(True)

    def action_cancel(self) -> None:
        self.dismiss(False)


class BoardCommands(Provider):
    """Command-palette provider (Ctrl+P) that lists the board's *own* actions.

    Implementing ``discover`` means the actions show the instant the palette opens
    — Ctrl+P goes straight to the board's commands, instead of the generic system
    list. ``search`` fuzzy-filters the same set as you type.
    """

    def _command_specs(self) -> list[tuple[str, str, object]]:
        app = self.app
        return [
            ("Launch", "Run the target in a new terminal window", app.action_launch),
            ("Open project", "Open a plain Claude at the project directory", app.action_open_plain),
            ("Attach", "Attach this terminal to the project's running session", app.action_attach),
            ("Copy command", "Copy the launch command to the clipboard", app.action_copy),
            ("Ralph-select epic", "Toggle the highlighted epic for a /cpm:ralph run", app.action_toggle_ralph),
            ("Add project", "Register a project", app.action_add_project),
            ("Remove project", "Unregister the highlighted project", app.action_remove_project),
            ("Show/hide completed", "Toggle completed epics & stories", app.action_toggle_complete),
            ("Refresh", "Force a re-derive, bypassing the cache", app.action_refresh),
            ("Clear cache", "Wipe and rebuild the status cache", app.action_clear_cache),
            ("Quit", "Exit the board", app.action_quit),
        ]

    async def discover(self) -> Hits:
        for name, help_text, callback in self._command_specs():
            yield DiscoveryHit(name, callback, help=help_text)

    async def search(self, query: str) -> Hits:
        matcher = self.matcher(query)
        for name, help_text, callback in self._command_specs():
            if (score := matcher.match(name)) > 0:
                yield Hit(score, matcher.highlight(name), callback, help=help_text)


class BoardApp(App[None]):
    """The cross-project CPM board — three columns, projects → epics → stories.

    Each column status is derived through ``derive_project_cached`` (retro 09) and
    only *reads* the engine's ``state`` / ``rag`` / ``next_actions`` (retro 08),
    never recomputing precedence. The middle column is the engine's ordered
    candidate list, so launch acts on exactly what the engine recommends.
    """

    TITLE = "cpm board"
    # Replace the default system-commands provider so Ctrl+P goes straight to the
    # board's own actions (shown immediately via BoardCommands.discover).
    COMMANDS = {BoardCommands}
    BINDINGS = [
        ("q", "quit", "Quit"),
        ("r", "refresh", "Refresh"),
        ("R", "clear_cache", "Clear cache"),
        ("a", "add_project", "Add"),
        ("x", "remove_project", "Remove"),
        ("z", "toggle_complete", "Show/hide done"),
        ("space", "toggle_ralph", "Ralph-select"),
        ("c", "copy", "Copy"),
        ("l", "launch", "Launch"),
        ("o", "open_plain", "Open project"),
        ("t", "attach", "Attach"),
        # Board → session is `t` (attach). Session → board is a tmux prefix binding
        # (`Ctrl-b o`) the board installs on launch (see launcher.tmux_bind_return_argv),
        # not a Textual key — a bare key like Ctrl-Space is swallowed inside launched
        # sessions and, on macOS, intercepted by the OS before the terminal sees it.
        ("left", "focus_left", "◀ column"),
        ("right", "focus_right", "column ▶"),
    ]

    CSS = """
    #columns {
        height: 1fr;
    }
    .col {
        width: 1fr;
        border-right: solid $panel;
    }
    /* Projects fit to their content (short `name · progress` rows) so the two
       detail columns split the remaining width equally and get more room. A floor
       keeps space for the `● live` pill; a ceiling stops a long name dominating. */
    #col-projects {
        width: auto;
        min-width: 24;
        max-width: 48;
    }
    #col-projects #projects {
        width: auto;
    }
    /* Middle column splits vertically: the epics list on top, a read-only file
       preview of the highlighted row below it, divided by a horizontal rule. */
    #col-epics #epics {
        height: 1fr;
    }
    #epic-detail {
        height: 1fr;
        border-top: solid $panel;
        padding: 0 1;
        background: transparent;
    }
    #epic-detail-body {
        color: $text;
    }
    /* Stories column splits the same way: the stories list on top, the highlighted
       story's own section (not the whole file) below it. */
    #col-stories #stories {
        height: 1fr;
    }
    #story-detail {
        height: 1fr;
        border-top: solid $panel;
        padding: 0 1;
        background: transparent;
    }
    #story-detail-body {
        color: $text;
    }
    .col-title {
        padding: 1 2;
        color: $text-muted;
    }
    /* Soften the columns: drop OptionList's own focus box-border so the only
       divider is the column rule, and let the screen background show through. */
    OptionList {
        height: 1fr;
        background: transparent;
        border: none;
        padding: 0 1;
    }
    OptionList:focus {
        background: transparent;
    }
    /* Neutralise the default blue cursor block: InverseOptionList paints the
       highlight itself (row-coloured inverse) in render_line, so at the CSS
       layer the highlighted row must read as a normal, un-blocked row. */
    OptionList > .option-list--option-highlighted,
    OptionList:focus > .option-list--option-highlighted {
        color: $foreground;
        background: transparent;
        text-style: none;
    }
    """

    def __init__(
        self,
        entries: list[RegistryEntry] | None = None,
        *,
        registry_file: Path | None = None,
        cache_root: Path | None = None,
        watch_interval: float | None = 2.0,
        clipboard_writer: Callable[[str], None] | None = None,
        runner: Callable[..., object] | None = None,
        add_project_root: Path | None = None,
        in_tmux: bool | None = None,
        tmux_available: bool | None = None,
        session_suffix: Callable[[], str] | None = None,
        window_lister: Callable[[], dict[str, str]] | None = None,
        activity_lister: Callable[[], dict[str, int]] | None = None,
        attach_suspend: Callable[[], AbstractContextManager] | None = None,
    ) -> None:
        super().__init__()
        self._entries = entries
        self._registry_file = registry_file
        self._cache_root = cache_root
        self._watch_interval = watch_interval
        # Root the add-project directory picker here (tests point it at a fixture
        # tree); the real app browses from the user's home directory.
        self._add_project_root = add_project_root
        # Injectable boundary (retro 10): copy/launch route through these seams so
        # the security-critical paths are tested with stubs.
        self._clipboard_writer = clipboard_writer or _pbcopy
        # Launch hands each tmux argv to the OS, which owns the session; the board
        # never blocks. The runner seam lets the spawn be asserted in tests without
        # touching a real tmux server.
        self._runner = runner or subprocess.run
        # tmux launch backend. ``in_tmux`` decides whether a launch switches the
        # current client into the new session (board is itself inside tmux) or
        # leaves it detached with an attach hint. ``tmux_available`` gates backend
        # selection; ``session_suffix`` names each launch's session; ``window_lister``
        # polls live windows (session → window-id) for liveness + handle capture,
        # which drives the projects pill.
        self._in_tmux = in_tmux if in_tmux is not None else bool(os.environ.get("TMUX"))
        self._tmux_available = (
            tmux_available
            if tmux_available is not None
            else shutil.which("tmux") is not None
        )
        self._session_suffix = session_suffix or _default_session_suffix
        self._window_lister = window_lister or _query_tmux_windows
        # Polled once per attach (not per tick) to order a project's live sessions by
        # when each was last used, so `t` returns you to the most recently accessed —
        # native ``Ctrl-b s`` switches included (see :func:`_query_tmux_activity`).
        self._activity_lister = activity_lister or _query_tmux_activity
        # Attach (`t`) hands the terminal to `tmux attach`, so the board must drop
        # its own UI first. ``self.suspend`` restores the normal terminal for the
        # duration of the attach; the seam lets tests substitute a no-op CM (the
        # headless test driver doesn't support real suspension).
        self._attach_suspend = attach_suspend or self.suspend
        # Sessions this board launched, ``session_name → project path``. Pruned each
        # watch tick against the live set; a project shows a "live" pill while any of
        # its launched sessions is still running. In-memory and this-board-only —
        # relaunching the board forgets sessions started by a previous run.
        self._live_sessions: dict[str, str] = {}
        # Captured native handles, ``session_name → #{window_id}`` (bmad-loop's launch
        # primitive). Filled from the liveness poll; a session is dropped if its id
        # ever changes, which catches a session name being reused by a new window.
        self._live_windows: dict[str, str] = {}
        self._last_live_paths: set[str] = set()
        self._projects: list[tuple[str, object]] = []  # (name, ProjectStatus), display order
        self._epic_rows: list[board_view.EpicRow] = []
        self._current_project: object | None = None  # ProjectStatus shown in the epics column
        # Directory the add-project picker was last browsed to, so successive
        # opens resume there instead of snapping back to the selected project's
        # parent. Set when the picker modal closes; ``None`` until first use.
        self._last_picker_dir: Path | None = None
        # The stories shown in the stories column and their epic's doc text, cached so
        # the story-detail panel can slice out the highlighted story's own section.
        self._stories: list[object] = []
        self._current_epic_text: str = ""
        # The detail panels rasterise markdown at their current width (see
        # markdown_content), so the highlighted row / story index is kept to re-render
        # them on resize.
        self._current_epic_row: board_view.EpicRow | None = None
        self._current_story_index: int = 0
        self._show_complete = False
        # Epics ralph-selected (by absolute target_path) for a `/cpm:ralph` launch.
        # Scoped to the project in the epics column: cleared when the project changes
        # (`_ralph_project` tracks whose selection this is). Ralph runs one project.
        self._ralph_selection: set[str] = set()
        self._ralph_project: str | None = None
        # Guards the cascade while columns are rebuilt programmatically, so a
        # rebuild's highlight change doesn't re-trigger the handler that rebuilds
        # the downstream column (we cascade explicitly instead).
        self._suppress = False

    def compose(self) -> ComposeResult:
        yield Header()
        with Horizontal(id="columns"):
            with Vertical(classes="col", id="col-projects"):
                yield Label("Projects", classes="col-title")
                yield InverseOptionList(id="projects")
            with Vertical(classes="col", id="col-epics"):
                yield Label(
                    "Epics   [green]ready[/]  [yellow]in-progress[/]  [red]blocked[/]  "
                    "[cyan]retro[/]  [magenta]needs epics[/]  [blue]ralph ✓[/]",
                    classes="col-title",
                )
                yield InverseOptionList(id="epics")
                # Bottom of the middle column: a read-only preview of the highlighted
                # epic row's source file (epic / spec / retro `.md`), so the stories
                # column stays purely stories. Non-focusable — column nav is unchanged;
                # long files scroll with the mouse wheel.
                detail = VerticalScroll(Static(id="epic-detail-body"), id="epic-detail")
                detail.can_focus = False
                yield detail
            with Vertical(classes="col", id="col-stories"):
                yield Label("Stories", classes="col-title")
                yield InverseOptionList(id="stories")
                # Bottom of the stories column: the highlighted story's own `##`
                # section from the epic doc (just that section, not the whole file).
                story_detail = VerticalScroll(Static(id="story-detail-body"), id="story-detail")
                story_detail.can_focus = False
                yield story_detail
        yield Footer()

    def on_mount(self) -> None:
        self.refresh_projects()
        self.query_one("#projects", OptionList).focus()
        if self._watch_interval:
            self.set_interval(self._watch_interval, self._on_tick)

    # --- derivation ----------------------------------------------------------

    def _derive(self, force: bool = False) -> list[tuple[str, object]]:
        entries = self._entries if self._entries is not None else load_registry(self._registry_file)
        rows = [
            (
                entry.label or Path(entry.path).name,
                derive_project_cached(entry.path, cache_root=self._cache_root, force=force),
            )
            for entry in entries
        ]
        return board_view.sort_rows(rows)

    # --- column population ---------------------------------------------------

    def refresh_projects(
        self,
        *,
        force: bool = False,
        keep_name: str | None = None,
        rows: list[tuple[str, object]] | None = None,
    ) -> None:
        """Rebuild the projects column, then cascade to epics/stories.

        Preserves the highlighted project (by name) *and* the epic/story cursor
        positions (by index) across a refresh, so a watch tick or manual refresh
        doesn't yank you back to the top of a list. ``rows`` lets a caller pass
        already-derived rows to avoid a second derive.
        """
        keep_epic = self.query_one("#epics", OptionList).highlighted
        keep_story = self.query_one("#stories", OptionList).highlighted
        self._projects = rows if rows is not None else self._derive(force=force)
        option_list = self.query_one("#projects", OptionList)
        live_counts = self._live_session_counts()
        live_paths = set(live_counts)
        self._last_live_paths = live_paths
        self._suppress = True
        option_list.clear_options()
        for name, status in self._projects:
            option_list.add_option(
                Option(
                    board_view.project_row_text(
                        name, status, live=live_counts.get(str(status.path), 0)
                    )
                )
            )
        self._suppress = False

        if not self._projects:
            self._current_project = None
            self._epic_rows = []
            self._stories = []
            self._current_epic_text = ""
            self.query_one("#epics", OptionList).clear_options()
            self.query_one("#stories", OptionList).clear_options()
            self._update_epic_detail(None)
            self._update_story_detail(0)
            return

        index = 0
        if keep_name is not None:
            names = [name for name, _ in self._projects]
            if keep_name in names:
                index = names.index(keep_name)
        self._suppress = True
        option_list.highlighted = index
        self._suppress = False
        self._populate_epics(self._projects[index][1], keep_epic=keep_epic, keep_story=keep_story)

    def _populate_epics(
        self, status: object, *, keep_epic: int | None = None, keep_story: int | None = None
    ) -> None:
        self._current_project = status
        self._epic_rows = board_view.epic_rows(status, show_complete=self._show_complete)
        self._reconcile_ralph_selection(status)
        option_list = self.query_one("#epics", OptionList)
        self._suppress = True
        option_list.clear_options()
        for row in self._epic_rows:
            selected = self._is_ralph_eligible(row) and row.action.target_path in self._ralph_selection
            style = _RALPH_STYLE if selected else row.style
            option_list.add_option(Option(Text(row.label, style=style)))
        if self._epic_rows:
            option_list.highlighted = _clamp(keep_epic, len(self._epic_rows))
        self._suppress = False
        index = option_list.highlighted or 0
        row = self._epic_rows[index] if self._epic_rows else None
        self._populate_stories(row, keep_index=keep_story)
        self._update_epic_detail(row)

    def _populate_stories(
        self, row: board_view.EpicRow | None, *, keep_index: int | None = None
    ) -> None:
        """Right column — purely the highlighted epic's stories. A ``needs epics`` row
        (``epic is None``) has no stories, so the column is empty; the spec it targets
        is shown in the middle-column detail panel instead.

        Caches the epic's visible stories and its doc text so the bottom detail panel
        can show the *highlighted* story's own section (read the file once per epic)."""
        epic = row.epic if row else None
        self._stories = board_view.visible_stories(epic, show_complete=self._show_complete)
        self._current_epic_text = (self._read_text(epic.path) or "") if epic is not None else ""
        option_list = self.query_one("#stories", OptionList)
        rows = board_view.story_rows(epic, show_complete=self._show_complete)
        self._suppress = True
        option_list.clear_options()
        for label, style in rows:
            option_list.add_option(Option(Text(label, style=style)))
        if rows:
            option_list.highlighted = _clamp(keep_index, len(rows))
        self._suppress = False
        self._update_story_detail(option_list.highlighted or 0)

    @staticmethod
    def _panel_width(widget: Static) -> int:
        """The width to rasterise a detail panel's markdown at — its content region,
        falling back to a sane default before the first layout (a resize re-renders)."""
        width = widget.content_size.width or widget.size.width
        return width if width > 0 else 80

    def _update_story_detail(self, index: int) -> None:
        """Bottom of the stories column: the highlighted story's own ``##`` section
        from the epic doc (just that section, not the whole file), as markdown."""
        self._current_story_index = index
        self._render_story_detail()

    def _render_story_detail(self) -> None:
        body = self.query_one("#story-detail-body", Static)
        index = self._current_story_index
        section = ""
        if 0 <= index < len(self._stories) and self._current_epic_text:
            section = story_section(self._current_epic_text, self._stories[index])
        body.update(markdown_content(section, self._panel_width(body)) if section else Content(""))

    def _update_epic_detail(self, row: board_view.EpicRow | None) -> None:
        """Bottom of the middle column: the highlighted epic row's source file
        (its epic / spec / retro ``.md``) rendered as markdown, prefaced — for a
        blocked epic — with what it is waiting on, so a red row explains itself."""
        self._current_epic_row = row
        self._render_epic_detail()

    def _render_epic_detail(self) -> None:
        body = self.query_one("#epic-detail-body", Static)
        body.update(self._epic_detail_content(self._current_epic_row, self._panel_width(body)))

    def _epic_detail_content(self, row: board_view.EpicRow | None, width: int) -> Content:
        if row is None:
            return Content("")
        # Preface the doc with attention notes: unrecognised statuses to fix (the
        # (!) flag's explanation), then — for a blocked epic — what it waits on.
        preface_rows: list[tuple[str, str]] = []
        if row.epic is not None:
            preface_rows.extend(board_view.unrecognised_rows(row.epic))
            if row.action is not None and row.action.kind == "attention:unblock":
                blocking = board_view.blocking_rows(row.epic)
                if preface_rows and blocking:
                    preface_rows.append(("", ""))  # blank line between the two blocks
                preface_rows.extend(blocking)
        preface: Text | None = None
        if preface_rows:
            preface = Text()
            for i, (label, style) in enumerate(preface_rows):
                if i:
                    preface.append("\n")
                preface.append(label, style=style or "")
        path = row.epic.path if row.epic is not None else None
        if path is None and row.action is not None and row.action.target_path:
            path = Path(row.action.target_path)
        if path is not None:
            text = self._read_text(path)
            if text is not None:
                return markdown_content(text, width, preface=preface)
            unreadable = Text(f"{path.name} (unreadable)", style="dim")
            if preface is not None:
                preface.append("\n\n")
                preface.append_text(unreadable)
                return Content.from_rich_text(preface)
            return Content.from_rich_text(unreadable)
        return Content.from_rich_text(preface) if preface is not None else Content("")

    def on_resize(self, event: object) -> None:
        """Detail-panel markdown is rasterised at panel width, so re-render both on a
        terminal resize to reflow to the new width."""
        self._render_epic_detail()
        self._render_story_detail()

    @staticmethod
    def _read_text(path: Path) -> str | None:
        """Read a doc file, or ``None`` when it can't be read (missing / unreadable)."""
        try:
            return Path(path).read_text(encoding="utf-8")
        except OSError:
            return None

    def on_option_list_option_highlighted(self, event: OptionList.OptionHighlighted) -> None:
        """User navigation cascades to the column on the right."""
        if self._suppress:
            return
        index = event.option_index
        if event.option_list.id == "projects":
            if 0 <= index < len(self._projects):
                self._populate_epics(self._projects[index][1])
        elif event.option_list.id == "epics":
            if 0 <= index < len(self._epic_rows):
                row = self._epic_rows[index]
                self._populate_stories(row)
                self._update_epic_detail(row)
        elif event.option_list.id == "stories":
            self._update_story_detail(index)

    # --- refresh / watch -----------------------------------------------------

    def action_refresh(self) -> None:
        """Manual refresh — force a full re-derive, bypassing the freshness cache."""
        self.refresh_projects(force=True, keep_name=self._highlighted_project_name())

    def _on_tick(self) -> None:
        # Watch mode: re-derive cheaply (cache-served) and prune finished launch
        # sessions, then rebuild only when the data *or* the live-session set
        # actually changed. When nothing changed — the common case while you're just
        # browsing — leave the columns and the cursor untouched so a tick never
        # yanks you off the bottom of a list.
        self._refresh_live_sessions()
        new = self._derive(force=False)
        if new == self._projects and self._live_project_paths() == self._last_live_paths:
            return
        self.refresh_projects(keep_name=self._highlighted_project_name(), rows=new)

    def _live_project_paths(self) -> set[str]:
        """Project paths with at least one live board-launched session (→ a pill)."""
        return set(self._live_sessions.values())

    def _live_session_counts(self) -> dict[str, int]:
        """Project path → number of live board-launched sessions it has. Drives the
        pill's count (``● 2 live``) so a project running several sessions reads as
        distinct from one running a single session."""
        counts: dict[str, int] = {}
        for path in self._live_sessions.values():
            counts[path] = counts.get(path, 0) + 1
        return counts

    def _live_session_for(
        self, project_path: str, last_attached: dict[str, int] | None = None
    ) -> str | None:
        """The still-live session a ``t`` attach should target for a project, or ``None``.

        With ``last_attached`` (session → epoch from :func:`_query_tmux_activity`), the
        **most recently accessed** session wins — so after switching between a project's
        sessions you return to the one you were last in, not merely the newest-launched.
        Ties, and any session with no attach record (never attached → absent → 0), fall
        back to launch order: ``_live_sessions`` preserves insertion order, so the
        highest-index match is newest. With no map (the default) every session scores 0,
        so this collapses to "newest launched" — the historical behaviour."""
        matches = [name for name, path in self._live_sessions.items() if path == project_path]
        if not matches:
            return None
        attached = last_attached or {}
        return max(matches, key=lambda name: (attached.get(name, 0), matches.index(name)))

    def _refresh_live_sessions(self) -> None:
        """Drop launch sessions that are no longer running, and capture/refresh each
        surviving session's native window-id handle.

        A session survives when it is still present in the live window map *and* its
        window id is unchanged from the one first captured — an id change means the
        session name was reused by a different window, so the original is gone. Only
        polls tmux when there is something to track, so a board that never launches
        never spawns ``tmux list-windows``."""
        if not self._live_sessions:
            return
        live = self._window_lister()  # session_name → window_id
        kept: dict[str, str] = {}
        windows: dict[str, str] = {}
        for name, path in self._live_sessions.items():
            window_id = live.get(name)
            if window_id is None:
                continue  # session gone
            if name in self._live_windows and self._live_windows[name] != window_id:
                continue  # name reused by a new window — the tracked session is gone
            kept[name] = path
            windows[name] = window_id
        self._live_sessions = kept
        self._live_windows = windows

    def action_clear_cache(self) -> None:
        """Wipe the whole cache directory (removing orphaned entries too), then
        re-derive. ``r`` rebuilds the registered projects in place; this also
        clears cache files left behind by projects that were removed."""
        cache.clear_cache(cache_root=self._cache_root)
        self.refresh_projects(force=True, keep_name=self._highlighted_project_name())
        self.notify("Cache cleared & rebuilt")

    def action_toggle_complete(self) -> None:
        """Show or hide completed epics/stories (default hidden)."""
        self._show_complete = not self._show_complete
        if self._current_project is not None:
            self._populate_epics(self._current_project)
        self.notify("Showing completed" if self._show_complete else "Hiding completed")

    # --- column focus --------------------------------------------------------

    def action_focus_left(self) -> None:
        self._move_focus(-1)

    def action_focus_right(self) -> None:
        self._move_focus(1)

    def _move_focus(self, delta: int) -> None:
        focused = self.focused
        current = focused.id if focused is not None and focused.id in _COLUMN_IDS else "projects"
        index = _COLUMN_IDS.index(current)
        target = max(0, min(len(_COLUMN_IDS) - 1, index + delta))
        self.query_one(f"#{_COLUMN_IDS[target]}", OptionList).focus()

    # --- registry actions ----------------------------------------------------

    def _highlighted_project_name(self) -> str | None:
        option_list = self.query_one("#projects", OptionList)
        index = option_list.highlighted
        if self._projects and index is not None and 0 <= index < len(self._projects):
            return self._projects[index][0]
        return None

    def _add_picker_root(self) -> Path | None:
        """Where the add-project directory picker starts browsing: the directory
        it was last left at (so browsing survives the modal closing), else the
        selected project's *parent* (so its sibling repos are right there), else
        an injected root (tests), else ``None`` — which the modal resolves to
        the home dir."""
        if self._last_picker_dir is not None and self._last_picker_dir.is_dir():
            return self._last_picker_dir
        if self._current_project is not None:
            parent = Path(self._current_project.path).parent
            if parent.is_dir():
                return parent
        return self._add_project_root

    def action_add_project(self) -> None:
        """Open the add-project modal; register the result and re-derive."""

        screen = AddProjectScreen(root=self._add_picker_root())

        def _apply(result: tuple[str, str | None] | None) -> None:
            # Remember where the picker was left — on cancel too — so the next
            # open resumes there rather than re-deriving from the selection.
            self._last_picker_dir = screen.final_root
            if result is None:
                return
            path, label = result
            registry.add_project(path, label, registry_file=self._registry_file)
            self.refresh_projects(force=True, keep_name=label or None)
            self.notify(f"Added: {path}")

        self.push_screen(screen, _apply)

    def action_remove_project(self) -> None:
        """Confirm, then unregister the highlighted project and re-derive."""
        index = self.query_one("#projects", OptionList).highlighted
        if index is None or not (0 <= index < len(self._projects)):
            return
        name, status = self._projects[index]

        def _apply(confirmed: bool) -> None:
            if not confirmed:
                return
            registry.remove_project(str(status.path), registry_file=self._registry_file)
            self.refresh_projects(force=True)
            self.notify(f"Removed: {name}")

        self.push_screen(ConfirmRemoveScreen(name), _apply)

    # --- launch actions ------------------------------------------------------

    @staticmethod
    def _is_ralph_eligible(row: board_view.EpicRow) -> bool:
        """Whether an epic row can be ralph-selected. Ralph wraps ``/cpm:do``, so
        only ``do`` candidates (in-progress + ready epics) qualify — blocked, retro,
        needs-epics and reference-only rows have nothing for ralph to execute."""
        return (
            row.action is not None
            and row.action.kind == "do"
            and row.action.target_path is not None
        )

    def _reconcile_ralph_selection(self, status: object) -> None:
        """Keep the ralph selection consistent with the epics column being shown:
        drop it wholesale when the project changed, then prune any paths no longer
        present as ``do`` rows (e.g. an epic that has since completed)."""
        project_key = str(getattr(status, "path", None))
        if project_key != self._ralph_project:
            self._ralph_selection = set()
            self._ralph_project = project_key
        eligible = {
            row.action.target_path for row in self._epic_rows if self._is_ralph_eligible(row)
        }
        self._ralph_selection &= eligible

    def action_toggle_ralph(self) -> None:
        """Toggle the highlighted epic in/out of the ralph selection (``space``).

        Only fires in the epics column and only for ``do`` rows; the selection
        recolours (blue) rather than adding a marker, and drives what ``c``/``l``
        launch — a ``/cpm:ralph`` over the selected epics.
        """
        focused = self.focused
        if focused is None or focused.id != "epics" or not self._epic_rows:
            return
        index = self.query_one("#epics", OptionList).highlighted
        if index is None or not (0 <= index < len(self._epic_rows)):
            return
        row = self._epic_rows[index]
        if not self._is_ralph_eligible(row):
            self.notify("Only runnable epics can be ralph-selected", severity="warning")
            return
        path = row.action.target_path
        if path in self._ralph_selection:
            self._ralph_selection.discard(path)
        else:
            self._ralph_selection.add(path)
        self._populate_epics(
            self._current_project, keep_epic=index, keep_story=self._story_highlight()
        )

    def _story_highlight(self) -> int | None:
        return self.query_one("#stories", OptionList).highlighted

    def _clear_ralph_selection(self) -> None:
        """Drop the selection and repaint (after a ralph launch fires)."""
        if not self._ralph_selection:
            return
        self._ralph_selection = set()
        index = self.query_one("#epics", OptionList).highlighted
        self._populate_epics(self._current_project, keep_epic=index, keep_story=self._story_highlight())

    def _ralph_action(self) -> NextAction:
        """Synthesize the ``/cpm:ralph <epics…>`` action for the current selection."""
        command = launcher.ralph_command(
            str(self._current_project.path), sorted(self._ralph_selection)
        )
        return NextAction("ralph", command, None, f"Ralph over {len(self._ralph_selection)} epic(s)")

    def _selected_epic_row(self) -> board_view.EpicRow | None:
        """The highlighted epic candidate, or ``None`` when it isn't launchable."""
        if not self._epic_rows or self._current_project is None:
            return None
        index = self.query_one("#epics", OptionList).highlighted
        if index is None or not (0 <= index < len(self._epic_rows)):
            return None
        row = self._epic_rows[index]
        if row.action is None or row.action.command is None:
            return None  # blocked candidate or reference-only done epic — no-op
        return row

    @staticmethod
    def _bare_do() -> NextAction:
        """A bare ``/cpm:do`` (no epic) — cpm:do discovers the next story itself."""
        return NextAction("do", "/cpm:do", None, "Run /cpm:do (discover next story)")

    def _launch_target(self) -> tuple[NextAction | None, str | None]:
        """The action ``l``/``c`` operate on plus an optional heads-up note, chosen
        by the *focused column* — the board's analogue of ``/cpm:do``'s own
        argument handling:

        - **Projects column** → a bare ``/cpm:do`` for the selected project.
        - **Epics / Stories column** → the highlighted epic candidate's own command
          (``/cpm:do <epic>`` / ``/cpm:epics <spec>`` / ``/cpm:retro <epic>``). A
          blocked or reference-only row has nothing to run directly, so it **falls
          back** to a bare ``/cpm:do`` (never a dead key) and returns a note so the
          toast explains the fallback.

        A non-empty **ralph selection** takes precedence over the column logic: the
        launch family then operates on a ``/cpm:ralph`` over the selected epics.

        Returns ``(None, note)`` only when there is no project at all.
        """
        if self._current_project is None:
            return None, "Nothing to launch — no project selected"
        if self._ralph_selection:
            return self._ralph_action(), None
        focused = self.focused
        column = focused.id if focused is not None and focused.id in _COLUMN_IDS else "projects"
        if column == "projects":
            return self._bare_do(), None
        row = self._selected_epic_row()
        if row is not None:
            return row.action, None
        return self._bare_do(), "No launchable command here — running /cpm:do to find the next story"

    def copy_to_clipboard(self, text: str) -> None:
        """Copy text (e.g. a mouse-selected panel region via ``Ctrl+C``) to the
        clipboard. Textual's base only emits an OSC 52 escape, which macOS Terminal —
        and iTerm2 without the clipboard opt-in — silently drop, so a selection never
        actually copies. We keep OSC 52 (it reaches the *local* clipboard over SSH and
        on terminals that honour it) and *also* pipe through the same local writer the
        command-copy uses (``pbcopy``), so a plain macOS Terminal copies too."""
        super().copy_to_clipboard(text)
        try:
            self._clipboard_writer(text)
        except (OSError, subprocess.SubprocessError):
            pass  # no local pbcopy (e.g. Linux) — the OSC 52 path above still applies
        self.notify(f"Copied {len(text)} chars")

    def action_copy(self) -> None:
        """Copy the focused target's shell-safe command to the clipboard."""
        action, note = self._launch_target()
        if action is None or action.command is None:
            self.notify(note or "Nothing to copy here", severity="warning")
            return
        command = launcher.clipboard_command(str(self._current_project.path), action)
        self._clipboard_writer(command)
        self.notify(note or f"Copied: {action.command}")

    def _spawn_launch(
        self,
        *,
        build_tmux: Callable[[str, str], list[list[str]]],
        note: str,
    ) -> bool:
        """Launch as a detached tmux session and toast.

        The launch runs as a tmux session (a plan of one or more tmux argvs, each
        spawned in turn) and always lands you in it: the plan switches the current
        client into the session when the board is itself inside tmux; otherwise the
        board suspends its UI and attaches in the foreground (``Ctrl-b o`` returns).
        With no tmux, launch degrades to a warning pointing at copy (`c`).

        ``build_tmux`` produces shell-safe argv(s) with no shell at any layer. On a
        successful spawn the session is recorded for the "live" pill and the projects
        column repainted. Returns ``True`` when a launch was actually spawned (so
        callers can, e.g., consume a ralph selection only on success).
        """
        project_path = str(self._current_project.path)
        if launcher.select_launch_backend(tmux_available=self._tmux_available) is None:
            self.notify(
                "tmux isn't available here — press c to copy the command instead",
                severity="error",
            )
            return False
        session = launcher.tmux_session_name(project_path, self._session_suffix())
        for argv in build_tmux(project_path, session):
            self._runner(argv)
        # Install the return binding (Ctrl-b o → back to the board). It is mode-aware
        # — switch-client when the board is inside tmux, detach when it isn't — and a
        # prefix binding guarded on the @cpm_launched marker, so it only fires inside
        # launched sessions and never shadows a bare key from Claude. Idempotent.
        self._runner(launcher.tmux_bind_return_argv(attach=self._in_tmux))
        self._live_sessions[session] = project_path
        self.refresh_projects(keep_name=self._highlighted_project_name())
        if self._in_tmux:
            # The launch plan already switched the client into the new session.
            self.notify(f"{note} — switched to tmux session {session}")
            return True
        # Detached: always attach — hand the terminal to the new session (suspend the
        # board UI, run tmux attach in the foreground). Ctrl-b o returns to the board,
        # where the session keeps its `● live` pill for as long as it runs.
        with self._attach_suspend():
            self._runner(launcher.tmux_attach_argv(session))
        self.notify(f"{note} — detached from {session}")
        return True

    def action_open_plain(self) -> None:
        """Open a **plain** Claude — no `/cpm` command — at the selected project's
        directory (`o`). Ignores the epic candidate and any ralph selection: this is
        "just open the project", nothing else.
        """
        if self._current_project is None:
            self.notify("Nothing to open — no project selected", severity="warning")
            return
        self._spawn_launch(
            build_tmux=lambda path, session: launcher.open_tmux_launch(
                path, session, attach=self._in_tmux
            ),
            note="Opened Claude for the project",
        )

    def action_launch(self) -> None:
        """Launch the focused target as a **tmux session** (`l`).

        The board never blocks: the command is handed to a tmux session and control
        returns here immediately — good for running several sessions at once. When
        the board is inside tmux the launch switches you into the new session;
        otherwise it stays detached (the toast carries the attach command) and a
        "live" pill marks the project. With no tmux, this notes to use copy (`c`).
        """
        action, note = self._launch_target()
        if action is None or action.command is None:
            self.notify(note or "Nothing to launch here", severity="warning")
            return
        launched = self._spawn_launch(
            build_tmux=lambda path, session: launcher.tmux_launch(
                path, action, session, attach=self._in_tmux
            ),
            note=note or f"Launched: {action.command}",
        )
        if launched and action.kind == "ralph":
            self._clear_ralph_selection()

    def action_attach(self) -> None:
        """Attach this terminal to the highlighted project's running session (`t`).

        This is "launch within the TUI": rather than opening a separate window, the
        board hands its own terminal to the live tmux session. Inside tmux it
        switches the client to the session; otherwise it **suspends** its UI, runs
        ``tmux attach`` in the foreground, and resumes when you return (``Ctrl-b o``
        returns in both modes — see :func:`launcher.tmux_bind_return_argv`). Where the
        highlighted project has several live sessions, it targets the one you most
        recently used (``#{session_last_attached}``, native ``Ctrl-b s`` switches
        included; newest-launched breaks ties) — see :meth:`_live_session_for`. A
        stale session is pruned first so attach never chases one that has already
        ended.
        """
        if self._current_project is None:
            self.notify("No project selected", severity="warning")
            return
        before = self._live_project_paths()
        self._refresh_live_sessions()
        if self._live_project_paths() != before:
            self.refresh_projects(keep_name=self._highlighted_project_name())
        session = self._live_session_for(
            str(self._current_project.path), self._activity_lister()
        )
        if session is None:
            self.notify("No live session here — launch one with l", severity="warning")
            return
        if self._in_tmux:
            self._runner(launcher.tmux_switch_argv(session))
            self.notify(f"Switched to {session}")
            return
        with self._attach_suspend():
            self._runner(launcher.tmux_attach_argv(session))
        self.notify(f"Detached from {session}")


def refresh_cli(
    argv: list[str], *, registry_file: Path | None = None, cache_root: Path | None = None
) -> int:
    """``refresh`` subcommand: rebuild every registered project's cache entry.

    ``--clear`` deletes the cache instead (each project re-derives on next read).
    Rebuilding force-re-derives all registered projects, rewriting their cache with
    the current schema — a fix for a cache you suspect is stale or wrong.
    """
    if "--clear" in argv:
        base = cache.clear_cache(cache_root=cache_root)
        print(f"Cleared cache at {base}")
        return 0
    entries = load_registry(registry_file)
    for entry in entries:
        derive_project_cached(entry.path, cache_root=cache_root, force=True)
    print(f"Rebuilt cache for {len(entries)} project(s) at {cache_root or cache.cache_dir()}")
    return 0


def main(argv: list[str] | None = None) -> int:
    """Dispatch registry / refresh subcommands, or launch the TUI when none is given."""
    argv = sys.argv[1:] if argv is None else argv
    if argv and argv[0] in _REGISTRY_COMMANDS:
        return registry.run_cli(argv)
    if argv and argv[0] == "refresh":
        return refresh_cli(argv[1:])
    BoardApp().run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
