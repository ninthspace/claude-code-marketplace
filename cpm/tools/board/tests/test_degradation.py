"""Unit tests for graceful degradation (Story 3).

The sweep must isolate per-project failures: an unreachable path or a
malformed/half-written artifact resolves to the `unknown` (`?`) state, and one
bad project never aborts the whole run.
"""

from __future__ import annotations

from status_model import State, derive_project, derive_projects

from test_derivation import epic_md


def test_unreachable_path_is_unknown_and_labelled(tmp_path):
    missing = tmp_path / "does-not-exist"
    status = derive_project(missing)
    assert status.state is State.UNKNOWN
    assert status.label == "unreachable"
    assert status.next_actions == []


def test_malformed_artifact_is_unknown(make_project):
    repo = make_project({"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending", "—")])})
    # Corrupt the epic with bytes that are not valid UTF-8 — a half-written file.
    (repo / "docs" / "epics" / "39-01-epic-foo.md").write_bytes(b"\xff\xfe# broken \x80\x81")
    status = derive_project(repo)
    assert status.state is State.UNKNOWN
    assert status.label == "unparseable"
    assert status.next_actions == []


def test_one_bad_project_does_not_abort_the_sweep(make_project, tmp_path):
    good = make_project({"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending", "—")])})
    bad = tmp_path / "gone"

    results = derive_projects([bad, good])

    assert len(results) == 2  # one row per input, nothing dropped
    assert results[0].state is State.UNKNOWN and results[0].label == "unreachable"
    assert results[1].state is State.EPICS_READY  # good project still derived correctly
