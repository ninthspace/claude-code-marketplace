"""Story 2 — the pill and the badge against the column's right edge (FR19).

Both markers say something about the project as a whole rather than about the end of its name, and
appended to the label that is exactly where they end up: halfway across a wide column, and first in
line to be clipped on a narrow one. The board lays the row out as a grid instead — the name flexing,
each marker in a right-justified cell of its own.

**Rendered at a width, not inspected as a structure.** A grid with the columns declared in the right
order is not the claim; the claim is where the characters land at 24 cells and at 48, so every test
here renders and reads back the line. The two widths are the criterion's, and they are the two that
matter: one where everything fits and one where it does not.
"""

from __future__ import annotations

import pytest
from pilot import board, colours, strips
from rich.console import Console
from rich.text import Text

from board import project_row
from board_view import BADGE_STYLE, BROKEN, LIVE, PILL_STYLE, ProjectView, integrity_badge, live_pill

#: The two widths the criterion names. 24 is the Projects column's own minimum and 48 its maximum,
#: so between them they are the column as a user can actually have it.
WIDTHS = (24, 48)

#: A name long enough that nothing fits beside it at either width — which is what makes the
#: rejection say something. A row with room to spare is laid out correctly by every composition,
#: including the one this story replaced.
LONG = "a-project-with-a-very-long-name-indeed"


def rendered(row: ProjectView, width: int) -> str:
    """One project row as it lands at ``width``, markup stripped — the characters and their places.

    Rendered through a plain Rich console rather than the board, because the criterion is about a
    *width* and the board's column has one width at a time. The board's own rendering is checked
    separately, below; what this reads is the composition at both widths in one run.
    """
    console = Console(width=width, color_system=None)

    with console.capture() as captured:
        console.print(row if isinstance(row, Text) else project_row(row), end="")

    return captured.get().splitlines()[0]


def marked(name: str = "alpha", *, live: int = 1, violations: int = 0) -> ProjectView:
    """A project row carrying whichever markers the test is about."""
    from pathlib import Path

    return ProjectView(name, Path(f"/{name}"), live=live, violations=violations)


def whole(line: str, *, pill: str = "", badge: str = "") -> None:
    """Assert every marker on ``line`` survived the width intact, and that the name is what gave.

    Shared by the rejection and its control, so what the control demonstrates is this assertion
    failing rather than a second, weaker copy of it written to be failed.
    """
    for marker in (pill, badge):
        if marker:
            assert marker in line, (
                f"{marker!r} did not survive the layout whole: {line!r}. A marker is a fixed handful "
                "of cells, so the row's flexible part — the project's name — is what has to give."
            )


def test_the_pill_ends_at_the_right_edge_at_both_widths():
    """Criterion 1 [unit]. Rendered at 24 and at 48, and read from the end of the line.

    `rstrip` is deliberately absent. What the criterion says is that the pill's last character is in
    the row's *last* column, and a line whose pill is followed by three spaces satisfies "the pill is
    at the end" while sitting nowhere near the edge.
    """
    for width in WIDTHS:
        line = rendered(marked(), width)

        assert len(line) == width, f"the row did not fill the column at {width}: {line!r}"
        assert line.endswith(LIVE), f"the pill is not against the right edge at {width}: {line!r}"


def test_the_pill_stays_outermost_when_the_badge_is_there_too():
    """Criterion 1, with both markers. The pill is the edge on the CPM board, so it is the edge here.

    A reader of both boards looks for the running-session marker in the same place; dpm's badge, which
    that board has no equivalent of, goes inboard of it rather than displacing it.
    """
    for width in WIDTHS:
        line = rendered(marked(violations=2), width)

        assert line.endswith(LIVE), f"the badge took the pill's place at {width}: {line!r}"
        assert BROKEN in line, f"the badge is not on the row at {width}: {line!r}"
        assert line.index(BROKEN) < line.index(LIVE), f"the badge is outboard of the pill: {line!r}"


async def test_each_marker_keeps_its_own_colour_over_the_row_s():
    """Criterion 2 [unit]. Read from what the board painted, on a row the cursor is not on.

    The cursor is elsewhere on purpose: the highlighted row is repainted as one bar in that row's
    colour (story 1), which is the CPM board's behaviour and is what makes a selection read as one
    thing. What this criterion is about is the row as it is painted the rest of the time.
    """
    rows = [marked("first"), marked("second", live=2, violations=3)]

    async with board(rows) as (app, pilot):
        await pilot.pause()

        painted = {
            segment.text.strip(): segment.style
            for strip in strips(app, "projects")
            if "second" in strip.text
            for segment in strip
            if segment.text.strip() and segment.style is not None
        }
        row_colour = colours(app, "projects")

    assert painted, "the second project painted no row to read"

    summary = next(text for text in painted if text.startswith("second"))
    pill = next(text for text in painted if LIVE in text)
    badge = next(text for text in painted if BROKEN in text)

    assert painted[pill].color != painted[summary].color, (
        f"the pill is painted in the row's own colour: {painted[pill]}"
    )
    assert painted[badge].color != painted[summary].color, (
        f"the badge is painted in the row's own colour: {painted[badge]}"
    )
    assert painted[pill].color != painted[badge].color, (
        f"the pill and the badge are the same colour, so neither says which it is: {painted[pill]}"
    )
    assert row_colour, "no project row painted both a foreground and a background"


