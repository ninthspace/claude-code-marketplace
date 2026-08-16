"""The registry injections a driven board needs, pointed somewhere a test owns.

The board holds no registry file of its own — every route to one is injected — and the reason is at
its sharpest here: these tests register and unregister projects by pressing keys, and a default
would have them editing the user's own board. So the file is always the test's, and it is passed in
rather than defaulted, because a helper that picked one would be the default this exists to avoid.

Shared because three suites drive the same injections: 48-05's picker tests and FR19's key-map and
extras tests. Written three times they agree until one of them gains an argument.
"""

from __future__ import annotations

from dataclasses import replace
from pathlib import Path

from board import registry_views
from board_view import ProjectView
from registry import add_project, list_projects, remove_project


def registry_wiring(file: Path, *, picker_root: Path | None = None) -> dict:
    """``reload``, ``register``, ``unregister`` and ``picker_root``, all reaching ``file``.

    ``reload`` re-reads the file each time it is called rather than closing over a list, which is
    what a refresh is for: a project registered since the board opened has to appear, and one
    unregistered elsewhere has to go.
    """
    return {
        "picker_root": picker_root or file.parent,
        "reload": lambda: registry_views(list_projects(registry_file=file)),
        "register": lambda path: add_project(str(path), None, registry_file=file),
        "unregister": lambda path: remove_project(str(path), registry_file=file),
    }


def surveyed(record: list):
    """A survey that reads nothing and records ``(path, fresh)`` for every project it was asked about.

    The real one spawns a server per project. What the key criteria are about is *which rows the
    board asked for, and whether it asked for them fresh* — both of which are arguments this
    receives — so a survey that answered honestly would add a subprocess per assertion and tell
    them nothing they do not already have.
    """
    async def survey(project: ProjectView, *, fresh: bool = False) -> ProjectView:
        record.append((project.path, fresh))

        return replace(project, pending=False)

    return survey


def registered(tmp_path: Path, *paths: Path) -> tuple[list[ProjectView], dict, Path]:
    """A registry already holding ``paths``: its rows, the injections, and the file itself.

    The rows are handed to the board as its opening state rather than left to be reloaded, because
    that is how the real launch does it — `reload` is what a *refresh* reaches for, and a board
    that had to call it to show anything would make a refresh test pass on the mount.

    The registry file is this test's own, which matters more here than anywhere: these tests
    unregister a project by pressing a key, and the one thing worse than a failing test is one that
    passes after removing somebody's project from their board.
    """
    file = tmp_path / "registry.json"
    injections = registry_wiring(file)

    for path in paths:
        injections["register"](path)

    return injections["reload"](), injections, file
