"""Story 1 — the opt-in project registry (FR1).

The registry is one of exactly two files this board ever writes, and the only one that holds
anything a user would miss. So the tests here are about two properties rather than one: that the
three operations round-trip, and that the writing they do lands where FR1 says it may and nowhere
else.

**The must-NOT is asserted as an absence in three places, not as a presence in one.** "The registry
appeared under ``$XDG_CONFIG_HOME``" is true of a board that also dropped a copy in the user's home
directory or in whatever directory it was started from, and a static sweep of the module's source
cannot say otherwise — it sees `Path.write_text` and cannot follow where the path came from. What
can is running the operations with all three roots owned by the test and listing each afterwards.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

import pytest

import registry
from conftest import files_under
from registry import (
    add_project,
    list_projects,
    load_registry,
    missing_marker,
    prune_missing,
    registry_path,
    remove_project,
    save_registry,
)


@pytest.fixture
def registry_file(tmp_path: Path) -> Path:
    """An explicit registry path, so no unit test can reach the developer's real one."""
    return tmp_path / "dpm-board" / "registry.json"


# --- criterion 1: add, list and remove round-trip through a file under $XDG_CONFIG_HOME ----------


def test_add_list_and_remove_round_trip(registry_file, project):
    first, second = project("first"), project("second")

    add_project(str(first), label="The first", registry_file=registry_file)
    add_project(str(second), registry_file=registry_file)

    listed = list_projects(registry_file=registry_file)

    assert [entry.path for entry in listed] == [str(first), str(second)]
    assert [entry.label for entry in listed] == ["The first", None]

    remove_project(str(first), registry_file=registry_file)

    assert [entry.path for entry in list_projects(registry_file=registry_file)] == [str(second)]


def test_the_record_on_disk_is_path_and_optional_label(registry_file, project):
    root = project()

    add_project(str(root), label="Named", registry_file=registry_file)
    assert json.loads(registry_file.read_text()) == [{"path": str(root), "label": "Named"}]

    # Re-adding updates rather than duplicating, and a dropped label is dropped from the record —
    # a `label: null` written back would be a second shape for "no label" the reader has to handle.
    add_project(str(root), registry_file=registry_file)
    assert json.loads(registry_file.read_text()) == [{"path": str(root)}]


def test_an_absent_registry_reads_as_empty_rather_than_raising(registry_file):
    assert load_registry(registry_file) == []
    assert registry_file.exists() is False, "reading the registry created it"


def test_the_default_location_is_xdg_and_falls_back_to_dot_config(monkeypatch, tmp_path):
    monkeypatch.setenv("XDG_CONFIG_HOME", str(tmp_path / "elsewhere"))
    assert registry_path() == tmp_path / "elsewhere" / "dpm-board" / "registry.json"

    monkeypatch.delenv("XDG_CONFIG_HOME")
    monkeypatch.setenv("HOME", str(tmp_path / "home"))
    assert registry_path() == tmp_path / "home" / ".config" / "dpm-board" / "registry.json"

    # A relative value is ignored per the XDG specification, and the reason is this criterion: it
    # would otherwise resolve against whatever directory the board was started in, which is a write
    # outside the config location and inside a project the board may not touch.
    monkeypatch.setenv("XDG_CONFIG_HOME", "relative/config")
    assert registry_path() == tmp_path / "home" / ".config" / "dpm-board" / "registry.json"


# --- criterion 2: a registered path that is no longer a directory is pruned on launch ------------


def test_prune_drops_paths_that_are_no_longer_directories(registry_file, project, tmp_path):
    alive, gone = project("alive"), project("gone")

    add_project(str(alive), registry_file=registry_file)
    add_project(str(gone), registry_file=registry_file)

    (gone / ".dpm" / "dpm.db").unlink()
    (gone / ".dpm").rmdir()
    gone.rmdir()

    assert [entry.path for entry in prune_missing(registry_file)] == [str(alive)]
    assert [entry.path for entry in load_registry(registry_file)] == [str(alive)]


def test_prune_forgets_the_entry_and_touches_nothing_in_the_project(registry_file, project):
    """ENVX3 holds for the project being dropped too — pruning is a write to one file."""
    kept = project("kept")

    add_project(str(kept), registry_file=registry_file)

    before = files_under(kept)
    stamped = registry_file.stat().st_mtime_ns

    assert [entry.path for entry in prune_missing(registry_file)] == [str(kept)]
    assert files_under(kept) == before, "pruning reached into a registered project"
    assert registry_file.stat().st_mtime_ns == stamped, (
        "an all-present prune rewrote the registry, so the board's only durable state is "
        "re-written on every launch for nothing"
    )


# --- criterion 3's refusal: what `add` declines, and what it says --------------------------------


