"""Feature tests for the embedded-pane launch (`l`, spike — A).

Pressing `l` runs the focused target in a PTY terminal widget covering the epics +
stories columns, with the projects column still visible. F10 or the session
exiting closes the pane and restores the columns. The fork/exec is stubbed via the
`terminal_spawn` seam so no real child is spawned; the stub instead holds the pty
slave open (as a real child would) so the master doesn't hit EOF, then closing it
simulates the session exiting. The widget still opens a real pty and drives its
reader/teardown, so the lifecycle wiring is exercised for real.
"""

from __future__ import annotations

import os

import pytest

from textual.app import App, ComposeResult

from board import BoardApp
from embedded_terminal import EmbeddedTerminal
from registry import RegistryEntry

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}

# A pid that does not exist, so the widget's teardown SIGHUP is a harmless no-op.
DEAD_PID = 999_999


class FakeSpawner:
    """Stub for the fork/exec seam that records calls and keeps the slave open.

    A real child inherits and holds the pty slave; without that the master would
    read EOF the instant the parent closes its slave, and the pane would self-close.
    The stub dups the slave to hold it open, and `end_session()` closes it to
    simulate the child exiting.
    """

    def __init__(self) -> None:
        self.calls: list = []
        self._slaves: list[int] = []

    def __call__(self, argv: list[str], cwd: str, fd: int) -> int:
        self.calls.append((argv, cwd))
        self._slaves.append(os.dup(fd))
        return DEAD_PID

    def end_session(self) -> None:
        for fd in self._slaves:
            os.close(fd)
        self._slaves.clear()

    def cleanup(self) -> None:
        for fd in self._slaves:
            try:
                os.close(fd)
            except OSError:
                pass
        self._slaves.clear()


@pytest.fixture
def spawner():
    s = FakeSpawner()
    yield s
    s.cleanup()


def board(repo, cache_root, spawner):
    return BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        terminal_spawn=spawner,
    )


async def test_l_opens_an_embedded_pane_over_the_side_columns(make_project, cache_root, spawner):
    repo = make_project(EPICS_READY)
    async with board(repo, cache_root, spawner).run_test() as pilot:
        await pilot.press("l")
        await pilot.pause()

        app = pilot.app
        # The pane mounted with the bare /cpm:do for this project, in its cwd.
        assert spawner.calls == [(["claude", "/cpm:do"], str(repo))]
        assert isinstance(app.query_one("#embedded"), EmbeddedTerminal)
        # Epics + stories are hidden behind it; projects stays visible.
        assert app.query_one("#col-epics").has_class("hidden")
        assert app.query_one("#col-stories").has_class("hidden")
        assert not app.query_one("#col-projects").has_class("hidden")


async def test_f10_closes_the_pane_and_restores_the_columns(make_project, cache_root, spawner):
    repo = make_project(EPICS_READY)
    async with board(repo, cache_root, spawner).run_test() as pilot:
        await pilot.press("l")
        await pilot.pause()
        assert pilot.app.query("#embedded")  # open

        await pilot.press("f10")
        await pilot.pause()

        app = pilot.app
        assert not app.query("#embedded")  # pane gone
        assert not app.query_one("#col-epics").has_class("hidden")
        assert not app.query_one("#col-stories").has_class("hidden")


async def test_pane_closes_when_the_session_exits(make_project, cache_root, spawner):
    repo = make_project(EPICS_READY)
    async with board(repo, cache_root, spawner).run_test() as pilot:
        await pilot.press("l")
        await pilot.pause()
        assert pilot.app.query("#embedded")

        spawner.end_session()  # child exits → EOF on the pty master
        await pilot.pause()

        assert not pilot.app.query("#embedded")  # pane auto-closed
        assert not pilot.app.query_one("#col-epics").has_class("hidden")


class _Host(App):
    """A minimal app hosting a single terminal, for widget-level render tests."""

    def __init__(self, spawner: FakeSpawner) -> None:
        super().__init__()
        self._spawner = spawner

    def compose(self) -> ComposeResult:
        yield EmbeddedTerminal(["sh"], cwd=".", spawn=self._spawner, id="t")


async def test_cursor_is_drawn_as_a_reverse_block_when_focused(spawner):
    async with _Host(spawner).run_test(size=(20, 5)) as pilot:
        term = pilot.app.query_one("#t", EmbeddedTerminal)
        await pilot.pause()
        assert term.has_focus  # keys route here; cursor should show

        # Move the cursor to row 0, column 3 (ESC [ row ; col H is 1-based).
        term._stream.feed(b"\x1b[1;4H")
        cursor = term._screen.cursor
        assert (cursor.y, cursor.x) == (0, 3)

        strip = term.render_line(0)
        # The cell under the cursor is reverse-video; its neighbours are not.
        cells = list(strip)
        assert cells[3].style.reverse is True
        assert not cells[2].style.reverse


async def test_a_second_l_does_not_stack_panes(make_project, cache_root, spawner):
    repo = make_project(EPICS_READY)
    async with board(repo, cache_root, spawner).run_test() as pilot:
        await pilot.press("l")
        await pilot.pause()
        await pilot.press("l")  # ignored while a session pane is live
        await pilot.pause()

        assert len(spawner.calls) == 1
        assert len(pilot.app.query("#embedded")) == 1
