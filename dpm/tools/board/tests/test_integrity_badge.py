"""48-08 Story 3 — `check_integrity` on the project row (FR17, NFR2).

The badge is a *rendering* rather than a derivation: dpm answers the question, and the board's whole
contribution is to ask it, count what came back, and put it where a user will see it. So the tests
split between the two things that can go wrong — the number being made up, and the number being
right and invisible.

**The clean project is the discriminator throughout.** A survey that read a project and reported
nothing of it satisfies every failure-side assertion here; only a run where one project shows a
badge and another does not says the board is reading rather than decorating.
"""

from __future__ import annotations

import sys
from pathlib import Path
from shutil import copytree, which

import pytest
from conftest import stand_in_pool
from failures import exiting_server
from fixture_database import build
from recording_server import transcript_of

from board import registry_views, survey_project
from board_view import BROKEN, LIVE, NOTHING, RALPH_MARKER, ProjectView, integrity_badge
from mcp_client import ServerPool, server_path
from registry import RegistryEntry
from status_model import violation_count, violations

#: A project whose database breaks one of the register's own invariants.
#:
#: Register entry 6 admits a `builds_on` edge only between two specs, so an epic-to-epic one is a
#: real violation of a rule dpm wrote — not a corruption invented for this test. Everything else
#: here is the minimum a `create_dependency` call needs to have two ends.
ONE_VIOLATION = [
    ("create_spec", {"slug": "10-broken-spec", "title": "A spec with a bad edge under it"}, "spec"),
    ("create_epic", {"parent_id": "{spec}", "slug": "10-01-one", "title": "First"}, "first"),
    ("create_epic", {"parent_id": "{spec}", "slug": "10-02-two", "title": "Second"}, "second"),
    (
        "create_dependency",
        {"kind": "builds_on", "source_document_id": "{first}",
         "target_document_id": "{second}"},
        None,
    ),
]


def needs_node() -> None:
    if which("node") is None:
        pytest.skip("no node on PATH to spawn a real server")


def views(*roots: Path) -> list:
    """Registry rows for ``roots``, named by their directory, as the board builds them."""
    return registry_views([RegistryEntry(str(root)) for root in roots])


async def built(root: Path, content: list | None = None) -> Path:
    """A project directory holding a real database with ``content`` in it."""
    root.mkdir(parents=True)
    await build(root, server_path(), content)

    return root


async def test_a_project_with_a_broken_invariant_shows_the_count_and_a_clean_one_shows_nothing(
    built_fixture, tmp_path
):
    """Criterion 1 [integration], with both halves in one run.

    The clean project is the shared fixture, which the board's own suite reads everywhere else —
    so a badge appearing on it would be news about the fixture as much as about this code. The
    broken one carries exactly one violation, which is what makes the count assertable rather than
    merely non-zero.
    """
    needs_node()

    broken = await built(tmp_path / "broken", ONE_VIOLATION)
    clean = tmp_path / "clean"
    copytree(built_fixture, clean)

    async with ServerPool() as pool:
        rows = views(broken, clean)
        surveyed = [await survey_project(pool, row) for row in rows]

    by_name = {row.name: row for row in surveyed}

    assert by_name["broken"].violations == 1, (
        f"the broken project reported {by_name['broken'].violations} violations, not one"
    )
    assert by_name["clean"].violations == 0, (
        "the shared fixture is no longer integrity-clean, so this test asserts about nothing"
    )
    assert BROKEN in by_name["broken"].label, (
        f"the badge is not on the row a user reads: {by_name['broken'].label!r}"
    )
    assert "1" in by_name["broken"].label.split(BROKEN)[1], "the badge carries no count"
    assert BROKEN not in by_name["clean"].label, (
        f"a project reporting ok carries a badge anyway: {by_name['clean'].label!r}"
    )


async def test_the_badge_is_read_from_the_check_integrity_tool(project, transcript):
    """Criterion 3 [integration], off the transcript.

    A count assembled any way at all satisfies criterion 1 — from the rows the survey already read,
    from a local sweep, from nothing. FR17 names `check_integrity`, and the witness that cannot be
    fooled by the board's intentions is what arrived on the wire.

    **Asserted as part of the survey**, not as a call made in isolation: reading it outside the
    survey would put it outside FR13's cache, and the read re-running on every repaint is the whole
    reason Task 3.1 put it where it is.
    """
    root = project("alpha")

    async with stand_in_pool() as pool:
        await survey_project(pool, views(root)[0])

    called = [
        message["params"]["name"]
        for message in transcript_of(transcript)
        if message.get("method") == "tools/call"
    ]

    assert "check_integrity" in called, (
        f"the survey never asked the server for its integrity report: {sorted(set(called))}"
    )


