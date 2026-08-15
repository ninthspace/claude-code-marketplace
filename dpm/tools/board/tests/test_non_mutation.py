"""Story 3 — observing a project leaves it byte-identical (FR10).

**These tests prove a property this epic did not deliver.** The board is non-mutating because of
48-02's Story 3 must-NOTs and 48-01's read-only mode; what is here is the evidence, and a passing
run is not a claim that anything in 48-06 made it so.

Two halves, and neither is the whole proof. The whole-tree comparison bounds what a *run* did — it
is the only thing that can catch a write nobody predicted, including one from a library — but it
covers only the paths the session took. The verb sweep bounds what the board's code *can* call, over
every path including the ones no test runs, but it can only see the calls and not what they do. Both
are kept, as 48-05's Story 5 kept its pair, and neither is offered as the whole of FR10's proof.
"""

from __future__ import annotations

import ast
import re
from pathlib import Path

import pytest
import session as board_session
from conftest import BOARD_DIR, DPM_ROOT
from session import NOT_IN_A_SESSION

from board import COMMANDS
from mcp_client import SURFACE, MCPClient, ServerFailed, read_only_environment, server_path
from registry import DATABASE

#: The database file, as it appears in a snapshot keyed on paths relative to the project root.
DATABASE_FILE = str(DATABASE)

#: Where dpm writes the sentence a read-only server refuses with.
READ_ONLY_SOURCE = DPM_ROOT / "src" / "server" / "read-only.js"

#: What is put in the project besides its database, so the whole-tree comparison has a tree.
#:
#: The fixture is built through the server's write tools and comes out holding `.dpm/` and nothing
#: else, which makes "no file under a registered project is written, `.dpm/` included" true of a
#: project that has no other files. Each of these is a file something *could* plausibly rewrite:
#: `.dpm/dpm.sql` is the projection Task 3.2 names by way of example, and the two documents under
#: `docs/` are what a board that decided to parse markdown after all would go looking for.
FURNISHINGS = {
    ".dpm/dpm.sql": "-- a projection of the database, as it stood when someone last published\n",
    "docs/specifications/10-fixture-spec.md": "# The fixture spec\n\nProse the board never reads.\n",
    "docs/epics/10-02-second.md": "# Second epic\n\n**Status**: Pending\n",
    "README.md": "# A project the board was pointed at\n",
}


def furnish(root: Path) -> Path:
    """Give the fixture project the ordinary files a real one has."""
    for relative, content in FURNISHINGS.items():
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    return root


@pytest.fixture
async def observed(fixture_project) -> board_session.Observed:
    """One full board session over a private, furnished copy of the fixture project."""
    return await board_session.run(furnish(fixture_project))


def test_a_full_session_leaves_the_database_byte_identical(observed):
    """Criterion 1, as the spec states it: hash, size and mtime of `.dpm/dpm.db`."""
    assert DATABASE_FILE in observed.before, (
        f"the fixture has no {DATABASE_FILE}, so this test compared nothing"
    )
    assert observed.after.get(DATABASE_FILE) == observed.before[DATABASE_FILE], (
        f"the board wrote to the database it was observing: "
        f"{observed.before[DATABASE_FILE]} → {observed.after.get(DATABASE_FILE)}"
    )


def test_a_full_session_leaves_the_whole_tree_byte_identical(observed):
    """Criterion 2, which is the requirement rather than the criterion.

    FR10 says no file under a registered project is written, `.dpm/` included. A board that
    regenerated `.dpm/dpm.sql`, or left a `-wal` beside the database, or wrote a cache of its own
    into the project passes the test above and fails this one — and the *file set* is asserted
    separately from the contents, because a file that appeared and a file that changed are two
    different faults that happen to share a remedy.
    """
    appeared = sorted(set(observed.after) - set(observed.before))
    vanished = sorted(set(observed.before) - set(observed.after))
    changed = sorted(
        path
        for path, fingerprint in observed.before.items()
        if path in observed.after and observed.after[path] != fingerprint
    )

    # The floor: a comparison over a project holding only its database says nothing about `docs/`,
    # and one over an empty directory says nothing at all.
    assert set(FURNISHINGS) <= set(observed.before), (
        f"the project was not furnished, so the tree compared is {sorted(observed.before)}"
    )
    assert appeared == [], f"the board wrote files into the project it was observing: {appeared}"
    assert vanished == [], f"files disappeared from the project the board was observing: {vanished}"
    assert changed == [], f"the board changed files in the project it was observing: {changed}"


def test_the_session_exercised_every_action_the_board_offers(observed):
    """The floor under both comparisons above: the session has to have been a full one.

    "A session that touched three screens proves nothing about the fourth" is the whole risk here,
    and it is invisible in a passing comparison — a board session that did nothing at all leaves
    every file exactly as it found it. Reconciled against the board's own table in both directions,
    so an action added by a later epic (48-07's search) is exercised here or named with a reason.
    """
    actions = {command.action for command in COMMANDS}
    unexercised = sorted(actions - observed.ran - set(NOT_IN_A_SESSION))
    stale = sorted(set(NOT_IN_A_SESSION) - actions)
    unoffered = [command.name for command in COMMANDS if command.name not in observed.offered]

    assert unoffered == [], f"the palette did not offer, so the session never opened it: {unoffered}"
    assert unexercised == [], f"the session never ran: {unexercised}"
    assert stale == [], f"excused from the session, but no longer an action at all: {stale}"


