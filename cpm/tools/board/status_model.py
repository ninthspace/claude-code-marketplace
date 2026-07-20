"""Status derivation for the cpm board.

Implements the shared contract at ``cpm/shared/status-model.md``: reads a
project's ``docs/`` planning artifacts (read-only) and derives an overall state,
story-progress counts, and — from Story 2 onward — an ordered list of candidate
next actions.

All access here is strictly read-only. Nothing in this module writes to, stages,
or otherwise mutates a tracked repository.
"""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path


class State(str, Enum):
    """The seven overall project states, per the contract (precedence order)."""

    UNKNOWN = "unknown"
    NO_ARTIFACTS = "no-artifacts"
    BLOCKED = "blocked"
    IN_PROGRESS = "in-progress"
    EPICS_READY = "epics-ready"
    SPEC_READY = "spec-ready"
    COMPLETE = "complete"


#: RAG colour band per state (contract "RAG" column).
RAG: dict[State, str] = {
    State.UNKNOWN: "grey",
    State.NO_ARTIFACTS: "grey",
    State.BLOCKED: "red",
    State.IN_PROGRESS: "amber",
    State.EPICS_READY: "amber",
    State.SPEC_READY: "amber",
    State.COMPLETE: "green",
}

_NO_DEP = {"—", "-", "", None}

#: Delimiters that separate a canonical status token from a trailing human note in a
#: ``**Status**:`` field (e.g. ``Complete — folded into Story 10``): an em/en dash,
#: an opening paren, a semicolon, or a *spaced* hyphen. A bare ``-`` (no surrounding
#: spaces) is not a delimiter, so it never splits a hyphenated status word.
_STATUS_NOTE_RE = re.compile(r"\s*[—–(;]|\s+-\s+")


def _status_token(status: str) -> str:
    """The canonical leading token of a status field — everything before the first
    note delimiter, stripped. A field with no delimiter is returned whole; case is
    preserved (callers lower-case). ``"Complete — folded in"`` → ``"Complete"``;
    ``"In Progress"`` → ``"In Progress"``."""
    return _STATUS_NOTE_RE.split(status.strip(), maxsplit=1)[0].strip()


#: Recognised story statuses (lower-cased leading token); epics add the two
#: user-set terminal statuses. A status whose leading token is outside its set is
#: *unrecognised* and surfaced (never silently counted) — see :func:`_is_recognised_status`.
_STORY_STATUSES = {"pending", "in progress", "complete", "done"}
_EPIC_STATUSES = _STORY_STATUSES | {"superseded", "withdrawn"}

#: Statuses (case-insensitive leading token) that mean a story or epic is *finished*
#: — it counts toward progress and it *satisfies* a dependency. ``Done`` is a full
#: synonym for ``Complete`` (CPM only ever writes ``Complete``; the board reads
#: either, like the ``pivot`` skill). Superseded/Withdrawn are deliberately absent —
#: see :data:`INACTIVE_EPIC_STATUSES`.
_DONE_STATUSES = {"complete", "done"}

#: Epic-level statuses a user sets by hand to *retire* an epic whose work is no
#: longer needed — terminal, and never auto-derived from stories. A retired epic's
#: stories still **count as done** for progress (the work is closed out) and the
#: epic is hidden from the active surface and never nags a retro; but it does
#: **not** satisfy a dependency — that work will never be done, so anything
#: depending on it stays permanently blocked. ``/cpm:archive`` sweeps them up.
INACTIVE_EPIC_STATUSES = {"Superseded", "Withdrawn"}
_INACTIVE_LOWER = {s.lower() for s in INACTIVE_EPIC_STATUSES}


def _is_done(status: str) -> bool:
    """True when a status means *finished* — leading token ``Complete`` or ``Done``
    (case-insensitive). Drives both progress counting and dependency satisfaction."""
    return _status_token(status).lower() in _DONE_STATUSES


def _is_pending(status: str) -> bool:
    """True when the status's leading token is ``Pending`` (case-insensitive)."""
    return _status_token(status).lower() == "pending"


def _is_in_progress(status: str) -> bool:
    """True when the status's leading token is ``In Progress`` (case-insensitive)."""
    return _status_token(status).lower() == "in progress"


