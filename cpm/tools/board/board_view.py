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

from rich.console import RenderableType
from rich.table import Table
from rich.text import Text

from status_model import (
    _NO_DEP,
    Epic,
    NextAction,
    ProjectStatus,
    State,
    _is_done,
    _is_inactive,
    _is_pending,
    _is_recognised_status,
    _status_token,
)
from status_model import _is_in_progress as _status_in_progress

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


#: The "running" pill for a project with a live board-launched tmux session. Blue
#: is unused by the project-state palette (red/yellow/green/magenta/dim), so the
#: pill reads as distinct on any row. It is foreground-only (no background), so
#: ``InverseOptionList``'s cursor blend — which samples a row's own colour and
#: background — is unaffected: the label segments come first, so the row colour is
#: still sampled from them and no background is introduced.
_LIVE_PILL = "● live"
_LIVE_PILL_STYLE = "bold blue"


def _live_pill(count: int) -> str:
    """The pill text for ``count`` live sessions: ``● live`` for one, ``● N live`` for
    several — so a project running multiple sessions reads as distinct at a glance."""
    return _LIVE_PILL if count == 1 else f"● {count} live"


def project_row_text(name: str, status: ProjectStatus, *, live: int = 0) -> RenderableType:
    """Projects-column row: the coloured name · progress label, and — when the
    project has ``live`` running board-launched sessions (a count) — a "live" pill
    **right-aligned** to the column edge.

    ``live == 0`` → a plain ``Text`` (the common case). One or more → an expanding
    ``Table.grid``: the label fills a ratio column and the pill sits in a
    right-justified column, so it hugs the right regardless of column width. The pill
    shows the session count when more than one (``● 2 live``) and keeps its own
    colour (a separate cell) over the row's status colour."""
    label = Text(project_label(name, status), style=project_style(status.state))
    if not live:
        return label
    row = Table.grid(expand=True)
    row.add_column(ratio=1)  # label — fills the remaining width
    row.add_column(justify="right")  # pill — hugs the right edge
    row.add_row(label, Text(_live_pill(live), style=_LIVE_PILL_STYLE))
    return row


# --- Miller-column model: epics (middle) and stories (right) ------------------
#
# The middle column IS the engine's ordered candidate list (`next_actions`) — the
# launchable surface — one row per candidate, projected with a human title. Only
# actionable work is a candidate, so complete-and-retro'd epics never appear here;
# the `show_complete` toggle appends them (dimmed, unlaunchable) for reference.

#: Marker + style for a status the tool doesn't recognise (free-text prose, a typo,
#: or a story-level Superseded/Withdrawn). The board *surfaces* it rather than
#: counting it — the user (or a /cpm skill) normalises the source.
_WARN_GLYPH = "⚠"
_WARN_MARKER = "(!)"
_WARN_STYLE = "bold red"


def _story_style(status: str) -> str:
    """Rich style for a story row by its status token: green = done, yellow =
    in-progress, unstyled otherwise."""
    if _is_done(status):
        return "green"
    if _status_in_progress(status):
        return "yellow"
    return ""


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
    done = sum(1 for story in epic.stories if _is_done(story.status))
    return f"{done}/{total}" if total else "—"


