"""Feature tests for the Ctrl+P command palette.

The palette must go straight to the board's own actions — shown the instant it
opens (via discover), not the generic system-command list — and fuzzy-filter the
same set as you type (via search).
"""

from __future__ import annotations

import pytest

from board import BoardApp, BoardCommands
from registry import RegistryEntry

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


PROJECT = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}


def board(repo, cache_root):
    return BoardApp(
        entries=[RegistryEntry(str(repo), "p")], cache_root=cache_root, watch_interval=None
    )


def test_palette_uses_the_board_commands_provider():
    # The default system-commands provider is replaced, so Ctrl+P surfaces the
    # board's actions rather than generic system commands.
    assert BoardApp.COMMANDS == {BoardCommands}


async def test_discover_shows_the_board_actions_immediately(make_project, cache_root):
    repo = make_project(PROJECT)
    async with board(repo, cache_root).run_test() as pilot:
        provider = BoardCommands(pilot.app.screen)
        names = [str(hit.display) async for hit in provider.discover()]

    # Every headline action is present the moment the palette opens.
    for expected in ("Launch", "Open project", "Ralph-select epic", "Add project", "Refresh", "Clear cache", "Quit"):
        assert expected in names


async def test_search_fuzzy_filters_the_actions(make_project, cache_root):
    repo = make_project(PROJECT)
    async with board(repo, cache_root).run_test() as pilot:
        provider = BoardCommands(pilot.app.screen)
        hits = [hit async for hit in provider.search("refr")]

    assert len(hits) == 1
    assert str(hits[0].match_display) == "Refresh"
    assert hits[0].score > 0


async def test_ctrl_p_opens_the_palette(make_project, cache_root):
    from textual.command import CommandPalette

    repo = make_project(PROJECT)
    async with board(repo, cache_root).run_test() as pilot:
        await pilot.press("ctrl+p")
        await pilot.pause()
        assert CommandPalette.is_open(pilot.app)
