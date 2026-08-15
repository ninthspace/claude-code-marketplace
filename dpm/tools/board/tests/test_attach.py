"""Story 3 — `t` attaches to the most recently used live session (FR8, ENV6).

**Three sessions, not two.** "Most recently used" and "last created" agree whenever there are two
of them, and they are different rules; the fixture here makes the middle-created session the most
recently used, so a board that picked the newest and a board that picked the oldest both fail.

What is asserted is the *choice* and the enumeration behind it, over a real tmux server. The attach
itself — one ``subprocess.run`` handing this terminal to tmux — is not driven here: a real attach
needs a controlling terminal, and a test with one would be asserting on pytest's own tty rather
than on the board. Its argv is checked against the server in `test_tmux.py`, which is the half that
can be wrong without a client.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from shutil import rmtree
from tempfile import mkdtemp
from time import monotonic, sleep

import pytest

from board_view import ProjectView
from launcher import (
    LAUNCHED_OPTION,
    Session,
    attach_target,
    live_sessions,
    parse_sessions,
    session_name,
)

#: How long to wait between the three creations. tmux's activity clock counts whole seconds, so
#: sessions created inside one second are indistinguishable by it — which is a property of tmux
#: rather than of the fixture, and the reason the wait is here rather than nowhere.
GAP = 1.1


@pytest.fixture
def tmux(monkeypatch):
    """A tmux server of this test's own, killed on the way out. See `test_tmux.py` for why."""
    directory = Path(mkdtemp(prefix="dpm-attach-", dir="/tmp"))
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


def activity(tmux) -> dict[str, int]:
    """What tmux itself says each session's latest window activity is.

    Asked of the server rather than of :func:`parse_sessions`, so the fixture below establishes its
    precondition from an outside witness instead of from the code the tests then assert about.
    """
    listed = tmux("list-windows", "-a", "-F", "#{session_name}\t#{window_activity}").stdout
    latest: dict[str, int] = {}

    for line in listed.splitlines():
        name, _, when = line.partition("\t")

        if when.strip().isdigit():
            latest[name] = max(latest.get(name, 0), int(when))

    return latest


def use(tmux, name: str, *, timeout: float = 10.0) -> None:
    """Make ``name`` the most recently used session, the way a user would: by working in it.

    **Waited for rather than slept past.** ``send-keys`` reaches the pane whether or not the shell
    attached to it has finished starting, and tmux records the activity when the output arrives —
    so a fixed sleep is a bet on how long a shell takes to start, and it is one this fixture lost
    about one run in five, as the session created *after* this one winning the comparison this one
    was set up to win. Retried until tmux's own answer says the precondition holds.
    """
    deadline = monotonic() + timeout

    while monotonic() < deadline:
        tmux("send-keys", "-t", name, "echo used", "Enter")
        sleep(0.4)
        seen = activity(tmux)

        # Strictly ahead of every other session, because tmux's clock counts whole seconds: an
        # activity equal to another session's is a tie, and a tie is decided by neither rule.
        if name in seen and all(when < seen[name] for other, when in seen.items() if other != name):
            return

    raise AssertionError(f"{name} never became the most recently used session: {activity(tmux)}")


def three_sessions(tmux, root: Path) -> list[str]:
    """Three launched sessions for one project, created oldest first."""
    names = [session_name(root, str(index)) for index in range(1, 4)]

    for name in names:
        start(tmux, name, root)
        sleep(GAP)

    return names


async def test_the_most_recently_used_session_is_neither_the_first_nor_the_last_created(
    tmp_path, tmux
):
    """Criterion 2, which is criterion 1's only falsifiable form.

    The middle session is used after all three exist, so "most recently used" is the one rule that
    names it: newest-created answers the third, oldest-created answers the first, and creation
    order in either direction is wrong.
    """
    root = tmp_path / "alpha"
    root.mkdir()

    first, middle, last = three_sessions(tmux, root)
    use(tmux, middle)

    chosen = attach_target(root)

    assert chosen == middle, f"`t` would attach to {chosen} rather than to {middle}"
    assert chosen not in (first, last), "the choice is creation order, not use"


