"""Unit + integration tests for the freshness cache (Story 2).

The `[integration]` no-staleness test proves the board never paints stale state
after a tracked project changes. The read-only guard reuses retro 08's pattern:
snapshot `git HEAD`, then assert `git status --porcelain` is empty after a
cached derive — the cache must never mutate a tracked repo.
"""

from __future__ import annotations

import subprocess

import pytest

import cache
from cache import _cache_file, cache_dir, derive_project_cached, freshness_stamp
from status_model import State

from test_derivation import epic_md


@pytest.fixture
def cache_root(tmp_path):
    return tmp_path / "cache"


def _commit(repo, message="update"):
    for args in (["add", "-A"], ["commit", "-q", "-m", message]):
        subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True)


EPICS_READY = {"docs/epics/39-01-epic-foo.md": epic_md(stories=[(1, "Pending", "—")])}
COMPLETE = {"docs/epics/39-01-epic-foo.md": epic_md("Complete", [(1, "Complete", "—")])}


# --- serve cache when unchanged ----------------------------------------------


def test_unchanged_project_is_served_from_cache(make_project, cache_root, monkeypatch):
    repo = make_project(EPICS_READY)
    first = derive_project_cached(repo, cache_root=cache_root)
    assert first.state is State.EPICS_READY

    # If the second call re-derived, this would raise — proving the cache was served.
    def boom(*_args, **_kwargs):
        raise AssertionError("derive_project should not be called for an unchanged project")

    monkeypatch.setattr(cache, "derive_project", boom)
    second = derive_project_cached(repo, cache_root=cache_root)
    assert second.state is State.EPICS_READY


# --- re-derive on change -----------------------------------------------------


def test_re_derives_when_the_cache_schema_is_outdated(make_project, cache_root):
    import json

    from cache import _cache_file, freshness_stamp

    repo = make_project(EPICS_READY)
    derive_project_cached(repo, cache_root=cache_root)  # warm the cache

    # Simulate a cache file written by an older schema (no epic/story titles):
    # keep the stamp current but drop the schema marker.
    file = _cache_file(repo, cache_root)
    payload = json.loads(file.read_text())
    payload.pop("schema", None)
    file.write_text(json.dumps(payload))

    calls = {"n": 0}
    real = cache.derive_project

    def counting(path):
        calls["n"] += 1
        return real(path)

    cache.derive_project = counting
    try:
        derive_project_cached(repo, cache_root=cache_root)
    finally:
        cache.derive_project = real
    assert calls["n"] == 1  # schema mismatch forces a re-derive despite a fresh stamp


def test_re_derives_after_head_changes(make_project, cache_root):
    repo = make_project(EPICS_READY)
    assert derive_project_cached(repo, cache_root=cache_root).state is State.EPICS_READY

    (repo / "docs" / "epics" / "39-01-epic-foo.md").write_text(
        epic_md("Complete", [(1, "Complete", "—")])
    )
    _commit(repo)  # HEAD moves

    assert derive_project_cached(repo, cache_root=cache_root).state is State.COMPLETE


def test_re_derives_after_docs_mtime_changes_without_a_commit(make_project, cache_root):
    repo = make_project(EPICS_READY)
    assert derive_project_cached(repo, cache_root=cache_root).state is State.EPICS_READY

    before = freshness_stamp(repo)
    # Edit the epic in place, no commit: HEAD is unchanged, docs mtime advances.
    (repo / "docs" / "epics" / "39-01-epic-foo.md").write_text(
        epic_md("Complete", [(1, "Complete", "—")])
    )
    after = freshness_stamp(repo)
    assert after != before  # mtime component changed the stamp

    assert derive_project_cached(repo, cache_root=cache_root).state is State.COMPLETE


# --- force bypass ------------------------------------------------------------


def test_force_bypasses_the_cache(make_project, cache_root, monkeypatch):
    repo = make_project(EPICS_READY)
    derive_project_cached(repo, cache_root=cache_root)  # warm the cache

    calls = {"n": 0}
    real = cache.derive_project

    def counting(path):
        calls["n"] += 1
        return real(path)

    monkeypatch.setattr(cache, "derive_project", counting)
    derive_project_cached(repo, cache_root=cache_root, force=True)
    assert calls["n"] == 1  # re-derived despite an unchanged stamp


# --- cache location & read-only guard ----------------------------------------


def test_cache_file_lives_under_cache_root_not_in_the_repo(make_project, cache_root):
    repo = make_project(EPICS_READY)
    derive_project_cached(repo, cache_root=cache_root)

    file = _cache_file(repo, cache_root)
    assert file.is_file()
    assert cache_root in file.parents
    assert repo not in file.parents  # never written inside the tracked repo


def test_cache_dir_honours_xdg_cache_home(monkeypatch, tmp_path):
    monkeypatch.setenv("XDG_CACHE_HOME", str(tmp_path / "xdg"))
    assert cache_dir() == tmp_path / "xdg" / "cpm-board"


def test_cached_derive_is_read_only(make_project, cache_root):
    repo = make_project(COMPLETE)
    before = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True, text=True
    ).stdout.strip()

    derive_project_cached(repo, cache_root=cache_root)

    after = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True, text=True
    ).stdout.strip()
    assert after == before  # HEAD unchanged
    porcelain = subprocess.run(
        ["git", "status", "--porcelain"], cwd=repo, capture_output=True, text=True
    )
    assert porcelain.stdout.strip() == ""  # no working-tree changes from the cache


# --- no staleness (integration) ----------------------------------------------


def test_must_not_show_stale_state_after_a_project_changes(make_project, cache_root):
    repo = make_project(EPICS_READY)
    assert derive_project_cached(repo, cache_root=cache_root).state is State.EPICS_READY

    # A story completes and is committed — the very next derive must reflect it.
    (repo / "docs" / "epics" / "39-01-epic-foo.md").write_text(
        epic_md("Complete", [(1, "Complete", "—")])
    )
    _commit(repo)

    refreshed = derive_project_cached(repo, cache_root=cache_root)
    assert refreshed.state is State.COMPLETE  # must NOT be the stale EPICS_READY
