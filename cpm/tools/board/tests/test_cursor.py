"""Feature tests for the soft, row-coloured cursor (InverseOptionList).

The cursor must (a) not be a fixed blue block, (b) carry the row's own status
colour, (c) stay legible — a full-saturation inverse turned bright rows (yellow)
into an unreadable glare, which is the regression these tests guard against — and
(d) remain visible, just fainter, when its column loses focus.
"""

from __future__ import annotations

import pytest
from textual.widgets import OptionList

from board import BoardApp, _luminance
from registry import RegistryEntry

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


# A single in-progress project → the projects cursor row is yellow, the colour
# that glared worst under a true inverse.
IN_PROGRESS = {
    "docs/epics/39-01-epic-foo.md": epic_md("In Progress", [(1, "Complete", "—"), (2, "Pending", "—")])
}


def _cursor_style(app, column):
    ol = app.query_one(f"#{column}", OptionList)
    strip = ol.render_line(0)  # row 0 is highlighted after the initial cascade
    seg = next(s for s in strip if s.text.strip())
    return seg.style


async def test_cursor_is_a_legible_muted_bar_not_a_glaring_inverse(make_project, cache_root):
    repo = make_project(IN_PROGRESS)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        app.query_one("#projects", OptionList).focus()
        await pilot.pause()
        style = _cursor_style(app, "projects")

        bg = style.bgcolor.get_truecolor()
        fg = style.color.get_truecolor()

        # Not the fixed blue block, and not the full-saturation row colour: the bar
        # is the yellow muted toward the background (its blue channel stays low, but
        # it is nowhere near pure #ffff00).
        assert bg != (255, 255, 0)  # not the raw status colour — muted
        assert max(bg) < 200  # toned down, no glare

        # Legible: a real luminance gap between text and bar.
        assert abs(_luminance(fg) - _luminance(bg)) > 80


async def test_blurred_cursor_is_fainter_but_still_visible(make_project, cache_root):
    repo = make_project(IN_PROGRESS)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        app.query_one("#projects", OptionList).focus()
        await pilot.pause()
        focused_bg = _cursor_style(app, "projects").bgcolor.get_truecolor()

        # Move focus away — the projects cursor must persist, just fainter.
        app.query_one("#epics", OptionList).focus()
        await pilot.pause()
        blurred_bg = _cursor_style(app, "projects").bgcolor.get_truecolor()

        assert blurred_bg != (18, 18, 18)  # the selection is still painted
        assert _luminance(blurred_bg) < _luminance(focused_bg)  # but dimmer than focused
