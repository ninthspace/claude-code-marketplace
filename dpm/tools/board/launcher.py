"""What a keypress launches: the target that follows the focused column (FR8).

Textual-free, like :mod:`board_view` and :mod:`status_model`, so the thing a launch actually runs is
unit-testable without standing up an app. That split is what `cpm/tools/board/launcher.py` uses for
the same reason, and AD7 says to reuse the shape.

**A target is an argv list, never a command line.** Nothing here joins a path or an id into a
string, and no layer of the board's own code passes anything to a shell (NFR4). The one string that
exists is the ``cd … && claude …`` command tmux runs itself, and it is built in one place with each
value quoted into it.

**The candidate's kind decides the command, not the column.** :data:`status_model.CANDIDATE_KINDS`
already answers *which row* could be worked on next and in what order (FR9); the commands those
kinds map to are FR8's, and this module is the other half of that handoff. A rule that read the
column instead would have to know that the Stories column's target belongs to the epic above it,
which is a fact about the row rather than about the column.
"""

from __future__ import annotations

import os
import re
import shlex
import subprocess
from dataclasses import dataclass
from pathlib import Path
from shutil import which
from uuid import uuid4

from status_model import CANDIDATE_KINDS, Candidate

#: The column whose target is the project rather than any row in it.
PROJECTS = "projects"

#: The command that works one epic, and the command that works several (FR8, FR14).
#:
#: Named rather than written out at each use, because three things now depend on `/dpm:do` being the
#: same string in all of them: the Projects column's bare target, the ``epic_ready`` mapping below,
#: and :func:`selectable`, which decides what a ralph selection may hold by asking which kinds launch
#: it. That last one is why the constant matters — the eligibility rule is derived from this table
#: rather than stated a second time, and a literal in one of the three would break the derivation
#: silently.
DO = "/dpm:do"
RALPH = "/dpm:ralph"

#: FR8's target for the Projects column: ``/dpm:do`` with no argument, so the session opens on the
#: project and picks its own work. A project row names a directory, not a document, and there is
#: nothing for the command to take an argument from.
PROJECT_TARGET = (DO,)

#: The command each candidate kind launches (FR8).
#:
#: **Keyed on :data:`status_model.CANDIDATE_KINDS`, not written alongside it.** A kind added to the
#: model with no command here is refused by :func:`launch_target` rather than falling back to the
#: project's bare command — which would launch a session that looks right, does something else, and
#: says nothing about the row the user was pointing at.
CANDIDATE_COMMANDS: dict[str, str] = {
    "epic_ready": DO,
    "spec_without_epics": "/dpm:epics",
    "retro_missing": "/dpm:retro",
}


#: What a launch key asks for (FR8). Named here rather than in the app, because the thing that acts
#: on them is the tmux layer and the app is only the place the key was pressed.
#:
#: ``LAUNCH`` runs the focused column's target; ``OPEN`` starts a plain Claude at the project with no
#: command; ``ATTACH`` joins this terminal to a session that is already running. Only ``LAUNCH``
#: takes a target — the other two are about the project, which is why the target is optional
#: wherever these three travel together.
LAUNCH = "launch"
OPEN = "open"
ATTACH = "attach"


class NoTarget(ValueError):
    """Raised when the focused column's highlighted row has no documented launch target.

    An epic nothing can be done to next — finished and reflected on, or blocked — is not a
    candidate, and FR8 documents a target for candidates. Raised rather than answered with the
    project's bare ``/dpm:do``, because that is a *different* launch: the user pointed at a row and
    would get a session about the whole project, with nothing on screen saying so.
    """


def missing_commands() -> list[str]:
    """Candidate kinds the model has and this module has no command for.

    Returns complaints rather than asserting, so a test can drive the real comparison instead of
    restating the pairing in a second place.
    """
    return [kind for kind in CANDIDATE_KINDS if kind not in CANDIDATE_COMMANDS]


