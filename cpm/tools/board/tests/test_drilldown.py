"""Feature tests for the three-column browser (projects → epics → stories).

Drives the real BoardApp under Textual Pilot: highlighting a project populates its
epics column, highlighting an epic populates its stories column. Completed work is
hidden until toggled; titles (not filenames) are shown.
"""

from __future__ import annotations

import pytest
from textual.widgets import OptionList

from board import BoardApp
from registry import RegistryEntry

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


def labels(app, column) -> list[str]:
    option_list = app.query_one(f"#{column}", OptionList)
    return [str(option_list.get_option_at_index(i).prompt) for i in range(option_list.option_count)]


# An in-progress epic (one story each of complete/in-progress/pending) plus a spec
# lacking epics → the epics column has a `do` candidate and a spec-breakdown row.
MULTI_ACTION = {
    "docs/epics/39-01-epic-foo.md": epic_md(
        "In Progress", [(1, "Complete", "—"), (2, "In Progress", "—"), (3, "Pending", "—")]
    ),
    "docs/specifications/40-spec-bar.md": "# Spec",
}


async def test_project_selection_populates_epics_and_stories(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        # Projects column has the one project; epics + stories cascaded from it.
        assert labels(app, "projects") == ["Proj  ·  1/3"]  # colour conveys state

        epics = labels(app, "epics")
        assert any("Test Epic" in line and "39-01" in line for line in epics)  # title, not filename

        stories = labels(app, "stories")
        # Complete stories hidden by default; in-progress/pending shown.
        assert any("Story 2" in line for line in stories)
        assert all("Complete" not in line for line in stories)


async def test_epics_column_lists_candidates_in_order(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        epics = labels(app, "epics")
        assert len(epics) == 2  # the do-candidate and the spec-breakdown row
        assert "39-01" in epics[0]  # runnable epic candidate first
        assert epics[1] == "40-spec-bar.md needs epics"  # spec-breakdown second, named


async def test_toggle_reveals_completed_stories(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        assert all("Complete" not in line for line in labels(app, "stories"))
        await pilot.press("z")  # toggle show-complete
        await pilot.pause()
        assert any("Complete" in line for line in labels(app, "stories"))


BLOCKED = {
    "docs/epics/39-02-epic-bar.md": epic_md(
        "Pending", [(1, "Pending", "—")], blocked_by="Epic 39-01-epic-missing"
    )
}


async def test_blocked_epic_shows_its_blocker_in_the_third_column(make_project, cache_root):
    repo = make_project(BLOCKED)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        # The sole epic candidate is the blocked one, highlighted by the cascade;
        # the third column explains what a red row is waiting on.
        stories = labels(app, "stories")
        assert "Blocked by:" in stories
        assert any("39-01-epic-missing" in line for line in stories)


async def test_navigating_epics_updates_the_stories_column(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        # First epic (the runnable one) has stories.
        assert labels(app, "stories")
        # Move focus to the epics column, then down to the spec-breakdown row.
        await pilot.press("right")
        await pilot.press("down")
        await pilot.pause()
        # A `needs epics` row targets a spec, not an epic → the third column shows
        # the spec file itself (its lines) instead of stories.
        stories = labels(app, "stories")
        assert "# Spec" in stories
