"""Story 3 — the board is an MCP client and nothing else (FR2's must-NOTs).

Both checks are **sweeps over every module in the board directory**, discovered by glob rather than
listed. A must-NOT written as a list of the files that exist today is satisfied by adding a file:
the module that reaches for `sqlite3` because it was quicker is exactly the module nobody thought
to add to the list.

Static, because that is the only form that covers code no test happens to run — and paired, for the
one about opening files, with a runtime check over a real read, because a static rule can only see
the calls and not where their paths point.
"""

from __future__ import annotations

import ast
import builtins
from pathlib import Path

import pytest
from conftest import BOARD_DIR

from mcp_client import MCPClient, server_path

#: Anything that opens a file, by the name the call is written under.
OPENERS = {"open", "read_text", "read_bytes", "write_text", "write_bytes", "mkdir", "touch"}

#: The modules allowed to open files, and what each is allowed to open.
#:
#: `registry.py` writes the opt-in list and `cache.py` the freshness cache (FR13), both under
#: `$XDG_CONFIG_HOME` and both named by the spec as the only files the board writes anywhere. A
#: *third* name appearing in this set is the finding: the board reads projects through a server, so
#: a module that needs a file needs a reason.
#:
#: **What this check cannot see is where those paths point**, which is why each of the two has a
#: must-NOT of its own asserting the write landed outside every registered project — FR1's for the
#: registry, and Story 1's tree hash across a session that definitely writes a cache entry.
MAY_OPEN_FILES = {"registry.py", "cache.py"}


def modules() -> list[Path]:
    """Every module the board ships — the sweep's subject, discovered rather than enumerated."""
    found = sorted(BOARD_DIR.glob("*.py"))

    assert found, "the sweep found no modules at all, which means it is looking in the wrong place"

    return found


def imports(module: Path) -> set[str]:
    """Every module name imported by ``module``, however the import is written."""
    names: set[str] = set()

    for node in ast.walk(ast.parse(module.read_text())):
        if isinstance(node, ast.Import):
            names.update(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module:
            names.add(node.module)

    return names


def file_openers(module: Path) -> list[tuple[int, str]]:
    """Every call in ``module`` that opens a file, as ``(line, name)``."""
    found = []

    for node in ast.walk(ast.parse(module.read_text())):
        if not isinstance(node, ast.Call):
            continue

        called = (
            node.func.attr
            if isinstance(node.func, ast.Attribute)
            else getattr(node.func, "id", None)
        )

        if called in OPENERS:
            found.append((node.lineno, called))

    return found


def test_no_board_module_imports_sqlite_or_any_binding_for_it():
    """FR2's must-NOT. The board has no database connection; it has a conversation with a server.

    Matched on the substring rather than on `sqlite3` alone, because the failure this prevents is
    someone reaching for whichever binding was to hand — `apsw`, `pysqlite3`, a driver bundled with
    an ORM — and a check that names one import is a check that catches one mistake.
    """
    reaching = {
        module.name: sorted(name for name in imports(module) if "sqlite" in name.lower())
        for module in modules()
    }
    offenders = {name: found for name, found in reaching.items() if found}

    assert offenders == {}, f"the board opened its own database connection: {offenders}"


def test_only_the_registry_opens_files_at_all():
    """The static half of "must NOT open any file under a project's `docs/` or `.dpm/`".

    Stated as *which modules open files* rather than as *which paths they open*, because the second
    is not decidable from the source: a path is built from variables and only exists at runtime.
    What is decidable — and is the property that matters — is that the modules which talk to
    projects do not touch the filesystem at all.
    """
    opening = {
        module.name: file_openers(module)
        for module in modules()
        if module.name not in MAY_OPEN_FILES and file_openers(module)
    }

    assert opening == {}, f"a module outside the registry opens files: {opening}"


async def test_a_real_read_opens_no_file_inside_the_project(fixture_project, monkeypatch):
    """The runtime half, over the real server and a real database.

    The static check cannot see where a path points; this can. Every open is recorded while the
    board reads a project through the client, and the assertion is that none of them landed inside
    the project — the database is opened by the *server*, in its own process, which is the whole
    architecture in one line.
    """
    opened: list[str] = []
    real_open = builtins.open

    def watched(file, *args, **kwargs):
        opened.append(str(file))
        return real_open(file, *args, **kwargs)

    monkeypatch.setattr(builtins, "open", watched)

    client = await MCPClient(server_path(), cwd=fixture_project).start()

    try:
        await client.call("list_epic")
    finally:
        await client.close()

    inside = [path for path in opened if str(fixture_project) in path]

    assert inside == [], f"board code opened a file inside the project it was reading: {inside}"


def test_the_sweep_finds_a_planted_violation(tmp_path, monkeypatch):
    """The control. Both sweeps above pass trivially if they are looking at nothing.

    Pointed at a directory holding one module that does both forbidden things, they must complain —
    which is what makes their silence over the real board mean something.
    """
    planted = tmp_path / "board"
    planted.mkdir()
    (planted / "shortcut.py").write_text(
        "import sqlite3\n\ndef read(path):\n    return path.read_text()\n"
    )

    monkeypatch.setattr("test_isolation.BOARD_DIR", planted)

    with pytest.raises(AssertionError, match="opened its own database connection"):
        test_no_board_module_imports_sqlite_or_any_binding_for_it()

    with pytest.raises(AssertionError, match="outside the registry opens files"):
        test_only_the_registry_opens_files_at_all()
