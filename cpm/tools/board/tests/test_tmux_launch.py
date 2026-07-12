"""Tests for the tmux launch backend (Linux/WSL, and anywhere tmux is preferred).

Two layers, matching the rest of the board:

- **Launcher unit tests** — Textual-free, asserting `select_launch_backend`,
  `tmux_session_name`, the `tmux_launch` / `open_tmux_launch` argv *plans*, and
  `tmux_attach_hint` directly. The security-critical property carries over from
  the clipboard layer: tmux runs a single trailing command *string* via its own
  shell, so that string is the exact shlex-quoted `cd … && claude …` command and
  it tokenises back to the same argv — no new escaping layer, no shell at our
  layer (each tmux call is an argv list, never a shell string).
- **Board Pilot tests** — the `l` / `o` keys dispatched through the tmux backend
  with the `tmux_available` / `in_tmux` / `session_suffix` seams pinned, so the
  emitted tmux argv sequence is asserted without a real server.
"""

from __future__ import annotations

import contextlib
import shlex

import pytest

from launcher import (
    LAUNCHED_OPTION,
    _return_hint,
    open_tmux_launch,
    select_launch_backend,
    tmux_attach_argv,
    tmux_attach_hint,
    tmux_bind_return_argv,
    tmux_launch,
    tmux_mark_launched_argv,
    tmux_session_name,
    tmux_switch_argv,
)
from registry import RegistryEntry
from status_model import NextAction

from board import BoardApp
from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


NASTY_PATH = "/tmp/a b'; rm -rf ~ #"


def do_action(command="/cpm:do docs/epics/39-01-epic-foo.md"):
    return NextAction("do", command, "docs/epics/39-01-epic-foo.md", "Start foo")


# --- backend selection -------------------------------------------------------


def test_backend_is_tmux_when_available_else_none():
    # tmux is the only backend: present → "tmux"; absent → None (copy fallback).
    assert select_launch_backend(tmux_available=True) == "tmux"
    assert select_launch_backend(tmux_available=False) is None


# --- session naming ----------------------------------------------------------


def test_session_name_is_cpm_prefixed_and_sanitised():
    # tmux forbids `.`/`:` in names; the project basename is sanitised to
    # [A-Za-z0-9_-] and the per-launch suffix keeps repeats from colliding.
    assert tmux_session_name("/home/me/my.proj", "17") == "cpm-my-proj-17"


def test_session_name_survives_a_metacharacter_laden_path():
    name = tmux_session_name(NASTY_PATH, "0")
    # Whatever the path, the result is a legal tmux session token.
    assert name.startswith("cpm-")
    assert all(ch.isalnum() or ch in "-_" for ch in name)


# --- tmux launch plan: argv lists, never shell strings -----------------------


def _status_argv(session):
    """The expected `set-option status-right` argv the plan pins to a session. Refers
    to ``_return_hint`` so these plan assertions don't churn when the hint's key
    combo changes — only the dedicated hint test below pins the literal text.

    Note the bare ``session`` target (no ``=`` prefix): ``set-option -t`` rejects the
    exact-match ``=`` that ``switch-client``/``attach`` require, so the plan targets
    the exact session name directly."""
    return ["tmux", "set-option", "-t", session, "status-right", _return_hint()]


def test_return_hint_names_the_key_to_get_back_to_the_board():
    # Uniform in both run modes: the tmux prefix binding Ctrl-b o returns to the board
    # whether the board is inside tmux (switch-client) or detached (detach-client).
    assert _return_hint() == " C-b o → cpm board "


def test_tmux_launch_detached_plan_when_not_inside_tmux():
    plan = tmux_launch("/home/me/proj", do_action(), "cpm-proj-1", attach=False)

    # A detached new-session (trailing element is the whole command string — tmux
    # runs it via its own shell, one argv element, not split), the @cpm_launched
    # marker, then the status-line "how to get back" reminder.
    assert plan == [
        [
            "tmux",
            "new-session",
            "-d",
            "-s",
            "cpm-proj-1",
            "cd /home/me/proj && claude '/cpm:do docs/epics/39-01-epic-foo.md'",
        ],
        tmux_mark_launched_argv("cpm-proj-1"),
        _status_argv("cpm-proj-1"),
    ]


