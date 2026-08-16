"""Story 2 — the preview panel renders markdown (FR6, NFR3, ENVX4).

The panel used to be handed a string, so a heading arrived as `## Heading` and a list as a run of
lines beginning with a dash. It is handed a rasterised `Content` now: the markdown rendered to
styled segments at the panel's own width and rebuilt as text, which is what keeps the preview
selectable — Textual maps a selection over `Text` and `Content` and not over a live `Markdown`.

**Read from what was painted, not from what was asked for.** The width criteria in particular are
about a raster, and a raster is only observable as characters landing in different places; a test
asserting that a width was *passed* would pass against a renderer that ignored it.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from pilot import board, lines, preview, strips
from rich.console import Console
from rich.segment import Segments
from textual.content import Content
from textual.selection import Selection
from textual.widgets import Markdown, Static

from board import markdown_content
from board_view import EpicView, ProjectView

#: One source carrying each construct the criterion names, so a single render answers for all four.
#: The emphasis is inside a paragraph rather than alone on a line: `**alone**` is a paragraph Rich
#: would style either way, and what the rejection is about is the markers coming through as text.
SOURCE = """# The eighth epic

A paragraph with **emphasis** in the middle of it, long enough that the width it is laid out at
decides where its lines break rather than the sentence ending first.

## What it delivers

- the first item
- the second item

