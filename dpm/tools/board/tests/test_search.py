"""Story 3 — one query, every registered project, and a result that goes back (FR15, NFR2).

Every test here is `[integration]`, and that is the criteria's own choice rather than a preference:
what a search returns depends on an FTS5 index dpm builds by trigger, and a stand-in that answered
with plausible hits would verify the board's plumbing against a corpus nobody indexed. The one
exception is the provenance test, which is *about* the calls and so has to read a transcript.

**The containment case asserts the healthy project's results, not merely that the search returned.**
A fan-out that swallowed everything returns an empty list without raising, which passes "did not
stop the other projects' results appearing" while stopping exactly that.
"""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path
from shutil import copytree, which

import pytest
from conftest import STAND_IN
from failures import exiting_server
from pilot import board, lines, until
from test_containment import Unanticipated

from board import registry_views, search_project, search_projects, survey_project
from board_view import ProjectView
from mcp_client import ServerPool
from recording_server import transcript_of
from registry import RegistryEntry

#: A phrase only one fixture section holds, so a hit is evidence about that section rather than about
#: the fixture being large. It sits under an epic the board renders, which is what makes it the case
#: where a result resolves all the way to a row.
IN_A_SECTION = "markdown"

#: Prose held on `story_criterion` rows — indexed by `entry_fts`, and *not* a row the browser's three
#: columns hold. The case where a result honestly has no document. No section body uses the word, so
#: a hit here is evidence about the entry index rather than about the query being common.
IN_A_CRITERION = "says"

#: Prose in a section of the fixture *spec*. A section like any other, and its document is one the
#: Epics column does not hold — the case that separates "this hit named a document" from "this hit
#: named a row the board can move the cursor to".
IN_A_SPEC_SECTION = "covers"

#: How long a fan-out over the real servers is given.
SETTLE = 30.0


def copy_of(built: Path, destination: Path) -> Path:
    """A private copy of the built fixture — one project the test may register under any name."""
    copytree(built, destination)

    return destination


def views(*roots: Path) -> list:
    """Registry rows for ``roots``, named by their directory, as the board builds them."""
    return registry_views([RegistryEntry(str(root)) for root in roots])


async def surveyed(pool: ServerPool, rows: list) -> list:
    """The same rows, read — a search resolves against the epics a project is holding."""
    return [await survey_project(pool, row) for row in rows]


def needs_node() -> None:
    if which("node") is None:
        pytest.skip("no node on PATH to spawn a real server")


async def test_a_search_runs_across_registered_projects_and_names_each_result_s_own(
    built_fixture, tmp_path
):
    """Criterion 1's first half [integration]: two projects, one query, results from both.

    **Two copies of the same fixture, deliberately.** Identical corpora make the projects
    indistinguishable by their hits, so the only thing that can tell the results apart is the field
    that says where each came from — which is the property being asserted. Two *different* projects
    would let a result be attributed correctly by accident, from its text.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")
    beta = copy_of(built_fixture, tmp_path / "beta")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(alpha, beta))
        results = await search_projects(pool, projects, IN_A_SECTION)

    assert results, f"{IN_A_SECTION!r} matched nothing in either project"
    assert {result.name for result in results} == {"alpha", "beta"}, (
        f"the results did not come from both projects: {sorted(r.name for r in results)}"
    )
    assert {result.project for result in results} == {alpha, beta}

    # Registry order, not answering order: two servers race, and a list that reordered itself by
    # whichever was quicker would put the same hit somewhere different on every run.
    assert [result.name for result in results] == sorted(
        (result.name for result in results), key=["alpha", "beta"].index
    )


async def test_each_result_navigates_back_to_its_project_and_epic(built_fixture, tmp_path):
    """Criterion 1's second half [integration], at the row: the document a result points at.

    Asserted as *a row that is in that project's Epics column*, not merely as a non-empty string. A
    result carrying an id the board is not showing navigates to a row that is not there, which on
    screen is indistinguishable from navigating nowhere.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(alpha))
        results = await search_projects(pool, projects, IN_A_SECTION)

    (project,) = projects
    holding = {row.id for row in project.epics}
    resolved = [result for result in results if result.document is not None]

    assert resolved, f"no result for {IN_A_SECTION!r} named a document to navigate to"
    assert all(result.document in holding for result in resolved), (
        f"a result points at a row the Epics column does not hold: "
        f"{[r.document for r in resolved if r.document not in holding]}"
    )


