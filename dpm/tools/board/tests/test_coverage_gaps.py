"""48-08 Story 1 — requirements no coverage row names, derived under the contract (FR16, AD5).

The rule is a set difference, which is the shape most able to pass for the wrong reason: returning
*every* requirement satisfies "the ones with no coverage row" over any fixture where nothing is
traced, and returning *none* satisfies it over any fixture where everything is. So the fixture holds
both kinds, and each test below states the wrong answer it excludes.

Two of this story's criteria are checked by tests that already existed before it — the contract
reconciliation in `test_contract.py` and the mutating-verb sweep in `test_non_mutation.py`. Both
read live registries this story's code joins (`DERIVATIONS`, `SURFACE`), so the coverage is real
rather than assumed; neither is restated here, because a second copy of a check is a test of the
copy.
"""

from __future__ import annotations

import status_model
from conftest import stand_in_pool
from fixture_database import labelled
from recording_server import transcript_of

from mcp_client import SURFACE, ServerPool
from status_model import untraced_requirements

#: The fixture's two gaps, by the role each was built to play rather than by a label copied here.
GAPS = ("untraced_requirement", "orphan_untraced_requirement")


async def test_the_derivation_returns_exactly_the_requirements_no_coverage_row_names(
    fixture_project,
):
    """Criterion 1, against `bin/dpm-mcp.js` over a fixture holding both kinds.

    The traced requirement is what makes this evidence. Without one in the fixture, a derivation
    that ignored `coverage` entirely and returned every requirement would pass — and that is the
    likeliest way this breaks, because it is what the code looks like with one filter removed.
    """
    async with ServerPool() as pool:
        gaps = await untraced_requirements(pool, fixture_project)

    found = {row["label"] for row in gaps}

    assert found == labelled(*GAPS), f"the gaps are not the fixture's two untraced rows: {found}"
    assert labelled("traced_requirement") & found == set(), (
        "a requirement a coverage row names was reported as a gap, so `coverage` was not read"
    )


async def test_a_gap_carries_the_spec_it_belongs_to(fixture_project):
    """Criterion 1's shape half: rows, not ids, and the columns the view is built from.

    Returning ids would send the caller back for the list it has just been handed. `spec_id` is the
    column that makes a gap locatable at all, and the two gaps deliberately sit under *different*
    specs — one that has epics and one that has none — so a derivation collapsing them onto a single
    spec fails here rather than in the view three stories later.
    """
    async with ServerPool() as pool:
        gaps = await untraced_requirements(pool, fixture_project)

    specs = {row["spec_id"] for row in gaps}

    assert len(specs) == 2, f"the fixture's two gaps did not come back under two specs: {specs}"
    assert all(row.get("label") for row in gaps), "a gap row carries no label to render"


async def test_a_read_that_comes_back_with_more_is_followed(fixture_project, monkeypatch):
    """Criterion 4, with the page size lowered rather than the fixture grown.

    Seeding hundreds of rows would make this true of today's `PAGE` and silently vacuous the day it
    changes; lowering the bound makes both reads page over a fixture of four rows and keeps the
    assertion honest at any default.

    It passes through `rows()`, which follows `more` — and that is the point. It fails the moment
    the derivation reaches for `pool.read` directly, which is the only way this criterion can be
    violated, and the resulting answer would name traced requirements as gaps because their coverage
    rows were on the page nobody asked for.
    """
    monkeypatch.setattr(status_model, "PAGE", 1)

    async with ServerPool() as pool:
        gaps = await untraced_requirements(pool, fixture_project)

    assert {row["label"] for row in gaps} == labelled(*GAPS), (
        "the answer changed when the reads had to page, so a page was reported as the answer"
    )


async def test_both_reads_are_declared_and_both_are_made(project, transcript):
    """Criterion 3, from the calls on the wire rather than from the declarations alone.

    `SURFACE` says what the board *may* call; NFR5's reconciliation holds it to what the server
    serves. Neither says a call was made — a declaration for a tool nothing calls reconciles
    perfectly. This is the other half: the stand-in records what it was asked, and both names have
    to appear in that record.

    Unscoped is asserted too. A `spec_id` or a `requirement_id` on either call would be a narrower
    question than the rule asks, and one that happens to return the right answer on a fixture with
    a single spec in it.
    """
    root = project()

    async with stand_in_pool() as pool:
        await untraced_requirements(pool, root)

    calls = {
        message["params"]["name"]: message["params"].get("arguments", {})
        for message in transcript_of(transcript)
        if message.get("method") == "tools/call"
    }

    for name in ("list_requirement", "list_coverage"):
        assert name in SURFACE, f"{name} is called as a bare string rather than declared"
        assert name in calls, f"the derivation never asked the server for {name}: {sorted(calls)}"

    assert "spec_id" not in calls["list_requirement"], "the requirements read was scoped to a spec"
    assert "requirement_id" not in calls["list_coverage"], (
        "coverage was read once per requirement rather than once for the project"
    )
