"""Shared fixtures for the dpm board's suite.

Two things every test here needs, and both exist to stop a test passing for the wrong reason.

``project`` materialises the *shape* a dpm project has — a directory with ``.dpm/dpm.db`` in it —
because that shape is what the registry validates against and what the pool refuses to spawn
without. A real database is built by ``fixture_database`` (Story 3) where the tests actually drive a
server; the registry never opens the file and has no business needing a real one.

``sandbox`` points every environment variable the board could resolve a write path from at a
directory the test owns, and hands back all three roots. Its value is not the isolation — it is that
a test can then assert on what appeared in each, which is the only form of FR1's must-NOT that says
anything: that the expected file appeared inside ``$XDG_CONFIG_HOME`` is equally true of a board
writing a second copy into the user's home directory.

``no_network`` is autouse, so ENVX4's "the suite passes with no network available" is a property of
every test here rather than of the one test that remembered to ask for it. Requesting it by name
additionally hands back the record of every socket opened while the test ran.

``built_fixture`` is a real dpm database, built once per session by dpm's own tools, and
``fixture_project`` is a throwaway copy of it — see ``support/fixture_database.py`` for why the
integration tests are worth their runtime only if the thing on the other end of the pipe is the
actual server.
"""

from __future__ import annotations

import asyncio
import os
import sys
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from shutil import copytree

import pytest
from fixture_database import build
from netguard import install
from recording_server import spawned_pids

from mcp_client import ServerPool, server_path

#: Put on a spawned interpreter's ``PYTHONPATH`` to install the same guard there.
NETGUARD = Path(__file__).resolve().parent / "support"

#: The board's own directory — what the module sweeps enumerate and the CLI tests spawn from.
BOARD_DIR = Path(__file__).resolve().parent.parent

#: The dpm tree the board lives in, holding `bin/dpm-mcp.js`, `package.json` and `src/`.
DPM_ROOT = BOARD_DIR.parent.parent

#: The stand-in server that records what it was asked — spawned with `sys.executable`, not `node`.
STAND_IN = NETGUARD / "recording_server.py"


@pytest.fixture(autouse=True)
def no_network(monkeypatch) -> list[str]:
    """Every test runs with the network unavailable; yields the list of sockets opened."""
    return install(setattr_=monkeypatch.setattr)


def guarded_env(sandbox: "Sandbox") -> dict[str, str]:
    """The environment for a spawned board: the test's own write roots, and no network."""
    return {**os.environ, **sandbox.env(), "PYTHONPATH": str(NETGUARD)}


def stand_in_pool() -> ServerPool:
    """A pool whose servers are the recording stand-in, spawned by this interpreter.

    Everything else about it is the real thing — the read-only environment, the pre-spawn check,
    the reconciliation — because those are what the tests using this are about.
    """
    return ServerPool(STAND_IN, node=sys.executable)


@dataclass(frozen=True)
class Sandbox:
    """The three roots a board run could plausibly write into, all owned by the test."""

    config: Path
    home: Path
    cwd: Path

    def env(self) -> dict[str, str]:
        """The environment that puts every one of them where this test can watch it."""
        return {"XDG_CONFIG_HOME": str(self.config), "HOME": str(self.home)}


def files_under(root: Path) -> set[str]:
    """Every file below ``root``, as paths relative to it.

    Returned as a set for a test to assert on rather than asserted here, so the assertion lives
    beside the criterion it is about — and so the same helper can be pointed at a root that is
    supposed to be empty and at one that is supposed to hold exactly one file.
    """
    return {str(path.relative_to(root)) for path in root.rglob("*") if path.is_file()}


@pytest.fixture
def sandbox(tmp_path: Path) -> Sandbox:
    """Config, home and working directories the test owns, all initially empty."""
    roots = Sandbox(config=tmp_path / "config", home=tmp_path / "home", cwd=tmp_path / "cwd")

    for root in (roots.config, roots.home, roots.cwd):
        root.mkdir()

    return roots


@pytest.fixture
def transcript(tmp_path, monkeypatch) -> Path:
    """Where the stand-in servers write what they were asked — one file for a whole pool.

    Set in the real environment rather than passed to the pool, because the pool builds its
    children's environment itself (that is the thing under test) and a test that handed it one
    would be exercising a path the board never takes.
    """
    path = tmp_path / "transcript.jsonl"
    monkeypatch.setenv("RECORDING_TRANSCRIPT", str(path))
    monkeypatch.setenv("RECORDING_PIDS", str(tmp_path / "pids"))

    return path


@pytest.fixture
def spawned(tmp_path) -> Callable[[], list[int]]:
    """Reads back the pids of every stand-in server that started — an outside witness."""
    return lambda: spawned_pids(tmp_path / "pids")


def is_running(pid: int) -> bool:
    """Whether a process still exists, asked of the operating system rather than of the board."""
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False

    return True


@pytest.fixture(scope="session")
def built_fixture(tmp_path_factory) -> Path:
    """A project directory holding a real dpm database, built once for the whole session (ENV5).

    Session-scoped because building it spawns a server and drives seven write calls, and nothing
    that reads it changes it. Tests that need their own copy take one from ``fixture_project``.
    """
    root = tmp_path_factory.mktemp("built-fixture")

    asyncio.run(build(root, server_path()))

    return root


@pytest.fixture
def fixture_project(built_fixture: Path, tmp_path: Path) -> Path:
    """A private copy of the built fixture, so a test may do what it likes to it."""
    root = tmp_path / "fixture-project"
    copytree(built_fixture, root)

    return root


@pytest.fixture
def project(tmp_path: Path):
    """Factory for a directory shaped like a dpm project, or deliberately not one."""
    def _make(name: str = "project", *, database: bool = True) -> Path:
        root = tmp_path / "projects" / name
        root.mkdir(parents=True)

        if database:
            (root / ".dpm").mkdir()
            (root / ".dpm" / "dpm.db").write_bytes(b"")

        return root

    return _make
