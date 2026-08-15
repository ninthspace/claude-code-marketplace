"""Story 6 — `board.py list` over a mixed registry (FR1, FR2, FR3 together).

Stories 1, 3, 4 and 5 each exercise one part of this. None of them crosses the registry, the pool
and the client in the order a user's first command actually takes, and none of them has *two*
projects — which is where a containment failure shows up: one project that cannot be read taking
the board down with it, and the healthy one reporting nothing at all.

The transcript assertion here is deliberately **positive**. "No file under the project was opened"
is Story 3's must-NOT and it passes on a board that reads nothing whatsoever; what this needs to
show is that the numbers on the row came from somewhere, and that the somewhere was a `tools/call`.
"""

from __future__ import annotations

import io
from pathlib import Path

from conftest import is_running, stand_in_pool
from fixture_database import created
from recording_server import transcript_of

from board import run_cli
from registry import add_project


def rows_of(output: str) -> list[str]:
    return [line for line in output.strip().splitlines() if line.strip()]


def listing(registry_file: Path, make_pool=None) -> tuple[int, str, str]:
    """`board.py list` driven in-process, returning its exit code and both streams."""
    out, err = io.StringIO(), io.StringIO()
    code = run_cli(["list"], registry_file=registry_file, out=out, err=err, make_pool=make_pool)

    return code, out.getvalue(), err.getvalue()


def test_a_mixed_registry_reports_a_state_for_every_project(tmp_path, fixture_project, project):
    """One project with a database and one without, over the real server.

    Both get a row, and neither takes the other down. A pool that let the second project's refusal
    escape would produce a board that reports nothing about the first — which is the failure this
    whole story is placed here to catch.
    """
    registry_file = tmp_path / "registry.json"
    bare = project("bare", database=False)

    add_project(str(fixture_project), "Has a database", registry_file=registry_file)
    add_project(str(bare), "Has none", registry_file=registry_file)

    code, out, err = listing(registry_file)

    assert code == 0, err
    assert len(rows_of(out)) == 2, f"one project's row is missing: {out}"

    healthy, missing = rows_of(out)

    # Counted from the fixture's own content rather than written out here, so that a later story
    # widening it does not silently turn this assertion into a test of a stale number.
    expected = (
        f"{created('create_epic')} epics, {created('create_story')} stories, "
        f"{created('create_task')} tasks"
    )
    assert expected in healthy, healthy
    assert "Has a database" in healthy
    assert "no-database" in missing, missing
    assert str(bare) in missing


def test_the_reported_numbers_come_from_tools_calls(tmp_path, project, transcript):
    """FR2 end to end: the row's contents, traced to the calls that produced them.

    Against the recording stand-in rather than the real server, because the question is not whether
    the numbers are *right* — the test above settles that — but whether they arrived as `tools/call`
    responses at all.
    """
    registry_file = tmp_path / "registry.json"
    add_project(str(project()), None, registry_file=registry_file)

    code, out, err = listing(registry_file, make_pool=stand_in_pool)

    called = [
        message["params"]["name"]
        for message in transcript_of(transcript)
        if message["method"] == "tools/call"
    ]

    assert code == 0, err
    assert called == ["list_epic", "list_story", "list_task"], (
        f"the row was built from something other than tool calls: {called}"
    )


def test_every_server_the_listing_spawned_is_gone_when_it_returns(
    tmp_path, project, transcript, spawned
):
    """FR3's teardown at the command's own level: `list` exits owning no processes.

    The pids come from the servers themselves, written as they start. Asking the pool what it
    closed would be asking the one component whose answer is wrong in the case this is about.
    """
    registry_file = tmp_path / "registry.json"

    for name in ("one", "two"):
        add_project(str(project(name)), None, registry_file=registry_file)

    code, out, err = listing(registry_file, make_pool=stand_in_pool)

    assert code == 0, err
    assert len(spawned()) == 2, f"the listing did not spawn one server per project: {spawned()}"
    assert [pid for pid in spawned() if is_running(pid)] == [], "a server outlived the command"


def test_a_registered_path_that_is_gone_is_a_row_and_spawns_nothing(
    tmp_path, project, transcript, spawned
):
    """A project deleted since it was registered: still a row, and nothing started for it."""
    registry_file = tmp_path / "registry.json"
    root = project("since-deleted")
    add_project(str(root), None, registry_file=registry_file)

    (root / ".dpm" / "dpm.db").unlink()
    (root / ".dpm").rmdir()
    root.rmdir()

    code, out, _ = listing(registry_file, make_pool=stand_in_pool)

    assert code == 0
    assert "(missing)" in out, out
    assert spawned() == [], "a server was spawned for a project that is not there"


def test_an_empty_registry_lists_nothing_and_spawns_nothing(tmp_path, transcript, spawned):
    """Nothing registered, nothing to read — and no pool built to read it with."""
    code, out, err = listing(tmp_path / "registry.json", make_pool=stand_in_pool)

    assert (code, out, err) == (0, "", "")
    assert spawned() == []
