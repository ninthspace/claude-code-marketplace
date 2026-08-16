"""Story 5 — the Epics column says what its colours mean (FR8, FR19).

The board's whole state model is carried by colour, and until this story neither column said what
any of it meant. The CPM board's Epics title is a legend; this one's was the word "Epics". That is
the one difference the surface sweep closed by writing code rather than by recording a reason.

**Derived from the palette, which is what the test is for.** A legend written out as a string is
one that explains six of seven colours the day a state is added — and the state that goes
unexplained is the new one, which is the one nobody recognises.
"""

from __future__ import annotations

from pathlib import Path

from pilot import board, painted
from textual.widgets import Label

from board import legend
from board_view import STATE_STYLE, ProjectView


def test_the_legend_names_every_state_the_model_has():
    """Every state, in the colour that state's rows are painted in.

    Both halves matter and neither implies the other: a legend listing the states in one colour
    explains nothing, and a legend of the right colours missing a state explains the wrong things.
    """
    printed = legend()

    for state, style in STATE_STYLE.items():
        assert f"[{style}]{state.replace('_', ' ')}[/]" in printed, (
            f"{state} is painted {style} on the board and is not in the legend under that colour: "
            f"{printed}"
        )

    assert printed.startswith("Epics"), f"the column lost its name to its legend: {printed}"


def test_a_state_the_model_gains_arrives_in_the_legend(monkeypatch):
    """The property the derivation buys, driven by adding a state to the palette.

    A legend built from the table cannot fall behind it; one written out as a string can, and looks
    exactly the same until the day it does.
    """
    monkeypatch.setitem(STATE_STYLE, "abandoned", "cyan")
    monkeypatch.setattr("board.EPIC_STATES", (*STATE_STYLE,))

    assert "[cyan]abandoned[/]" in legend(), legend()


async def test_the_column_paints_the_legend_rather_than_its_markup():
    """On the board rather than in the function, and read from what the title painted.

    The legend is markup, so the failure worth catching is it arriving on screen as `[red]blocked`
    — a title that says what the colours mean by printing their names as text.
    """
    async with board([ProjectView("fixture", Path("/fixture"))], size=(200, 40)) as (app, _):
        title = app.screen.query_one("#col-epics").query_one(Label)
        printed = " ".join(strip.text for strip in painted(title))

    for state in STATE_STYLE:
        assert state.replace("_", " ") in printed, f"{state} is not in the painted title: {printed}"

    for style in set(STATE_STYLE.values()):
        assert f"[{style}]" not in printed, f"the title printed its own markup: {printed}"