def selectable(candidate: Candidate | None = None) -> bool:
    """Whether a row may go into a ralph selection (FR14).

    **Derived from :data:`CANDIDATE_COMMANDS`, not from a list of the kinds to exclude.**
    ``/dpm:ralph <epics…>`` is the multi-epic form of ``/dpm:do <epic>``, so what it may hold is
    exactly what launches ``/dpm:do`` singly — and each of FR14's three exclusions then falls out of
    the table rather than being remembered here. A blocked epic has no candidate at all; a
    ``spec_without_epics`` launches ``/dpm:epics`` because there are no epics to run; a
    ``retro_missing`` launches ``/dpm:retro`` because the work is already done. A kind added to the
    model is out of a selection until something says which command it launches, which is the same
    refusal :func:`launch_target` makes for the same reason.
    """
    return candidate is not None and CANDIDATE_COMMANDS.get(candidate.kind) == DO


def ralph_target(selected: list[str]) -> list[str]:
    """One ``/dpm:ralph`` over several epics, as an argv list (FR14, NFR4).

    An argv list like every other target here, so the ids reach tmux through the one quoting rule
    the module already has. Nothing joins them into a command line on the way.
    """
    return [RALPH, *selected]


def launch_target(
    column: str, candidate: Candidate | None = None, selected: list[str] | None = None
) -> list[str]:
    """FR8's launch target for the focused column, as an argv list — or FR14's, for a selection.

    Four shapes and they are not symmetric: the Projects column has no candidate and produces the
    bare command; the Epics and Stories columns produce the highlighted candidate's own, with the
    candidate's ``id`` as the argument. ``retro_missing`` carries the *epic's* id, which is what
    ``/dpm:retro`` takes — that is why the argument comes off the candidate rather than off the row
    a column happens to hold.

    **A non-empty selection answers before any of that, and for every column** (FR14). The selection
    is what the user built deliberately, one keypress per epic; the highlighted row is wherever the
    cursor happens to be resting. A board that let the cursor win would launch a single epic from a
    row the user had moved past, discarding a selection still marked on screen.

    :raises NoTarget: the column has a candidate and there is none, or its kind has no command.
    """
    if selected:
        return ralph_target(selected)

    if column == PROJECTS:
        return list(PROJECT_TARGET)

    if candidate is None:
        raise NoTarget(f"nothing to launch: no candidate is highlighted in the {column} column")

    command = CANDIDATE_COMMANDS.get(candidate.kind)

    if command is None:
        raise NoTarget(f"no launch command for candidate kind {candidate.kind!r}")

    return [command, candidate.id]


def target_line(target: list[str]) -> str:
    """A target as the single argument Claude is given: ``/dpm:do 48-05``.

    Unquoted, because it is quoted exactly once — by :func:`launch_command`, as it goes into the
    command string, and as a whole. Quoting here as well would put the quotes *inside* the argument
    and Claude would be handed them as text.
    """
    return " ".join(target)


# --- tmux (AD7, NFR4) --------------------------------------------------------
#
# The design is CPM's launcher's, which AD7 says to reuse in shape: one detached session per launch,
# every tmux invocation an argv list, and exact-match `=name` targeting. What is dpm's own is the
# session-name prefix and the guard option — two boards on one tmux server must not claim each
# other's sessions, and both halves of that are the *names* below.

#: Session names may hold only ``[A-Za-z0-9_-]``: tmux reads ``.`` and ``:`` as address separators.
_UNSAFE = re.compile(r"[^A-Za-z0-9_-]+")

#: The prefix every session this board launches carries. **Distinct from CPM's `cpm-`**, which is
#: what lets the two boards share a tmux server: attach, the live pills and the return binding all
#: scope themselves by this, and a shared prefix would make each board wrong about the other's work.
SESSION_PREFIX = "dpm"

#: Set on every session this board launches, and the guard the return binding tests. Distinct from
#: CPM's `@cpm_launched` for the same reason the prefix is, and load-bearing twice over: a session
#: the board did not launch is untouched by the binding (AD7) and produces no live pill (FR12).
LAUNCHED_OPTION = "@dpm_launched"

