"""Story 1, criterion 3 — the three operations reached from the command line (FR1).

Driven by spawning `board.py` the way a user runs it, rather than by calling `run_cli` in-process.
Two things are being checked at once and only the spawn checks both: that the subcommands are wired,
and that the file is *runnable* — the PEP 723 header, the `registry` import resolving from the
script's own directory, and the shebang's `uv run --script`. An in-process call would pass on a
script that cannot start.

FR1's TUI directory picker is not here. It needs an app to open in and belongs to 48-04; this is the
CLI half, and FR1 is covered only when both are done.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from conftest import files_under

BOARD = Path(__file__).resolve().parent.parent / "board.py"


def run(sandbox, *args: str) -> subprocess.CompletedProcess:
    """`board.py` as a user runs it, with every write path pointed at the test's own directories."""
    return subprocess.run(
        [sys.executable, str(BOARD), *args],
        cwd=sandbox.cwd,
        env={**os.environ, **sandbox.env()},
        capture_output=True,
        text=True,
    )


def test_add_list_and_remove_are_all_reachable_from_the_command_line(sandbox, project):
    root = project()

    added = run(sandbox, "add", str(root), "--label", "The one")

    assert added.returncode == 0, added.stderr
    assert str(root) in added.stdout

    listed = run(sandbox, "list")

    assert listed.returncode == 0, listed.stderr
    assert str(root) in listed.stdout
    assert "The one" in listed.stdout

    removed = run(sandbox, "remove", str(root))

    assert removed.returncode == 0, removed.stderr
    assert run(sandbox, "list").stdout.strip() == "", "the removed project is still listed"


def test_add_refuses_a_path_that_is_not_a_dpm_project_and_names_what_was_missing(sandbox, project):
    bare = project("bare", database=False)

    refused = run(sandbox, "add", str(bare))

    # The failure text, not merely a non-zero exit: the usual cause is a directory that is plainly a
    # project of some kind, and the user's next question is which file the board wanted.
    assert refused.returncode != 0, "a directory with no database was accepted"
    assert str(bare / ".dpm" / "dpm.db") in refused.stderr, (
        f"the refusal does not name what was missing: {refused.stderr!r}"
    )
    assert refused.stdout.strip() == "", "the refusal was reported on stdout"

    # And the refusal is a refusal: nothing was registered, so a later `list` is still empty.
    assert run(sandbox, "list").stdout.strip() == ""


def test_a_missing_directory_is_refused_by_its_own_path(sandbox, tmp_path):
    absent = tmp_path / "never-existed"

    refused = run(sandbox, "add", str(absent))

    assert refused.returncode != 0
    assert str(absent) in refused.stderr


def test_the_command_line_writes_only_under_the_xdg_config_directory(sandbox, project):
    """The must-NOT again, from outside the process this time.

    The unit form of this assertion holds over a `monkeypatch`ed environment; a spawned board
    resolves its own paths from a real one, which is the only way to catch a resolution that works
    when the variable is patched in-process and not when it is inherited.
    """
    root = project()

    run(sandbox, "add", str(root))
    run(sandbox, "list")
    run(sandbox, "remove", str(root))

    assert files_under(sandbox.config) == {str(Path("dpm-board") / "registry.json")}
    assert files_under(sandbox.home) == set(), "the board wrote into the home directory"
    assert files_under(sandbox.cwd) == set(), "the board wrote into the directory it was run from"
