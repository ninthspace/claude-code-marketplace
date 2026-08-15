"""Story 4 — one server per project, spawned only where a database exists (FR3, AD4).

Every assertion here is made from **outside the pool's own account of itself**. That a client is
reused is asserted from the transcript the server wrote, not from an identity check; that a process
is gone is asserted by signalling its pid, not by asking the client whether it closed; that a
server is read-only and rooted at the project is asserted from the environment and cwd the spawned
process reports about itself, not from the environment the pool assembled.

The distinction matters because every one of these has a passing implementation that does nothing:
a `close()` that returns immediately, a pool that hands back a client it never spawned, a read-only
flag set on a dict that is then not passed.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from conftest import is_running, stand_in_pool
from recording_server import transcript_of

from mcp_client import NO_DATABASE, READ_ONLY, Unreadable, read_only_environment


def handshakes(transcript: Path) -> int:
    """How many servers ever started — one `initialize` per spawned process."""
    return sum(1 for message in transcript_of(transcript) if message["method"] == "initialize")


async def test_reading_a_project_twice_spawns_one_server(transcript, project):
    root = project()

    async with stand_in_pool() as servers:
        await servers.read(root, "list_epic")
        await servers.read(root, "list_story")

    assert handshakes(transcript) == 1, "the second read spawned a second server"
    assert sum(1 for m in transcript_of(transcript) if m["method"] == "tools/call") == 2


async def test_two_entries_reaching_the_same_tree_share_one_server(transcript, project, tmp_path):
    """Keyed on the *resolved* root: the same project registered twice is one process.

    A user who registered a checkout and a symlink to it has one project, whatever the registry
    says. Two servers would mean two connections to one database and two answers to reconcile.
    """
    root = project()
    alias = tmp_path / "alias"
    alias.symlink_to(root)

    async with stand_in_pool() as servers:
        await servers.read(root, "list_epic")
        await servers.read(alias, "list_epic")

    assert handshakes(transcript) == 1, "the same tree under two names spawned two servers"


async def test_every_spawned_server_is_terminated_when_the_pool_closes(transcript, project):
    roots = [project("one"), project("two")]

    async with stand_in_pool() as servers:
        pids = [(await servers.client(root)).pid for root in roots]

        assert all(is_running(pid) for pid in pids), "the servers were never running"

    assert [pid for pid in pids if is_running(pid)] == [], "a server outlived the board"


async def test_a_pool_left_by_an_exception_still_reaps_its_servers(transcript, project):
    """The path that matters, per FR3: not the clean exit, the crash.

    A board that fell over with servers running would leave one process per project holding a
    database open — and the user's next run, seeing nothing, would spawn another beside each.
    """
    root = project()
    pids = []

    with pytest.raises(RuntimeError, match="the board fell over"):
        async with stand_in_pool() as servers:
            pids.append((await servers.client(root)).pid)

            raise RuntimeError("the board fell over")

    assert not is_running(pids[0]), "the server survived the exception that ended the board"


async def test_each_server_is_launched_read_only_at_the_project_root(transcript, project):
    """FR3, asserted from the spawned process's own account of its cwd and environment."""
    root = project()

    async with stand_in_pool() as servers:
        launched = await servers.read(root, "list_epic")

    assert Path(launched["cwd"]).resolve() == root.resolve(), (
        f"the server was launched somewhere other than the project: {launched['cwd']}"
    )
    assert launched["dpm_environment"].get(READ_ONLY) == "1", (
        f"the server was not launched read-only: {launched['dpm_environment']}"
    )


async def test_an_inherited_database_override_never_reaches_a_spawned_server(
    transcript, project, monkeypatch
):
    """`DPM_DATABASE` is dpm's own override, and it is plausibly set in the user's shell.

    Inherited, it would point every server at one database whatever project it was launched in, and
    every row on the board would render — without error, and identically — the status of whichever
    project that variable happened to name.
    """
    monkeypatch.setenv("DPM_DATABASE", "/somewhere/else.db")
    root = project()

    async with stand_in_pool() as servers:
        launched = await servers.read(root, "list_epic")

    assert "DPM_DATABASE" not in launched["dpm_environment"], (
        f"the override reached the server: {launched['dpm_environment']}"
    )
    # The control: the reporting works, so the absence above is an absence and not a blind spot.
    assert READ_ONLY in launched["dpm_environment"]


async def test_a_project_with_no_database_starts_no_process_and_names_the_state(
    transcript, project
):
    """FR3's must-NOT, and FR11's state. Two assertions, and the first is the one with teeth.

    That the board *reports* a missing database is easy; that it did so without paying for a
    process, a handshake and a round trip to learn what was on disk all along is the requirement.
    The transcript is empty because nothing ever started.
    """
    bare = project("bare", database=False)
    refusal = None

    async with stand_in_pool() as servers:
        try:
            await servers.read(bare, "list_epic")
        except Unreadable as state:
            refusal = state

    # First, and not via `pytest.raises`, whose "DID NOT RAISE" is true and names the wrong harm:
    # a board that reported the missing database *after* spawning a server would fail this line
    # and pass every other assertion in the test.
    assert transcript_of(transcript) == [], "a server was spawned against a project with no database"

    assert refusal is not None, "a project with no database was read as though it had one"
    assert refusal.state == NO_DATABASE
    # On the detail rather than the remedy: 48-06 made the remedy a property of the *state* — one
    # sentence per state, so the set can be held to FR11's enumeration — and the context of this
    # occurrence, which is the project it happened to, is what `detail` carries.
    assert str(bare) in refusal.detail, (
        f"the state does not say which project it is about: {refusal.detail}"
    )


async def test_one_unreadable_project_does_not_stop_the_others(transcript, project):
    """FR11: every other project continues to render."""
    bare = project("bare", database=False)
    fine = project("fine")

    async with stand_in_pool() as servers:
        with pytest.raises(Unreadable):
            await servers.read(bare, "list_epic")

        answered = await servers.read(fine, "list_epic")

    assert answered["tool"] == "list_epic"
    assert handshakes(transcript) == 1


def test_the_read_only_environment_is_built_from_the_one_it_inherits():
    """A unit check on the environment itself, so the two rules are visible without a subprocess."""
    built = read_only_environment({"PATH": "/usr/bin", "DPM_DATABASE": "/elsewhere.db"})

    assert built[READ_ONLY] == "1"
    assert "DPM_DATABASE" not in built
    assert built["PATH"] == "/usr/bin", "the inherited environment was discarded rather than amended"
