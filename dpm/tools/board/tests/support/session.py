"""A full board session over one project, and the file set it was run against (FR10).

**"A full board session" is the operative phrase**, and it is why this is a driver rather than a
walk through a couple of screens. A board that never opened a preview is a board that never called
the read tool a preview goes through, and an assertion that such a session left a project untouched
is an assertion about a session nobody has.

Two things make the session *provably* full rather than as full as whoever wrote it remembered. It
walks the columns by enumeration — every project, every epic under each, every story under each —
rather than by pressing `down` a plausible number of times. And it runs the board's own
:data:`board.COMMANDS` table, reporting back which actions it ran, so an action added by a later
epic is either exercised here or named in :data:`NOT_IN_A_SESSION` with a reason.
"""

from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path

from pilot import board, palette, until

from board import (
    COLUMNS,
    COMMANDS,
    gaps_projects,
    previews,
    registry_views,
    search_projects,
    survey_project,
)
from mcp_client import ServerPool
from registry import RegistryEntry

#: How long the survey is given to finish before the walk starts.
SETTLE = 30.0

#: The palette actions a session deliberately does not run, and why.
#:
#: Reconciled against :data:`board.COMMANDS` in both directions, so this is an exclusion list that
#: cannot go stale quietly: an action added to the board is exercised or named here, and a name here
#: that is no longer an action fails as loudly.
NOT_IN_A_SESSION: dict[str, str] = {
    "quit": "ends the session this driver is inside",
    "register": "opens a modal over a directory tree; what it would write is the registry, not a project",
    "unregister": "takes the row off the board, so everything after it would read nothing",
}

#: The query the session runs (FR15).
#:
#: A word every dpm project's prose holds, because a query that matched nothing would exercise the
#: fan-out and none of the reads behind it — and a search that read nothing is a search that could
#: not have written anything either, which is the claim this driver exists to support.
QUERY = "story"


@dataclass(frozen=True)
class Observed:
    """One project, before and after a full board session over it."""

    #: Path to file digest, size and mtime, taken either side of the session.
    before: dict[str, tuple[str, int, int]]
    after: dict[str, tuple[str, int, int]]
    #: Which palette actions the session ran, and what the palette offered when it opened.
    ran: set[str]
    offered: list[str]


def snapshot(root: Path) -> dict[str, tuple[str, int, int]]:
    """Every file under ``root``, by content digest, size and modification time.

    All three, because they fail differently: a digest catches a rewrite that kept the length, a
    size catches a truncation the digest would also catch but names it legibly, and an mtime catches
    a write that happened to produce identical bytes — which is exactly what re-running a migration
    or regenerating a projection looks like.
    """
    found = {}

    for path in sorted(root.rglob("*")):
        if path.is_file():
            stat = path.stat()
            found[str(path.relative_to(root))] = (
                sha256(path.read_bytes()).hexdigest(),
                stat.st_size,
                stat.st_mtime_ns,
            )

    return found


async def _focus(app, pilot, column: str) -> None:
    """Move focus to ``column`` with the keys, so the focus actions are exercised too."""
    while app.focused_column() != column:
        here = COLUMNS.index(app.focused_column())
        await pilot.press("right" if COLUMNS.index(column) > here else "left")


async def _walk(app, pilot) -> None:
    """Every row of every column, and therefore every preview the session can open.

    Enumerated from the selection rather than pressed a fixed number of times: the fixture grows,
    and a walk of six `down`s over a project that has eight epics is a walk that stops reporting
    the moment it matters.
    """
    for project in range(len(app.selection.projects)):
        await _focus(app, pilot, "projects")

        if project:
            await pilot.press("down")

        for epic in range(len(app.selection.epics)):
            await _focus(app, pilot, "epics")

            if epic:
                await pilot.press("down")

            for story in range(len(app.selection.stories)):
                await _focus(app, pilot, "stories")

                if story:
                    await pilot.press("down")


async def _search(app, pilot) -> None:
    """Open the search screen, run one query across every project, and close it again (FR15).

    Driven rather than dispatched, because the action alone only opens a modal: what has to happen
    inside a session that claims to be full is the *query* — the `search` call and the section read
    behind it — and an action that opened and closed reaches neither.
    """
    await pilot.press("ctrl+f")
    await pilot.pause()

    for character in QUERY:
        await pilot.press(character)

    await pilot.press("enter")
    await until(pilot, lambda: getattr(app.screen, "results", None), timeout=SETTLE)
    await pilot.press("escape")
    await pilot.pause()


async def _coverage_gaps(app, pilot) -> None:
    """Open the coverage-gaps screen, let the fan-out land, and close it again (FR16).

    Driven rather than dispatched, for the reason the search is: the action alone pushes a modal,
    and what has to happen inside a session claiming to be full is the *read* — the
    `list_requirement` and `list_coverage` calls the screen starts on mount. Waiting on ``results``
    rather than on a pause is what makes that a fact about the worker rather than about timing;
    ``None`` until it lands is exactly the distinction that makes the wait possible.
    """
    await pilot.press("ctrl+g")
    await pilot.pause()
    await until(pilot, lambda: getattr(app.screen, "results", None) is not None, timeout=SETTLE)
    await pilot.press("escape")
    await pilot.pause()


async def run(root: Path, *, cache=None) -> Observed:
    """Snapshot ``root``, run a full board session over it, and snapshot it again.

    The pool is the real one and the server is the real ``bin/dpm-mcp.js`` — a stand-in would prove
    that the board sent no mutating call, which is a different claim from this one and is Task 3.3's.

    ``cache`` gives the pool a freshness cache (FR13). Left out, the session runs without one, which
    is what a caller asking "did the board write anything at all" wants; handed one, the session is
    also the case Story 1's must-NOT needs — a board that definitely wrote a cache entry, so that
    the unchanged tree afterwards is evidence about where the entry landed rather than about a
    cache that was never populated.
    """
    entries = [RegistryEntry(str(root))]
    before = snapshot(root)
    ran: set[str] = set()

    def reload() -> list:
        return registry_views(entries)

    async with ServerPool(cache=cache) as pool:
        async with board(
            reload(),
            reader=previews(pool),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
            reload=reload,
            clear_cache=None if cache is None else cache.clear,
            search=lambda projects, query: search_projects(pool, projects, query),
            gaps=lambda projects: gaps_projects(pool, projects),
        ) as (app, pilot):
            await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )
            await _walk(app, pilot)

            # The palette opened for real, which is what exercises the provider (FR18); the actions
            # below are then run the way a palette hit runs them.
            await pilot.press("ctrl+p")
            await pilot.pause()
            offered = palette(app)
            await pilot.press("escape")
            await pilot.pause()

            for command in COMMANDS:
                if command.action in NOT_IN_A_SESSION:
                    continue

                if command.action == "search":
                    await _search(app, pilot)
                elif command.action == "coverage_gaps":
                    await _coverage_gaps(app, pilot)
                else:
                    await app.run_action(command.action)
                    await pilot.pause()

                ran.add(command.action)

            # A refresh re-surveys every project, so the session is not over until those land.
            await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )

    return Observed(before=before, after=snapshot(root), ran=ran, offered=offered)
