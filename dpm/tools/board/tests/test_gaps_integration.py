"""48-08 Story 4 — the two new reads inside the properties the board already holds (FR10, FR13).

Stories 1 to 3 added a derivation, a screen and a per-project read. Each was verified on its own
terms; neither of the board-wide guarantees was re-asked, and both are the kind that a new read is
exactly able to break — one by writing something, one by going out on the wire every repaint.

**Neither test here is redundant with the one it extends.** 48-06 proved FR10 over a session that
could not have opened the gaps view, because there was none; 48-05 proved FR13 over the reads that
existed then. A ✓ on either is not evidence about a read added afterwards, which is the same reason
48-07 added a whole-session comparison of its own rather than pointing at 48-06's.
"""

from __future__ import annotations

import sys
from pathlib import Path
from shutil import which

import pytest
import session as board_session
from conftest import STAND_IN
from recording_server import transcript_of

from board import gaps_project, registry_views, survey_project
from cache import Cache
from mcp_client import ServerPool
from registry import DATABASE, RegistryEntry

#: The reads this epic added, which are the ones neither existing guarantee has been asked about.
NEW_READS = ("list_requirement", "list_coverage", "check_integrity")

#: The file set the whole-tree comparison needs in order to be a comparison of a tree.
FURNISHINGS = {
    ".dpm/dpm.sql": "-- a projection of the database, as it stood when someone last published\n",
    "docs/specifications/10-fixture-spec.md": "# The fixture spec\n\nProse the board never reads.\n",
    "README.md": "# A project the board was pointed at\n",
}


def needs_node() -> None:
    if which("node") is None:
        pytest.skip("no node on PATH to spawn a real server")


def furnish(root: Path) -> Path:
    """Put files in the project besides its database, so the comparison has a tree to compare."""
    for name, content in FURNISHINGS.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    return root


def calls(transcript: Path) -> list[str]:
    """Every tool the servers were actually asked for, in order — the outside witness."""
    if not transcript.exists():
        return []

    return [
        message["params"]["name"]
        for message in transcript_of(transcript)
        if message.get("method") == "tools/call"
    ]


async def test_a_session_that_opened_the_gaps_view_leaves_the_project_byte_identical(
    fixture_project,
):
    """Criterion 1 [integration]: FR10, over a session that definitely took this epic's paths.

    The driver runs the board's own `COMMANDS` table and reconciles what it ran against it in both
    directions, so *this* session opened the gaps view and surveyed every project — which is to say
    it made all three of the new reads. The assertion that it did is here rather than assumed,
    because a comparison over a session that skipped them would pass while proving nothing.
    """
    needs_node()

    observed = await board_session.run(furnish(fixture_project))

    appeared = sorted(set(observed.after) - set(observed.before))
    vanished = sorted(set(observed.before) - set(observed.after))
    changed = sorted(
        path
        for path, fingerprint in observed.before.items()
        if path in observed.after and observed.after[path] != fingerprint
    )

    assert "coverage_gaps" in observed.ran, (
        f"the session never opened the gaps view, so this proves nothing about it: {observed.ran}"
    )
    assert set(FURNISHINGS) <= set(observed.before), (
        f"the project was not furnished, so the tree compared is {sorted(observed.before)}"
    )
    assert appeared == [], f"the board wrote files into the project it was observing: {appeared}"
    assert vanished == [], f"files disappeared from the project the board was observing: {vanished}"
    assert changed == [], f"the board changed files in the project it was observing: {changed}"


async def test_both_new_reads_are_served_from_the_cache_on_a_second_survey(
    tmp_path, project, transcript, monkeypatch
):
    """Criterion 2 [integration]: FR13, counted from calls that did not happen.

    **Two entry points, not one, because the three reads do not share one.** `check_integrity` is
    inside the survey (Task 3.1 put it there for exactly this reason); the two coverage reads are in
    the gaps fan-out, which is an action a user takes rather than part of a repaint. The criterion
    says "a second survey", and what it is about is the wire — so both paths are driven twice and
    every call is counted off the same transcript.

    Asked of those functions rather than of the pool directly, because a read written outside them
    would answer a hand-driven test perfectly and go out again on every repaint in a running board.
    """
    monkeypatch.setenv("RECORDING_SCHEMA", "1")

    root = project("alpha")
    (view,) = registry_views([RegistryEntry(str(root))])
    pool = ServerPool(STAND_IN, node=sys.executable, cache=Cache(tmp_path / "cache.json"))

    try:
        await gaps_project(pool, await survey_project(pool, view))
        first = calls(transcript)

        await gaps_project(pool, await survey_project(pool, view))
        second = calls(transcript)
    finally:
        await pool.close()

    for name in NEW_READS:
        assert name in first, f"the survey never made the {name} read at all: {sorted(set(first))}"

    assert second == first, (
        f"a second survey went back to the server: {[c for c in second[len(first):]]}"
    )

    # And the other half, so this is a claim about the cache rather than about a survey that only
    # ever reads once: a database whose stamp has moved is a different state, and the reads go out
    # again. Without it, a survey that cached nothing but was never called twice would pass above.
    (root / DATABASE).write_bytes(b"written since the survey")

    pool = ServerPool(STAND_IN, node=sys.executable, cache=Cache(tmp_path / "cache.json"))

    try:
        await gaps_project(pool, await survey_project(pool, view))
        third = calls(transcript)
    finally:
        await pool.close()

    for name in NEW_READS:
        assert third.count(name) > first.count(name), (
            f"a touched database was still answered from the cache for {name}"
        )