async def test_the_count_tracks_the_report_rather_than_the_project_being_broken(tmp_path):
    """Criterion 3's other half: the *number*, not merely the call.

    Two broken projects, one with a second bad edge, so a board that answered `1` for anything
    failing fails here. **Both edges break the same invariant**, which is exactly the case that
    separates counting rows from counting register entries: an entry count would report two broken
    edges as one problem, and the number on a badge is there to say how much there is to fix.
    """
    needs_node()

    one = await built(tmp_path / "one", ONE_VIOLATION)
    two = await built(
        tmp_path / "two",
        [
            *ONE_VIOLATION,
            ("create_epic", {"parent_id": "{spec}", "slug": "10-03-three", "title": "Third"},
             "third"),
            (
                "create_dependency",
                {"kind": "builds_on", "source_document_id": "{second}",
                 "target_document_id": "{third}"},
                None,
            ),
        ],
    )

    async with ServerPool() as pool:
        counts = {root.name: await violations(pool, root) for root in (one, two)}

    assert counts == {"one": 1, "two": 2}, f"the count does not track the report: {counts}"


def test_the_badge_marker_is_none_of_the_other_two():
    """Criterion 2 [unit]. Three markers on one board, told apart by shape rather than position.

    The pill's `●` means a session is running now and the ralph `▸` means a keypress would start
    one; both are about work in flight and this is about the database under it being wrong. A user
    who has to work out which marker they are looking at from where it sits has one marker, as far
    as a glance is concerned.
    """
    marker = BROKEN[0]

    assert marker not in LIVE, f"the badge reuses the live pill's marker: {BROKEN!r} / {LIVE!r}"
    assert marker != RALPH_MARKER, f"the badge reuses the ralph marker: {BROKEN!r}"
    assert integrity_badge(0) == "", "a clean project was given a badge"
    assert integrity_badge(3) == f"{BROKEN} 3", "the badge does not carry its count"


def test_a_clean_row_renders_exactly_as_it_did_before_the_badge_existed():
    """The badge's other half: what it costs a project that has nothing wrong.

    A row whose shape changed to hold a blank would put a gap in every clean project's row for the
    sake of the ones that are not — which is the rule the live pill already follows, and the reason
    both are suffixes rather than columns.
    """
    clean = ProjectView(name="alpha", path=Path("/alpha"))
    flagged = ProjectView(name="alpha", path=Path("/alpha"), violations=2)

    assert clean.label == f"alpha  ·  {NOTHING}", f"a clean row grew a blank: {clean.label!r}"
    assert flagged.label.startswith(clean.label), (
        "the badge changed the row rather than joining the end of it"
    )


def test_an_orphaned_row_counts_even_when_every_register_entry_holds():
    """The arm no fixture can reach, planted.

    dpm's own write tools enforce the foreign keys an orphan breaks, so a project with a dangling
    row cannot be built the way every other fixture here is. Left untested, the orphan term would
    be a line nobody had ever run — and the failure it guards against is the quiet one: a badge
    reading `0` beside a database whose keys no longer resolve.
    """
    holding = [{"entry": 1, "held": True, "rows": []}]

    assert violation_count({"ok": True, "entries": holding, "orphans": []}) == 0
    assert violation_count({"ok": False, "entries": holding, "orphans": [{}, {}]}) == 2, (
        "orphaned rows were dropped, so a broken key renders as a clean project"
    )
    assert violation_count(
        {"ok": False, "entries": [{"entry": 6, "held": False, "rows": [{}, {}]}], "orphans": [{}]}
    ) == 3, "the two kinds of finding are not counted together"


async def test_a_project_whose_check_cannot_run_renders_its_state_and_the_others_their_badges(
    tmp_path,
):
    """Criterion 4 [integration]. One project the board cannot read, beside one it can.

    **The dead project is first**, so a survey that gave up at the first failure would report
    nothing about the one behind it. And the assertion on the healthy project is its *badge*, not
    merely its presence: a survey that returned rows with every field defaulted would pass "the
    other project still renders" while reporting a broken database as clean.
    """
    needs_node()

    dead = tmp_path / "dead"
    (dead / ".dpm").mkdir(parents=True)
    (dead / ".dpm" / "dpm.db").write_bytes(b"not a database")
    healthy = await built(tmp_path / "healthy", ONE_VIOLATION)

    rows = views(dead, healthy)

    async with ServerPool(exiting_server(tmp_path), node=sys.executable) as broken:
        first = await survey_project(broken, rows[0])

    async with ServerPool() as pool:
        second = await survey_project(pool, rows[1])

    assert first.unreadable is not None, "the project the board cannot read rendered as readable"
    assert first.violations == 0, "a project nobody could open was given an integrity count"
    assert BROKEN not in first.label, (
        f"an unreadable project carries a badge about a database nobody opened: {first.label!r}"
    )
    assert second.violations == 1 and BROKEN in second.label, (
        f"the readable project lost its badge: {second.label!r}"
    )
