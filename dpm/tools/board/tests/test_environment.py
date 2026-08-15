"""Story 2 — a runnable script and a resolvable server (ENV1, ENV3, ENV4, ENVX2, ENVX4).

The story's subject is the *environment*, so most of what is asserted here is about what the board
does not need: no install step, no dependency on dpm, no network. Each of those is easy to pass
vacuously — a suite that never tried the network passes "no network available" — so every one of
them is paired with a planted control that must fail.
"""

from __future__ import annotations

import json
import shutil
import socket
import subprocess
import sys
import tomllib
from pathlib import Path

import pytest
from conftest import BOARD_DIR, DPM_ROOT, guarded_env
from netguard import NetworkUnavailable

from board import run_cli
from mcp_client import SERVER_EXECUTABLE, SERVER_OVERRIDE, ServerNotFound, server_path

uv_required = pytest.mark.skipif(shutil.which("uv") is None, reason="uv is not on PATH")


def plant_server(root: Path) -> Path:
    """A stand-in ``bin/dpm-mcp.js`` under ``root``, returned by its full path."""
    server = root / SERVER_EXECUTABLE
    server.parent.mkdir(parents=True, exist_ok=True)
    server.write_text("// not run by these tests\n")
    return server


def plant_install(cache: Path, marketplace: str, version: str) -> Path:
    """A stand-in installed plugin: ``cache/<marketplace>/dpm/<version>/bin/dpm-mcp.js``."""
    return plant_server(cache / marketplace / "dpm" / version)


def inline_dependencies(script: Path) -> list[str]:
    """The ``dependencies`` list from a PEP 723 inline metadata block."""
    block: list[str] = []
    inside = False

    for line in script.read_text().splitlines():
        if line.startswith("# /// script"):
            inside = True
        elif inside and line.startswith("# ///"):
            break
        elif inside:
            block.append(line.removeprefix("#").removeprefix(" "))

    assert block, f"{script} has no PEP 723 inline metadata block"

    return tomllib.loads("\n".join(block))["dependencies"]


# --- ENV3: the server path resolves three ways -----------------------------------------------


def test_the_override_is_taken_before_a_checkout_and_a_plugin_cache(tmp_path):
    """All three present at once, which is the only arrangement that tests an *order*."""
    checkout = tmp_path / "checkout"
    cache = tmp_path / "cache"
    override = plant_server(tmp_path / "elsewhere")

    plant_server(checkout)
    plant_install(cache, "a-marketplace", "9.9.9")

    resolved = server_path(override=str(override), dpm_root=checkout, cache_root=cache)

    assert resolved == override, "the override lost to a server that was merely nearer"


def test_the_override_is_read_from_the_environment(tmp_path, monkeypatch):
    """The variable, not just the keyword argument — the keyword is the seam, not the interface."""
    override = plant_server(tmp_path / "elsewhere")
    checkout = tmp_path / "checkout"
    plant_server(checkout)

    monkeypatch.setenv(SERVER_OVERRIDE, str(override))

    assert server_path(dpm_root=checkout, cache_root=tmp_path / "nothing") == override


def test_the_server_beside_the_script_is_taken_before_the_plugin_cache(tmp_path):
    checkout = tmp_path / "checkout"
    cache = tmp_path / "cache"
    beside = plant_server(checkout)
    plant_install(cache, "a-marketplace", "9.9.9")

    assert server_path(dpm_root=checkout, cache_root=cache) == beside


def test_the_plugin_cache_answers_when_the_script_stands_alone(tmp_path):
    """``board.py`` copied out on its own has no sibling ``bin/`` — the installed plugin is it."""
    cache = tmp_path / "cache"
    plant_install(cache, "a-marketplace", "0.9.0")
    newest = plant_install(cache, "a-marketplace", "0.10.0")
    plant_install(cache, "b-marketplace", "0.2.0")

    resolved = server_path(dpm_root=tmp_path / "no-checkout", cache_root=cache)

    # Compared numerically, not as strings: 0.9.0 sorts above 0.10.0 in every alphabetical order.
    assert resolved == newest, f"the newest installed version did not win: {resolved}"


