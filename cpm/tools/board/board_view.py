"""Pure view helpers for the cpm board roll-up.

This module is deliberately free of any Textual import (retro 09's pure-module
pattern), so RAG mapping, attention-first ordering, and next-action formatting
are unit-testable without standing up the TUI. It reads the derivation engine's
own outputs — ``state``, ``rag``, and the ordered ``next_actions`` list — and
never recomputes precedence (retro 08's "one rule, two callers"): the roll-up and
the drill-down both project the same engine result, so they cannot disagree.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from status_model import _NO_DEP, Epic, NextAction, ProjectStatus, State

#: Rich style per project state, on the *same palette as the epics legend* so the
#: two columns read alike: green = ready to pick up · yellow = in-progress ·
#: red = blocked · magenta = specs but no epics ("needs epics") · dim = done or no
#: artifacts. Colour carries the state, so the project row shows no status word.
_PROJECT_STYLE: dict[State, str] = {
    State.BLOCKED: "red",
    State.IN_PROGRESS: "yellow",
    State.EPICS_READY: "green",
    State.SPEC_READY: "magenta",
    State.COMPLETE: "green",
    State.NO_ARTIFACTS: "dim",
    State.UNKNOWN: "dim",
}

#: Attention-first ordering: lower rank sorts higher. Action-needing states
#: (blocked, in-progress, spec-waiting-on-epics, epics-ready) sit above idle ones
#: (complete, no-artifacts, unknown).
_ATTENTION_RANK: dict[State, int] = {
    State.BLOCKED: 0,
    State.IN_PROGRESS: 1,
    State.SPEC_READY: 2,
    State.EPICS_READY: 3,
    State.COMPLETE: 4,
    State.NO_ARTIFACTS: 5,
    State.UNKNOWN: 6,
}


def project_style(state: State) -> str:
    """Rich style for a project row, on the epics-legend palette (see ``_PROJECT_STYLE``)."""
    return _PROJECT_STYLE.get(state, "dim")


def attention_rank(state: State) -> int:
    """Sort rank for attention-first ordering (unknown states sort last)."""
    return _ATTENTION_RANK.get(state, len(_ATTENTION_RANK))


def next_action_text(status: ProjectStatus) -> str:
    """Primary next-action label, with a ``+N`` count of the extra candidates."""
    action = status.primary_action
    if action is None:
        return "—"
    extra = len(status.next_actions) - 1
    return f"{action.label}  +{extra}" if extra > 0 else action.label


def sort_rows(rows: list[tuple[str, ProjectStatus]]) -> list[tuple[str, ProjectStatus]]:
    """Order ``(name, status)`` rows attention-first, then by name for stability."""
    return sorted(rows, key=lambda row: (attention_rank(row[1].state), row[0].lower()))


def project_label(name: str, status: ProjectStatus) -> str:
    """Left-column line for a project: name · progress. The state word is dropped —
    colour (``project_style``) conveys it, matching the epics column."""
    return f"{name}  ·  {status.progress}"


# --- Miller-column model: epics (middle) and stories (right) ------------------
#
# The middle column IS the engine's ordered candidate list (`next_actions`) — the
# launchable surface — one row per candidate, projected with a human title. Only
# actionable work is a candidate, so complete-and-retro'd epics never appear here;
# the `show_complete` toggle appends them (dimmed, unlaunchable) for reference.

#: Rich style per story status for the right column.
_STORY_STYLE: dict[str, str] = {
    "Complete": "green",
    "In Progress": "yellow",
    "Pending": "",
}


@dataclass
class EpicRow:
    """One middle-column row. ``action`` is the launchable candidate (``None`` for a
    reference-only done epic); ``epic`` drives the stories column (``None`` for a
    spec-breakdown row, which targets a spec, not an epic)."""

    label: str
    style: str
    action: NextAction | None
    epic: Epic | None


def _epic_prefix(epic: Epic) -> str:
    """The ``NN-NN`` identifier from a two-part epic filename, else the stem."""
    match = re.match(r"^(\d+-\d+)", epic.path.name)
    return match.group(1) if match else epic.path.stem


def _progress(epic: Epic) -> str:
    total = len(epic.stories)
    done = sum(1 for story in epic.stories if story.status == "Complete")
    return f"{done}/{total}" if total else "—"


def _is_in_progress(epic: Epic) -> bool:
    statuses = [story.status for story in epic.stories]
    return any(s == "In Progress" for s in statuses) or (
        any(s == "Complete" for s in statuses) and any(s == "Pending" for s in statuses)
    )


def _row_style(action: NextAction, epic: Epic | None) -> str:
    """Rich style encoding the candidate's status — the colour that replaces the
    status word. in-progress and ready are deliberately distinct.

    green = ready · yellow = in-progress · red = blocked · cyan = retro ·
    magenta = spec break-down · dim = done/other.
    """
    kind = action.kind
    if kind == "do":
        return "yellow" if (epic and _is_in_progress(epic)) else "green"
    return {
        "attention:unblock": "red",
        "retro": "cyan",
        "epics": "magenta",
        "discover": "dim",
    }.get(kind, "")


#: Display order for the epics column, independent of the engine's priority list:
#: in-progress → ready → blocked → retro → needs-epics. (A "do" row splits into
#: in-progress vs ready by whether the epic has started; done/other rows sort last.)
def _row_rank(row: "EpicRow") -> int:
    action = row.action
    if action is None:
        return 99  # done / reference-only rows go last
    if action.kind == "do":
        return 0 if (row.epic is not None and _is_in_progress(row.epic)) else 1
    return {"attention:unblock": 2, "retro": 3, "epics": 4}.get(action.kind, 5)


def _action_row(action: NextAction, epic: Epic | None) -> EpicRow:
    # Status is carried by colour (see _row_style), so the label is just the
    # identity + progress — no redundant "· ready"/"· in progress" word.
    if epic is not None:
        title = epic.title or epic.path.stem
        label = f"{_epic_prefix(epic)} · {title}  ·  {_progress(epic)}"
    elif action.target_path:
        # Spec-breakdown: a spec with no epics yet. Name the spec that needs them.
        label = f"{Path(action.target_path).name} needs epics"
    else:
        # discover / no-artifacts: no target — use the engine's own label.
        label = action.label
    return EpicRow(label=label, style=_row_style(action, epic), action=action, epic=epic)


def _done_row(epic: Epic) -> EpicRow:
    title = epic.title or epic.path.stem
    total = len(epic.stories)
    return EpicRow(
        label=f"{_epic_prefix(epic)} · {title}  ·  {total}/{total}",
        style="dim",
        action=None,
        epic=epic,
    )


def epic_rows(status: ProjectStatus, *, show_complete: bool = False) -> list[EpicRow]:
    """Middle-column rows for a project: the ordered candidates, plus (when
    ``show_complete``) the finished-and-retro'd epics as dimmed reference rows."""
    by_path = {str(epic.path): epic for epic in status.epics}
    seen: set[str] = set()
    rows: list[EpicRow] = []
    for action in status.next_actions:
        epic = by_path.get(action.target_path) if action.target_path else None
        if epic is not None:
            seen.add(str(epic.path))
        rows.append(_action_row(action, epic))
    # Re-order for display only — the engine's next_actions order drives launch
    # precedence and must not change. Stable sort keeps engine/filename order
    # within each rank group.
    rows.sort(key=_row_rank)
    if show_complete:
        for epic in status.epics:
            if str(epic.path) not in seen:
                rows.append(_done_row(epic))
    return rows


