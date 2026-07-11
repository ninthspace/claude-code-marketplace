"""Tests for the `refresh` subcommand — rebuild / clear the status cache."""

from __future__ import annotations

import json

from board import refresh_cli
from cache import _cache_file, derive_project_cached
from registry import add_project

from test_derivation import epic_md

EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md("Pending", [(1, "Pending", "—")])}


def test_refresh_rebuilds_cache_for_registered_projects(make_project, tmp_path, capsys):
    repo = make_project(EPICS_READY)
    reg = tmp_path / "registry.json"
    cache_root = tmp_path / "cache"
    add_project(str(repo), "Foo", registry_file=reg)

    assert refresh_cli([], registry_file=reg, cache_root=cache_root) == 0

    file = _cache_file(repo, cache_root)
    assert file.is_file()
    assert json.loads(file.read_text())["schema"] == 2  # written with the current schema
    assert "Rebuilt cache for 1 project" in capsys.readouterr().out


def test_refresh_clear_deletes_the_cache(make_project, tmp_path, capsys):
    repo = make_project(EPICS_READY)
    reg = tmp_path / "registry.json"
    cache_root = tmp_path / "cache"
    add_project(str(repo), "Foo", registry_file=reg)
    derive_project_cached(repo, cache_root=cache_root)  # warm it
    assert _cache_file(repo, cache_root).is_file()

    assert refresh_cli(["--clear"], registry_file=reg, cache_root=cache_root) == 0

    assert not _cache_file(repo, cache_root).exists()
    assert "Cleared cache" in capsys.readouterr().out
