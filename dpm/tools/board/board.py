#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "textual>=0.80",
# ]
# ///
"""dpm board — a cross-project dpm status board & launcher.

Run directly with uv; the PEP 723 block above is what provisions it, so there is no install step
(AD2, ENV1):

    uv run dpm/tools/board/board.py            # the TUI
    uv run dpm/tools/board/board.py list
    uv run dpm/tools/board/board.py add PATH
    uv run dpm/tools/board/board.py remove PATH

**The board is an MCP client and nothing else** (FR2). It opens no SQLite connection, reads no file
under a project's ``docs/`` or ``.dpm/``, and parses no markdown: everything it knows about a project
arrives as a ``tools/call`` response from a read-only ``bin/dpm-mcp.js`` spawned at that project's
root. The registry below is one of only two things it writes, and both live under the XDG config
directory (ENVX3).

**Textual is the only dependency, and the same list appears in `pyproject.toml`.** What ships is
this file, provisioned by the block above; the pyproject provisions the test harness. A package in
one and not the other is a package the suite has and the board does not, which is how an import
that works in every test fails on the first real run.
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from contextlib import contextmanager
from dataclasses import dataclass, replace
from functools import partial
from pathlib import Path

from rich.color import Color
from rich.color_triplet import ColorTriplet
from rich.console import Console
from rich.markdown import Markdown
from rich.segment import Segment
from rich.style import Style
from rich.table import Table
from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.command import DiscoveryHit, Hit, Provider
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.content import Content
from textual.screen import ModalScreen
from textual.strip import Strip
from textual.widgets import DirectoryTree, Footer, Header, Input, Label, OptionList, Static

from board_view import (
    BADGE_STYLE,
    PILL_STYLE,
    READING_STYLE,
    UNREADABLE_STYLE,
    EpicView,
    Gap,
    ProjectView,
    Result,
    Selection,
    StoryView,
    document_preview,
    integrity_badge,
    live_pill,
    markers,
    ralph_label,
    story_preview,
    style_for,
)
from cache import Cache
from mcp_client import (
    SERVER_FAILED,
    SERVER_MISSING,
    ServerNotFound,
    ServerPool,
    Unreadable,
)
from registry import (
    add_project,
    list_projects,
    missing_marker,
    remove_project,
)
from launcher import (
    ATTACH,
    LAUNCH,
    OPEN,
    PROJECTS,
    Degraded,
    LaunchFailed,
    NoTarget,
    launch_command,
    launch_target,
    live_sessions,
    selectable,
    tmux_launcher,
)
from status_model import (
    DOCUMENT_READS,
    EPICS,
    PAGE,
    RETROS,
    SECTIONS,
    SPECS,
    STORIES,
    STORY_CRITERIA,
    TASKS,
    Candidate,
    blockers,
    by_epic,
    candidates,
    dependencies,
    epic_state,
    gating_kinds,
    hits,
    progress,
    ready_epic_ids,
    rows,
    untraced_requirements,
    violations,
)


def refusal(path: str) -> str | None:
    """Why ``path`` cannot be registered, or ``None`` when nothing stops it (FR1).

    **Named, not generic.** A refused registration is nearly always a directory that is obviously a
    project of some kind — a git repository, a checkout with a `docs/` tree — and the user's next
    question is which file the board was looking for. Naming the path it wanted turns "not a dpm
    project" into an instruction.

    One function because there are two affordances: the CLI's `add` and the browser's picker (FR1
    is covered only across both). Two copies of this sentence would be two explanations of one
    condition, and they would diverge in the direction of whichever was edited last.
    """
    marker = missing_marker(path)

    return None if marker is None else f"not a dpm project: no {marker}"


def _add(path: str, label: str | None, registry_file: Path | None, out, err) -> int:
    """Register a project, or refuse and say which file was not there (FR1)."""
    complaint = refusal(path)

    if complaint is not None:
        print(complaint, file=err)
        return 1

    add_project(path, label, registry_file=registry_file)
    print(f"registered {path}", file=out)

    return 0


async def read_project(pool: ServerPool, root: Path) -> dict[str, int]:
    """What one project contributes to a board row: how much of each thing it holds.

    Every one of these is a `tools/call` on that project's own server (FR2) and goes through a
    call declared in :mod:`status_model`, so the set the reconciliation checks is this function's
    actual behaviour rather than a list someone kept up to date.
    """
    counts = {}

    for key, call in (("epics", EPICS), ("stories", STORIES), ("tasks", TASKS)):
        answer = await pool.read(root, call, {"limit": PAGE})
        counts[key] = answer["returned"]

    return counts


def _describe(entry, counts: dict[str, int] | None, state: Unreadable | None) -> str:
    """One row: the project, and either what it holds or why it could not be read."""
    label = f" — {entry.label}" if entry.label else ""

    if state is not None:
        # The whole of it — state, remedy and the detail of this occurrence. A terminal line has
        # room for the path that could not be read or the tools that disagreed, and the row is the
        # only place a `list` run shows anything at all.
        return f"{entry.path}{label}  {state}"

    if counts is None:
        return f"{entry.path}{label}  (missing)"

    return (
        f"{entry.path}{label}  "
        f"{counts['epics']} epics, {counts['stories']} stories, {counts['tasks']} tasks"
    )


async def _survey(entries, make_pool) -> list[str]:
    """Read every registered project through one pool, and describe each one.

    **A project that cannot be read is a row, not an exception** (FR11). The whole point of the
    mixed registry is that one broken project does not take the board down with it, so the state is
    caught per entry and rendered beside the projects that are fine.
    """
    rows = []

    async with make_pool() as pool:
        for entry in entries:
            if not entry.exists():
                rows.append(_describe(entry, None, None))
                continue

            try:
                rows.append(_describe(entry, await read_project(pool, Path(entry.path)), None))
            except Unreadable as state:
                # Every failure the pool can reach arrives in this one shape — the board declining
                # before it spawns anything, a server that refused to start, and a server that
                # started and then could not answer are all states with remedies (FR11), and each
                # is a row beside the projects that are fine.
                rows.append(_describe(entry, None, state))
            except ServerNotFound as missing:
                rows.append(_describe(entry, None, Unreadable(SERVER_MISSING, str(missing))))
            except Exception as unexpected:  # noqa: BLE001 — one project's failure is one row (NFR2)
                # The same containment `survey_project` gives the browser, for the same reason: a
                # `list` that raised on the third of twelve projects would report nothing about the
                # nine it had not reached and nothing about the two it had.
                rows.append(
                    _describe(
                        entry,
                        None,
                        Unreadable(SERVER_FAILED, f"{type(unexpected).__name__}: {unexpected}"),
                    )
                )

    return rows


def _list(registry_file: Path | None, out, err, make_pool) -> int:
    """Print the registry with each project's state, read from its own server (FR1, FR2, FR3)."""
    entries = list_projects(registry_file=registry_file)

    if not entries:
        return 0

    try:
        rows = asyncio.run(_survey(entries, make_pool))
    except ServerNotFound as missing:
        # Board-level, not per-project: without a server there is nothing to say about any of them,
        # and the message names every place that was looked.
        print(missing, file=err)
        return 1

    for row in rows:
        print(row, file=out)

    return 0


def _remove(path: str, registry_file: Path | None, out) -> int:
    """Unregister a project. Removing one that was never registered is not an error."""
    remove_project(path, registry_file=registry_file)
    print(f"unregistered {path}", file=out)

    return 0


def offered_by_id(offers: list[Candidate]) -> dict[str, Candidate]:
    """Each row's candidate, by the id it is about — the first by FR9's order where there are two.

    A row can qualify twice only if the model's kinds overlap, and today they cannot: an epic is
    either ready or complete. ``setdefault`` over the already-sorted list is what decides it if that
    ever changes, so the answer stays FR9's ordering rather than whichever loop ran last.
    """
    found: dict[str, Candidate] = {}

    for offer in offers:
        found.setdefault(offer.id, offer)

    return found


async def read_view(pool: ServerPool, root: Path, name: str, *, fresh: bool = False) -> ProjectView:
    """Everything one project contributes to the browser, in one pass over its rows.

    Five unscoped reads answer for the whole project — every story row carries the ``epic_id`` it
    belongs to and every edge carries both its ends — so the columns are built by grouping what
    arrived rather than by a scoped call per epic.

    **Nothing here decides anything.** Readiness, blocking, the state and the counts are
    :mod:`status_model`'s, which is the board's half of the contract; this function's whole job is
    to shape them into rows a column can paint.

    **``fresh`` is all-or-nothing across the eight reads, and has to be** (FR13). A project's figure
    is derived from all of them together, so refreshing some and serving the rest from the cache
    would render one project out of two different moments — an epic counted ready by a readiness
    read taken now against stories counted from a read taken minutes ago.

    **The integrity check is read here rather than beside the badge** (FR17). Inside the survey it
    goes through the pool like every other read and is therefore behind FR13's freshness cache; read
    where it is rendered it would be uncached and would run again on every repaint, which for a
    sweep over thirteen invariants and a foreign-key check is a cost paid per keystroke.
    """
    epics = await rows(pool, root, EPICS, fresh=fresh)
    stories = await rows(pool, root, STORIES, fresh=fresh)
    specs = await rows(pool, root, SPECS, fresh=fresh)
    retros = await rows(pool, root, RETROS, fresh=fresh)
    edges = await dependencies(pool, root, fresh=fresh)
    gating = await gating_kinds(pool, root, fresh=fresh)
    ready = await ready_epic_ids(pool, root, fresh=fresh)
    broken = await violations(pool, root, fresh=fresh)

    index = {row["id"]: row for row in (*epics, *stories)}
    grouped = by_epic(stories)
    offered = offered_by_id(candidates(epics, specs, retros, ready))

    views = [
        EpicView(
            id=epic["id"],
            title=epic["title"],
            state=epic_state(epic, grouped.get(epic["id"], []), held, ready),
            progress=progress(grouped.get(epic["id"], [])),
            stories=tuple(
                StoryView(story["id"], story["title"], story["status"])
                for story in grouped.get(epic["id"], [])
            ),
            candidate=offered.get(epic["id"]),
        )
        for epic in epics
        for held in [blockers(epic["id"], edges, gating, index)]
    ]

    # The project figure is its story rows, not the average of its epics' — an epic with no stories
    # would otherwise contribute a completion of its own and lift the number.
    return ProjectView(
        name=name,
        path=root,
        epics=tuple(views),
        progress=progress(stories),
        violations=broken,
    )


