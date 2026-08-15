"""Story 3 — candidate next actions, ordered (FR9).

The ordering is the requirement and it is also the part a fixture can quietly fail to test. An
assertion over one candidate of each kind is satisfied by several wrong comparators; one over a
fixture holding a single kind is satisfied by a comparator that does not sort at all. So the tests
here run against a project holding **more than one of each kind**, with a decoy for each — a spec
that does have epics, a complete epic that already has a retro, and a complete epic whose retro was
waived.
"""

from __future__ import annotations

from fixture_database import titled

from status_model import (
    CANDIDATE_KINDS,
    EPICS,
    RETROS,
    SPECS,
    Candidate,
    candidates,
    ready_epic_ids,
    rows,
)

from mcp_client import ServerPool


async def read_candidates(root) -> list[Candidate]:
    """FR9's answer for one project, over the real server — every input a `tools/call`."""
    async with ServerPool() as pool:
        epics = await rows(pool, root, EPICS)
        specs = await rows(pool, root, SPECS)
        retros = await rows(pool, root, RETROS)
        ready = await ready_epic_ids(pool, root)

    return candidates(epics, specs, retros, ready)


async def test_candidates_are_ordered_by_kind_over_more_than_one_of_each(fixture_project):
    """FR9's ordering, over a fixture that can tell a sort from an accident of append order.

    Two ready epics, two specs with no epics and two complete epics with no retro. A comparator
    that never sorts returns them in the order they were built, which interleaves the kinds; one
    that sorts by number alone interleaves them too. Only the required order survives.
    """
    found = await read_candidates(fixture_project)
    kinds = [candidate.kind for candidate in found]

    assert kinds == sorted(kinds, key=CANDIDATE_KINDS.index), (
        f"the candidate kinds are not in FR9's order: {kinds}"
    )

    for kind in CANDIDATE_KINDS:
        assert kinds.count(kind) >= 2, (
            f"the fixture holds fewer than two {kind} candidates, so the ordering above is "
            f"satisfied by comparators that do not sort: {kinds}"
        )


async def test_each_kind_holds_the_rows_it_names(fixture_project):
    """The decoys, one per kind: an ordering over the wrong candidates is still the wrong list."""
    by_kind: dict[str, set[str]] = {kind: set() for kind in CANDIDATE_KINDS}

    for candidate in await read_candidates(fixture_project):
        by_kind[candidate.kind].add(candidate.title)

    assert by_kind["epic_ready"] == titled("open_epic", "second_ready_epic", "preview_epic"), (
        f"a blocked or finished epic was offered as ready: {by_kind['epic_ready']}"
    )
    assert by_kind["spec_without_epics"] == titled("quiet_spec", "later_spec"), (
        f"a spec that has been broken down was offered for breaking down: "
        f"{by_kind['spec_without_epics']}"
    )
    assert by_kind["retro_missing"] == titled("done_epic", "second_done_epic"), (
        f"an epic with a retro, or one whose retro was waived, was offered again: "
        f"{by_kind['retro_missing']}"
    )


async def test_a_waived_epic_is_not_offered_a_retro(fixture_project):
    """FR9's must-NOT, and the case that separates "has a retro" from "needs no retro".

    The fixture's seventh epic is complete, has no retro, and carries a recorded waiver. It is the
    only epic in that state, so a rule that read the waiver as absent — or ignored the column —
    offers it. The paired positive is in the same assertion: two complete epics *without* a waiver
    are still offered, so a check that excluded every complete epic would fail here too.
    """
    offered = {
        candidate.title
        for candidate in await read_candidates(fixture_project)
        if candidate.kind == "retro_missing"
    }

    assert "Seventh epic" not in offered, (
        f"an epic whose retro was deliberately waived was offered again: {offered}"
    )
    assert offered == {"First epic", "Fifth epic"}, (
        f"the waiver rule reached epics it is not about: {offered}"
    )


async def test_numbering_orders_within_a_kind(fixture_project):
    """Within a kind, lowest number first — and specs and epics number by different columns.

    Epics are child-numbered and carry `sequence`; specs are root-numbered and carry `number`.
    Reading one column would order one kind correctly and pile the other at zero, where the tie is
    broken by id and the result is stable, plausible and wrong.
    """
    found = await read_candidates(fixture_project)

    for kind in CANDIDATE_KINDS:
        numbers = [candidate.number for candidate in found if candidate.kind == kind]

        assert numbers == sorted(numbers), f"{kind} candidates are out of order: {numbers}"
        assert 0 not in numbers, f"a {kind} candidate has no number, so its order is by id: {found}"