def _is_in_progress(epic: Epic) -> bool:
    statuses = [story.status for story in epic.stories]
    return any(_status_in_progress(s) for s in statuses) or (
        any(_is_done(s) for s in statuses) and any(_is_pending(s) for s in statuses)
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


def _inactive_row(epic: Epic) -> EpicRow:
    """A retired (Superseded/Withdrawn) epic: reference-only, labelled with its
    terminal status word rather than a progress fraction — its stories no longer
    count toward the project's progress."""
    title = epic.title or epic.path.stem
    return EpicRow(
        label=f"{_epic_prefix(epic)} · {title}  ·  {epic.status}",
        style="dim",
        action=None,
        epic=epic,
    )


#: Style + glyph for the collapsed retro-nudge summary. Cyan matches the per-epic
#: retro candidate colour (see ``_row_style``) so the summary reads as the same
#: "reflect on this" signal, just rolled up.
_RETRO_SUMMARY_STYLE = "cyan"
_RETRO_GLYPH = "⟳"


def _retro_summary_row(count: int) -> EpicRow:
    """A single, non-launchable line standing in for the complete-but-not-retro'd
    epics that are hidden when completed work is collapsed — so the retro nudge
    survives the hide instead of vanishing with the rows. ``action``/``epic`` are
    ``None`` (like the dimmed reference rows), so it can't be launched, copied, or
    ralph-selected."""
    noun = "epic" if count == 1 else "epics"
    return EpicRow(
        label=f"{_RETRO_GLYPH} {count} complete {noun} · retro pending",
        style=_RETRO_SUMMARY_STYLE,
        action=None,
        epic=None,
    )


def _epic_has_unrecognised(epic: Epic) -> bool:
    """True when the epic's own status or any of its stories' statuses is
    unrecognised — the trigger for the row's ``(!)`` flag."""
    if not _is_recognised_status(epic.status, epic=True):
        return True
    return any(not _is_recognised_status(s.status) for s in epic.stories)


def epic_rows(status: ProjectStatus, *, show_complete: bool = False) -> list[EpicRow]:
    """Middle-column rows for a project: the ordered candidates, plus (when
    ``show_complete``) the finished-and-retro'd epics — and any retired
    (Superseded/Withdrawn) epics — as dimmed reference rows."""
    by_path = {str(epic.path): epic for epic in status.epics}
    seen: set[str] = set()
    rows: list[EpicRow] = []
    retro_pending = 0
    for action in status.next_actions:
        epic = by_path.get(action.target_path) if action.target_path else None
        if epic is not None:
            seen.add(str(epic.path))
        # A retro candidate is a complete epic still awaiting reflection. When
        # completed work is collapsed, don't pin it as its own row — count it and
        # roll the nudge into one summary line below, so "hide done" hides it too.
        if action.kind == "retro" and not show_complete:
            retro_pending += 1
            continue
        rows.append(_action_row(action, epic))
    # Re-order for display only — the engine's next_actions order drives launch
    # precedence and must not change. Stable sort keeps engine/filename order
    # within each rank group.
    rows.sort(key=_row_rank)
    if show_complete:
        for epic in status.epics:
            if str(epic.path) not in seen:
                row = _inactive_row(epic) if _is_inactive(epic) else _done_row(epic)
                rows.append(row)
    elif retro_pending:
        rows.append(_retro_summary_row(retro_pending))
    # Flag any epic carrying an unrecognised status so it reads as "needs a look"
    # at a glance — this only marks; it never changes the epic's counts.
    for row in rows:
        if row.epic is not None and _epic_has_unrecognised(row.epic):
            row.label = f"{row.label}  {_WARN_MARKER}"
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
    sources = [epic.blocked_by, *(s.blocked_by for s in epic.stories if _is_pending(s.status))]
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


def unrecognised_rows(epic: Epic) -> list[tuple[str, str]]:
    """Detail lines naming each unrecognised status on an epic — its own and each
    story's — so a flagged ``(!)`` row explains itself. Empty when all recognised."""
    rows: list[tuple[str, str]] = []
    if not _is_recognised_status(epic.status, epic=True):
        rows.append((f"Epic status not recognised: {epic.status}", "red"))
    for s in epic.stories:
        if not _is_recognised_status(s.status):
            num = s.number if s.number is not None else "?"
            rows.append((f"Story {num} status not recognised: {s.status}", "red"))
    if rows:
        rows.insert(0, (f"{_WARN_GLYPH} Unrecognised — normalise to Pending / In Progress / Complete:", "bold red"))
    return rows


def visible_stories(epic: Epic | None, *, show_complete: bool = False):
    """The stories shown in the stories column, in order — complete ones hidden unless
    ``show_complete``. The board maps a highlighted row back to its ``Story`` through
    this same list, so :func:`story_rows` is defined in its terms (no drift)."""
    if epic is None:
        return []
    return [s for s in epic.stories if show_complete or not _is_done(s.status)]


def story_rows(epic: Epic | None, *, show_complete: bool = False) -> list[tuple[str, str]]:
    """Right-column ``(label, style)`` rows for the selected epic's stories.

    Complete stories are hidden unless ``show_complete``; a spec-breakdown row
    (``epic is None``) has no stories.
    """
    rows: list[tuple[str, str]] = []
    for story in visible_stories(epic, show_complete=show_complete):
        number = story.number if story.number is not None else "?"
        title = story.title or ""
        if not _is_recognised_status(story.status):
            # Surface the raw noise (with a glyph) so a human can normalise it —
            # never guess what the prose meant.
            label = f"{_WARN_GLYPH} Story {number} · {title}  ·  {story.status or '—'}"
            rows.append((label, _WARN_STYLE))
        else:
            shown = _status_token(story.status) or "—"
            label = f"Story {number} · {title}  ·  {shown}"
            rows.append((label, _story_style(story.status)))
    return rows
