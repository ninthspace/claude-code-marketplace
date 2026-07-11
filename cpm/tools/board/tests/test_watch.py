"""Feature tests for manual refresh (Story 3).

The watch-mode *feel* (flicker-free live updates on an interval) is a `[manual]`
criterion — visual judgement automation can't confirm — so it is not tested here.
The manual-refresh keypress IS automatable: it must force a full re-derive that
bypasses the freshness cache.
"""

from __future__ import annotations

import subprocess

import pytest
from textual.widgets import OptionList

import cache as cache_mod
from board import BoardApp
from registry import RegistryEntry

from test_derivation import epic_md


def project_state(app) -> str:
    prompt = app.query_one("#projects", OptionList).get_option_at_index(0).prompt
    return prompt.plain


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending", "—")])}
# An in-progress epic + a spec lacking epics → two epic-column candidates to
# navigate between, so we can prove a tick keeps the cursor off row 0.
TWO_CANDIDATES = {
    "docs/epics/39-01-epic-foo.md": epic_md("In Progress", [(1, "Complete", "—"), (2, "Pending", "—")]),
    "docs/specifications/40-spec-bar.md": "# Spec",
}


def _commit(repo, message="update"):
    for args in (["add", "-A"], ["commit", "-q", "-m", message]):
        subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True)


async def test_refresh_key_forces_a_re_derive_bypassing_cache(make_project, cache_root, monkeypatch):
    repo = make_project(EPICS_READY)
    # watch_interval=None so only the keypress drives a refresh, nothing else.
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        # on_mount warmed the cache; with no disk change an unforced refresh would
        # serve cache (zero derives). Count derives from here.
        calls = {"n": 0}
        real = cache_mod.derive_project

        def counting(path):
            calls["n"] += 1
            return real(path)

        monkeypatch.setattr(cache_mod, "derive_project", counting)
        await pilot.press("r")
        assert calls["n"] == 1  # re-derived despite an unchanged freshness stamp


async def test_refresh_key_reflects_on_disk_changes(make_project, cache_root):
    repo = make_project(EPICS_READY)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        # The project row shows no state word now, so the disk change shows through
        # progress: an epics-ready 0/1 becomes a complete 1/1.
        assert "0/1" in project_state(app)

        # The work completes on disk after the board first rendered.
        (repo / "docs" / "epics" / "39-01-epic-foo.md").write_text(
            epic_md("Complete", [(1, "Complete", "—")])
        )
        _commit(repo)

        await pilot.press("r")
        assert "1/1" in project_state(app)


async def test_watch_tick_preserves_the_cursor_when_nothing_changed(make_project, cache_root):
    repo = make_project(TWO_CANDIDATES)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        # Move into the epics column and down to the 2nd candidate.
        await pilot.press("right")
        await pilot.press("down")
        await pilot.pause()
        epics = app.query_one("#epics", OptionList)
        assert epics.highlighted == 1

        # A watch tick with no on-disk change must be a no-op for the cursor.
        app._on_tick()
        await pilot.pause()
        assert epics.highlighted == 1  # not yanked back to the top


async def test_watch_tick_reflects_a_disk_change(make_project, cache_root):
    repo = make_project(EPICS_READY)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        assert "0/1" in project_state(app)  # epics-ready → 0/1 (no state word)
        (repo / "docs" / "epics" / "39-01-epic-foo.md").write_text(
            epic_md("Complete", [(1, "Complete", "—")])
        )
        _commit(repo)

        app._on_tick()  # the tick detects the change and rebuilds
        await pilot.pause()
        assert "1/1" in project_state(app)  # complete → 1/1
