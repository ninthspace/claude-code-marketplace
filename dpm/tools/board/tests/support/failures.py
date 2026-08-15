"""Producing each of FR11's failure conditions, rather than simulating them.

Here rather than inside one test module because two stories need the same producers: Story 1 asserts
that each condition renders as a distinct named state, and Story 2 that all four of them contain to
their own rows in a registry that also holds a healthy project. A second copy of any of these would
be a second definition of what "a Node below the floor" *is*, and the two would agree only until one
of them was edited.

**Nothing here writes a message the board then classifies.** The schema-ahead case is a real dpm
database with a version row above the server's, read by the real ``bin/dpm-mcp.js``; the Node floor
is dpm's own ``assertNodeFloor`` refusing, so the refusal text is the one dpm actually writes. A
transcribed copy of either would go on passing for exactly as long as it took someone to reword the
original — which is the only circumstance under which the board's classification is wrong.
"""

from __future__ import annotations

import re
import shlex
import sqlite3
from pathlib import Path
from shutil import which

from conftest import DPM_ROOT

#: A schema version no dpm will ever have migrated to, so `migrated.ahead` is unambiguous.
FUTURE_VERSION = 9999

#: The Node the floor refusal is written against — below :func:`floor_version` by construction.
BELOW_THE_FLOOR = "20.0.0"


def ahead(root: Path) -> Path:
    """Put a schema version above the server's into a real dpm database.

    A row rather than a rewritten file: `migrate.js` reads `max(version)` from `schema_version`, so
    one insert is the whole of "this database came from a newer plugin" as far as the server is
    concerned — and everything else about the database stays real, which is what makes the read
    that follows a real read.
    """
    with sqlite3.connect(root / ".dpm" / "dpm.db") as connection:
        connection.execute(
            "INSERT INTO schema_version (version, applied_at) VALUES (?, datetime('now'))",
            (FUTURE_VERSION,),
        )

    return root


def exiting_server(tmp_path: Path) -> Path:
    """A server that writes nothing anyone can classify and exits before the handshake."""
    stub = tmp_path / "exits-at-once.py"
    stub.write_text("import sys\nsys.stderr.write('stopped\\n')\nsys.exit(1)\n")

    return stub


def floor_version() -> str:
    """dpm's Node floor, read from dpm's source — the version its refusal has to name.

    Read rather than written down for the same reason the refusal itself is generated: a number
    copied here agrees with dpm on the day it is copied, and a floor that moves is exactly when
    an assertion about the refusal should have something to say.
    """
    source = (DPM_ROOT / "src" / "server" / "node-floor.js").read_text()
    found = re.search(r"REQUIRED_NODE\s*=\s*'([^']+)'", source)

    return found.group(1) if found else ""


def floor_script() -> str:
    """A one-liner that makes dpm refuse the running Node, and writes dpm's own sentence.

    **The refusal comes from `src/server/node-floor.js`, not from this file.** What the board is
    held to is that it classifies dpm's message; a copy of that message here would classify itself.
    """
    floor = DPM_ROOT / "src" / "server" / "node-floor.js"

    return (
        f"import {{ assertNodeFloor }} from {str(floor)!r};"
        f"try {{ assertNodeFloor({BELOW_THE_FLOOR!r}); }} catch (error) {{"
        "  process.stderr.write(error.message + '\\n'); process.exit(1); }"
    )


def _shell(body: str, tmp_path: Path, name: str) -> Path:
    """Write an executable `/bin/sh` stub and hand back its path."""
    stub = tmp_path / name
    stub.write_text(f"#!/bin/sh\n{body}")
    stub.chmod(0o755)

    return stub


def _real_node() -> str:
    """The Node on `PATH`, quoted for a shell.

    Quoted because a real node is routinely installed under a path with a space in it, and an
    unquoted one fails as "no such file" — which is a *different* refusal, and one a test about the
    board classifying a refusal would have read as a pass.
    """
    return shlex.quote(which("node") or "")


def old_node(tmp_path: Path) -> Path:
    """A ``node`` that refuses the way dpm refuses below its floor, for every project (ENV2)."""
    return _shell(
        f"exec {_real_node()} --input-type=module -e {shlex.quote(floor_script())}\n",
        tmp_path,
        "old-node",
    )


def per_project_node(tmp_path: Path, *, refusing: Path, dying: Path) -> Path:
    """A ``node`` that fails differently depending on which project it was launched in.

    **This exists because ``node`` belongs to the pool and not to the project.** One board session
    has one server executable and one interpreter for every row in the registry, so a registry
    holding a healthy project *and* a project whose Node is below the floor cannot be built by
    configuring the pool — and "each of the four states in a mixed registry" is what the criterion
    asks for. The dispatch is on the working directory the pool spawns in, which is the project
    root, so what varies per project is the environment rather than anything about the board.

    ``refusing`` gets dpm's own floor refusal (ENV2); ``dying`` gets a server that exits before it
    speaks. Every other project gets the real Node and therefore the real server.

    The patterns are quoted parameter expansions, which a shell matches literally — an unquoted
    pattern is a glob, and a temporary directory is not somewhere to assume the absence of one.
    """
    real = _real_node()

    return _shell(
        f"refusing={shlex.quote(str(refusing.resolve()))}\n"
        f"dying={shlex.quote(str(dying.resolve()))}\n"
        'case "$(pwd -P)" in\n'
        f'"$refusing") exec {real} --input-type=module -e {shlex.quote(floor_script())} ;;\n'
        '"$dying") echo \'stopped before it said anything\' >&2; exit 1 ;;\n'
        "esac\n"
        f'exec {real} "$@"\n',
        tmp_path,
        "dispatching-node",
    )