#: The return binding: ``Ctrl-b`` then ``o``, and how it reads in a status line.
#:
#: A **prefix** binding rather than a bare key, because a bare key would be swallowed by whatever is
#: running in the pane — the launched Claude keeps every one of its own keystrokes, and the price is
#: the extra prefix press.
RETURN_KEY = "o"
RETURN_KEY_LABEL = "C-b o"

#: The format tmux evaluates to decide whether the return binding does anything. One string, used by
#: the binding and by the tests that check a session the board did not launch is untouched.
GUARD = f"#{{{LAUNCHED_OPTION}}}"


class LaunchFailed(RuntimeError):
    """A tmux invocation the board made did not succeed, with what tmux said about it."""


class Degraded(Exception):
    """tmux is not here, and this is the command the user can run instead (ENVX1).

    Not a failure: the command the board would have run is still exactly right, so the launch keys
    fall back to what `c` does rather than reporting that nothing can be done. Carries the project
    it is about, because the answer is per project and the board has other rows.
    """

    def __init__(self, command: str, project: str) -> None:
        super().__init__(f"{project}: tmux is not installed — the command is on the clipboard")
        self.command = command
        self.project = project


def available(binary: str) -> bool:
    """Whether ``binary`` is on ``PATH`` **right now** (ENVX1, ENVX5).

    Asked at the point of use rather than at startup, and not remembered. A board that decided this
    once would be wrong for the whole session for the user who installs tmux while it is open, and
    a board that refused to *start* without it would break the requirement outright: the board is
    for looking at projects, and launching is one thing it can do with them.
    """
    return which(binary) is not None


def session_name(project_path, suffix: str) -> str:
    """``dpm-<project>-<id>`` — the launched session's name (AD7).

    The project's directory name is sanitised to tmux's character set and ``suffix`` is the
    per-launch id, so two launches of one project do not collide on a shared server. An empty
    result on either side would produce ``dpm--`` and a name that is not about anything, so each
    falls back to a word.
    """
    project = _UNSAFE.sub("-", Path(project_path).name).strip("-") or "project"
    token = _UNSAFE.sub("-", suffix).strip("-") or "0"

    return f"{SESSION_PREFIX}-{project}-{token}"


def new_suffix() -> str:
    """A short per-launch id. Random rather than counted: the board does not own the tmux server,
    and a counter would collide with the sessions another board already put there."""
    return uuid4().hex[:6]


def launch_command(project_path, target: list[str] | None = None) -> str:
    """The one string tmux runs: ``cd <path> && claude [<command>]`` (NFR4).

    **This is the only place a value is interpolated into text in the whole launch path**, which is
    what makes the quoting reviewable: both interpolated values go through ``shlex.quote``, and
    everything else the board hands tmux is an argv element that no shell ever sees.

    ``target is None`` is the plain-Claude open (`o`): no command, so the session lands in the
    project with Claude waiting rather than working.
    """
    change = f"cd {shlex.quote(str(project_path))}"
    run = "claude" if target is None else f"claude {shlex.quote(target_line(target))}"

    return f"{change} && {run}"


def return_binding(*, inside: bool) -> list[str]:
    """Argv binding :data:`RETURN_KEY` in the prefix table, guarded by :data:`GUARD` (AD7).

    tmux bindings are server-wide, so the guard is what makes this a no-op everywhere except a
    session the board launched — including CPM's sessions and the user's own. ``if-shell -F`` on the
    session option has no false branch: outside a launched session the key does nothing at all.

    What "return" means depends on how the board is running. Inside tmux the board is a session, so
    the client flips back to it; outside, the board is a suspended process behind a foreground
    ``tmux attach``, and detaching is what resumes it.
    """
    return [
        "tmux",
        "bind-key",
        RETURN_KEY,
        "if-shell",
        "-F",
        GUARD,
        "switch-client -l" if inside else "detach-client",
    ]


