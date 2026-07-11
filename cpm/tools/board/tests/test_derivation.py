"""Unit + contract-conformance tests for status derivation (Story 1).

Assertions key on the structured `State` enum and integer counts, never on
rendered strings — retro 05's testing-gap lesson.
"""

from __future__ import annotations

import subprocess

import pytest

from status_model import State, derive_project, read_head


def epic_md(epic_status="Pending", stories=(), blocked_by="—"):
    """Render a minimal epic doc. `stories` = iterable of (num, status, blocked_by)."""
    lines = ["# Test Epic", "", f"**Status**: {epic_status}", f"**Blocked by**: {blocked_by}", ""]
    for num, status, dep in stories:
        lines += [f"## Story {num}", f"**Story**: {num}", f"**Status**: {status}", f"**Blocked by**: {dep}", ""]
    return "\n".join(lines)


# --- individual state cases --------------------------------------------------


def test_no_artifacts(make_project):
    repo = make_project({"README.md": "hi"})
    assert derive_project(repo).state is State.NO_ARTIFACTS


def test_spec_ready(make_project):
    repo = make_project({"docs/specifications/39-spec-foo.md": "# Spec"})
    assert derive_project(repo).state is State.SPEC_READY


def test_epics_ready_when_all_stories_pending(make_project):
    repo = make_project(
        {
            "docs/specifications/39-spec-foo.md": "# Spec",
            "docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending", "—"), (2, "Pending", "—")]),
        }
    )
    assert derive_project(repo).state is State.EPICS_READY


def test_in_progress_when_a_story_is_in_progress(make_project):
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md("In Progress", [(1, "In Progress", "—"), (2, "Pending", "—")])}
    )
    assert derive_project(repo).state is State.IN_PROGRESS


def test_in_progress_when_complete_and_pending_mix(make_project):
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Complete", "—"), (2, "Pending", "—")])}
    )
    assert derive_project(repo).state is State.IN_PROGRESS


def test_complete_when_all_stories_complete(make_project):
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md("Complete", [(1, "Complete", "—"), (2, "Complete", "—")])}
    )
    assert derive_project(repo).state is State.COMPLETE


def test_blocked_when_all_pending_work_is_dependency_blocked(make_project):
    # Single epic whose epic-level dep points at an epic not present (never Complete),
    # so every pending story is blocked and nothing is in progress -> blocked.
    repo = make_project(
        {
            "docs/epics/39-02-epic-foo.md": epic_md(
                "Pending",
                [(1, "Pending", "—"), (2, "Pending", "—")],
                blocked_by="Epic 39-01-epic-missing",
            )
        }
    )
    assert derive_project(repo).state is State.BLOCKED


# --- story counts ------------------------------------------------------------


def test_story_progress_counts(make_project):
    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md(
                stories=[(1, "Complete", "—"), (2, "Pending", "—"), (3, "Pending", "—")]
            )
        }
    )
    status = derive_project(repo)
    assert (status.complete_stories, status.total_stories) == (1, 3)
    assert status.progress == "1/3"


# --- contract conformance (table-driven from status-model.md) ---------------

CONFORMANCE = [
    ("no-artifacts", {"README.md": "x"}, State.NO_ARTIFACTS),
    ("spec-ready", {"docs/specifications/39-spec-foo.md": "# Spec"}, State.SPEC_READY),
    (
        "epics-ready",
        {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending", "—")])},
        State.EPICS_READY,
    ),
    (
        "in-progress",
        {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Complete", "—"), (2, "Pending", "—")])},
        State.IN_PROGRESS,
    ),
    (
        "complete",
        {"docs/epics/39-01-epic-foo.md": epic_md("Complete", [(1, "Complete", "—")])},
        State.COMPLETE,
    ),
]


@pytest.mark.parametrize("name,files,expected", CONFORMANCE, ids=[c[0] for c in CONFORMANCE])
def test_conforms_to_contract_mapping(make_project, name, files, expected):
    assert derive_project(make_project(files)).state is expected


# --- read-only guarantee -----------------------------------------------------


def test_derivation_is_read_only(make_project):
    repo = make_project({"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Complete", "—")])})
    before = read_head(repo)

    derive_project(repo)

    assert read_head(repo) == before  # HEAD unchanged
    porcelain = subprocess.run(
        ["git", "status", "--porcelain"], cwd=repo, capture_output=True, text=True
    )
    assert porcelain.stdout.strip() == ""  # no working-tree changes
