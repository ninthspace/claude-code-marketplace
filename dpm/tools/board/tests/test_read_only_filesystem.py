"""Story 4 — a project the board cannot write to is an ordinary project (ENVX3).

**Deliberately test-only.** If this story needs a line of production code, then 48-01's read-only
server or Story 3's non-mutation is wrong, and finding that out is the point of running it.

The second criterion is the one that discriminates, and it is why both halves of every assertion
here are *comparisons against a writable copy of the same fixture* rather than checks that something
rendered. "Renders its state without error" is equally true of a project rendered as `server-failed`
with a remedy beside it — which is the wrong answer arriving quietly, and the exact failure a board
that needed to write somewhere would produce.
"""

from __future__ import annotations

import stat
from pathlib import Path
from shutil import copytree

import pytest
from pilot import board, lines

from board import read_document_preview, read_story_preview, survey_project
from board_view import ProjectView
from mcp_client import ServerPool

#: The write bits, taken off everything in the project.
WRITABLE = stat.S_IWUSR | stat.S_IWGRP | stat.S_IWOTH


@pytest.fixture
def read_only(built_fixture, tmp_path) -> Path:
    """A copy of the fixture project with every write permission taken off it.

    A permission change rather than a mounted read-only filesystem: a real mount needs privileges
    this suite does not have and a different incantation on every platform, and what the board can
    observe of either is the same — nothing under the project can be created, opened for writing, or
    replaced. The floor below is what keeps that substitution honest.

    Restored on the way out, because a directory with no write bit cannot be cleaned up.
    """
    root = tmp_path / "read-only"
    copytree(built_fixture, root)

    everything = [root, *root.rglob("*")]
    modes = {path: path.stat().st_mode for path in everything}

    for path in everything:
        path.chmod(modes[path] & ~WRITABLE)

    yield root

    for path, mode in modes.items():
        path.chmod(mode)


async def rendered(root: Path, name: str) -> tuple[str, list[str], list[str], str, str]:
    """Everything the board shows about one project: its row, its columns and both previews.

    Read through the same functions the browser reads through, and returned as text rather than as
    view objects, because the criterion is about what a user sees — two projects whose rows differ
    in a field nobody renders are the same project as far as ENVX3 is concerned.

    A project with no rows answers with empty ones rather than raising, so that a project that could
    not be read at all is a *difference* the comparison reports and not a traceback in place of it.
    """
    async with ServerPool() as pool:
        view = await survey_project(pool, ProjectView(name=name, path=root, pending=True))
        epics = list(view.epics)
        stories = [row for epic in epics for row in epic.stories]

        return (
            view.label,
            [row.label for row in epics],
            [row.label for row in stories],
            await read_document_preview(pool, root, epics[0]) if epics else "",
            await read_story_preview(pool, root, stories[0]) if stories else "",
        )


def test_the_project_really_cannot_be_written_to(read_only):
    """The floor. Without it every assertion below holds over an ordinary writable directory.

    Asserted as the operating system refusing, not as a mode bit being set: a suite running as root
    would have the permissions exactly as this fixture left them and write straight through them.
    """
    with pytest.raises((PermissionError, OSError)):
        (read_only / "written-by-the-test").write_text("x")

    with pytest.raises((PermissionError, OSError)):
        (read_only / ".dpm" / "dpm.db").write_bytes(b"")


async def test_a_project_on_a_read_only_filesystem_renders_its_state(read_only):
    """Criterion 1, from the painted row rather than from the view.

    A state the board holds and does not paint is a project the user is told nothing about, and the
    assertion that it is not a failure state is what separates this from "something rendered".
    """
    async with ServerPool() as pool:
        view = await survey_project(pool, ProjectView(name="read-only", path=read_only, pending=True))

    async with board([view]) as (app, _):
        row = next(iter(lines(app, "projects")), "")

    assert view.unreadable is None, f"the project rendered as {view.unreadable!r}"
    assert not view.pending, "the row is still saying it is being read"
    assert row.startswith("read-only  ·  "), f"the row does not name the project: {row!r}"


async def test_it_renders_exactly_as_the_same_project_does_when_writable(read_only, fixture_project):
    """Criterion 2: the read-only filesystem changes nothing the user sees.

    Both sides are copies of the same built fixture, so any difference at all is the filesystem's —
    which is what makes an equality assertion the right shape here rather than a list of properties
    someone thought to check. The previews are included because they are the reads that happen after
    the survey, on a connection the server has held open since the handshake.
    """
    writable = await rendered(fixture_project, "same")
    unwritable = await rendered(read_only, "same")

    assert unwritable[0] == writable[0], "the project's own row differs"
    assert unwritable[1] == writable[1], "the Epics column differs"
    assert unwritable[2] == writable[2], "the Stories column differs"
    assert unwritable[3] == writable[3], "an epic's preview differs"
    assert unwritable[4] == writable[4], "a story's preview differs"
    assert all(writable), "the writable project rendered nothing, so the comparison is vacuous"