def tmux_plan(session: str, command: str, project_path, *, inside: bool = False) -> list[list[str]]:
    """Every tmux invocation one launch makes, in order, each an argv list (NFR4).

    1. ``new-session -d`` starts the session detached, ``-c`` in the project directory, running
       ``command``. The directory is an argv element *and* the command's own ``cd``: tmux reads
       ``-c`` for ``#{session_path}``, and the ``cd`` is what the copied command line needs to be
       runnable on its own.
    2. ``set-option`` marks it as this board's (:data:`LAUNCHED_OPTION`).
    3. The return binding, guarded on that mark.
    4. A status-line hint, so an attached user is not stranded wondering how to get back.

    Returned rather than run, so that what is asserted about a launch is the invocations themselves
    — a plan is comparable, and a side effect has to be gone looking for.
    """
    return [
        ["tmux", "new-session", "-d", "-s", session, "-c", str(project_path), command],
        ["tmux", "set-option", "-t", session, LAUNCHED_OPTION, "1"],
        return_binding(inside=inside),
        ["tmux", "set-option", "-t", session, "status-right", f" {RETURN_KEY_LABEL} → dpm board "],
    ]


def attach_argv(session: str, *, inside: bool = False) -> list[str]:
    """Argv that puts this terminal into ``session`` (FR8's `t`), exact-match targeted.

    ``=name`` so a prefix cannot resolve to a different session. Inside tmux an attach is refused
    by tmux itself — a client cannot nest — so the client switches instead.
    """
    if inside:
        return ["tmux", "switch-client", "-t", f"={session}"]

    return ["tmux", "attach", "-t", f"={session}"]


@dataclass(frozen=True)
class Session:
    """One live session this board launched: where it is, when it was last used, which window.

    ``activity`` is tmux's own clock rather than anything the board remembers, so a session the
    user has been working in ranks above one the board started more recently. ``window`` is the
    native ``#{window_id}``, a handle that survives a rename and tells a *replaced* session from
    the one that was there before (FR12).
    """

    name: str
    path: str
    activity: int
    window: str


#: What one line of the live-session read carries. Tab-separated because a project path holds
#: spaces far more often than it holds tabs.
LIVE_FORMAT = "\t".join(
    ("#{session_name}", "#{session_path}", "#{window_activity}", GUARD, "#{window_id}")
)


def live_argv() -> list[str]:
    """The argv that lists every window on the server, with what the board needs to know about it.

    ``list-windows -a`` rather than ``list-sessions``: ``#{session_activity}`` does not move when a
    detached session produces output, and a detached session producing output is exactly what a
    working Claude is. The window's activity does move, and a session's activity is its windows'.
    """
    return ["tmux", "list-windows", "-a", "-F", LIVE_FORMAT]


def parse_sessions(output: str) -> list[Session]:
    """The board's own live sessions, one per session, from :func:`live_argv`'s output.

    **Rows without the guard option are dropped here**, which is the one place that decision is
    made: a session the board did not launch is not the board's to attach to, count or return from
    — including CPM's, which is on the same server under its own option.

    A session's activity is the latest of its windows', and the window id kept is that row's; a
    launched session has one window, so the two are the same thing.
    """
    latest: dict[str, Session] = {}

    for line in output.splitlines():
        fields = line.split("\t")

        if len(fields) != 5 or not fields[3].strip():
            continue

        name, path, activity, _, window = fields
        session = Session(name, path, int(activity or 0), window)
        held = latest.get(name)

        if held is None or session.activity >= held.activity:
            latest[name] = session

    return list(latest.values())


