"""Story 5 — the parity check itself, and what it does when it cannot work (FR19).

Stories 1, 3 and 4 use the check. This is the story that asks whether the check is worth using, and
the questions are not the ones a passing test answers. A comparison between two files can be green
because the two agree, because the second file was never opened, because the wrong second file was
opened, or because the comparison was written as something that cannot fail. Each of those is asked
here, and three of them are asked by breaking something deliberately and reading what comes back.

**The real check is driven, not re-implemented.** The mutation and equality tests import
`test_keys`' own parity test and run it against a substituted binding table, so what they exercise
is the assertion that runs in the suite rather than a second copy of its reasoning that could agree
with the criteria while the real one had stopped working.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from shutil import copytree

import pytest
from test_keys import test_no_key_the_cpm_board_binds_does_something_else_here as parity_check

import key_maps
from board import BoardApp

#: The board's own directory, and the modules a run of it needs. Copied rather than referenced, so
#: the copy can be put somewhere with no cpm tree above it.
BOARD = Path(__file__).resolve().parents[1]

#: A board driven with no cpm tree in reach: it starts, paints its Projects column, and answers a
#: key. Printed as three lines this test reads back, because a subprocess has no assertions to
#: report — an exit code alone would not distinguish a board that painted nothing from one that
#: painted everything and then failed to quit.
DRIVE = """
import asyncio, sys
sys.path.insert(0, ".")

from pathlib import Path

from board import BoardApp
from board_view import EpicView, ProjectView

rows = [ProjectView("solo", Path("/solo"), epics=(EpicView("e", "An epic", "in_progress"),))]

async def main():
    app = BoardApp(rows)

    async with app.run_test(size=(120, 40)) as pilot:
        await pilot.pause()

        column = app.screen.query_one("#projects")
        painted = [strip.text.strip() for strip in column.render_lines(column.region.reset_offset)]

        print("PAINTED", [row for row in painted if row])

        await pilot.press("right")
        await pilot.pause()

        print("FOCUS", app.focused.id)

    print("STOPPED")

asyncio.run(main())
"""


def bound(**changes: str) -> list[tuple[str, ...]]:
    """This board's bindings with ``changes`` applied as ``{key: action}``, replacing or adding."""
    kept = [binding for binding in BoardApp.BINDINGS if binding[0] not in changes]

    return kept + [(key, action, action.replace("_", " ").capitalize()) for key, action in changes.items()]


def test_a_binding_that_takes_a_cpm_key_makes_the_check_fail_and_name_the_key(monkeypatch):
    """Criterion 1 [integration]. The mutation is run, and what it says is read.

    The mutation is `x`, which the CPM board unregisters a project with — the worst kind of
    collision, since a user reaching for it has already decided to remove something. Pointed at
    `quit` here, so a board that took the mutation would close instead.

    **Read for the key, not merely for red.** A control that only checks the test failed is passed
    by an import error, and a parity check that failed for the wrong reason has not been shown to
    work — it has been shown to be fragile.
    """
    monkeypatch.setattr(BoardApp, "BINDINGS", bound(x="quit"))

    with pytest.raises(AssertionError) as raised:
        parity_check()

    said = str(raised.value)

    assert "`x`" in said, f"the failure did not name the key that collided: {said}"
    assert "remove_project" in said and "quit" in said, (
        f"the failure named the key without saying what each board does with it: {said}"
    )


def test_a_new_capability_on_a_key_cpm_leaves_alone_keeps_the_check_passing(monkeypatch):
    """Criterion 5, the must-NOT [integration]. The check is a rejection, not an equality.

    Written as an equality between the two maps, the check would fail the first time either board
    legitimately grew a key — and a check that fails for doing the right thing is one somebody
    silences. So a dpm-only capability on a key CPM does not bind has to leave it green, and this
    is the test that says so.

    `ctrl+y` because CPM binds neither it nor any modified key at all.
    """
    monkeypatch.setattr(BoardApp, "BINDINGS", bound(**{"ctrl+y": "clear_cache"}))

    parity_check()


