"""Feature tests for adding a project from within the TUI (directory-picker flow).

Drives the real BoardApp with Textual Pilot: press `a`, browse the directory tree,
select a folder, and assert the project is both persisted to the registry file and
rendered as a new row — without shelling out to the CLI or typing a path by hand.
The picker is rooted at an injected fixture tree (`add_project_root`) so selection
is deterministic.
"""

from __future__ import annotations

import pytest
from textual.widgets import DirectoryTree, Input, OptionList

from board import BoardApp
from registry import RegistryEntry, load_registry


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


@pytest.fixture
def workspace(tmp_path):
    """A directory tree to browse: two project dirs, a file, and a dotfile."""
    root = tmp_path / "workspace"
    (root / "alpha").mkdir(parents=True)
    (root / "beta").mkdir()
    (root / ".hidden").mkdir()
    (root / "notes.txt").write_text("x")
    return root


def project_count(app) -> int:
    return app.query_one("#projects", OptionList).option_count


def tree_labels(app) -> list[str]:
    tree = app.screen.query_one("#add-tree", DirectoryTree)
    return [str(tree.get_node_at_line(i).label) for i in range(tree.last_line + 1)]


async def test_add_project_via_picker_persists_and_renders(workspace, tmp_path, cache_root):
    reg = tmp_path / "registry.json"
    app = BoardApp(
        registry_file=reg, cache_root=cache_root, watch_interval=None, add_project_root=workspace
    )
    async with app.run_test() as pilot:
        assert project_count(app) == 0  # starts empty

        await pilot.press("a")
        await pilot.pause()
        await pilot.pause()  # let the tree load its children
        # The optional label can be set without touching the path field.
        app.screen.query_one("#add-label", Input).value = "Alpha"
        # Move to the first child directory ("alpha") and select it — no typing.
        await pilot.press("down")
        await pilot.press("enter")
        await pilot.pause()

        assert project_count(app) == 1
        prompt = app.query_one("#projects", OptionList).get_option_at_index(0).prompt
        assert "Alpha" in prompt.plain

    # Persisted to the registry file, so it survives a restart.
    entries = load_registry(reg)
    assert [(e.path, e.label) for e in entries] == [(str(workspace / "alpha"), "Alpha")]


async def test_picker_starts_from_the_selected_project_parent(workspace, cache_root):
    # With "alpha" registered and selected, the picker roots at its parent
    # (the workspace) so the sibling repos are right there to pick from.
    app = BoardApp(
        entries=[RegistryEntry(str(workspace / "alpha"), "Alpha")],
        cache_root=cache_root,
        watch_interval=None,
    )
    async with app.run_test() as pilot:
        await pilot.press("a")
        await pilot.pause()
        await pilot.pause()
        labels = tree_labels(app)

        assert "alpha" in labels and "beta" in labels  # siblings of the selected project


async def test_picker_lists_directories_only(workspace, tmp_path, cache_root):
    reg = tmp_path / "registry.json"
    app = BoardApp(
        registry_file=reg, cache_root=cache_root, watch_interval=None, add_project_root=workspace
    )
    async with app.run_test() as pilot:
        await pilot.press("a")
        await pilot.pause()
        await pilot.pause()
        labels = tree_labels(app)

        assert "alpha" in labels and "beta" in labels  # project dirs shown
        assert "notes.txt" not in labels  # files hidden — a project is a directory
        assert ".hidden" not in labels  # dotfiles hidden to reduce clutter


async def test_escape_cancels_without_adding(workspace, tmp_path, cache_root):
    reg = tmp_path / "registry.json"
    app = BoardApp(
        registry_file=reg, cache_root=cache_root, watch_interval=None, add_project_root=workspace
    )
    async with app.run_test() as pilot:
        await pilot.press("a")
        await pilot.pause()
        await pilot.pause()
        await pilot.press("escape")
        await pilot.pause()
        assert project_count(app) == 0

    assert load_registry(reg) == []
