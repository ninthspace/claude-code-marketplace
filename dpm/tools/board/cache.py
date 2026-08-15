"""The freshness cache: derived answers kept between reads and between sessions (FR13, AD6).

**What is cached is a tool's reply, not a derived view.** Every read the board performs goes through
one call (FR2), so caching there covers the survey, the previews and the CLI's row counts with one
implementation — and what is stored is the JSON the server sent, which cannot disagree with what a
live read would have returned. Caching a `ProjectView` instead would put a second, serialised copy
of the derivation on disk, and a plugin upgrade would make it a wrong one.

**The stamp is the database file's own mtime and size** (AD6, ENVX6). The database is the state; git
is not consulted and need not be present. `cpm/tools/board` stamps on `HEAD` and `docs/` mtimes
because *its* state is files under version control — this one's is not, and a project that is not a
repository has to render like any other.

**The schema version is the third part of the stamp, and it is why a cold board still spawns one
server.** An entry produced under an earlier schema is stale however untouched the file is: the
derivation that produced it may not be the derivation in force. The version arrives in the
`initialize` handshake — the connection is not open when it is answered and no read tool reports it,
so there is nowhere else it could come from — which means the board does not know it until *some*
server has started. An entry is therefore never served against an unknown schema, and the cost is
paid in spawns: the first read of a session goes out, as does every read that started before that
first handshake came back. What it buys is the rest of the session, where a stamped entry is answered
from disk without a call — which is what AD6 is for, and is not something a guessed version could
give safely.

**This file and the registry are the only two things the board writes** (ENVX3), and both live under
the XDG config root. Nothing here ever writes inside a registered project.
"""

from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from registry import CONFIG_DIR, DATABASE, config_home

#: The cache's filename, beside the registry in the XDG config directory.
CACHE_FILE = "cache.json"

#: How long an entry is trusted after it is written, in seconds.
#:
#: **The stamp is what invalidates an entry; this is what bounds the stamp's blind spot.** A write
#: that leaves the database's mtime and size exactly as they were is indistinguishable from no write
#: at all, and the window is the difference between a board that is wrong for a few minutes and one
#: that is wrong until the file changes again. A force-refresh is the other half of that answer, and
#: is the one a user reaches for when they know they have just written something.
WINDOW = 300.0

#: What :meth:`Cache.get` returns when it has nothing — a sentinel rather than ``None``, because a
#: tool answering with ``null`` is a cached value like any other and would otherwise be a miss
#: forever.
MISS = object()


@dataclass(frozen=True)
class Stamp:
    """What a cached answer was true of: the database as it stood, under a known schema."""

    mtime: int
    size: int
    schema: int

    def as_json(self) -> list[int]:
        return [self.mtime, self.size, self.schema]

    @classmethod
    def from_json(cls, record: Any) -> "Stamp | None":
        """A stamp read back from the file, or ``None`` for anything this version cannot read."""
        if isinstance(record, list) and len(record) == 3 and all(
            isinstance(part, int) for part in record
        ):
            return cls(*record)

        return None


def stamp_of(root: Path, schema: int | None) -> Stamp | None:
    """The stamp a project has right now, or ``None`` when it cannot have one.

    ``None`` on two conditions, and both are the same answer to the caller: there is nothing to
    compare against. A project with no database has no state to stamp, and an unknown schema means
    the board has not yet been told which derivation is in force — see the module docstring for why
    that is a miss rather than a guess.

    The database file is *stat*-ed and never opened, which is what keeps this inside FR2's must-NOT:
    the board reads no file under a project's ``.dpm/``, and AD6 names these two attributes as the
    stamp precisely because they are readable without doing so.
    """
    if schema is None:
        return None

    try:
        stat = (root / DATABASE).stat()
    except OSError:
        return None

    return Stamp(mtime=stat.st_mtime_ns, size=stat.st_size, schema=schema)


def cache_path() -> Path:
    """Where the cache lives. Never created as a side effect of asking for it."""
    return config_home() / CONFIG_DIR / CACHE_FILE


