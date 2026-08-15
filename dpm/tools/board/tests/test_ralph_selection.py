"""Story 2 — several ready epics become one `/dpm:ralph` command (FR14).

**The empty-selection criterion is an equality against 48-05's own resolver, not a restatement of
it.** A board that always built a `/dpm:ralph` command — with one epic in it when nothing is selected
— satisfies every other criterion here and quietly breaks FR8. The only assertion that catches it is
one whose expected value is `launch_target()`'s answer for the same row, so the two cannot drift.

The eligibility rule is checked the same way: derived from `launcher.CANDIDATE_COMMANDS` rather than
written out, with a floor that fails if the derivation ever admits every kind.
"""

from __future__ import annotations

from pilot import board, lines, painted, text_of

from board_view import RALPH_MARKER, EpicView, ProjectView, StoryView
from launcher import (
    ATTACH,
    CANDIDATE_COMMANDS,
    DO,
    LAUNCH,
    OPEN,
    RALPH,
    launch_command,
    launch_target,
    selectable,
)
from status_model import CANDIDATE_KINDS, Candidate

#: One epic per candidate kind, plus one with no candidate at all — FR14's three exclusions and the
#: one row that may be selected. The ids differ per row so a selection built from the wrong one is
#: visible in the target rather than being masked by a shared id.
READY = Candidate("epic_ready", "48-07", "Freshness, Ralph Multi-Select and Cross-Project Search")
SECOND = Candidate("epic_ready", "48-08", "A second epic that can be run now")
UNBROKEN = Candidate("spec_without_epics", "51", "A spec nothing has been broken down from")
UNREFLECTED = Candidate("retro_missing", "48-04", "The Three-Column Browser and Previews")

#: The row that cannot be selected because nothing can be done to it next — blocked, in FR14's words.
BLOCKED = None


def epic(candidate: Candidate | None, identifier: str, title: str) -> EpicView:
    """One epic row carrying ``candidate``, with a story under it.

    The story matters for the same reason it does in 48-05's fixture: the Stories column's target is
    the epic's, and a row with no stories leaves that column empty.
    """
    return EpicView(
        id=identifier,
        title=title,
        state="ready",
        stories=(StoryView(f"{identifier}-1", f"A story under {identifier}", "pending"),),
        candidate=candidate,
    )


def project(*epics: EpicView) -> ProjectView:
    """A project holding ``epics``, in the order given — which is the order a selection comes out in."""
    return ProjectView(name="alpha", path="/tmp/alpha", epics=tuple(epics))


#: The four-row fixture: one selectable epic, then each of the three FR14 excludes.
def mixed() -> ProjectView:
    return project(
        epic(READY, "48-07", "Freshness, Ralph Multi-Select and Cross-Project Search"),
        epic(BLOCKED, "48-09", "An epic that is blocked"),
        epic(UNREFLECTED, "48-04", "The Three-Column Browser and Previews"),
        epic(UNBROKEN, "51", "A spec nothing has been broken down from"),
    )


def recorder():
    """A launch sink and the list of what reached it: ``(intent, project name, target)``."""
    calls: list[tuple] = []

    def launch(intent, view, target) -> None:
        calls.append((intent, view.name, target))

    return calls, launch


def reports(app) -> list[str]:
    """What the board's notifications painted, one string per toast.

    Read from the rendered toasts rather than from the app's own record, the same rule every other
    assertion here follows: a refusal the board noted and never painted refuses nothing to anybody.
    """
    return [" ".join(text_of(painted(toast))) for toast in app.screen.query("Toast")]


async def select(pilot, *steps: int) -> None:
    """Move down ``steps`` rows in the Epics column and press `space` at each stop."""
    for step in steps:
        for _ in range(step):
            await pilot.press("down")

        await pilot.press("space")
        await pilot.pause()


