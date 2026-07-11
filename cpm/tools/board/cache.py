"""Freshness-by-construction cache for the cpm board.

Each project's derived status is cached under XDG (``$XDG_CACHE_HOME/cpm-board/``,
default ``~/.cache/cpm-board/``), keyed by the project's absolute path. The cache
is a pure read-through: a project is re-derived only when its **freshness stamp**
changes, where the stamp is ``git HEAD`` combined with the maximum mtime under
``docs/``. An unchanged project is painted from cache.

The cache lives in a single central location — never inside a tracked repo — so
the board never dirties a project's working tree. Derivation itself is read-only
(see ``status_model``); this layer only reads git/mtime and reads/writes the
central cache.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
from pathlib import Path

from status_model import (
    Epic,
    NextAction,
    ProjectStatus,
    State,
    Story,
    derive_project,
    read_head,
)


def cache_dir() -> Path:
    """The XDG-aware cache directory (never created as a side effect of resolving)."""
    cache_home = os.environ.get("XDG_CACHE_HOME")
    base = Path(cache_home) if cache_home else Path.home() / ".cache"
    return base / "cpm-board"


def freshness_stamp(path: Path | str) -> str:
    """Derive the per-project freshness stamp: ``git HEAD`` + max ``docs/`` mtime.

    Read-only. A missing HEAD (not a git repo) and an absent ``docs/`` both resolve
    to stable sentinels, so an unreachable project still yields a deterministic
    stamp rather than raising.
    """
    root = Path(path)
    head = read_head(root) or "nohead"

    latest_mtime = 0
    docs = root / "docs"
    if docs.is_dir():
        for entry in docs.rglob("*"):
            try:
                latest_mtime = max(latest_mtime, entry.stat().st_mtime_ns)
            except OSError:
                continue
    return f"{head}:{latest_mtime}"


def _cache_file(root: Path, cache_root: Path | None = None) -> Path:
    """Central cache file for a project, keyed by a hash of its absolute path."""
    base = cache_root or cache_dir()
    key = hashlib.sha256(str(root.resolve()).encode()).hexdigest()[:16]
    return base / f"{key}.json"


def clear_cache(*, cache_root: Path | None = None) -> Path:
    """Delete the whole cache directory (a no-op if it doesn't exist). Returns the
    path so callers can report it. Every project re-derives on next read."""
    base = cache_root or cache_dir()
    if base.is_dir():
        shutil.rmtree(base)
    return base


def _epic_to_dict(epic: Epic) -> dict:
    return {
        "path": str(epic.path),
        "parent": epic.parent,
        "status": epic.status,
        "blocked_by": epic.blocked_by,
        "title": epic.title,
        "stories": [
            {
                "number": story.number,
                "status": story.status,
                "blocked_by": story.blocked_by,
                "title": story.title,
            }
            for story in epic.stories
        ],
    }


def _epic_from_dict(data: dict) -> Epic:
    # `Story(**story)` and `title=data.get(...)` tolerate pre-title cache files:
    # the missing key falls back to the dataclass default, so a stale cache just
    # re-derives on the next freshness-stamp change rather than KeyError-ing.
    return Epic(
        path=Path(data["path"]),
        parent=data["parent"],
        status=data["status"],
        blocked_by=data["blocked_by"],
        title=data.get("title", ""),
        stories=[Story(**story) for story in data["stories"]],
    )


def _status_to_dict(status: ProjectStatus) -> dict:
    return {
        "path": str(status.path),
        "state": status.state.value,
        "complete_stories": status.complete_stories,
        "total_stories": status.total_stories,
        "label": status.label,
        "next_actions": [
            {
                "kind": action.kind,
                "command": action.command,
                "target_path": action.target_path,
                "label": action.label,
            }
            for action in status.next_actions
        ],
        "epics": [_epic_to_dict(epic) for epic in status.epics],
    }


def _status_from_dict(data: dict) -> ProjectStatus:
    return ProjectStatus(
        path=Path(data["path"]),
        state=State(data["state"]),
        complete_stories=data["complete_stories"],
        total_stories=data["total_stories"],
        next_actions=[NextAction(**action) for action in data["next_actions"]],
        epics=[_epic_from_dict(epic) for epic in data.get("epics", [])],
        label=data["label"],
    )


# Bumped whenever the cached shape changes (e.g. epic/story titles added). A
# cache file written by an older schema is ignored — not merely stamp-checked —
# so new fields appear immediately instead of after the next freshness change.
_SCHEMA = 2


def _write_cache(file: Path, stamp: str, status: ProjectStatus) -> None:
    file.parent.mkdir(parents=True, exist_ok=True)
    payload = {"schema": _SCHEMA, "stamp": stamp, "status": _status_to_dict(status)}
    file.write_text(json.dumps(payload, indent=2) + "\n")


def derive_project_cached(
    path: Path | str, *, cache_root: Path | None = None, force: bool = False
) -> ProjectStatus:
    """Return a project's status, serving cache when its freshness stamp is unchanged.

    Re-derives (and rewrites the cache) when the stamp differs, when no cache
    entry exists, or when ``force`` is set — the force path is what the TUI's
    manual refresh uses to bypass the cache entirely.
    """
    root = Path(path)
    stamp = freshness_stamp(root)
    file = _cache_file(root, cache_root)

    if not force and file.is_file():
        try:
            payload = json.loads(file.read_text())
            if payload.get("schema") == _SCHEMA and payload.get("stamp") == stamp:
                return _status_from_dict(payload["status"])
        except (json.JSONDecodeError, KeyError, OSError):
            pass  # corrupt / stale cache entry — fall through and re-derive

    status = derive_project(root)
    _write_cache(file, stamp, status)
    return status