def _is_recognised_status(status: str, *, epic: bool = False) -> bool:
    """True when the status's leading token is in the vocabulary. An empty status is
    *recognised* (absence is not noise) — only a non-empty, unrecognised leading
    token (free-text prose, a typo, or a story-level ``Superseded``/``Withdrawn``,
    which are epic-level only) is flagged for the user to normalise."""
    token = _status_token(status).lower()
    if not token:
        return True
    return token in (_EPIC_STATUSES if epic else _STORY_STATUSES)


@dataclass(frozen=True)
class Story:
    number: int | None
    status: str  # "Pending" | "In Progress" | "Complete"/"Done" | "" (unparsed)
    blocked_by: str  # raw field value, e.g. "—" or "Story 1"
    title: str = ""  # the `##` heading text, sans trailing workflow tags


@dataclass
class Epic:
    path: Path
    parent: str | None  # source spec number prefix, e.g. "39"
    status: str  # epic-level Status field
    blocked_by: str  # epic-level Blocked by field
    stories: list[Story]
    title: str = ""  # the epic doc's `# ` H1 heading
    retro_waived: bool = False  # epic-level `**Retro waived**:` marker (set by /cpm:retro triage)


@dataclass
class NextAction:
    """A single candidate next action for a project (populated in Story 2)."""

    kind: str  # e.g. "do", "epics", "retro", "discover", "attention:unblock"
    command: str | None  # None for attention items (no runnable command)
    target_path: str | None
    label: str


@dataclass
class ProjectStatus:
    path: Path
    state: State
    complete_stories: int
    total_stories: int
    next_actions: list[NextAction] = field(default_factory=list)
    epics: list[Epic] = field(default_factory=list)  # parsed detail for drill-down
    label: str = ""  # e.g. "unreachable" for the unknown state

    @property
    def progress(self) -> str:
        return f"{self.complete_stories}/{self.total_stories}"

    @property
    def rag(self) -> str:
        return RAG[self.state]

    @property
    def primary_action(self) -> NextAction | None:
        return self.next_actions[0] if self.next_actions else None


# --- parsing -----------------------------------------------------------------


def _field(block: str, name: str) -> str | None:
    match = re.search(rf"^\*\*{re.escape(name)}\*\*:\s*(.+?)\s*$", block, re.MULTILINE)
    return match.group(1).strip() if match else None


def _parent_from_epic_name(name: str) -> str | None:
    """Extract the source-spec prefix from a two-part epic filename (``39-01-...``)."""
    match = re.match(r"^(\d+)-\d+-epic-", name)
    return match.group(1) if match else None


def _strip_tags(heading: str) -> str:
    """Drop trailing workflow tags (``[plan]``, ``[tdd]`` …) from a story heading."""
    previous = None
    title = heading.strip()
    while title != previous:
        previous = title
        title = re.sub(r"\s*\[[^\]]*\]\s*$", "", title).strip()
    return title


def parse_epic(path: Path) -> Epic:
    """Parse an epic doc into its epic-level fields and its stories (read-only)."""
    text = path.read_text()
    # Split on story headings (## ...). parts[0] is the epic preamble/metadata;
    # thereafter pairs of (heading, body).
    parts = re.split(r"^##\s+(.*)$", text, flags=re.MULTILINE)
    preamble = parts[0]
    h1 = re.search(r"^#\s+(.+)$", preamble, re.MULTILINE)

    stories: list[Story] = []
    for i in range(1, len(parts), 2):
        heading = parts[i]
        body = parts[i + 1] if i + 1 < len(parts) else ""
        number = _field(body, "Story")
        if number is None:
            # A `##` section that is not a story (defensive) — skip it.
            continue
        stories.append(
            Story(
                number=int(number) if number.isdigit() else None,
                status=_field(body, "Status") or "",
                blocked_by=_field(body, "Blocked by") or "—",
                title=_strip_tags(heading),
            )
        )

    return Epic(
        path=path,
        parent=_parent_from_epic_name(path.name),
        status=_field(preamble, "Status") or "",
        blocked_by=_field(preamble, "Blocked by") or "—",
        stories=stories,
        title=h1.group(1).strip() if h1 else "",
        retro_waived=_field(preamble, "Retro waived") is not None,
    )