def test_tmux_launch_appends_switch_client_when_inside_tmux():
    plan = tmux_launch("/home/me/proj", do_action(), "cpm-proj-1", attach=True)

    # Inside tmux the caller is switched into the new session (after the marker and
    # status reminder); `=name` is exact-match targeting so a prefix can't hit the wrong one.
    assert plan[0][:5] == ["tmux", "new-session", "-d", "-s", "cpm-proj-1"]
    assert plan[1] == tmux_mark_launched_argv("cpm-proj-1")
    assert plan[2] == _status_argv("cpm-proj-1")
    assert plan[3] == ["tmux", "switch-client", "-t", "=cpm-proj-1"]


def test_open_tmux_launch_runs_a_plain_claude():
    plan = open_tmux_launch("/home/me/proj", "cpm-proj-1", attach=False)
    assert plan == [
        ["tmux", "new-session", "-d", "-s", "cpm-proj-1", "cd /home/me/proj && claude"],
        tmux_mark_launched_argv("cpm-proj-1"),
        _status_argv("cpm-proj-1"),
    ]


def test_mark_launched_argv_sets_the_session_marker():
    # The marker the global Ctrl-Space binding tests; bare target (set-option rejects `=`).
    assert tmux_mark_launched_argv("cpm-proj-1") == [
        "tmux", "set-option", "-t", "cpm-proj-1", LAUNCHED_OPTION, "1",
    ]


def test_tmux_command_string_is_shell_safe_across_a_nasty_path():
    plan = tmux_launch(NASTY_PATH, do_action(), "cpm-x-1", attach=False)
    command = plan[0][-1]
    # The command tmux will run tokenises back to exactly the intended args — no
    # metacharacter leaked out as a separate word or operator.
    assert shlex.split(command) == [
        "cd",
        NASTY_PATH,
        "&&",
        "claude",
        "/cpm:do docs/epics/39-01-epic-foo.md",
    ]


def test_tmux_attach_hint_uses_exact_match_targeting():
    assert tmux_attach_hint("cpm-proj-1") == "tmux attach -t =cpm-proj-1"


def test_switch_and_attach_argv_use_exact_match_targeting():
    # Both target `=session` (exact) so a prefix can't hit the wrong session.
    assert tmux_switch_argv("cpm-proj-1") == ["tmux", "switch-client", "-t", "=cpm-proj-1"]
    assert tmux_attach_argv("cpm-proj-1") == ["tmux", "attach", "-t", "=cpm-proj-1"]


def test_set_option_targets_the_bare_session_not_exact_match():
    # Regression: `set-option -t =name` fails with "no such session" — set-option
    # rejects the `=` exact-match prefix that switch-client/attach accept. Every
    # set-option in the plan (marker + status hint) must target the bare, exact name.
    plan = tmux_launch("/home/me/proj", do_action(), "cpm-proj-1", attach=False)
    for argv in plan:
        if argv[1] == "set-option":
            assert argv[:4] == ["tmux", "set-option", "-t", "cpm-proj-1"]
            assert "=cpm-proj-1" not in argv


def test_bind_return_argv_is_a_guarded_prefix_binding():
    # A prefix binding (`bind-key o`, not `-n`) so it never shadows a bare key from
    # Claude, guarded on @cpm_launched so it's a no-op outside launched sessions
    # (no false branch). The branch command differs by run mode.
    detached = tmux_bind_return_argv(attach=False)
    in_tmux = tmux_bind_return_argv(attach=True)

    assert detached[:6] == ["tmux", "bind-key", "o", "if-shell", "-F", "#{@cpm_launched}"]
    assert in_tmux[:6] == detached[:6]
    # Detached returns by detaching the foreground attach; in-tmux by switching client.
    assert detached[6] == "detach-client"
    assert in_tmux[6] == "switch-client -l"
    # No false branch — Ctrl-b o simply does nothing outside a launched session.
    assert len(detached) == 7
    assert len(in_tmux) == 7


