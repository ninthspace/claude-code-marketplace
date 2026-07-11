"""Opt-in project registry for the cpm board.

The board never discovers projects on its own — the user opts each one in. This
module persists that choice to an XDG-aware config file
(``$XDG_CONFIG_HOME/cpm-board/registry.json``, default
``~/.config/cpm-board/registry.json``) as a list of ``{ path, label? }`` records.

Registering a path never validates that it exists: a missing path is accepted
here and flagged later at render time (via :meth:`RegistryEntry.exists`), so a
project that is temporarily unmounted or renamed is surfaced, not silently
dropped at ``add`` time.

This module deliberately imports nothing from Textual — the registry CLI surface
is usable (and testable) without the TUI.
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from pathlib import Path


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


def registry_path() -> Path:
    """The XDG-aware path to the registry file (never created as a side effect)."""
    config_home = os.environ.get("XDG_CONFIG_HOME")
    base = Path(config_home) if config_home else Path.home() / ".config"
    return base / "cpm-board" / "registry.json"


def _normalise(path: str) -> str:
    """Absolute, ~-expanded key for a path — without touching the filesystem."""
    return os.path.abspath(os.path.expanduser(path))


def load_registry(registry_file: Path | None = None) -> list[RegistryEntry]:
    """Read the registry, returning ``[]`` when the file is absent or empty."""
    file = registry_file or registry_path()
    if not file.is_file():
        return []
    data = json.loads(file.read_text() or "[]")
    return [RegistryEntry.from_json(record) for record in data]


def save_registry(entries: list[RegistryEntry], registry_file: Path | None = None) -> None:
    """Persist the registry, creating the parent directory on first write."""
    file = registry_file or registry_path()
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text(json.dumps([entry.to_json() for entry in entries], indent=2) + "\n")


def add_project(
    path: str, label: str | None = None, *, registry_file: Path | None = None
) -> list[RegistryEntry]:
    """Register ``path`` (existence not required). Re-adding a path updates its label."""
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


def list_projects(*, registry_file: Path | None = None) -> list[RegistryEntry]:
    """Return the registered projects in registration order."""
    return load_registry(registry_file)


def run_cli(argv: list[str], *, registry_file: Path | None = None) -> int:
    """Argparse CLI over the registry: ``add`` / ``remove`` / ``list``."""
    parser = argparse.ArgumentParser(
        prog="cpm-board", description="Manage the cpm board project registry."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    add_parser = sub.add_parser("add", help="Register a project path (existence not required).")
    add_parser.add_argument("path")
    add_parser.add_argument("--label", default=None, help="Optional display label.")

    remove_parser = sub.add_parser("remove", help="Unregister a project path.")
    remove_parser.add_argument("path")

    sub.add_parser("list", help="List registered projects.")

    args = parser.parse_args(argv)

    if args.command == "add":
        add_project(args.path, args.label, registry_file=registry_file)
    elif args.command == "remove":
        remove_project(args.path, registry_file=registry_file)
    elif args.command == "list":
        for entry in list_projects(registry_file=registry_file):
            label = f" — {entry.label}" if entry.label else ""
            flag = "" if entry.exists() else "  (missing)"
            print(f"{entry.path}{label}{flag}")

    return 0
