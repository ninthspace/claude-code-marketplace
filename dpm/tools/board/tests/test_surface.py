"""Story 5 — the tool surface is pinned, not assumed (NFR5).

The requirement is that a dpm release renaming or rescoping a tool *fails a test* rather than
quietly rendering an empty column, so the load-bearing test here is the one that reconciles the
board's declared surface against the real server's own `tools/list`.

Everything else exists because that test has two ways of passing for nothing. It passes if the
board declares no tools, and it passes if the server advertises none — two empty sets agree
perfectly. And it passes while the board calls a tool it never declared, which is why the sweep for
raw string names is here too: the declaration has to *be* the call, not accompany it.
"""

from __future__ import annotations

import ast
import json
from pathlib import Path

import pytest
from conftest import BOARD_DIR, stand_in_pool
from recording_server import DEFAULT_TOOLS

# Imported for its side effect as much as its contents: importing the module that makes the calls
# is what puts them in `SURFACE`, which is the point of declaring at the call site.
import board
from mcp_client import (
    SURFACE,
    SURFACE_MISMATCH,
    Call,
    MCPClient,
    ServerPool,
    Unreadable,
    reconcile,
    server_path,
)

#: Where the tool name sits in the calls board code makes, by method.
TOOL_ARGUMENT = {"call": 0, "read": 1}


def literal_tool_names(module: Path) -> list[tuple[int, str]]:
    """Every ``client.call("name")`` / ``pool.read(root, "name")`` written as a bare string."""
    found = []

    for node in ast.walk(ast.parse(module.read_text())):
        if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Attribute):
            continue

        position = TOOL_ARGUMENT.get(node.func.attr)

        if position is None or len(node.args) <= position:
            continue

        argument = node.args[position]

        if isinstance(argument, ast.Constant) and isinstance(argument.value, str):
            found.append((node.lineno, argument.value))

    return found


async def test_every_declared_call_resolves_against_the_real_server(fixture_project):
    """NFR5's criterion, against `bin/dpm-mcp.js` itself.

    This is the test a dpm release breaks. Every name and every argument the board declares is
    checked against what the server actually serves, and the complaint says which is which.
    """
    client = await MCPClient(server_path(), cwd=fixture_project).start()

    try:
        advertised = await client.advertised()
    finally:
        await client.close()

    complaints = reconcile(SURFACE, advertised)

    assert complaints == [], "dpm no longer serves what the board calls: " + "; ".join(complaints)
    assert SURFACE, "the board declared nothing, so the reconciliation above inspected nothing"


def test_no_board_module_names_a_tool_without_declaring_it():
    """The declared set is the call sites, and this is what stops it being merely *beside* them.

    A `pool.read(root, "list_epic")` written with the name inline works perfectly, is invisible to
    the reconciliation, and is exactly the drift NFR5 exists to catch — the declared list agreeing
    with the server while the code that runs agrees with neither.
    """
    inline = {
        module.name: literal_tool_names(module)
        for module in sorted(BOARD_DIR.glob("*.py"))
        if literal_tool_names(module)
    }

    assert inline == {}, f"a tool name is called without being declared: {inline}"


def test_the_sweep_finds_a_planted_inline_name(tmp_path):
    """The control: the sweep above is silent over a board that has nothing to hide."""
    planted = tmp_path / "shortcut.py"
    planted.write_text('async def go(pool, root):\n    return await pool.read(root, "list_epic")\n')

    assert literal_tool_names(planted) == [(2, "list_epic")]


def test_the_stand_ins_default_surface_still_covers_what_the_board_declares():
    """A diagnostic, not a claim about dpm — but the alternative is eight confusing failures.

    `DEFAULT_TOOLS` is deliberately a *copy* of the shape dpm serves, so that a renamed or rescoped
    one can be planted. A copy drifts: the moment a story declares a new tool or a new argument,
    every stand-in test fails at once with a surface mismatch, and none of them says which side is
    stale. This one does, in one place, and names what to add.
    """
    complaints = reconcile(SURFACE, DEFAULT_TOOLS)

    assert complaints == [], (
        "the stand-in's copy of dpm's surface is behind the board's declarations, so every test "
        "using it fails as a mismatch: " + "; ".join(complaints)
    )


def test_the_floor_rejects_an_empty_declared_set():
    """Two empty sets agree perfectly, which is why agreement alone is not the check."""
    complaints = reconcile({}, [{"name": "list_epic", "inputSchema": {"properties": {}}}])

    assert complaints, "a board that declares nothing passed the reconciliation"
    assert "declares no tools" in complaints[0]


def test_the_floor_rejects_an_empty_advertised_list():
    complaints = reconcile({"list_epic": Call("list_epic")}, [])

    assert complaints, "a server that advertised nothing passed the reconciliation"
    assert "advertised no tools" in complaints[0]


def test_a_renamed_tool_is_named_in_the_complaint():
    renamed = [{"name": "list_epics", "inputSchema": {"properties": {"limit": {}}}}]

    complaints = reconcile({"list_epic": Call("list_epic", frozenset({"limit"}))}, renamed)

    assert complaints == ["the board calls list_epic, which this server does not serve"]


def test_a_rescoped_argument_is_named_in_the_complaint():
    """Rescoped, not renamed: the tool is still there and no longer takes what the board sends."""
    rescoped = [{"name": "list_epic", "inputSchema": {"properties": {"offset": {}}}}]

    complaints = reconcile({"list_epic": Call("list_epic", frozenset({"limit"}))}, rescoped)

    assert complaints == ["list_epic does not accept limit — it accepts offset"]


async def test_a_mismatched_server_makes_the_project_a_state_rather_than_an_empty_column(
    transcript, project, monkeypatch
):
    """NFR5's must-NOT, over a stand-in advertising a renamed tool.

    An empty column is what a renamed tool looks like, and it is also what a project with no epics
    looks like — so a board that carried on would report, in good faith, that there is no work
    anywhere. The read has to fail instead, naming the tool.
    """
    monkeypatch.setenv(
        "RECORDING_TOOLS",
        json.dumps([{"name": "list_epics", "inputSchema": {"properties": {"limit": {}}}}]),
    )
    root = project()
    refusal = None

    async with stand_in_pool() as servers:
        try:
            await servers.read(root, board.EPICS, {"limit": 10})
        except Unreadable as state:
            refusal = state

    assert refusal is not None, "the board read a server that does not serve what it calls"
    assert refusal.state == SURFACE_MISMATCH
    # The complaints are the occurrence's `detail`, not the state's remedy: 48-06 keyed one remedy
    # per state so the set can be reconciled against FR11's, and which tools disagreed is context.
    assert "list_epic" in refusal.detail, f"the state does not name the tool: {refusal.detail}"


async def test_a_mismatched_server_is_not_left_running(transcript, project, monkeypatch):
    """It cannot answer what this board asks; leaving it up holds a database open for nothing."""
    monkeypatch.setenv("RECORDING_TOOLS", "[]")
    root = project()

    async with stand_in_pool() as servers:
        with pytest.raises(Unreadable):
            await servers.read(root, board.EPICS)

        assert servers._clients == {}, "the mismatched server was kept in the pool"
