"""Story 4 — a preview it cannot render does not take the board down (FR6).

A preview is the one place this board renders text it did not compose: the markdown comes from
whatever wrote the rows, and the board's job is to show it whatever shape it is in. So the raster
falls back to the source itself when the render raises, and the panel shows unrendered markdown
rather than the board showing a traceback.

**What the pathological inputs actually establish.** None of them makes the renderer raise — Rich
and markdown-it treat malformed markdown as text, which is the right answer and leaves the criterion
below asserting that the *output* is sane rather than that a crash was caught. The guard's own
control is separate, and drives the failure through a renderer that raises.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from pilot import board, preview

import board as board_module
from board import markdown_content
from board_view import EpicView, ProjectView

#: Sources that have no business rendering cleanly, each named for what is wrong with it. Two of the
#: three shapes the criterion lists are here several times over, because "pathologically nested" has
#: more than one nesting to be pathological about.
PATHOLOGICAL = {
    "twenty thousand nested blockquotes": ">" * 20_000 + " deep\n",
    "two thousand nested list levels": "\n".join("  " * n + "- item" for n in range(2_000)),
    "an unclosed code fence": "```python\nprint('x')\n",
    "one line of a hundred thousand characters": "word " * 20_000,
    "five thousand unbalanced brackets": "[" * 5_000 + "x" + "]" * 5_000,
    "a ragged table": "| a | b |\n| --- |\n| 1 | 2 | 3 |\n",
    "a fence naming a lexer that does not exist": "```notalanguage\nx = 1\n```\n",
    "a fence full of NUL bytes": "```\n\x00\x01\x02\n```\n",
    "ANSI escapes in the text": "a\x07b\x1b[31mred\x1b[0m\n",
    "an unpaired surrogate": "text \ud800 more",
    "nothing at all": "",
    "five thousand horizontal rules": "---\n" * 5_000,
}


@pytest.mark.parametrize("name", sorted(PATHOLOGICAL))
def test_a_source_the_board_did_not_compose_still_renders(name):
    """Criterion 1 [unit]. Each pathological source, through the raster the panel uses.

    The assertion is that something renderable comes back, not that it looks like anything: a
    source with no content in it — twenty thousand blockquote markers and a word — is *entitled* to
    render as nothing, and demanding text from it would be demanding the renderer invent some.
    """
    content = markdown_content(PATHOLOGICAL[name], 80)

    assert content is not None, f"{name} rendered nothing at all"
    assert isinstance(content.plain, str), f"{name} rendered something unpaintable: {content!r}"


def one_epic() -> list[ProjectView]:
    return [ProjectView("fixture", Path("/fixture"), epics=(EpicView("e1", "An epic", "ready"),))]


def previewed(source: str):
    async def read(root: Path, row) -> str:
        return source

    return read


@pytest.mark.parametrize(
    "name",
    ["an unclosed code fence", "two thousand nested list levels", "a ragged table"],
    ids=["unclosed fence", "nested lists", "ragged table"],
)
async def test_the_board_survives_previewing_one(name):
    """Criterion 1's other half [feature]: the board, not the function.

    A raster that returned something and a board that fell over painting it would satisfy the test
    above. Three of the sources rather than all twelve, because what is being checked here is the
    path from panel to screen and each one costs a running app.
    """
    async with board(one_epic(), size=(120, 40), reader=previewed(PATHOLOGICAL[name])) as (
        app,
        pilot,
    ):
        await pilot.pause()
        await pilot.press("right", "down", "up")
        await pilot.pause()

        assert app.is_running, f"the board stopped while previewing {name}"

        preview(app, "epic")


def a_renderer_that_raises(monkeypatch) -> None:
    """Make the render itself fail, which no input the board can be given does.

    The guard is around a call, so the control has to make that call raise; every source in
    :data:`PATHOLOGICAL` renders. What this leaves is a real demonstration that the guard is
    load-bearing, and no demonstration that any particular input is dangerous — which is what the
    criterion says.
    """

    def broken(markup: str, width: int):
        raise RuntimeError("the renderer fell over")

    monkeypatch.setattr(board_module, "_rasterised", broken)


async def test_a_render_that_raises_leaves_the_source_on_screen(monkeypatch):
    """Criterion 1, through the failure the guard is actually for.

    Both the call and the board: the text survives the render failing, and a board previewing a row
    whose every render raises is still running afterwards with that text in the panel.
    """
    a_renderer_that_raises(monkeypatch)

    content = markdown_content("# A heading\n\nAnd a paragraph.", 80)

    assert "A heading" in content.plain, (
        f"a render that raised lost the text as well as the formatting: {content.plain!r}"
    )

    async with board(one_epic(), size=(120, 40), reader=previewed("# A heading")) as (app, pilot):
        await pilot.press("right")
        await pilot.pause()
        await pilot.pause()

        assert app.is_running, "the board stopped when a render raised"
        assert "A heading" in " ".join(preview(app, "epic")), preview(app, "epic")


def test_without_the_guard_the_same_render_takes_the_board_down(monkeypatch):
    """Criterion 2, the control. The same call, made the way it would be made without the guard.

    The guard is a `try` around one expression, so removing it is calling that expression — and the
    pair is the demonstration: guarded, the call comes back with the source; unguarded, the
    renderer's own exception escapes towards whoever asked for the preview, which on the resize path
    is the message pump.

    Read as well as raised, because a control that accepted any exception would be satisfied by a
    test that broke something else on the way.
    """
    a_renderer_that_raises(monkeypatch)

    assert markdown_content("# A heading", 80) is not None, "the guarded call did not come back"

    with pytest.raises(RuntimeError) as raised:
        board_module._rasterised("# A heading", 80)

    assert "fell over" in str(raised.value), (
        f"something other than the render failed, so the control shows nothing: {raised.value}"
    )