# --- board dispatch through the tmux backend ---------------------------------

EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}
TWO_READY = {
    "docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")]),
    "docs/epics/39-02-epic-bar.md": epic_md("Pending", [(1, "Pending", "—")]),
}
RALPH_BOTH = "/cpm:ralph docs/epics/39-01-epic-foo.md docs/epics/39-02-epic-bar.md"


def _tmux_board(repo, cache_root, calls, *, in_tmux):
    return BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        runner=calls.append,
        tmux_available=True,
        in_tmux=in_tmux,
        session_suffix=lambda: "s",
        # A detached launch always attaches; stub the suspend (the headless driver
        # can't suspend). Unused when in_tmux=True (the plan switches the client).
        attach_suspend=lambda: contextlib.nullcontext(),
    )


async def test_launch_via_tmux_detached_when_board_is_not_in_tmux(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    app = _tmux_board(repo, cache_root, calls, in_tmux=False)
    async with app.run_test() as pilot:
        await pilot.press("l")  # projects column → bare /cpm:do

    session = tmux_session_name(str(repo), "s")
    # A detached new-session, the launched marker, the status reminder, the one-key
    # return binding, then attach — a detached launch always attaches (board suspends).
    assert calls == [
        ["tmux", "new-session", "-d", "-s", session, f"cd {repo} && claude /cpm:do"],
        tmux_mark_launched_argv(session),
        _status_argv(session),
        tmux_bind_return_argv(attach=False),
        tmux_attach_argv(session),
    ]


async def test_launch_via_tmux_switches_client_when_board_is_in_tmux(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    app = _tmux_board(repo, cache_root, calls, in_tmux=True)
    async with app.run_test() as pilot:
        await pilot.press("l")

    session = tmux_session_name(str(repo), "s")
    # Inside tmux: marker, status, switch-client into the session, and the return
    # binding (guarded on @cpm_launched so it can't hijack the board's own pane).
    assert calls[0][:5] == ["tmux", "new-session", "-d", "-s", session]
    assert calls[1] == tmux_mark_launched_argv(session)
    assert calls[2] == _status_argv(session)
    assert calls[3] == ["tmux", "switch-client", "-t", f"={session}"]
    assert calls[4] == tmux_bind_return_argv(attach=True)


async def test_open_plain_via_tmux_runs_a_plain_claude(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    app = _tmux_board(repo, cache_root, calls, in_tmux=False)
    async with app.run_test() as pilot:
        await pilot.press("o")

    session = tmux_session_name(str(repo), "s")
    assert calls == [
        ["tmux", "new-session", "-d", "-s", session, f"cd {repo} && claude"],
        tmux_mark_launched_argv(session),
        _status_argv(session),
        tmux_bind_return_argv(attach=False),
        tmux_attach_argv(session),
    ]


async def test_ralph_launch_via_tmux_runs_the_selection(make_project, cache_root):
    repo = make_project(TWO_READY)
    calls: list = []
    app = _tmux_board(repo, cache_root, calls, in_tmux=False)
    async with app.run_test() as pilot:
        await pilot.press("right")  # epics
        await pilot.press("space")  # select row 0
        await pilot.press("down")
        await pilot.press("space")  # select row 1
        await pilot.pause()
        await pilot.press("l")

    session = tmux_session_name(str(repo), "s")
    assert calls == [
        ["tmux", "new-session", "-d", "-s", session, f"cd {repo} && claude '{RALPH_BOTH}'"],
        tmux_mark_launched_argv(session),
        _status_argv(session),
        tmux_bind_return_argv(attach=False),
        tmux_attach_argv(session),
    ]
    # A launch consumes the ralph selection, tmux backend included.
    assert app._ralph_selection == set()


async def test_no_backend_warns_and_does_not_spawn(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    app = BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        runner=calls.append,
        tmux_available=False,  # no tmux → copy is the only path
    )
    async with app.run_test() as pilot:
        await pilot.press("l")

    assert calls == []
