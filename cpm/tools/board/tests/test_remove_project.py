"""Feature tests for removing a project from within the TUI (confirm flow).

Press `x` on the highlighted row, confirm in the modal, and assert the project is
dropped from both the registry file and the rendered rows. Cancelling leaves it.
"""

from __future__ import annotations

import pytest

from textual.widgets import Label, OptionList

from board import BoardApp, ConfirmRemoveScreen
from registry import add_project, load_registry

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}


def project_count(app) -> int:
    return app.query_one("#projects", OptionList).option_count


async def test_remove_project_after_confirm(make_project, tmp_path, cache_root):
    repo = make_project(EPICS_READY)
    reg = tmp_path / "registry.json"
    add_project(str(repo), "Foo", registry_file=reg)
    app = BoardApp(registry_file=reg, cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        assert project_count(app) == 1

        await pilot.press("x")
        await pilot.pause()
        assert isinstance(app.screen, ConfirmRemoveScreen)
        await pilot.press("y")
        await pilot.pause()
        assert project_count(app) == 0

    assert load_registry(reg) == []  # unregistered on disk too


async def test_confirm_dialog_shows_both_key_hints(make_project, tmp_path, cache_root):
    # The "[y]" hint must survive to the screen — with Rich markup enabled it is
    # parsed as an (unknown) style tag and silently swallowed, so the remove key
    # would show no hint while "[n / Esc]" (invalid markup) survives.
    repo = make_project(EPICS_READY)
    reg = tmp_path / "registry.json"
    add_project(str(repo), "Foo", registry_file=reg)
    app = BoardApp(registry_file=reg, cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        await pilot.press("x")
        await pilot.pause()
        rendered = [label.render().plain for label in app.screen.query(Label)]
        hint = next(line for line in rendered if "cancel" in line)
        assert "[y]" in hint  # the remove key hint is present, not eaten by markup
        assert "[n / Esc]" in hint


async def test_remove_cancelled_keeps_project(make_project, tmp_path, cache_root):
    repo = make_project(EPICS_READY)
    reg = tmp_path / "registry.json"
    add_project(str(repo), "Foo", registry_file=reg)
    app = BoardApp(registry_file=reg, cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        await pilot.press("x")
        await pilot.pause()
        await pilot.press("n")  # cancel
        await pilot.pause()
        assert project_count(app) == 1

    assert [e.path for e in load_registry(reg)] == [str(repo)]  # still registered
