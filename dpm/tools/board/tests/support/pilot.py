"""Driving the TUI through Textual's ``run_test()`` pilot, and reading what it painted (ENV7).

Established here once, for every ``[feature]`` criterion in 48-04 and for 48-05 and 48-07 after it.

**Everything below reads the rendered strips, never a widget's own account of itself.** A pilot
harness makes "what the app thinks it rendered" the easiest thing to assert — the option list will
happily tell you how many options it holds and what style it was given — and every one of those
answers is the app agreeing with itself. ``Widget.render_lines()`` returns what was actually
painted, text and per-segment style together, which is the outside witness retro 48 asks for.

There is a second reason it has to be this way here: Textual 8 removed ``Static.renderable``, so a
preview panel has no attribute holding what it was handed. The convenient wrong thing is gone.
"""

from __future__ import annotations

from contextlib import asynccontextmanager
from time import monotonic

from rich.segment import Segment
from textual.command import CommandPalette
from textual.strip import Strip
from textual.widget import Widget
from textual.widgets import OptionList
from textual.widgets._footer import FooterKey

from board import BoardApp

#: Wide enough that a row's label is not truncated and tall enough for every fixture's rows —
#: a clipped row would read as a label that does not match, which is a test failing for the
#: terminal's reasons rather than the board's.
SIZE = (140, 44)


@asynccontextmanager
async def board(projects=(), *, size=SIZE, notifications=False, **injections):
    """A running board over ``projects``, settled and ready to drive.

    Yields the app and its pilot together: assertions want the app (to query what was painted) and
    keystrokes want the pilot, and every test here needs both.

    ``injections`` goes straight to :class:`BoardApp` — the preview reader (FR7), the project
    survey (NFR3), the registry callables and the picker's root (FR1). Passed through rather than
    enumerated, so a story that gives the app another one does not have to come back here; and
    every one of them is left out by tests about the layout, since each would otherwise make a test
    spawn a server or touch a registry it has no assertion about.

    ``notifications`` follows ``run_test``'s own default of off, because a toast is painted over the
    columns and would sit in the middle of every assertion about a row. A test whose criterion is
    what the board *told* the user turns it on and reads the toasts like any other widget.
    """
    app = BoardApp(list(projects), **injections)

    async with app.run_test(size=size, notifications=notifications) as pilot:
        await pilot.pause()

        yield app, pilot


async def show_everything(pilot) -> None:
    """Press `z`, so the board paints finished work alongside live work (FR19).

    A board opens hiding complete, superseded and withdrawn rows, which is right for the person
    looking at one and wrong for a test whose fixture is a row per state. Pressed rather than set,
    because the board's affordance is what a user has and a test reaching into the model would go
    on passing after the key stopped working.
    """
    await pilot.press("z")
    await pilot.pause()


def painted(widget: Widget) -> list[Strip]:
    """The lines a widget actually painted, cropped to the whole of its own box.

    **The crop is the widget's ``region``, not its ``scrollable_content_region``.** ``render_lines``
    numbers its lines from the widget's own origin — outside any padding — so a crop sized to the
    content and started at zero reads from the border inwards and falls one cell short at the right.
    On a row that fills the width that costs its last character, which reads as a label that does
    not match: `no-database` arrives as `no-databas`. The padding is whitespace, and stripping it
    is what the readers above already do.
    """
    return widget.render_lines(widget.region.reset_offset)


def strips(app: BoardApp, widget_id: str) -> list[Strip]:
    """The same, for a widget named by id, on whatever screen is in front.

    ``app.screen`` rather than ``app``, because a modal — the picker (FR1) — is a screen of its own
    and its widgets are not in the default screen's tree. Reading through the app would find the
    board behind the modal, which is not what a user is looking at.
    """
    return painted(app.screen.query_one(f"#{widget_id}", Widget))


def text_of(strips: list[Strip]) -> list[str]:
    """The non-blank text of some painted lines, in order."""
    return [strip.text.strip() for strip in strips if strip.text.strip()]


def lines(app: BoardApp, widget_id: str) -> list[str]:
    """The non-blank text a widget painted, in order — a column's rows, or a preview's body."""
    return text_of(strips(app, widget_id))


def _first_content(strip: Strip) -> Segment | None:
    """The segment carrying a row's own text, past the padding the layout paints first."""
    for segment in strip:
        if segment.text.strip():
            return segment

    return None


def styles(app: BoardApp, column: str) -> dict[str, str]:
    """Row text to the foreground colour it was painted in.

    **Foreground only, because the background is not the row's.** The highlighted row is painted on
    the cursor's background, so comparing whole styles would make one row differ from its
    neighbours for a reason that has nothing to do with the state it is in.
    """
    painted = {}

    for strip in strips(app, column):
        segment = _first_content(strip)

        if segment is not None and segment.style is not None:
            painted[segment.text.strip()] = str(segment.style.color)

    return painted


def preview(app: BoardApp, kind: str) -> list[str]:
    """What the preview panel beneath ``kind``'s column painted."""
    return lines(app, f"{kind}-preview-body")


def footer(app: BoardApp) -> dict[str, str]:
    """What the footer is documenting: each key it printed, by its binding name, to its label.

    Keyed by ``key`` rather than by ``key_display`` so a caller can compare it against a binding
    table without translating `left` into `←` on the way — the display form is the footer's own
    rendering of the same key, and asserting on it would make this a test of Textual.

    Read from the `FooterKey` widgets the footer actually built rather than from `BINDINGS`, which
    is the whole point of asking: a binding shadowed by one nearer the focused widget is bound,
    works, and prints nothing — Textual answers `left` with the option list's own scroll binding
    unless the column takes the key back. Comparing the table with itself would report a footer
    that never appeared.

    The command palette's own entry is left out. It is Textual's rather than the board's, added by
    the footer independently of `BINDINGS`, and a comparison against the board's map would have to
    special-case it at every call site instead of here.
    """
    return {
        entry.key: entry.description
        for entry in app.screen.query(FooterKey)
        if entry.description != "palette"
    }


def toasts(app: BoardApp) -> list[str]:
    """What the board's notifications painted, one string per toast, oldest first.

    Read from the rendered toasts rather than from the app's own record, the same rule everything
    else here follows: a notification the app noted and never painted told nobody anything. A toast
    wraps over several lines in a narrow terminal, so each one's lines are rejoined into a sentence.

    A test wanting these has to open its board with ``notifications=True`` — ``run_test`` suppresses
    them by default, because a toast is painted over the columns.
    """
    return [" ".join(text_of(painted(toast))) for toast in app.screen.query("Toast")]


def palette(app: BoardApp) -> list[str]:
    """What the command palette's list painted, in order. Empty when it is not open.

    Read from the rendered strips like everything else here, and **not** from the provider: asking
    ``BoardCommands`` what it yields would be asking the thing under test to grade itself, and the
    criterion is about what a user sees when the palette opens.
    """
    if not isinstance(app.screen, CommandPalette):
        return []

    return text_of(painted(app.screen.query_one(OptionList)))


async def until(pilot, condition, *, timeout: float = 10.0) -> bool:
    """Drive the app until ``condition()`` holds, or give up. Returns whether it held.

    Returned rather than asserted, so the test says what the timeout *meant* — for one test a
    condition that never arrives is a board that never finished reading, and for another it is the
    whole point.

    The loop is short pauses rather than one long sleep because the work being waited on lands
    through the message pump, and a sleep that does not yield to it waits for something that cannot
    happen.
    """
    deadline = monotonic() + timeout

    while monotonic() < deadline:
        if condition():
            return True

        await pilot.pause(0.02)

    return condition()