async def test_attaching_names_a_session_of_the_selected_project(tmp_path, tmux):
    """Criterion 1's "for the selected project" half.

    Two projects with live sessions, and the answer for each is its own. The scoping is by the
    directory the session was started in rather than by the project name inside the session's own
    name: two registered projects can share a directory basename, and the name would then put one
    project's sessions on the other's row.
    """
    alpha = tmp_path / "one" / "shared-name"
    beta = tmp_path / "two" / "shared-name"

    for root in (alpha, beta):
        root.mkdir(parents=True)

    start(tmux, "dpm-shared-name-a", alpha)
    sleep(GAP)
    start(tmux, "dpm-shared-name-b", beta)

    assert attach_target(alpha) == "dpm-shared-name-a"
    assert attach_target(beta) == "dpm-shared-name-b"


async def test_a_session_the_board_did_not_launch_is_not_attached_to(tmp_path, tmux):
    """The guard, at the enumeration rather than at the binding.

    The control is a session in the *same project directory*, newer than the board's own and
    therefore the one every rule but the guard would choose. Without the option check `t` would
    drop the user into a stranger's session — CPM's board, or a shell they left running.
    """
    root = tmp_path / "gamma"
    root.mkdir()

    start(tmux, session_name(root, "ours"), root)
    sleep(GAP)
    start(tmux, "someone-elses", root, launched=False)
    use(tmux, "someone-elses")

    live = live_sessions(root)

    assert [session.name for session in live] == [session_name(root, "ours")], (
        f"the board counted a session it did not launch: {live}"
    )
    assert attach_target(root) == session_name(root, "ours")


async def test_no_live_session_is_no_target_rather_than_an_error(tmp_path, tmux):
    """A project with nothing running, which is most projects most of the time.

    ``list-windows`` exits non-zero when no server is running at all, and a board that treated that
    as a failure would report an error every time a user pressed `t` before launching anything.
    """
    root = tmp_path / "delta"
    root.mkdir()

    assert live_sessions(root) == []
    assert attach_target(root) is None


def test_a_session_ranks_by_its_windows_latest_activity():
    """The parse, over lines tmux would emit — including the two ways it can be wrong.

    A session with several windows takes the latest of them, and a row without the guard option is
    dropped. Both are decided here rather than at the call sites, which is what keeps the pill
    (FR12) and the attach from disagreeing about which sessions are the board's.
    """
    lines = "\n".join(
        (
            "dpm-alpha-1\t/tmp/alpha\t100\t1\t@0",
            "dpm-alpha-1\t/tmp/alpha\t400\t1\t@1",
            "dpm-alpha-2\t/tmp/alpha\t200\t1\t@2",
            "stranger\t/tmp/alpha\t900\t\t@3",
        )
    )

    parsed = {session.name: session for session in parse_sessions(lines)}

    assert set(parsed) == {"dpm-alpha-1", "dpm-alpha-2"}, (
        f"a session without the guard option survived the parse: {sorted(parsed)}"
    )
    assert parsed["dpm-alpha-1"] == Session("dpm-alpha-1", "/tmp/alpha", 400, "@1"), (
        f"a session took an older window's activity: {parsed['dpm-alpha-1']}"
    )


async def test_the_board_attaches_to_the_session_the_launcher_chose(tmp_path, tmux):
    """`t` from the board, down to the session name, with the attach itself stubbed out.

    The board's half of the criterion is that the key reaches the launcher with the *selected
    project*; the launcher's half is which of that project's sessions it picks. This joins the two
    without handing the test's terminal to tmux.
    """
    from pilot import board

    from launcher import ATTACH

    root = tmp_path / "epsilon"
    root.mkdir()

    _, middle, _ = three_sessions(tmux, root)
    use(tmux, middle)

    reached = []

    def launch(intent, project, target):
        # The real launcher's attach branch, minus the one line that hands over the terminal: it
        # asks `attach_target` for this project and joins what it names.
        reached.append((intent, attach_target(project.path)))

    async with board([ProjectView(name="epsilon", path=root)], launch=launch) as (app, pilot):
        await pilot.press("t")
        await pilot.pause()

    assert reached == [(ATTACH, middle)], (
        f"`t` reached the launcher as {reached} rather than an attach to {middle}"
    )
