"""Story 2 — one unreadable project never takes the board down (NFR2, FR11).

Story 1 asked what each failure *renders as*, one project at a time. This asks what happens to the
projects beside it, which is a different property and the one a board is worth having for: a user
with a dozen registered projects has, on any given day, at least one that has been renamed, or
holds a database from a newer plugin, or is on a machine with the wrong Node. A board that reported
nothing at all on those days would be a board nobody opened.

**The healthy project is registered last, behind all four failures.** A board that stopped at the
first project it could not read would pass a containment test written the other way round, and it
would fail for real on the registry a user actually has. The same reasoning is why the assertion on
that project is its *real* figures and its own epics rather than the presence of a row: a project
rendered as `server-failed` is also a project that rendered, and it is the wrong answer arriving
quietly.

**All four conditions are in one registry, which is what makes the node stub here dispatch on the
project root** (see ``support/failures.py``). `node` belongs to the pool rather than to the project,
so a registry holding both a healthy project and one whose Node is below dpm's floor cannot be built
by configuring the pool — and one failure kind per board session would leave exactly the containment
paths that differ untested, since an absent database is caught before anything is spawned and a
server that dies mid-handshake is not.
"""

from __future__ import annotations

import asyncio
import io
from pathlib import Path
from shutil import copytree, which

import pytest
from failures import ahead, per_project_node
from fixture_database import CONTENT, titles
from pilot import board, lines, until

from board import registry_views, run_cli, survey_project
from board_view import ProjectView
from mcp_client import (
    NO_DATABASE,
    NODE_TOO_OLD,
    REMEDIES,
    SCHEMA_AHEAD,
    SERVER_FAILED,
    ServerPool,
    server_path,
)
from registry import RegistryEntry, add_project
from status_model import RETIRED

#: How long the mixed registry is given to settle. Longer than :func:`until`'s own default because
#: five projects are read at once and two of them spawn a real server and complete a handshake.
SETTLE = 30.0


def copy_of(built: Path, root: Path) -> Path:
    """A private copy of the built fixture at ``root`` — one per project that needs its own."""
    copytree(built, root)

    return root


def expected_progress() -> str:
    """The healthy project's real figure, derived from the fixture's own definition.

    Derived rather than written down for the reason every count in this suite is: a fixture that
    grows a story would otherwise turn this into a test of a stale number, and it would fail in a
    way that reads as the board mis-counting.

    **A retired story leaves the denominator**, which is `progress`'s rule and has to be stated
    here too — over the fixture's own definition rather than by calling the derivation, which would
    make this an assertion about nothing. Written the other way, a fixture holding a withdrawn
    story reports the board mis-counting when what changed was the expectation.
    """
    stories = [
        arguments
        for call, arguments, _ in CONTENT
        if call == "create_story" and arguments.get("status") not in RETIRED
    ]
    done = sum(1 for arguments in stories if arguments.get("status") == "complete")

    return f"{done}/{len(stories)}"


def rows_by_name(app) -> dict[str, str]:
    """What the Projects column painted, keyed on the project each row is about.

    Read from the rendered strips like everything else here: a row the board holds and does not
    paint is a project nobody is told about, which is the same nothing as one it never read.
    """
    return {row.split("·")[0].strip(): row for row in lines(app, "projects")}


def unreadable_row(name: str, state: str) -> str:
    """The whole row a project in ``state`` should paint — the state *and* its remedy (FR11)."""
    return f"{name}  ·  {state}: {REMEDIES[state]}"


class Unanticipated:
    """A pool whose reads fail in a way this board has no state for.

    Every failure Story 1 named is one the board went looking for. This is the other kind — a
    permission error on the database, a `node` that is not on `PATH` at all, a bug in the board
    itself — and the whole of NFR2 is that it lands in one row rather than in the worker it was
    raised in. Raised from ``read`` rather than injected as a survey, so what is exercised is
    :func:`survey_project`'s own containment and not a stand-in for it.
    """

    def __init__(self, failure: BaseException) -> None:
        self._failure = failure

    async def read(self, *_arguments, **_keywords):
        raise self._failure

    async def __aenter__(self) -> "Unanticipated":
        return self

    async def __aexit__(self, *_exception) -> None:
        return None