async def read_document_preview(pool: ServerPool, root: Path, row: EpicView) -> str:
    """The preview text for an epic, spec or retro — its row and its sections (FR7).

    The read tool is named for the kind, so the kind is on the row rather than guessed from the
    id: ``read_spec`` refuses an id that turns out to be an epic rather than answering for it.
    """
    document = await pool.read(root, DOCUMENT_READS[row.kind], {"id": row.id})
    sections = await rows(pool, root, SECTIONS, {"document_id": row.id, "include_body": True})

    return document_preview(document, sections)


async def read_story_preview(pool: ServerPool, root: Path, row: StoryView) -> str:
    """The preview text for a story: its own criteria and tasks, scoped in the call (FR7).

    ``include_body`` on both, because the withheld column is the content in each case — a
    criterion's ``text`` is the criterion, and a task's ``description`` is what it says to do.
    """
    criteria = await rows(pool, root, STORY_CRITERIA, {"story_id": row.id, "include_body": True})
    tasks = await rows(pool, root, TASKS, {"story_id": row.id, "include_body": True})

    return story_preview(row, criteria, tasks)


def previews(pool: ServerPool):
    """A reader the app can call for any highlighted row, bound to one pool.

    Handed to :class:`BoardApp` rather than built by it: the app owns no server and spawns
    nothing, which is what keeps every read in one place and lets a test drive the browser with a
    reader of its own.
    """
    async def read(root: Path, row: EpicView | StoryView) -> str:
        if isinstance(row, StoryView):
            return await read_story_preview(pool, root, row)

        return await read_document_preview(pool, root, row)

    return read


#: How many hits one project contributes to a search (FR15).
#:
#: Per project rather than for the whole board, because the fan-out has no way to rank across
#: servers: each answers with its own bm25 scores, on its own corpus, and a global bound would have
#: to pick a winner between two numbers that are not comparable. A bound each is the honest version
#: — every registered project gets to show its best matches — and the board's own ordering is by
#: project, which is a fact rather than a ranking.
SEARCH_LIMIT = 20


def resolve_hits(project: ProjectView, found: list[dict], sections: list[dict]) -> list[Result]:
    """A project's raw hits as rows that name where selecting them goes (FR15).

    Three ways a hit reaches a document, and all three read an id off a row rather than deriving
    one: the hit *is* a document the board holds, the hit is a story and the epic holding it is on
    the board already, or the hit is a section and its own row carries the ``document_id``. That last
    one is why the sections are read at all — it is the entity the whole of every document's prose
    is indexed under, so it is the bulk of what a search matches.

    **Everything else keeps its project and no document**, which is stated in :class:`Result` and is
    the deliberate half of this function. Resolving a requirement or a finding would mean the board
    walking dpm's parent columns table by table — a second implementation of ancestry the server
    owns (AD5), and one that would go quietly wrong the day a sixteenth entity is indexed.
    """
    documents = {row.id for row in project.epics}
    holding = {story.id: row.id for row in project.epics for story in row.stories}
    under = {row["id"]: row["document_id"] for row in sections}

    def document_of(hit: dict) -> str | None:
        found_id = hit["entity_id"]

        if found_id in documents:
            return found_id

        # A section's document is the row it carries; a story's is the epic it is under. Either can
        # name a document the board is not showing — a section of a spec, say — and `documents` is
        # what keeps a result from pointing the Epics column at a row that is not in it.
        named = holding.get(found_id, under.get(found_id))

        return named if named in documents else None

    return [
        Result(
            project=project.path,
            name=project.name,
            entity=hit["entity"],
            entity_id=hit["entity_id"],
            excerpt=hit.get("excerpt") or "",
            document=document_of(hit),
            heading=hit.get("heading"),
        )
        for hit in found
    ]


async def search_project(pool: ServerPool, project: ProjectView, query: str) -> list[Result]:
    """One project's results, or none — a failure here is this project's alone (NFR2, FR15).

    **Contained the same way :func:`survey_project` is, and for a sharper reason.** A search is the
    one action that touches every registered project at once, so one server that will not start is
    the failure most likely to take a whole answer down rather than one row. It contributes nothing
    and says nothing; the projects that answered are the result.

    ``Exception`` and not ``BaseException``, which is what keeps a cancellation out of it: this runs
    in a worker the board cancels when the search screen closes, and a cancelled read swallowed here
    would be a project silently missing from a list the user is still reading.
    """
    if project.unreadable is not None:
        return []

    try:
        found = await hits(pool, project.path, query, limit=SEARCH_LIMIT)
        sections = await rows(pool, project.path, SECTIONS)
    except Exception:  # noqa: BLE001 — the containment boundary is the point (NFR2)
        return []

    return resolve_hits(project, found, sections)


async def search_projects(pool: ServerPool, projects, query: str) -> list[Result]:
    """Every registered project's results for one query, in registry order (FR15).

    Concurrently, for the reason the survey is: a project's server is a process, and asking twelve
    of them one after another makes the last one wait on the eleven in front of it. The order the
    results come back in is the registry's, not the order the servers answered — a list that
    reordered itself by who was quickest would put the same hit somewhere different each time.
    """
    rows_per_project = await asyncio.gather(
        *(search_project(pool, project, query) for project in projects)
    )

    return [result for found in rows_per_project for result in found]


def resolve_gaps(project: ProjectView, requirements: list[dict]) -> list[Gap]:
    """A project's untraced requirements as rows that say where selecting them goes (FR16).

    **The membership test is the whole of this function's judgement**, and it is the same one
    :func:`resolve_hits` makes: a row may name a document only if the Epics column is holding that
    document. A requirement names a spec, the column holds epics, so in practice nothing resolves
    and every gap carries its project and no document — which is the answer rather than a shortfall
    in it, and is why the test is written as a lookup rather than as ``None``.

    Writing the ``spec_id`` into ``document`` regardless is the failure this forbids: it costs
    nothing at the moment it is written, points the column at a row that is not in it, and leaves
    a user pressing enter on a gap and watching the cursor go somewhere arbitrary.
    """
    documents = {row.id for row in project.epics}

    return [
        Gap(
            project=project.path,
            name=project.name,
            requirement=row.get("label") or row["id"],
            spec_id=row["spec_id"],
            document=row["spec_id"] if row["spec_id"] in documents else None,
        )
        for row in requirements
    ]


async def gaps_project(pool: ServerPool, project: ProjectView) -> list[Gap]:
    """One project's coverage gaps, or none — a failure here is this project's alone (NFR2, FR16).

    Contained exactly as :func:`search_project` is, and for the same reason: this is a fan-out
    across every registered project at once, so one server that will not start is the failure most
    able to take a whole answer down instead of one project's part of it. It contributes nothing and
    says nothing; the projects that answered are the answer.
    """
    if project.unreadable is not None:
        return []

    try:
        requirements = await untraced_requirements(pool, project.path)
    except Exception:  # noqa: BLE001 — the containment boundary is the point (NFR2)
        return []

    return resolve_gaps(project, requirements)


async def gaps_projects(pool: ServerPool, projects) -> list[Gap]:
    """Every registered project's coverage gaps, in registry order (FR16).

    Concurrently and ordered by the registry, for :func:`search_projects`' reasons: a project's
    server is a process, and a list that reordered itself by whichever answered first would put the
    same requirement somewhere different on every open.
    """
    rows_per_project = await asyncio.gather(*(gaps_project(pool, project) for project in projects))

    return [gap for found in rows_per_project for gap in found]


def registry_views(entries) -> list[ProjectView]:
    """Every registered project as a row, from the registry alone (NFR3).

    **This is the whole reason the Projects column can render first.** The registry is a file on
    disk: the name, the path and whether the directory is still there are all readable without
    spawning anything, so the column is complete before a single server has been asked to start.
    What is missing from these rows is the epics and the progress, and those arrive per project as
    :func:`survey_project` answers.
    """
    return [
        ProjectView(
            name=entry.label or Path(entry.path).name,
            path=Path(entry.path),
            unreadable=None if entry.exists() else "missing",
            # A row that will be read is pending; one whose directory is already gone is not,
            # because nothing is going to arrive for it.
            pending=entry.exists(),
        )
        for entry in entries
    ]


async def survey_project(
    pool: ServerPool, view: ProjectView, *, fresh: bool = False
) -> ProjectView:
    """One project's rows, or the named state it has instead (FR11).

    Named apart from :func:`read_project`, which answers with the CLI's row counts for one project.
    Two functions called ``read_project`` in one module is an import waiting to go to the wrong one.

    Every failure is a returned row rather than a raised exception, because this runs in a worker:
    an exception escaping one has no screen to land on and takes the app down with it, which is
    the opposite of FR11's "one unreadable project does not stop the others".

    **Every path clears ``pending``.** A row that stayed pending after its read had finished would
    say "reading…" for the rest of the session, which is the one thing worse than saying nothing:
    it reports the board as busy over work that is done.
    """
    if view.unreadable is not None:
        return replace(view, pending=False)

    try:
        return await read_view(pool, view.path, view.name, fresh=fresh)
    except Unreadable as state:
        return _unreadable(view, state)
    except ServerNotFound as missing:
        # The only failure the pool cannot name for itself: there is no server to have a state, so
        # there is no stderr and no reply to classify from. Named here and given the same shape as
        # every other state, because from a row's point of view it is one.
        return _unreadable(view, Unreadable(SERVER_MISSING, str(missing)))
    except Exception as unexpected:  # noqa: BLE001 — the containment boundary is the point (NFR2)
        # **The last arm is the one NFR2 is about.** The named states above are the failures the
        # board went looking for; this is every other way one project's read can end — `node` not
        # on `PATH` at all, a server whose stdout is not JSON-RPC, a permission error on the
        # database — and each of them is raised inside a worker, where an escape is not a
        # traceback in a row but the whole app coming down over one project in a registry of ten.
        #
        # ``Exception`` and not ``BaseException``, which is what keeps a cancellation out of it:
        # this runs in a worker the board cancels on the way out, and a cancelled read turned into
        # a row would render the project as broken while the app closes over it.
        return _unreadable(view, Unreadable(SERVER_FAILED, f"{type(unexpected).__name__}: {unexpected}"))


def _unreadable(view: ProjectView, state: Unreadable) -> ProjectView:
    """The row a project in a named state renders as: the state, and what to do about it (FR11)."""
    return replace(view, unreadable=state.state, remedy=state.remedy, pending=False)