def test_an_override_pointing_at_nothing_is_fatal_rather_than_a_fallback(tmp_path):
    """The failure mode the ordering exists to prevent, with a *working* server left in reach.

    A fall-through here would answer every query correctly, from the wrong tree, with nothing
    looking broken — and the reason to set the variable at all is that the resolution order was
    about to pick the copy this now silently returns.
    """
    checkout = tmp_path / "checkout"
    plant_server(checkout)
    absent = tmp_path / "typo" / "dpm-mcp.js"

    try:
        resolved = server_path(override=str(absent), dpm_root=checkout, cache_root=tmp_path)
    except ServerNotFound as refusal:
        message = str(refusal)
    else:
        # Written out rather than `pytest.raises`, whose "DID NOT RAISE" is true and says nothing:
        # the failure worth reading names the tree the board would have answered from instead.
        pytest.fail(f"a broken override fell through and silently answered from {resolved}")

    assert str(absent) in message, "the refusal does not name the path it was given"
    assert SERVER_OVERRIDE in message, "the refusal does not say which variable set it"


def test_nothing_resolvable_names_every_place_that_was_looked(tmp_path):
    missing_checkout = tmp_path / "no-checkout"
    missing_cache = tmp_path / "no-cache"

    with pytest.raises(ServerNotFound) as refusal:
        server_path(dpm_root=missing_checkout, cache_root=missing_cache)

    message = str(refusal.value)

    assert str(missing_checkout) in message
    assert str(missing_cache) in message
    assert SERVER_OVERRIDE in message


# --- ENVX2: no install step, and dpm gains nothing ---------------------------------------------


def test_the_inline_block_and_the_test_harness_declare_the_same_dependencies():
    """The two lists are copies of each other, not a superset and a subset.

    ``pyproject.toml`` provisions the *suite*; the PEP 723 block provisions what ships. A package
    named in the first and not the second is one every test has and the board does not, which is an
    import that works everywhere except the first real run.
    """
    shipped = inline_dependencies(BOARD_DIR / "board.py")
    harness = tomllib.loads((BOARD_DIR / "pyproject.toml").read_text())["project"]["dependencies"]

    assert shipped == harness, f"the script provisions {shipped} and the suite {harness}"


def test_dpm_gains_no_runtime_dependency():
    """ENVX2: the board is uv-managed and its own; dpm still ships zero dependencies."""
    manifest = json.loads((DPM_ROOT / "package.json").read_text())

    assert manifest.get("dependencies") == {}, "dpm gained a runtime dependency"
    assert manifest.get("devDependencies") == {}, "dpm gained a development dependency"


@uv_required
def test_the_script_runs_from_a_clean_copy_with_no_install_step(sandbox, tmp_path):
    """ENV1: the shipped modules, copied somewhere with no ``.venv``, no lock file, no pyproject.

    Run from the board directory this would pass on the harness the developer already installed.
    The copy is what makes it mean "clean checkout": uv has nothing to work from but the inline
    block at the top of ``board.py``.
    """
    clean = tmp_path / "clean-checkout"
    clean.mkdir()

    for module in sorted(BOARD_DIR.glob("*.py")):
        shutil.copy(module, clean / module.name)

    run = subprocess.run(
        ["uv", "run", "--script", "board.py", "list"],
        cwd=clean,
        env=guarded_env(sandbox),
        capture_output=True,
        text=True,
        timeout=180,
    )

    assert run.returncode == 0, run.stderr
    assert run.stdout.strip() == "", f"a clean checkout listed something: {run.stdout!r}"

    # An install is a `.venv`, a `uv.lock`, a `pyproject.toml`. `__pycache__` is the interpreter's
    # own bytecode and would appear for a script with no metadata block at all, so it is not one.
    shipped = {module.name for module in BOARD_DIR.glob("*.py")} | {"__pycache__"}
    left_behind = {entry.name for entry in clean.iterdir()} - shipped

    assert left_behind == set(), f"running the script left an install behind beside it: {left_behind}"


@uv_required
def test_uv_run_pytest_runs_the_suite_from_the_board_directory():
    """ENV4, from outside: the harness this file is running under, provisioned by uv itself.

    A single module is selected rather than the whole suite because the whole suite contains this
    test, and a test that runs itself does not terminate.
    """
    run = subprocess.run(
        ["uv", "run", "pytest", "tests/test_registry.py", "-q"],
        cwd=BOARD_DIR,
        capture_output=True,
        text=True,
        timeout=300,
    )

    assert run.returncode == 0, f"{run.stdout}\n{run.stderr}"
    assert "passed" in run.stdout