def live_sessions(project_path=None) -> list[Session]:
    """Every live session the board launched, most recently used first.

    ``project_path`` narrows it to one project by the directory the session was started in, rather
    than by the project name inside the session's own name: two registered projects can have the
    same directory basename, and the name would put one project's sessions on the other's row.

    **No tmux server is not an error**: ``list-windows`` exits non-zero when there is nothing
    running, and so does a missing tmux, and in both cases the true answer is that there are no
    live sessions.
    """
    try:
        answer = subprocess.run(live_argv(), capture_output=True, text=True)
    except OSError:
        return []

    if answer.returncode != 0:
        return []

    found = parse_sessions(answer.stdout)

    if project_path is not None:
        found = [session for session in found if session.path == str(project_path)]

    # Name as the tie-break, so two sessions used within one second of each other still order the
    # same way twice — tmux's activity clock counts in seconds and a board that answered
    # differently on consecutive presses of `t` would look like it was choosing at random.
    return sorted(found, key=lambda session: (-session.activity, session.name))


def attach_target(project_path) -> str | None:
    """The session `t` joins: the most recently used one for this project, or ``None``."""
    found = live_sessions(project_path)

    return found[0].name if found else None


def attach_session(session: str) -> None:
    """Hand this terminal to ``session`` (FR8).

    **Output is deliberately not captured.** The whole point of the call is that tmux draws on this
    terminal and reads its keys; capturing would give the user a blank terminal until they found
    the detach key. The caller has already suspended the board's own drawing.
    """
    answer = subprocess.run(attach_argv(session, inside=inside_tmux()))

    if answer.returncode != 0:
        raise LaunchFailed(f"could not attach to {session}")


def inside_tmux() -> bool:
    """Whether the board is itself running in tmux, which decides what "return" and "attach" mean.

    Read from ``TMUX``, which tmux sets in every pane's environment and nothing else does. Read at
    the moment it is needed rather than at startup: a board opened outside tmux and then attached
    to one is a thing that happens, and a cached answer would be wrong for the rest of the session.
    """
    return bool(os.environ.get("TMUX"))


def run_plan(plan: list[list[str]]) -> None:
    """Run each argv in turn, stopping at the first that fails.

    The environment is inherited whole and deliberately: ``TMUX_TMPDIR`` decides which tmux server
    a launch lands on, and a board that overrode it would put its sessions somewhere the user's own
    ``tmux`` cannot see. That is also what lets the suite run every launch here against a server of
    its own without the board knowing.
    """
    for argv in plan:
        answer = subprocess.run(argv, capture_output=True, text=True)

        if answer.returncode != 0:
            raise LaunchFailed(f"{' '.join(argv)}: {(answer.stderr or '').strip()}")


def tmux_launcher(*, suffix=new_suffix):
    """What the board's launch keys are wired to: one intent, one tmux session (FR8, AD7).

    A closure for the same reason :func:`board.previews` is one: the app owns no tmux server, so
    what it holds is something to call. ``suffix`` is a parameter because the id in
    ``dpm-<project>-<id>`` is the launch's own — a caller that wants launches to be nameable in
    advance says so, and the default is a value nothing has to coordinate on.
    """
    def launch(intent: str, project, target: list[str] | None) -> str | None:
        command = launch_command(project.path, None if intent == OPEN else target)

        # **Claude first, then tmux.** With both absent, the tmux fallback would put a command on
        # the clipboard that cannot run either — the useful thing to say is the one about the
        # binary that has no fallback (ENVX5), and it stays true when tmux arrives.
        if not available("claude"):
            raise LaunchFailed(f"{project.name}: claude is not on PATH, so there is nothing to run")

        if not available("tmux"):
            if intent == ATTACH:
                raise LaunchFailed(f"{project.name}: tmux is not installed, so nothing is running")

            raise Degraded(command, project.name)

        if intent == ATTACH:
            session = attach_target(project.path)

            if session is None:
                raise LaunchFailed(f"no live session for {project.name}")

            attach_session(session)

            return session

        if intent != LAUNCH and intent != OPEN:
            return None

        session = session_name(project.path, suffix())

        run_plan(tmux_plan(session, command, project.path, inside=inside_tmux()))

        return session

    return launch
