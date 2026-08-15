"""Story 1 — the three-column browser (FR4, ENV7).

Every test here drives the real app through Textual's ``run_test()`` pilot and asserts on the
strips it painted (criterion 4). Nothing reads a widget's own account of itself: an option list will
tell you how many options it holds and what style it was handed, and every one of those answers is
the app agreeing with itself. Keystrokes go through the pilot for the same reason — focus moving
because ``right`` was pressed is a fact about the app; focus moving because a test called
``focus()`` is a fact about the test.

The expectations come from the fixture rows rather than from labels written here, so a fixture that
grows in a later story cannot leave an assertion quietly describing a board that no longer exists.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from pilot import board, lines, preview, styles

from board_view import (
    STATE_STYLE,
    EpicView,
    ProjectView,
    Selection,
    StoryView,
    style_collisions,
    style_for,
)
from status_model import EPIC_STATES, Progress


def sample() -> list[ProjectView]:
    """Two projects: one with epics and stories, one the board could not read.

    The second is not decoration. The browser renders *every* registered project, so it meets a
    project whose server would not answer the first time a real board is opened — and a column that
    raises on one row takes the whole board with it (FR11, NFR2).
    """
    return [
        ProjectView(
            "alpha",
            Path("/alpha"),
            progress=Progress(1, 3),
            epics=(
                EpicView(
                    "e1",
                    "Read-only server mode",
                    "complete",
                    Progress(1, 1),
                    (StoryView("s1", "Refuse a write", "complete"),),
                ),
                EpicView(
                    "e2",
                    "Board foundation",
                    "in_progress",
                    Progress(0, 2),
                    (
                        StoryView("s2", "The registry", "complete"),
                        StoryView("s3", "The pool", "pending"),
                    ),
                ),
            ),
        ),
        ProjectView("beta", Path("/beta"), unreadable="no-database"),
    ]


def one_of_each_state() -> list[ProjectView]:
    """A project holding exactly one epic per state the model can derive."""
    return [
        ProjectView(
            "palette",
            Path("/palette"),
            epics=tuple(
                EpicView(f"e{index}", f"Epic in {state}", state)
                for index, state in enumerate(EPIC_STATES)
            ),
        )
    ]


async def test_the_three_columns_render_the_rows_they_were_given():
    """Criterion 1's first half: Projects, Epics and Stories all paint, drilled down in order."""
    projects = sample()
    alpha = projects[0]

    async with board(projects) as (app, _):
        assert lines(app, "projects") == [row.label for row in projects]
        assert lines(app, "epics") == [row.label for row in alpha.epics]
        assert lines(app, "stories") == [row.label for row in alpha.epics[0].stories]

        # Not only that the right rows are in the right columns — that a row says what it is. The
        # assertions above would hold for a label format that had lost the progress figure.
        assert "alpha" in lines(app, "projects")[0]
        assert "1/3" in lines(app, "projects")[0]


async def test_focus_moves_between_the_columns_with_left_and_right():
    """Criterion 1's second half, and criterion 4: the keys go through the pilot.

    Focus that moved because ``right`` was pressed went through the app's real binding table and
    its real event loop. A test calling ``focus()`` would prove the widget can take focus.
    """
    async with board(sample()) as (app, pilot):
        assert app.focused.id == "projects"

        await pilot.press("right")
        assert app.focused.id == "epics"

        await pilot.press("right")
        assert app.focused.id == "stories"

        # The ends are ends, not a wrap. ← from Projects landing on Stories reads as a jump.
        await pilot.press("right")
        assert app.focused.id == "stories"

        await pilot.press("left", "left", "left")
        assert app.focused.id == "projects"


async def test_the_preview_beneath_a_column_follows_its_highlighted_row():
    """Criterion 2, for both previewed columns, against the row the cursor is actually on."""
    projects = sample()
    alpha = projects[0]

    async with board(projects) as (app, pilot):
        assert preview(app, "epic")[0] == alpha.epics[0].label
        assert preview(app, "story")[0] == alpha.epics[0].stories[0].label

        await pilot.press("right", "down")

        assert preview(app, "epic")[0] == alpha.epics[1].label, "the epic preview did not follow"
        assert preview(app, "story")[0] == alpha.epics[1].stories[0].label, (
            "the story preview stayed under the epic the cursor left"
        )

        await pilot.press("right", "down")

        assert preview(app, "story")[0] == alpha.epics[1].stories[1].label


async def test_every_derived_state_renders_in_its_own_colour():
    """Criterion 3, from the painted strips: the seven states, seven colours.

    **Read from what was painted, not from ``STATE_STYLE``.** A test that compared the mapping
    against itself would pass with every row rendering identically — which is what a stylesheet
    applying one class to every row produces, and it satisfies "colour carries state" as worded.
    """
    async with board(one_of_each_state()) as (app, _):
        painted = styles(app, "epics")
        rows = lines(app, "epics")

        assert len(rows) == len(EPIC_STATES), f"not every state rendered a row: {rows}"

        colours = [painted[row] for row in rows]

        assert len(set(colours)) == len(colours), (
            f"states shared a rendered colour: {dict(zip(rows, colours))}"
        )