#: The columns, left to right. Focus moves along this tuple and nothing else defines their order.
COLUMNS = ("projects", "epics", "stories")

#: The columns that carry a preview panel beneath them (FR4). Projects does not: the preview is of
#: the *document* a row names, and a project is a directory rather than a document.
PREVIEWED = ("epic", "story")

#: Seconds between live-session polls (FR12). One `tmux list-windows` answers for the whole board,
#: so the cost is one process every couple of seconds; what the interval buys is that a session the
#: user just ended stops being reported while they are still looking at the row it was on.
LIVE_POLL = 2.0


@dataclass(frozen=True)
class Command:
    """One entry in the palette: what it is called, what it says, and the action it runs."""

    name: str
    help: str
    action: str


#: The board's own actions, in the order the palette offers them (FR18).
#:
#: **A table rather than a method per entry**, because the palette is where the board's actions are
#: enumerated and an enumeration spread over a class body is one that goes out of date. A later
#: epic adds its action here beside `action_*` on the app, and both halves are one edit.
#:
#: The four launch entries are bound to keys as well (FR8). Both, for the reason the register
#: binding gives: a key nobody knows about is not an affordance, and a palette-only action costs two
#: keystrokes forever.
COMMANDS: tuple[Command, ...] = (
    Command("Launch a session", "Run the focused column's command in a tmux session", "launch"),
    Command("Open Claude at the project", "Start Claude in the project with no command", "open"),
    Command("Attach to a live session", "Join this terminal to a running session", "attach"),
    Command("Copy the command", "Put the focused column's command on the clipboard", "copy_command"),
    Command("Search every project", "Find prose across every registered project", "search"),
    # FR16, bound and listed for the reason search is: it is a question about the whole board rather
    # than about the row under the cursor, and it is the thing a user opens the board to ask when
    # they want to know what was never planned rather than what is in flight.
    Command(
        "Coverage gaps",
        "List every requirement no coverage row names, across every registered project",
        "coverage_gaps",
    ),
    Command("Register a project", "Choose a directory to add to the board", "register"),
    Command("Refresh", "Read every registered project again", "refresh"),
    Command("Show/hide done", "Show or hide complete, superseded and withdrawn rows", "toggle_retired"),
    # FR13's two halves, and they are different actions rather than one with a flag. A refresh that
    # is answered from the cache is the ordinary case and the one the entry above is for; this pair
    # is what a user reaches for when they do not believe it. Both are bound as well as listed, for
    # the reason the register binding gives.
    Command("Force refresh", "Read every project again, ignoring the cache", "force_refresh"),
    Command("Clear the cache", "Forget every cached answer, here and on disk", "clear_cache"),
    Command("Copy project path", "Put the highlighted project's path on the clipboard", "copy_path"),
    Command("Remove project", "Unregister the highlighted project", "unregister"),
    # "Quit the board", not "Quit": Textual's own system command set — the one this provider
    # replaces — calls its entry "Quit", and a palette whose contents are asserted to be the
    # board's own is not testable against a name that is in both lists.
    Command("Quit the board", "Close the board", "quit"),
)


#: How much of a row's own colour the cursor bar carries, focused and blurred (FR4, FR19).
#:
#: **Muted rather than a full inverse**, which is the whole of why these are fractions. A true
#: inverse paints the row's colour at full saturation, and on a bright state — yellow, for
#: `in_progress` — that is a glare a reader's eye skips over rather than lands on. Blending partway
#: toward the background keeps the bar unmistakably that row's colour and still readable.
#:
#: The blurred column fades further, so a board with three columns says which one the keys are
#: talking to without any column losing its selection.
FOCUSED_WEIGHT = 0.42
BLURRED_WEIGHT = 0.22

#: What the bar falls back to when a strip carries no colour of its own to read. A row painted in
#: the terminal's default has no colour in its segments — `project_row` renders exactly that — and a
#: cursor that gave up on such a row would be a cursor that vanishes on the Projects column.
DEFAULT_SURFACE = ColorTriplet(18, 18, 18)
DEFAULT_ROW = ColorTriplet(224, 224, 224)

#: Above this luminance the bar is light enough that the surface reads as the legible foreground;
#: below it, near-white does. Rec. 709 midpoint, in the 0–255 range :func:`_luminance` returns.
LEGIBLE_ON_LIGHT = 128

#: How far the bar's background is lifted off the row's before the row's own colour is mixed in.
#:
#: **This is what keeps a dark row's cursor visible on a terminal without truecolor** (NFR1). A
#: blurred bar on a dark green row is `#0e2a0e`, which is a legible tint of the background in
#: 24-bit colour and quantises to palette entry 16 — pure black — on a 256-colour terminal, where
#: the surface is entry 233. The bar disappears into a background it is two shades darker than.
#:
#: Mixing into a background already a step toward the light lands the same row on entry 22, a dark
#: green, and leaves every other state where it was: the states that were already clear of the
#: surface are clear of it by the same margin, because the lift moves what the colour is mixed
#: *into* rather than how much of it there is.
SURFACE_LIFT = 0.08


def _blend(row: ColorTriplet, background: ColorTriplet, weight: float) -> ColorTriplet:
    """``row`` mixed into ``background`` by ``weight`` — 0 is all background, 1 is all row."""
    return ColorTriplet(
        round(row.red * weight + background.red * (1 - weight)),
        round(row.green * weight + background.green * (1 - weight)),
        round(row.blue * weight + background.blue * (1 - weight)),
    )


def _luminance(colour: ColorTriplet) -> float:
    """``colour``'s perceived brightness (Rec. 709), which is what decides a legible foreground."""
    return 0.2126 * colour.red + 0.7152 * colour.green + 0.0722 * colour.blue


def lifted(background: ColorTriplet) -> ColorTriplet:
    """``background`` a step toward the light — what a cursor bar is mixed into (NFR1).

    See :data:`SURFACE_LIFT`. The step is the same for every row, so what the bar carries is still
    the row's own colour and the difference between two rows is still the difference between their
    two colours.
    """
    return _blend(DEFAULT_ROW, background, SURFACE_LIFT)


def _read_colours(strip: Strip) -> tuple[ColorTriplet, ColorTriplet]:
    """The row's own colour and the background it was painted on, read from what was painted.

    Read from the strip rather than from the row it came from, because the cursor is a fact about
    the rendering and the same rule reaches every column: the Projects column's rows carry no state
    style at all, and a bar derived from a model would have nothing to derive one from there.
    """
    row: ColorTriplet | None = None
    background: ColorTriplet | None = None

    for segment in strip:
        if segment.style is None:
            continue

        if row is None and segment.text.strip() and segment.style.color:
            row = segment.style.color.get_truecolor()

        if background is None and segment.style.bgcolor:
            background = segment.style.bgcolor.get_truecolor()

    return row or DEFAULT_ROW, background or DEFAULT_SURFACE


def cursor_strip(strip: Strip, *, focused: bool) -> Strip:
    """``strip`` repainted as the cursor bar: its own colour, blended toward its own background.

    **The colour is the row's, which is the point** (FR4, FR19). A fixed accent — Textual's default
    block cursor, and every framework's — says the same thing on a blocked row as on a ready one, so
    the one row a user is looking at is the one row whose state has been painted over. Blending the
    row's own colour keeps the state on screen and adds the selection to it.

    Painting one bar across the whole strip is lossless here because every board row is a single
    colour; per-segment click metadata is carried over, so the bar costs no mouse target.
    """
    row, background = _read_colours(strip)
    bar_background = _blend(row, lifted(background), FOCUSED_WEIGHT if focused else BLURRED_WEIGHT)
    bar_foreground = background if _luminance(bar_background) > LEGIBLE_ON_LIGHT else DEFAULT_ROW
    bar = Style(
        color=Color.from_triplet(bar_foreground), bgcolor=Color.from_triplet(bar_background)
    )

    return Strip(
        [
            Segment(
                segment.text,
                bar + Style(meta=segment.style.meta) if segment.style else bar,
                segment.control,
            )
            for segment in strip
        ],
        strip.cell_length,
    )


#: The narrowest width markdown is laid out at, whatever the panel says it has (FR6). A panel
#: reporting less than this is mid-layout rather than a width anyone is reading at, and Rich's
#: tables and headings have nowhere to put themselves below it — the resize that follows re-renders
#: at the real width, so nothing is stuck at the floor.
MINIMUM_RASTER = 10

#: What a panel that has not been laid out yet is rasterised at — an ordinary terminal width, so a
#: preview rendered before the first layout reads as a document rather than as a column of single
#: characters. See :func:`_panel_width`.
FALLBACK_WIDTH = 80


class HardBreakMarkdown(Markdown):
    """`Markdown` that renders a single newline as a line break, GitHub-style (FR6).

    CommonMark treats a lone newline as a *soft* break — a space — so consecutive lines collapse
    into one run-on paragraph. The previews are built from rows, where a criterion and the criterion
    after it are two rows and two lines, so the line structure is the content rather than the
    source's formatting. Paragraph wrapping at the panel width is untouched: that is display
    wrapping, and this rewrites break *tokens*.
    """

    def __init__(self, markup: str, **kwargs: object) -> None:
        super().__init__(markup, **kwargs)

        for token in self.parsed:
            for child in token.children or []:
                if child.type == "softbreak":
                    child.type = "hardbreak"


def markdown_content(markup: str, width: int) -> Content:
    """``markup`` rasterised at ``width`` as selectable styled text (FR6).

    **Rasterised rather than handed to a markdown widget, and selection is the reason.** Textual
    maps a selection over a `Static` whose renderable is `Text` or `Content`; a live `Markdown`
    renders to strips with no selection mapping, so a preview built that way is one a user cannot
    copy a line out of. Rendering to segments at the panel's width and rebuilding them as `Content`
    keeps every heading, emphasis, list and table Rich would draw and gives the selection back.

    The raster is width-specific — that is what the width argument means — so the caller re-renders
    it when the panel resizes.

    **No colour system is named** (NFR3, ENVX4). The segments this produces carry `Style` objects
    rather than escape codes, and Textual downgrades them at output against the terminal it actually
    has; naming one here would be a claim about that terminal made in the one place that cannot see
    it, and on a 256-colour terminal it is the claim that decides whether a preview is legible.

    Trailing pad is stripped per line, so a copied selection carries no run-on whitespace.
    """
    laid_out = max(width, MINIMUM_RASTER)
    console = Console(width=laid_out)
    rendered = console.render(
        HardBreakMarkdown(markup), console.options.update_width(laid_out)
    )
    text = Text()

    for line in Segment.split_lines(rendered):
        painted = Text()

        for segment in line:
            if segment.control:
                continue

            painted.append(segment.text, style=segment.style or "")

        painted.rstrip()
        text.append_text(painted)
        text.append("\n")

    text.rstrip()

    return Content.from_rich_text(text)