async def test_a_hit_the_board_holds_no_row_for_keeps_its_project_and_no_document(
    built_fixture, tmp_path
):
    """The honest half of the resolution, stated rather than left to be discovered.

    `search` answers over fifteen indexed entities; the browser's three columns hold documents and
    stories. A criterion's prose matches, and there is no row to move the cursor to — so the result
    appears, named by its project, with no document. **Hiding it would be the false negative dpm's
    own search tool documents**: an empty answer a user reads as an absence.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(alpha))
        results = await search_projects(pool, projects, IN_A_CRITERION)

    found = {result.entity for result in results}

    assert results, f"{IN_A_CRITERION!r} matched nothing, so this asserts about an empty list"
    assert "story_criterion" in found, f"the query reached no criterion at all: {sorted(found)}"
    assert "document_section" not in found, (
        f"the query also matched a section, so a resolved result would mask this one: {sorted(found)}"
    )
    assert all(result.document is None for result in results)
    assert all(result.name == "alpha" and result.project == alpha for result in results), (
        "a result the board cannot navigate to lost the project it came from as well"
    )


async def test_a_section_of_a_document_the_column_does_not_hold_names_no_row(
    built_fixture, tmp_path
):
    """The guard between "resolved to a document" and "resolved to a row that is on the board".

    A spec's section carries a `document_id` like any other, and the Epics column holds epics — so a
    hit here has a perfectly good document that is not a row the cursor can be moved to. Carrying it
    anyway would send the cursor to a row that is not there, which on screen is indistinguishable
    from a selection that did nothing, and is worse: the user has no reason to look further.

    **This is the case `IN_A_SECTION` cannot reach**, because that section is under an epic.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")

    async with ServerPool() as pool:
        projects = await surveyed(pool, views(alpha))
        results = await search_projects(pool, projects, IN_A_SPEC_SECTION)

    (project,) = projects
    holding = {row.id for row in project.epics}
    sections = [result for result in results if result.entity == "document_section"]

    assert sections, f"{IN_A_SPEC_SECTION!r} matched no section, so this asserts about nothing"
    assert not any(result.document in holding for result in sections), (
        "the fixture's spec section is under an epic after all, so this test proves nothing"
    )
    assert all(result.document is None for result in sections), (
        f"a hit named a document the Epics column does not hold: "
        f"{[r.document for r in sections if r.document is not None]}"
    )


async def test_the_results_come_from_the_search_tool(tmp_path, project, transcript, monkeypatch):
    """Criterion 2 [integration], read off the transcript.

    Results assembled any way at all satisfy criterion 1 — from a cache, from a local index, from
    the sections the board already reads. FR15 names the `search` tool, and the only witness that
    cannot be fooled by the board's intentions is what arrived on the wire.

    **The query is asserted verbatim.** A board that helpfully added an `entity:` scope would return
    a narrower corpus than the user asked for and report it as the whole answer, which is the failure
    dpm's search tool spends three paragraphs of its own description warning about.
    """
    monkeypatch.setenv("RECORDING_SCHEMA", "1")

    alpha, beta = project("alpha"), project("beta")
    pool = ServerPool(STAND_IN, node=sys.executable)

    try:
        await search_projects(pool, views(alpha, beta), "a query the user wrote")
    finally:
        await pool.close()

    searches = [
        message["params"]
        for message in transcript_of(transcript)
        if message.get("method") == "tools/call" and message["params"]["name"] == "search"
    ]

    assert len(searches) == 2, f"a search was not one call per project: {searches}"
    assert {call["arguments"]["query"] for call in searches} == {"a query the user wrote"}


