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
    UnsupportedTerminalError,
    clipboard_command,
    ralph_command,
    terminal_launch,
)
from status_model import NextAction


def _unescape_applescript(text: str) -> str:
    """Reverse ``_applescript_literal`` — drop the backslash before any escaped char.

    One left-to-right pass undoes both ``\\\\`` → ``\\`` and ``\\"`` → ``"`` correctly,
    so the recovered string is the exact shell command that was embedded.
    """
    out: list[str] = []
    i = 0
    while i < len(text):
        if text[i] == "\\" and i + 1 < len(text):
            out.append(text[i + 1])
            i += 2
        else:
            out.append(text[i])
            i += 1
    return "".join(out)

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


# --- detached terminal launch (macOS): osascript argv, never a shell string ---


def test_terminal_launch_wraps_the_command_for_a_new_macos_window():
    action = do_action("/cpm:do docs/epics/39-01-epic-foo.md")
    argv = terminal_launch("/home/me/proj", action, platform="darwin")

    # An osascript invocation whose script tells Terminal to run the exact
    # shell-safe command in a fresh window, then bring it to the front.
    assert argv == [
        "osascript",
        "-e",
        'tell application "Terminal" to do script '
        "\"cd /home/me/proj && claude '/cpm:do docs/epics/39-01-epic-foo.md'\"",
        "-e",
        'tell application "Terminal" to activate',
    ]


def test_terminal_launch_is_safe_across_both_escaping_layers():
    # A path laden with a double-quote and backslash exercises the AppleScript
    # layer on top of the shell layer.
    path = '/tmp/a b"c\\d; rm -rf ~ #'
    action = do_action()
    argv = terminal_launch(path, action, platform="darwin")

    prefix = 'tell application "Terminal" to do script "'
    do_script = argv[2]
    assert do_script.startswith(prefix) and do_script.endswith('"')

    # Peel the AppleScript string layer → the inner shell command must be exactly
    # the shlex-quoted clipboard command, and that command must still tokenise to
    # the exact args (no metacharacter leaked out as a word or operator).
    inner = _unescape_applescript(do_script[len(prefix):-1])
    assert inner == clipboard_command(path, action)
    assert shlex.split(inner) == ["cd", path, "&&", "claude", action.command]


def test_terminal_launch_never_builds_a_bare_shell_string():
    argv = terminal_launch(NASTY_PATH, do_action(), platform="darwin")
    # osascript receives the AppleScript as discrete -e argv elements; the process
    # is spawned with no shell, so nothing re-parses the path.
    assert argv[0] == "osascript"
    assert argv.count("-e") == 2


def test_terminal_launch_unsupported_platform_raises():
    with pytest.raises(UnsupportedTerminalError):
        terminal_launch(NASTY_PATH, do_action(), platform="linux")


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


def test_terminal_launch_rejects_action_without_command():
    with pytest.raises(NoCommandError):
        terminal_launch(NASTY_PATH, unblock_action(), platform="darwin")