async def test_a_row_renders_in_the_colour_its_own_state_maps_to():
    """The other half of criterion 3: distinct is not enough if they are distinctly wrong.

    Two epics differing only in state must differ on screen, and the *pair* that differs must be
    the pair the model distinguished — so the assertion is made against a second row known to be
    in a different state rather than against a colour name written here.
    """
    projects = one_of_each_state()
    epics = projects[0].epics

    async with board(projects) as (app, _):
        painted = styles(app, "epics")

        blocked = next(row for row in epics if row.state == "blocked")
        ready = next(row for row in epics if row.state == "ready")

        assert painted[blocked.label] != painted[ready.label], (
            "a blocked epic and a ready one painted the same, so the colour carries nothing"
        )


def test_no_two_states_share_a_style():
    """Criterion 3's distinctness, over the mapping — the check the rendering test cannot make.

    The rendered test above sees only the states a fixture happens to contain. This one is over
    the whole map, so a state added later with a borrowed colour fails here even if no fixture
    ever puts the two side by side.
    """
    assert style_collisions(STATE_STYLE) == []


def test_the_collision_check_names_the_states_that_share_a_style():
    """must NOT — the distinctness check passes over a mapping where two states are the same.

    Planted, because once the real map is distinct it can no longer tell a working check from one
    that returns an empty list whatever it is given.
    """
    complaints = style_collisions({"blocked": "red", "in_progress": "red", "ready": "green"})

    assert complaints == ["blocked and in_progress both render as 'red'"]


def test_every_state_the_model_derives_has_a_style_and_an_unknown_one_is_refused():
    """The enumeration is the model's, so a state added there arrives here with nothing to show.

    Refusing is the point. A default would render the new state exactly like every other row, and
    a board where every row looks the same is indistinguishable from one with nothing to report.
    """
    for state in EPIC_STATES:
        assert style_for(state), f"the model derives {state!r} and nothing says what it looks like"

    with pytest.raises(KeyError, match="no style for state"):
        style_for("nearly-done")


async def test_a_project_the_board_could_not_read_is_a_row_that_says_so():
    """FR11 reaching the browser: one unreadable project does not take the board down.

    The row renders, names its state, and selecting it empties the columns to its right without
    raising — and the healthy project still renders after the cursor comes back.
    """
    projects = sample()
    broken = projects[1]

    async with board(projects) as (app, pilot):
        assert lines(app, "projects")[1] == broken.label
        assert broken.unreadable in lines(app, "projects")[1]

        await pilot.press("down")

        assert lines(app, "epics") == []
        assert lines(app, "stories") == []
        assert preview(app, "epic") == []

        await pilot.press("up")

        assert lines(app, "epics") == [row.label for row in projects[0].epics]


def test_the_selection_pulls_its_own_indices_back_inside_the_lists_they_index():
    """The clamp as a rule, which the feature test below cannot see.

    ``OptionList`` clamps ``highlighted`` itself and raises a highlight event when it does, so the
    app recovers a stale index through the message pump whether or not the model ever clamped —
    and the on-screen outcome is identical. What differs is *when*: everything painted between the
    refresh and the event was painted from an index pointing outside its list. Asserted here on
    the model, where a pilot has no way to stand in for it.
    """
    projects = sample()
    alpha = projects[0]
    shrunk = ProjectView(alpha.name, alpha.path, epics=alpha.epics[:1])

    selection = Selection([shrunk], project=0, epic=1, story=1)
    selection.clamp()

    assert (selection.epic, selection.story) == (0, 0)
    assert selection.current_epic is shrunk.epics[0]
    assert selection.stories == shrunk.epics[0].stories

    # And a project list that emptied entirely — nothing to index into, and no exception either.
    gone = Selection([], project=3)
    gone.clamp()

    assert gone.current_project is None
    assert gone.epics == ()


async def test_an_epic_that_vanishes_from_a_refresh_moves_the_cursor_rather_than_emptying_a_column():
    """The invalid-selection case, which only a *second* read can produce.

    An epic can be retired or deleted between one refresh and the next while its stories are on
    screen. Holding the old index would point the Stories column at a row that is not there;
    resetting to the top would yank a user out of the list they were reading. The cursor clamps.
    """
    projects = sample()
    alpha = projects[0]

    async with board(projects) as (app, pilot):
        await pilot.press("right", "down", "right", "down")

        assert (app.selection.epic, app.selection.story) == (1, 1)

        fewer = [
            ProjectView(alpha.name, alpha.path, progress=alpha.progress, epics=alpha.epics[:1]),
            projects[1],
        ]
        app.show(fewer)
        await pilot.pause()

        assert lines(app, "epics") == [alpha.epics[0].label]
        assert lines(app, "stories") == [row.label for row in alpha.epics[0].stories]
        assert (app.selection.epic, app.selection.story) == (0, 0)
