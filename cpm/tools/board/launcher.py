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

import os
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


def _launch_string(project_path: str, command: str | None) -> str:
    """The ``cd <path> && claude [command]`` line, shell-safe.

    Both interpolated values — the project path and any ``/cpm:… `` command — are
    ``shlex.quote()``d, so a path with spaces, quotes, or shell metacharacters
    neither breaks the command nor injects. ``command is None`` means a **plain**
    ``claude`` (open the project with no operation).
    """
    cd = f"cd {shlex.quote(str(project_path))}"
    run = "claude" if command is None else f"claude {shlex.quote(command)}"
    return f"{cd} && {run}"


def clipboard_command(project_path: str, action: NextAction) -> str:
    """Build the ``cd <path> && claude "<command>"`` string for the clipboard."""
    if action.command is None:
        raise NoCommandError(f"{action.kind} has no runnable command")
    return _launch_string(project_path, action.command)


def open_clipboard_command(project_path: str) -> str:
    """Build the ``cd <path> && claude`` string that opens a **plain** session — no
    ``/cpm`` command, just Claude at the project directory."""
    return _launch_string(project_path, None)


def ralph_command(project_path: str, epic_paths: list[str]) -> str:
    """Build the ``/cpm:ralph <epics…>`` command for autonomous multi-epic execution.

    Each epic is passed as a project-relative path, sorted so ``ralph`` runs them in
    filename (numeric-prefix) order, and every path is ``shlex.quote()``d — ``ralph``
    re-parses its arguments the way a shell tokenises them, so this is the *inner*
    quoting layer (the outer shell layer is added when this command flows through
    :func:`clipboard_command`). With no epics the bare ``/cpm:ralph`` is returned, so
    ralph auto-discovers every incomplete epic itself.
    """
    if not epic_paths:
        return "/cpm:ralph"
    rels = sorted(os.path.relpath(path, project_path) for path in epic_paths)
    return "/cpm:ralph " + " ".join(shlex.quote(rel) for rel in rels)


def _applescript_literal(text: str) -> str:
    """Escape ``text`` for embedding inside an AppleScript double-quoted string.

    AppleScript string literals recognise ``\\`` and ``"`` — escape those, backslash
    first so the escapes we add aren't re-escaped. This is the *second* escaping
    layer: ``text`` is already a shell-safe command (its paths are ``shlex.quote``d),
    and this wraps it safely for the AppleScript string that ``osascript`` parses.
    """
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _osascript_launch(command: str, platform: str) -> list[str]:
    """Wrap a shell-safe ``command`` in the ``osascript`` argv that runs it in a new
    Terminal.app window. On macOS the command is escaped for the AppleScript string
    layer, then handed to ``osascript`` as discrete ``-e`` argv elements — no shell
    at any layer. Non-macOS has no detached-window support yet.

    :raises UnsupportedTerminalError: no detached-terminal support for ``platform``.
    """
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
        f"Opening a new terminal window isn't supported on {platform!r} yet — "
        "press c to copy the command and paste it into a terminal instead."
    )


def terminal_launch(
    project_path: str, action: NextAction, *, platform: str = sys.platform
) -> list[str]:
    """Build the argv that opens the session in a **new** terminal window.

    Running ``claude`` in-place would block the board's TUI until the session ends
    and fight it for the terminal. Instead we hand a ``cd <path> && claude
    <command>`` line to the host terminal, which opens its own window and owns the
    session's lifetime; the board spawns this, returns immediately, and stays
    interactive.

    Shell-safety holds with no shell anywhere: the inner command comes from
    :func:`clipboard_command` (every path ``shlex.quote``d), then the AppleScript
    layer is added by :func:`_osascript_launch`.

    :raises NoCommandError: the action has no runnable command.
    :raises UnsupportedTerminalError: no new-window support for ``platform``.
    """
    return _osascript_launch(clipboard_command(project_path, action), platform)


def open_terminal_launch(project_path: str, *, platform: str = sys.platform) -> list[str]:
    """Build the argv that opens a **plain** ``claude`` (no command) in a new window
    at the project directory — the ``o`` "open project" launch."""
    return _osascript_launch(open_clipboard_command(project_path), platform)