def test_the_eligibility_rule_is_derived_from_the_launch_commands():
    """Criterion 4 [unit], at the rule rather than at the keypress.

    **A floor and a ceiling.** The floor is that something is selectable at all — a rule that
    admitted nothing would pass every must-NOT below while making the feature unreachable. The
    ceiling is that it is a *proper* subset of the model's kinds, which is the must-NOT itself: a
    rule that returned true for everything is exactly what FR14 forbids, and it is what a
    hand-written list quietly becomes when a fourth kind is added.
    """
    admitted = {kind for kind in CANDIDATE_KINDS if selectable(Candidate(kind, "1", "A row"))}

    assert admitted, "no candidate kind can be selected, so a ralph selection can never be built"
    assert admitted < set(CANDIDATE_KINDS), (
        f"every candidate kind is selectable, including the ones FR14 excludes: {admitted}"
    )
    assert admitted == {kind for kind, command in CANDIDATE_COMMANDS.items() if command == DO}
    assert not selectable(None), "a row with no candidate at all was admitted"


def test_a_selection_retargets_the_resolver_whatever_the_column_says():
    """Criterion 1 [unit], at the resolver.

    All three columns, because the selection is the user's deliberate act and the cursor is wherever
    it was left: a resolver that honoured the selection in the Epics column and the highlighted row
    everywhere else would launch a single epic from a board still showing two marked rows.
    """
    selected = ["48-07", "48-08"]
    resolved = {
        "projects": launch_target("projects", None, selected),
        "epics": launch_target("epics", READY, selected),
        "stories": launch_target("stories", READY, selected),
    }

    assert resolved == {column: [RALPH, "48-07", "48-08"] for column in resolved}

    for target in resolved.values():
        assert isinstance(target, list) and all(isinstance(word, str) for word in target), (
            f"a ralph target is not an argv list of strings: {target!r}"
        )


async def test_a_non_empty_selection_retargets_every_launch_key():
    """Criterion 1 [unit], from the board's own keys.

    `l` and `c` are both asserted: they are the two keys that carry a target, and the copy is the one
    that shows the whole command a user would paste — including that the epics are one quoted
    argument rather than three (NFR4).
    """
    calls, launch = recorder()

    async with board(
        [project(epic(READY, "48-07", "Freshness"), epic(SECOND, "48-08", "The one after"))],
        launch=launch,
    ) as (app, pilot):
        await pilot.press("right")
        await pilot.pause()
        await select(pilot, 0, 1)

        selection = app.ralph_selection()
        target = app.current_target()

        await pilot.press("l")
        await pilot.pause()
        await pilot.press("c")
        await pilot.pause()

        copied = app.clipboard

    assert selection == ["48-07", "48-08"], f"the selection came out as {selection}"
    assert target == [RALPH, "48-07", "48-08"]
    assert calls == [(LAUNCH, "alpha", [RALPH, "48-07", "48-08"])], (
        f"`l` launched something other than the selection: {calls}"
    )
    assert copied == "cd /tmp/alpha && claude '/dpm:ralph 48-07 48-08'", (
        f"`c` copied {copied!r} for a two-epic selection"
    )
    assert copied == launch_command("/tmp/alpha", [RALPH, "48-07", "48-08"]), (
        "the copied command is not the one the launcher builds for the same target"
    )


async def test_space_selects_a_runnable_epic_and_deselects_it_and_the_row_shows_it():
    """Criterion 2 [feature], read off the painted rows.

    **The marker is asserted from what the column painted**, not from the set the app is holding. A
    selection the board knows about and does not draw is the failure this criterion exists to catch —
    the user presses launch expecting one epic and gets two.
    """
    async with board(
        [project(epic(READY, "48-07", "Freshness"), epic(SECOND, "48-08", "The one after"))]
    ) as (app, pilot):
        await pilot.press("right")
        await pilot.pause()

        before = lines(app, "epics")

        await pilot.press("space")
        await pilot.pause()

        marked = lines(app, "epics")
        held = app.ralph_selection()

        await pilot.press("space")
        await pilot.pause()

        after = lines(app, "epics")
        released = app.ralph_selection()

    assert not any(RALPH_MARKER in row for row in before), (
        f"a board with nothing selected painted a marker: {before}"
    )
    assert [RALPH_MARKER in row for row in marked] == [True, False], (
        f"the marker did not land on the highlighted row alone: {marked}"
    )
    assert held == ["48-07"] and released == []
    assert after == before, f"deselecting left the column different from how it started: {after}"


