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
    unrecognised_rows,
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


def test_retired_epics_render_as_dimmed_reference_rows_labelled_by_status():
    # A superseded epic is not a candidate (absent from next_actions); under the
    # toggle it shows dimmed, reference-only, labelled with its status word rather
    # than a progress fraction.
    old = epic(
        "docs/epics/39-02-epic-old.md",
        status="Superseded",
        stories=[Story(1, "Pending", "—"), Story(2, "Complete", "—")],
        title="Old Feature",
    )
    st = status(State.COMPLETE, actions=[], epics=[old])

    assert epic_rows(st) == []  # hidden by default, like completed epics
    (row,) = epic_rows(st, show_complete=True)
    assert row.action is None  # reference-only, not launchable
    assert row.style == "dim"
    assert "Superseded" in row.label  # status word, not a "2/2"-style fraction
    assert "Old Feature" in row.label


# --- retro-nudge collapse under show/hide-done -------------------------------


def _retro(path):
    return NextAction("retro", f"/cpm:retro {path}", path, f"Retro {path}")


def test_toggle_off_collapses_retro_candidates_into_a_summary():
    # A complete-but-not-retro'd epic is surfaced by the engine as a `retro`
    # candidate. With completed work hidden it must not pin its own row; instead a
    # single summary line carries the nudge, so "hide done" hides it like any other
    # finished epic.
    done = epic(
        "docs/epics/39-01-epic-foo.md",
        status="Complete",
        stories=[Story(1, "Complete", "—")],
        title="Foo",
    )
    rows = epic_rows(status(State.COMPLETE, actions=[_retro("docs/epics/39-01-epic-foo.md")], epics=[done]))

    assert all(r.action is None or r.action.kind != "retro" for r in rows)  # no individual retro row
    summaries = [r for r in rows if "retro pending" in r.label]
    assert len(summaries) == 1
    assert "1 complete epic " in summaries[0].label  # singular, count carried
    assert summaries[0].style == "cyan"  # same signal colour as the per-epic nudge


def test_retro_summary_row_is_not_launchable():
    done = epic("docs/epics/39-01-epic-foo.md", status="Complete", stories=[Story(1, "Complete", "—")])
    (summary,) = [
        r
        for r in epic_rows(status(State.COMPLETE, actions=[_retro("docs/epics/39-01-epic-foo.md")], epics=[done]))
        if "retro pending" in r.label
    ]
    assert summary.action is None  # nothing to launch / copy / ralph-select
    assert summary.epic is None  # drives no stories column


def test_retro_summary_counts_and_pluralises():
    epics_, actions = [], []
    for n in (1, 2, 3):
        path = f"docs/epics/39-0{n}-epic-e{n}.md"
        epics_.append(epic(path, status="Complete", stories=[Story(1, "Complete", "—")]))
        actions.append(_retro(path))
    (summary,) = [
        r for r in epic_rows(status(State.COMPLETE, actions=actions, epics=epics_)) if "retro pending" in r.label
    ]
    assert "3 complete epics " in summary.label  # plural for more than one


def test_toggle_on_shows_individual_retro_rows_and_no_summary():
    done = epic(
        "docs/epics/39-01-epic-foo.md",
        status="Complete",
        stories=[Story(1, "Complete", "—")],
        title="Foo",
    )
    rows = epic_rows(
        status(State.COMPLETE, actions=[_retro("docs/epics/39-01-epic-foo.md")], epics=[done]),
        show_complete=True,
    )

    retro_rows = [r for r in rows if r.action is not None and r.action.kind == "retro"]
    assert len(retro_rows) == 1  # individual cyan row restored under the toggle
    assert retro_rows[0].style == "cyan"
    assert not any("retro pending" in r.label for r in rows)  # summary suppressed when expanded


def test_waived_complete_epic_shows_no_retro_row_or_summary(make_project):
    # End-to-end: a `**Retro waived**:` epic produces no retro NextAction, so the
    # board renders neither a cyan retro row nor a "retro pending" summary for it.
    from status_model import derive_project

    from test_derivation import epic_md

    repo = make_project(
        {
            "docs/epics/39-01-epic-foo.md": epic_md(
                "Complete", [(1, "Complete", "—")], retro_waived="2026-07-20 — clean epic"
            ),
        }
    )
    rows = epic_rows(derive_project(repo))  # default: completed work hidden
    assert not any(r.action is not None and r.action.kind == "retro" for r in rows)
    assert not any("retro pending" in r.label for r in rows)


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
    # show_complete=True so the retro candidate stays an inline row — the default
    # view collapses it into a summary (covered by the retro-collapse tests above);
    # here we assert the display ordering of the candidates themselves.
    rows = epic_rows(
        status(State.IN_PROGRESS, actions=actions, epics=[in_progress, ready, blocked, done_no_retro]),
        show_complete=True,
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


# --- unrecognised-status lint ------------------------------------------------


def test_lead_token_story_renders_by_its_token_and_is_not_flagged():
    foo = epic(
        "docs/epics/39-01-epic-foo.md",
        stories=[Story(1, "In Progress — mid conversion", "—", title="Convert")],
    )
    (label, style) = story_rows(foo)[0]
    assert "In Progress" in label  # the token, not the note
    assert "mid conversion" not in label
    assert style == "yellow"
    assert unrecognised_rows(foo) == []


def test_story_row_flags_an_unrecognised_status():
    foo = epic(
        "docs/epics/39-01-epic-foo.md",
        stories=[Story(1, "Folded into Story 10 — delivered", "—", title="Fold")],
    )
    (label, style) = story_rows(foo)[0]
    assert label.startswith("⚠")
    assert "Folded into Story 10" in label  # raw noise shown, not guessed
    assert style == "bold red"


def test_story_level_superseded_is_flagged():
    # Superseded/Withdrawn are epic-level only → unrecognised on a story.
    foo = epic("docs/epics/39-01-epic-foo.md", stories=[Story(1, "Withdrawn", "—", title="X")])
    (label, _style) = story_rows(foo)[0]
    assert label.startswith("⚠")


def test_epic_row_gets_a_marker_when_a_status_is_unrecognised():
    foo = epic(
        "docs/epics/39-01-epic-foo.md",
        status="In Progress",
        stories=[Story(1, "Folded into Story 10 — delivered", "—", title="Fold")],
        title="Foo",
    )
    action = NextAction("do", "/cpm:do a", "docs/epics/39-01-epic-foo.md", "Continue")
    (row,) = epic_rows(status(State.IN_PROGRESS, actions=[action], epics=[foo]))
    assert row.label.rstrip().endswith("(!)")


def test_unrecognised_rows_names_only_the_bad_statuses():
    foo = epic(
        "docs/epics/39-01-epic-foo.md",
        status="In Progress",
        stories=[
            Story(1, "Folded into Story 10", "—", title="Fold"),
            Story(2, "Complete", "—", title="Done one"),
        ],
    )
    text = " ".join(label for label, _ in unrecognised_rows(foo))
    assert "Story 1" in text and "Folded into Story 10" in text
    assert "Story 2" not in text  # recognised → not listed
