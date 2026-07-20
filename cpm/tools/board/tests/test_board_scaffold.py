"""Feature test for the foundation scaffold (Story 2).

Asserts on structural markers (widget identity, exit return code) rather than
rendered text — see retro 05's testing-gap lesson.
"""

from board import BoardApp
from registry import add_project, load_registry


async def test_scaffold_boots_and_quits_on_q():
    app = BoardApp(entries=[])  # empty registry — no disk access
    async with app.run_test() as pilot:
        # The three columns mounted — the app booted.
        assert app.query_one("#projects")
        assert app.query_one("#epics")
        assert app.query_one("#stories")
        # Pressing the bound key quits.
        await pilot.press("q")

    # The app exited cleanly via the `q` binding.
    assert app.return_code == 0


async def test_launch_prunes_missing_projects_from_the_registry(tmp_path):
    # A registry loaded from disk (not injected entries) is pruned at startup:
    # the deleted project vanishes from both the board and the file.
    registry_file = tmp_path / "cpm-board" / "registry.json"
    live = tmp_path / "live"
    live.mkdir()
    add_project(str(live), registry_file=registry_file)
    add_project(str(tmp_path / "gone"), registry_file=registry_file)  # never created

    app = BoardApp(registry_file=registry_file, cache_root=tmp_path / "cache", watch_interval=None)
    async with app.run_test():
        assert [name for name, _ in app._projects] == [live.name]  # only the live project shown

    assert [e.path for e in load_registry(registry_file)] == [str(live)]  # dead entry pruned from disk
