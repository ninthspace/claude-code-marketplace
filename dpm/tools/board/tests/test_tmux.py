"""Story 2 — the launch creates a real tmux session (FR8, NFR4, ENV6, AD7).

**Real tmux, on a server of the suite's own.** ``TMUX_TMPDIR`` points tmux at a socket directory the
test made, so nothing here can see, name or kill a session belonging to the user — and the teardown
that kills that server is what ENV6's "create and tear down" is about.

**A stand-in ``claude`` on ``PATH``**, for the same reason 48-02 used a stand-in server: the launch
has to run *something*, the something has to still be there when the assertions run, and what it
recorded is the outside witness for what the command actually did. Its argv file is how "the path
and command are quoted correctly" is asserted from the far side of the shell tmux runs, rather than
from the string the board built.
"""

from __future__ import annotations

import ast
import os
import subprocess
from pathlib import Path
from shutil import rmtree
from tempfile import mkdtemp
from time import monotonic, sleep

import pytest
from conftest import BOARD_DIR

from board_view import ProjectView
from launcher import (
    GUARD,
    LAUNCH,
    LAUNCHED_OPTION,
    OPEN,
    RETURN_KEY,
    SESSION_PREFIX,
    attach_argv,
    launch_command,
    return_binding,
    session_name,
    tmux_launcher,
    tmux_plan,
)

#: The suffix every launch in this module gets, so the session's name is knowable in advance.
SUFFIX = "test01"

#: What the stand-in `claude` writes down: one line per argument it was given, then its directory.
ARGUMENTS = "claude-arguments"
DIRECTORY = "claude-directory"


@pytest.fixture
def tmux(monkeypatch):
    """A tmux server of this test's own, and a way to talk to it. Killed on the way out.

    **The board is not told about it.** ``TMUX_TMPDIR`` goes into the environment every process
    here inherits, so the launcher runs exactly the ``tmux`` argv it runs in production and lands
    on a socket no user session shares — an injection point on the board for the suite's benefit
    would be production code with no production caller.

    Under `/tmp` rather than under pytest's own directory: a unix socket path has a hard length
    limit that pytest's nested temporary directories exceed, and the failure is an obscure one two
    layers down in tmux. ``TMUX`` is removed for the same reason: a suite run from inside tmux
    would otherwise take the board's "am I in tmux" branch.
    """
    directory = Path(mkdtemp(prefix="dpm-tmux-", dir="/tmp"))
    monkeypatch.setenv("TMUX_TMPDIR", str(directory))
    monkeypatch.delenv("TMUX", raising=False)

    def call(*arguments: str) -> subprocess.CompletedProcess:
        return subprocess.run(["tmux", *arguments], capture_output=True, text=True)

    yield call

    call("kill-server")
    rmtree(directory, ignore_errors=True)


def claude_stub(monkeypatch, directory: Path, *, linger: bool = True) -> None:
    """A stand-in ``claude`` on ``PATH`` that records its arguments and its directory.

    ``linger`` keeps the process alive so the session it was launched in is still there to be
    asserted about; the unit tests that only want the recording use a stub that exits.
    """
    binaries = directory / "bin"
    binaries.mkdir(parents=True, exist_ok=True)
    stub = binaries / "claude"
    # The record paths arrive as environment variables rather than being written into the script:
    # this stub is installed under project directories whose names contain quotes and semicolons,
    # and a path interpolated into the script's own quoting is the bug the test is about, planted
    # in the test's apparatus where it would look like a failure of the code under test.
    stub.write_text(
        "#!/bin/sh\n"
        'for word in "$@"; do printf "%s\\n" "$word" >> "$CLAUDE_ARGUMENTS"; done\n'
        'pwd >> "$CLAUDE_DIRECTORY"\n' + ("sleep 30\n" if linger else "")
    )
    stub.chmod(0o755)

    monkeypatch.setenv("PATH", f"{binaries}:{os.environ['PATH']}")
    monkeypatch.setenv("CLAUDE_ARGUMENTS", str(directory / ARGUMENTS))
    monkeypatch.setenv("CLAUDE_DIRECTORY", str(directory / DIRECTORY))


