"""Story 1 — the cursor in the row's own colour (FR4, FR19).

Every row on this board is a colour that means something: green is ready, red is blocked, yellow is
in flight. Textual's default cursor is a block of one fixed accent painted over whichever row it is
on — so the single row a user is *looking at* is the one row whose state has been painted out. The
board paints the highlight itself instead: the row's own colour, blended partway toward the
background so it reads as a selection rather than a glare.

**The must-NOT and its control are about the CSS, not the renderer.** `Column.render_line` reads the
background to blend toward from the strip it was handed, so Textual's block cursor left in place is
not a second highlight underneath the board's — it is the colour the board's own highlight gets
mixed with. That is what the control demonstrates: with the override taken out of the stylesheet,
the same assertion sees a bar mixed with `#0178D4` and fails.
"""

from __future__ import annotations

from collections import Counter
from pathlib import Path

import pytest
from pilot import board, colours
from rich.color import Color as RichColour
from rich.color_triplet import ColorTriplet
from rich.segment import Segment
from rich.style import Style
from textual.color import Color
from textual.strip import Strip

from board import BLURRED_WEIGHT, FOCUSED_WEIGHT, BoardApp, _blend, cursor_strip
from board_view import EpicView, ProjectView

#: A background to blend toward in the pure tests. Any colour would do — what the assertions turn on
#: is that both rows are blended toward the *same* one.
SURFACE = ColorTriplet(18, 18, 18)

#: Where the stylesheet's override starts. Held here so the control removes the real rule and fails
#: loudly if it is ever renamed, rather than removing nothing and reporting a passing board.
OVERRIDE = "    OptionList > .option-list--option-highlighted,"


def a_row(colour: str, text: str = "a row") -> Strip:
    """One rendered row's strip: its text in ``colour`` on :data:`SURFACE`, with padding either side.

    The padding matters. A real strip starts with the column's own blank cells, and the reader has
    to reach past them for the row's colour — a strip built as one coloured segment would pass
    against a reader that simply took the first segment it was given.
    """
    blank = Style(bgcolor=rich_colour(SURFACE))
    body = Style(color=rich_colour(triplet(colour)), bgcolor=rich_colour(SURFACE))

    return Strip(
        [Segment(" ", blank), Segment(text, body), Segment(" ", blank)], len(text) + 2
    )


def triplet(colour: str) -> ColorTriplet:
    """``colour`` as the board's own stylesheet resolves it — `red` is CSS red, not the ANSI one."""
    return ColorTriplet(*Color.parse(colour).rgb)


def rich_colour(colour: ColorTriplet) -> RichColour:
    """A truecolor Rich colour from a triplet, for building a strip to hand the renderer."""
    return RichColour.from_triplet(colour)


def bar_of(strip: Strip) -> tuple[ColorTriplet, ColorTriplet]:
    """The foreground and background the repainted strip's own text was painted in."""
    for segment in strip:
        if segment.text.strip() and segment.style is not None:
            return segment.style.color.get_truecolor(), segment.style.bgcolor.get_truecolor()

    raise AssertionError(f"the repainted strip carries no text: {strip.text!r}")


def the_cursor_is_the_board_s_own(app, column: str, *, colour=None, focused: bool) -> str:
    """Assert ``column``'s highlighted row is a row colour blended toward that column's own surface.

    The bar row is found by *being* different — the one row whose background is not the surface the
    others share — rather than by asking the widget which row it thinks is highlighted. What the
    criterion is about is the pixels, and a widget that reports a highlight it did not paint is one
    of the things this is here to catch.

    ``colour`` is the row's own colour, which the bar has painted over and cannot be read back from.
    Left out, it is taken from the rows that were *not* highlighted, which is exact for a column
    whose rows share one style — the Projects column — and wrong for one where every row differs.
    """
    painted = colours(app, column)

    assert len(painted) > 2, (
        f"the {column} column painted {len(painted)} rows, which is too few to read the surface off "
        "the unhighlighted ones: with two, the bar and the surface each appear once and the more "
        "common of them is whichever was painted first"
    )

    surface, _ = Counter(background for _, background in painted.values()).most_common(1)[0]
    bars = {text: background for text, (_, background) in painted.items() if background != surface}

    assert len(bars) == 1, (
        f"the {column} column painted {len(bars)} rows off the surface {surface}, not one: {bars}"
    )

    (text, background), = bars.items()

    if colour is None:
        others = {
            foreground for row, (foreground, _) in painted.items() if row != text
        }
        assert len(others) == 1, f"the {column} column's rows do not share one colour: {others}"
        colour = others.pop()

    expected = _blend(colour, surface, FOCUSED_WEIGHT if focused else BLURRED_WEIGHT)

    assert background == expected, (
        f"the cursor on {text!r} is painted {background}, not that row's own colour {colour} "
        f"blended toward the board's own surface {surface}, which is {expected}. A third colour is "
        f"in the mix — Textual's block cursor is {app.theme_variables.get('block-cursor-background')}"
    )

    return text


