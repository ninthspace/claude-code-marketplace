"""Tests for the projects-column "live" pill.

A launch records its tmux session; while that session is alive the project shows a
`● live` pill. Each watch tick polls the (injected) session lister and drops
sessions that have ended, clearing the pill. The lister is only consulted when
there is something to track, so a board that never launches never polls tmux.
"""

from __future__ import annotations

import contextlib

import pytest

from rich.console import Console, RenderableType
from textual.widgets import OptionList

import board_view
from board import BoardApp
from launcher import tmux_session_name
from registry import RegistryEntry
from status_model import derive_project

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}


def _render(renderable: RenderableType, width: int = 60) -> str:
    """Render a Rich renderable (Text or the live-pill grid) to a plain string, so a
    row's text and the pill's right-alignment can be asserted uniformly."""
    console = Console(width=width, color_system=None)  # no ANSI styling in the capture
    with console.capture() as capture:
        console.print(renderable, end="")
    return capture.get().rstrip("\n")


def _board(repo, cache_root, *, runner=None, lister=None):
    return BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        runner=runner or (lambda argv: None),
        tmux_available=True,
        in_tmux=False,
        session_suffix=lambda: "s",
        window_lister=lister or (lambda: {}),
        attach_suspend=lambda: contextlib.nullcontext(),  # detached launch attaches
    )


def _projects_text(app) -> str:
    return _render(app.query_one("#projects", OptionList).get_option_at_index(0).prompt)


# --- rendering ---------------------------------------------------------------


def test_project_row_text_appends_pill_only_when_live(make_project, cache_root):
    status = derive_project(make_project(EPICS_READY))
    assert "● live" not in _render(board_view.project_row_text("proj", status, live=False))
    live = _render(board_view.project_row_text("proj", status, live=True), width=40)
    # Present, and right-aligned: the pill hugs the far right edge, well past the label.
    assert "● live" in live
    assert live.endswith("● live")
    assert live.index("proj") < live.index("●") - 5  # padding between label and pill


# --- launch → pill -----------------------------------------------------------


async def test_launch_marks_the_project_live(make_project, cache_root):
    repo = make_project(EPICS_READY)
    session = tmux_session_name(str(repo), "s")
    app = _board(repo, cache_root, lister=lambda: {session: "@0"})
    async with app.run_test() as pilot:
        assert "● live" not in _projects_text(app)  # nothing running yet
        await pilot.press("l")
        await pilot.pause()

        assert app._live_sessions == {session: str(repo)}
        assert "● live" in _projects_text(app)


async def test_watch_tick_captures_the_window_id_handle(make_project, cache_root):
    repo = make_project(EPICS_READY)
    session = tmux_session_name(str(repo), "s")
    app = _board(repo, cache_root, lister=lambda: {session: "@7"})
    async with app.run_test() as pilot:
        await pilot.press("l")
        await pilot.pause()
        assert app._live_windows == {}  # not captured yet — filled by the poll

        app._on_tick()
        await pilot.pause()
        # The native #{window_id} handle is captured from the liveness poll.
        assert app._live_windows == {session: "@7"}


async def test_watch_tick_clears_the_pill_when_the_session_ends(make_project, cache_root):
    repo = make_project(EPICS_READY)
    session = tmux_session_name(str(repo), "s")
    live: dict[str, str] = {session: "@0"}
    app = _board(repo, cache_root, lister=lambda: dict(live))
    async with app.run_test() as pilot:
        await pilot.press("l")
        await pilot.pause()
        assert "● live" in _projects_text(app)

        live.clear()  # the session ends (Claude exited → tmux session gone)
        app._on_tick()
        await pilot.pause()

        assert app._live_sessions == {}
        assert app._live_windows == {}
        assert "● live" not in _projects_text(app)


async def test_watch_tick_drops_a_session_whose_window_id_changed(make_project, cache_root):
    repo = make_project(EPICS_READY)
    session = tmux_session_name(str(repo), "s")
    current: dict[str, str] = {session: "@0"}
    app = _board(repo, cache_root, lister=lambda: dict(current))
    async with app.run_test() as pilot:
        await pilot.press("l")
        await pilot.pause()
        app._on_tick()  # capture @0
        await pilot.pause()
        assert app._live_windows == {session: "@0"}

        # Same name, different window — the tracked session is gone (name reused).
        current[session] = "@9"
        app._on_tick()
        await pilot.pause()

        assert app._live_sessions == {}
        assert "● live" not in _projects_text(app)


async def test_tick_does_not_poll_tmux_when_nothing_launched(make_project, cache_root):
    repo = make_project(EPICS_READY)
    polled: list[int] = []

    def lister() -> dict[str, str]:
        polled.append(1)
        return {}

    app = _board(repo, cache_root, lister=lister)
    async with app.run_test() as pilot:
        app._on_tick()
        await pilot.pause()

    # No launch → nothing to track → the lister is never consulted.
    assert polled == []
