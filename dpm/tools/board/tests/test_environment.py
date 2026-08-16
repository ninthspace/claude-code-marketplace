"""Story 2 — a runnable script and a resolvable server (ENV1, ENV3, ENV4, ENVX2, ENVX4).

The story's subject is the *environment*, so most of what is asserted here is about what the board
does not need: no install step, no dependency on dpm, no network. Each of those is easy to pass
vacuously — a suite that never tried the network passes "no network available" — so every one of
them is paired with a planted control that must fail.
"""

from __future__ import annotations

import ast
import json
import re
import shutil
import socket
import subprocess
import sys
import tomllib
from importlib import metadata
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


# --- ENV4: the runner the suite is provisioned with --------------------------------------------


def dev_requirements() -> dict[str, str]:
    """The development group's requirements, as ``{distribution: stated minimum}``.

    Read from the file rather than written out here, so raising a floor in `pyproject.toml` raises
    it in the assertion too. Split on `>=` because that is the only operator this group uses; a
    requirement written any other way lands as a `ValueError` naming the line, which is the right
    outcome for a check whose whole subject is what the group says.
    """
    groups = tomllib.loads((BOARD_DIR / "pyproject.toml").read_text())["dependency-groups"]

    return dict(requirement.split(">=") for requirement in groups["dev"])


def release(version: str) -> tuple[int, ...]:
    """A version as numbers. `0.24` is above `0.9`, which as strings it is not."""
    return tuple(int(part) for part in re.findall(r"\d+", version))


def at_least(installed: str, minimum: str) -> bool:
    """Whether ``installed`` meets ``minimum``, compared numerically and padded to one length.

    Padding matters in one direction only, and it is the direction this is used in: `8` states a
    floor of `8.0.0`, so an installed `8.4.1` has to be read as three parts against one rather than
    as a tuple that is longer and therefore greater by accident.
    """
    found, wanted = release(installed), release(minimum)
    width = max(len(found), len(wanted))

    return found + (0,) * (width - len(found)) >= wanted + (0,) * (width - len(wanted))


def test_the_runner_and_its_asyncio_plugin_meet_the_minimums_the_project_states():
    """ENV4's first half: the harness this file is running under is the one that was asked for.

    Asserted against what is *installed*, through `importlib.metadata`, rather than against the
    file that requested it — a floor stated in `pyproject.toml` and never provisioned is a claim
    about a resolver's intentions, and this suite runs on whatever uv actually put there.
    """
    stated = dev_requirements()

    assert {"pytest", "pytest-asyncio"} <= set(stated), (
        f"the group states no floor for the runner or its asyncio plugin: {stated}"
    )

    for distribution, minimum in stated.items():
        installed = metadata.version(distribution)

        assert at_least(installed, minimum), (
            f"{distribution} {installed} is below the stated minimum of {minimum}"
        )


def test_the_version_comparison_can_report_a_floor_that_is_not_met():
    """The control for the comparison above, which otherwise passes by never being able to fail.

    The third case is the one worth having: `0.9.0` is above `0.24` in every string ordering, so a
    comparison that never became numeric would report a plugin two years out of date as current.
    """
    assert at_least("8.4.1", "8") is True
    assert at_least("7.4.4", "8") is False
    assert at_least("0.9.0", "0.24") is False


# --- ENVX2 continued: what `board.py` is allowed to import --------------------------------------


def canonical(distribution: str) -> str:
    """A distribution name in the one form comparisons can use — see PEP 503."""
    return re.sub(r"[-_.]+", "-", distribution).lower()


def requirement_name(requirement: str) -> str | None:
    """The distribution a requirement string names, or ``None`` for an optional one.

    Anything behind an `extra ==` marker is left out on purpose: an extra is a dependency the
    install did *not* take unless something asked for it, so counting one would widen the allowed
    surface by packages that need not be present at all.
    """
    statement, _, marker = requirement.partition(";")

    if "extra" in marker:
        return None

    return canonical(re.split(r"[\s<>=!~\[(]", statement.strip(), maxsplit=1)[0])