def recorded(directory: Path, name: str) -> list[str]:
    """What the stand-in wrote to one of its files, a line at a time."""
    path = directory / name

    return path.read_text().splitlines() if path.exists() else []


def settled(directory: Path, *, timeout: float = 5.0) -> list[str]:
    """The stand-in's directory record, once it has written one.

    A launch returns as soon as tmux has the session; the shell inside it still has to start, run
    ``cd`` and exec the stand-in. Waiting for the *file* rather than for a duration is what keeps
    this from being either flaky or slow.
    """
    deadline = monotonic() + timeout

    while monotonic() < deadline and not recorded(directory, DIRECTORY):
        sleep(0.05)

    return recorded(directory, DIRECTORY)


def project(root: Path) -> ProjectView:
    return ProjectView(name=root.name, path=root)


def launched(monkeypatch, root: Path, *, intent: str = LAUNCH, target=None) -> str:
    """Run one real launch through the board's own launcher, and return the session's name.

    Nothing about the launcher is substituted except the per-launch id, which is what makes the
    session's name knowable before it exists. Everything else — the tmux server, the ``claude`` it
    finds, the directory it lands in — is arranged in the environment the launch inherits.
    """
    claude_stub(monkeypatch, root, linger=True)

    return tmux_launcher(suffix=lambda: SUFFIX)(intent, project(root), target)


def sessions(tmux) -> dict[str, str]:
    """Every session on this test's server: name to the directory it was started in.

    Read with ``list-sessions -F`` rather than ``display-message``, whose ``-t`` is a *pane* target
    and does not take the ``=name`` session form.
    """
    answer = tmux("list-sessions", "-F", "#{session_name} #{session_path}")

    return dict(line.split(" ", 1) for line in answer.stdout.splitlines() if " " in line)


def option(tmux, session: str, name: str) -> str:
    """One session option's value, or empty when the session does not carry it.

    ``-t`` on the option commands takes a bare name: the ``=`` exact-match prefix that ``attach``
    and ``has-session`` want is rejected here with "not found", which reads as a missing session
    rather than as the wrong target syntax.
    """
    return tmux("show-options", "-v", "-t", session, name).stdout.strip()


async def test_a_launch_creates_the_named_session_in_the_project_directory(
    tmp_path, tmux, monkeypatch
):
    """Criterion 1, from tmux rather than from the plan the board built.

    The name, the directory and the command are three separate ways this can be wrong, and each is
    read back from the server or from what the launched process itself recorded — not from the argv
    the board assembled, which is the thing under test.
    """
    root = tmp_path / "alpha"
    root.mkdir()

    session = launched(monkeypatch, root, target=["/dpm:do", "48-05"])
    running = sessions(tmux)

    assert session == f"{SESSION_PREFIX}-alpha-{SUFFIX}", f"the session is named {session}"
    assert list(running) == [session], f"the server holds {running}"
    assert running[session] == str(root), (
        f"the session started in {running[session]} rather than {root}"
    )
    assert settled(root) == [str(root)], (
        f"claude ran in {recorded(root, DIRECTORY)} rather than in the project"
    )
    assert recorded(root, ARGUMENTS) == ["/dpm:do 48-05"], (
        f"claude was given {recorded(root, ARGUMENTS)} rather than one command argument"
    )


async def test_the_open_intent_launches_a_plain_claude(tmp_path, tmux, monkeypatch):
    """`o`'s session, which is the same launch with no command at all.

    Asserted from the stand-in's argument file: a launch that passed an empty string, or the target
    it happened to have, would still start a session and still look right from the outside.
    """
    root = tmp_path / "beta"
    root.mkdir()

    launched(monkeypatch, root, intent=OPEN, target=["/dpm:do", "48-05"])

    assert settled(root) == [str(root)], "the plain Claude never started, so nothing was recorded"
    assert recorded(root, ARGUMENTS) == [], (
        f"a plain Claude was given arguments: {recorded(root, ARGUMENTS)}"
    )


