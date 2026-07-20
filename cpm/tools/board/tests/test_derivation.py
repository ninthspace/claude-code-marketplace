"""Unit + contract-conformance tests for status derivation (Story 1).

Assertions key on the structured `State` enum and integer counts, never on
rendered strings — retro 05's testing-gap lesson.
"""

from __future__ import annotations

import subprocess

import pytest

from status_model import State, Story, derive_project, read_head, story_section


def epic_md(epic_status="Pending", stories=(), blocked_by="—", retro_waived=None):
    """Render a minimal epic doc. `stories` = iterable of (num, status, blocked_by).
    `retro_waived`, when given, adds an epic-level `**Retro waived**:` marker line."""
    lines = ["# Test Epic", "", f"**Status**: {epic_status}", f"**Blocked by**: {blocked_by}"]
    if retro_waived is not None:
        lines.append(f"**Retro waived**: {retro_waived}")
    lines.append("")
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


# --- retired epics (Superseded / Withdrawn) ----------------------------------


@pytest.mark.parametrize("retired", ["Superseded", "Withdrawn"])
def test_retired_epic_is_excluded_from_state(make_project, retired):
    # An active COMPLETE epic plus a retired epic whose pending stories would
    # otherwise drag the project to in-progress. The retired epic is excluded,
    # so the project reads Complete.
    repo = make_project(
        {
            "docs/epics/39-01-epic-live.md": epic_md("Complete", [(1, "Complete", "—")]),
            "docs/epics/39-02-epic-old.md": epic_md(retired, [(1, "Pending", "—"), (2, "Pending", "—")]),
        }
    )
    assert derive_project(repo).state is State.COMPLETE


@pytest.mark.parametrize("retired", ["Superseded", "Withdrawn"])
def test_project_with_only_retired_epics_is_complete(make_project, retired):
    # Every epic retired → nothing left to action → Complete, not a stuck state.
    repo = make_project(
        {"docs/epics/39-01-epic-old.md": epic_md(retired, [(1, "Pending", "—")])}
    )
    assert derive_project(repo).state is State.COMPLETE


def test_retired_epic_stories_count_as_done(make_project):
    repo = make_project(
        {
            "docs/epics/39-01-epic-live.md": epic_md(
                "In Progress", [(1, "Complete", "—"), (2, "Pending", "—")]
            ),
            "docs/epics/39-02-epic-old.md": epic_md("Superseded", [(1, "Pending", "—"), (2, "Pending", "—")]),
        }
    )
    status = derive_project(repo)
    # Everything counts: the live epic contributes 1/2, and the retired epic's two
    # stories all count as done (its work is closed out) — so 3/4 overall.
    assert (status.complete_stories, status.total_stories) == (3, 4)


def test_retired_epic_is_not_a_next_action(make_project):
    repo = make_project(
        {
            "docs/epics/39-01-epic-live.md": epic_md("In Progress", [(1, "In Progress", "—")]),
            "docs/epics/39-02-epic-old.md": epic_md("Withdrawn", [(1, "Pending", "—")]),
        }
    )
    targets = [a.target_path or "" for a in derive_project(repo).next_actions]
    assert any("39-01-epic-live" in t for t in targets)  # live epic is a candidate
    assert not any("39-02-epic-old" in t for t in targets)  # retired epic never is


def test_retired_epic_does_not_nudge_a_retro(make_project):
    # A retired epic counts as done but has nothing to reflect on — it must NOT
    # produce a `/cpm:retro` candidate (that's `/cpm:archive`'s job).
    repo = make_project(
        {"docs/epics/39-01-epic-old.md": epic_md("Withdrawn", [(1, "Pending", "—")])}
    )
    kinds = [a.kind for a in derive_project(repo).next_actions]
    assert "retro" not in kinds


# --- "Done" as a synonym for "Complete" --------------------------------------


def test_done_story_counts_toward_progress(make_project):
    # A story authored with `Status: Done` (off-spec but real — see the board's
    # tolerant read) counts as finished, exactly like Complete.
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md("Done", [(1, "Done", "—")])}
    )
    status = derive_project(repo)
    assert (status.complete_stories, status.total_stories) == (1, 1)


def test_all_done_stories_resolve_to_complete_state(make_project):
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md("Done", [(1, "Done", "—"), (2, "done", "—")])}
    )
    assert derive_project(repo).state is State.COMPLETE


# --- dependency semantics of terminal statuses -------------------------------


