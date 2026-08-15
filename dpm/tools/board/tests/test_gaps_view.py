"""48-08 Story 2 — the coverage-gaps view (FR16, NFR2).

Story 1 derived the answer; this is the half a user can reach. The tests split the way the criteria
do: the fan-out and its containment are `[integration]` against the real servers, because what
counts as a gap depends on rows dpm wrote; the affordance is `[feature]`, driven through the pilot
and asserted on painted strips; and the must-NOT is `[unit]`, because the resolution is a pure
function and the case it forbids cannot be produced from real data at all.

**That last point is the reason the must-NOT is planted rather than observed.** A requirement names
a spec and the Epics column holds epics, so over any real project every gap resolves to nothing —
and a test asserting "document is None" over such a fixture passes equally for a function that
returns ``None`` unconditionally and for one that hard-codes the ``spec_id``. Only a project view
holding a document with the spec's own id can tell those apart, and no fixture has one.
"""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path
from shutil import copytree, which

import pytest
from failures import exiting_server
from fixture_database import build, labelled
from pilot import board, lines, palette, until
from test_containment import Unanticipated

from board import (
    COMMANDS,
    GapsScreen,
    gaps_project,
    gaps_projects,
    registry_views,
    resolve_gaps,
    survey_project,
)
from board_view import EpicView, ProjectView
from mcp_client import ServerPool, server_path
from registry import RegistryEntry

#: How long a fan-out over the real servers is given.
SETTLE = 30.0

#: A project with **no** coverage gaps: one requirement, and a coverage row naming it.
#:
#: Its own content rather than the shared fixture's, because the shared fixture exists to hold both
#: kinds of requirement and a project with none of one kind is what the empty case needs. Kept to
#: the four rows a coverage row requires — a spec, a requirement, a story under an epic, and the
#: criterion the binding's other half is.
FULLY_TRACED = [
    ("create_spec", {"slug": "10-covered-spec", "title": "A spec with nothing outstanding"}, "spec"),
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-01-only", "title": "The only epic"},
        "epic",
    ),
    (
        "create_story",
        {"epic_id": "{epic}", "number": 1, "title": "The only story", "position": 0},
        "story",
    ),
    (
        "create_story_criterion",
        {"story_id": "{story}", "text": "The only criterion", "position": 0},
        "criterion",
    ),
    (
        "create_requirement",
        {"spec_id": "{spec}", "label": "FR1", "class": "functional",
         "text": "The only requirement, and something is written against it.", "position": 0},
        "requirement",
    ),
    (
        "create_coverage",
        {"requirement_id": "{requirement}", "spec_fragment": "something is written against it",
         "story_criterion_id": "{criterion}", "position": 0},
        None,
    ),
]


def needs_node() -> None:
    if which("node") is None:
        pytest.skip("no node on PATH to spawn a real server")


def copy_of(built: Path, destination: Path) -> Path:
    """A private copy of the built fixture — one project the test may register under any name."""
    copytree(built, destination)

    return destination


def views(*roots: Path) -> list:
    """Registry rows for ``roots``, named by their directory, as the board builds them."""
    return registry_views([RegistryEntry(str(root)) for root in roots])


async def surveyed(pool: ServerPool, rows: list) -> list:
    """The same rows, read — a gap resolves against the epics a project is holding."""
    return [await survey_project(pool, row) for row in rows]


async def test_every_registered_project_contributes_its_gaps(built_fixture, tmp_path):
    """Criterion 1's fan-out half [integration]: two projects, one answer, both named.

    Two copies of the same fixture, for the reason FR15's own test gives: identical corpora make
    the projects indistinguishable by their content, so the only thing that can tell the rows apart
    is the field saying where each came from — which is what is being asserted.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")
    beta = copy_of(built_fixture, tmp_path / "beta")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(alpha, beta))
        gaps = await gaps_projects(pool, projects)

    assert gaps, "neither project reported a gap, so this asserts about an empty list"
    assert {gap.name for gap in gaps} == {"alpha", "beta"}, (
        f"the gaps did not come from both projects: {sorted(gap.name for gap in gaps)}"
    )
    assert [gap.name for gap in gaps] == sorted(
        (gap.name for gap in gaps), key=["alpha", "beta"].index
    ), "the rows were ordered by whichever server answered first rather than by the registry"


async def test_each_row_carries_its_project_and_the_requirements_own_label(
    built_fixture, tmp_path
):
    """Criterion 2's first half [integration], at the row.

    The labels are the fixture's two untraced requirements and **not** its traced one, asked for by
    the role each was built to play. A view that listed every requirement would satisfy "carries a
    label" perfectly and be the wrong list.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(alpha))
        gaps = await gaps_projects(pool, projects)

    assert {gap.requirement for gap in gaps} == labelled(
        "untraced_requirement", "orphan_untraced_requirement"
    )
    assert all(gap.project == alpha and gap.name == "alpha" for gap in gaps)
    assert all(gap.name in gap.label and gap.requirement in gap.label for gap in gaps), (
        f"a row a user reads names neither its project nor its requirement: "
        f"{[gap.label for gap in gaps]}"
    )