async def test_a_real_session_is_created_and_torn_down(tmp_path, tmux, monkeypatch):
    """ENV6: the launch path stands a real session up, and it can be taken down again.

    The attach argv is checked against the same server in the same test — ``=name`` exact matching
    is the half of attach that can be wrong without a client, and a target that resolves to nothing
    is an attach that would fail with the terminal already handed over.
    """
    root = tmp_path / "gamma"
    root.mkdir()

    session = launched(monkeypatch, root)

    assert session in sessions(tmux)

    target = attach_argv(session)[-1]

    assert tmux("has-session", "-t", target).returncode == 0, (
        f"the attach target {target} resolves to no session on the server"
    )

    tmux("kill-session", "-t", target)

    assert sessions(tmux) == {}, f"the session outlived its teardown: {sessions(tmux)}"


async def test_the_return_binding_is_guarded_by_the_launched_option(tmp_path, tmux, monkeypatch):
    """Criterion 3, with the session the board did *not* launch as the control.

    The guard is run as tmux itself runs it — the same format string, against both sessions — and
    each is asked afterwards whether the guarded command fired. Reading the binding's text alone
    would assert that a guard is *written*, which is true of a guard that never excludes anything.
    """
    root = tmp_path / "delta"
    root.mkdir()

    session = launched(monkeypatch, root)
    tmux("new-session", "-d", "-s", "stranger", "-c", str(root), "sleep 30")

    assert option(tmux, session, LAUNCHED_OPTION) == "1", (
        f"the launched session does not carry {LAUNCHED_OPTION}"
    )
    assert option(tmux, "stranger", LAUNCHED_OPTION) == "", (
        "the control session carries the guard option, so the two are not distinguishable"
    )

    keys = tmux("list-keys", "-T", "prefix", RETURN_KEY).stdout

    assert GUARD in keys, f"the {RETURN_KEY!r} binding is not guarded by {GUARD}: {keys!r}"

    for name in (session, "stranger"):
        tmux("if-shell", "-F", "-t", name, GUARD, f"set-option -t {name} @dpm_fired 1")

    sleep(0.2)

    fired = {name: option(tmux, name, "@dpm_fired") for name in (session, "stranger")}

    assert fired[session], "the guard did not fire inside the session the board launched"
    assert not fired["stranger"], (
        f"the guard fired in a session the board did not launch: {fired['stranger']!r}"
    )


def test_the_return_binding_returns_differently_inside_and_outside_tmux():
    """AD7's two run modes, which are the same key and different commands.

    Inside tmux the board is a session and the client flips back to it; outside, the board is a
    suspended process behind a foreground attach and detaching is what resumes it. One command for
    both would leave one of the two modes with a key that does nothing.
    """
    inside = return_binding(inside=True)
    outside = return_binding(inside=False)

    assert inside[-1] != outside[-1], f"both modes bind {RETURN_KEY!r} to {inside[-1]!r}"
    assert GUARD in inside and GUARD in outside, "a run mode binds the key without the guard"


def test_the_session_prefix_and_guard_are_this_boards_own():
    """AD7's reason for naming them at all: two boards, one tmux server.

    A shared prefix or a shared option would make each board's attach, pills and return binding
    wrong about the other's sessions, and both failures look like the board misbehaving rather than
    like a name collision.
    """
    assert SESSION_PREFIX == "dpm"
    assert LAUNCHED_OPTION == "@dpm_launched"
    assert session_name("/tmp/alpha", SUFFIX).startswith(f"{SESSION_PREFIX}-")


def test_a_project_name_is_sanitised_into_the_session_name():
    """tmux reads `.` and `:` as address separators, so a name carrying one is not a name.

    The fallbacks matter as much: an empty result on either side would produce `dpm--`, a session
    named after nothing that every later launch would collide with.
    """
    assert session_name("/tmp/my.project:2", SUFFIX) == f"dpm-my-project-2-{SUFFIX}"
    assert session_name("/tmp/...", SUFFIX) == f"dpm-project-{SUFFIX}"
    assert session_name("/tmp/alpha", "...") == "dpm-alpha-0"


