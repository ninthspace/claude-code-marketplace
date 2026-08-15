"""Opt-in project registry for the dpm board (FR1).

The board never discovers projects on its own — the user opts each one in, and this module is where
that choice is kept: ``$XDG_CONFIG_HOME/dpm-board/registry.json``, or ``~/.config/dpm-board/…`` when
the variable is unset, as a list of ``{ path, label? }`` records.

**A sibling of ``cpm/tools/board/registry.py``, sharing no code with it** (AD3). The shape transfers
and the behaviour does not: a dpm project is identified by ``.dpm/dpm.db`` rather than by ``docs/``,
so ``add`` validates where the cpm board accepts anything, and the two registries are separate files
under separate directories because a project is a CPM project or a dpm project and never both.

**The write is atomic, which the cpm board's is not.** This file and the status cache are the only
two things the board writes anywhere (ENVX3 forbids the rest), and a registry truncated by an
interrupted write is a board that has forgotten every project the user ever registered — on a path
nobody is watching, with no error at the time it happened. A temporary file in the same directory
followed by ``os.replace`` costs nothing and removes the failure mode.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path

#: The directory the registry lives in, under the XDG config root.
CONFIG_DIR = "dpm-board"

#: The registry's filename inside that directory.
REGISTRY_FILE = "registry.json"

#: What makes a directory a dpm project, relative to its root.
DATABASE = Path(".dpm") / "dpm.db"


@dataclass(frozen=True)
class RegistryEntry:
    """One opt-in project: an absolute path and an optional display label."""

    path: str
    label: str | None = None

    def exists(self) -> bool:
        """Whether the registered path resolves to a directory — the render-time flag."""
        return Path(self.path).expanduser().is_dir()

    def to_json(self) -> dict[str, str]:
        record: dict[str, str] = {"path": self.path}
        if self.label is not None:
            record["label"] = self.label
        return record

    @classmethod
    def from_json(cls, record: dict) -> RegistryEntry:
        return cls(path=record["path"], label=record.get("label"))


def config_home() -> Path:
    """The XDG config root: ``$XDG_CONFIG_HOME`` when set to an absolute path, else ``~/.config``.

    The specification requires the variable to hold an absolute path and says a relative one is to
    be ignored, so a stray relative value falls back to the default rather than resolving against
    whatever directory the board happened to be started in — which is a path outside the config
    location, and the one thing FR1's must-NOT forbids.
    """
    value = os.environ.get("XDG_CONFIG_HOME")

    if value and os.path.isabs(value):
        return Path(value)

    return Path.home() / ".config"


def registry_path() -> Path:
    """The path to the registry file. Never created as a side effect of asking for it."""
    return config_home() / CONFIG_DIR / REGISTRY_FILE


def _normalise(path: str) -> str:
    """Absolute, ``~``-expanded key for a path — without touching the filesystem."""
    return os.path.abspath(os.path.expanduser(path))


def missing_marker(path: str) -> str | None:
    """What stops ``path`` being a dpm project, named, or ``None`` if nothing does.

    Returns the *thing that was missing* rather than a boolean, because the caller's job is to say
    so: the usual cause of a refused ``add`` is a directory that is plainly a project of some kind —
    a git repository, a checkout with a ``docs/`` tree — and "not a dpm project" leaves the user to
    guess which of the two it failed on.
    """
    root = Path(_normalise(path))

    if not root.is_dir():
        return str(root)

    database = root / DATABASE

    return None if database.is_file() else str(database)


def load_registry(registry_file: Path | None = None) -> list[RegistryEntry]:
    """Read the registry, returning ``[]`` when the file is absent or empty."""
    file = registry_file or registry_path()

    if not file.is_file():
        return []

    return [RegistryEntry.from_json(record) for record in json.loads(file.read_text() or "[]")]


def save_registry(entries: list[RegistryEntry], registry_file: Path | None = None) -> None:
    """Persist the registry atomically, creating the parent directory on first write.

    The temporary file is created *beside* the registry rather than in the system temp directory:
    ``os.replace`` is only atomic within a filesystem, and it is also the only way this function can
    honour FR1's must-NOT, which forbids writing anywhere outside the XDG config location — a
    scratch file under ``/tmp`` would be a write outside it however briefly it existed.
    """
    file = registry_file or registry_path()
    file.parent.mkdir(parents=True, exist_ok=True)

    staged = file.with_name(f"{file.name}.tmp")

    try:
        staged.write_text(json.dumps([entry.to_json() for entry in entries], indent=2) + "\n")
        os.replace(staged, file)
    except OSError:
        # The staging file exists for the length of one rename and must not outlive a failure. Left
        # behind it is a half-written registry sitting beside the real one, in the directory FR1's
        # must-NOT is about, with a name that invites the next reader to wonder which is current.
        staged.unlink(missing_ok=True)
        raise


def add_project(
    path: str, label: str | None = None, *, registry_file: Path | None = None
) -> list[RegistryEntry]:
    """Register ``path``. Re-adding a path updates its label rather than duplicating the entry."""
    key = _normalise(path)
    entries = [entry for entry in load_registry(registry_file) if _normalise(entry.path) != key]
    entries.append(RegistryEntry(path=key, label=label))
    save_registry(entries, registry_file)

    return entries


def remove_project(path: str, *, registry_file: Path | None = None) -> list[RegistryEntry]:
    """Unregister ``path``. Removing an absent path is a no-op, not an error."""
    key = _normalise(path)
    entries = [entry for entry in load_registry(registry_file) if _normalise(entry.path) != key]
    save_registry(entries, registry_file)

    return entries


def prune_missing(registry_file: Path | None = None) -> list[RegistryEntry]:
    """Drop every registered path that is no longer a directory, returning the survivors (FR1).

    Run once at launch. A project deleted, renamed or on an unmounted drive since it was registered
    is unregistered rather than lingering as a row the board can say nothing about.

    **What it forgets is the registry entry, and nothing else.** ENVX3 forbids the board writing into
    any registered project, and that holds for the project being dropped too — pruning touches the one
    file in the XDG config directory and never reaches the tree it is forgetting.

    The registry is rewritten **only if** something was actually removed, so the ordinary
    all-present launch causes no write at all. That is worth the branch: the alternative rewrites the
    board's only durable state on every start, which is a great many more chances for the interrupted
    write ``save_registry`` was made atomic to survive.
    """
    entries = load_registry(registry_file)
    survivors = [entry for entry in entries if entry.exists()]

    if len(survivors) != len(entries):
        save_registry(survivors, registry_file)

    return survivors


def list_projects(*, registry_file: Path | None = None) -> list[RegistryEntry]:
    """Return the registered projects in registration order."""
    return load_registry(registry_file)
