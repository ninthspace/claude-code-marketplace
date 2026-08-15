"""Story 1 — state derived from rows, never from prose (FR5).

The derivations here are the two halves of what a board has to answer that a row cannot: *in
progress*, which dpm's status enum has no member for, and *blocked by what*, which dpm answers as
edges rather than as a word.

Each test states the wrong answer it excludes, because a green assertion over one case is not
evidence: a derivation that returns "in progress" unconditionally satisfies the requirement as
FR5 words it, and a blocker rule that reads retirement as completion satisfies every fixture in
which nothing was ever retired.
"""

from __future__ import annotations

import pytest
from conftest import stand_in_pool
from recording_server import transcript_of

from mcp_client import ServerPool
from status_model import (
    BLOCKED,
    EPICS,
    IN_PROGRESS,
    blockers,
    dependencies,
    epic_state,
    gating_kinds,
    in_progress,
    ready_epic_ids,
    ready_story_ids,
    rows,
    still_gates,
)


def stories(*statuses: str) -> list[dict]:
    """Story rows as the tools return them — only the column the derivation reads is required."""
    return [{"id": f"s{index}", "status": status} for index, status in enumerate(statuses)]


def edge(source: str, target: str, kind: str = "blocks") -> dict:
    """A `dependency` row, document to document, as `list_dependency` returns one."""
    return {
        "id": f"{source}->{target}",
        "kind": kind,
        "source_document_id": source,
        "source_story_id": None,
        "target_document_id": target,
        "target_story_id": None,
    }


def epic(identifier: str, title: str, status: str = "pending") -> dict:
    """A `document` row of kind epic, with the columns the derivations read."""
    return {"id": identifier, "title": title, "status": status}


def test_in_progress_is_some_complete_and_some_not():
    """The mixed case, which is the whole of what FR5 names."""
    assert in_progress(stories("complete", "pending")) is True


def test_neither_extreme_reads_as_in_progress():
    """The two decoys, without which a derivation that always says yes passes the test above.

    The wrong answer this excludes: `return True`. It is right about the mixed case, right about
    the only case the requirement names, and wrong about both ends of the epic's life — an epic
    nobody has started reads as under way, and a finished one never stops reading that way.
    """
    assert in_progress(stories("complete", "complete")) is False
    assert in_progress(stories("pending", "pending")) is False


def test_a_mixed_epic_renders_in_progress_though_no_row_says_so():
    """The rendered half of the same criterion: the derivation reaches the epic's state.

    `document.status` is `pending` here and stays `pending` — *in progress* exists nowhere in the
    database, which is what makes this a derivation rather than a column being read out.
    """
    mixed = epic("mixed", "An epic under way")

    assert mixed["status"] == "pending", "the fixture, not the derivation, is under test"
    assert epic_state(mixed, stories("complete", "pending"), [], {mixed["id"]}) == IN_PROGRESS


def test_an_epic_with_no_stories_is_not_in_progress():
    """`any`/`all` over an empty list disagree, and `all` is the one that says yes here."""
    assert in_progress([]) is False


@pytest.mark.parametrize("status", ["superseded", "withdrawn"])
def test_a_retired_blocker_does_not_satisfy_the_edge_it_holds(status):
    """FR5's must-NOT, at the level where the harm lands: the dependent is still blocked.

    The wrong answer this excludes is "terminal means done" — a rule reading all three of
    `complete`, `superseded` and `withdrawn` as satisfying the edge. Under it the epic below
    renders workable, and a user picks up work that dpm's own `ready` filter excludes. Retiring an
    epic something waits on is meant to surface *as a blocker*, because the work it was waiting
    for is now never coming.
    """
    retired = epic("blocker", "An abandoned epic", status=status)
    waiting = epic("waiting", "The epic left holding")

    held = blockers(
        "waiting",
        [edge("blocker", "waiting")],
        {"blocks"},
        {"blocker": retired, "waiting": waiting},
    )

    assert [one.id for one in held] == ["blocker"], (
        f"a {status} blocker was read as satisfying the edge, releasing the epic waiting on it"
    )
    assert epic_state(waiting, stories("pending"), held, ready=set()) == BLOCKED


def test_only_a_complete_blocker_releases_the_work():
    """The paired positive, so the rule above is not satisfied by one that never releases at all."""
    assert still_gates("complete") is False
    assert still_gates("pending") is True


async def test_a_blocked_epic_names_its_blocker_over_the_real_server(fixture_project):
    """FR5 end to end against `bin/dpm-mcp.js`: the edge is a row, so the blocker has a name.

    This is the whole difference from CPM's board, which infers a blocker by matching a title out
    of a `**Blocked by**` line. Here the fixture's third epic is held by its second over a real
    `dependency` row, and what the board reports is the blocker's own title, read from the row the
    edge points at.

    The paired negative is in the same run: the epic doing the blocking is itself ready. A board
    that rendered everything blocked would satisfy the first assertion and fail this one.
    """
    async with ServerPool() as pool:
        epics = await rows(pool, fixture_project, EPICS)
        ready = await ready_epic_ids(pool, fixture_project)
        edges = await dependencies(pool, fixture_project)
        gating = await gating_kinds(pool, fixture_project)

    index = {row["id"]: row for row in epics}
    by_title = {row["title"]: row for row in epics}
    waiting, blocker = by_title["Third epic"], by_title["Second epic"]

    held = blockers(waiting["id"], edges, gating, index)

    assert [one.title for one in held] == ["Second epic"], (
        f"the blocked epic did not name its blocker: {held}"
    )
    assert epic_state(waiting, [], held, ready) == BLOCKED
    assert waiting["id"] not in ready, "dpm's own `ready` filter disagrees with the board"
    assert blocker["id"] in ready, "every epic read as blocked, so blocking distinguishes nothing"

    # The decoy the fixture plants: an incomplete epic reaches this one over a `builds_on` edge,
    # whose kind does not gate work. An edge is not a blocker; a *gating* edge is.
    assert blockers(blocker["id"], edges, gating, index) == [], (
        "an edge of a kind that does not gate work was read as blocking"
    )


async def test_readiness_and_blocking_are_asked_for_rather_than_computed(project, transcript):
    """FR5's provenance criterion, from the calls made rather than from the answer produced.

    A board that read every epic and reimplemented `readyClause` over the rows would return the
    same answer as one that asked, and be a second implementation of dpm's rule that drifts the
    first time that clause changes. The only thing that tells them apart is the request: `ready`
    on the wire, and `dependency_kind` read at all.

    `include_retired` is asserted for the reason `gating_kinds` gives — a retired edge kind still
    gates, so a board taking the tool's default would miss edges dpm is still enforcing.
    """
    root = project()

    async with stand_in_pool() as pool:
        await ready_epic_ids(pool, root)
        await ready_story_ids(pool, root)
        await gating_kinds(pool, root)
        await dependencies(pool, root)

    calls = {
        message["params"]["name"]: message["params"].get("arguments", {})
        for message in transcript_of(transcript)
        if message.get("method") == "tools/call"
    }

    assert calls.get("list_epic", {}).get("ready") is True, (
        f"readiness was not asked of the server: {calls}"
    )
    assert calls.get("list_story", {}).get("ready") is True, (
        f"story readiness was recomputed rather than asked for: {calls}"
    )
    assert "list_dependency" in calls, f"no edge was ever read, so no blocker can be named: {calls}"
    assert calls.get("list_dependency_kind", {}).get("include_retired") is True, (
        f"`gates_work` was read from the live kinds only, or not at all: {calls}"
    )
