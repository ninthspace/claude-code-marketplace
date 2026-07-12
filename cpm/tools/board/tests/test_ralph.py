"""Feature tests for ralph multi-epic selection and launch.

`space` toggles the highlighted epic in/out of a *ralph selection* (only `do`
epics — the runnable ones — qualify). A selected epic recolours to blue rather
than gaining a marker. While the selection is non-empty, the whole launch family
(`c`/`l`) retargets to a single `/cpm:ralph <epics…>` over the selection,
so ralph runs them autonomously. The selection is scoped to the project shown in
the epics column and clears when the project changes or after a launch fires.

The runner / clipboard / tmux seams are stubbed exactly as in
`test_launch_actions.py`, so the emitted command is asserted without spawning a
tmux session or touching the clipboard.
"""

from __future__ import annotations

import contextlib

import pytest

from textual.widgets import OptionList

from board import _RALPH_STYLE, BoardApp
from registry import RegistryEntry

from test_derivation import epic_md
from test_launch_actions import launched_command


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


# Two ready epics → two runnable `do` candidates, both ralph-eligible.
TWO_READY = {
    "docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")]),
    "docs/epics/39-02-epic-bar.md": epic_md("Pending", [(1, "Pending", "—")]),
}
# A blocked epic → the only epics-column row is `attention:unblock` (not `do`).
BLOCKED = {
    "docs/epics/39-01-epic-foo.md": epic_md(
        "Pending", [(1, "Pending", "—")], blocked_by="Epic 39-09-epic-missing"
    )
}

RALPH_BOTH = "/cpm:ralph docs/epics/39-01-epic-foo.md docs/epics/39-02-epic-bar.md"


def _board(repo, cache_root, **kwargs):
    # Launch-family tests pass runner=…; pin the tmux backend detached with a fixed
    # session name so the emitted argv is deterministic (mirrors test_launch_actions).
    launch_seams = (
        dict(
            tmux_available=True,
            in_tmux=False,
            session_suffix=lambda: "s",
            attach_suspend=lambda: contextlib.nullcontext(),  # detached launch attaches
        )
        if "runner" in kwargs
        else {}
    )
    return BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        **launch_seams,
        **kwargs,
    )


def _epic_option_style(app, index: int):
    return app.query_one("#epics", OptionList).get_option_at_index(index).prompt.style


# --- selection: space toggles, recolours, and is `do`-only -------------------


async def test_space_selects_the_highlighted_epic_and_recolours_it(make_project, cache_root):
    repo = make_project(TWO_READY)
    async with _board(repo, cache_root).run_test() as pilot:
        await pilot.press("right")  # into the epics column
        await pilot.press("space")  # select the highlighted (row 0) epic
        await pilot.pause()

        app = pilot.app
        assert app._ralph_selection == {str(repo / "docs/epics/39-01-epic-foo.md")}
        assert _epic_option_style(app, 0) == _RALPH_STYLE  # blue, no marker glyph
        assert _epic_option_style(app, 1) != _RALPH_STYLE  # the other row untouched


async def test_space_toggles_off_again(make_project, cache_root):
    repo = make_project(TWO_READY)
    async with _board(repo, cache_root).run_test() as pilot:
        await pilot.press("right")
        await pilot.press("space")  # select
        await pilot.press("space")  # deselect
        await pilot.pause()

        assert pilot.app._ralph_selection == set()


async def test_space_on_a_non_do_row_is_a_noop(make_project, cache_root):
    repo = make_project(BLOCKED)
    async with _board(repo, cache_root).run_test() as pilot:
        await pilot.press("right")  # epics column — the only row is attention:unblock
        await pilot.press("space")
        await pilot.pause()

        # Ralph wraps /cpm:do, so a blocked row can't be selected.
        assert pilot.app._ralph_selection == set()


async def test_switching_project_clears_the_selection(make_project, cache_root):
    repo_a = make_project(TWO_READY, name="alpha")
    repo_b = make_project(TWO_READY, name="beta")
    app = BoardApp(
        entries=[RegistryEntry(str(repo_a), "Alpha"), RegistryEntry(str(repo_b), "Beta")],
        cache_root=cache_root,
        watch_interval=None,
    )
    async with app.run_test() as pilot:
        await pilot.press("right")  # epics
        await pilot.press("space")  # select an epic in the focused project
        await pilot.pause()
        assert pilot.app._ralph_selection

        await pilot.press("left")  # back to projects
        await pilot.press("down")  # highlight the other project → epics repopulate
        await pilot.pause()

        assert pilot.app._ralph_selection == set()


# --- launch: the family retargets to /cpm:ralph over the selection -----------


async def test_launch_runs_ralph_over_the_selected_epics(make_project, cache_root):
    repo = make_project(TWO_READY)
    calls: list = []
    app = _board(repo, cache_root, runner=calls.append)
    async with app.run_test() as pilot:
        await pilot.press("right")  # epics
        await pilot.press("space")  # select row 0
        await pilot.press("down")
        await pilot.press("space")  # select row 1
        await pilot.pause()
        await pilot.press("l")  # launch in a new window

    assert [c[1] for c in calls] == ["new-session", "set-option", "set-option", "bind-key", "attach"]
    assert launched_command(calls[0]) == f"cd {repo} && claude '{RALPH_BOTH}'"


async def test_open_plain_ignores_the_ralph_selection(make_project, cache_root):
    repo = make_project(TWO_READY)
    calls: list = []
    app = _board(repo, cache_root, runner=calls.append)
    async with app.run_test() as pilot:
        await pilot.press("right")
        await pilot.press("space")  # select an epic
        await pilot.pause()
        await pilot.press("o")  # open is always a plain session, never ralph

    assert launched_command(calls[0]) == f"cd {repo} && claude"
    assert pilot.app._ralph_selection  # `o` doesn't consume the selection


async def test_copy_writes_the_ralph_command_for_the_selection(make_project, cache_root):
    repo = make_project(TWO_READY)
    copied: list[str] = []
    app = _board(repo, cache_root, clipboard_writer=copied.append)
    async with app.run_test() as pilot:
        await pilot.press("right")
        await pilot.press("space")
        await pilot.press("down")
        await pilot.press("space")
        await pilot.pause()
        await pilot.press("c")

    assert copied == [f"cd {repo} && claude '{RALPH_BOTH}'"]


async def test_launch_consumes_the_selection(make_project, cache_root):
    repo = make_project(TWO_READY)
    calls: list = []
    app = _board(repo, cache_root, runner=calls.append)
    async with app.run_test() as pilot:
        await pilot.press("right")
        await pilot.press("space")
        await pilot.press("down")
        await pilot.press("space")
        await pilot.pause()
        await pilot.press("l")
        await pilot.pause()

        assert launched_command(calls[0]) == f"cd {repo} && claude '{RALPH_BOTH}'"
        # A launch consumes the selection — the next launch is single-candidate again.
        assert pilot.app._ralph_selection == set()


async def test_empty_selection_leaves_single_candidate_launch_unchanged(make_project, cache_root):
    repo = make_project(TWO_READY)
    calls: list = []
    app = _board(repo, cache_root, runner=calls.append)
    async with app.run_test() as pilot:
        await pilot.press("right")  # epics, nothing selected
        await pilot.press("l")

    # No ralph selection → the highlighted single epic's own /cpm:do, as before.
    assert launched_command(calls[0]) == f"cd {repo} && claude '/cpm:do docs/epics/39-01-epic-foo.md'"
