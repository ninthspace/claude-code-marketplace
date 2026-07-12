"""Shell-safe launch command generation (Story 1, epic 39-05).

Textual-free so the security-critical paths are unit-tested directly, without a
Pilot event loop — the same split that made ``board_view`` and ``registry``
testable. A :class:`~status_model.NextAction` and a project root become one of
these launch forms:

- a **clipboard string** — a shell command the user pastes into a terminal, with
  every interpolated path ``shlex.quote()``d;
- a **tmux argv plan** — creates a detached tmux session running that same
  shell-safe command. tmux runs the single command string via its own shell, so
  the exact ``cd … && claude …`` clipboard string is reused verbatim as one argv
  element — no extra escaping layer, and no shell in *our* code (every ``tmux``
  invocation is an argv list).

tmux is the sole launch backend (:func:`select_launch_backend`); where it is
absent the TUI falls back to the clipboard string. No form is ever built by
unescaped string interpolation of a path.
"""

from __future__ import annotations

import os
import re
import shlex

from pathlib import Path

from status_model import NextAction


class NoCommandError(ValueError):
    """Raised when a launch is attempted for an action with no runnable command.

    ``attention:unblock`` candidates carry ``command is None`` — there is nothing
    to copy or launch. Callers (the TUI in Story 2) check ``command is not None``
    first and treat those candidates as no-ops; this error is the loud backstop
    if that guard is ever bypassed.
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


# --- tmux backend (the sole launch backend) ----------------------------------
#
# tmux is the cross-platform launch substrate. Design mirrors bmad-loop's tmux
# adapter (see reference_bmad_loop_architecture): one *detached* session per
# launch, argv lists never shell strings, exact-match ``=name`` targeting. The
# command is the same ``cd … && claude …`` string the clipboard path uses — tmux
# runs a single trailing command string via its own shell (verified: ``cd … && …``
# chains execute), so no new escaping layer is introduced and shell-safety carries
# over unchanged.

#: Session names may only contain ``[A-Za-z0-9_-]`` (no ``.`` or ``:`` — tmux
#: treats those as address separators).
_SESSION_UNSAFE = re.compile(r"[^A-Za-z0-9_-]+")


def tmux_session_name(project_path: str, suffix: str) -> str:
    """A unique, tmux-safe session name for a launch: ``cpm-<project>-<suffix>``.

    The project basename is sanitised to tmux's allowed character set; ``suffix``
    (a short per-launch token the caller supplies) keeps repeated launches of the
    same project from colliding on the shared tmux server.
    """
    base = _SESSION_UNSAFE.sub("-", Path(project_path).name).strip("-") or "project"
    clean_suffix = _SESSION_UNSAFE.sub("-", suffix).strip("-") or "0"
    return f"cpm-{base}-{clean_suffix}"


def tmux_switch_argv(session: str) -> list[str]:
    """Argv that switches the current tmux client into ``session`` (exact ``=`` match).

    Used both when a launch happens inside tmux and by the board's attach action
    when it is itself inside tmux (a nested ``attach`` is disallowed — switch instead)."""
    return ["tmux", "switch-client", "-t", f"={session}"]


def tmux_attach_argv(session: str) -> list[str]:
    """Argv that attaches the terminal to ``session`` (exact ``=`` match).

    This is a *foreground* command — it owns the terminal until the user detaches —
    so the board runs it only after suspending its own UI (attach within the TUI)."""
    return ["tmux", "attach", "-t", f"={session}"]


#: The return binding: a **prefix** key (``Ctrl-b`` then ``o``) and its human label.
#: ``o`` is bound in tmux's ``prefix`` key table, so it never shadows a bare key from
#: the program inside the pane (Claude keeps all its own Ctrl-keys) — the trade-off
#: for that safety is the extra prefix keystroke. A no-prefix key can't be used: any
#: bare key would be swallowed inside launched sessions, and ``Ctrl-Space`` (the
#: earlier attempt) is intercepted by macOS as "select previous input source".
RETURN_KEY = "o"
RETURN_KEY_LABEL = "C-b o"

#: A session option set on every board-launched session to mark it as "ours". The
#: return binding tests this marker (:func:`tmux_bind_return_argv`) so ``Ctrl-b o``
#: only acts inside launched sessions and is a no-op in the board's own pane or any
#: unrelated session on the server.
LAUNCHED_OPTION = "@cpm_launched"


def tmux_mark_launched_argv(session: str) -> list[str]:
    """Argv that marks ``session`` as board-launched via the :data:`LAUNCHED_OPTION`
    session option. Bare ``session`` target (``set-option -t`` rejects the ``=``
    exact-match prefix — see :func:`_tmux_plan`)."""
    return ["tmux", "set-option", "-t", session, LAUNCHED_OPTION, "1"]


def tmux_bind_return_argv(*, attach: bool) -> list[str]:
    """Argv binding :data:`RETURN_KEY` in tmux's **prefix** table to return to the
    board — ``Ctrl-b`` then ``o`` from inside a launched session.

    A prefix binding (``bind-key o …``, not ``-n``) is used deliberately: it never
    shadows a bare key from the program inside the pane, so Claude keeps every one of
    its own Ctrl-keys. It applies server-wide, so an ``if-shell -F`` guard on the
    :data:`LAUNCHED_OPTION` marker keeps it a **no-op outside launched sessions**
    (the board's own pane, unrelated sessions) — there is no false branch.

    The return command depends on how the board runs:

    - ``attach`` (board **inside** tmux) → ``switch-client -l`` flips the client back
      to the board's session (the launch made it the last session);
    - detached (board **outside** tmux) → ``detach-client`` drops the foreground
      ``tmux attach`` so the suspended board UI resumes.
    """
    action = "switch-client -l" if attach else "detach-client"
    return [
        "tmux", "bind-key", RETURN_KEY,
        "if-shell", "-F", f"#{{{LAUNCHED_OPTION}}}",
        action,
    ]


def _return_hint() -> str:
    """The status-line reminder pinned to a launched session: :data:`RETURN_KEY_LABEL`
    (``Ctrl-b o``) returns to the board in both run modes (see
    :func:`tmux_bind_return_argv`). Contains no ``#`` so tmux won't interpret it as a
    ``#{…}`` format expansion."""
    return f" {RETURN_KEY_LABEL} → cpm board "


def _tmux_plan(command: str, session: str, *, attach: bool) -> list[list[str]]:
    """The argv sequence for a detached tmux launch of ``command``.

    1. ``new-session -d`` creates the session detached and runs the command via
       tmux's shell (the command already ``cd``s into the project).
    2. ``set-option @cpm_launched`` marks the session as board-launched, so the
       ``Ctrl-b o`` return binding acts only here (see :func:`tmux_bind_return_argv`).
    3. ``set-option status-right`` pins a "how to get back to the board" hint to the
       session's status line, so an attached user isn't stranded (see
       :func:`_return_hint`).
    4. When ``attach`` (the board is itself inside tmux), a ``switch-client`` argv
       follows so the user is dropped into the new session; otherwise the session
       stays detached for the caller to attach to.

    ``switch-client`` targets ``=session`` (exact match, so a prefix can't hit the
    wrong session). ``set-option -t`` is the exception: it rejects the ``=`` prefix
    ("no such session"), so it targets the bare ``session`` name — safe here because
    the name is already exact and unique, and tmux resolves an exact name first.
    """
    plan = [
        ["tmux", "new-session", "-d", "-s", session, command],
        tmux_mark_launched_argv(session),
        ["tmux", "set-option", "-t", session, "status-right", _return_hint()],
    ]
    if attach:
        plan.append(tmux_switch_argv(session))
    return plan


def tmux_launch(
    project_path: str, action: NextAction, session: str, *, attach: bool
) -> list[list[str]]:
    """Build the tmux argv plan that runs the action's session detached in tmux.

    :raises NoCommandError: the action has no runnable command.
    """
    return _tmux_plan(clipboard_command(project_path, action), session, attach=attach)


def open_tmux_launch(project_path: str, session: str, *, attach: bool) -> list[list[str]]:
    """Build the tmux argv plan for a **plain** ``claude`` (no command) — the ``o``
    open-project launch, in tmux."""
    return _tmux_plan(open_clipboard_command(project_path), session, attach=attach)


def tmux_attach_hint(session: str) -> str:
    """The command a user runs to attach to a detached launch session."""
    return f"tmux attach -t ={session}"


def select_launch_backend(*, tmux_available: bool) -> str | None:
    """Choose the launch backend for this host.

    tmux is the only backend. ``"tmux"`` when it is installed, else ``None`` — the
    board then falls back to copy (``c``).
    """
    return "tmux" if tmux_available else None


def tmux_list_windows_argv() -> list[str]:
    """The argv that lists every live tmux window as ``<session_name> <window_id>``.

    Used to poll which board-launched sessions are still running (liveness for the
    projects-column "live" pill) *and* to capture each session's native
    ``#{window_id}`` handle (bmad-loop's launch chokepoint primitive) — the id is a
    stable handle that survives session rename and disambiguates a reused session
    name. ``list-windows`` exits non-zero when no server is running; the caller
    treats that, and any spawn failure, as "no live windows".
    """
    return ["tmux", "list-windows", "-a", "-F", "#{session_name} #{window_id}"]


def parse_tmux_windows(output: str) -> dict[str, str]:
    """Map ``session_name → window_id`` from :func:`tmux_list_windows_argv` output.

    Each line is ``<session_name> <window_id>``; the id is the last space-separated
    field (our session names are sanitised to ``[A-Za-z0-9_-]`` so they never
    contain spaces, but splitting on the last space is robust regardless). A session
    with several windows keeps its last-listed id — launches are one-window sessions,
    so this is unambiguous for board-tracked sessions.
    """
    result: dict[str, str] = {}
    for raw in output.splitlines():
        line = raw.strip()
        if not line:
            continue
        session, _, window_id = line.rpartition(" ")
        if session and window_id:
            result[session] = window_id
    return result
