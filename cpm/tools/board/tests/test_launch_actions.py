"""Feature tests for launch / open / copy in the three-column browser.

The launch model is a single backend: **tmux**. **launch** (`l`) runs the target
in a detached tmux session; **open** (`o`) runs a plain `claude` — no `/cpm`
command — at the selected project's directory, also in tmux. Copy (`c`) writes
the same shell-safe launch command to the clipboard.

Launch and copy pick their target by the **focused column**, analogous to
`/cpm:do`: from the projects column, a bare `/cpm:do` (no epic — cpm:do discovers
the next story) for the selected project; from the epics/stories column, the
highlighted epic candidate's own command. `o` always targets the project
directory with no command, whatever the focused column.

Stub clipboard-writer / runner seams assert the exact command without touching
the clipboard or spawning tmux. The tmux seams (`tmux_available`, `in_tmux`,
`session_suffix`) are pinned so the emitted argv is deterministic.
"""

from __future__ import annotations

import contextlib

import pytest

from board import BoardApp
from launcher import clipboard_command
from registry import RegistryEntry
from status_model import derive_project

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


def launched_command(argv: list[str]) -> str:
    """Recover the shell command from a `tmux new-session` argv.

    tmux runs the whole `cd … && claude …` command as a single trailing argv
    element, so it is exactly `argv[-1]`."""
    assert argv[0] == "tmux" and "new-session" in argv
    return argv[-1]


def _launch_app(repo, cache_root, calls):
    """A board wired to the tmux backend with a pinned session name, detached
    (not inside tmux). A detached launch always attaches, so the suspend is stubbed
    with a no-op context — the headless driver can't really suspend."""
    return BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        runner=calls.append,
        tmux_available=True,
        in_tmux=False,
        session_suffix=lambda: "s",
        attach_suspend=lambda: contextlib.nullcontext(),
    )


# One ready epic → the epics column has a single runnable `do` candidate.
EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}
# A blocked epic → the only candidate is `attention:unblock` (no command).
BLOCKED = {
    "docs/epics/39-02-epic-bar.md": epic_md(
        "Pending", [(1, "Pending", "—")], blocked_by="Epic 39-01-epic-missing"
    )
}
# An in-progress epic + a spec lacking epics → two runnable candidates in order.
TWO_CANDIDATES = {
    "docs/epics/39-01-epic-foo.md": epic_md("In Progress", [(1, "Complete", "—"), (2, "Pending", "—")]),
    "docs/specifications/40-spec-bar.md": "# Spec",
}


# --- copy (clipboard) --------------------------------------------------------


async def test_projects_column_copy_emits_a_bare_cpm_do(make_project, cache_root):
    repo = make_project(EPICS_READY)
    copied: list[str] = []
    app = BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        clipboard_writer=copied.append,
    )
    async with app.run_test() as pilot:
        # Focus starts on the projects column → a bare, argument-free /cpm:do.
        await pilot.press("c")

    # /cpm:do has no shell-special chars, so shlex.quote leaves it unquoted.
    assert copied == [f"cd {repo} && claude /cpm:do"]


async def test_selection_copy_routes_through_the_local_clipboard_writer(make_project, cache_root):
    # A mouse-selected panel region is copied by Textual via App.copy_to_clipboard,
    # which base-Textual sends as an OSC 52 escape only — macOS Terminal drops that.
    # We override it to also pipe through the local writer (pbcopy), so the copy lands.
    repo = make_project(EPICS_READY)
    copied: list[str] = []
    app = BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        clipboard_writer=copied.append,
    )
    async with app.run_test():
        app.copy_to_clipboard("selected text")

    assert copied == ["selected text"]


