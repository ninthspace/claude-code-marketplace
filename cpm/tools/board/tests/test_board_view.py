"""Unit tests for the pure roll-up view helpers (Story 1).

These need no Textual event loop — board_view is Textual-free — so RAG mapping,
attention ordering, and next-action formatting are asserted directly.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from board_view import (
    attention_rank,
    blocking_rows,
    epic_rows,
    next_action_text,
    project_label,
    project_style,
    sort_rows,
    story_rows,
)
from status_model import Epic, NextAction, ProjectStatus, State, Story


def status(state, *, actions=(), epics=(), complete=0, total=0, name="proj"):
    return ProjectStatus(
        path=Path("/x") / name,
        state=state,
        complete_stories=complete,
        total_stories=total,
        next_actions=list(actions),
        epics=list(epics),
    )


# --- RAG mapping -------------------------------------------------------------


@pytest.mark.parametrize(
    "state,expected",
    [
        # Same palette as the epics legend: green ready · yellow in-progress ·
        # red blocked · magenta needs-epics · dim done/none. Ready (epics-ready)
        # is now green — distinct from in-progress yellow, matching the epics.
        (State.COMPLETE, "green"),
        (State.IN_PROGRESS, "yellow"),
        (State.EPICS_READY, "green"),
        (State.SPEC_READY, "magenta"),
        (State.BLOCKED, "red"),
        (State.NO_ARTIFACTS, "dim"),
        (State.UNKNOWN, "dim"),
    ],
)
def test_project_style_maps_state_to_the_epics_palette(state, expected):
    assert project_style(state) == expected


# --- attention-first ordering ------------------------------------------------


def test_action_states_rank_above_idle_states():
    assert attention_rank(State.BLOCKED) < attention_rank(State.COMPLETE)
    assert attention_rank(State.IN_PROGRESS) < attention_rank(State.COMPLETE)
    assert attention_rank(State.SPEC_READY) < attention_rank(State.COMPLETE)


def test_sort_rows_puts_attention_first_then_alphabetical():
    rows = [
        ("zeta", status(State.COMPLETE)),
        ("alpha", status(State.COMPLETE)),
        ("beta", status(State.BLOCKED)),
        ("gamma", status(State.IN_PROGRESS)),
    ]
    ordered = [name for name, _ in sort_rows(rows)]
    assert ordered == ["beta", "gamma", "alpha", "zeta"]


# --- next-action text --------------------------------------------------------


def test_next_action_text_shows_primary_label_only_when_single():
    action = NextAction("do", "/cpm:do e", "e", "Continue e")
    assert next_action_text(status(State.IN_PROGRESS, actions=[action])) == "Continue e"


def test_next_action_text_appends_extra_candidate_count():
    actions = [
        NextAction("do", "/cpm:do e", "e", "Continue e"),
        NextAction("epics", "/cpm:epics s", "s", "Break down s"),
        NextAction("retro", "/cpm:retro d", "d", "Retro d"),
    ]
    assert next_action_text(status(State.IN_PROGRESS, actions=actions)) == "Continue e  +2"


def test_next_action_text_dashes_when_no_candidates():
    assert next_action_text(status(State.UNKNOWN)) == "—"


# --- project column label ----------------------------------------------------


def test_project_label_shows_name_and_progress_without_the_state_word():
    st = status(State.IN_PROGRESS, complete=4, total=7)
    # Colour conveys the state now — no "in-progress" word in the text.
    assert project_label("planwise", st) == "planwise  ·  4/7"


# --- epics column (the launchable candidate list) ----------------------------


def epic(path, *, status="In Progress", stories=(), title="", blocked_by="—"):
    return Epic(
        path=Path(path),
        parent="39",
        status=status,
        blocked_by=blocked_by,
        stories=list(stories),
        title=title,
    )


def test_epic_rows_are_the_candidates_projected_with_titles():
    foo = epic(
        "docs/epics/39-01-epic-foo.md",
        stories=[Story(1, "Complete", "—"), Story(2, "Pending", "—")],
        title="Foo Feature",
    )
    action = NextAction(
        "do", "/cpm:do docs/epics/39-01-epic-foo.md", "docs/epics/39-01-epic-foo.md", "Continue foo"
    )
    rows = epic_rows(status(State.IN_PROGRESS, actions=[action], epics=[foo]))

    assert len(rows) == 1
    assert "Foo Feature" in rows[0].label  # human title, not the filename
    assert "39-01" in rows[0].label
    assert rows[0].action is action  # carries the launchable command
    assert rows[0].epic is foo  # drives the stories column


def test_completed_epics_are_hidden_until_toggled():
    # A finished, retro'd epic is not a candidate → absent from next_actions.
    done = epic(
        "docs/epics/39-01-epic-foo.md",
        status="Complete",
        stories=[Story(1, "Complete", "—")],
        title="Done Epic",
    )
    st = status(State.COMPLETE, actions=[], epics=[done])

    assert epic_rows(st) == []  # hidden by default
    shown = epic_rows(st, show_complete=True)
    assert len(shown) == 1
    assert shown[0].action is None  # reference-only, not launchable
    assert shown[0].style == "dim"
    assert "1/1" in shown[0].label  # full progress, dimmed


def test_in_progress_and_ready_candidates_get_distinct_colours():
    in_progress = epic("docs/epics/39-01-epic-foo.md", stories=[Story(1, "In Progress", "—")], title="A")
    ready = epic("docs/epics/39-02-epic-bar.md", stories=[Story(1, "Pending", "—")], title="B")
    ip_action = NextAction("do", "/cpm:do a", "docs/epics/39-01-epic-foo.md", "Continue A")
    rd_action = NextAction("do", "/cpm:do b", "docs/epics/39-02-epic-bar.md", "Start B")

    ip_style = epic_rows(status(State.IN_PROGRESS, actions=[ip_action], epics=[in_progress]))[0].style
    rd_style = epic_rows(status(State.EPICS_READY, actions=[rd_action], epics=[ready]))[0].style

    assert ip_style == "yellow"
    assert rd_style == "green"
    assert ip_style != rd_style  # the distinction Chris asked for


def test_epic_row_label_omits_the_status_word():
    foo = epic("docs/epics/39-01-epic-foo.md", stories=[Story(1, "Pending", "—")], title="Foo")
    action = NextAction("do", "/cpm:do a", "docs/epics/39-01-epic-foo.md", "Start foo")
    (row,) = epic_rows(status(State.EPICS_READY, actions=[action], epics=[foo]))
    # Colour conveys status now — the word must not be in the text.
    assert "ready" not in row.label
    assert "in progress" not in row.label


def test_epic_rows_are_ordered_for_display_not_by_engine_priority():
    # The engine hands candidates in priority order (blocked → in-progress → ready
    # → needs-epics → retro); the middle column re-orders them for reading:
    # in-progress · ready · blocked · retro · needs-epics.
    in_progress = epic("docs/epics/39-01-epic-a.md", stories=[Story(1, "In Progress", "—")], title="A")
    ready = epic("docs/epics/39-02-epic-b.md", stories=[Story(1, "Pending", "—")], title="B")
    blocked = epic("docs/epics/39-03-epic-c.md", status="Pending", stories=[Story(1, "Pending", "Story 9")], title="C")
    done_no_retro = epic("docs/epics/39-04-epic-d.md", status="Complete", stories=[Story(1, "Complete", "—")], title="D")
    actions = [  # engine priority order
        NextAction("attention:unblock", None, "docs/epics/39-03-epic-c.md", "Unblock C"),
        NextAction("do", "/cpm:do a", "docs/epics/39-01-epic-a.md", "Continue A"),
        NextAction("do", "/cpm:do b", "docs/epics/39-02-epic-b.md", "Start B"),
        NextAction("epics", "/cpm:epics x", "docs/specifications/40-spec-x.md", "Break down x"),
        NextAction("retro", "/cpm:retro d", "docs/epics/39-04-epic-d.md", "Retro D"),
    ]
    rows = epic_rows(
        status(State.IN_PROGRESS, actions=actions, epics=[in_progress, ready, blocked, done_no_retro])
    )
    # Colour is a 1:1 proxy for the category, so the style sequence reads the order.
    assert [r.style for r in rows] == ["yellow", "green", "red", "cyan", "magenta"]
    assert rows[-1].epic is None  # the needs-epics row targets a spec, not an epic


# --- blocked epic: what it's waiting on --------------------------------------


def test_blocking_rows_list_each_dependency_one_per_line():
    bar = epic(
        "docs/epics/39-02-epic-bar.md",
        status="Pending",
        blocked_by="Epic 94-02, Epic 94-04",  # comma-separated → split, one per line
        stories=[Story(1, "Pending", "Story 1"), Story(2, "Pending", "Story 1")],  # dup dep
    )
    labels = [label for label, _ in blocking_rows(bar)]
    assert labels[0] == "Blocked by:"  # a header
    assert labels[1:] == ["Epic 94-02", "Epic 94-04", "Story 1"]  # split + deduped
    assert all("waiting on" not in line for line in labels)  # no run-on prose


def test_blocking_rows_are_defensive_when_no_named_dependency():
    orphan = epic("docs/epics/39-02-epic-bar.md", status="Pending", stories=[Story(1, "Pending", "—")])
    labels = [label for label, _ in blocking_rows(orphan)]
    assert labels[0] == "Blocked by:"
    assert any("incomplete dependency" in line for line in labels)


# --- stories column ----------------------------------------------------------


def test_story_rows_hide_complete_and_show_titles():
    foo = epic(
        "docs/epics/39-01-epic-foo.md",
        stories=[Story(1, "Complete", "—", title="Story 1"), Story(2, "Pending", "—", title="Wire it up")],
    )
    labels = [label for label, _ in story_rows(foo)]
    assert all("Complete" not in label for label in labels)  # complete hidden
    assert any("Wire it up" in label for label in labels)  # title shown
    assert len(story_rows(foo, show_complete=True)) == 2  # toggle reveals the complete one


def test_story_rows_empty_for_a_spec_breakdown_row():
    assert story_rows(None) == []
