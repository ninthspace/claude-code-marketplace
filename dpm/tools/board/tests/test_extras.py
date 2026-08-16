"""Story 3 — the dpm board's own capabilities, on keys the CPM board leaves alone (FR19).

Story 1 gave back the keys both boards share. This is the other side of that settlement: a forced
re-read, a cross-project search and a coverage-gaps view are things the CPM board has no equivalent
of, and a board is entitled to bind its own capabilities however it likes — *provided* it does not
take a key the other board has already spent.

So the two criteria pull in opposite directions, and both are needed. The first says the extras are
reachable at all, driven through a running board. The second says where they were put, read from the
CPM board's source by the same reader story 1 uses — and it is a rejection over the extras rather
than an equality between the maps, because "the dpm board binds three keys CPM does not" is the
intended state rather than a drift to be reported.
"""

from __future__ import annotations

from pathlib import Path

from key_maps import cpm_bindings, extras, extras_on_cpm_keys
from pilot import board, until
from wiring import registered, surveyed

from board import COMMANDS, BoardApp, GapsScreen, SearchScreen
from board_view import ProjectView

#: How long a key's effect is given to land. The board answers in one frame; this is slack for a
#: loaded machine rather than a wait for anything in particular.
SETTLE = 2.0


async def test_ctrl_r_re_reads_every_project_ignoring_the_cache(tmp_path, project):
    """Criterion 1's first key [feature], and the one with a second thing to prove.

    `ctrl+f` and `ctrl+g` open a screen, which is visible from outside. A forced re-read looks
    exactly like an ordinary one unless the *fresh* flag is followed, so the assertion is on the
    argument the survey was called with rather than on the fact that it was called: a `ctrl+r`
    wired to `refresh` would re-read every project and pass any test that only counted the calls.
    """
    first, second = project("first"), project("second")
    rows, injections, _ = registered(tmp_path, first, second)
    asked: list = []

    async with board(rows, **injections, survey=surveyed(asked)) as (app, pilot):
        await until(pilot, lambda: not any(row.pending for row in app.selection.projects), timeout=SETTLE)

        opening = list(asked)
        asked.clear()

        await pilot.press("ctrl+r")
        await until(pilot, lambda: len(asked) == len(opening), timeout=SETTLE)

    assert not any(fresh for _, fresh in opening), (
        f"the opening read went past the cache without being asked to: {opening}"
    )
    assert {path for path, _ in asked} == {first, second}, (
        f"`ctrl+r` did not re-read every registered project: {asked}"
    )
    assert all(fresh for _, fresh in asked), (
        f"`ctrl+r` re-read from the cache rather than past it: {asked}"
    )


async def test_ctrl_f_opens_search_and_ctrl_g_opens_coverage_gaps():
    """Criterion 1's other two keys [feature], each read from the screen it put in front.

    Both are given the injection they fan out through, answering with nothing: what is under test
    is which screen the key opens, and a real fan-out would make this a test of the search.
    """
    async def nothing(*arguments, **keywords):
        return []

    rows = [ProjectView(name="alpha", path=Path("/alpha"))]

    async with board(rows, search=nothing, gaps=nothing) as (app, pilot):
        await pilot.press("ctrl+f")
        await until(pilot, lambda: isinstance(app.screen, SearchScreen), timeout=SETTLE)

        searching = isinstance(app.screen, SearchScreen)

        await pilot.press("escape")
        await until(pilot, lambda: not isinstance(app.screen, SearchScreen), timeout=SETTLE)

        await pilot.press("ctrl+g")
        await until(pilot, lambda: isinstance(app.screen, GapsScreen), timeout=SETTLE)

        gaps = isinstance(app.screen, GapsScreen)

    assert searching, "`ctrl+f` did not open the search"
    assert gaps, "`ctrl+g` did not open the coverage-gaps view"


def test_no_capability_of_this_boards_own_sits_on_a_key_the_cpm_board_binds():
    """Criterion 2, the must-NOT [integration]. Read from the other board's source, not from a list.

    **The floor first.** "No extra is on a CPM key" is what an empty extras set says too, and an
    extras set can empty itself by accident — a reader that stopped finding the class, a
    `SAME_MEANING` entry that swallowed a capability CPM does not have. So the three this story is
    about are named, and their absence fails here rather than passing quietly.

    The failure names the key and what this board does with it, because "an extra is on a CPM key"
    sends whoever reads it back to two files to find out which one.
    """
    cpm = cpm_bindings()
    dpm = {key: action for key, action, *_ in BoardApp.BINDINGS}

    mine = extras(cpm, dpm)

    for action in ("force_refresh", "search", "coverage_gaps"):
        assert action in mine.values(), (
            f"{action} is not being read as one of this board's own capabilities: {mine}"
        )

    found = extras_on_cpm_keys(cpm, dpm)

    assert found == {}, "\n".join(
        f"`{key}` is this board's {action} and the cpm board binds it to {cpm[key]}"
        for key, action in found.items()
    )


def test_every_extra_is_reachable_from_the_palette_as_well_as_from_a_key():
    """The pair rule the board applies to everything else, applied to the keys just moved.

    A capability that is only bindable is found by reading the footer at the moment it happens to be
    needed. These three moved to modified keys, which makes that worse rather than better: `ctrl+r`
    is not a key anybody guesses.
    """
    cpm = cpm_bindings()
    dpm = {key: action for key, action, *_ in BoardApp.BINDINGS}
    offered = {command.action for command in COMMANDS}

    for key, action in extras(cpm, dpm).items():
        assert action in offered, f"`{key}` reaches {action}, which is in no palette entry"
