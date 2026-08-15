"""Story 3 — the browser opens before anything has been read (NFR3).

Driven by a **slow stand-in server**, not by a hook in the board. `RECORDING_DELAY` makes the
handshake take a measurable amount of time, which is the condition NFR3 is about and one the board
cannot tell from a genuinely slow machine. A seam added so a test could stall a read would be
production code with no production caller.

What makes these assertions falsifiable is the `reading…` row: it exists *only* between the app
opening and that project's read coming back. A board that surveyed first would paint its first row
with the progress already in it, and every test here would fail on the row it found rather than on
a clock.

Timing is asserted as a bound far from both alternatives — an order of magnitude below the delay
for "did not wait", and well under the serial total for "read concurrently" — so a loaded machine
moves the number without crossing the line.
"""

from __future__ import annotations

from pathlib import Path
from time import monotonic

from conftest import stand_in_pool
from pilot import board, lines, styles, until
from recording_server import transcript_of

from board import registry_views, survey_project
from board_view import READING

#: How long each stand-in takes to answer its handshake. Long enough that a survey done before the
#: app opened could not be mistaken for a fast one, short enough to pay for on every run.
DELAY = "1.0"

#: Registered projects for the ten-project criterion. Twelve, not ten: "over ten" is the
#: requirement's own wording and a fixture of exactly ten satisfies it only at the boundary.
MANY = 12


class Entry:
    """A registry entry, as :func:`registry_views` reads one.

    Built here rather than through `add_project` because the registry file is not what these tests
    are about, and a project registered through the real path would still have to be given a name.
    """

    def __init__(self, path: Path, label: str) -> None:
        self.path = str(path)
        self.label = label

    def exists(self) -> bool:
        return Path(self.path).is_dir()


def slow_projects(project, monkeypatch, count: int) -> list:
    """``count`` registered projects whose servers each take :data:`DELAY` to say hello.

    The delay is set in this process's environment because the pool builds its children's
    environment itself — that assembly is the thing other stories test, and handing the pool one
    here would exercise a path the board never takes.
    """
    monkeypatch.setenv("RECORDING_DELAY", DELAY)

    return [Entry(project(f"project-{index}"), f"project-{index}") for index in range(count)]


def reading(app) -> list[str]:
    """The rows currently saying they are still being read."""
    return [row for row in lines(app, "projects") if READING in row]


async def test_the_projects_column_renders_before_any_handshake_completes(
    transcript, project, monkeypatch
):
    """NFR3's first criterion, with three witnesses that do not stand in for each other.

    ``reading…`` is a state the row can only be in *before* its server has answered. The transcript
    says the same thing without reference to any label: the stand-in writes down every line it
    receives, and a `tools/call` cannot arrive until the handshake it follows has completed, so an
    empty call log at first paint is the handshake still being outstanding. The clock is the third:
    the paint did not merely happen first, it happened without waiting.
    """
    entries = slow_projects(project, monkeypatch, 1)
    started = monotonic()

    async with stand_in_pool() as pool:
        async with board(
            registry_views(entries),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
        ) as (app, pilot):
            painted = monotonic() - started
            rows = lines(app, "projects")
            waiting = reading(app)
            calls = [m for m in transcript_of(transcript) if m.get("method") == "tools/call"]

            # And it does finish: without this the assertions above pass against a board that
            # renders `reading…` and never reads anything at all.
            filled = await until(pilot, lambda: not reading(app))

    assert rows, "the Projects column is empty while its one project is being read"
    assert waiting == rows, f"a row was painted as read before its server answered: {rows}"
    assert calls == [], f"a server had already been called when the column was painted: {calls}"
    assert painted < float(DELAY) / 2, (
        f"the first paint took {painted:.2f}s against a {DELAY}s handshake — it waited for it"
    )
    assert filled, "the row never stopped saying it was being read"


async def test_the_pending_row_is_distinguishable_from_a_project_with_no_epics(
    transcript, project, monkeypatch
):
    """The pending row says something, and says it in its own style.

    A project the board has read and found empty renders its progress as `—`. If a pending row
    rendered the same, a board still working would be indistinguishable from a board reporting an
    empty project — which is the whole content of this criterion.
    """
    entries = slow_projects(project, monkeypatch, 1)

    async with stand_in_pool() as pool:
        async with board(
            registry_views(entries),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
        ) as (app, pilot):
            waiting = reading(app)
            pending_style = styles(app, "projects")

            await until(pilot, lambda: not reading(app))

            settled = lines(app, "projects")
            settled_style = styles(app, "projects")

    assert waiting, "nothing said it was being read"
    assert settled and not any(READING in row for row in settled), (
        f"the row still says it is being read after the read finished: {settled}"
    )
    assert pending_style != settled_style, (
        f"a pending row renders in the same style as a read one: {pending_style}"
    )


async def test_over_ten_projects_all_render_without_waiting_on_any_server(
    transcript, project, monkeypatch
):
    """NFR3's second criterion, and the one a single survey worker still fails.

    Every row is present and pending before any server has answered, and they *all* finish in
    roughly one handshake rather than twelve. The second half is what separates a worker per
    project from one worker walking the list: both keep the UI thread free, and only one of them
    stops the twelfth project waiting on the first eleven.
    """
    entries = slow_projects(project, monkeypatch, MANY)
    started = monotonic()

    async with stand_in_pool() as pool:
        async with board(
            registry_views(entries),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
        ) as (app, pilot):
            painted = monotonic() - started
            rows = lines(app, "projects")
            waiting = reading(app)

            filled = await until(pilot, lambda: not reading(app))
            elapsed = monotonic() - started

    assert len(rows) == MANY, f"{MANY} projects were registered and {len(rows)} rows were painted"
    assert len(waiting) == MANY, f"a row was painted as read before its server answered: {rows}"
    assert painted < float(DELAY) / 2, (
        f"the first paint took {painted:.2f}s against a {DELAY}s handshake — it waited for one"
    )
    assert filled, "some rows never stopped saying they were being read"
    assert elapsed < float(DELAY) * (MANY / 2), (
        f"{MANY} projects took {elapsed:.2f}s against a {DELAY}s handshake each — they were read "
        f"one after another"
    )


async def test_the_ui_answers_keystrokes_while_reads_are_in_flight(
    transcript, project, monkeypatch
):
    """must NOT block the UI thread on a server spawn or a tool call.

    The bound alone would pass against a board that painted early and then froze, so this drives it
    instead: the cursor is moved *while* every server is still mid-handshake, and where it ends up
    is read from the rendered column. A blocked UI thread cannot process the key at all.
    """
    entries = slow_projects(project, monkeypatch, MANY)

    async with stand_in_pool() as pool:
        async with board(
            registry_views(entries),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
        ) as (app, pilot):
            assert reading(app) == lines(app, "projects"), "the reads had already finished"

            started = monotonic()
            await pilot.press("down", "down")
            await pilot.press("right")
            answered = monotonic() - started

            moved = app.selection.project
            focused = app.focused.id
            still_reading = bool(reading(app))

            await until(pilot, lambda: not reading(app))

    assert moved == 2, f"two ↓ while reads were in flight moved the cursor to {moved}"
    assert focused == "epics", f"→ while reads were in flight left focus on {focused}"
    assert still_reading, "the reads finished first, so nothing was asserted about a blocked thread"
    assert answered < float(DELAY) / 2, (
        f"three keystrokes took {answered:.2f}s against a {DELAY}s handshake — the thread was held"
    )