async def test_the_gaps_come_from_more_than_one_spec(built_fixture, tmp_path):
    """The fixture's two gaps sit under two different specs, and both arrive.

    A derivation scoped to one spec — the shape `dpm:status` uses, ported without widening it —
    would report one of these and drop the other, and the dropped one is exactly the requirement
    under the spec nobody has broken down. That is the gap most worth seeing.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(alpha))
        gaps = await gaps_projects(pool, projects)

    assert len({gap.spec_id for gap in gaps}) == 2, (
        f"the two gaps came back under one spec: {[gap.spec_id for gap in gaps]}"
    )


async def test_a_project_with_nothing_outstanding_contributes_no_rows(
    built_fixture, tmp_path
):
    """Criterion 3's first half [integration]: a fully traced project, beside one that is not.

    **The gapped project is what makes this evidence.** A view that returned nothing at all would
    satisfy "contributes no rows" for the clean project and be broken for every other, and nothing
    about an empty list says which happened.
    """
    needs_node()

    clean = tmp_path / "clean"
    clean.mkdir()
    await build(clean, server_path(), FULLY_TRACED)
    gapped = copy_of(built_fixture, tmp_path / "gapped")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(clean, gapped))
        gaps = await gaps_projects(pool, projects)

    assert gaps, "the gapped project contributed nothing either, so this proves nothing"
    assert {gap.name for gap in gaps} == {"gapped"}, (
        f"a project whose every requirement is traced contributed rows: "
        f"{sorted(gap.name for gap in gaps)}"
    )


async def test_an_empty_answer_reads_differently_from_one_that_has_not_arrived():
    """Criterion 3's second half [feature], on the painted strips.

    The two states are held apart with the read *pending*, which is the only moment they can be
    confused: a screen showing an empty list under the words "no coverage gaps" while twelve
    servers are still being asked has reported a clean bill of health it has no evidence for.

    The gate is an event rather than a sleep, so the pending state is observed rather than raced
    for — the same reason `until` loops instead of sleeping.
    """
    landed = asyncio.Event()

    async def gaps(projects):
        await landed.wait()

        return []

    async with board([ProjectView(name="alpha", path=Path("/alpha"))], gaps=gaps) as (app, pilot):
        await pilot.press("ctrl+g")
        await pilot.pause()

        pending = "\n".join(lines(app, "gaps-state"))

        landed.set()
        await until(pilot, lambda: getattr(app.screen, "results", None) is not None, timeout=5.0)

        answered = "\n".join(lines(app, "gaps-state"))

    assert GapsScreen.RUNNING in pending, f"the screen did not say it was still reading: {pending!r}"
    assert GapsScreen.NOTHING in answered, f"an empty answer did not say so: {answered!r}"
    assert pending != answered, "a board mid-read and a board with nothing to report read the same"


async def test_ctrl_g_opens_the_view_and_the_palette_offers_the_same_action():
    """Criterion 1's reachability half [feature]. Both affordances, and they are the same action.

    A key nobody knows about is not an affordance and a palette-only action costs two keystrokes
    forever, which is the board's own rule for `register` and `search`. Asserted from the palette's
    painted rows rather than from `COMMANDS`, because the provider is what a user meets.
    """
    async def gaps(projects):
        return []

    async with board([ProjectView(name="alpha", path=Path("/alpha"))], gaps=gaps) as (app, pilot):
        await pilot.press("ctrl+g")
        await pilot.pause()

        opened = isinstance(app.screen, GapsScreen)

        await pilot.press("escape")
        await pilot.pause()
        await pilot.press("ctrl+p")
        await pilot.pause()

        offered = palette(app)

    assert opened, "ctrl+g did not open the coverage-gaps screen"

    entry = next(command for command in COMMANDS if command.action == "coverage_gaps")

    assert any(entry.name in row for row in offered), (
        f"the palette does not offer the coverage-gaps entry: {offered}"
    )


async def test_choosing_a_gap_moves_the_columns_to_its_project(built_fixture, tmp_path):
    """Criterion 2's second half [integration], driven the way a user reaches it.

    The gap chosen is the second project's, so a board that did nothing with the selection leaves
    the cursor on the first and fails. The assertion is on the painted rows, because a selection the
    app recorded and did not paint has moved nothing anyone can see.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")
    beta = copy_of(built_fixture, tmp_path / "beta")

    async with ServerPool() as pool:
        async with board(
            views(alpha, beta),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
            gaps=lambda projects: gaps_projects(pool, projects),
        ) as (app, pilot):
            await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )

            await pilot.press("ctrl+g")
            await pilot.pause()
            await until(
                pilot, lambda: getattr(app.screen, "results", None), timeout=SETTLE
            )

            found = app.screen.results
            chosen = next(index for index, row in enumerate(found) if row.name == "beta")

            await pilot.press(*["down"] * chosen)
            await pilot.press("enter")
            await pilot.pause()
            await pilot.pause()

            landed = app.selection.current_project
            painted = lines(app, "projects")

    assert landed is not None and landed.name == "beta", (
        f"choosing beta's gap left the cursor on {landed and landed.name}"
    )
    assert painted, "the columns painted nothing after the screen closed"