class Column(OptionList):
    """One of the board's three columns, with ← and → returned to the board (FR19).

    `OptionList` inherits horizontal scroll bindings from its scrolling ancestor, and those sit
    *nearer* the focused widget than the app's own — so while a column has focus, `active_bindings`
    answers `left` with "Scroll Left", carrying `show=False`, and the footer prints neither. The
    keys still move focus, because a column that cannot scroll sideways declines its own binding and
    lets it bubble; what is lost is only the line in the footer that says so, which is exactly the
    thing this story is about.

    Re-declaring them here puts the board's meaning at the near end of the chain, where the footer
    reads. The actions are the app's, so there is one implementation of moving between columns and
    this is a second route to it rather than a second copy of it.

    **A column does not scroll sideways anyway.** Its rows are labels the layout truncates, so the
    bindings being displaced reach a scroll that has nowhere to go.

    **Its cursor is the row's own colour rather than a block of accent** (FR4, FR19). That cannot be
    had from CSS: Textual drops `text-style: reverse` in the option render path, and an option's own
    foreground wins over the component class's, so a highlight declared in the stylesheet arrives as
    a fixed background with the row's colour still on top of it. So the strip is repainted after the
    fact — see :func:`cursor_strip` — and the stylesheet's job is only to get the framework's own
    block out of the way.
    """

    BINDINGS = [
        Binding("left", "app.focus_left", "◀ column", show=True),
        Binding("right", "app.focus_right", "column ▶", show=True),
    ]

    def render_line(self, y: int) -> Strip:
        """The line Textual painted, repainted as the cursor bar when it is the highlighted row.

        The line-to-option mapping is Textual's own, so a row wrapping over two lines highlights on
        both and a scrolled column highlights the row rather than the screen position.
        """
        strip = super().render_line(y)

        try:
            option_index, _ = self._lines[self.scroll_offset.y + y]
        except IndexError:
            return strip

        if option_index != self.highlighted:
            return strip

        return cursor_strip(strip, focused=self.has_focus)


class ProjectTree(DirectoryTree):
    """A directory tree with the files taken out — the thing being chosen is a directory (FR1).

    Dot-directories go too. The one a project always has is `.dpm`, which is the marker being
    looked *for* rather than a place to look, and offering it as somewhere to descend into invites
    a user to register the marker instead of the project.
    """

    def filter_paths(self, paths):
        return [path for path in paths if path.is_dir() and not path.name.startswith(".")]


class PickerScreen(ModalScreen[Path | None]):
    """FR1's second affordance: choose a directory, without leaving the board.

    A refusal is rendered **in the picker and the picker stays open**, rather than closing and
    reporting. The user's next move after "not a dpm project" is to pick a different directory,
    and a modal that closes to say so has thrown away the thing they were doing it from.
    """

    BINDINGS = [("escape", "cancel", "Cancel")]

    def __init__(self, root: Path) -> None:
        super().__init__()
        self._root = root

    def compose(self) -> ComposeResult:
        with Vertical(id="picker"):
            yield Label("Register a project", id="picker-title")
            yield ProjectTree(self._root, id="picker-tree")
            yield Static("", id="picker-refusal")

    def on_mount(self) -> None:
        self.query_one("#picker-tree", ProjectTree).focus()

    def on_directory_tree_directory_selected(self, event) -> None:
        complaint = refusal(str(event.path))

        if complaint is not None:
            self.query_one("#picker-refusal", Static).update(complaint)
            return

        self.dismiss(event.path)

    def action_cancel(self) -> None:
        self.dismiss(None)


class SearchScreen(ModalScreen[Result | None]):
    """FR15: one query, every registered project, and a result that goes back where it came from.

    A modal for the same reason the picker is one: the thing being done is a question with an answer,
    and the three columns behind it are what the answer is *about* — a results panel wedged into the
    layout would take space from them for as long as the board was open.

    **The search runs in a worker and the screen stays up while it does** (NFR3). Twelve servers is
    twelve processes; a modal that blocked until the slowest of them answered would be a board that
    stops repainting on a keypress, which is the behaviour NFR3 exists to forbid.
    """

    BINDINGS = [("escape", "cancel", "Cancel")]

    #: What the results list says before a query is run, and when one finds nothing. **Different
    #: strings**: a board that said the same thing either way would report an unrun search and an
    #: empty answer identically, and the user's next move differs — press enter, or try other words.
    READY = "Type a query and press enter"
    NOTHING = "No matches in any registered project"
    RUNNING = "Searching…"

    def __init__(self, projects: list[ProjectView], search) -> None:
        super().__init__()
        self._projects = projects
        self._search = search
        self._results: list[Result] = []

    def compose(self) -> ComposeResult:
        with Vertical(id="search"):
            yield Label("Search every registered project", id="search-title")
            yield Input(placeholder="query", id="search-query")
            yield Static(self.READY, id="search-state")
            yield OptionList(id="search-results")

    def on_mount(self) -> None:
        self.query_one("#search-query", Input).focus()

    @property
    def results(self) -> list[Result]:
        """The rows the last query produced. Public because a driver has to wait for them.

        What it is *not* is the assertion surface: a test about what a search found reads the
        painted rows, like every other assertion about this board. This is how a caller knows the
        worker has landed, which no amount of reading strips can answer.
        """
        return list(self._results)

    def on_input_submitted(self, event) -> None:
        """Enter in the query box runs the search — nothing awaited here (NFR3)."""
        if self._search is None or not event.value.strip():
            return

        self.query_one("#search-state", Static).update(self.RUNNING)
        self.run_worker(self._run(event.value.strip()), exclusive=True)

    async def _run(self, query: str) -> None:
        self._results = await self._search(self._projects, query)

        results = self.query_one("#search-results", OptionList)
        results.clear_options()
        results.add_options([Text(result.label) for result in self._results])

        self.query_one("#search-state", Static).update(
            f"{len(self._results)} in {len({row.project for row in self._results})} projects"
            if self._results
            else self.NOTHING
        )

        if self._results:
            results.highlighted = 0
            results.focus()

    def on_option_list_option_selected(self, event) -> None:
        """A chosen result closes the screen and hands the row back — the board does the moving."""
        if 0 <= event.option_index < len(self._results):
            self.dismiss(self._results[event.option_index])

    def action_cancel(self) -> None:
        self.dismiss(None)


class GapsScreen(ModalScreen[Gap | None]):
    """FR16: every requirement no coverage row names, across every registered project.

    A modal for :class:`SearchScreen`'s reason, and the two are deliberately the same shape — both
    are a fan-out whose answer is a list of rows a user then wants to go to.

    **The one difference is that there is no query**, so the read starts on mount rather than on
    enter. That is what makes the empty state matter here in a way it does not on a search: a
    board with nothing to report and a board that has not finished asking both show an empty list,
    and they are opposite pieces of news.
    """

    BINDINGS = [("escape", "cancel", "Cancel")]

    #: The two ends of the read, and the answer that has none. **Three strings, not two**: *no
    #: gaps* is the thing a project wants to hear and *still reading* is the thing that means
    #: nothing yet, and a screen that rendered them identically would report a board mid-fan-out
    #: as a clean bill of health.
    RUNNING = "Reading every registered project…"
    NOTHING = "No coverage gaps in any registered project"

    def __init__(self, projects: list[ProjectView], gaps) -> None:
        super().__init__()
        self._projects = projects
        self._gaps = gaps
        self._results: list[Gap] | None = None

    def compose(self) -> ComposeResult:
        with Vertical(id="gaps"):
            yield Label("Requirements with no coverage row", id="gaps-title")
            yield Static(self.RUNNING, id="gaps-state")
            yield OptionList(id="gaps-results")

    def on_mount(self) -> None:
        """The read starts here, in a worker, and the screen is up while it runs (NFR3)."""
        if self._gaps is None:
            return

        self.run_worker(self._run(), exclusive=True)

    @property
    def results(self) -> list[Gap] | None:
        """The gaps the read produced, or ``None`` while it is still running.

        ``None`` rather than an empty list, so a driver waiting for the worker can tell *not yet*
        from *nothing to report* — the same distinction the two strings above draw for a reader.
        """
        return None if self._results is None else list(self._results)

    async def _run(self) -> None:
        self._results = await self._gaps(self._projects)

        results = self.query_one("#gaps-results", OptionList)
        results.clear_options()
        results.add_options([Text(gap.label) for gap in self._results])

        self.query_one("#gaps-state", Static).update(
            f"{len(self._results)} in {len({gap.project for gap in self._results})} projects"
            if self._results
            else self.NOTHING
        )

        if self._results:
            results.highlighted = 0
            results.focus()

    def on_option_list_option_selected(self, event) -> None:
        """A chosen gap closes the screen and hands the row back — the board does the moving."""
        if self._results is not None and 0 <= event.option_index < len(self._results):
            self.dismiss(self._results[event.option_index])

    def action_cancel(self) -> None:
        self.dismiss(None)


class BoardCommands(Provider):
    """The palette's source of commands — :data:`COMMANDS` and nothing else (FR18).

    Set as the app's *whole* ``COMMANDS`` set rather than added to it, which is what makes the
    palette open on the board's actions rather than on Textual's system commands with the board's
    somewhere among them. FR18's word is *straight*, and an unconfigured provider gives the other
    thing while passing any test that only asks whether the palette opened.
    """

    def _run(self, command: Command):
        return partial(self.app.run_action, command.action)

    async def discover(self):
        """What the palette shows before anything is typed — every action, in table order."""
        for command in COMMANDS:
            yield DiscoveryHit(command.name, self._run(command), help=command.help)

    async def search(self, query: str):
        matcher = self.matcher(query)

        for command in COMMANDS:
            score = matcher.match(command.name)

            if score > 0:
                yield Hit(
                    score,
                    matcher.highlight(command.name),
                    self._run(command),
                    help=command.help,
                )


