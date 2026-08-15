"""Story 5 — the board without tmux, and without `claude` (ENVX1, ENVX5).

**`PATH` is the whole apparatus.** Each test builds a directory holding exactly the stubs it wants
found and points `PATH` at nothing else, so "tmux is absent" is absent in the way it is absent for a
user rather than in a way the board was told about. Nothing here injects a detector.

**The assertions are on what the keys do**, never on the board having started. "The board renders
with tmux absent" is also true of a board that never looks for tmux — and of a board that looks once
at startup and is then wrong for the rest of the session. What separates them is the clipboard and
the report after a keypress, and, in the point-of-use test, `PATH` changing while the board runs.

The two absences degrade differently and that difference is the requirement: without tmux the
command the board would have run is still exactly right, so the launch keys fall back to what `c`
does; without `claude` there is nothing runnable to fall back to, so they say so. `t` reports in both
cases, because a copied command is not an attach and there is no session to join.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from pilot import board, lines, painted, text_of, until

from board_view import ProjectView
from launcher import live_sessions, tmux_launcher


@pytest.fixture
def binaries(tmp_path, monkeypatch):
    """A ``PATH`` holding only what a test provides, rewritable while the board is running.

    Yields ``(provide, calls)``: ``provide("claude")`` makes that the only binary on ``PATH``, and
    ``calls()`` is what the stubs were invoked with. Rewritable is the point — the point-of-use
    criterion is about a board that is asked again, and a fixture that could only be set up before
    the app started could not express it.
    """
    directory = tmp_path / "bin"
    directory.mkdir()
    record = tmp_path / "invocations"

    monkeypatch.setenv("PATH", str(directory))
    # A suite run from inside tmux would otherwise take the board's "am I in tmux" branch, which is
    # about the return binding rather than about anything here.
    monkeypatch.delenv("TMUX", raising=False)

    def provide(*names: str) -> None:
        for existing in directory.iterdir():
            existing.unlink()

        for name in names:
            stub = directory / name
            stub.write_text(f'#!/bin/sh\nprintf "%s\\n" "$*" >> {record}\n')
            stub.chmod(0o755)

    def calls() -> list[str]:
        return record.read_text().splitlines() if record.exists() else []

    return provide, calls


def project(root: Path) -> ProjectView:
    return ProjectView(name=root.name, path=root)


def projects(tmp_path, *names: str) -> list[ProjectView]:
    """One real directory per name, so each row carries a path of its own to be quoted into."""
    views = []

    for name in names:
        root = tmp_path / name
        root.mkdir()
        views.append(project(root))

    return views


def reports(app) -> list[str]:
    """What the board's notifications painted, one string per toast.

    Read from the rendered toasts rather than from ``app._notifications``, for the same reason every
    other assertion in this suite reads strips: the requirement is that the absence is *reported*,
    and a notification the app recorded but never painted reports nothing to anybody. A toast wraps
    to its own width, so its lines are joined — the words being looked for are as likely to land
    either side of a line break as together.
    """
    return [" ".join(text_of(painted(toast))) for toast in app.screen.query("Toast")]


def reported(app, *words: str) -> bool:
    """Whether some report carries all of ``words`` — the project it is about, and what is wrong."""
    return any(all(word in report for word in words) for report in reports(app))


async def test_without_tmux_the_launch_keys_copy_the_command(tmp_path, binaries):
    """Criterion 1, in both of the shapes a launch key has.

    `l` and `o` build *different* commands — one carries the column's target and one is a plain
    Claude — so a fallback that copied some fixed string, or the wrong intent's line, fails here.
    `t` is the key that does *not* degrade to copy, and it is asserted alongside them: a command on
    the clipboard is not an attach, and without tmux there is no session to join.

    The board is given the real session reader as well: the pill poll shells out to tmux every two
    seconds, and a poll that raised when tmux went missing would take the whole board down without
    any launch key being pressed.
    """
    provide, _ = binaries
    provide("claude")
    (alpha,) = projects(tmp_path, "alpha")

    async with board(
        [alpha], launch=tmux_launcher(), sessions=live_sessions, notifications=True
    ) as (app, pilot):
        await pilot.press("l")
        await until(pilot, lambda: reports(app))

        launched = app.clipboard
        told = reported(app, "alpha", "tmux")
        said = reports(app)

        await pilot.press("o")
        await pilot.pause()

        opened = app.clipboard

        await pilot.press("t")
        await pilot.pause()

        attached = app.clipboard
        refused = reported(app, "alpha", "nothing is running")
        rendered = lines(app, "projects")

    assert launched == f"cd {alpha.path} && claude /dpm:do", (
        f"`l` without tmux put {launched!r} on the clipboard"
    )
    assert opened == f"cd {alpha.path} && claude", (
        f"`o` without tmux put {opened!r} on the clipboard"
    )
    assert told, f"nothing said why the key copied instead of launching: {said}"
    assert attached == opened and refused, (
        "`t` degraded to copy, but a command on the clipboard is not an attach and without tmux "
        f"there is no session to join: {attached!r}"
    )
    assert any("alpha" in line for line in rendered), (
        f"the board did not render its projects without tmux: {rendered}"
    )


async def test_without_claude_the_launch_keys_report_the_absence(tmp_path, binaries):
    """Criterion 2, and the ordering the two absences are checked in.

    Nothing is copied: the fallback exists because the command is still runnable, and without
    `claude` it is not. The second half is why the order is claude-first — with *both* binaries
    gone, a board that checked tmux first would put a command on the clipboard that cannot run
    wherever it is pasted, and would say the wrong thing about why.
    """
    provide, _ = binaries
    provide("tmux")
    (beta,) = projects(tmp_path, "beta")

    async with board([beta], launch=tmux_launcher(), notifications=True) as (app, pilot):
        await pilot.press("l")
        await until(pilot, lambda: reports(app))

        with_tmux = app.clipboard
        told_with_tmux = reported(app, "beta", "claude")

        provide()

        await pilot.press("l")
        await pilot.pause()

        with_neither = app.clipboard
        told_with_neither = reported(app, "beta", "claude")
        said = reports(app)
        rendered = lines(app, "projects")

    assert with_tmux == "", f"`l` without claude copied {with_tmux!r} rather than reporting"
    assert told_with_tmux, f"the absence of claude was not reported: {said}"
    assert with_neither == "", (
        f"with neither binary present the board copied {with_neither!r}, which cannot run"
    )
    assert told_with_neither, "with neither binary present the report was not about claude"
    assert any("beta" in line for line in rendered), (
        f"the board did not render its projects without claude: {rendered}"
    )


async def test_each_absence_is_detected_at_the_point_of_use(tmp_path, binaries):
    """Criterion 3's first half: asked on every keypress, and never remembered.

    Three phases against one running board — tmux gone, tmux installed, tmux gone again — and the
    behaviour has to follow `PATH` each time. A board that decided at startup passes the first phase
    and fails the second; one that cached the first *answer* passes the first two and fails the
    third. The middle phase is the one that needs a witness of its own, so the tmux stub records
    what it was invoked with: a launch that quietly did nothing would leave the clipboard untouched
    too.
    """
    provide, calls = binaries
    provide("claude")
    (gamma,) = projects(tmp_path, "gamma")

    async with board([gamma], launch=tmux_launcher()) as (app, pilot):
        await pilot.press("l")
        await pilot.pause()

        before = app.clipboard

        provide("claude", "tmux")

        await pilot.press("l")
        await until(pilot, lambda: calls())

        launched = calls()

        provide("claude")

        # `o` rather than `l` for the last phase: the clipboard cannot be cleared between presses,
        # so the third answer has to be a *different* string from the first to be evidence that a
        # copy happened at all rather than that the first one is still sitting there.
        await pilot.press("o")
        await pilot.pause()

        after = app.clipboard
        again = calls()

    assert before == f"cd {gamma.path} && claude /dpm:do", (
        f"the first keypress, with no tmux, put {before!r} on the clipboard"
    )
    assert any(call.startswith("new-session") for call in launched), (
        f"tmux arrived while the board was running and the launch key did not use it: {launched}"
    )
    assert after == f"cd {gamma.path} && claude", (
        f"tmux left again and the launch key did not fall back to copy: {after!r}"
    )
    assert again == launched, (
        f"the board invoked tmux after it had gone from PATH: {again[len(launched):]}"
    )


async def test_the_report_is_about_the_selected_project(tmp_path, binaries):
    """Criterion 3's second half: per project, not a startup refusal.

    The board holds two projects and starts with neither binary present — a startup check would
    have refused here, before either row was ever selected. What each key produces is the *selected*
    row's own answer, which is why the second half moves the cursor: a message and a command built
    from the first project would satisfy every other assertion in this file.
    """
    provide, _ = binaries
    provide()
    delta, epsilon = projects(tmp_path, "delta", "epsilon")

    async with board([delta, epsilon], launch=tmux_launcher(), notifications=True) as (app, pilot):
        rendered = lines(app, "projects")

        await pilot.press("l")
        await until(pilot, lambda: reports(app))

        first = reported(app, "delta", "claude")
        wrong_project = reported(app, "epsilon")
        said = reports(app)

        # And the same board, one row down, with the absence that has a fallback.
        provide("claude")

        await pilot.press("down")
        await pilot.pause()
        await pilot.press("l")
        await pilot.pause()

        copied = app.clipboard

    assert [line for line in rendered if "delta" in line or "epsilon" in line], (
        f"the board refused to render with neither binary present: {rendered}"
    )
    assert first, f"the report did not name the project it was about: {said}"
    assert not wrong_project, "the report named a project other than the selected one"
    assert copied == f"cd {epsilon.path} && claude /dpm:do", (
        f"the second row's launch key produced {copied!r}"
    )
