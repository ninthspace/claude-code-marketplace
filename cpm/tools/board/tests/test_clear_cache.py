"""Feature test for the in-app clear-cache action (`R`)."""

from __future__ import annotations

import pytest
from textual.widgets import OptionList

import cache as cache_mod
from board import BoardApp
from registry import RegistryEntry

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}


async def test_clear_cache_key_wipes_and_rebuilds(make_project, cache_root, monkeypatch):
    repo = make_project(EPICS_READY)
    calls = {"n": 0}
    real_clear = cache_mod.clear_cache

    def spy(**kwargs):
        calls["n"] += 1
        return real_clear(**kwargs)

    monkeypatch.setattr(cache_mod, "clear_cache", spy)

    app = BoardApp(entries=[RegistryEntry(str(repo), "P")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        await pilot.press("R")
        await pilot.pause()
        assert calls["n"] == 1  # the cache directory was wiped
        assert app.query_one("#projects", OptionList).option_count == 1  # and rebuilt