@pytest.mark.parametrize(
    ("width", "live", "violations"),
    [(24, 2, 0), (24, 0, 1), (30, 2, 1), (48, 2, 1)],
    ids=["pill at the minimum", "badge at the minimum", "both, just", "both, roomy"],
)
def test_neither_marker_is_truncated_when_the_row_will_not_fit(width, live, violations):
    """Criterion 3, the must-NOT [unit]. The name gives; the markers do not.

    A name far too long for the width in every case, so there is always something for the layout to
    take — and each marker has to come through whole while it does.

    **30 rather than 24 for the pair**, and the reason is arithmetic rather than convenience: two
    markers and their gaps are 25 cells, so a 24-cell row carrying both has already given up the
    whole of its name and has nothing left to give. `board_view.markers` records that floor. What
    the criterion is about is a row that *can* be laid out and lays out the wrong thing, and each
    case here is one.
    """
    line = rendered(marked(LONG, live=live, violations=violations), width)

    whole(line, pill=live_pill(live), badge=integrity_badge(violations))

    assert LONG not in line, f"nothing gave at all, so the row is not being laid out to width: {line!r}"

    kept = line.split("…")[0]

    assert kept and LONG.startswith(kept), (
        f"what survived is not the front of the name, so the row gave from the wrong end: {line!r}"
    )


def test_appending_the_markers_to_the_label_is_what_the_rejection_catches():
    """The control for criterion 3, and it is the composition this story replaced.

    The rejection is about an absence — nothing truncated — and an absence is satisfied by a board
    that renders no markers at all, or by a check that never looked. So the same assertion is run
    against a row composed the old way: the markers appended to the label as text, truncated to the
    column with an ellipsis, which is what a single flexible cell does to whatever is at its end.
    """
    row = marked(LONG, live=2, violations=1)
    appended = Text(row.label, no_wrap=True, overflow="ellipsis")

    line = rendered(appended, 30)

    with pytest.raises(AssertionError) as raised:
        whole(line, pill=live_pill(2), badge=integrity_badge(1))

    assert live_pill(2) in str(raised.value), (
        f"the failure did not name the marker that was lost: {raised.value}"
    )


async def test_the_pill_follows_the_column_when_the_terminal_is_resized():
    """Criterion 1, on the board rather than a console — and after the width has changed under it.

    The rendered-at-a-width tests above ask the composition the right question and cannot ask this
    one: a board that laid its rows out correctly *once* and then kept the strips it had would pass
    every one of them, and would leave the pill stranded mid-row the moment somebody dragged the
    window. So the terminal is resized and the same edge is read again.

    The row's last column is the last cell inside the option list's padding, which is why the
    assertion allows exactly one trailing space rather than stripping the line: a pill followed by
    two is a pill that is not against the edge.
    """
    rows = [marked("first"), marked("second"), marked("third")]

    async with board(rows, size=(120, 30)) as (app, pilot):
        wide = pill_row(app)

        await pilot.resize_terminal(34, 30)
        await pilot.pause()

        narrow = pill_row(app)

    assert wide != narrow, f"the row did not follow the column's width: {wide!r}"

    for line in (wide, narrow):
        assert line.endswith(f"{LIVE} "), f"the pill is not against the column's edge: {line!r}"


def pill_row(app) -> str:
    """The painted line of the first project row carrying a pill, padding and all."""
    return next(strip.text for strip in strips(app, "projects") if LIVE in strip.text)


def test_a_project_with_no_markers_is_the_plain_row_it_always_was():
    """Criterion 1's other side, which no width can show: nothing was added to the ordinary row.

    Every project on a board where nothing is running and nothing is wrong is this row, and a layout
    that padded it to the column's width would put a trailing run of spaces in every copied line.
    """
    plain = marked("clean", live=0)

    assert rendered(plain, 48) == plain.label, f"a plain row was laid out as a grid: {plain.label!r}"


def test_the_markers_carry_the_styles_the_view_names():
    """Criterion 2, over the mapping — the check the rendering cannot make.

    The rendering test above says the three differ; that is satisfied by three arbitrary colours,
    including three the next change picks again by accident. This says which two the view decided
    on, and that they are foreground-only — a marker with a background of its own would be a second
    background on a highlighted row, and the cursor bar blends toward whichever it reads first.
    """
    for style in (PILL_STYLE, BADGE_STYLE):
        assert "on " not in style, f"{style!r} carries a background, which the cursor bar samples"

    assert PILL_STYLE != BADGE_STYLE, "the pill and the badge are declared the same colour"