async def test_a_blocked_retro_or_needs_epics_row_cannot_be_selected():
    """Criterion 4's must-NOT [unit], driven at the key over all three excluded kinds at once.

    One test rather than three, because the requirement is the *set*: two refusals and one admission
    is a board that builds a ralph command over a spec, and a test per kind makes that a green suite
    with one red line in it. The refusal is also asserted to be *said* — a key that quietly did
    nothing is indistinguishable from a selection that is broken, and the user's next move would be
    to press it again.
    """
    calls, launch = recorder()

    async with board([mixed()], launch=launch, notifications=True) as (app, pilot):
        await pilot.press("right")
        await pilot.pause()
        await select(pilot, 1, 1, 1)

        refused = app.ralph_selection()
        painted_rows = lines(app, "epics")
        said = reports(app)

        await pilot.press("l")
        await pilot.pause()

    assert refused == [], f"an excluded row was selected: {refused}"
    assert not any(RALPH_MARKER in row for row in painted_rows), (
        f"an excluded row was painted as selected: {painted_rows}"
    )
    assert len(said) == 3, f"the three refusals were not all reported: {said}"
    # The cursor ends on the last row `space` was pressed over, and its target is that row's own —
    # which is FR8's answer and not a ralph command. Three refusals leave the launch keys exactly
    # where they were.
    assert calls == [(LAUNCH, "alpha", launch_target("epics", UNBROKEN))], (
        f"the launch after three refused selections was not the highlighted row's own: {calls}"
    )


async def test_with_no_selection_the_launch_keys_behave_exactly_as_48_05_specifies():
    """Criterion 3 [unit]. Every column's target, against the resolver 48-05 verified.

    **The expected value is `launch_target()` called the way 48-05 calls it** — two arguments, no
    selection at all — not a list written here and not the same three-argument call the board makes.
    That is the whole discriminating power of this test: a board that always built a ralph command
    passes criteria 1, 2 and 4, and comparing its answer against its own call would agree with it.
    """
    calls, launch = recorder()
    rows = project(epic(READY, "48-07", "Freshness"), epic(UNBROKEN, "51", "An unbroken spec"))
    resolved = {}

    async with board([rows], launch=launch) as (app, pilot):
        for column in ("projects", "epics", "stories"):
            while app.focused_column() != column:
                await pilot.press("right")

            await pilot.pause()
            resolved[column] = (app.current_target(), app.current_candidate())

            await pilot.press("l")
            await pilot.pause()

        selection = app.ralph_selection()

    assert selection == [], "the board under test had something selected after all"
    assert resolved == {
        column: (launch_target(column, candidate), candidate)
        for column, (_, candidate) in resolved.items()
    }, f"an empty selection changed what a column resolves to: {resolved}"
    assert calls == [
        (LAUNCH, "alpha", launch_target(column, candidate))
        for column, (_, candidate) in resolved.items()
    ], f"the launch keys did not produce 48-05's own targets: {calls}"
    assert [intent for intent, _, _ in calls] == [LAUNCH] * 3
    assert OPEN not in {intent for intent, _, _ in calls}
    assert ATTACH not in {intent for intent, _, _ in calls}


async def test_a_selection_made_in_one_project_does_not_reach_another():
    """The consequence of holding one set for the whole board, asserted rather than assumed.

    The selection is read *through* the epics on screen, so a project's launch can only ever carry
    its own rows — and coming back to the project the selection was made in finds it intact, which is
    what makes one flat set the right shape rather than merely the simple one.
    """
    alpha = project(epic(READY, "48-07", "Freshness"))
    beta = ProjectView(
        name="beta",
        path="/tmp/beta",
        epics=(epic(SECOND, "48-08", "Another project's epic"),),
    )

    async with board([alpha, beta]) as (app, pilot):
        await pilot.press("right")
        await pilot.pause()
        await pilot.press("space")
        await pilot.pause()

        here = app.ralph_selection()

        await pilot.press("left")
        await pilot.press("down")
        await pilot.pause()

        elsewhere = app.ralph_selection()
        target_there = app.current_target()

        await pilot.press("up")
        await pilot.pause()

        back = app.ralph_selection()

    assert here == ["48-07"]
    assert elsewhere == [], f"another project's launch carried alpha's selection: {elsewhere}"
    assert target_there == [DO], "the other project's target was not its own bare command"
    assert back == ["48-07"], "returning to the project lost the selection made in it"