async def test_epics_column_copy_writes_the_highlighted_epic_command(make_project, cache_root):
    repo = make_project(EPICS_READY)
    copied: list[str] = []
    app = BoardApp(
        entries=[RegistryEntry(str(repo), "Proj")],
        cache_root=cache_root,
        watch_interval=None,
        clipboard_writer=copied.append,
    )
    async with app.run_test() as pilot:
        # Step into the epics column → the specific epic candidate, not a bare do.
        await pilot.press("right")
        await pilot.press("c")

    primary = derive_project(repo).primary_action
    assert copied == [clipboard_command(str(repo), primary)]
    assert copied[0] == f"cd {repo} && claude '{primary.command}'"


# --- launch (`l`): a detached tmux session -----------------------------------


async def test_projects_column_launch_runs_a_bare_cpm_do(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    async with _launch_app(repo, cache_root, calls).run_test() as pilot:
        await pilot.press("l")

    # new-session (the launch), the @cpm_launched marker + status reminder set-options,
    # the Ctrl-Space return binding, then attach — a detached launch always attaches.
    assert [c[1] for c in calls] == ["new-session", "set-option", "set-option", "bind-key", "attach"]
    assert launched_command(calls[0]) == f"cd {repo} && claude /cpm:do"


async def test_launch_uses_the_highlighted_candidate(make_project, cache_root):
    repo = make_project(TWO_CANDIDATES)
    calls: list = []
    async with _launch_app(repo, cache_root, calls).run_test() as pilot:
        # Focus the epics column and move down to the 2nd candidate (spec-breakdown).
        await pilot.press("right")
        await pilot.press("down")
        await pilot.pause()
        await pilot.press("l")

    second = derive_project(repo).next_actions[1]
    assert launched_command(calls[0]) == f"cd {repo} && claude '{second.command}'"


async def test_stories_column_launch_uses_the_selected_epic(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    async with _launch_app(repo, cache_root, calls).run_test() as pilot:
        # In the third (stories) column, launch still targets the parent epic —
        # a story isn't independently launchable.
        await pilot.press("right")  # epics
        await pilot.press("right")  # stories
        await pilot.press("l")

    primary = derive_project(repo).primary_action
    assert launched_command(calls[0]) == f"cd {repo} && claude '{primary.command}'"


async def test_blocked_candidate_falls_back_to_bare_cpm_do(make_project, cache_root):
    repo = make_project(BLOCKED)
    copied: list[str] = []
    launched: list = []
    app = BoardApp(
        entries=[RegistryEntry(str(repo), "Stuck")],
        cache_root=cache_root,
        watch_interval=None,
        clipboard_writer=copied.append,
        runner=launched.append,
        tmux_available=True,
        in_tmux=False,
        session_suffix=lambda: "s",
        attach_suspend=lambda: contextlib.nullcontext(),
    )
    async with app.run_test() as pilot:
        assert derive_project(repo).primary_action.command is None  # sanity: blocked
        # In the epics column the blocked candidate has no command of its own, so
        # copy/launch fall back to a bare /cpm:do — never a dead key.
        await pilot.press("right")
        await pilot.press("c")
        await pilot.press("l")

    assert [c[1] for c in launched] == ["new-session", "set-option", "set-option", "bind-key", "attach"]
    assert launched_command(launched[0]) == f"cd {repo} && claude /cpm:do"
    assert copied == [f"cd {repo} && claude /cpm:do"]


# --- open (`o`): plain Claude at the project directory ------------------------


async def test_open_plain_opens_claude_at_the_project_directory(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    async with _launch_app(repo, cache_root, calls).run_test() as pilot:
        await pilot.press("o")

    assert [c[1] for c in calls] == ["new-session", "set-option", "set-option", "bind-key", "attach"]
    # A plain `claude` — no /cpm command — in the project's directory.
    assert launched_command(calls[0]) == f"cd {repo} && claude"


async def test_open_plain_ignores_the_focused_column(make_project, cache_root):
    repo = make_project(EPICS_READY)
    calls: list = []
    async with _launch_app(repo, cache_root, calls).run_test() as pilot:
        # Even from the epics column, `o` opens the project, not the epic command.
        await pilot.press("right")
        await pilot.press("o")

    assert launched_command(calls[0]) == f"cd {repo} && claude"
