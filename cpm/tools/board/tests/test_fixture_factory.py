"""Unit tests for the fixture-repo factory (Story 3)."""

from __future__ import annotations

import subprocess


def test_make_project_writes_the_requested_docs_tree(make_project):
    repo = make_project(
        {
            "docs/specifications/01-spec-foo.md": "# Spec\n",
            "docs/epics/01-01-epic-foo.md": "**Status**: Pending\n",
        }
    )
    assert (repo / "docs/specifications/01-spec-foo.md").read_text() == "# Spec\n"
    assert (repo / "docs/epics/01-01-epic-foo.md").read_text() == "**Status**: Pending\n"


def test_make_project_is_a_git_repo_with_a_resolvable_head(make_project):
    repo = make_project({"docs/epics/01-01-epic-foo.md": "x"})
    head = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True, text=True
    )
    assert head.returncode == 0
    assert head.stdout.strip()  # a real commit sha


def test_make_project_can_skip_the_commit(make_project):
    repo = make_project({"docs/epics/01-01-epic-foo.md": "x"}, commit=False)
    assert not (repo / ".git").exists()


def test_make_project_isolates_repos_per_call(make_project):
    a = make_project({"docs/epics/01-01-epic-a.md": "a"})
    b = make_project({"docs/epics/01-01-epic-b.md": "b"})
    assert a != b
    assert (a / "docs/epics/01-01-epic-a.md").exists()
    assert not (a / "docs/epics/01-01-epic-b.md").exists()