def several_projects() -> list[ProjectView]:
    """Three projects, the first holding a row per colour the cursor has to carry.

    Three rather than one, because the check above reads the surface off the rows that are *not*
    highlighted. One row leaves no such row; two leave a tie, where the bar and the surface each
    appear once and "the common background" is decided by paint order.
    """
    return [
        ProjectView(
            "first",
            Path("/first"),
            epics=(
                EpicView("e1", "Blocked epic", "blocked"),
                EpicView("e2", "Ready epic", "ready"),
                EpicView("e3", "In-flight epic", "in_progress"),
            ),
        ),
        ProjectView("second", Path("/second"), epics=()),
        ProjectView("third", Path("/third"), epics=()),
    ]


def test_the_bar_carries_the_row_s_own_colour_blended_toward_the_background():
    """Criterion 1 [unit]. Two rows, two bars, and the difference between them is the row's colour.

    Run over the renderer directly rather than a running board: what this criterion claims is
    arithmetic — that the bar is *this row's* colour mixed with the background — and a board renders
    it once per row where a call renders it for whatever colour is asked for. The running board is
    criterion 4's, below.

    The third assertion is the one that rules out an accent. Two bars differing is satisfied by a
    renderer that hashes the row text into a palette; what says the colour is the row's is each bar
    landing between its own row's colour and the shared background.
    """
    red, green = triplet("red"), triplet("green")

    _, red_bar = bar_of(cursor_strip(a_row("red"), focused=True))
    _, green_bar = bar_of(cursor_strip(a_row("green"), focused=True))

    assert red_bar != green_bar, f"a red row and a green row highlight identically: {red_bar}"
    assert red_bar == _blend(red, SURFACE, FOCUSED_WEIGHT), red_bar
    assert green_bar == _blend(green, SURFACE, FOCUSED_WEIGHT), green_bar

    faint = bar_of(cursor_strip(a_row("red"), focused=False))[1]

    assert faint == _blend(red, SURFACE, BLURRED_WEIGHT), faint
    assert faint != red_bar, "a blurred column's bar is as loud as the focused one's"


async def test_textual_s_own_highlight_is_on_no_row_focused_or_blurred():
    """Criterion 2, the must-NOT [unit]. Both columns, in both focus states.

    Blurred as well as focused because they are two rules in Textual's own stylesheet — a board that
    neutralised only `:focus` would look right until the cursor was somewhere else, which is the
    board's ordinary condition in two columns out of three.
    """
    async with board(several_projects()) as (app, pilot):
        the_cursor_is_the_board_s_own(app, "projects", focused=True)
        the_cursor_is_the_board_s_own(app, "epics", colour=triplet("red"), focused=False)

        await pilot.press("right")
        await pilot.pause()

        the_cursor_is_the_board_s_own(app, "projects", focused=False)
        the_cursor_is_the_board_s_own(app, "epics", colour=triplet("red"), focused=True)


async def test_with_the_css_override_removed_the_rejection_fails(monkeypatch):
    """Criterion 3, the control [unit]. The rejection is run against a board that commits it.

    Without this, "Textual's highlight appears on no row" is equally true of a board that renders no
    highlight at all, and of a check that never looked. The override is cut out of the stylesheet,
    the same assertion is run, and what it says is read: the bar has to be wrong *and* the failure
    has to name the block cursor as what got into it.
    """
    monkeypatch.setattr(BoardApp, "CSS", without_the_override(BoardApp.CSS))

    async with board(several_projects()) as (app, _):
        with pytest.raises(AssertionError) as raised:
            the_cursor_is_the_board_s_own(app, "epics", colour=triplet("red"), focused=False)

    said = str(raised.value)

    assert "block cursor" in said, f"the failure did not say what got into the bar: {said}"
    assert "#0178D4" in said, f"the failure did not name the colour that got into the bar: {said}"


def without_the_override(css: str) -> str:
    """``css`` with the rule that neutralises Textual's block cursor cut out.

    Located by the selector rather than by a copy of the whole rule, so the control keeps working
    when the comment above it is reworded — and raises rather than silently removing nothing if the
    selector itself ever moves.
    """
    start = css.index(OVERRIDE)

    return css[:start] + css[css.index("}", start) + 1 :]


async def test_moving_the_cursor_paints_the_row_it_lands_on():
    """Criterion 4 [feature]. The cursor is driven, and the row it arrives at is read.

    The board renders the highlight in `render_line`, which is called for whatever Textual thinks is
    highlighted — so the thing worth checking on a running board is that pressing a key moves both:
    the bar arrives on the new row *and* leaves the old one. A cursor that painted every row it had
    ever been on would satisfy either half alone.
    """
    async with board(several_projects()) as (app, pilot):
        await pilot.press("right")
        await pilot.pause()

        first = the_cursor_is_the_board_s_own(app, "epics", colour=triplet("red"), focused=True)

        await pilot.press("down")
        await pilot.pause()

        second = the_cursor_is_the_board_s_own(app, "epics", colour=triplet("green"), focused=True)

    assert first.startswith("Blocked epic"), first
    assert second.startswith("Ready epic"), second
