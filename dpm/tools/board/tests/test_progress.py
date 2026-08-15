"""Story 2 — stories done over stories total, per epic and per project (FR6).

The arithmetic is the easy half. What the tests here are actually about is the epic with no stories,
because 0/0 is complete by every reading a naive implementation gives it: `done == total` is true,
"all stories done" is vacuously true, and a percentage is either 100 or a division by zero. An epic
nobody has broken down yet would render as finished work.
"""

from __future__ import annotations

from fixture_database import CONTENT

from mcp_client import ServerPool
from status_model import EPICS, STORIES, by_epic, in_progress, progress, rows


def stories(epic: str, *statuses: str) -> list[dict]:
    """Story rows as `list_story` returns them: an epic, and a status per story."""
    return [
        {"id": f"{epic}-{index}", "epic_id": epic, "status": status}
        for index, status in enumerate(statuses)
    ]


def test_an_epics_progress_is_its_own_story_rows():
    """The criterion: counts equal the rows the tools return, not a remembered total."""
    counted = progress(stories("e1", "complete", "pending", "complete"))

    assert (counted.done, counted.total) == (2, 3)
    assert str(counted) == "2/3"


def test_an_epic_with_no_stories_reports_no_progress():
    """The wrong answer this excludes: `Progress(0, 0)`, which reads as complete.

    `done == total` is true of it, and an epic nobody has broken down yet would render finished —
    on a board whose whole job is showing what is left to do.
    """
    assert progress([]) is None


def test_a_finished_epic_is_complete_and_an_empty_one_is_not():
    """The two ends of the same rule, so `complete` cannot be answered by the arithmetic alone."""
    assert progress(stories("e1", "complete", "complete")).complete is True
    assert progress(stories("e1", "complete", "pending")).complete is False


def test_a_retired_story_leaves_the_count_rather_than_joining_either_side():
    """`story.status` has four values, and the two wrong readings sit on either side of this one.

    `020-status-lifecycle.sql` widened `story` and `task` alongside `document`, so a `withdrawn`
    story is a row that really occurs. Counting it as done reports work that was dropped as
    delivered; holding it in the denominator keeps the epic open for something nobody intends to
    do. It leaves the count, and how many left is carried alongside so a shrunken denominator does
    not do it silently.

    This is `dpm:status`'s rule. It reached the board through AD5's reconciliation, which found the
    board's own answer — three complete stories and one withdrawn reading as 3/4, forever — wrong.
    """
    counted = progress([
        {"id": "s0", "epic_id": "e1", "status": "complete"},
        {"id": "s1", "epic_id": "e1", "status": "complete"},
        {"id": "s2", "epic_id": "e1", "status": "complete"},
        {"id": "s3", "epic_id": "e1", "status": "withdrawn"},
    ])

    assert (counted.done, counted.total) == (3, 3), (
        f"a retired story joined one side of the count: {counted}"
    )
    assert counted.complete is True, "an epic whose only unfinished story was withdrawn reads open"
    assert counted.retired == 1, "the denominator shrank without saying so"


def test_an_epic_whose_only_unfinished_stories_are_retired_is_not_in_progress():
    """The same rule reaching the derived state, so the two cannot drift apart."""
    stories = [
        {"id": "s0", "epic_id": "e1", "status": "complete"},
        {"id": "s1", "epic_id": "e1", "status": "superseded"},
    ]

    assert in_progress(stories) is False, "an epic with nothing left to do read as under way"


def test_an_epic_of_nothing_but_retired_stories_has_no_progress():
    """Nothing to do and nothing done — the empty case reached from the third direction."""
    assert progress([{"id": "s0", "epic_id": "e1", "status": "withdrawn"}]) is None


def test_progress_is_grouped_by_the_epic_the_row_names():
    """`epic_id` comes back on every story row, so grouping needs no second call per epic."""
    grouped = by_epic(stories("e1", "complete") + stories("e2", "pending", "pending"))

    assert {epic: str(progress(rows)) for epic, rows in grouped.items()} == {
        "e1": "1/1",
        "e2": "0/2",
    }


def test_the_project_roll_up_counts_rows_rather_than_averaging_epics():
    """The roll-up's own decoy: an epic with no stories must not lift the project's figure.

    Averaging per-epic completion gives the empty epic a 100% of its own, so a project with one
    untouched epic and one empty one reads as half done. Counting the rows the tools returned is
    the only reading in which an epic with nothing in it contributes nothing.
    """
    project = stories("e1", "complete", "pending") + stories("e2")

    assert str(progress(project)) == "1/2"


def test_a_project_with_no_stories_at_all_reports_no_progress():
    """Same rule as the empty epic, reached from the other end — a project with no epics."""
    assert progress([]) is None


def fixture_stories() -> list[dict]:
    """The story rows :data:`CONTENT` creates, with the status each one is created in."""
    return [
        {"status": arguments.get("status", "pending")}
        for call, arguments, _ in CONTENT
        if call == "create_story"
    ]


async def test_the_counts_equal_the_story_rows_the_tools_return(fixture_project):
    """FR6 against real rows: the figure the board reports is the rows the server sent.

    Compared against the fixture's own content rather than a number written here, so the
    assertion cannot be satisfied by a count that stopped agreeing with the project it describes.
    The fixture also holds two epics with no stories at all, which is what makes the per-epic half
    of this reach the empty case over real rows rather than only over a hand-built list.
    """
    async with ServerPool() as pool:
        epics = await rows(pool, fixture_project, EPICS)
        story_rows = await rows(pool, fixture_project, STORIES)

    expected = progress(fixture_stories())
    counted = progress(story_rows)

    assert (counted.done, counted.total) == (expected.done, expected.total)

    grouped = by_epic(story_rows)
    per_epic = {epic["title"]: progress(grouped.get(epic["id"], [])) for epic in epics}

    assert str(per_epic["Second epic"]) == "1/2"
    assert per_epic["First epic"] is None, "an epic with no stories reported a figure"
    assert per_epic["Third epic"] is None
