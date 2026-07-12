"""Feature tests for attach (`t`) — "launch within the TUI".

Attach hands the board's own terminal to a live tmux session instead of opening a
separate window. Inside tmux it `switch-client`s; otherwise it **suspends** the
board UI, runs `tmux attach` in the foreground, and resumes on detach. It targets
the newest live session the board launched for the highlighted project.

The suspend is injected as a recording no-op context manager (the headless test
driver can't really suspend), and the runner is stubbed, so the emitted argv and
the suspend behaviour are asserted without touching a real tmux server or the tty.
"""

from __future__ import annotations

import contextlib

import pytest

from board import BoardApp
from launcher import tmux_session_name
from registry import RegistryEntry

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}


class _RecordingSuspend:
    """A stand-in for ``App.suspend``: records entries and yields a no-op context."""

    def __init__(self) -> None:
        self.entered = 0

    def __call__(self):
        self.entered += 1
        return contextlib.nullcontext()


def _attach_board(repo, cache_root, calls, *, in_tmux, suspend, lister, activity=None):
    return BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        runner=calls.append,
        tmux_available=True,
        in_tmux=in_tmux,
        session_suffix=lambda: "s",
        window_lister=lister,
        activity_lister=activity or (lambda: {}),
        attach_suspend=suspend,
    )


async def test_attach_suspends_and_attaches_when_not_in_tmux(make_project, cache_root):
    repo = make_project(EPICS_READY)
    session = tmux_session_name(str(repo), "s")
    calls: list = []
    suspend = _RecordingSuspend()
    app = _attach_board(
        repo, cache_root, calls, in_tmux=False, suspend=suspend, lister=lambda: {session: "@0"}
    )
    async with app.run_test() as pilot:
        app._live_sessions[session] = str(repo)  # a running session to attach to
        await pilot.press("t")
        await pilot.pause()

    # The board dropped its UI once, then attached in the foreground.
    assert suspend.entered == 1
    assert calls == [["tmux", "attach", "-t", f"={session}"]]


async def test_attach_switches_client_when_in_tmux(make_project, cache_root):
    repo = make_project(EPICS_READY)
    session = tmux_session_name(str(repo), "s")
    calls: list = []
    suspend = _RecordingSuspend()
    app = _attach_board(
        repo, cache_root, calls, in_tmux=True, suspend=suspend, lister=lambda: {session: "@0"}
    )
    async with app.run_test() as pilot:
        app._live_sessions[session] = str(repo)
        await pilot.press("t")
        await pilot.pause()

    # Inside tmux a nested attach is disallowed → switch-client, and no suspend.
    assert suspend.entered == 0
    assert calls == [["tmux", "switch-client", "-t", f"={session}"]]


async def test_attach_with_no_live_session_warns_and_does_nothing(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    suspend = _RecordingSuspend()
    app = _attach_board(
        repo, cache_root, calls, in_tmux=False, suspend=suspend, lister=lambda: {}
    )
    async with app.run_test() as pilot:
        # Nothing launched → nothing to attach to.
        await pilot.press("t")
        await pilot.pause()

    assert suspend.entered == 0
    assert calls == []


async def test_attach_prunes_a_dead_session_before_attaching(make_project, cache_root):
    repo = make_project(EPICS_READY)
    session = tmux_session_name(str(repo), "s")
    calls: list = []
    suspend = _RecordingSuspend()
    # The board thinks the session is live, but tmux reports it gone.
    app = _attach_board(
        repo, cache_root, calls, in_tmux=False, suspend=suspend, lister=lambda: {}
    )
    async with app.run_test() as pilot:
        app._live_sessions[session] = str(repo)
        await pilot.press("t")
        await pilot.pause()

        # Attach refused (session already ended) and the stale record was pruned.
        assert app._live_sessions == {}
    assert suspend.entered == 0
    assert calls == []


async def test_attach_targets_the_highlighted_projects_session(make_project, cache_root):
    repo_a = make_project(EPICS_READY, name="alpha")
    repo_b = make_project(EPICS_READY, name="beta")
    session_b = tmux_session_name(str(repo_b), "s")
    calls: list = []
    suspend = _RecordingSuspend()
    app = BoardApp(
        entries=[RegistryEntry(str(repo_a), "Alpha"), RegistryEntry(str(repo_b), "Beta")],
        cache_root=cache_root,
        watch_interval=None,
        runner=calls.append,
        tmux_available=True,
        in_tmux=False,
        session_suffix=lambda: "s",
        window_lister=lambda: {session_b: "@0"},
        activity_lister=lambda: {},
        attach_suspend=suspend,
    )
    async with app.run_test() as pilot:
        app._live_sessions[session_b] = str(repo_b)
        # Highlight the second project, then attach → its session, not the first's.
        await pilot.press("down")
        await pilot.pause()
        await pilot.press("t")
        await pilot.pause()

    assert calls == [["tmux", "attach", "-t", f"={session_b}"]]


async def test_attach_targets_most_recently_accessed_session(make_project, cache_root):
    repo = make_project(EPICS_READY)
    older = tmux_session_name(str(repo), "1")
    newer = tmux_session_name(str(repo), "2")
    calls: list = []
    suspend = _RecordingSuspend()
    # Both sessions live; `older` was launched first (newest-launched would pick
    # `newer`), but the user last attached to `older` (higher last_attached epoch).
    app = _attach_board(
        repo,
        cache_root,
        calls,
        in_tmux=False,
        suspend=suspend,
        lister=lambda: {older: "@0", newer: "@1"},
        activity=lambda: {older: 1720800100, newer: 1720800000},
    )
    async with app.run_test() as pilot:
        app._live_sessions[older] = str(repo)
        app._live_sessions[newer] = str(repo)
        await pilot.press("t")
        await pilot.pause()

    # Most recently accessed wins over newest-launched.
    assert calls == [["tmux", "attach", "-t", f"={older}"]]


async def test_attach_falls_back_to_newest_launched_without_activity(make_project, cache_root):
    repo = make_project(EPICS_READY)
    older = tmux_session_name(str(repo), "1")
    newer = tmux_session_name(str(repo), "2")
    calls: list = []
    suspend = _RecordingSuspend()
    # No attach records for either (never attached) → tie broken by launch order.
    app = _attach_board(
        repo,
        cache_root,
        calls,
        in_tmux=False,
        suspend=suspend,
        lister=lambda: {older: "@0", newer: "@1"},
        activity=lambda: {},
    )
    async with app.run_test() as pilot:
        app._live_sessions[older] = str(repo)
        app._live_sessions[newer] = str(repo)
        await pilot.press("t")
        await pilot.pause()

    assert calls == [["tmux", "attach", "-t", f"={newer}"]]
