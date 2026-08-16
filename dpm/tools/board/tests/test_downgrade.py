"""Story 3 — the board on a terminal without truecolor (NFR1).

Everything stories 1 and 2 put on screen is a 24-bit colour: a cursor bar mixed from a row's own
colour and the background, a pill and a badge in colours of their own. A terminal that reports 256
colours does not refuse any of it — it *quantises* it, silently, to the nearest palette entry, and
two colours that were plainly different can arrive as the same one.

**Quantised the way a terminal quantises, not approximated here.** Rich's own `downgrade` is what
runs when the board writes to a 256-colour terminal, so the tests below put the painted colours
through it and read what comes out. The alternative — deciding here what "close enough" means — is a
second colour model that would agree with the terminal until the day it did not.

The failure this is written against is invisible on the machine it is developed on: a modern
terminal reports truecolor, so a bar that collapses into the background at 256 colours looks
perfect right up until somebody opens the board over ssh from something older.
"""

from __future__ import annotations

from collections import Counter
from pathlib import Path

from pilot import board, colours, painted, strips
from rich.color import Color as RichColour
from rich.color import ColorSystem
from rich.color_triplet import ColorTriplet
from rich.console import Console
from rich.segment import Segments

from board_view import BROKEN, LIVE, EpicView, ProjectView
from status_model import EPIC_STATES

#: How far apart two quantised colours have to be to count as telling one row from another. A
#: channel at a time rather than a luminance, because luminance weights red at a fifth and the
#: board's most important row — a blocked one — is red: `#5f0000` and `#121212` differ by 77 in the
#: channel that matters and by 2 in luminance, and only one of those numbers describes what a reader
#: sees.
APART = 24


def eight_bit(colour: ColorTriplet) -> tuple[int, ColorTriplet]:
    """``colour`` as a 256-colour terminal receives it: the palette entry, and what it paints."""
    number = RichColour.from_triplet(colour).downgrade(ColorSystem.EIGHT_BIT).number

    return number, RichColour.from_ansi(number).get_truecolor()


def apart(one: ColorTriplet, other: ColorTriplet) -> int:
    """How far two colours are from each other, as the widest single-channel difference."""
    return max(abs(one.red - other.red), abs(one.green - other.green), abs(one.blue - other.blue))


def every_state() -> list[ProjectView]:
    """One project per marker, and an epic per state the model has — the whole palette, on screen.

    Built from `EPIC_STATES` rather than from a list here, so a state added to the model arrives in
    this test as a row that has to survive the downgrade rather than as a row nobody rendered.
    """
    return [
        ProjectView(
            "first",
            Path("/first"),
            epics=tuple(EpicView(f"e{n}", f"{state} epic", state) for n, state in enumerate(EPIC_STATES)),
        ),
        ProjectView("second", Path("/second"), live=1, violations=1),
        ProjectView("third", Path("/third")),
    ]


async def test_the_cursor_survives_the_downgrade_on_every_state_the_model_has():
    """Criterion 1's first half [unit]. Every row, focused and blurred, at 256 colours.

    Both focus states, because they are two different blends and the blurred one is the fainter by
    design — it is the one with room to disappear. Every state rather than a sample, because which
    of them quantises into the background is a fact about that state's colour: dark green did, and
    nothing about the code said which of the seven it would be.
    """
    async with board(every_state()) as (app, pilot):
        await pilot.press("z")
        await pilot.pause()

        for column, focused in (("epics", False), ("epics", True), ("projects", False)):
            if focused:
                await pilot.press("right")
                await pilot.pause()

            rows = colours(app, column)
            surface = quantised_surface(rows)
            bars = [
                (text, eight_bit(background)[1])
                for text, (_, background) in rows.items()
                if eight_bit(background)[1] != surface
            ]

            assert bars, f"no row in {column} is painted off the surface at 256 colours: {rows}"

            for text, bar in bars:
                assert apart(bar, surface) >= APART, (
                    f"the cursor on {text!r} quantises to {bar}, which a 256-colour terminal paints "
                    f"{apart(bar, surface)} from the surface {surface} — the highlight is on screen "
                    "in 24-bit colour and gone on an older one"
                )


def quantised_surface(rows: dict) -> ColorTriplet:
    """What the unhighlighted rows' background becomes at 256 colours — the commonest of them."""
    counted = Counter(eight_bit(background)[1] for _, background in rows.values())

    return counted.most_common(1)[0][0]


async def test_the_pill_and_the_badge_stay_off_the_row_s_own_colour_at_256():
    """Criterion 1's second half [unit]. The markers keep their meaning after quantisation.

    A pill that quantises onto the row's own colour is a pill that has stopped saying anything: it
    is the same shape as the rest of the row's text and, at that point, the same colour.

    The markers are on the *second* project in the fixture, which is why: the cursor opens on the
    first, and a highlighted row is deliberately one bar in one colour — asking this question there
    would be asking it of the cursor rather than of the markers.
    """
    async with board(every_state()) as (app, _):
        marked = next(strip for strip in strips(app, "projects") if LIVE in strip.text)
        segments = {
            segment.text.strip(): segment.style.color.get_truecolor()
            for segment in marked
            if segment.text.strip() and segment.style is not None and segment.style.color
        }

    summary = next(colour for text, colour in segments.items() if text.startswith("second"))
    pill = next(colour for text, colour in segments.items() if LIVE in text)
    badge = next(colour for text, colour in segments.items() if BROKEN in text)

    for name, colour in (("pill", pill), ("badge", badge)):
        assert apart(eight_bit(colour)[1], eight_bit(summary)[1]) >= APART, (
            f"the {name} quantises onto the row's own colour at 256 colours: "
            f"{eight_bit(colour)} against {eight_bit(summary)}"
        )

    assert apart(eight_bit(pill)[1], eight_bit(badge)[1]) >= APART, (
        f"the pill and the badge quantise together: {eight_bit(pill)} and {eight_bit(badge)}"
    )


async def test_the_board_renders_to_a_256_colour_console_in_colour():
    """Criterion 2 [unit]. Every painted strip, written to a console that reports 256 colours.

    Two halves, and the second is the one worth having. A render that raised nothing and emitted no
    colour at all would satisfy "renders without error" perfectly — and monochrome is exactly what a
    board falls back to when its colours cannot be expressed, so the absence of an exception says
    nothing about whether anything survived. The assertion is that 8-bit colour codes are in the
    output and 24-bit ones are not.
    """
    async with board(every_state()) as (app, pilot):
        await pilot.press("z")
        await pilot.pause()

        console = Console(color_system="256", force_terminal=True, width=200)

        with console.capture() as captured:
            for column in ("projects", "epics", "stories"):
                for strip in painted(app.screen.query_one(f"#{column}")):
                    console.print(Segments(list(strip)), end="")

    written = captured.get()

    assert "\x1b[38;5;" in written or "\x1b[48;5;" in written, (
        "the board rendered to a 256-colour console without a single colour code — a monochrome "
        f"board is what a failed downgrade looks like: {written[:200]!r}"
    )
    assert "\x1b[38;2;" not in written and "\x1b[48;2;" not in written, (
        "24-bit colour codes reached a console that reports 256 colours, so the terminal is being "
        "sent colours it cannot render"
    )