def test_a_directory_without_a_database_is_named_by_what_it_is_missing(project, tmp_path):
    assert missing_marker(str(project("real"))) is None

    bare = project("bare", database=False)
    assert missing_marker(str(bare)) == str(bare / ".dpm" / "dpm.db")

    # A path that is not a directory at all names *itself*, because the file the board wanted is not
    # the useful thing to report about a path that does not exist.
    absent = tmp_path / "nowhere"
    assert missing_marker(str(absent)) == str(absent)


# --- must NOT: write the registry anywhere outside the XDG config location -----------------------


def test_every_operation_writes_only_under_the_xdg_config_directory(sandbox, project, monkeypatch):
    monkeypatch.setenv("XDG_CONFIG_HOME", str(sandbox.config))
    monkeypatch.setenv("HOME", str(sandbox.home))
    monkeypatch.chdir(sandbox.cwd)

    root = project()

    # The default path throughout — no `registry_file` anywhere below, because injecting one is
    # exactly what would stop this test observing where the board puts things on its own.
    add_project(str(root))
    list_projects()
    prune_missing()
    remove_project(str(root))

    written = files_under(sandbox.config)
    expected = str(Path("dpm-board") / "registry.json")

    # Two assertions rather than one equality, because the two ways it fails are different faults
    # and a single `==` reports whichever one happened as the same sentence: the registry landing
    # somewhere else entirely, and something *extra* landing here — a leaked staging file from the
    # atomic write is the second, and it is the one nobody would guess from an empty-set diff.
    assert expected in written, f"the registry did not land under $XDG_CONFIG_HOME: {written}"
    assert written == {expected}, f"the config directory holds more than the registry: {written}"
    assert files_under(sandbox.home) == set(), "the board wrote into the home directory"
    assert files_under(sandbox.cwd) == set(), "the board wrote into the directory it was run from"
    assert files_under(root) == {str(Path(".dpm") / "dpm.db")}, "the board wrote into the project"


def test_the_absence_check_can_see_a_write_when_there_is_one(sandbox):
    """The control for the test above: a sweep that finds nothing anywhere reads identically.

    Without this, every assertion up there holds for a `files_under` that cannot see a file — a
    wrong `rglob`, a `Path` compared against a `str`, a root that was never created. Planting one
    write in each of the three roots is what separates "nothing was written" from "nothing is
    observable".
    """
    (sandbox.config / "stray.json").write_text("{}")
    (sandbox.home / "stray.json").write_text("{}")
    (sandbox.cwd / "nested").mkdir()
    (sandbox.cwd / "nested" / "stray.json").write_text("{}")

    assert files_under(sandbox.config) == {"stray.json"}
    assert files_under(sandbox.home) == {"stray.json"}
    assert files_under(sandbox.cwd) == {str(Path("nested") / "stray.json")}


def test_the_atomic_write_leaves_no_staging_file_behind_even_over_an_existing_registry(
    registry_file, project
):
    add_project(str(project("one")), registry_file=registry_file)
    add_project(str(project("two")), registry_file=registry_file)

    assert files_under(registry_file.parent) == {registry_file.name}


def test_the_registry_file_is_never_the_one_being_written_to(registry_file, project, monkeypatch):
    """The mechanism, because it *is* the property: the live file only ever changes by rename.

    A save that writes the registry in place is indistinguishable from this one on every observable
    outcome — same content, same path, same result — right up until it is interrupted, and by then
    the board has forgotten every project the user registered. So what is asserted is where the
    bytes went: to a staging file, never to the registry itself.
    """
    add_project(str(project("survivor")), registry_file=registry_file)

    written: list[Path] = []
    real = Path.write_text

    def record(self, *args, **kwargs):
        written.append(self)
        return real(self, *args, **kwargs)

    monkeypatch.setattr(Path, "write_text", record)
    save_registry([], registry_file)

    assert written, "the save wrote nothing at all"
    assert registry_file not in written, (
        f"the registry was written in place rather than renamed over: {written}"
    )


def test_a_save_that_fails_leaves_the_previous_registry_intact(registry_file, project, monkeypatch):
    """What the atomicity is for: an interrupted write must not truncate what was there."""
    add_project(str(project("survivor")), registry_file=registry_file)
    before = registry_file.read_text()

    def refuse(*args, **kwargs):
        raise OSError("disk full")

    monkeypatch.setattr(registry.os, "replace", refuse)

    with pytest.raises(OSError):
        save_registry([], registry_file)

    assert registry_file.read_text() == before, "a failed write emptied the registry"
    assert load_registry(registry_file) != [], "the board forgot every project on a failed write"
    assert files_under(registry_file.parent) == {registry_file.name}, (
        "the failed write left its staging file beside the registry, in the one directory FR1 "
        "allows the board to write to"
    )
