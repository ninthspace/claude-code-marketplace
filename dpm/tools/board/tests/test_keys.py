"""Story 1 — CPM's key meanings restored (FR19).

The subject is not what the board *can* do; every capability here already existed. It is which key
reaches it, and the claim is about two boards rather than one — so the first two tests drive a
running board through the keys, and the third reads the other board's source and compares.

Driven through the pilot, because a binding table is the app agreeing with itself: `BINDINGS` can
name an action that does not exist, and Textual will simply not fire it. What settles a criterion
worded "driving a running board" is the key being pressed and the thing happening.
"""

from __future__ import annotations

from dataclasses import replace
from pathlib import Path

from key_maps import cpm_bindings, disagreements
from pilot import board, lines, until
from wiring import registry_wiring

from board import COMMANDS, BoardApp, PickerScreen
from board_view import ProjectView
from registry import list_projects

#: How long a key's effect is given to land. The board answers in one frame; this is slack for a
#: loaded machine rather than a wait for anything in particular.
SETTLE = 2.0


def surveyed(record: list) -> callable:
    """A survey that reads nothing and records every project it was asked about.

    The real one spawns a server per project. What these criteria are about is *which rows the
    board asked for*, which is the argument this receives, so a survey that answered honestly would
    add a subprocess per assertion and tell them nothing they do not already have.
    """
    async def survey(project: ProjectView, *, fresh: bool = False) -> ProjectView:
        record.append((project.path, fresh))

        return replace(project, pending=False)

    return survey


def registered(tmp_path: Path, *paths: Path) -> tuple[list[ProjectView], dict, Path]:
    """A registry already holding ``paths``: its rows, the injections, and the file itself.

    The rows are handed to the board as its opening state rather than left to be reloaded, because
    that is how the real launch does it — `reload` is what a *refresh* reaches for, and a board
    that had to call it to show anything would make the first test below pass on the mount.

    The registry file is this test's own, which matters more here than anywhere: these tests
    unregister a project by pressing a key, and the one thing worse than a failing test is one that
    passes after removing somebody's project from their board.
    """
    file = tmp_path / "registry.json"
    injections = registry_wiring(file)

    for path in paths:
        injections["register"](path)

    return injections["reload"](), injections, file


async def test_r_re_reads_every_registered_project(tmp_path, project):
    """Criterion 1's first key [feature]. `r` is CPM's refresh, and it reaches every row.

    Every row rather than the highlighted one: a refresh that read only what the cursor was on
    would leave the board's own figures disagreeing about when each was read, and the assertion
    that catches it is the *set* of paths the survey was asked for.
    """
    first, second = project("first"), project("second")
    rows, injections, file = registered(tmp_path, first, second)
    asked: list = []

    async with board(rows, **injections, survey=surveyed(asked)) as (app, pilot):
        await until(pilot, lambda: not any(row.pending for row in app.selection.projects), timeout=SETTLE)

        opening = list(asked)
        asked.clear()

        await pilot.press("r")
        await until(pilot, lambda: len(asked) == len(opening), timeout=SETTLE)

    assert {path for path, _ in opening} == {first, second}, opening
    assert {path for path, _ in asked} == {first, second}, (
        f"`r` did not re-read every registered project: {asked}"
    )
    assert file.exists(), "the test wrote to a registry other than its own"


async def test_a_opens_the_picker_and_x_unregisters_the_highlighted_project(tmp_path, project):
    """Criterion 1's other three keys [feature], and criterion 2's half about unregistering.

    `R` is asserted from the callable it reaches rather than from a cache on disk — this story
    moved the key, and whether clearing a cache clears it is story 48-06's criterion, already
    covered. What is new here is which key gets there.
    """
    first, second = project("first"), project("second")
    rows, injections, file = registered(tmp_path, first, second)
    cleared: list[bool] = []

    async with board(
        rows, **injections, survey=surveyed([]), clear_cache=lambda: cleared.append(True)
    ) as (app, pilot):
        await until(pilot, lambda: not any(row.pending for row in app.selection.projects), timeout=SETTLE)

        await pilot.press("a")
        await until(pilot, lambda: isinstance(app.screen, PickerScreen), timeout=SETTLE)
        await pilot.press("escape")
        await until(pilot, lambda: not isinstance(app.screen, PickerScreen), timeout=SETTLE)

        await pilot.press("R")
        await pilot.pause()

        highlighted = app.selection.current_project.path

        await pilot.press("x")
        await until(pilot, lambda: len(app.selection.projects) == 1, timeout=SETTLE)

        remaining = lines(app, "projects")

    assert cleared == [True], "`R` did not reach the cache's clear"
    assert [Path(row.path) for row in list_projects(registry_file=file)] == [
        path for path in (first, second) if path != highlighted
    ], "`x` took the row off the board without unregistering it"
    assert len(remaining) == 1, f"the unregistered project is still painted: {remaining}"


def test_refresh_and_unregister_are_reachable_by_key_as_well_as_by_the_palette():
    """Criterion 2 [feature]. Both were palette-only; neither may be key-only now either.

    The pair is the point. A capability that is only bindable is found by reading the footer at the
    moment it happens to be needed, and one that is only in the palette costs two keystrokes
    forever — so the criterion is satisfied by *both* routes existing, and each is read from the
    table that actually drives it.
    """
    bound = {action for _, action, *_ in BoardApp.BINDINGS}
    offered = {command.action for command in COMMANDS}

    for action in ("refresh", "unregister"):
        assert action in bound, f"{action} is still palette-only: {sorted(bound)}"
        assert action in offered, f"{action} left the palette when it gained a key"


def test_no_key_the_cpm_board_binds_does_something_else_here():
    """Criterion 3, the must-NOT [integration]. The other board's source is the other half.

    Read from `cpm/tools/board/board.py` in this checkout rather than from an installed copy, and
    compared over the keys both boards bind rather than by equality — a dpm-only capability on a
    key CPM leaves alone is exactly what the next story is for.

    The failure names the key and both meanings, because "the key maps disagree" sends whoever
    reads it back to two files to find out which one.
    """
    cpm = cpm_bindings()
    dpm = {key: action for key, action, *_ in BoardApp.BINDINGS}

    # The floor, without which "nothing disagrees" is what an unreadable file and an empty
    # intersection both say. Story 5 turns this into a check of its own with a failure to read.
    assert set(cpm) & set(dpm), f"the two boards share no key at all: {sorted(cpm)}"

    found = disagreements(cpm, dpm)

    assert found == {}, "\n".join(
        f"`{key}` is {cpm} on the cpm board and {dpm} here" for key, (cpm, dpm) in found.items()
    )