def blocking_rows(epic: Epic) -> list[tuple[str, str]]:
    """Right-column detail for a blocked epic: a header, then each dependency it's
    waiting on — one per line.

    Reads the epic's own dependency fields (its ``Blocked by`` and each pending
    story's) — the same fields the engine used to classify it as blocked — and
    splits the comma-separated references so a long dependency list becomes a tidy
    list rather than one run-on line that wraps. Duplicate references are collapsed.
    A blocked epic always has at least one real dependency; the fallback is defensive.
    """
    sources = [epic.blocked_by, *(s.blocked_by for s in epic.stories if s.status == "Pending")]
    refs: list[str] = []
    for blocked_by in sources:
        if blocked_by in _NO_DEP:
            continue
        for ref in blocked_by.split(","):
            ref = ref.strip()
            if ref and ref not in _NO_DEP and ref not in refs:
                refs.append(ref)
    if not refs:
        refs = ["an incomplete dependency"]
    return [("Blocked by:", "bold red"), *[(ref, "red") for ref in refs]]


def spec_preview_rows(text: str) -> list[tuple[str, str]]:
    """Right-column preview of a spec selected for break-down: its own lines, with
    markdown headings emphasised and metadata dimmed so the spec is scannable in
    place. A ``needs epics`` row has no stories yet — this shows the source instead.
    """
    rows: list[tuple[str, str]] = []
    for raw in text.splitlines():
        line = raw.rstrip()
        if line.startswith("#"):
            style = "bold"
        elif line.startswith("**") or line.startswith(">"):
            style = "dim"
        else:
            style = ""
        rows.append((line or " ", style))
    return rows


def story_rows(epic: Epic | None, *, show_complete: bool = False) -> list[tuple[str, str]]:
    """Right-column ``(label, style)`` rows for the selected epic's stories.

    Complete stories are hidden unless ``show_complete``; a spec-breakdown row
    (``epic is None``) has no stories.
    """
    if epic is None:
        return []
    rows: list[tuple[str, str]] = []
    for story in epic.stories:
        if not show_complete and story.status == "Complete":
            continue
        number = story.number if story.number is not None else "?"
        title = story.title or ""
        label = f"Story {number} · {title}  ·  {story.status or '—'}"
        rows.append((label, _STORY_STYLE.get(story.status, "")))
    return rows