def entry_key(root: Path, tool: str, arguments: dict | None) -> str:
    """One key per (project, call, arguments).

    The arguments are part of it because they change the answer: ``list_task`` for one story and
    ``list_task`` for another are different reads, and a key that ignored them would serve the
    first story's tasks under the second's preview. Serialised with sorted keys so that two calls
    that differ only in the order a dict was built land on one entry rather than two.
    """
    return json.dumps([str(root), tool, arguments or {}], sort_keys=True)


class Cache:
    """Answers kept by (project, call), valid while the project's stamp is unchanged.

    Held in memory for the session and written once, by :meth:`save`. A flush per read would
    rewrite the whole file on every one of the seven calls each project makes at startup, which is
    a write amplified by the registry's length for a file nobody reads until the next session.
    """

    def __init__(
        self,
        path: Path | None = None,
        *,
        window: float = WINDOW,
        clock=time.time,
        enabled: bool = True,
    ) -> None:
        self.path = path if path is not None else cache_path()
        self.window = window
        self.enabled = enabled
        self._clock = clock
        self._entries: dict[str, dict] = self._load()
        self._dirty = False

    def _load(self) -> dict[str, dict]:
        """Read the file, treating anything unreadable as an empty cache.

        **A damaged cache is not an error.** It holds nothing that cannot be recomputed by asking
        the servers again, so a board that refused to start over a truncated JSON file would be
        failing over the one thing it is safe to throw away.
        """
        try:
            loaded = json.loads(self.path.read_text() or "{}")
        except (OSError, ValueError):
            return {}

        return loaded if isinstance(loaded, dict) else {}

    def get(self, root: Path, tool: str, arguments: dict | None, stamp: Stamp | None) -> Any:
        """The cached answer for one call, or :data:`MISS`.

        Three things have to hold: the project has a stamp at all, the entry was written against
        that same stamp, and it was written recently enough. The stamp is checked first because it
        is the one that carries the meaning — the window only bounds what the stamp cannot see.
        """
        if not self.enabled or stamp is None:
            return MISS

        entry = self._entries.get(entry_key(root, tool, arguments))

        if entry is None or Stamp.from_json(entry.get("stamp")) != stamp:
            return MISS

        written = entry.get("written")

        if not isinstance(written, (int, float)) or self._clock() - written > self.window:
            return MISS

        return entry.get("value")

    def put(
        self, root: Path, tool: str, arguments: dict | None, stamp: Stamp | None, value: Any
    ) -> None:
        """Record one answer against the stamp it was true of. A project with no stamp is skipped."""
        if not self.enabled or stamp is None:
            return

        self._entries[entry_key(root, tool, arguments)] = {
            "stamp": stamp.as_json(),
            "written": self._clock(),
            "value": value,
        }
        self._dirty = True

    def clear(self) -> None:
        """Forget everything, in memory and on disk (FR13).

        The file is removed rather than rewritten as an empty object: a user clearing the cache is
        usually establishing that it is not the cause of what they are looking at, and a file that
        is still there invites the next reader to wonder whether it was.
        """
        self._entries = {}
        self._dirty = False
        self.path.unlink(missing_ok=True)

    def save(self) -> None:
        """Write the cache out, atomically, if anything changed.

        The same rename dance the registry uses and for a weaker reason: a truncated cache is
        recoverable by definition. It is here anyway because the failure it prevents — a half-written
        file that parses as a *shorter* one — is silent, and because the two files sitting side by
        side should not have two different durability stories.
        """
        if not self.enabled or not self._dirty:
            return

        self.path.parent.mkdir(parents=True, exist_ok=True)
        staged = self.path.with_name(f"{self.path.name}.tmp")

        try:
            staged.write_text(json.dumps(self._entries) + "\n")
            os.replace(staged, self.path)
        except OSError:
            staged.unlink(missing_ok=True)
            raise

        self._dirty = False