def story_section(text: str, story: Story) -> str:
    """Extract one story's ``## `` section from an epic doc's text — the heading line
    through the line before the next ``##`` (or a top-level ``#``) heading.

    Matched by story number (the ``**Story**: N`` field, the stable key) with the
    ``##`` heading title as fallback. Returns ``""`` when no section matches.
    """
    lines = text.splitlines()
    starts = [i for i, line in enumerate(lines) if re.match(r"^##\s+", line)]
    blocks: list[tuple[str, str]] = []  # (stripped heading title, section text)
    for k, start in enumerate(starts):
        end = starts[k + 1] if k + 1 < len(starts) else len(lines)
        for j in range(start + 1, end):
            if re.match(r"^#\s+", lines[j]):  # a top-level heading closes the section
                end = j
                break
        block = "\n".join(lines[start:end]).rstrip()
        heading = _strip_tags(re.match(r"^##\s+(.*)$", lines[start]).group(1))
        blocks.append((heading, block))
        number = _field(block, "Story")
        if (
            story.number is not None
            and number is not None
            and number.isdigit()
            and int(number) == story.number
        ):
            return block
    for heading, block in blocks:  # number didn't match → fall back to the title
        if story.title and heading == story.title:
            return block
    return ""


def _spec_paths(root: Path) -> list[Path]:
    directory = root / "docs" / "specifications"
    return sorted(directory.glob("[0-9]*-spec-*.md")) if directory.is_dir() else []


def _spec_number(path: Path) -> str | None:
    """Extract the numeric prefix from a spec filename (``39-spec-foo.md`` → ``39``)."""
    match = re.match(r"^(\d+)-spec-", path.name)
    return match.group(1) if match else None


def _retro_texts(root: Path) -> list[str]:
    directory = root / "docs" / "retros"
    if not directory.is_dir():
        return []
    return [p.read_text() for p in directory.glob("[0-9]*-retro-*.md")]


def _epic_paths(root: Path) -> list[Path]:
    directory = root / "docs" / "epics"
    if not directory.is_dir():
        return []
    return sorted(
        p for p in directory.glob("[0-9]*-epic-*.md") if "-coverage-" not in p.name
    )


# --- dependency resolution ---------------------------------------------------


def _epic_deps_satisfied(epic: Epic, epics: list[Epic]) -> bool:
    return _deps_satisfied(epic.blocked_by, story_by_num={}, epics=epics)


def _deps_satisfied(blocked_by: str, story_by_num: dict[int, Story], epics: list[Epic]) -> bool:
    """A dependency string is satisfied when every referenced story/epic is *finished*
    (``Complete`` / ``Done``).

    A ``Superseded`` / ``Withdrawn`` reference is **never** satisfied — that work
    will not be done, so anything depending on it stays permanently blocked.
    Unparseable references resolve to *not satisfied* (conservative — the contract
    says undetermined dependencies are treated as blocked, never as ready).
    """
    if blocked_by in _NO_DEP:
        return True

    for ref in (r.strip() for r in blocked_by.split(",")):
        lowered = ref.lower()
        if lowered.startswith("story"):
            match = re.search(r"(\d+)", ref)
            if match is None:
                return False
            target = story_by_num.get(int(match.group(1)))
            if target is None or not _is_done(target.status):
                return False
        elif lowered.startswith("epic"):
            target_epic = _find_epic(ref, epics)
            if target_epic is None or not _is_done(target_epic.status):
                return False
        else:
            return False
    return True


def _find_epic(ref: str, epics: list[Epic]) -> Epic | None:
    # ref looks like "Epic 39-01-epic-foundation-...": match on the filename stem.
    token = ref.split(None, 1)[1].strip() if " " in ref else ref
    for epic in epics:
        if epic.path.stem == token or epic.path.name.startswith(token):
            return epic
    return None


def _unblocked_pending(epic: Epic, epics: list[Epic]) -> list[Story]:
    story_by_num = {s.number: s for s in epic.stories if s.number is not None}
    epic_ok = _epic_deps_satisfied(epic, epics)
    unblocked: list[Story] = []
    for story in epic.stories:
        if not _is_pending(story.status):
            continue
        if epic_ok and _deps_satisfied(story.blocked_by, story_by_num, epics):
            unblocked.append(story)
    return unblocked


# --- state derivation --------------------------------------------------------


def _is_inactive(epic: Epic) -> bool:
    """True when an epic has been retired via a terminal, user-set status
    (:data:`INACTIVE_EPIC_STATUSES`) — matched on the leading token, so a trailing
    note is allowed (``Superseded — replaced by 12-03``)."""
    return _status_token(epic.status).lower() in _INACTIVE_LOWER