def test_an_unreadable_cpm_tree_fails_the_check_rather_than_skipping_it(monkeypatch, tmp_path):
    """Criterion 2 [integration]. The absent-tree case, produced rather than reasoned about.

    A skip is the tempting behaviour and the wrong one: it reads afterwards as a check that ran, and
    a project where the cpm tree has moved would go on reporting parity between one board and no
    board. So the reader asserts, and the assertion names the path it wanted.
    """
    monkeypatch.setattr(key_maps, "CPM_BOARD", tmp_path / "gone" / "board.py")

    with pytest.raises(AssertionError) as raised:
        parity_check()

    said = str(raised.value)

    assert str(tmp_path / "gone" / "board.py") in said, (
        f"the failure did not name what it could not read: {said}"
    )


def test_the_reader_refuses_an_installed_copy_and_names_it(monkeypatch):
    """Criterion 6, the must-NOT [integration] — with the plant, since the real path is not one.

    The reader looks at a path built from this file's own location, so over an ordinary checkout it
    can never reach a cache and a test asserting "it did not" passes against a reader with no such
    rule. Planting a cache-shaped path is what tells a refusal from an absence of opportunity.
    """
    monkeypatch.setattr(
        key_maps,
        "CPM_BOARD",
        Path.home() / ".claude" / "plugins" / "cache" / "m" / "cpm" / "tools" / "board" / "board.py",
    )

    with pytest.raises(AssertionError, match="plugins/cache"):
        parity_check()


def test_the_cpm_board_is_where_the_reader_looks_for_it(monkeypatch, tmp_path):
    """Criterion 3 [integration]. The path holds, and holds from wherever the suite was started.

    Derived from this file's location rather than from the working directory, which is what makes
    the second half true — so the check is run again after moving somewhere else entirely, and the
    answer has to be the same file.
    """
    assert key_maps.CPM_BOARD.is_file(), f"no cpm board at {key_maps.CPM_BOARD}"
    assert key_maps.CPM_BOARD == key_maps.MARKETPLACE / "cpm" / "tools" / "board" / "board.py"
    assert (key_maps.MARKETPLACE / ".git").exists(), (
        f"{key_maps.MARKETPLACE} is not a checkout, so the reader is not reading repository source"
    )

    from_here = key_maps.cpm_bindings()

    monkeypatch.chdir(tmp_path)

    assert key_maps.cpm_bindings() == from_here, "the reader's answer depends on the working directory"


def test_the_board_runs_with_no_cpm_tree_anywhere_on_its_path(tmp_path):
    """Criterion 4 [feature]. A copy of the board with no cpm sibling, started and driven.

    In a subprocess and from a copied tree, because that is the only way to ask the question: this
    process has already imported the board from a checkout that *does* have a cpm tree beside it,
    and no assertion made in here can distinguish a board that never reaches sideways from one that
    reached sideways and found what it wanted.

    Driven rather than merely imported. An import that succeeds says the module has no cpm import at
    the top; the board could still reach for one on the first keystroke, which is the moment a user
    would meet it.
    """
    alone = tmp_path / "board"
    copytree(BOARD, alone, ignore=lambda *_: {"tests", "__pycache__", ".venv"})

    for parent in [alone, *alone.parents]:
        assert not (parent / "cpm").exists(), f"a cpm tree is in reach at {parent / 'cpm'}"

    script = alone / "drive.py"
    script.write_text(DRIVE)

    finished = subprocess.run(
        [sys.executable, str(script)], cwd=alone, capture_output=True, text=True, timeout=120
    )

    assert finished.returncode == 0, f"the board would not run alone:\n{finished.stderr}"
    assert "solo" in finished.stdout, f"the board started and painted nothing: {finished.stdout}"
    assert "FOCUS epics" in finished.stdout, f"the board did not answer a key: {finished.stdout}"
    assert "STOPPED" in finished.stdout, f"the board did not shut down cleanly: {finished.stdout}"
