"""Story 1 — the fixture project every later story reads, and what it has to hold.

Two claims, and they fail in opposite directions.

The first is about *coverage*: a fixture holding two of the four statuses lets every rule about the
other two pass by never meeting one. So the states are enumerated from the model's own vocabulary
rather than from a list written here, and a state added to :data:`status_model.EPIC_STATES` fails
this file until the fixture holds a row in it.

The second is about *reach*: building a fixture spawns a real server, and a server writes. The
must-NOT is stated over three roots the test owns rather than over the one it expects — that the
database appeared under the working directory is equally true of a build that also dropped
something in the user's home, and only one of those two facts is worth asserting.
"""

from __future__ import annotations

from pathlib import Path
from textwrap import wrap

from conftest import Sandbox, files_under
from fixture_database import LONG_DOCUMENT, build

from mcp_client import ServerPool, server_path
from status_model import (
    EPICS,
    EPIC_STATES,
    SECTIONS,
    SPECS,
    STORIES,
    blockers,
    dependencies,
    epic_state,
    gating_kinds,
    ready_epic_ids,
    rows,
)

#: The two widths the long document is wrapped at. Far enough apart that a document whose breaks
#: move at all moves them here, and both plausible terminal widths rather than extremes.
NARROW, WIDE = 60, 100


async def states_present(root: Path) -> set[str]:
    """Every state the fixture actually holds, derived over its rows the way the board derives it.

    Epics go through :func:`epic_state`, which is where *blocked* and *in progress* come from —
    neither is a column, so a fixture checked against ``status`` alone could not tell whether it
    held one. Story statuses join them because the criterion is about a row in each state and a
    story is a row: ``pending`` is reachable for a story and, for an epic, only by archiving it out
    of every read the board makes.
    """
    async with ServerPool() as pool:
        epics = await rows(pool, root, EPICS)
        stories = await rows(pool, root, STORIES)
        edges = await dependencies(pool, root)
        gating = await gating_kinds(pool, root)
        ready = await ready_epic_ids(pool, root)

    index = {row["id"]: row for row in epics + stories}
    grouped: dict[str, list[dict]] = {}

    for story in stories:
        grouped.setdefault(story["epic_id"], []).append(story)

    derived = {
        epic_state(
            epic,
            grouped.get(epic["id"], []),
            blockers(epic["id"], edges, gating, index),
            ready,
        )
        for epic in epics
    }

    return derived | {story["status"] for story in stories}


async def test_the_fixture_holds_a_row_in_every_state_the_model_defines(fixture_project):
    """The state-coverage half of criterion 1, over the real server.

    The wrong answer this excludes is a fixture that renders every row the same way. Enumerating
    from :data:`EPIC_STATES` rather than from a list here is what makes it say something: the
    assertion names what is *missing*, so a state the model gains and the fixture never reaches
    fails with the state's own word in the message.
    """
    present = await states_present(fixture_project)
    missing = set(EPIC_STATES) - present

    assert not missing, f"no row in the fixture reaches: {sorted(missing)}"

    assert len(present) > 1, (
        "every row read as one state, so the fixture distinguishes nothing it is here to hold"
    )


async def test_the_fixture_holds_a_document_long_enough_to_render(fixture_project):
    """The other half of criterion 1: the document NFR1's budget is measured on.

    Read back through the server rather than from the module, so what is asserted is what a
    ``list_document_section`` answer actually carries — a body truncated on the way in would be
    invisible to a test comparing the constant with itself.

    **Long is not the property; wrapping is.** A document of ten thousand short lines is as long
    and does none of the work, so the check is that the same text breaks differently at two widths.
    """
    async with ServerPool() as pool:
        specs = await rows(pool, fixture_project, SPECS)
        bodies = [
            section["body"]
            for spec in specs
            for section in await rows(
                pool, fixture_project, SECTIONS, {"document_id": spec["id"], "include_body": True}
            )
        ]

    assert LONG_DOCUMENT in bodies, (
        "the long document did not survive the round trip through the server"
    )

    narrow = wrap(LONG_DOCUMENT, NARROW)
    wide = wrap(LONG_DOCUMENT, WIDE)

    assert len(narrow) != len(wide), (
        f"the document breaks the same way at {NARROW} and {WIDE} columns, so no width changes it"
    )


def outside(sandbox: Sandbox) -> dict[str, set[str]]:
    """What appeared in each root the build was not supposed to touch.

    Returned rather than asserted so the same reading serves both arms below — the run that has to
    find nothing, and the control that has to find the file it planted. A check with no arm that
    fails is not a check.
    """
    return {"config": files_under(sandbox.config), "home": files_under(sandbox.home)}


async def test_the_fixture_build_writes_only_inside_the_directory_the_test_owns(
    sandbox, monkeypatch
):
    """Criterion 2, the must-NOT — stated over the roots a stray write would land in.

    ``XDG_CONFIG_HOME`` and ``HOME`` are pointed at directories this test owns and are then checked
    for being *empty*, which is the only form of this that says anything: asserting the database
    appeared under the working directory is true of a build that wrote there and elsewhere both.
    """
    monkeypatch.setenv("XDG_CONFIG_HOME", str(sandbox.config))
    monkeypatch.setenv("HOME", str(sandbox.home))

    database = await build(sandbox.cwd, server_path())

    assert database.exists(), "the build produced no database, so it wrote nothing to check"
    assert outside(sandbox) == {"config": set(), "home": set()}, (
        f"the build wrote outside the directory it was given: {outside(sandbox)}"
    )
    assert all(path.startswith(".dpm/") for path in files_under(sandbox.cwd)), (
        f"the build wrote outside `.dpm/` in its own root: {files_under(sandbox.cwd)}"
    )


def test_a_write_outside_the_owned_directory_would_be_caught(sandbox):
    """The control for the must-NOT above: the same reading, with the rejected thing planted.

    Without this, the assertion is satisfied by a :func:`outside` that returns two empty sets
    whatever happened — an absence asserted by something with no way to report a presence. Here the
    file is put where a stray write would land and the reading has to name it.
    """
    (sandbox.home / "a-stray-write").write_text("what a build outside its root would leave")

    assert outside(sandbox)["home"] == {"a-stray-write"}, (
        "a file planted in the home root was not reported, so the must-NOT asserts nothing"
    )