def _epic_is_terminal(epic: Epic) -> bool:
    """True when the epic as a whole is closed out — retired, or its epic-level
    status is itself done/complete. Every story of a terminal epic counts as done,
    whatever the stories' own statuses say."""
    return _is_inactive(epic) or _is_done(epic.status)


def derive_state(specs: list[Path], epics: list[Epic]) -> State:
    """Apply the contract's precedence rules (first match wins)."""
    if not specs and not epics:
        return State.NO_ARTIFACTS

    if not epics:
        return State.SPEC_READY  # specs exist, none derived into epics yet

    # Superseded/Withdrawn epics are retired by hand. Exclude them from the state
    # *logic* so their (possibly Pending) stories can't peg a project to a stuck
    # amber/red state — their stories still count as done for progress (see
    # derive_project). Dependency resolution still sees the full epic list.
    active = [e for e in epics if not _is_inactive(e)]
    if not active:
        return State.COMPLETE  # every epic retired — nothing left to action

    stories = [s for e in active for s in e.stories]
    if not stories:
        return State.COMPLETE if all(_epic_is_terminal(e) for e in active) else State.EPICS_READY

    pending = [s for s in stories if _is_pending(s.status)]
    in_progress = [s for s in stories if _is_in_progress(s.status)]
    done = [s for s in stories if _is_done(s.status)]
    unblocked_pending = [s for e in active for s in _unblocked_pending(e, epics)]

    # 3 — blocked: pending work remains but none of it is actionable.
    if pending and not unblocked_pending and not in_progress:
        return State.BLOCKED
    # 7 — complete: every story done.
    if len(done) == len(stories):
        return State.COMPLETE
    # 4 — in-progress: active work, or a partially-done set.
    if in_progress or (done and pending):
        return State.IN_PROGRESS
    # 5 — epics-ready: epics exist, nothing started.
    if all(_is_pending(s.status) for s in stories):
        return State.EPICS_READY
    return State.IN_PROGRESS


# --- next actions ------------------------------------------------------------


def _epic_state(epic: Epic, all_epics: list[Epic]) -> str:
    """Classify one epic using the same precedence as ``derive_state``.

    Returns ``inactive`` for a retired (Superseded/Withdrawn) epic, else one of
    ``blocked`` / ``complete`` / ``in-progress`` / ``epics-ready``. ``all_epics``
    is threaded through so cross-epic dependencies resolve. No action branch in
    :func:`compute_next_actions` matches ``inactive``, so retired epics never
    surface as candidates.
    """
    if _is_inactive(epic):
        return "inactive"
    stories = epic.stories
    if not stories:
        return "complete" if _epic_is_terminal(epic) else "epics-ready"

    pending = [s for s in stories if _is_pending(s.status)]
    in_progress = [s for s in stories if _is_in_progress(s.status)]
    done = [s for s in stories if _is_done(s.status)]
    unblocked = _unblocked_pending(epic, all_epics)

    if pending and not unblocked and not in_progress:
        return "blocked"
    if len(done) == len(stories):
        return "complete"
    if in_progress or (done and pending):
        return "in-progress"
    if all(_is_pending(s.status) for s in stories):
        return "epics-ready"
    return "in-progress"


def _rel(path: Path, root: Path) -> str:
    """Path relative to the project root for use in launchable commands."""
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def _blocking_deps(epic: Epic) -> str:
    """Human-readable summary of what a blocked epic is waiting on."""
    if epic.blocked_by not in _NO_DEP:
        return epic.blocked_by
    deps = sorted(
        {s.blocked_by for s in epic.stories if _is_pending(s.status) and s.blocked_by not in _NO_DEP}
    )
    return ", ".join(deps) if deps else "an incomplete dependency"


def _epic_has_retro(epic: Epic, retro_texts: list[str]) -> bool:
    return any(epic.path.stem in text or epic.path.name in text for text in retro_texts)