def test_every_tmux_invocation_in_a_plan_is_an_argv_list():
    """NFR4's shape, over the whole plan rather than over the invocation that carries the command.

    The command string is one *element*, and the assertion below is that it stayed one: a plan that
    interpolated it into the invocation would still be a list, and would still run.
    """
    plan = tmux_plan("dpm-alpha-test01", "cd /tmp/alpha && claude", "/tmp/alpha")

    for argv in plan:
        assert isinstance(argv, list) and all(isinstance(word, str) for word in argv), (
            f"a tmux invocation is not an argv list of strings: {argv!r}"
        )
        assert argv[0] == "tmux"

    new_session = plan[0]

    assert new_session[-1] == "cd /tmp/alpha && claude", (
        f"the command is not the last argv element of new-session: {new_session!r}"
    )
    assert sum(1 for word in new_session if "&&" in word) == 1, (
        f"the command string was split or repeated across the argv: {new_session!r}"
    )


def test_a_path_with_spaces_quotes_and_a_semicolon_executes_nothing_extra(tmp_path, monkeypatch):
    """Criterion 4, run through a real shell with a marker the injection would create.

    **The control is the point.** A quoted command that failed for some other reason would also
    leave no marker, so the same line built by interpolation is run first and the marker it creates
    is what proves the check can fail at all.
    """
    marker = tmp_path / "executed-something-extra"
    # The injection is *relative*, because a directory name cannot hold a `/`. It lands beside the
    # project when the command below is run from `tmp_path`, which is what the marker checks.
    root = tmp_path / f'al pha "x"; touch {marker.name}'
    root.mkdir()

    claude_stub(monkeypatch, root, linger=False)
    quoted = launch_command(root, ["/dpm:do", "48-05"])

    subprocess.run(["sh", "-c", quoted], capture_output=True, cwd=tmp_path)

    assert not marker.exists(), f"the quoted command executed the path's injection: {quoted}"
    assert recorded(root, ARGUMENTS) == ["/dpm:do 48-05"], (
        f"the quoted command did not reach claude correctly: {recorded(root, ARGUMENTS)}"
    )
    assert recorded(root, DIRECTORY) == [str(root)], (
        f"the quoted command landed in {recorded(root, DIRECTORY)} rather than in the project"
    )

    subprocess.run(
        ["sh", "-c", f"cd {root} && claude '/dpm:do 48-05'"], capture_output=True, cwd=tmp_path
    )

    assert marker.exists(), (
        "the same command built by interpolation executed nothing extra either, so the assertion "
        "above is about something other than the quoting"
    )


def shell_uses(source: str) -> list[str]:
    """Every place ``source`` hands a command to a shell, named by line.

    Returned as complaints rather than asserted, so the sweep can be driven over a planted control
    that must complain — a sweep that has never said anything is not evidence that there is nothing
    to say.
    """
    found = []

    for node in ast.walk(ast.parse(source)):
        if not isinstance(node, ast.Call):
            continue

        for keyword in node.keywords:
            if keyword.arg == "shell" and getattr(keyword.value, "value", False) is True:
                found.append(f"line {node.lineno}: shell=True")

        name = node.func.attr if isinstance(node.func, ast.Attribute) else getattr(node.func, "id", "")

        if name in ("system", "popen", "getoutput", "getstatusoutput"):
            found.append(f"line {node.lineno}: {name}()")

        if name in ("run", "Popen", "call", "check_call", "check_output") and node.args:
            argument = node.args[0]

            if isinstance(argument, (ast.Constant, ast.JoinedStr, ast.BinOp)):
                found.append(f"line {node.lineno}: {name}() given a string")

    return found


def test_no_tmux_invocation_is_built_as_a_shell_string():
    """The must-NOT, swept over the board's own modules, with a planted control.

    NFR4's words are "no shell at any layer of the board's own code", so the sweep is over every
    module rather than over the launcher: a shell reached from the survey or the CLI is the same
    failure in a place nobody was looking.
    """
    complaints = {
        module.name: shell_uses(module.read_text()) for module in sorted(BOARD_DIR.glob("*.py"))
    }

    assert complaints, "the sweep found no modules to read, so it inspected nothing"
    assert not any(complaints.values()), f"the board hands a command to a shell: {complaints}"

    planted = (
        "import subprocess\n"
        "def launch(name):\n"
        "    subprocess.run(f'tmux new-session -s {name}', shell=True)\n"
    )

    assert shell_uses(planted), "the sweep does not complain about a shell-string tmux invocation"