def provisioned(declared: list[str]) -> set[str]:
    """Every distribution the inline block's declarations bring with them, transitively.

    **The closure rather than the literal list**, and that is what the story's own criteria ask
    for: the markdown renderer is imported and appears in neither dependency list, because Textual
    brings it. Written as an equality against `{"textual"}` this would be a change detector — green
    today, and failing the moment a package the board legitimately has arrives one level down.
    """
    seen: set[str] = set()
    pending = [name for name in map(requirement_name, declared) if name]

    while pending:
        distribution = pending.pop()

        if distribution in seen:
            continue

        seen.add(distribution)

        try:
            requires = metadata.requires(distribution) or []
        except metadata.PackageNotFoundError:  # declared, and not installed in this environment
            continue

        pending += [name for name in map(requirement_name, requires) if name]

    return seen


def top_level_imports(script: Path) -> set[str]:
    """The root module of every import in ``script``, from its syntax rather than from a regex.

    A regex over the source finds the same names on a good day and finds them inside strings and
    comments on a bad one — and this is the check that decides whether the board can run where it
    is shipped, so it reads the tree the interpreter will.
    """
    found: set[str] = set()

    for node in ast.walk(ast.parse(script.read_text())):
        if isinstance(node, ast.Import):
            found |= {alias.name.split(".")[0] for alias in node.names}
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            found.add(node.module.split(".")[0])

    return found


def test_the_script_imports_only_what_it_ships_with_or_the_standard_library():
    """ENVX2: every name `board.py` imports is one a clean `uv run` will have.

    Three categories, and each is read from something rather than listed here: the interpreter's own
    `stdlib_module_names`, the modules shipped beside the script, and the distributions the inline
    block provisions. An import outside all three works on the harness — which has a `pyproject.toml`
    and a `.venv` — and fails on the first run of the file as it is distributed.
    """
    shipped = {module.stem for module in BOARD_DIR.glob("*.py")}
    brought = provisioned(inline_dependencies(BOARD_DIR / "board.py"))
    packaged = {
        module
        for module, distributions in metadata.packages_distributions().items()
        if any(canonical(name) in brought for name in distributions)
    }

    outside = top_level_imports(BOARD_DIR / "board.py") - sys.stdlib_module_names - shipped - packaged

    assert outside == set(), (
        f"`board.py` imports what a clean run has no way to provide: {sorted(outside)}"
    )


def test_the_import_sweep_finds_a_planted_import_of_something_absent(tmp_path):
    """The control: a name in none of the three categories has to be reported.

    Without it the assertion above is satisfied by a sweep that returns nothing whatever the file
    says — and the sweep is the half most easily broken, because an `ast` walk that misses a node
    kind reports an empty difference rather than an error.
    """
    planted = tmp_path / "planted.py"
    planted.write_text("import json\nfrom nowhere.at_all import something\n")

    assert top_level_imports(planted) == {"json", "nowhere"}


def test_the_markdown_renderer_imports_and_neither_dependency_list_names_it():
    """The renderer epic 4 builds on, and the reason it costs nothing to reach for.

    Rich arrives with Textual, so the board already has a markdown renderer and a console to
    measure with. The second half is what makes that worth asserting: a package added to either
    list would be a new thing to provision on a clean run, and the two lists are asserted equal
    elsewhere, so this is checked on both rather than on whichever one happened to be edited.
    """
    from rich.markdown import Markdown

    assert Markdown("# a heading") is not None

    named = {
        requirement_name(requirement)
        for requirement in inline_dependencies(BOARD_DIR / "board.py")
        + tomllib.loads((BOARD_DIR / "pyproject.toml").read_text())["project"]["dependencies"]
    }

    assert "rich" not in named, (
        f"the renderer was added as a dependency rather than taken from Textual's: {sorted(named)}"
    )


def test_the_python_floor_is_stated_once_and_agrees_with_itself():
    """The checkable half of the `target` criterion — what the board *asks* for, not what it got.

    Whether the deployment host meets the floor is not decidable here and is deliberately not
    attempted: confirming "3.11 or later" on a machine running 3.11 is the false pass `target`
    exists to stop. What this environment can settle is that the two places the board states the
    floor have not drifted, since `uv run board.py` reads the inline block and `uv run pytest`
    reads `pyproject.toml`, and a disagreement provisions two different interpreters.
    """
    script = [
        line.removeprefix("#").strip()
        for line in (BOARD_DIR / "board.py").read_text().splitlines()
        if line.startswith("# requires-python")
    ]
    harness = tomllib.loads((BOARD_DIR / "pyproject.toml").read_text())["project"]["requires-python"]

    assert script == [f'requires-python = "{harness}"'], (
        f"the inline block and the harness ask for different interpreters: {script} and {harness}"
    )


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
