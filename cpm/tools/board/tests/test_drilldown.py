"""Feature tests for the three-column browser (projects → epics → stories).

Drives the real BoardApp under Textual Pilot: highlighting a project populates its
epics column, highlighting an epic populates its stories column. Completed work is
hidden until toggled; titles (not filenames) are shown.
"""

from __future__ import annotations

import pytest
from textual.selection import Selection
from textual.widgets import OptionList, Static

from board import BoardApp
from registry import RegistryEntry

from test_derivation import epic_md


def _rendered_text(widget) -> str:
    """The Static's rendered text. The detail panels hold a Textual ``Content`` (a
    selectable, markdown-rasterised renderable) or a bare ``Text`` when empty — both
    expose the visible text as ``.plain``. ``.content`` is the renderable passed to
    ``update`` (``render`` wraps it in a Visual)."""
    return widget.content.plain


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


def labels(app, column) -> list[str]:
    option_list = app.query_one(f"#{column}", OptionList)
    return [str(option_list.get_option_at_index(i).prompt) for i in range(option_list.option_count)]


def detail_text(app) -> str:
    """The middle-column detail panel's rendered text (source-file markdown for the
    highlighted epic row, plus any 'Blocked by' preface)."""
    return _rendered_text(app.query_one("#epic-detail-body", Static))


def story_detail_text(app) -> str:
    """The stories-column detail panel's rendered text (the highlighted story's own
    `##` section from the epic doc, rendered as markdown)."""
    return _rendered_text(app.query_one("#story-detail-body", Static))


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


async def test_detail_panel_shows_the_highlighted_epics_file(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        # The cascade highlights the runnable epic → its source `.md` renders below
        # the epics list, so the middle column carries both the row and its file.
        assert "Test Epic" in detail_text(app)


async def test_epics_column_lists_candidates_in_order(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        epics = labels(app, "epics")
        assert len(epics) == 2  # the do-candidate and the spec-breakdown row
        assert "39-01" in epics[0]  # runnable epic candidate first
        assert epics[1] == "40-spec-bar.md needs epics"  # spec-breakdown second, named


async def test_story_detail_shows_the_highlighted_storys_section(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        # Complete story 1 is hidden → visible stories are 2 (in-progress) and 3.
        # The cascade highlights the first visible story (2); its section shows below.
        detail = story_detail_text(app)
        assert "Story 2" in detail
        assert "In Progress" in detail
        assert "Story 3" not in detail  # just this story's section, not the whole file
        assert "Test Epic" not in detail  # just the story's section, not the epic H1

        # Navigate to the next story → the panel follows the highlight.
        await pilot.press("right")  # epics
        await pilot.press("right")  # stories
        await pilot.press("down")   # story 3
        await pilot.pause()
        detail = story_detail_text(app)
        assert "Story 3" in detail
        assert "Story 2" not in detail


async def test_story_detail_keeps_metadata_fields_on_separate_lines(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        # The story section's consecutive `**Field**: value` lines must render one per
        # line — a single newline is a hard break here, not a space. Regression: Rich's
        # default CommonMark collapses them into one run-on paragraph.
        status_lines = [ln for ln in story_detail_text(app).splitlines() if "Status" in ln]
        assert status_lines
        assert all("Blocked by" not in ln for ln in status_lines)  # not collapsed onto one line


async def test_detail_panels_hold_selectable_text(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        # The panels must render selectable text (a Textual Content), not a Rich
        # Markdown renderable — the latter reports no selection, so nothing highlights
        # or copies. get_selection returning text is that contract. Regression.
        for panel_id in ("#epic-detail-body", "#story-detail-body"):
            body = app.query_one(panel_id, Static)
            extracted = body.get_selection(Selection(None, None))
            assert extracted is not None, f"{panel_id} is not selectable"
            assert extracted[0].strip()  # some text under the whole-widget selection


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


async def test_blocked_epic_shows_its_blocker_in_the_detail_panel(make_project, cache_root):
    repo = make_project(BLOCKED)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        # The sole epic candidate is the blocked one, highlighted by the cascade;
        # the middle-column detail panel explains what a red row is waiting on
        # (the stories column stays purely stories).
        detail = detail_text(app)
        assert "Blocked by:" in detail
        assert "39-01-epic-missing" in detail


async def test_navigating_epics_updates_the_detail_panel(make_project, cache_root):
    repo = make_project(MULTI_ACTION)
    app = BoardApp(entries=[RegistryEntry(str(repo), "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test() as pilot:
        # First epic (the runnable one) has stories.
        assert labels(app, "stories")
        # Move focus to the epics column, then down to the spec-breakdown row.
        await pilot.press("right")
        await pilot.press("down")
        await pilot.pause()
        # A `needs epics` row targets a spec, not an epic → the stories column is empty
        # and the detail panel shows the spec file itself (its lines).
        assert labels(app, "stories") == []
        assert "Spec" in detail_text(app)
