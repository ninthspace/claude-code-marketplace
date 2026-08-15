"""Story 1 — the freshness cache: what it serves, what invalidates it, and where it lives (FR13).

**Every claim about "served from cache" here is a claim about calls that did not happen**, read off
the stand-in's transcript rather than off the cache's own account of itself. A cache asked whether it
had a hit is a cache grading itself, and the property FR13 is actually about — a cold board that does
not re-query everything — is one about the wire.

The two ends are both real. The stand-in is what makes the calls countable; the real
``bin/dpm-mcp.js`` is what makes the schema version in the handshake a fact rather than a fixture,
which is the one part of the stamp the board cannot compute for itself.
"""

from __future__ import annotations

import sys
from pathlib import Path

from conftest import STAND_IN, files_under
from pilot import board, palette, until
from recording_server import transcript_of
from session import run as full_session

from board import registry_views, survey_project
from cache import MISS, WINDOW, Cache, Stamp, cache_path, stamp_of
from mcp_client import ServerPool
from registry import CONFIG_DIR, DATABASE, RegistryEntry

#: The schema the stand-in reports, and one after it. Two versions is the whole of what the
#: schema-stamp criterion needs; which numbers they are is immaterial as long as they differ.
SCHEMA = 1
LATER = 2

#: How long a survey is given to land before a test reads what it painted.
SETTLE = 30.0


def calls(transcript: Path) -> list[str]:
    """Every tool the servers were actually asked for, in order — the outside witness."""
    if not transcript.exists():
        return []

    return [
        message["params"]["name"]
        for message in transcript_of(transcript)
        if message.get("method") == "tools/call"
    ]


def stand_in_pool(cache: Cache | None) -> ServerPool:
    """A pool over the recording stand-in, carrying ``cache``.

    Which schema its servers report is the caller's, set in the environment before the pool is built:
    FR13 puts the version on the server, and a pool with a setter for it would be a path the board
    never takes.
    """
    return ServerPool(STAND_IN, node=sys.executable, cache=cache)


class Recording(Cache):
    """A real cache that counts what it was asked to store.

    Subclassed rather than mocked because the must-NOT is about what a *working* cache writes and
    where: a stand-in that recorded the calls and wrote nothing would pass the tree comparison by
    never having been a cache.
    """

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self.stored = 0

    def put(self, *args, **kwargs) -> None:
        super().put(*args, **kwargs)
        self.stored += 1


async def test_a_second_read_inside_the_window_is_served_from_cache(
    tmp_path, project, transcript, monkeypatch
):
    """Criterion 1 [unit]. Twice for the same answer, once on the wire.

    And then the other half: a database whose mtime and size have moved is a different state, so the
    entry stops being an answer about it and the read goes out again. Both are counted from the
    transcript, which is what the stand-in is for.
    """
    monkeypatch.setenv("RECORDING_SCHEMA", str(SCHEMA))
    root = project()
    pool = stand_in_pool(Cache(tmp_path / "cache.json"))

    try:
        first = await pool.read(root, "list_epic")
        second = await pool.read(root, "list_epic")

        assert second == first, "the cached answer is not the one the server gave"
        assert calls(transcript) == ["list_epic"], "the second read went out on the wire"

        # A write the board did not make and cannot see coming. Both halves of AD6's stamp move:
        # the file is longer and its mtime is later.
        (root / DATABASE).write_bytes(b"written since")

        await pool.read(root, "list_epic")

        assert calls(transcript) == ["list_epic", "list_epic"], (
            "a touched database was still answered from the cache"
        )
    finally:
        await pool.close()


def test_an_entry_stops_being_served_once_the_window_has_passed(tmp_path, project):
    """Criterion 1 [unit], the *within* in "within the freshness window".

    The clock is injected rather than waited on, and the stamp is deliberately identical throughout:
    what expires the entry here is time alone, which is the only part of :data:`WINDOW`'s job. Its
    reason for existing is the write the stamp cannot see, so an entry that outlived its window
    against an unchanged file is the board being wrong until the file changes again.
    """
    root = project()
    minutes = iter([0.0, 100.0, WINDOW + 100.0])
    cache = Cache(tmp_path / "cache.json", clock=lambda: next(minutes))
    stamp = stamp_of(root, SCHEMA)

    cache.put(root, "list_epic", None, stamp, {"items": []})

    assert cache.get(root, "list_epic", None, stamp) is not MISS, "inside the window and not served"
    assert cache.get(root, "list_epic", None, stamp) is MISS, "outside the window and still served"


