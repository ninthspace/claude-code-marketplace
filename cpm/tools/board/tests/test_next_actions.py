"""Unit tests for the multi-action candidate list (Story 2).

Assertions key on the structured `NextAction` fields (kind / command), never on
rendered strings — retro 05's testing-gap lesson. The candidate ordering is the
contract's priority list in `status-model.md`.
"""

from __future__ import annotations

from status_model import State, derive_project

from test_derivation import epic_md


def primary(repo):
    status = derive_project(repo)
    action = status.primary_action
    assert action is not None
    return status, action


# --- primary action per state (the core Story 2 criterion) -------------------


def test_no_artifacts_recommends_discover(make_project):
    repo = make_project({"README.md": "hi"})
    status, action = primary(repo)
    assert status.state is State.NO_ARTIFACTS
    assert (action.kind, action.command) == ("discover", "/cpm:discover")


def test_spec_ready_recommends_epics(make_project):
    repo = make_project({"docs/specifications/39-spec-foo.md": "# Spec"})
    status, action = primary(repo)
    assert status.state is State.SPEC_READY
    assert action.kind == "epics"
    assert action.command == "/cpm:epics docs/specifications/39-spec-foo.md"


def test_epics_ready_recommends_do_start(make_project):
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending", "—")])}
    )
    status, action = primary(repo)
    assert status.state is State.EPICS_READY
    assert action.kind == "do"
    assert action.command == "/cpm:do docs/epics/39-01-epic-foo.md"


def test_in_progress_recommends_do_that_epic(make_project):
    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md(
                "In Progress", [(1, "In Progress", "—"), (2, "Pending", "—")]
            )
        }
    )
    status, action = primary(repo)
    assert status.state is State.IN_PROGRESS
    assert action.kind == "do"
    assert action.command == "/cpm:do docs/epics/39-01-epic-foo.md"


def test_complete_recommends_retro(make_project):
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md("Complete", [(1, "Complete", "—")])}
    )
    status, action = primary(repo)
    assert status.state is State.COMPLETE
    assert action.kind == "retro"
    assert action.command == "/cpm:retro docs/epics/39-01-epic-foo.md"


def test_blocked_recommends_attention_with_no_command(make_project):
    repo = make_project(
        {
            "docs/epics/39-02-epic-foo.md": epic_md(
                "Pending",
                [(1, "Pending", "—"), (2, "Pending", "—")],
                blocked_by="Epic 39-01-epic-missing",
            )
        }
    )
    status, action = primary(repo)
    assert status.state is State.BLOCKED
    assert action.kind == "attention:unblock"
    assert action.command is None  # must NOT be launchable
    assert "39-01-epic-missing" in action.label


# --- multi-action ordering ---------------------------------------------------


def test_ordering_in_progress_before_epics_ready(make_project):
    # Two epics under one spec: 39-01 in-progress, 39-02 all-pending (ready).
    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md(
                "In Progress", [(1, "In Progress", "—")]
            ),
            "docs/epics/39-02-epic-bar.md": epic_md(stories=[(1, "Pending", "—")]),
        }
    )
    actions = derive_project(repo).next_actions
    kinds = [(a.kind, a.command) for a in actions if a.kind == "do"]
    # in-progress epic (39-01) comes before epics-ready epic (39-02)
    assert kinds[0][1] == "/cpm:do docs/epics/39-01-epic-foo.md"
    assert kinds[1][1] == "/cpm:do docs/epics/39-02-epic-bar.md"


def test_spec_without_epics_yields_epics_candidate_alongside_others(make_project):
    # Spec 40 has no epics; spec 39 has an in-progress epic.
    repo = make_project(
        {
            "docs/specifications/39-spec-foo.md": "# Spec",
            "docs/specifications/40-spec-bar.md": "# Spec",
            "docs/epics/39-01-epic-foo.md": epic_md("In Progress", [(1, "In Progress", "—")]),
        }
    )
    actions = derive_project(repo).next_actions
    kinds = [a.kind for a in actions]
    assert kinds[0] == "do"  # in-progress epic is primary
    epics_actions = [a for a in actions if a.kind == "epics"]
    assert len(epics_actions) == 1
    assert epics_actions[0].command == "/cpm:epics docs/specifications/40-spec-bar.md"


def test_complete_epic_with_matching_retro_yields_no_retro_candidate(make_project):
    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md("Complete", [(1, "Complete", "—")]),
            "docs/retros/01-retro-foo.md": "Reflection on 39-01-epic-foo delivery.",
        }
    )
    actions = derive_project(repo).next_actions
    assert [a for a in actions if a.kind == "retro"] == []


def test_retro_waived_epic_yields_no_retro_candidate(make_project):
    # A `**Retro waived**:` marker (set by /cpm:retro triage) satisfies the retro
    # requirement just like an actual retro file — no /cpm:retro nag.
    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md(
                "Complete", [(1, "Complete", "—")], retro_waived="2026-07-20 — clean epic"
            ),
        }
    )
    actions = derive_project(repo).next_actions
    assert [a for a in actions if a.kind == "retro"] == []


def test_complete_epic_without_waiver_or_retro_still_recommends_retro(make_project):
    # Guard: the waiver is the only thing that suppresses the nudge — an ordinary
    # completed epic still gets its /cpm:retro candidate.
    repo = make_project(
        {"docs/epics/39-01-epic-foo.md": epic_md("Complete", [(1, "Complete", "—")])}
    )
    actions = derive_project(repo).next_actions
    assert [a.kind for a in actions if a.kind == "retro"] == ["retro"]
