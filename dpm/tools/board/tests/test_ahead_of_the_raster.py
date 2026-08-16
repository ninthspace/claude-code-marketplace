"""Story 3 — the cursor stays ahead of the raster (FR6, NFR2).

Two failures, and neither is visible on a board driven one keystroke at a time. A preview is read
and then rendered, and both take time: a user holding ↓ moves through rows whose reads are still in
flight, and what a naive panel shows when they stop is whichever read finished last. The render
itself is arithmetic rather than I/O, so awaiting it on the event loop puts every queued keystroke
behind it.

**Driven by a slow reader, not by a hook in the board.** The delay is on the stand-in that answers
for a row, which is the condition the criterion is about and one the board cannot tell from a slow
server. A seam added so a test could stall a render would be production code with no production
caller.
"""

from __future__ import annotations

import asyncio
from pathlib import Path
from time import perf_counter

from conftest import stand_in_pool  # noqa: F401 — imported for its fixtures
from pilot import board, preview, until

from board import markdown_content, read_document_preview
from board_view import EpicView, ProjectView
from mcp_client import ServerPool
from status_model import EPICS, rows

#: How long the first row's read takes. Long enough that a cursor moved straight after it is
#: unmistakably somewhere else by the time it lands, short enough to pay for on every run.
SLOW = 0.6

#: The width the timing criterion names, and an ordinary terminal's.
WIDTH = 80

#: The ceiling the timing criterion names, in seconds.
BUDGET = 0.050

#: How many copies of the fixture's largest document make a realistically sized one. Forty of them
#: is a few hundred lines — the size of a spec or an epic doc, which is what a board previews.
REPEATS = 40


def two_epics() -> list[ProjectView]:
    """A project with two epics, so the cursor has somewhere to move to."""
    return [
        ProjectView(
            "fixture",
            Path("/fixture"),
            epics=(
                EpicView("e1", "First epic", "ready"),
                EpicView("e2", "Second epic", "ready"),
            ),
        )
    ]


def slow_first():
    """A reader that takes :data:`SLOW` over the first epic and answers the second at once.

    The order is what makes the test say something: the read the cursor left is the one that comes
    back last, so "paint whatever arrived most recently" and "paint the highlighted row" disagree.
    """

    async def read(root: Path, row) -> str:
        if row.id == "e1":
            await asyncio.sleep(SLOW)

            return "# The first epic's own preview"

        return "# The second epic's own preview"

    return read


async def test_a_read_the_cursor_has_left_is_not_painted():
    """Criterion 1 [feature]. The cursor moves while the first row's read is in flight.

    Both halves are asserted. That the second row's preview is up says the panel followed the
    cursor; that the first row's never appears says the late arrival was discarded rather than
    painted and then overwritten — a board that painted it would show the wrong preview for as long
    as it took the next read to land, which is exactly the flicker this is about.
    """
    async with board(two_epics(), size=(120, 40), reader=slow_first()) as (app, pilot):
        await pilot.press("right")
        await pilot.press("down")

        arrived = await until(
            pilot, lambda: "second epic's own preview" in " ".join(preview(app, "epic")).lower()
        )

        assert arrived, "the second row's preview never arrived, so nothing below says anything"

        # Long enough for the abandoned read to have come back, so its absence is a decision.
        await asyncio.sleep(SLOW)
        await pilot.pause()

        painted = " ".join(preview(app, "epic")).lower()

    assert "second epic" in painted, painted
    assert "first epic's own preview" not in painted, (
        f"the read for the row the cursor left was painted over the row it is on: {painted}"
    )


async def test_the_second_row_is_previewed_before_the_first_read_returns():
    """Criterion 1's other half: the cursor is not waiting on the panel.

    Timed against the read the cursor left rather than against a number of its own. A board that
    awaited each read on the key path could not show the second row's preview until the first row's
    read had finished, so the second preview arriving inside :data:`SLOW` is the whole claim — and
    it is a claim about this board's own reader, not about how fast the machine is.
    """
    async with board(two_epics(), size=(120, 40), reader=slow_first()) as (app, pilot):
        started = perf_counter()

        await pilot.press("right")
        await pilot.press("down")

        arrived = await until(
            pilot, lambda: "second epic's own preview" in " ".join(preview(app, "epic")).lower()
        )

        elapsed = perf_counter() - started

    assert arrived, "the second row's preview never arrived"
    assert elapsed < SLOW, (
        f"the second row's preview took {elapsed:.3f}s to appear, which is longer than the read "
        f"for the row the cursor left ({SLOW}s) — so the two are being done one after the other"
    )


async def largest_preview(root: Path) -> str:
    """The longest preview source the fixture project can produce, through the real read path."""
    async with ServerPool() as pool:
        sources = [
            await read_document_preview(pool, root, EpicView(row["id"], row["title"], "pending"))
            for row in await rows(pool, root, EPICS)
        ]

    return max(sources, key=len)


async def test_the_largest_document_renders_inside_the_budget(fixture_project):
    """Criterion 2 [unit]. The fixture's largest document, at 80 columns, under 50 ms.

    Timed over the render alone rather than over a board, because what the criterion bounds is the
    raster: a measurement through the app would include a read, a repaint and the message pump, and
    a regression in the render would hide inside them.

    **The fastest of several runs**, which is the honest statistic for a ceiling on work the machine
    does: a slow sample says the machine was busy, and the question is whether this render can be
    done in the budget on a machine that is not.

    **Two documents, because the fixture's largest is around 130 characters.** That is the document
    the criterion names and it renders in well under a millisecond, so a budget met by it alone
    says nothing about a board previewing a real spec. The second is that document repeated until
    it is the size of one — a few hundred lines with every construct in it — and it is the one that
    can fail. The fixture is small by design (it is read by every test in the suite), so this is
    recorded as the criterion's shortfall rather than fixed by enlarging it.
    """
    smallest = await largest_preview(fixture_project)
    realistic = "\n\n".join([smallest] * REPEATS)

    for name, source in (("the fixture's largest", smallest), ("a document-sized source", realistic)):
        times = []

        for _ in range(5):
            started = perf_counter()
            markdown_content(source, WIDTH)
            times.append(perf_counter() - started)

        assert min(times) < BUDGET, (
            f"{name} ({len(source)} characters) took {min(times) * 1000:.1f} ms to render at "
            f"{WIDTH} columns, over the {BUDGET * 1000:.0f} ms the criterion allows — a preview "
            "this slow is one a held arrow key outruns"
        )