def test_the_stamp_is_the_databases_own_mtime_and_size(tmp_path, project):
    """Criterion 2 [unit], first half. The stamp's parts, compared against what the OS says.

    Derived from ``os.stat`` here rather than transcribed, so a stamp that quietly started using
    something else — a hash of the file, the directory's mtime — fails rather than agreeing with a
    number this test wrote down.
    """
    root = project()
    stat = (root / DATABASE).stat()

    assert stamp_of(root, SCHEMA) == Stamp(mtime=stat.st_mtime_ns, size=stat.st_size, schema=SCHEMA)

    # ENVX6, as the thing it forbids: no repository anywhere above the project, and a stamp all the
    # same. A git-derived stamp is the natural thing to reach for and CPM's board does exactly that.
    assert not any((parent / ".git").exists() for parent in (root, *root.parents))
    assert stamp_of(root, SCHEMA) is not None

    # And nothing at all where there is no database to have a state, or no schema to have read it
    # under — the two conditions that make an entry unservable rather than servable against a guess.
    assert stamp_of(tmp_path / "nowhere", SCHEMA) is None
    assert stamp_of(root, None) is None


def test_an_entry_written_under_an_earlier_schema_is_not_served(tmp_path, project):
    """Criterion 2 [unit], second half. The file has not changed; the derivation has.

    Asserted over an untouched database on purpose. mtime and size are identical either side of the
    upgrade — that is precisely the case they cannot see — so an entry that survived here is one a
    plugin upgrade would serve from the schema before it.
    """
    root = project()
    cache = Cache(tmp_path / "cache.json")
    before, after = stamp_of(root, SCHEMA), stamp_of(root, LATER)

    cache.put(root, "list_epic", None, before, {"items": ["written under the old schema"]})

    assert (before.mtime, before.size) == (after.mtime, after.size), (
        "the two stamps differ by more than the schema, so this proves nothing about the schema"
    )
    assert cache.get(root, "list_epic", None, before) is not MISS
    assert cache.get(root, "list_epic", None, after) is MISS


async def session(root: Path, path: Path, schema: int, monkeypatch) -> None:
    """One board session over the cache at ``path``, against a server reporting ``schema``.

    Two reads, and the first is a warm-up rather than part of the claim: the cache is consulted
    before the server is spawned, so the schema is unknown for the very first read of any session and
    that read always goes out. It is the *second* read that can be served, which is what the test
    below is about.
    """
    monkeypatch.setenv("RECORDING_SCHEMA", str(schema))
    pool = stand_in_pool(Cache(path))

    try:
        await pool.read(root, "list_story")
        await pool.read(root, "list_epic")
    finally:
        await pool.close()


async def test_a_pool_on_a_newer_schema_does_not_serve_the_old_ones_entries(
    tmp_path, project, transcript, monkeypatch
):
    """Criterion 2 [unit], as behaviour: the same cache file, three sessions, one upgrade.

    The pair above establishes what the stamp holds and what :class:`Cache` does with it. This is the
    upgrade itself — the entries persist on disk, the server the board spawns reports a different
    schema, and the answer comes off the wire again.

    **The middle session is the control and the test is worthless without it.** A second session on
    the *same* schema is served from the file; that is what makes the third session's call evidence
    about the schema rather than about a cache that never persisted anything.
    """
    root = project()
    path = tmp_path / "cache.json"

    await session(root, path, SCHEMA, monkeypatch)

    assert path.exists(), "the cache was never written, so the sessions below read nothing"
    assert calls(transcript) == ["list_story", "list_epic"]

    await session(root, path, SCHEMA, monkeypatch)

    assert calls(transcript) == ["list_story", "list_epic", "list_story"], (
        "the same schema's own entry was not served back to it"
    )

    await session(root, path, LATER, monkeypatch)

    assert calls(transcript) == ["list_story", "list_epic", "list_story", "list_story", "list_epic"], (
        "the upgraded board was answered out of the previous schema's cache"
    )