def read_only_reason() -> str:
    """The opening of dpm's own read-only refusal, read from dpm's source.

    Read rather than transcribed for the reason every signature in this suite is: a copy here agrees
    with dpm on the day it is written, and the day it stops agreeing is the day the derivation below
    silently produces an empty set — which would sweep for nothing and report as a pass.
    """
    found = re.search(r"LAUNCHED_READ_ONLY\s*=\s*'([^']+)'", READ_ONLY_SOURCE.read_text())

    return found.group(1) if found else ""


async def surfaces(root: Path) -> tuple[set[str], set[str]]:
    """Every tool a read-only server advertises, and the subset it refuses *as* read-only.

    **Not the difference between the two tool lists**, which is empty by construction: a read-only
    server advertises every tool and refuses at call time, because a tool withheld from the list
    answers with *Method not found* and tells a user nothing about the reason that applies. So the
    question is put to the server one layer down — every advertised tool is called, and the ones
    that come back with dpm's read-only sentence are the mutating set.

    Both halves are returned because the floor needs both: a derivation that named every tool is as
    vacuous as one that named none, and only the pair distinguishes them.

    Safe by the design it is measuring — the server refuses the calls — and pointed at a throwaway
    copy regardless, so a read-only mode that was broken would damage a directory nobody is
    asserting about rather than the one being hashed above.
    """
    reason = read_only_reason()
    client = await MCPClient(server_path(), cwd=root, env=read_only_environment()).start()
    advertised, refused = set(), set()

    try:
        for tool in await client.advertised():
            advertised.add(tool["name"])

            try:
                await client.call(tool["name"], {})
            except ServerFailed as failure:
                if reason and reason in str(failure):
                    refused.add(tool["name"])
    finally:
        await client.close()

    return advertised, refused


def named_in(module: Path, names: set[str]) -> list[str]:
    """Every place ``module`` writes one of ``names`` as a string, as ``file:line — name``.

    Complaints rather than an assertion, so the control below can drive the real sweep over a
    planted module instead of restating its rule in a second place.
    """
    found = []

    for node in ast.walk(ast.parse(module.read_text())):
        if isinstance(node, ast.Constant) and node.value in names:
            found.append(f"{module.name}:{node.lineno} — {node.value}")

    return found


def sweep(modules: list[Path], names: set[str]) -> list[str]:
    """The same over several modules."""
    return [complaint for module in modules for complaint in named_in(module, names)]


def board_modules() -> list[Path]:
    """Every module the board ships, discovered rather than listed."""
    found = sorted(BOARD_DIR.glob("*.py"))

    assert found, "the sweep found no modules at all, which means it is looking in the wrong place"

    return found


async def test_the_board_names_no_mutating_tool_in_any_code_path(fixture_project):
    """FR10's must-NOT, static so that it covers the paths no test runs.

    Two sweeps over one derived set. The declared surface (NFR5) is what the board's call sites
    actually build, so a mutating tool reaching ``SURFACE`` is one the board would send; the source
    sweep is wider and catches a name written anywhere at all — including one passed to ``pool.read``
    as a bare string, which never reaches ``SURFACE`` until the moment it is called.
    """
    _, mutating = await surfaces(fixture_project)
    declared = sorted(SURFACE.keys() & mutating)
    named = sweep(board_modules(), mutating)

    assert mutating, "no tool refused as read-only, so both sweeps below are looking for nothing"
    assert declared == [], f"the board declares a call to a mutating tool: {declared}"
    assert named == [], f"a board module names a mutating tool: {named}"


async def test_the_mutating_set_is_derived_from_the_server_and_never_empty(fixture_project, tmp_path):
    """The must-NOT's floor, and the control that shows the sweep can fail.

    Once the derivation works, the live surfaces cannot tell a real sweep from a vacuous one: a
    board that names no mutating tool and a set with no tools in it produce the same silence. So the
    set is bounded on both sides — non-empty, and a *proper* subset, which is what a signature
    matching any refusal at all would fail — and the sweep is driven over a planted module that
    calls one of the tools the derivation actually named.
    """
    advertised, mutating = await surfaces(fixture_project)

    assert read_only_reason(), f"dpm's read-only sentence was not found in {READ_ONLY_SOURCE}"
    assert mutating, "the derivation produced no mutating tools at all"
    assert mutating < advertised, (
        f"every tool the server advertises was called mutating ({len(advertised)}), "
        "so the derivation is matching something other than the read-only refusal"
    )

    # Built from what the derivation actually named, so the control cannot outlive the tool it
    # transcribed: a planted `create_epic` would go on failing correctly after dpm renamed it.
    planted = tmp_path / "shortcut.py"
    planted.write_text(
        "async def tidy(pool, root):\n"
        f"    return await pool.read(root, {sorted(mutating)[0]!r}, {{}})\n"
    )

    assert sweep([planted], mutating), "the sweep passes over a module that calls a mutating tool"
    assert sweep(board_modules(), set()) == [], (
        "the sweep complains about a board that names nothing forbidden"
    )
