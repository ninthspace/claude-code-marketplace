"""Feature tests for the projects column (left column of the browser).

Drives the real BoardApp with Textual Pilot over real fixture repos wired through
the registry → cache → engine stack, then asserts on the OptionList's structured
options (count, RAG-styled prompt, order) rather than a screen scrape.
"""

from __future__ import annotations

import pytest
from textual.widgets import OptionList

from board import BoardApp
from board_view import project_style
from registry import RegistryEntry
from status_model import State, derive_project

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


def entry(repo, label=None):
    return RegistryEntry(path=str(repo), label=label)


def project_prompts(app):
    """The projects column as a list of Rich Text prompts (carrying .plain/.style)."""
    option_list = app.query_one("#projects", OptionList)
    return [option_list.get_option_at_index(i).prompt for i in range(option_list.option_count)]


IN_PROGRESS_4_OF_7 = {
    "docs/epics/39-01-epic-foo.md": epic_md(
        "In Progress",
        [(1, "Complete", "—"), (2, "Complete", "—"), (3, "Complete", "—"),
         (4, "Complete", "—"), (5, "In Progress", "—"), (6, "Pending", "—"), (7, "Pending", "—")],
    )
}
COMPLETE = {"docs/epics/39-01-epic-foo.md": epic_md("Complete", [(1, "Complete", "—")])}
BLOCKED = {
    "docs/epics/39-02-epic-bar.md": epic_md(
        "Pending", [(1, "Pending", "—")], blocked_by="Epic 39-01-epic-missing"
    )
}


async def test_renders_one_option_per_registered_project(make_project, cache_root):
    a = make_project(COMPLETE)
    b = make_project(COMPLETE)
    app = BoardApp(entries=[entry(a, "Alpha"), entry(b, "Bravo")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        names = {p.plain.split("  ·  ")[0] for p in project_prompts(app)}
        assert names == {"Alpha", "Bravo"}


async def test_project_option_shows_progress_and_no_state_word(make_project, cache_root):
    repo = make_project(IN_PROGRESS_4_OF_7)
    app = BoardApp(entries=[entry(repo, "Proj")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        (prompt,) = project_prompts(app)
        assert "4/7" in prompt.plain
        assert "in-progress" not in prompt.plain  # colour conveys state, not text
        assert prompt.style == "yellow"  # in-progress → yellow (epics palette)


async def test_status_colour_maps_state(make_project, cache_root):
    green_repo = make_project(COMPLETE)
    red_repo = make_project(BLOCKED)
    app = BoardApp(
        entries=[entry(green_repo, "Done"), entry(red_repo, "Stuck")], cache_root=cache_root, watch_interval=None
    )
    async with app.run_test():
        by_name = {p.plain.split("  ·  ")[0]: p.style for p in project_prompts(app)}
        assert by_name["Done"] == project_style(State.COMPLETE) == "green"
        assert by_name["Stuck"] == project_style(State.BLOCKED) == "red"


async def test_attention_needing_projects_sort_above_idle(make_project, cache_root):
    done = make_project(COMPLETE)
    stuck = make_project(BLOCKED)
    active = make_project(IN_PROGRESS_4_OF_7)
    app = BoardApp(
        entries=[entry(done, "Done"), entry(stuck, "Stuck"), entry(active, "Active")],
        cache_root=cache_root,
        watch_interval=None,
    )
    async with app.run_test():
        order = [p.plain.split("  ·  ")[0] for p in project_prompts(app)]
        assert order.index("Stuck") < order.index("Done")
        assert order.index("Active") < order.index("Done")
        assert order[-1] == "Done"


async def test_derive_project_agrees_with_the_rendered_state(make_project, cache_root):
    repo = make_project(BLOCKED)
    app = BoardApp(entries=[entry(repo, "Stuck")], cache_root=cache_root, watch_interval=None)
    async with app.run_test():
        (prompt,) = project_prompts(app)
        # The state word is gone from the text, so the view mirrors the engine
        # through colour: the engine's state maps to the row's rendered style.
        assert prompt.style == project_style(derive_project(repo).state)