# --- ENVX4: no network, and no socket outside the stdio pipes ----------------------------------


def test_the_board_opens_no_socket_that_reaches_outside_the_process(
    sandbox, monkeypatch, project, no_network
):
    """The board's only channel to anything is a child process's stdio pipes.

    The record is compared against `AF_UNIX` rather than against nothing, and that is not a
    weakening: from Story 6 the board runs an asyncio event loop, and a selector loop builds an
    `AF_UNIX` socketpair for its own self-pipe — two file descriptors joined to each other inside
    this process, reaching nothing. Every network family is refused outright by the guard rather
    than merely recorded, which the planted control below proves.

    Driven in-process so the record is the board's own, over the whole surface it has: the three
    registry operations, a `list` that spawns a server, and the server resolution.
    """
    monkeypatch.setenv("XDG_CONFIG_HOME", str(sandbox.config))
    root = project()

    run_cli(["add", str(root)])
    run_cli(["list"])
    run_cli(["remove", str(root)])

    with pytest.raises(ServerNotFound):
        server_path(dpm_root=sandbox.cwd, cache_root=sandbox.cwd)

    assert set(no_network) <= {str(socket.AF_UNIX)}, (
        f"the board opened a socket reaching outside the process: {no_network}"
    )


def test_the_network_is_actually_unavailable_to_the_suite():
    """The planted control: the guard the other test relies on can see a violation.

    Without this, an empty record reads exactly the same whether nothing was opened or nothing was
    watching.
    """
    with pytest.raises(NetworkUnavailable):
        socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    with pytest.raises(NetworkUnavailable):
        socket.create_connection(("example.invalid", 80))

    with pytest.raises(NetworkUnavailable):
        socket.getaddrinfo("example.invalid", 80)


def test_a_spawned_board_starts_with_the_network_unavailable_too(sandbox, tmp_path):
    """And the same control for a child, which no in-process patch reaches.

    Two runs of one interpreter configuration: the board, which must succeed, and a script that
    reaches for the network, which must not. The second is what proves the first was constrained.
    """
    listing = subprocess.run(
        [sys.executable, str(BOARD_DIR / "board.py"), "list"],
        cwd=sandbox.cwd,
        env=guarded_env(sandbox),
        capture_output=True,
        text=True,
    )

    assert listing.returncode == 0, listing.stderr

    reaching = tmp_path / "reach.py"
    reaching.write_text("import socket; socket.create_connection(('example.invalid', 80))\n")

    control = subprocess.run(
        [sys.executable, str(reaching)],
        cwd=sandbox.cwd,
        env=guarded_env(sandbox),
        capture_output=True,
        text=True,
    )

    # The exception type, not merely a non-zero exit: an unresolvable host fails on a machine with
    # no network whether or not the guard was ever installed, so `NetworkUnavailable` is the only
    # part of this that distinguishes a guarded child from an unguarded one.
    assert control.returncode != 0, "the child reached the network with the guard installed"
    assert "NetworkUnavailable" in control.stderr, (
        f"the guard was not installed in the child; it failed for another reason: {control.stderr}"
    )


def test_a_guarded_child_can_still_import_asyncio(sandbox, tmp_path):
    """The guard makes the network unavailable; it must not make the standard library unusable.

    `ssl.py` runs `class SSLSocket(socket)` at import time and `asyncio` imports `ssl`, so a guard
    that leaves anything but a class where `socket.socket` was takes down every child that touches
    asyncio — which, once `board.py` reaches the MCP client, is the board itself. This is the
    regression test for a defect that got as far as being written, because the only children the
    suite spawned at the time imported neither.
    """
    importing = tmp_path / "asynchronous.py"
    importing.write_text("import asyncio\n\nasyncio.run(asyncio.sleep(0))\nprint('ok')\n")

    run = subprocess.run(
        [sys.executable, str(importing)],
        cwd=sandbox.cwd,
        env=guarded_env(sandbox),
        capture_output=True,
        text=True,
    )

    assert run.returncode == 0, f"the guard broke a child that only wanted asyncio: {run.stderr}"
    assert run.stdout.strip() == "ok"