| approach | count |
| --- | --- |
| unit | 3 |
"""

#: The markers that must not survive for a construct that rendered. Held as a table because the
#: rejection and the control run over the same list.
MARKERS = ("# ", "## ", "- ", "**", "| ")


def rendered(width: int = 60) -> str:
    """:data:`SOURCE` rasterised at ``width``, as the characters a reader would see."""
    return markdown_content(SOURCE, width).plain


def test_each_construct_renders_as_itself_rather_than_as_its_source():
    """Criterion 1 [unit]. A heading, emphasis, a list and a table, in one render.

    The list is checked by its bullet and the table by its rule, because those are what Rich draws
    in place of the source characters — a check for the *text* of a list item would pass on a
    renderer that emitted the markdown untouched.
    """
    text = rendered()

    assert "The eighth epic" in text, text
    assert "What it delivers" in text, text
    assert "• the first item" in text, f"the list did not render as a list: {text}"
    assert "─" in text, f"the table did not render as a table: {text}"
    assert "emphasis" in text, text


def test_the_constructs_carry_the_styles_rich_drew_them_with():
    """Criterion 1's other half: styled, not merely re-punctuated.

    Text with every marker stripped and no styling is what a naive `re.sub` produces, and it
    satisfies every assertion above. What says the markdown was *rendered* is that the heading and
    the emphasis arrive in styles the surrounding paragraph does not have.
    """
    content = markdown_content(SOURCE, 60)
    styled = {content.plain[span.start : span.end].strip(): span.style for span in content.spans}

    heading = next(style for text, style in styled.items() if "The eighth epic" in text)
    emphasis = next(style for text, style in styled.items() if text == "emphasis")

    assert getattr(heading, "bold", None), f"the heading is not styled: {heading}"
    assert getattr(emphasis, "bold", None), f"the emphasis is not styled: {emphasis}"


def test_the_same_source_breaks_differently_at_two_widths():
    """Criterion 2 [unit]. The panel's width is what the paragraph is laid out at.

    Line *breaks* rather than line count, because a renderer using a fixed width would still produce
    a different number of lines if it happened to truncate — and the paragraph is deliberately long
    enough that a wrap has to happen at both.
    """
    narrow, wide = rendered(30).splitlines(), rendered(70).splitlines()

    assert narrow != wide, "the raster laid the same source out identically at 30 and at 70"
    assert max(len(line) for line in narrow) <= 30, narrow
    assert max(len(line) for line in wide) > 30, wide


def previewed(source: str):
    """A reader that answers with ``source`` for whichever row is highlighted."""

    async def read(root: Path, row) -> str:
        return source

    return read


def one_epic() -> list[ProjectView]:
    """A project with a single epic, so the epic panel has something to preview."""
    return [
        ProjectView(
            "fixture",
            Path("/fixture"),
            epics=(EpicView("e1", "The eighth epic", "ready"),),
        )
    ]


async def test_resizing_the_panel_renders_the_preview_again():
    """Criterion 3 [feature]. The terminal is resized and the panel is read a second time.

    The raster is width-specific, so a board that rendered once and kept the `Content` would show a
    preview laid out for a window that is no longer there. **The heading is what says which
    happened**, and the two readings are not interchangeable: a `Content` wraps itself to whatever
    panel it is in, so a paragraph re-flows either way and "the text changed" is satisfied by a
    board that re-rendered nothing. A heading is *centred at the width it was rastered at*, so a
    stale one arrives with the old width's padding still on it and wraps onto a second line.
    """
    async with board(one_epic(), size=(200, 40), reader=previewed(SOURCE)) as (app, pilot):
        await pilot.pause()

        wide = preview(app, "epic")

        await pilot.resize_terminal(140, 40)
        await pilot.pause()
        await pilot.pause()

        narrow = preview(app, "epic")

    assert wide and narrow, "the panel painted nothing, so neither reading says anything"
    assert wide != narrow, f"the preview did not re-render at the new width: {wide}"
    assert "The eighth epic" in narrow, (
        "the heading arrived wrapped, so what is on screen is the raster from before the resize "
        f"with its old centring still on it: {narrow[:3]}"
    )


async def test_the_panel_holds_styled_text_rather_than_a_markdown_widget():
    """Criterion 4 [unit]. What makes the rendered preview selectable.

    Asked of the selection itself rather than of the type, because that is the behaviour the
    criterion is about: `Widget.get_selection` extracts text when what it renders is `Text` or
    `Content` and returns `None` for anything else, which is exactly what a live `Markdown` widget
    is. A panel built that way looks identical and cannot have a line copied out of it.
    """
    async with board(one_epic(), reader=previewed(SOURCE)) as (app, pilot):
        await pilot.pause()

        body = app.screen.query_one("#epic-preview-body", Static)
        selected = body.get_selection(Selection(None, None))

        assert isinstance(body.content, Content), f"the panel holds {type(body.content)}"
        assert not app.screen.query(Markdown), "the board mounted a live markdown widget"
        assert selected is not None, "nothing can be selected out of the panel"
        assert "The eighth epic" in selected[0], (
            f"the selection did not come back with the preview's own text: {selected}"
        )


def no_marker_survives(text: str) -> None:
    """Assert no markdown marker is in ``text``, for a construct that was rendered.

    Shared by the rejection and its control, so what the control demonstrates is this assertion
    failing rather than a weaker copy of it.
    """
    for marker in MARKERS:
        assert marker not in text, (
            f"{marker!r} survived into the rendered preview, so the construct it introduces was "
            f"painted as its own source: {text!r}"
        )


async def test_no_markdown_marker_reaches_the_painted_panel():
    """Criterion 5, the must-NOT [unit]. Read from the panel's own strips, not from the raster.

    Through the app rather than the function, because the rejection is about what a *reader* sees:
    a raster that stripped every marker and a panel that then painted the source instead would
    satisfy a check made one call earlier.
    """
    async with board(one_epic(), size=(120, 40), reader=previewed(SOURCE)) as (app, pilot):
        await pilot.pause()

        painted = "\n".join(preview(app, "epic"))

    assert "The eighth epic" in painted, f"the panel painted no preview to check: {painted!r}"

    no_marker_survives(painted)


def test_the_unrasterised_source_is_what_the_rejection_catches():
    """The control for criterion 5, and it is what the panel was handed before this story.

    The rejection is an absence, and an absence is satisfied by a panel that paints nothing at all.
    So the same assertion is run against the string the panel used to be given, and what it says is
    read rather than merely that it raised.
    """
    with pytest.raises(AssertionError) as raised:
        no_marker_survives(SOURCE)

    assert "'# '" in str(raised.value), f"the failure did not name the marker it found: {raised.value}"


async def test_a_rendered_preview_reaches_a_256_colour_terminal_in_colour():
    """The colour-system criterion [unit]. The raster's output, written to an older terminal.

    The raster names no colour system, so what a preview's styles become is decided where the
    terminal actually is. Both halves are needed: 8-bit codes present says colour survived, and
    24-bit codes absent says nothing was written that this terminal cannot render — a raster that
    baked in truecolor would be legible here and wrong over ssh.
    """
    async with board(one_epic(), size=(120, 40), reader=previewed(SOURCE)) as (app, pilot):
        await pilot.pause()

        console = Console(color_system="256", force_terminal=True, width=200)

        with console.capture() as captured:
            for strip in strips(app, "epic-preview-body"):
                console.print(Segments(list(strip)), end="")

        assert lines(app, "epic-preview-body"), "the panel painted nothing to write out"

    written = captured.get()

    assert "\x1b[38;5;" in written or "\x1b[48;5;" in written, (
        f"the preview reached a 256-colour terminal with no colour at all: {written[:200]!r}"
    )
    assert "\x1b[38;2;" not in written and "\x1b[48;2;" not in written, (
        "24-bit colour codes reached a console that reports 256 colours, so the preview is being "
        "sent colours the terminal cannot render"
    )
