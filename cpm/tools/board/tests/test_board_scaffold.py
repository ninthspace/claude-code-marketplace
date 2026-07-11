"""Feature test for the foundation scaffold (Story 2).

Asserts on structural markers (widget identity, exit return code) rather than
rendered text — see retro 05's testing-gap lesson.
"""

from board import BoardApp


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