async def test_a_project_whose_server_cannot_start_stops_none_of_the_others(
    built_fixture, tmp_path
):
    """Criterion 4 [integration]. The dead project is **first** in the registry.

    A fan-out that stopped at the first failure would return nothing at all, and the assertion is on
    the healthy project's own rows rather than on the call completing — a fan-out that swallowed
    every project returns an empty list without raising and would pass the weaker claim while
    failing this requirement outright.
    """
    needs_node()

    dead = tmp_path / "dead"
    (dead / ".dpm").mkdir(parents=True)
    (dead / ".dpm" / "dpm.db").write_bytes(b"not a database")
    healthy = copy_of(built_fixture, tmp_path / "healthy")

    async with ServerPool(exiting_server(tmp_path), node=sys.executable) as broken:
        async with ServerPool() as pool:
            rows = views(dead, healthy)
            projects = [await survey_project(broken, rows[0]), await survey_project(pool, rows[1])]
            gaps = await gaps_projects(pool, projects)

    assert projects[0].unreadable is not None, "the dead project rendered as readable after all"
    assert gaps, "one dead server took the whole fan-out down with it"
    assert {gap.name for gap in gaps} == {"healthy"}, (
        f"the dead project contributed rows: {sorted(gap.name for gap in gaps)}"
    )


async def test_an_unforeseen_failure_costs_one_project_its_rows_and_no_more(project):
    """NFR2's arm itself: a failure nothing here has a signature for is this project's alone."""
    found = await gaps_project(
        Unanticipated(MemoryError("the machine ran out of memory")),
        ProjectView(name="boom", path=project("boom")),
    )

    assert found == [], f"an unforeseen failure produced rows anyway: {found}"


async def test_a_cancelled_read_is_not_a_project_with_no_gaps(project):
    """The *width* of that arm, which every other test here is blind to.

    A cancellation is the board shutting the screen. ``BaseException`` — the reflexive way to write
    "contain everything" — would swallow it and answer with an empty list, so the project appears
    to have nothing outstanding in a list the user may still be reading.
    """
    with pytest.raises(asyncio.CancelledError):
        await gaps_project(
            Unanticipated(asyncio.CancelledError()),
            ProjectView(name="boom", path=project("boom")),
        )


def test_a_gap_names_no_document_the_epics_column_does_not_hold():
    """The must-NOT [unit], planted on both sides because no fixture can produce the positive case.

    The forbidden implementation is one line and costs nothing to write: put the ``spec_id`` in
    ``document`` and be done. It points the Epics column at a row that is not in it, and on screen
    that is indistinguishable from a selection that did nothing.

    Both directions are here. Over a column holding no such row the gap carries its project and no
    document — and, crucially, **is still a row**: hiding it would trade a wrong destination for a
    missing gap, which is the worse of the two. Over a column that *does* hold a document with that
    id it resolves, which is what stops this passing for a function that returns ``None`` always.
    """
    requirement = {"id": "r1", "label": "FR1", "spec_id": "spec-1"}
    project = ProjectView(name="alpha", path=Path("/alpha"))

    (unresolved,) = resolve_gaps(project, [requirement])

    assert unresolved.document is None, "a gap named a spec the Epics column does not hold"
    assert unresolved.project == Path("/alpha") and unresolved.requirement == "FR1", (
        "a gap with nowhere to go lost its project as well"
    )

    holding = ProjectView(
        name="alpha",
        path=Path("/alpha"),
        epics=(EpicView(id="spec-1", title="A row with the spec's id", state="pending"),),
    )

    (resolved,) = resolve_gaps(holding, [requirement])

    assert resolved.document == "spec-1", (
        "the resolution is hard-coded to None, so the test above proves nothing"
    )
