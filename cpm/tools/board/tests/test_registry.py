"""Unit tests for the opt-in project registry (Story 1).

Every test writes to an explicit temp registry file (never the real
``~/.config``), so the suite is hermetic and order-independent.
"""

from __future__ import annotations

import json

import pytest

import registry
from registry import (
    RegistryEntry,
    add_project,
    list_projects,
    load_registry,
    registry_path,
    remove_project,
    run_cli,
)


@pytest.fixture
def registry_file(tmp_path):
    return tmp_path / "cpm-board" / "registry.json"


# --- persistence round-trip --------------------------------------------------


def test_add_persists_as_path_label_records(registry_file, tmp_path):
    project = tmp_path / "proj"
    project.mkdir()
    add_project(str(project), label="My Project", registry_file=registry_file)

    on_disk = json.loads(registry_file.read_text())
    assert on_disk == [{"path": str(project), "label": "My Project"}]


def test_add_without_label_omits_the_label_key(registry_file, tmp_path):
    project = tmp_path / "proj"
    project.mkdir()
    add_project(str(project), registry_file=registry_file)

    on_disk = json.loads(registry_file.read_text())
    assert on_disk == [{"path": str(project)}]


def test_list_reads_back_what_add_wrote(registry_file, tmp_path):
    a, b = tmp_path / "a", tmp_path / "b"
    a.mkdir()
    b.mkdir()
    add_project(str(a), registry_file=registry_file)
    add_project(str(b), label="B", registry_file=registry_file)

    entries = list_projects(registry_file=registry_file)
    assert [(e.path, e.label) for e in entries] == [(str(a), None), (str(b), "B")]


def test_remove_deletes_only_the_named_project(registry_file, tmp_path):
    a, b = tmp_path / "a", tmp_path / "b"
    a.mkdir()
    b.mkdir()
    add_project(str(a), registry_file=registry_file)
    add_project(str(b), registry_file=registry_file)

    remove_project(str(a), registry_file=registry_file)

    remaining = [e.path for e in list_projects(registry_file=registry_file)]
    assert remaining == [str(b)]


def test_re_adding_a_path_updates_its_label_without_duplicating(registry_file, tmp_path):
    project = tmp_path / "proj"
    project.mkdir()
    add_project(str(project), label="Old", registry_file=registry_file)
    add_project(str(project), label="New", registry_file=registry_file)

    entries = list_projects(registry_file=registry_file)
    assert len(entries) == 1
    assert entries[0].label == "New"


def test_load_of_absent_file_is_empty(registry_file):
    assert load_registry(registry_file) == []


# --- accept-but-flag (not rejected at add time) ------------------------------


def test_adding_a_nonexistent_path_is_permitted(registry_file, tmp_path):
    missing = tmp_path / "not-here"  # never created
    add_project(str(missing), registry_file=registry_file)

    entries = list_projects(registry_file=registry_file)
    assert [e.path for e in entries] == [str(missing)]  # persisted, not rejected


def test_missing_path_is_flagged_only_at_render_via_exists(tmp_path):
    present = tmp_path / "present"
    present.mkdir()
    assert RegistryEntry(str(present)).exists() is True
    assert RegistryEntry(str(tmp_path / "absent")).exists() is False


# --- launch-time prune -------------------------------------------------------


def test_prune_removes_missing_and_keeps_existing(registry_file, tmp_path):
    live = tmp_path / "live"
    live.mkdir()
    add_project(str(live), registry_file=registry_file)
    add_project(str(tmp_path / "gone"), registry_file=registry_file)  # never created

    survivors = registry.prune_missing(registry_file)

    assert [e.path for e in survivors] == [str(live)]
    assert [e.path for e in load_registry(registry_file)] == [str(live)]  # dead entry gone from disk too


def test_prune_preserves_survivor_labels(registry_file, tmp_path):
    live = tmp_path / "keep"
    live.mkdir()
    add_project(str(live), label="Keep", registry_file=registry_file)
    add_project(str(tmp_path / "missing"), registry_file=registry_file)

    (survivor,) = registry.prune_missing(registry_file)
    assert survivor.path == str(live)
    assert survivor.label == "Keep"


def test_prune_does_not_rewrite_when_all_exist(registry_file, tmp_path, monkeypatch):
    a, b = tmp_path / "a", tmp_path / "b"
    a.mkdir()
    b.mkdir()
    add_project(str(a), registry_file=registry_file)
    add_project(str(b), registry_file=registry_file)

    saved: list[object] = []
    monkeypatch.setattr(registry, "save_registry", lambda *a, **k: saved.append(1))
    survivors = registry.prune_missing(registry_file)

    assert len(survivors) == 2
    assert saved == []  # no churn — the file is untouched when nothing is missing


def test_prune_of_empty_registry_stays_empty_and_writes_nothing(registry_file):
    assert registry.prune_missing(registry_file) == []
    assert not registry_file.exists()  # never created as a side effect


# --- XDG path resolution -----------------------------------------------------


def test_registry_path_honours_xdg_config_home(monkeypatch, tmp_path):
    monkeypatch.setenv("XDG_CONFIG_HOME", str(tmp_path / "xdg"))
    assert registry_path() == tmp_path / "xdg" / "cpm-board" / "registry.json"


def test_registry_path_falls_back_to_home_config(monkeypatch, tmp_path):
    monkeypatch.delenv("XDG_CONFIG_HOME", raising=False)
    monkeypatch.setattr(registry.Path, "home", classmethod(lambda cls: tmp_path))
    assert registry_path() == tmp_path / ".config" / "cpm-board" / "registry.json"


# --- CLI surface -------------------------------------------------------------


def test_cli_add_then_list_prints_the_project(registry_file, tmp_path, capsys):
    project = tmp_path / "proj"
    project.mkdir()
    assert run_cli(["add", str(project), "--label", "Proj"], registry_file=registry_file) == 0

    run_cli(["list"], registry_file=registry_file)
    out = capsys.readouterr().out
    assert str(project) in out
    assert "Proj" in out
    assert "(missing)" not in out


def test_cli_list_flags_a_missing_project(registry_file, tmp_path, capsys):
    missing = tmp_path / "gone"
    run_cli(["add", str(missing)], registry_file=registry_file)

    run_cli(["list"], registry_file=registry_file)
    out = capsys.readouterr().out
    assert "(missing)" in out
