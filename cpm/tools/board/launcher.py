"""Shell-safe launch command generation (Story 1, epic 39-05).

Textual-free so the security-critical paths are unit-tested directly, without a
Pilot event loop — the same split that made ``board_view`` and ``registry``
testable. A :class:`~status_model.NextAction` and a project root become one of
two launch forms:

- a **clipboard string** — a shell command the user pastes into a terminal, with
  every interpolated path ``shlex.quote()``d;
- a **detached-terminal argv** — an ``osascript`` invocation that opens the
  session in a *new* terminal window, so the board never blocks on the session
  and never re-parses a path through a shell.

Neither form is ever built by unescaped string interpolation of a path.
"""

from __future__ import annotations

import shlex
import sys

from status_model import NextAction


class NoCommandError(ValueError):
    """Raised when a launch is attempted for an action with no runnable command.

    ``attention:unblock`` candidates carry ``command is None`` — there is nothing
    to copy or launch. Callers (the TUI in Story 2) check ``command is not None``
    first and treat those candidates as no-ops; this error is the loud backstop
    if that guard is ever bypassed.
    """


class UnsupportedTerminalError(RuntimeError):
    """Raised when there is no known way to open a detached terminal on this OS.

    Detached-window launching is currently macOS-only (via ``osascript`` +
    Terminal.app). On other platforms the TUI catches this and points the user at
    the copy key instead, so launch degrades to a paste rather than a crash.
    """


def clipboard_command(project_path: str, action: NextAction) -> str:
    """Build the ``cd <path> && claude "<command>"`` string for the clipboard.

    Both interpolated values — the project path and the ``/cpm:do …`` command —
    are ``shlex.quote()``d, so a path with spaces, quotes, or shell
    metacharacters neither breaks the command nor injects.
    """
    if action.command is None:
        raise NoCommandError(f"{action.kind} has no runnable command")
    return f"cd {shlex.quote(str(project_path))} && claude {shlex.quote(action.command)}"


def direct_launch(project_path: str, action: NextAction) -> tuple[list[str], str]:
    """Build the ``(argv, cwd)`` for running the session **inline** with ``subprocess``.

    Used by the board's suspend-inline launch: the board drops its screen and
    ``subprocess.run(argv, cwd=cwd)`` runs ``claude`` full-size in the same
    terminal until it exits. The command is a **single argv element** (``claude``
    takes the prompt as one positional argument), so it is handed to the OS with no
    shell — no ``shell=True``, no shell string, and the cwd path is never
    shell-parsed.
    """
    if action.command is None:
        raise NoCommandError(f"{action.kind} has no runnable command")
    return ["claude", action.command], str(project_path)


def _applescript_literal(text: str) -> str:
    """Escape ``text`` for embedding inside an AppleScript double-quoted string.

    AppleScript string literals recognise ``\\`` and ``"`` — escape those, backslash
    first so the escapes we add aren't re-escaped. This is the *second* escaping
    layer: ``text`` is already a shell-safe command (its paths are ``shlex.quote``d),
    and this wraps it safely for the AppleScript string that ``osascript`` parses.
    """
    return text.replace("\\", "\\\\").replace('"', '\\"')


def terminal_launch(
    project_path: str, action: NextAction, *, platform: str = sys.platform
) -> list[str]:
    """Build the argv that opens the session in a **new, detached** terminal window.

    Running ``claude`` in-place would block the board's TUI until the session ends
    and fight it for the terminal. Instead we hand a ``cd <path> && claude
    <command>`` line to the host terminal, which opens its own window and owns the
    session's lifetime; the board spawns this, returns immediately, and stays
    interactive.

    Shell-safety holds across both layers with no shell anywhere: the inner command
    comes from :func:`clipboard_command` (every path ``shlex.quote``d), and on macOS
    it is additionally escaped for the AppleScript string layer before ``osascript``
    receives it as discrete ``-e`` argv elements.

    :raises NoCommandError: the action has no runnable command.
    :raises UnsupportedTerminalError: no detached-terminal support for ``platform``.
    """
    command = clipboard_command(project_path, action)  # raises NoCommandError if none
    if platform == "darwin":
        literal = _applescript_literal(command)
        return [
            "osascript",
            "-e",
            f'tell application "Terminal" to do script "{literal}"',
            "-e",
            'tell application "Terminal" to activate',
        ]
    raise UnsupportedTerminalError(
        f"Opening a detached terminal isn't supported on {platform!r} yet — "
        "press c to copy the command and paste it into a terminal instead."
    )