async def test_every_failure_state_renders_beside_a_healthy_project(
    built_fixture, project, tmp_path
):
    """Criteria 1, 2 and 3 together: four failures in one registry, and the healthy project intact.

    The four are produced rather than simulated — a directory with no database, a real database
    carrying a version row above the server's, dpm's own floor refusal, and a server that exits
    before it speaks — so what is contained here is what a user's machine actually produces.
    """
    if which("node") is None:
        pytest.skip("no node on PATH to spawn a real server or build dpm's refusal from")

    healthy = copy_of(built_fixture, tmp_path / "healthy")
    skewed = ahead(copy_of(built_fixture, tmp_path / "ahead"))
    bare = project("bare", database=False)
    old, dead = project("old"), project("dead")

    # Healthy last, behind every failure — see this module's docstring.
    roots = [bare, skewed, old, dead, healthy]
    entries = [RegistryEntry(str(root)) for root in roots]
    node = per_project_node(tmp_path, refusing=old, dying=dead)

    async with ServerPool(server_path(), node=str(node)) as pool:
        async with board(
            registry_views(entries),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
        ) as (app, pilot):
            settled = await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )
            rows = rows_by_name(app)

            # The cursor onto the healthy project, so its own epics have to have arrived rather
            # than merely a figure on its row. Driven with the keyboard because that is how a user
            # reaches it — past four rows the board could not read.
            await pilot.press(*["down"] * (len(roots) - 1))

            epics = [row.split("·")[0].strip() for row in lines(app, "epics")]

    assert settled, f"a project never finished being read: {rows}"
    assert set(rows) == {root.name for root in roots}, f"a project has no row at all: {rows}"

    assert rows["bare"] == unreadable_row("bare", NO_DATABASE), rows["bare"]
    assert rows["ahead"] == unreadable_row("ahead", SCHEMA_AHEAD), rows["ahead"]
    assert rows["old"] == unreadable_row("old", NODE_TOO_OLD), rows["old"]
    assert rows["dead"] == unreadable_row("dead", SERVER_FAILED), rows["dead"]

    # The discriminator: the healthy project renders what it *holds*, not merely a row. Its figure
    # and its epics both, because either alone is reachable by a board that read half of it.
    assert rows["healthy"] == f"healthy  ·  {expected_progress()}", rows["healthy"]
    assert set(epics) == set(titles("create_epic")), (
        f"the healthy project's epics did not render behind four failures: {epics}"
    )


async def test_a_failure_with_no_named_state_is_contained_to_its_own_row(project):
    """The catch-all arm, which the four named states do not reach (NFR2).

    Every failure the tests above produce is one the pool classifies. This is the arm underneath
    them, and it is the one that decides whether an unforeseen failure is a row or a traceback out
    of a worker with no screen to land on.
    """
    view = await survey_project(
        Unanticipated(MemoryError("the machine ran out of memory")),
        ProjectView(name="boom", path=project("boom"), pending=True),
    )

    assert view.unreadable == SERVER_FAILED, f"an unforeseen failure became {view.unreadable!r}"
    assert view.remedy == REMEDIES[SERVER_FAILED], "the row names a state with no remedy"
    assert not view.pending, "the row went on saying it was still being read"


async def test_a_cancelled_survey_is_not_a_project_that_failed(project):
    """A cancellation is the board shutting down, and the containment arm has to let it through.

    What this holds is the *width* of the catch-all above: ``Exception`` lets a cancellation past
    and ``BaseException`` — the reflexive way to write "contain everything" — swallows it, leaving
    the project rendered as broken while the app closes over it and a worker the loop is still
    waiting on. The two widths are indistinguishable in every other test here.
    """
    with pytest.raises(asyncio.CancelledError):
        await survey_project(
            Unanticipated(asyncio.CancelledError()),
            ProjectView(name="going", path=project("going"), pending=True),
        )


def test_the_listing_contains_a_failure_it_has_no_state_for(tmp_path, project):
    """The same containment on the CLI's path, where the row has room to name the cause.

    `list` walks the registry in one loop, so an escape there reports nothing about the projects it
    had already read *and* nothing about the ones it had not reached — and the detail is asserted
    because a terminal row is the only place the board shows what actually went wrong.
    """
    registry_file = tmp_path / "registry.json"
    out, err = io.StringIO(), io.StringIO()

    for name in ("first", "second"):
        add_project(str(project(name)), None, registry_file=registry_file)

    code = run_cli(
        ["list"],
        registry_file=registry_file,
        out=out,
        err=err,
        make_pool=lambda: Unanticipated(MemoryError("the machine ran out of memory")),
    )
    rows = [row for row in out.getvalue().splitlines() if row.strip()]

    assert code == 0, err.getvalue()
    assert len(rows) == 2, f"one project's row is missing: {out.getvalue()}"
    assert all(SERVER_FAILED in row for row in rows), rows
    assert all("MemoryError: the machine ran out of memory" in row for row in rows), (
        f"the row does not say what actually went wrong: {rows}"
    )
