"""Shared test fixtures for the cpm board.

The `make_project` factory materialises a temporary git repository with a
caller-specified `docs/` tree and commit state. It is the deterministic backbone
for status-derivation tests (epic 39-02) — each test declares exactly the
artifacts and git state it needs.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Callable, Mapping

import pytest


def _git(repo: Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True)


def build_project(root: Path, files: Mapping[str, str], *, commit: bool = True) -> Path:
    """Write `files` (relative path -> contents) under `root`, optionally as a git repo.

    When `commit` is True, initialises a git repo and commits everything, so
    `git rev-parse HEAD` resolves — the freshness stamp derivation depends on it.
    """
    for rel, content in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    if commit:
        _git(root, "init", "-q")
        _git(root, "config", "user.email", "test@example.com")
        _git(root, "config", "user.name", "cpm-board tests")
        _git(root, "add", "-A")
        _git(root, "commit", "-q", "-m", "fixture")

    return root


@pytest.fixture
def make_project(tmp_path: Path) -> Callable[..., Path]:
    """Factory fixture returning a fresh project repo per call.

    Usage:
        repo = make_project({"docs/epics/01-01-epic-foo.md": "**Status**: Pending"})
    """
    counter = {"n": 0}

    def _make(files: Mapping[str, str], *, commit: bool = True, name: str | None = None) -> Path:
        counter["n"] += 1
        root = tmp_path / (name or f"project{counter['n']}")
        root.mkdir()
        return build_project(root, files, commit=commit)

    return _make