async def test_a_force_refresh_bypasses_the_cache_and_a_clear_removes_it(
    tmp_path, project, transcript, monkeypatch
):
    """Criterion 3 [feature]. Both actions, driven from the board the way a user reaches them.

    **Three presses, and the middle one is what gives the first and last their meaning.** An
    ordinary refresh that produced no calls is the cache doing its job; the force-refresh that
    follows produces a full set from the same board a moment later, which is the bypass. Without the
    ordinary refresh in between, a force-refresh's calls would be indistinguishable from a board that
    never cached anything.
    """
    monkeypatch.setenv("RECORDING_SCHEMA", str(SCHEMA))
    root = project()
    path = tmp_path / "cache.json"
    cache = Cache(path)
    pool = stand_in_pool(cache)
    entries = [RegistryEntry(str(root))]

    def reload() -> list:
        return registry_views(entries)

    try:
        async with board(
            reload(),
            survey=lambda view, *, fresh=False: survey_project(pool, view, fresh=fresh),
            reload=reload,
            clear_cache=cache.clear,
        ) as (app, pilot):
            await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )

            surveyed = calls(transcript)

            assert surveyed, "the board read nothing at all, so there is no cache to bypass"

            # Reachable from the palette as well as from a key (FR13, FR18) — read from what the
            # palette painted, not from the table it was built from.
            await pilot.press("ctrl+p")
            await pilot.pause()
            offered = palette(app)
            await pilot.press("escape")
            await pilot.pause()

            assert "Force refresh" in offered
            assert "Clear the cache" in offered

            await app.run_action("refresh")
            await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )

            assert calls(transcript) == surveyed, "an ordinary refresh went back to the servers"

            await pilot.press("R")
            await until(
                pilot,
                lambda: not any(row.pending for row in app.selection.projects),
                timeout=SETTLE,
            )

            assert calls(transcript) == surveyed * 2, (
                "the force-refresh did not re-read every project's every call"
            )

            cache.save()

            assert path.exists(), "nothing was written, so the clear below removes nothing"

            await pilot.press("ctrl+k")
            await pilot.pause()

            assert not path.exists(), "the cleared cache is still on disk"
            assert cache.get(root, "list_epic", None, stamp_of(root, SCHEMA)) is MISS
    finally:
        await pool.close()


async def test_a_project_that_is_not_a_git_repository_renders_normally(tmp_path, fixture_project):
    """Criterion 4 [integration]. ENVX6, over the real server and a real database.

    The comparison is against the *same* project read by a pool with no cache at all, so what is
    asserted is that the two agree rather than that the cached one looks plausible. A cache keyed on
    something git-derived would have nothing to key on here, and the board that reads through it
    would render a project it could not stamp.
    """
    assert not any((parent / ".git").exists() for parent in (fixture_project, *fixture_project.parents)), (
        "the fixture sits inside a repository, so this test says nothing about a project outside one"
    )

    row = registry_views([RegistryEntry(str(fixture_project))])[0]
    cache = Cache(tmp_path / "cache.json")

    async with ServerPool(cache=cache) as cached:
        first = await survey_project(cached, row)
        second = await survey_project(cached, row)

        # The handshake is the only place the version could have come from, so a pool that learned
        # one is the end-to-end proof that dpm reports it.
        assert cached.schema is not None, "the real server's handshake carried no schema version"

    async with ServerPool() as direct:
        uncached = await survey_project(direct, row)

    assert first.unreadable is None, f"the project would not read at all: {first.unreadable}"
    assert first.epics, "the fixture rendered no epics, so the comparison below is empty"
    assert (first, second) == (uncached, uncached)


async def test_the_cache_lands_beside_the_registry_and_nowhere_in_a_project(
    fixture_project, sandbox, monkeypatch
):
    """The must-NOT [unit]. A full session that definitely wrote an entry, over an untouched tree.

    **The counted writes are what makes the unchanged tree mean something.** 48-06 hashes the same
    tree across the same session and its cache is a cache that was never there; a board with one
    could put a file in `.dpm/` and pass that test unaltered. Here the session is given a real cache,
    the stores are counted, and the tree is compared with mtime and size as well as content — because
    a rewrite that reproduced the bytes is exactly what re-caching a projection would look like.
    """
    for name, value in sandbox.env().items():
        monkeypatch.setenv(name, value)

    root = fixture_project
    cache = Recording(cache_path())
    observed = await full_session(root, cache=cache)

    assert cache.stored, "the session cached nothing, so it is not the session this asserts about"
    assert observed.before == observed.after, "a board session changed the project it was reading"

    # Named directly as well as compared, because a tree comparison only sees what survived the
    # session — and the session runs the clear, which would take a misplaced cache away with it. The
    # path the cache is *still pointing at* after a full run is the durable form of the claim.
    assert not any("cache" in name for name in files_under(root))
    assert cache.path == sandbox.config / CONFIG_DIR / "cache.json" == cache_path()
    assert root not in cache.path.parents