def test_dependency_on_done_epic_is_satisfied(make_project):
    # Done is finished work, so a dependency on it is met: B's pending story is
    # unblocked → the project is actionable (in-progress), not blocked.
    repo = make_project(
        {
            "docs/epics/39-01-epic-a.md": epic_md("Done", [(1, "Done", "—")]),
            "docs/epics/39-02-epic-b.md": epic_md(
                "Pending", [(1, "Pending", "—")], blocked_by="Epic 39-01-epic-a"
            ),
        }
    )
    assert derive_project(repo).state is State.IN_PROGRESS


@pytest.mark.parametrize("retired", ["Superseded", "Withdrawn"])
def test_dependency_on_retired_epic_stays_permanently_blocked(make_project, retired):
    # A retired epic's work will never be done, so it never satisfies a dependency:
    # anything waiting on it stays blocked, surfacing it as a real blocker.
    repo = make_project(
        {
            "docs/epics/39-01-epic-a.md": epic_md(retired, [(1, "Pending", "—")]),
            "docs/epics/39-02-epic-b.md": epic_md(
                "Pending", [(1, "Pending", "—")], blocked_by="Epic 39-01-epic-a"
            ),
        }
    )
    assert derive_project(repo).state is State.BLOCKED


# --- lead-token status parsing & the unrecognised-status lint ----------------


def test_lead_token_status_counts_as_done(make_project):
    # "Complete — <note>" reads as Complete; the trailing note is ignored by logic.
    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md(
                "Complete", [(1, "Complete — folded into Story 10; do not run", "—")]
            )
        }
    )
    status = derive_project(repo)
    assert (status.complete_stories, status.total_stories) == (1, 1)
    assert status.state is State.COMPLETE


def test_lead_token_applies_to_pending(make_project):
    # The convention holds for every status, not just done.
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending — waiting on infra", "—")])}
    )
    assert derive_project(repo).state is State.EPICS_READY


def test_unrecognised_status_is_not_counted(make_project):
    # A prose status with no leading status word is conservative: never counted done.
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Folded into Story 10 — delivered", "—")])}
    )
    status = derive_project(repo)
    assert (status.complete_stories, status.total_stories) == (0, 1)


def test_status_token_and_recognition():
    from status_model import _is_recognised_status, _status_token

    assert _status_token("Complete — folded in") == "Complete"
    assert _status_token("In Progress") == "In Progress"
    assert _status_token("Done (see #10)") == "Done"
    assert _is_recognised_status("Complete — note")
    assert _is_recognised_status("Pending")
    assert _is_recognised_status("")  # empty is absence, not noise
    assert not _is_recognised_status("Folded into Story 10 — delivered")
    # Superseded/Withdrawn are epic-level only → unrecognised on a story.
    assert not _is_recognised_status("Superseded")
    assert _is_recognised_status("Superseded", epic=True)
    assert _is_recognised_status("Superseded — replaced by 12-03", epic=True)


# --- retro-waived marker -----------------------------------------------------


def test_parse_epic_reads_the_retro_waived_marker(make_project):
    from status_model import parse_epic

    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md(
                "Complete", [(1, "Complete", "—")], retro_waived="2026-07-20 — clean epic"
            ),
            "docs/epics/39-02-epic-bar.md": epic_md("Complete", [(1, "Complete", "—")]),
        }
    )
    assert parse_epic(repo / "docs/epics/39-01-epic-foo.md").retro_waived is True
    assert parse_epic(repo / "docs/epics/39-02-epic-bar.md").retro_waived is False


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


# --- story_section: slice one story's section out of an epic doc ---------------

_THREE = epic_md(
    "In Progress", [(1, "Complete", "—"), (2, "In Progress", "—"), (3, "Pending", "—")]
)


def test_story_section_returns_only_the_matching_story_by_number():
    section = story_section(_THREE, Story(number=2, status="In Progress", blocked_by="—", title="Story 2"))
    assert "## Story 2" in section
    assert "**Status**: In Progress" in section
    # It is a section, not the whole file: neither sibling story nor the H1 preamble.
    assert "## Story 1" not in section
    assert "## Story 3" not in section
    assert "# Test Epic" not in section


def test_story_section_falls_back_to_the_title_when_number_is_absent():
    section = story_section(_THREE, Story(number=None, status="", blocked_by="—", title="Story 3"))
    assert "## Story 3" in section
    assert "## Story 2" not in section


def test_story_section_is_empty_when_no_story_matches():
    assert story_section(_THREE, Story(number=99, status="", blocked_by="—", title="Nope")) == ""
