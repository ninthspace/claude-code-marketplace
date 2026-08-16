"""Story 2 — finished work is hidden until `z` asks for it (FR19).

Two claims that look like one and are not. The first is about the board: what it opens showing, and
what each press of `z` does to that. The second is about the filter underneath: which states it is
entitled to take, asserted state by state rather than over the set, because "the live rows survived"
is satisfied by a filter that took the wrong one and left three.

**The live states are read from the model, never from the board's own `HIDDEN_STATES`.** Deriving
them from the thing under test would make the control below pass: widen the filter, and the state it
starts taking quietly stops being one the test expects to survive.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from pilot import board, lines, show_everything, toasts

import board_view
from board_view import EpicView, ProjectView, StoryView, visible
from status_model import COMPLETE, EPIC_STATES, RETIRED

#: The states nothing may hide, from the model's enumeration rather than from the board's filter.
#: `ready`, `in_progress`, `blocked` and `pending` — work outstanding, in four shapes.
LIVE = tuple(state for state in EPIC_STATES if state not in (COMPLETE, *RETIRED))

#: One epic per state a story can be in, which is also one per group criterion 1 counts.
STORY_STATES = ("pending", COMPLETE, *RETIRED)


def four_groups() -> list[ProjectView]:
    """A project holding an epic and a story in each of the four states, live one first."""
    return [
        ProjectView(
            "mixed",
            Path("/mixed"),
            epics=tuple(
                EpicView(
                    f"e-{state}",
                    f"Epic in {state}",
                    "in_progress" if state == "pending" else state,
                    stories=(StoryView(f"s-{state}", f"Story in {state}", state),),
                )
                for state in STORY_STATES
            ),
        )
    ]


def titles(rows: list[str]) -> list[str]:
    """A column's painted rows with the progress figure taken off, leaving each row's own title."""
    return [row.split("·")[0].strip() for row in rows]


async def test_the_board_opens_on_live_work_and_z_shows_the_rest():
    """Criterion 1 [feature]. Both columns, both directions, driven through the key.

    The Stories column is asserted alongside the Epics column because they are filtered by separate
    property reads: a board hiding a complete epic while showing a complete story under a live one
    passes an assertion that only looks left.

    The third state is compared against the first rather than described again — *returns to* is a
    claim about two moments being the same, and writing the expected rows out twice would let the
    second press land anywhere the first one happened to be written down.
    """
    async with board(four_groups()) as (app, pilot):
        opening = titles(lines(app, "epics"))
        opening_stories = lines(app, "stories")

        await show_everything(pilot)

        widened = titles(lines(app, "epics"))

        await pilot.press("z")
        await pilot.pause()

        returned = titles(lines(app, "epics"))
        returned_stories = lines(app, "stories")

    assert opening == ["Epic in pending"], f"the board opened showing finished work: {opening}"
    assert opening_stories == ["Story in pending"], (
        f"a finished story rendered under a live epic: {opening_stories}"
    )

    assert widened == [f"Epic in {state}" for state in STORY_STATES], (
        f"`z` did not reveal all four groups: {widened}"
    )

    assert returned == opening, f"a second `z` did not return to the first state: {returned}"
    assert returned_stories == opening_stories, f"the Stories column stayed open: {returned_stories}"


async def test_each_press_says_which_way_it_went():
    """Criterion 2 [feature]. The two messages differ, and each names its own direction.

    **Asserted as a difference plus a word, not against a sentence written here.** A test holding
    the exact string is a second copy of the message that goes on passing after the real one is
    reworded — but a test asserting only that *something* was said passes on two identical toasts,
    which is the failure this criterion exists to name.
    """
    async with board(four_groups(), notifications=True) as (app, pilot):
        await pilot.press("z")
        await pilot.pause()

        showing = toasts(app)[-1]

        await pilot.press("z")
        await pilot.pause()

        hiding = toasts(app)[-1]

    assert showing != hiding, f"both presses said the same thing: {showing!r}"
    assert "showing" in showing.lower(), f"the reveal did not say it was revealing: {showing!r}"
    assert "hiding" in hiding.lower(), f"the hide did not say it was hiding: {hiding!r}"


def a_live_state_survives_the_filter(state: str) -> None:
    """Criterion 3's case for one state, as a function so the control can run it too.

    Extracted rather than duplicated: a control asserting against its own copy of the case would
    prove that *a* check fails when the filter is widened, and say nothing about the one that runs
    in the suite.
    """
    rows = (EpicView("e", f"Epic in {state}", state),)
    kept = visible(rows, show_retired=False)

    assert kept == rows, f"the filter removed a live row: the epic in {state} is not on the board"


@pytest.mark.parametrize("state", LIVE)
def test_no_live_state_is_removed_by_the_filter(state):
    """Criterion 3, the must-NOT [unit] — one case per live state, not one for the set.

    Per state because that is what the criterion asks for and because the set-shaped version is
    weaker in a way that matters: a filter that started hiding `blocked` would leave three of four
    rows standing, and an assertion over the group would report the count it expected.
    """
    a_live_state_survives_the_filter(state)


def test_widening_the_filter_makes_that_case_fail_and_name_the_state_it_lost(monkeypatch):
    """The control [unit]. Plant a live state in `HIDDEN_STATES` and watch the check above go red.

    Without this, criterion 3 is an assertion rather than a verification: every case passes on a
    board where nothing is filtered at all, and passes just as well against a `visible()` that
    returned its argument untouched. The plant is what distinguishes a filter that keeps the live
    rows from an absence of filtering.

    `blocked` rather than any live state, because it is the one furthest from finished — a run that
    quietly hid it would be hiding exactly the work somebody opened the board to find.
    """
    monkeypatch.setattr(board_view, "HIDDEN_STATES", (COMPLETE, *RETIRED, "blocked"))

    with pytest.raises(AssertionError, match="blocked"):
        a_live_state_survives_the_filter("blocked")