def state_row(row: EpicView | StoryView, *, selected: bool = False) -> Text:
    """An epic or story row: its label, in the style its derived state maps to (FR4).

    The style is looked up rather than decided here, so the colour a user reads and the state the
    model derived are one thing with one definition.

    ``selected`` is FR14's marker, and it is a separate argument rather than a field on the row
    because the rows are replaced wholesale by every survey: a selection carried on one would be
    forgotten by the next refresh, which is the point at which a user is most likely to press launch.
    """
    label = ralph_label(row, selected) if isinstance(row, EpicView) else row.label

    return Text(label, style=style_for(row.state))


def project_row(row: ProjectView):
    """A project row. One the board could not read says so, and one still being read says that.

    **A row carrying a marker is a grid rather than a string** (FR19). The pill and the badge are
    fixed-width things that say something about the project as a whole, and appending them to the
    label leaves them wherever the name happens to end — halfway across a wide column, and first in
    line to be clipped on a narrow one. In their own right-justified cells they sit against the
    column's edge at any width, and what gives when there is not room for everything is the name,
    which is the part a reader can still recognise from half of it.

    A row with neither is the plain `Text` it always was. A grid holding one cell would lay out the
    same string through more machinery, and every project on a board where nothing is running and
    nothing is wrong is that row.
    """
    if row.unreadable is not None:
        return Text(row.label, style=UNREADABLE_STYLE)

    if row.pending:
        return Text(row.label, style=READING_STYLE)

    pill, badge = live_pill(row.live), integrity_badge(row.violations)

    if not pill and not badge:
        return Text(row.summary)

    return _marked_row(row.summary, badge=badge, pill=pill)


def _marked_row(summary: str, *, badge: str, pill: str) -> Table:
    """``summary`` filling the column, with whichever markers it carries against the right edge.

    **The pill is the outermost**, which is where the CPM board puts it and therefore where a reader
    of both looks for it; the badge — which that board has no equivalent of — sits inboard of it.
    Each is a cell of its own, so each keeps its own colour over whatever the row is painted in.

    The summary's column is the only one that flexes, and it truncates rather than wraps: a marker
    is a fixed handful of cells and a name is not, so a row too narrow for everything gives up the
    end of the name and keeps both markers whole.

    The markers' text — their order and the gap before each — is :func:`board_view.markers`', which
    is also what the row's plain-string `label` is built from. Two spellings of the same row would
    be two answers to what it says.
    """
    grid = Table.grid(expand=True)
    grid.add_column(ratio=1, no_wrap=True, overflow="ellipsis")

    cells = [Text(summary)]
    styles = [style for text, style in ((badge, BADGE_STYLE), (pill, PILL_STYLE)) if text]

    for text, style in zip(markers(badge=badge, pill=pill), styles):
        grid.add_column(justify="right", no_wrap=True)
        cells.append(Text(text, style=style))

    grid.add_row(*cells)

    return grid


class PreviewBody(Static):
    """A preview panel's body: markdown source, rasterised at whatever width the panel has (FR6).

    **The source is held here rather than on the app, and the re-render is this widget's own
    `Resize` rather than the app's.** The app's event carries the *terminal's* new size and arrives
    before the columns beneath it have been laid out again, so a raster driven from it reads the
    width the panel had a moment ago — which is the stale layout the re-render exists to replace,
    written one step later. A widget's own `Resize` is delivered with its new size, which is the
    only width worth rasterising at.
    """

    def __init__(self, **kwargs: object) -> None:
        super().__init__(**kwargs)

        #: The markdown last put in this panel. Held because the raster is width-specific and a
        #: painted `Content` cannot be reflowed back into the markdown it came from.
        self.source = ""

    def show(self, source: str) -> None:
        """Put ``source`` in the panel, rendered at the width it has now."""
        self.source = source
        self.rasterise()

    def on_resize(self, event: object) -> None:
        """Render the same source again, because the raster was laid out at the old width."""
        self.rasterise()

    def rasterise(self) -> None:
        content = markdown_content(self.source, _panel_width(self)) if self.source else Content("")

        self.update(content)


def _panel_width(body: Static) -> int:
    """The width to rasterise a panel's markdown at: its content region (FR6).

    `content_size` is what the widget has *inside* its padding and border, which is where the text
    goes. Before the first layout it is zero and so is `size`, and a raster at zero would lay every
    paragraph out one character wide — so the fallback is a width a document reads at, and the
    resize that follows the first layout re-renders at the real one.
    """
    width = body.content_size.width or body.size.width

    return width if width > 0 else FALLBACK_WIDTH


def _preview_panel(kind: str) -> VerticalScroll:
    """The read-only panel beneath a column, holding the highlighted row's preview.

    ``can_focus`` is off so that ← / → still steps between the three lists rather than through a
    panel that has nothing to select. Long previews scroll with the wheel.
    """
    panel = VerticalScroll(PreviewBody(id=f"{kind}-preview-body"), id=f"{kind}-preview")
    panel.can_focus = False

    return panel


