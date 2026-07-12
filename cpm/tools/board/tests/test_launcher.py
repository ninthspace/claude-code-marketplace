"""Unit tests for shell-safe launch command generation (Story 1).

The launcher is Textual-free, so the security-critical criteria are asserted
directly — no Pilot event loop. The adversarial inputs carry spaces, single and
double quotes, and shell metacharacters (`;`, `&&`, `|`, `$(…)`, backtick, `#`,
`~`, `>`); a correct implementation must neither break the command nor inject.
"""

from __future__ import annotations

import shlex

import pytest

from launcher import (
    NoCommandError,
    clipboard_command,
    parse_tmux_windows,
    ralph_command,
    tmux_list_windows_argv,
)
from status_model import NextAction


# A project root and a command each laden with metacharacters that would break
# or inject if interpolated into a shell string unescaped.
NASTY_PATH = "/tmp/a b'; rm -rf ~ #"
NASTY_COMMAND = '/cpm:do docs/epics/39-01 weird\'name"; $(touch pwned) `id` >out.md'


def do_action(command=NASTY_COMMAND):
    return NextAction("do", command, "docs/epics/39-01-epic-foo.md", "Start foo")


def unblock_action():
    return NextAction("attention:unblock", None, "docs/epics/39-01-epic-foo.md", "Unblock foo")


# --- clipboard string: shlex-quoted, round-trips ------------------------------


def test_clipboard_string_round_trips_to_exact_tokens():
    action = do_action()
    result = clipboard_command(NASTY_PATH, action)

    # shlex.split re-parses the string the way a shell would tokenise it. The
    # nasty path and command must each survive as a *single* token — no
    # metacharacter leaked out as a separate word or operator.
    assert shlex.split(result) == ["cd", NASTY_PATH, "&&", "claude", action.command]


def test_clipboard_string_is_not_naive_interpolation():
    action = do_action()
    naive = f"cd {NASTY_PATH} && claude {action.command}"

    # Proves quoting actually happened — the safe form differs from the
    # unescaped string interpolation the security must-NOT forbids.
    assert clipboard_command(NASTY_PATH, action) != naive


def test_clipboard_string_shape_for_a_benign_path():
    action = do_action("/cpm:do docs/epics/39-01-epic-foo.md")
    assert (
        clipboard_command("/home/me/proj", action)
        == "cd /home/me/proj && claude '/cpm:do docs/epics/39-01-epic-foo.md'"
    )


# --- liveness poll: list-windows argv + parse (captures window-id handles) ----


def test_tmux_list_windows_argv_lists_session_and_window_id():
    # A `session_name window_id` listing across all sessions — argv, never a shell string.
    assert tmux_list_windows_argv() == [
        "tmux",
        "list-windows",
        "-a",
        "-F",
        "#{session_name} #{window_id}",
    ]


def test_parse_tmux_windows_maps_session_to_window_id():
    out = "cpm-proj-1 @0\ncpm-other-2 @3\n\n  cpm-proj-3 @5  \n"
    assert parse_tmux_windows(out) == {
        "cpm-proj-1": "@0",
        "cpm-other-2": "@3",
        "cpm-proj-3": "@5",
    }


def test_parse_tmux_windows_empty_output_is_empty_map():
    # No server / no windows → empty stdout → no live sessions.
    assert parse_tmux_windows("") == {}


# --- ralph command: multi-epic /cpm:ralph, relative + shlex-quoted ------------


def test_ralph_command_lists_epics_relative_and_sorted():
    root = "/home/me/proj"
    epics = [
        "/home/me/proj/docs/epics/24-01-epic-bar.md",
        "/home/me/proj/docs/epics/23-01-epic-foo.md",
    ]
    # Relative to the root, sorted so ralph runs them in numeric-prefix order.
    assert ralph_command(root, epics) == (
        "/cpm:ralph docs/epics/23-01-epic-foo.md docs/epics/24-01-epic-bar.md"
    )


def test_ralph_command_with_no_epics_is_the_bare_command():
    # Bare /cpm:ralph lets ralph auto-discover every incomplete epic itself.
    assert ralph_command("/home/me/proj", []) == "/cpm:ralph"


def test_ralph_command_quotes_each_epic_path_for_the_claude_arg_layer():
    # A project laden with metacharacters and an epic filename with a space: each
    # relative path must survive as a single token when ralph re-parses $ARGUMENTS.
    root = NASTY_PATH
    epics = [f"{NASTY_PATH}/docs/epics/23-01 weird name.md"]
    command = ralph_command(root, epics)

    assert command.startswith("/cpm:ralph ")
    args = shlex.split(command)
    assert args[0] == "/cpm:ralph"
    assert args[1:] == ["docs/epics/23-01 weird name.md"]


def test_ralph_command_flows_safely_through_the_clipboard_layer():
    # The ralph command is the inner (claude-arg) layer; wrapping it for the shell
    # via clipboard_command must still tokenise cleanly — no leaked metacharacter.
    root = NASTY_PATH
    epics = [f"{NASTY_PATH}/docs/epics/23-01 weird name.md"]
    action = NextAction("ralph", ralph_command(root, epics), None, "Ralph over 1 epic(s)")

    result = clipboard_command(root, action)
    assert shlex.split(result) == ["cd", root, "&&", "claude", action.command]


# --- no-command guard (attention:unblock has no runnable command) -------------


def test_clipboard_command_rejects_action_without_command():
    with pytest.raises(NoCommandError):
        clipboard_command(NASTY_PATH, unblock_action())
