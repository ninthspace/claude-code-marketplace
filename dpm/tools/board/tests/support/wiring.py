"""The registry injections a driven board needs, pointed somewhere a test owns.

The board holds no registry file of its own — every route to one is injected — and the reason is at
its sharpest here: these tests register and unregister projects by pressing keys, and a default
would have them editing the user's own board. So the file is always the test's, and it is passed in
rather than defaulted, because a helper that picked one would be the default this exists to avoid.

Shared because two suites drive the same four injections: 48-05's picker tests and FR19's key-map
tests. Written twice they agree until one of them gains an argument.
"""

from __future__ import annotations

from pathlib import Path

from board import registry_views
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