def compute_next_actions(root: Path, specs: list[Path], epics: list[Epic]) -> list[NextAction]:
    """Derive the ordered candidate next actions per the contract's priority list.

    Ordering (highest priority first): blocked epics → in-progress epics →
    epics-ready epics → specs without epics → complete epics lacking a retro →
    discover (only when there are no artifacts at all). The first item is the
    *primary* action, aligned with the overall state's precedence.
    """
    if not specs and not epics:
        return [
            NextAction("discover", "/cpm:discover", None, "No planning artifacts — run /cpm:discover")
        ]

    classified = {id(epic): _epic_state(epic, epics) for epic in epics}
    actions: list[NextAction] = []

    # 1 — blocked epics: attention only, no runnable command.
    for epic in epics:
        if classified[id(epic)] == "blocked":
            actions.append(
                NextAction(
                    "attention:unblock",
                    None,
                    str(epic.path),
                    f"Unblock {epic.path.name} — waiting on {_blocking_deps(epic)}",
                )
            )
    # 2 — in-progress epics: continue.
    for epic in epics:
        if classified[id(epic)] == "in-progress":
            command = f"/cpm:do {_rel(epic.path, root)}"
            actions.append(NextAction("do", command, str(epic.path), f"Continue {epic.path.name}"))
    # 3 — epics-ready epics: start.
    for epic in epics:
        if classified[id(epic)] == "epics-ready":
            command = f"/cpm:do {_rel(epic.path, root)}"
            actions.append(NextAction("do", command, str(epic.path), f"Start {epic.path.name}"))
    # 4 — specs with no derived epics: break down.
    covered = {epic.parent for epic in epics if epic.parent}
    for spec in specs:
        number = _spec_number(spec)
        if number is not None and number not in covered:
            command = f"/cpm:epics {_rel(spec, root)}"
            actions.append(NextAction("epics", command, str(spec), f"Break down {spec.name}"))
    # 5 — complete epics lacking a retro: reflect. A `**Retro waived**:` marker
    # (set by /cpm:retro triage on a clean epic) satisfies this just like an actual
    # retro does, so a deliberately-waived epic never nags.
    retro_texts = _retro_texts(root)
    for epic in epics:
        if (
            classified[id(epic)] == "complete"
            and not epic.retro_waived
            and not _epic_has_retro(epic, retro_texts)
        ):
            command = f"/cpm:retro {_rel(epic.path, root)}"
            actions.append(NextAction("retro", command, str(epic.path), f"Retro {epic.path.name}"))

    return actions


# --- git (read-only) ---------------------------------------------------------


def read_head(root: Path) -> str | None:
    """Return the current git HEAD sha, or None if not a git repo. Read-only."""
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=root,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


# --- top-level ---------------------------------------------------------------


def _unknown(root: Path, label: str) -> ProjectStatus:
    """Graceful-degradation result: the `unknown` (`?`) state, no next actions."""
    return ProjectStatus(
        path=root, state=State.UNKNOWN, complete_stories=0, total_stories=0, label=label
    )


def derive_project(path: Path | str) -> ProjectStatus:
    """Derive a project's status from its planning artifacts (read-only).

    Never raises: an unreachable path degrades to `unknown`/"unreachable" and a
    malformed or half-written artifact degrades to `unknown`/"unparseable" (the
    `?` state). This isolation is what lets :func:`derive_projects` sweep a
    registry without one bad project aborting the whole run.
    """
    root = Path(path)
    if not root.is_dir():
        return _unknown(root, "unreachable")

    try:
        specs = _spec_paths(root)
        epics = [parse_epic(p) for p in _epic_paths(root)]

        # Everything counts: a terminal epic (retired, or done at the epic level)
        # closes out all its stories, so they count as done regardless of their own
        # status; otherwise a story counts only when individually done.
        total = sum(len(e.stories) for e in epics)
        complete = sum(
            len(e.stories) if _epic_is_terminal(e)
            else sum(1 for s in e.stories if _is_done(s.status))
            for e in epics
        )

        return ProjectStatus(
            path=root,
            state=derive_state(specs, epics),
            complete_stories=complete,
            total_stories=total,
            next_actions=compute_next_actions(root, specs, epics),
            epics=epics,
        )
    except Exception:
        # A single unparseable / half-written artifact must never abort the sweep.
        return _unknown(root, "unparseable")


def derive_projects(paths: list[Path | str]) -> list[ProjectStatus]:
    """Derive every project in a registry, isolating per-project failures.

    Each project is derived independently; a failure in one yields an `unknown`
    row rather than propagating, so the sweep always returns one row per input.
    """
    return [derive_project(path) for path in paths]
