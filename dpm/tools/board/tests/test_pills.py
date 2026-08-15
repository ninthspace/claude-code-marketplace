"""Story 4 — the live-session pill (FR12).

Every criterion here is read from the **painted Projects column**, over a real tmux server of the
suite's own. The pill is a rendered string, so the negative cases are what carry the requirement:
a pill that appears for any running session, or one that never goes away, satisfies "shows a pill"
perfectly.

The third criterion is the load-bearing one. FR12's own criteria are met by a board that counts
every tmux session in a project — which is what a board without the guard check does, and it would
light up for a CPM board's session in the same directory. The control here is exactly that session.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from shutil import rmtree
from tempfile import mkdtemp

import pytest
from pilot import board, lines, until

from board_view import LIVE, ProjectView, live_pill
from launcher import LAUNCHED_OPTION, live_sessions, session_name


@pytest.fixture
def tmux(monkeypatch):
    """A tmux server of this test's own, killed on the way out. See `test_tmux.py` for why."""
    directory = Path(mkdtemp(prefix="dpm-pills-", dir="/tmp"))
    monkeypatch.setenv("TMUX_TMPDIR", str(directory))
    monkeypatch.delenv("TMUX", raising=False)

    def call(*arguments: str) -> subprocess.CompletedProcess:
        return subprocess.run(["tmux", *arguments], capture_output=True, text=True)

    yield call

    call("kill-server")
    rmtree(directory, ignore_errors=True)


def start(tmux, name: str, root: Path, *, launched: bool = True) -> None:
    """A live session in ``root``, marked as the board's unless the test says otherwise."""
    tmux("new-session", "-d", "-s", name, "-c", str(root))

    if launched:
        tmux("set-option", "-t", name, LAUNCHED_OPTION, "1")


def project(root: Path) -> ProjectView:
    return ProjectView(name=root.name, path=root)


def pill_of(app) -> str:
    """The pill on the only project row, or empty — read from what the column painted."""
    row = next((line for line in lines(app, "projects") if line), "")

    return row[row.index(LIVE) :] if LIVE in row else ""


async def test_a_project_with_a_launched_session_shows_the_pill(tmp_path, tmux):
    """Criterion 1's first half, from the rendered row.

    The board is given the real reader, so what is asserted is the whole path: tmux is asked, the
    answer is counted, the row is rebuilt and the column repaints — off the UI thread throughout.
    """
    root = tmp_path / "alpha"
    root.mkdir()
    start(tmux, session_name(root, "one"), root)

    async with board([project(root)], sessions=live_sessions) as (app, pilot):
        arrived = await until(pilot, lambda: pill_of(app) == LIVE)
        painted = pill_of(app)

    assert arrived, f"no pill for a project with a live session: {painted!r}"


async def test_several_sessions_carry_a_count(tmp_path, tmux):
    """Criterion 1's second half. Three, not two: `● live 2` and a pill that appends the count of
    *anything* agree at two, and one of those two rules is wrong."""
    root = tmp_path / "beta"
    root.mkdir()

    for index in range(3):
        start(tmux, session_name(root, str(index)), root)

    async with board([project(root)], sessions=live_sessions) as (app, pilot):
        arrived = await until(pilot, lambda: pill_of(app) == f"{LIVE} 3")
        painted = pill_of(app)

    assert arrived, f"three live sessions rendered as {painted!r}"


async def test_the_pill_is_dropped_when_the_session_ends(tmp_path, tmux):
    """Criterion 2's first half, with the pill's arrival as its own control.

    Asserting only the absence would pass on a board that never showed a pill at all, so the pill
    has to be *there* before the session is killed and gone afterwards.
    """
    root = tmp_path / "gamma"
    root.mkdir()
    name = session_name(root, "one")
    start(tmux, name, root)

    async with board([project(root)], sessions=live_sessions) as (app, pilot):
        assert await until(pilot, lambda: pill_of(app) == LIVE), "the pill never appeared"

        tmux("kill-session", "-t", f"={name}")

        dropped = await until(pilot, lambda: pill_of(app) == "")
        painted = pill_of(app)

    assert dropped, f"the pill outlived its session: {painted!r}"


async def test_the_pill_is_dropped_when_the_window_id_changes(tmp_path, tmux):
    """Criterion 2's second half — a session *replaced* rather than closed.

    The session name is the same and it is still guarded, so a board counting live sessions by name
    sees no change at all. The window id is the handle that does change, and it is the only thing
    that distinguishes the session the board launched from whatever took its place.
    """
    root = tmp_path / "delta"
    root.mkdir()
    name = session_name(root, "one")
    start(tmux, name, root)

    async with board([project(root)], sessions=live_sessions) as (app, pilot):
        assert await until(pilot, lambda: pill_of(app) == LIVE), "the pill never appeared"

        # A new window in the same session, and the original killed: the session lives on under a
        # window it did not start with.
        tmux("new-window", "-t", f"={name}", "-c", str(root))
        tmux("kill-window", "-t", f"={name}:0")

        dropped = await until(pilot, lambda: pill_of(app) == "")
        painted = pill_of(app)

    assert dropped, f"the pill survived the session being replaced: {painted!r}"


async def test_a_session_the_board_did_not_launch_produces_no_pill(tmp_path, tmux):
    """Criterion 3, with the forbidden condition actually present.

    The session is real, running, and in the project's own directory — everything a pill needs
    except the mark the board puts on its own. Without that check this test is the one that fails,
    and with no session at all it would assert nothing.
    """
    root = tmp_path / "epsilon"
    root.mkdir()
    start(tmux, "someone-elses", root, launched=False)

    assert live_sessions() == [], "the stranger session is not visible to the board's own reader"

    async with board([project(root)], sessions=live_sessions) as (app, pilot):
        for _ in range(5):
            await pilot.pause(0.05)

        painted = pill_of(app)

    # And the same board *does* show a pill when the session is its own, so the absence above is
    # about the guard rather than about a poll that never ran.
    start(tmux, session_name(root, "ours"), root)

    async with board([project(root)], sessions=live_sessions) as (app, pilot):
        arrived = await until(pilot, lambda: pill_of(app) == LIVE)

    assert painted == "", f"a session the board did not launch produced {painted!r}"
    assert arrived, "the board shows no pill for its own session either, so the check above is idle"


def test_the_count_appears_only_when_there_is_more_than_one():
    """The pill's own rule, stated where it is decided.

    "● live 1" reads as one of something the reader is now looking for a second of; the bare pill
    is the ordinary case, and the number is what marks the unusual one.
    """
    assert live_pill(0) == ""
    assert live_pill(1) == LIVE
    assert live_pill(2) == f"{LIVE} 2"