class BoardApp(App[None]):
    """The three-column browser: Projects → Epics → Stories, previews beneath (FR4, ENV7).

    **Every value it renders was derived in :mod:`status_model` and shaped in :mod:`board_view`.**
    The app queries no server itself and recomputes no state; it is handed :class:`ProjectView`
    rows and paints them. That is what keeps the thing a user actually looks at from becoming a
    second answer to "what is the state of this project" (AD5).
    """

    TITLE = "dpm board"

    #: The palette's providers — replaced, not extended (FR18). See :class:`BoardCommands`.
    COMMANDS = {BoardCommands}

    #: FR18's key, stated rather than inherited. Textual's default happens to be the same today,
    #: and a default that agrees with the requirement is not the requirement being met: the board's
    #: key would move the day the framework moved its own, with nothing here to notice.
    COMMAND_PALETTE_BINDING = "ctrl+p"

    #: How that key reads in the footer. Textual leaves this unset and falls back to the binding's
    #: own name, which prints as `ctrl+p` in a footer where every other key is written `^`-style.
    COMMAND_PALETTE_DISPLAY = "^p"

    BINDINGS = [
        ("q", "quit", "Quit"),
        ("left", "focus_left", "◀ column"),
        ("right", "focus_right", "column ▶"),
        # Bound *and* in the palette (FR1). A capability that is only bindable is one a user finds
        # by reading the footer at the moment they happen to need it; one that is only in the
        # palette costs two keystrokes forever. Registering is rare enough to want the palette and
        # common enough to want the key.
        #
        # **`a` and `x`, which is what the CPM board binds them to** (FR19). Both boards are opened
        # by the same people in the same week, and a key that adds a project on one and does
        # something else on the other is worse than a key that does nothing: muscle memory does not
        # check which board it is looking at. The palette entries stay — this gives each a key it
        # did not have.
        ("a", "register", "Add"),
        ("x", "unregister", "Remove"),
        # FR13's pair, on the CPM board's letters. `r` re-reads and `R` empties the cache, which is
        # the opposite of the shifted-key reasoning this board was written with — and the reasoning
        # loses, because agreement between the two boards is the thing being asked for and a board
        # deciding for itself which key is the careful one is how they came apart. The forced
        # re-read, which the CPM board has no equivalent of, is a dpm extra and takes a key clear of
        # this map in story 3.
        ("r", "refresh", "Refresh"),
        ("R", "clear_cache", "Clear cache"),
        # FR19. `z` is the CPM board's key for the same capability over a narrower set of states:
        # that board hides `complete` because complete is all its model has, and this one hides
        # everything `status_model` calls finished. Same key, same gesture, more rows.
        ("z", "toggle_retired", "Show/hide done"),
        # FR13's other half, and a dpm extra: the CPM board has no forced re-read, so this
        # capability needs a key CPM leaves alone rather than the shifted letter it used to have.
        # `ctrl+r` and not `R`, which is now the clear — the two were swapped by story 1, and a
        # forced re-read landing on the key that empties the cache is the worst of the pairings.
        ("ctrl+r", "force_refresh", "Force refresh"),
        # FR15, bound and in the palette for the reason registering is: a search is the thing a user
        # opens the board to do when they cannot remember which project something is in, and that is
        # exactly the moment they will not want to go looking for it in a menu.
        ("ctrl+f", "search", "Search"),
        # FR16's key. `ctrl+g` because `g` is free and the letter keys are FR8's working set — an
        # unshifted `g` would sit among launch, open, attach and copy, where every other key acts on
        # the row under the cursor and this one does not.
        ("ctrl+g", "coverage_gaps", "Gaps"),
        # FR8's four. Single letters because they are the board's working keys — the thing a user
        # opens it to do — and each is in the palette too, so the capability is discoverable
        # without the footer being read at the moment it happens to be needed.
        ("l", "launch", "Launch"),
        # "Open project" rather than "Open", which is CPM's wording for the same action: a footer
        # reading `o Open` beside `l Launch` invites the reading that `o` opens whatever the cursor
        # is on, and what it opens is the project.
        ("o", "open", "Open project"),
        ("t", "attach", "Attach"),
        ("c", "copy_command", "Copy"),
        # FR14. A key and no palette entry, unlike everything else here: the palette acts on the
        # board as a whole and this acts on the row under the cursor, so an entry would run against
        # whichever row the palette happened to leave highlighted rather than the one a user was
        # looking at when they opened it.
        # "Ralph-select", which is CPM's wording: a bare "Select" beside a column the cursor already
        # selects a row in says nothing, and what this marks a row *for* is the thing worth naming.
        ("space", "toggle_ralph", "Ralph-select"),
    ]

    CSS = """
    #columns {
        height: 1fr;
    }
    .col {
        width: 1fr;
        border-right: solid $panel;
    }
    /* Projects is fitted to its content and capped, because its rows are names and states rather
       than the columns to its right, which hold work and want the space. The cap is what keeps a
       long project path from taking half the board. */
    #col-projects {
        width: auto;
        min-width: 24;
        max-width: 48;
    }
    /* Each previewed column splits vertically: the list on top, the highlighted row's preview
       beneath it, divided by a rule. */
    #col-epics #epics, #col-stories #stories {
        height: 1fr;
    }
    #epic-preview, #story-preview {
        height: 1fr;
        border-top: solid $panel;
        padding: 0 1;
        background: transparent;
    }
    #epic-preview-body, #story-preview-body {
        color: $text;
    }
    .col-title {
        padding: 1 2;
        color: $text-muted;
    }
    OptionList {
        height: 1fr;
        background: transparent;
        border: none;
        padding: 0 1;
    }
    OptionList:focus {
        background: transparent;
    }
    /* Take Textual's own block cursor out of the way (FR4, FR19). `Column.render_line` paints the
       highlight itself, in the row's own colour, and it reads the background to blend toward from
       the strip it was handed — so a framework cursor left in place is not merely a second
       highlight underneath the first, it is the colour the first one is mixed with. At the CSS
       layer the highlighted row therefore has to read as an ordinary row. */
    OptionList > .option-list--option-highlighted,
    OptionList:focus > .option-list--option-highlighted {
        color: $foreground;
        background: transparent;
        text-style: none;
    }
    /* The picker (FR1). Sized rather than full-screen so the board stays visible behind it — the
       thing being added is being added *to* something, and a modal that hides it reads as having
       left the board. */
    PickerScreen {
        align: center middle;
    }
    #picker {
        width: 72;
        height: 24;
        border: solid $panel;
        background: $surface;
    }
    #picker-title {
        padding: 0 1;
        color: $text-muted;
    }
    #picker-tree {
        height: 1fr;
    }
    #picker-refusal {
        padding: 0 1;
        color: red;
    }
    /* The search screen (FR15). Wider than the picker because its rows carry three things — the
       project, the row and the matching prose — and a result clipped at the excerpt is a hit whose
       relevance the user has to open it to judge. */
    SearchScreen {
        align: center middle;
    }
    #search {
        width: 110;
        height: 28;
        border: solid $panel;
        background: $surface;
    }
    #search-title, #search-state {
        padding: 0 1;
        color: $text-muted;
    }
    #search-results {
        height: 1fr;
    }
    /* The coverage-gaps screen (FR16). Narrower than the search screen because its rows carry two
       things rather than three — the project and the requirement's label — and no excerpt. */
    GapsScreen {
        align: center middle;
    }
    #gaps {
        width: 80;
        height: 24;
        border: solid $panel;
        background: $surface;
    }
    #gaps-title, #gaps-state {
        padding: 0 1;
        color: $text-muted;
    }
    #gaps-results {
        height: 1fr;
    }
    """

    def __init__(
        self,
        projects: list[ProjectView] | None = None,
        *,
        reader=None,
        survey=None,
        reload=None,
        register=None,
        unregister=None,
        picker_root=None,
        launch=None,
        sessions=None,
        clear_cache=None,
        search=None,
        gaps=None,
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        #: ``async (root, row) -> str`` — what a highlighted row's preview says (FR7). Injected,
        #: because the app owns no server: :func:`previews` binds one to a pool, and a test binds
        #: one to whatever it wants the panel to have been given.
        self._reader = reader

        #: ``async (ProjectView, *, fresh) -> ProjectView`` — one project's rows (NFR3). Injected
        #: for the same reason as ``reader``, and left out by every test whose subject is the
        #: layout. ``fresh`` is FR13's force-refresh, decided by the action the user pressed and
        #: passed straight through: the app holds no cache and knows nothing about one.
        self._survey = survey

        #: ``async (projects, query) -> list[Result]`` — every project's hits for one query (FR15).
        #: Injected like every other read: the app owns no pool, and the fan-out is the one action
        #: that would otherwise have it talking to twelve servers at once.
        self._search = search

        #: ``async (projects) -> list[Gap]`` — every project's untraced requirements (FR16).
        #: Injected for ``search``'s reason, and it is the second fan-out on the board: the app
        #: owns no pool, and a default here would have a layout test talking to every registered
        #: project the moment somebody pressed the key.
        self._gaps = gaps

        #: ``() -> None`` — forget every cached answer (FR13). Injected like the rest, and for the
        #: sharpest version of the reason: with a default, a test that stood the app up and pressed
        #: the key would delete the *user's* own cache file.
        self._forget = clear_cache

        #: ``() -> list[ProjectView]`` — the registry, re-read. Injected rather than read here for
        #: the same reason as the two above: the app owns no registry file any more than it owns a
        #: pool, and a default that fell back to the real one would have a test refreshing the
        #: user's own projects.
        self._reload = reload

        #: ``(Path) -> None`` each — register and unregister one project (FR1). Same rule; they are
        #: the only actions here that write anything, and what they write to is the registry rather
        #: than any project (FR10).
        #:
        #: **Not** ``_register`` and ``_unregister``: both are methods on Textual's ``App``, and
        #: assigning over them replaces the framework's node registration with a callable that
        #: takes different arguments. The board's first screen then fails to mount, in a traceback
        #: that names Textual's code and nothing of the board's.
        self._add_project = register
        self._drop_project = unregister

        #: Where the picker's tree starts. The working directory, because a user opening the board
        #: to add a project is nearly always standing in one or beside one.
        self._picker_root = Path(picker_root) if picker_root is not None else Path.cwd()

        #: ``() -> list[Session]`` — every live session the board launched (FR12). Injected like
        #: the reads are, and for a sharper reason: with a default, every test that stands the app
        #: up would ask the *user's* own tmux server what is running and paint whatever it found.
        self._sessions = sessions

        #: Session name to the window id it was first seen with (FR12). A launched session whose
        #: window id has changed is not the session the board knew — it was replaced rather than
        #: closed — and the pill goes, which a count of live sessions alone would not notice.
        #: Never updated: re-learning the new id here would put the pill back a poll later and
        #: report the replacement as the board's own work.
        self._windows: dict[str, str] = {}

        #: ``(intent, ProjectView, list[str] | None) -> None`` — what a launch key does (FR8).
        #: Injected like every other thing the app does not own: the app decides *what* was asked
        #: for and which target follows the focused column, and something else owns the tmux
        #: server. With none bound, the keys resolve their target and stop, which is what a test
        #: about the resolution drives.
        self._launch = launch

        #: Where the cursor is, and therefore what the columns to its right hold. One object rather
        #: than three indices on the app, because they are only meaningful together.
        self.selection = Selection(list(projects or []))

        #: Per panel, the id of the row whose preview is being awaited — see :meth:`_preview`.
        self._awaited: dict[str, str] = {}

        #: The epics `space` has put in the ralph selection (FR14), by id.
        #:
        #: **Ids, not rows.** Every survey replaces the row objects, so a held row would be one that
        #: is no longer in the column — and the moment a refresh lands is exactly when a user is
        #: about to press launch on what they selected before it.
        #:
        #: One flat set for the whole board rather than one per project, because
        #: :meth:`ralph_selection` reads it *through* the epics on screen: a selection made in one
        #: project contributes nothing to another's launch, and comes back intact on returning to it.
        self._ralph: set[str] = set()


    def compose(self) -> ComposeResult:
        yield Header()

        with Horizontal(id="columns"):
            with Vertical(classes="col", id="col-projects"):
                yield Label("Projects", classes="col-title")
                yield Column(id="projects")

            with Vertical(classes="col", id="col-epics"):
                yield Label("Epics", classes="col-title")
                yield Column(id="epics")
                yield _preview_panel("epic")

            with Vertical(classes="col", id="col-stories"):
                yield Label("Stories", classes="col-title")
                yield Column(id="stories")
                yield _preview_panel("story")

        yield Footer()

    def on_mount(self) -> None:
        self.repaint()
        self.query_one("#projects", OptionList).focus()
        self.start_survey()
        self.start_pills()

    # --- reading -------------------------------------------------------------

    def start_survey(self, indices=None, *, fresh: bool = False) -> None:
        """One worker per project, none of them awaited here (NFR3).

        **A worker each, rather than one worker over the list.** A single worker would keep the UI
        thread free just as well and would still make the tenth project wait on the first nine, so
        the column would fill in registry order at the speed of the slowest server in front of it.
        Read concurrently, each row lands when its own server answers.

        Nothing is awaited in this method, which is the requirement: it is called from
        ``on_mount`` and has to return before the first paint.

        ``indices`` narrows it to some of the rows. A registration adds one project, and putting
        every other row back to `reading…` and re-spawning its server for that is a board-wide
        flicker over a change that touched one of them.

        ``fresh`` is handed to every survey it starts (FR13), so a force-refresh reaches all of
        them: the cache is per project, and refreshing only the highlighted one would leave the
        board's own figures disagreeing about when they were read.
        """
        if self._survey is None:
            return

        rows = self.selection.projects
        chosen = range(len(rows)) if indices is None else indices

        for index in chosen:
            self.run_worker(self._fill_project(index, rows[index], fresh), exclusive=False)

    async def _fill_project(self, index: int, project: ProjectView, fresh: bool = False) -> None:
        """Read one project and put it back where it was.

        **By index, not by searching for the row.** The rows are replaced as they arrive and a
        project can legitimately appear twice under two names, so matching on identity would be
        matching on a value that is no longer there or is not unique.
        """
        filled = await self._survey(project, fresh=fresh)

        if index >= len(self.selection.projects):
            return

        # The live count is the pill poll's answer, not the survey's, and the two land
        # independently: a survey that replaced the row wholesale would drop a pill that arrived
        # while it was reading.
        self.selection.projects[index] = replace(filled, live=self.selection.projects[index].live)

        # Only the row that arrived changed, so only the columns that show it are repainted. A
        # full repaint per arrival would re-request the highlighted row's preview once per project
        # in the registry, for a panel whose contents did not change.
        if index == self.selection.project:
            self.repaint()
        else:
            self.paint_projects()

    # --- live sessions (FR12) ------------------------------------------------

    def start_pills(self) -> None:
        """Ask which sessions are live, now and every :data:`LIVE_POLL` seconds after (FR12).

        Polled rather than driven by the board's own launches, because the answer changes without
        the board doing anything: the user quits Claude, the session ends, and a pill that only
        moved when a key was pressed would go on reporting a session that is not there.
        """
        if self._sessions is None:
            return

        self.poll_pills()
        self.set_interval(LIVE_POLL, self.poll_pills)

    def poll_pills(self) -> None:
        """One poll, in a worker — nothing here waits on tmux (NFR3).

        The rule NFR3 states about tool calls holds for this read for the same reason: it spawns a
        process, and a spawn on the UI thread is a board that stops repainting while it happens.
        """
        self.run_worker(self._read_pills(), exclusive=False)

    async def _read_pills(self) -> None:
        """Count each project's live sessions and put the counts on its row.

        One tmux call for the whole board rather than one per project: the server answers for every
        session it has, and asking it once per registered project would spawn a process per row to
        learn what one answer already said.
        """
        found = await asyncio.to_thread(self._sessions)
        counted: dict[str, int] = {}

        for session in found:
            # First sighting records the window; a later sighting under a different one is a
            # different window, so the session the board knew has gone.
            known = self._windows.setdefault(session.name, session.window)

            if known == session.window:
                counted[session.path] = counted.get(session.path, 0) + 1

        rows = self.selection.projects

        for index, row in enumerate(rows):
            live = counted.get(str(row.path), 0)

            if live != row.live:
                rows[index] = replace(row, live=live)

        self.paint_projects()

    # --- painting ------------------------------------------------------------

    def repaint(self) -> None:
        """Rebuild all three columns and both previews from :attr:`selection`.

        The columns to the right of the cursor are a *function* of it, so they are painted from it
        and from nothing else — that is what keeps the Stories column from being under an epic it
        does not belong to.
        """
        self.selection.clamp()

        self.paint_projects()
        self.paint_epics()
        self.paint_stories()

    def paint_projects(self) -> None:
        self._fill("projects", [project_row(row) for row in self.selection.projects])
        self._highlight("projects", self.selection.project)

    def paint_epics(self) -> None:
        self._fill(
            "epics",
            [state_row(row, selected=row.id in self._ralph) for row in self.selection.epics],
        )
        self._highlight("epics", self.selection.epic)
        self._preview("epic", self.selection.current_epic)

    def paint_stories(self) -> None:
        self._fill("stories", [state_row(row) for row in self.selection.stories])
        self._highlight("stories", self.selection.story)
        self._preview("story", self.selection.current_story)

    def _fill(self, column: str, labels: list[Text]) -> None:
        option_list = self.query_one(f"#{column}", OptionList)
        option_list.clear_options()
        option_list.add_options(labels)

    def _highlight(self, column: str, index: int) -> None:
        option_list = self.query_one(f"#{column}", OptionList)
        option_list.highlighted = index if option_list.option_count else None

    def _preview(self, kind: str, row: EpicView | StoryView | None) -> None:
        """Render the highlighted row's preview beneath its column (FR4, FR7).

        The label goes up immediately and the rows-derived text replaces it when the read comes
        back, so a moved cursor never leaves the panel showing the row it left. With no reader —
        the browser before a pool is bound to it — the label is all there is, which is the right
        answer rather than a blank panel.
        """
        if row is None:
            self._paint_preview(kind, "")
            return

        self._paint_preview(kind, row.label)

        project = self.selection.current_project

        if self._reader is None or project is None:
            return

        # Stamped on the request and checked on the answer: a slow read for a row the cursor has
        # since left must not paint over the row it is on now. The panel is of the *highlighted*
        # row, and "whichever read finished last" is a different and wrong rule.
        self._awaited[kind] = row.id
        self.run_worker(self._fill_preview(kind, project.path, row), exclusive=False)

    async def _fill_preview(self, kind: str, root: Path, row: EpicView | StoryView) -> None:
        text = await self._reader(root, row)

        if self._awaited.get(kind) == row.id:
            self._paint_preview(kind, text)

    def _paint_preview(self, kind: str, source: str) -> None:
        """Put ``source`` in ``kind``'s panel (FR6).

        Everything a panel shows goes through here, the row's label included: a placeholder painted
        some other way would be the one thing the panel could not render again on a resize.
        """
        self.query_one(f"#{kind}-preview-body", PreviewBody).show(source)

    # --- navigation ----------------------------------------------------------

    def show(self, projects: list[ProjectView]) -> None:
        """Replace the rows, keeping the cursor wherever it still means something.

        **This is the case that makes the indices worth clamping rather than resetting.** A read
        can come back with an epic gone — retired, or deleted between one refresh and the next —
        while its stories are on screen. Resetting would yank the user to the top of a list they
        were reading; holding the old index would point the stories column at a row that is not
        there. Clamping moves the cursor the least it can and leaves the columns consistent.
        """
        self.selection.projects = list(projects)
        self.repaint()

    def on_option_list_option_highlighted(self, event: OptionList.OptionHighlighted) -> None:
        """A moved cursor is a new selection, and the columns to its right follow from it.

        **The guard is that the index actually changed, not a flag saying "I am painting".** The
        app's own writes raise this event too — filling a list clears its highlight, and setting
        one restores it — but Textual delivers the event through the message pump, so it arrives
        *after* any flag the writing code set has been cleared. A repaint that painted a column
        therefore triggered a repaint that painted it again, without end. Comparing against the
        selection cannot come apart from the pump's timing: an event that agrees with where the
        cursor already is has nothing to propagate.

        Everything to the *right* of the moved cursor starts again from the top — those rows
        belong to a different parent now, so a remembered index would index a list that is gone.
        """
        index = event.option_index

        if index is None:
            return

        if event.option_list.id == "projects":
            if index == self.selection.project:
                return

            self.selection.project = index
            self.selection.epic = 0
            self.selection.story = 0
            self.selection.clamp()
            self.paint_epics()
            self.paint_stories()

        elif event.option_list.id == "epics":
            if index == self.selection.epic:
                return

            self.selection.epic = index
            self.selection.story = 0
            self.selection.clamp()
            # The epics list itself is not repainted — the cursor is already where the user put
            # it — but the panel beneath it is of the *highlighted row*, so it moves with them.
            self._preview("epic", self.selection.current_epic)
            self.paint_stories()

        elif event.option_list.id == "stories":
            if index == self.selection.story:
                return

            self.selection.story = index
            self.selection.clamp()
            self._preview("story", self.selection.current_story)

    def action_focus_left(self) -> None:
        self._move_focus(-1)

    def action_focus_right(self) -> None:
        self._move_focus(1)

    def focused_column(self) -> str:
        """Which of :data:`COLUMNS` the cursor is in, or the leftmost when it is somewhere else.

        The fallback is not a guess about focus: the board opens with Projects focused, and
        anything that is not one of the three lists — a modal, the palette — is not a column whose
        target FR8 documents.
        """
        focused = self.focused

        return focused.id if focused is not None and focused.id in COLUMNS else COLUMNS[0]

    def _move_focus(self, delta: int) -> None:
        """Step focus along :data:`COLUMNS`, stopping at the ends rather than wrapping.

        Wrapping would make ← from Projects land on Stories, which reads as a jump rather than a
        move; the columns are a left-to-right drill-down and the ends of one are its ends.
        """
        target = max(0, min(len(COLUMNS) - 1, COLUMNS.index(self.focused_column()) + delta))

        self.query_one(f"#{COLUMNS[target]}", OptionList).focus()

    # --- launching (FR8) -----------------------------------------------------

    def current_candidate(self) -> Candidate | None:
        """What could be done next to the highlighted epic — for the Stories column too.

        **A story is not a candidate.** The Stories column's rows belong to the epic above them and
        that epic is what a session would be started on, which is why FR8 gives the two columns one
        target: the candidate is a property of the row the work hangs off, not of the cursor's
        depth.
        """
        epic = self.selection.current_epic

        return epic.candidate if epic is not None else None

    def ralph_selection(self) -> list[str]:
        """The selected epics of the project on screen, in the order the column holds them (FR14).

        **Read through the epics on screen rather than out of the set directly**, which is what makes
        one set safe for the whole board: an id selected in another project is not among these rows
        and so contributes nothing here.

        Column order, not the order they were pressed. A ralph run works the epics in the order it is
        given them, and the column's order is the project's own — reproducible, and the same twice.
        """
        return [row.id for row in self.selection.epics if row.id in self._ralph]

    def action_toggle_ralph(self) -> None:
        """`space` — put the highlighted epic in the ralph selection, or take it out (FR14).

        **A refusal is said out loud.** The three kinds that cannot be selected are refused by
        :func:`selectable`, and a key that quietly did nothing over them would be indistinguishable
        from a board whose selection is broken — the user's next move would be to press it again.
        """
        row = self.selection.current_epic

        if self.focused_column() == PROJECTS or row is None:
            self.notify("epics are selected in the Epics column", severity="warning")
            return

        if row.id in self._ralph:
            self._ralph.discard(row.id)
        elif not selectable(row.candidate):
            self.notify(f"{row.title} is not an epic that can be run now", severity="warning")
            return
        else:
            self._ralph.add(row.id)

        self.paint_epics()

    def current_target(self) -> list[str] | None:
        """FR8's target for wherever the cursor is, or FR14's for a selection — ``None`` for neither.

        A row with no candidate is *reported*, not launched — a notification rather than an
        exception, because this is reached from a keypress and the alternative to saying so is
        starting a session about something the user was not pointing at.
        """
        try:
            return launch_target(
                self.focused_column(), self.current_candidate(), self.ralph_selection()
            )
        except NoTarget as absent:
            self.notify(str(absent), severity="warning")

            return None

    def action_launch(self) -> None:
        """`l` — run the focused column's target in a session of its own."""
        target = self.current_target()

        if target is not None:
            self._start(LAUNCH, target)

    def action_open(self) -> None:
        """`o` — a plain Claude at the project, with no command. No target by definition."""
        self._start(OPEN, None)

    def action_attach(self) -> None:
        """`t` — join this terminal to a session that is already running for this project."""
        self._start(ATTACH, None)

    def action_copy_command(self) -> None:
        """`c` — put the whole launch command on the clipboard, quoted (FR8, NFR4).

        The same ``cd … && claude …`` string a launch runs, because that is what a user pastes into
        a terminal: the target alone is not a command anyone can run, and a second way of building
        this line would be a second set of quoting rules to get wrong.
        """
        project = self.selection.current_project
        target = self.current_target()

        if project is not None and target is not None:
            self.copy_to_clipboard(launch_command(project.path, target))

    def _start(self, intent: str, target: list[str] | None) -> None:
        """Hand one launch intent to whatever owns sessions, with the project it is about.

        A tmux invocation that fails is *reported*, not raised: this is reached from a keypress, and
        an exception out of an action puts an error screen over a board whose other projects are
        fine (NFR2's rule, one layer up from the reads it was written about).
        """
        project = self.selection.current_project

        if project is None or self._launch is None:
            return

        try:
            with self._foreground(intent):
                self._launch(intent, project, target)
        except Degraded as fallback:
            # ENVX1: without tmux the command is still the right command, so the key does the one
            # useful thing left rather than reporting that it cannot. This is `c`'s behaviour, and
            # `c` is deliberately the thing everything degrades *to*: it needs neither binary.
            self.copy_to_clipboard(fallback.command)
            self.notify(str(fallback), severity="warning")
        except LaunchFailed as failure:
            self.notify(str(failure), severity="error")

    @contextmanager
    def _foreground(self, intent: str):
        """The terminal, handed over for an attach and taken back afterwards (FR8).

        ``tmux attach`` owns the terminal until the user detaches, so the board has to stop drawing
        on it first — otherwise two programs paint the same screen and neither is readable. A
        launch needs none of this: the session it starts is detached.

        A driver that cannot suspend is one where nothing is sharing this terminal with the board,
        so the attach runs as it is rather than being refused.
        """
        if intent != ATTACH or self._driver is None or not self._driver.can_suspend:
            yield
            return

        with self.suspend():
            yield

    # --- the palette's actions (FR18) ----------------------------------------

    def action_refresh(self) -> None:
        """Read every registered project again, from the registry outwards.

        The rows are rebuilt from the registry rather than re-pended in place, so a project
        registered since the board opened appears and one unregistered elsewhere goes — and a
        project that was unreadable is *retried* rather than kept at the state it failed in, which
        is the reason a user reaches for refresh at all.
        """
        self._reread()

    def action_force_refresh(self) -> None:
        """The same refresh, with every read taken from the servers rather than the cache (FR13).

        **What this is for is the write the stamp cannot see.** An entry is invalidated by the
        database's mtime and size, and a write that leaves both exactly as they were is
        indistinguishable from no write at all — so the user who has just made one needs a way to
        say so. Nothing is discarded: the reads land back in the cache under the stamp they were
        true of, which is the difference between this and :meth:`action_clear_cache`.
        """
        self._reread(fresh=True)

    def action_clear_cache(self) -> None:
        """Forget every cached answer, in memory and on disk (FR13).

        **The board is not re-read.** Clearing is what a user does to establish that the cache is
        not the cause of what they are looking at, and a clear that immediately repopulated it
        would answer a different question — the rows on screen are the ones they were asking about.
        The next read fills it again, which is the point at which they will have decided what to do.
        """
        if self._forget is not None:
            self._forget()

    def action_toggle_retired(self) -> None:
        """Show or hide finished work — complete, superseded and withdrawn (FR19).

        **Each press says which way it went**, because the two states are told apart by what is on
        screen and a board with nothing finished under it looks identical in both. Without the
        message, pressing `z` on such a project reads as a key that does nothing, and the next
        thing a user does is press it again.

        Nothing is re-read. The rows are already in hand and the filter is applied where the
        columns are built from them, so this is a repaint rather than a survey — which is also what
        makes the toggle instant on a project the board took seconds to read.
        """
        self.selection.show_retired = not self.selection.show_retired

        self.repaint()
        self.notify("Showing finished work" if self.selection.show_retired else "Hiding finished work")

    def _reread(self, *, fresh: bool = False) -> None:
        """The rebuild both refreshes share: registry first, then a survey per row."""
        if self._reload is not None:
            self.selection.projects = self._reload()

        self.repaint()
        self.start_survey(fresh=fresh)

    def action_search(self) -> None:
        """Open the search screen over every registered project (FR15)."""
        self.push_screen(SearchScreen(self.selection.projects, self._search), self.found)

    def action_coverage_gaps(self) -> None:
        """Open the coverage-gaps screen over every registered project (FR16)."""
        self.push_screen(GapsScreen(self.selection.projects, self._gaps), self.found)

    def found(self, result: Result | Gap | None) -> None:
        """Move the three columns to the project and epic a chosen row came from (FR15, FR16).

        One method for both fan-outs rather than two, because both answers are the same claim — a
        project, and a document in it when the board is holding one. A second copy of this would be
        a second place for *by id, not by index* to be got wrong.

        **By id, not by index.** The result was built from the rows as they stood when the search
        ran, and a survey can land while the screen is open — an index would then point at whatever
        row had moved into that position. A row that has genuinely gone leaves the cursor where it
        can get to: the project, which is the part that cannot go stale while it is registered.

        A cancel is ``None`` and changes nothing, which is the same rule the picker follows.
        """
        if result is None:
            return

        for index, project in enumerate(self.selection.projects):
            if project.path != result.project:
                continue

            self.selection.project = index
            self.selection.epic = 0
            self.selection.story = 0

            # Over the *visible* epics, because that is the column the index addresses. Enumerating
            # the project's own tuple was right while nothing was hidden and became an off-by-n the
            # moment `z` could take rows out of it — the cursor would land on whichever epic had
            # moved up into the position the hidden one used to occupy.
            #
            # A hit on a hidden row reveals the filter rather than being dropped: the search reads
            # every epic the project holds, so a result the board then refused to move to would be
            # a row it had just offered and could not reach.
            if any(row.id == result.document for row in project.epics):
                self.selection.show_retired = self.selection.show_retired or not any(
                    row.id == result.document for row in self.selection.epics
                )

            for epic, row in enumerate(self.selection.epics):
                if row.id == result.document:
                    self.selection.epic = epic

            break

        self.repaint()
        self.query_one("#projects", OptionList).focus()

    def action_register(self) -> None:
        """Open the directory picker (FR1). What happens to the chosen path is :meth:`registered`."""
        self.push_screen(PickerScreen(self._picker_root), self.registered)

    def registered(self, chosen: Path | None) -> None:
        """The picker's answer. ``None`` is a cancel, and a cancel changes nothing."""
        if chosen is None or self._add_project is None:
            return

        self._add_project(chosen)
        self.rescan()

    def rescan(self) -> None:
        """Take the registry's word for which projects there are, keeping what has been read.

        **"Without a restart" is the criterion, and the failure it names is the registration
        landing in the file and not in the view** — which looks exactly like the picker not
        working. So the rows come back from the registry rather than from an assumption about what
        was just written to it: the registry normalises the path it stores, and a row built here
        from the picker's own answer would be a second, quietly different account of it.

        Only genuinely new rows are read. Every project already surveyed keeps its epics and its
        counts, because nothing about it changed.
        """
        if self._reload is None:
            return

        read = {row.path: row for row in self.selection.projects if not row.pending}
        rows = [read.get(row.path, row) for row in self._reload()]
        fresh = [index for index, row in enumerate(rows) if row.pending]

        self.selection.projects = rows
        self.repaint()
        self.start_survey(fresh)

    def action_copy_path(self) -> None:
        """Put the highlighted project's path on the clipboard."""
        project = self.selection.current_project

        if project is not None:
            self.copy_to_clipboard(str(project.path))

    def action_unregister(self) -> None:
        """Unregister the highlighted project, and take its row off the board.

        The row goes without waiting for a refresh: the registry is this board's own file, so
        re-reading it to find out what this board just did to it is a round trip that can only
        disagree with itself.
        """
        project = self.selection.current_project

        if project is None or self._drop_project is None:
            return

        self._drop_project(project.path)
        self.selection.projects = [
            row for row in self.selection.projects if row.path != project.path
        ]
        self.repaint()


def run_cli(
    argv: list[str],
    *,
    registry_file: Path | None = None,
    out=None,
    err=None,
    make_pool=None,
) -> int:
    """The board's command line: ``add`` / ``list`` / ``remove``.

    ``registry_file``, ``out``, ``err`` and ``make_pool`` are injected so the whole surface is
    drivable in-process. A test that had to spawn a subprocess to read a refusal would be asserting
    on a pipe, and the thing under test here is which message came out of which stream.

    ``make_pool`` is a factory rather than a pool because the pool owns processes: built here, it
    is entered and left inside one `asyncio.run`, and a caller cannot hand in a live one built on
    an event loop that has already finished.
    """
    out = out or sys.stdout
    err = err or sys.stderr
    # The default pool caches (FR13); an injected one decides for itself, which is what keeps a test
    # about a read from being answered out of the user's own cache file. `list` gets it as well as
    # the browser: it is the command a shell prompt or a status line calls, and the round trip it
    # saves there is a server per project per invocation.
    make_pool = make_pool or (lambda: ServerPool(cache=Cache()))

    parser = argparse.ArgumentParser(
        prog="dpm-board", description="The dpm board: browse registered projects, or manage them."
    )
    # Optional, because the board's default is the thing it is for: no subcommand opens the TUI.
    sub = parser.add_subparsers(dest="command", required=False)

    add_parser = sub.add_parser("add", help="Register a dpm project by path.")
    add_parser.add_argument("path")
    add_parser.add_argument("--label", default=None, help="Optional display label.")

    remove_parser = sub.add_parser("remove", help="Unregister a project path.")
    remove_parser.add_argument("path")

    sub.add_parser("list", help="List registered projects.")

    args = parser.parse_args(argv)

    if args.command == "add":
        return _add(args.path, args.label, registry_file, out, err)

    if args.command == "remove":
        return _remove(args.path, registry_file, out)

    if args.command == "list":
        return _list(registry_file, out, err, make_pool)

    return _browse(registry_file, err, make_pool)


def _browse(registry_file: Path | None, err, make_pool) -> int:
    """Open the browser over every registered project (FR4, NFR3).

    **Nothing is read before the app starts.** The rows come from the registry, which is a file;
    the app opens on them and each project's reads run in a worker of its own. A survey here would
    keep the terminal blank until the slowest server in the registry had finished its handshake,
    which is the behaviour NFR3 exists to forbid.
    """
    asyncio.run(_browse_with(registry_file, make_pool))

    return 0


async def _browse_with(registry_file: Path | None, make_pool) -> None:
    """Run the browser with a live pool behind its reads, closed when the app exits.

    One pool for the whole session: a preview is read when a row is highlighted, which goes on for
    as long as the browser is open, and the servers the survey spawned are the ones it reads
    through (AD4).

    The registry file is closed over rather than handed to the app, which is the same rule as the
    pool: the app owns neither, so a test can drive every palette action without either one.
    """
    def reload() -> list[ProjectView]:
        return registry_views(list_projects(registry_file=registry_file))

    async with make_pool() as pool:
        app = BoardApp(
            reload(),
            reader=previews(pool),
            survey=lambda project, *, fresh=False: survey_project(pool, project, fresh=fresh),
            reload=reload,
            register=lambda path: add_project(str(path), None, registry_file=registry_file),
            unregister=lambda path: remove_project(str(path), registry_file=registry_file),
            launch=tmux_launcher(),
            sessions=live_sessions,
            # Bound to whatever cache the pool was built with, or to nothing when it has none — a
            # pool without one has nothing to clear, and a board that reached past it to the default
            # file would be clearing a cache it was not reading from.
            clear_cache=None if pool.cache is None else pool.cache.clear,
            search=lambda projects, query: search_projects(pool, projects, query),
            gaps=lambda projects: gaps_projects(pool, projects),
        )

        await app.run_async()


if __name__ == "__main__":
    sys.exit(run_cli(sys.argv[1:]))
