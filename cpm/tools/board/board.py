#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "textual>=0.80",
#     "pyte>=0.8",
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
populates its epics; selecting an epic populates its stories. Launch (`l`) and
copy (`c`) act on the highlighted epic candidate, in the project's cwd. The
``add`` / ``remove`` / ``list`` subcommands manage the opt-in project registry
(see ``registry.py``). Status derivation conforms to ``cpm/shared/status-model.md``.
"""

from __future__ import annotations

import subprocess
import sys
from collections.abc import Iterable
from pathlib import Path
from typing import Callable

from rich.color import Color
from rich.color_triplet import ColorTriplet
from rich.segment import Segment
from rich.style import Style
from rich.text import Text
from textual.app import App, ComposeResult
from textual.command import DiscoveryHit, Hit, Hits, Provider
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.strip import Strip
from textual.widgets import DirectoryTree, Footer, Header, Input, Label, OptionList
from textual.widgets.option_list import Option

import board_view
import cache
import launcher
import registry
from cache import derive_project_cached
from embedded_terminal import EmbeddedTerminal
from registry import RegistryEntry, load_registry
from status_model import NextAction

_REGISTRY_COMMANDS = {"add", "remove", "list"}
_COLUMN_IDS = ("projects", "epics", "stories")


def _pbcopy(text: str) -> None:
    """Default clipboard writer — pipe the shell-safe string to macOS ``pbcopy``."""
    subprocess.run(["pbcopy"], input=text, text=True, check=True)


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

    BINDINGS = [("escape", "cancel", "Cancel")]

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

    def compose(self) -> ComposeResult:
        with Vertical(id="add-dialog"):
            yield Label("Add project — ↑↓ move · space open folder · Enter select · Esc cancel")
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
            ("Launch here", "Run the session in an embedded pane", app.action_launch_embedded),
            ("Launch full-screen", "Suspend the board and run the session inline", app.action_launch_inline),
            ("Launch in a new window", "Open the session in a detached terminal", app.action_launch_detached),
            ("Copy command", "Copy the launch command to the clipboard", app.action_copy),
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
        ("c", "copy", "Copy"),
        ("l", "launch_embedded", "Launch here"),
        ("i", "launch_inline", "Launch (full-screen)"),
        ("L", "launch_detached", "Launch window"),
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
    .col.hidden {
        display: none;
    }
    /* The embedded session pane takes the space the epics + stories columns
       vacate (2 of the 3 equal columns); the projects column stays visible. */
    #embedded {
        width: 2fr;
        height: 1fr;
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
        platform: str | None = None,
        suspend: Callable[[], object] | None = None,
        terminal_spawn: Callable[..., int] | None = None,
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
        # Launch has two modes: inline (suspend the board, run claude full-size in
        # this terminal) and detached (osascript opens a new window). The default
        # runner drives both; the suspend seam lets the inline path be tested
        # without a real terminal to suspend.
        self._runner = runner or subprocess.run
        self._platform = platform or sys.platform
        self._suspend = suspend or self.suspend
        # Embedded-terminal launch (`l`): fork/exec seam (stubbed in tests) and the
        # single live pane, if any.
        self._terminal_spawn = terminal_spawn
        self._embedded: EmbeddedTerminal | None = None
        self._projects: list[tuple[str, object]] = []  # (name, ProjectStatus), display order
        self._epic_rows: list[board_view.EpicRow] = []
        self._current_project: object | None = None  # ProjectStatus shown in the epics column
        self._show_complete = False
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
                    "[cyan]retro[/]  [magenta]needs epics[/]",
                    classes="col-title",
                )
                yield InverseOptionList(id="epics")
            with Vertical(classes="col", id="col-stories"):
                yield Label("Stories", classes="col-title")
                yield InverseOptionList(id="stories")
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
        self._suppress = True
        option_list.clear_options()
        for name, status in self._projects:
            option_list.add_option(
                Option(Text(board_view.project_label(name, status), style=board_view.project_style(status.state)))
            )
        self._suppress = False

        if not self._projects:
            self._current_project = None
            self._epic_rows = []
            self.query_one("#epics", OptionList).clear_options()
            self.query_one("#stories", OptionList).clear_options()
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
        option_list = self.query_one("#epics", OptionList)
        self._suppress = True
        option_list.clear_options()
        for row in self._epic_rows:
            option_list.add_option(Option(Text(row.label, style=row.style)))
        if self._epic_rows:
            option_list.highlighted = _clamp(keep_epic, len(self._epic_rows))
        self._suppress = False
        index = option_list.highlighted or 0
        row = self._epic_rows[index] if self._epic_rows else None
        self._populate_stories(row, keep_index=keep_story)

    def _populate_stories(
        self, row: board_view.EpicRow | None, *, keep_index: int | None = None
    ) -> None:
        option_list = self.query_one("#stories", OptionList)
        rows = self._detail_rows(row)
        self._suppress = True
        option_list.clear_options()
        for label, style in rows:
            option_list.add_option(Option(Text(label, style=style)))
        if rows:
            option_list.highlighted = _clamp(keep_index, len(rows))
        self._suppress = False

    def _detail_rows(self, row: board_view.EpicRow | None) -> list[tuple[str, str]]:
        """Right-column rows for the highlighted epic row: its stories, or — for a
        ``needs epics`` row (a spec with no epics yet) — a preview of the spec. A
        blocked epic is prefaced with what it's waiting on, so a red row explains
        itself."""
        if row is None:
            return []
        if row.epic is None and row.action is not None and row.action.target_path:
            return self._spec_preview(row.action.target_path)
        stories = board_view.story_rows(row.epic, show_complete=self._show_complete)
        if row.epic is not None and row.action is not None and row.action.kind == "attention:unblock":
            return [*board_view.blocking_rows(row.epic), ("", ""), *stories]
        return stories

    def _spec_preview(self, target_path: str) -> list[tuple[str, str]]:
        path = Path(target_path)
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            return [(f"{path.name} (unreadable)", "dim")]
        return board_view.spec_preview_rows(text)

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
                self._populate_stories(self._epic_rows[index])

    # --- refresh / watch -----------------------------------------------------

    def action_refresh(self) -> None:
        """Manual refresh — force a full re-derive, bypassing the freshness cache."""
        self.refresh_projects(force=True, keep_name=self._highlighted_project_name())

    def _on_tick(self) -> None:
        # Watch mode: re-derive cheaply (cache-served) and only rebuild when the
        # data actually changed. When nothing changed — the common case while
        # you're just browsing — leave the columns and the cursor untouched so a
        # tick never yanks you off the bottom of a list.
        new = self._derive(force=False)
        if new == self._projects:
            return
        self.refresh_projects(keep_name=self._highlighted_project_name(), rows=new)

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
        """Where the add-project directory picker starts browsing: the selected
        project's *parent* (so its sibling repos are right there), else an injected
        root (tests), else ``None`` — which the modal resolves to the home dir."""
        if self._current_project is not None:
            parent = Path(self._current_project.path).parent
            if parent.is_dir():
                return parent
        return self._add_project_root

    def action_add_project(self) -> None:
        """Open the add-project modal; register the result and re-derive."""

        def _apply(result: tuple[str, str | None] | None) -> None:
            if result is None:
                return
            path, label = result
            registry.add_project(path, label, registry_file=self._registry_file)
            self.refresh_projects(force=True, keep_name=label or None)
            self.notify(f"Added: {path}")

        self.push_screen(AddProjectScreen(root=self._add_picker_root()), _apply)

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

        Returns ``(None, note)`` only when there is no project at all.
        """
        if self._current_project is None:
            return None, "Nothing to launch — no project selected"
        focused = self.focused
        column = focused.id if focused is not None and focused.id in _COLUMN_IDS else "projects"
        if column == "projects":
            return self._bare_do(), None
        row = self._selected_epic_row()
        if row is not None:
            return row.action, None
        return self._bare_do(), "No launchable command here — running /cpm:do to find the next story"

    def action_copy(self) -> None:
        """Copy the focused target's shell-safe command to the clipboard."""
        action, note = self._launch_target()
        if action is None or action.command is None:
            self.notify(note or "Nothing to copy here", severity="warning")
            return
        command = launcher.clipboard_command(str(self._current_project.path), action)
        self._clipboard_writer(command)
        self.notify(note or f"Copied: {action.command}")

    def action_launch_embedded(self) -> None:
        """Run the focused target in a pane covering the epics + stories columns.

        The board stays mounted alongside (projects column still visible); the
        session runs in an embedded PTY terminal. Press F10, or exit the session,
        to close the pane and restore the columns.
        """
        if self._embedded is not None:
            return  # one embedded session at a time
        action, note = self._launch_target()
        if action is None or action.command is None:
            self.notify(note or "Nothing to launch here", severity="warning")
            return
        argv, cwd = launcher.direct_launch(str(self._current_project.path), action)
        terminal = EmbeddedTerminal(argv, cwd=cwd, spawn=self._terminal_spawn, id="embedded")
        self._embedded = terminal
        self.query_one("#col-epics").add_class("hidden")
        self.query_one("#col-stories").add_class("hidden")
        self.query_one("#columns").mount(terminal)
        # Focus after the widget is actually in the DOM, else keys keep going to
        # the columns and the session looks frozen.
        self.call_after_refresh(terminal.focus)
        self.notify(note or "Launched here — press F10 to close the session pane")

    def on_embedded_terminal_exited(self, event: EmbeddedTerminal.Exited) -> None:
        """Close the pane when its session ends (F10 or the process exiting)."""
        self._close_embedded()

    def _close_embedded(self) -> None:
        if self._embedded is None:
            return
        terminal = self._embedded
        self._embedded = None  # first, so a re-entrant Exited is a no-op
        if terminal.is_mounted:
            terminal.remove()
        self.query_one("#col-epics").remove_class("hidden")
        self.query_one("#col-stories").remove_class("hidden")
        self.query_one("#epics", OptionList).focus()

    def action_launch_inline(self) -> None:
        """Run the focused target's session inline, taking over the whole terminal.

        The board suspends (drops its screen), claude runs full-size in this same
        terminal, and the board is restored exactly where it was when the session
        exits. Blocking is the point here — you're in the session until you leave it.
        """
        action, note = self._launch_target()
        if action is None or action.command is None:
            self.notify(note or "Nothing to launch here", severity="warning")
            return
        argv, cwd = launcher.direct_launch(str(self._current_project.path), action)
        with self._suspend():
            self._runner(argv, cwd=cwd)
        if note:
            self.notify(note)

    def action_launch_detached(self) -> None:
        """Open the focused target's session in a new, detached terminal window.

        The board does not block, so instead of running claude in-place we hand the
        command to the OS terminal, which owns its own window. Control returns here
        immediately and the board stays interactive — good for several sessions at
        once.
        """
        action, note = self._launch_target()
        if action is None or action.command is None:
            self.notify(note or "Nothing to launch here", severity="warning")
            return
        try:
            argv = launcher.terminal_launch(
                str(self._current_project.path), action, platform=self._platform
            )
        except launcher.UnsupportedTerminalError as exc:
            self.notify(str(exc), severity="error")
            return
        self._runner(argv)
        self.notify(note or f"Launched in a new terminal: {action.command}")


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