async def test_a_project_whose_server_cannot_start_stops_none_of_the_others(built_fixture, tmp_path):
    """Criterion 3 [integration]. One dead server in a registry, and the answer still arrives.

    **The dead project is first**, so a fan-out that stopped at the first failure would return
    nothing at all — and the assertion is on the healthy project's own hits rather than on the call
    completing, because a fan-out that swallowed every project returns an empty list without raising
    and would pass the weaker claim while failing this requirement entirely.
    """
    needs_node()

    dead = project_without_a_server(tmp_path)
    healthy = copy_of(built_fixture, tmp_path / "healthy")

    async with ServerPool(exiting_server(tmp_path), node=sys.executable) as broken:
        async with ServerPool() as pool:
            rows = views(dead, healthy)
            projects = [await survey_project(broken, rows[0]), await survey_project(pool, rows[1])]

            # The dead project is surveyed through a pool whose server exits, so its row carries the
            # failure a user would see; the search then runs over the real pool, where *its* server
            # is the one that will not start.
            results = await search_projects(pool, projects, IN_A_SECTION)

    assert projects[0].unreadable is not None, "the dead project rendered as readable after all"
    assert results, "one dead server took the whole search down with it"
    assert {result.name for result in results} == {"healthy"}, (
        f"the dead project contributed results: {sorted(r.name for r in results)}"
    )


async def test_a_cancelled_search_is_not_a_project_with_no_results(project):
    """The *width* of the containment arm above, which every other test here is blind to.

    A cancellation is the board shutting the screen: the search worker is cancelled, and
    ``BaseException`` — the reflexive way to write "contain everything" — would swallow it and answer
    with an empty list. The project then appears to have matched nothing, in a list the user may
    still be reading, and the loop is left waiting on a worker that reported success.
    """
    with pytest.raises(asyncio.CancelledError):
        await search_project(
            Unanticipated(asyncio.CancelledError()),
            ProjectView(name="boom", path=project("boom")),
            IN_A_SECTION,
        )


async def test_an_unforeseen_failure_costs_one_project_its_results_and_no_more(project):
    """NFR2's arm itself: a failure nothing here has a signature for is this project's alone.

    Driven with a `MemoryError`, which is neither a named state nor anything the pool classifies —
    the class of failure the arm exists for rather than the ones the tests above produce.
    """
    found = await search_project(
        Unanticipated(MemoryError("the machine ran out of memory")),
        ProjectView(name="boom", path=project("boom")),
        IN_A_SECTION,
    )

    assert found == [], f"an unforeseen failure produced results anyway: {found}"


def project_without_a_server(tmp_path: Path) -> Path:
    """A directory shaped like a dpm project whose database is not one a server will open."""
    root = tmp_path / "dead"
    (root / ".dpm").mkdir(parents=True)
    (root / ".dpm" / "dpm.db").write_bytes(b"not a database")

    return root


async def test_choosing_a_result_moves_the_columns_to_its_project_and_epic(built_fixture, tmp_path):
    """Criterion 1 [integration], driven the way a user reaches it — FR15's second half.

    Everything above drives the fan-out. This is the one that says the board *does* something with a
    chosen result: the search opens on a key, runs over both projects, and picking a hit from the
    second one moves all three columns to it. The assertion is on the painted rows, because a
    selection the app recorded and did not paint has moved nothing a user can see.
    """
    needs_node()

    alpha = copy_of(built_fixture, tmp_path / "alpha")
    beta = copy_of(built_fixture, tmp_path / "beta")

    async with ServerPool() as pool:
        rows = views(alpha, beta)

        async with board(
            rows,
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
            search=lambda projects, query: search_projects(pool, projects, query),
        ) as (app, pilot):
            await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )

            await pilot.press("ctrl+f")
            await pilot.pause()

            for character in IN_A_SECTION:
                await pilot.press(character)

            await pilot.press("enter")
            await until(pilot, lambda: getattr(app.screen, "results", None), timeout=SETTLE)

            found = app.screen.results
            chosen = next(index for index, row in enumerate(found) if row.name == "beta")

            await pilot.press(*["down"] * chosen)
            await pilot.press("enter")
            await pilot.pause()
            await pilot.pause()

            landed = app.selection.current_project
            epic = app.selection.current_epic
            painted = lines(app, "projects")

    assert landed is not None and landed.name == "beta", (
        f"choosing a result from beta left the cursor on {landed and landed.name}"
    )
    assert epic is not None and epic.id == found[chosen].document, (
        "the Epics column did not move to the row the result named"
    )
    assert painted, "the columns painted nothing after the search closed"
