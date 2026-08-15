"""Story 1 — the launch target follows the focused column (FR8).

Two halves, and each is the other's control. The resolver is driven directly over all four
documented shapes, because a criterion asserted on one column passes on a resolver that ignores the
column entirely. The keys are driven through the pilot, because a resolver nothing reaches is a
correct answer to a question the board never asks.

**Every candidate kind's command is checked against the model's own enumeration** rather than
against a transcribed list: `status_model.CANDIDATE_KINDS` decides what kinds exist, and a kind
added there with no command here has to fail somewhere.
"""

from __future__ import annotations

import pytest
from pilot import board, palette, until

from board import offered_by_id, read_view
from board_view import EpicView, ProjectView, StoryView
from launcher import (
    ATTACH,
    CANDIDATE_COMMANDS,
    LAUNCH,
    OPEN,
    PROJECT_TARGET,
    NoTarget,
    launch_target,
    missing_commands,
    target_line,
)
from mcp_client import ServerPool
from status_model import (
    CANDIDATE_KINDS,
    EPICS,
    RETROS,
    SPECS,
    Candidate,
    candidates,
    ready_epic_ids,
    rows,
)

#: One candidate of each kind, named by the row it is about. The ids are deliberately different per
#: kind: a resolver that took the argument from somewhere other than the candidate would still
#: produce *an* id, and identical ids would let it pass.
READY_EPIC = Candidate("epic_ready", "48-05", "Launch, Attach and Live Sessions")
UNBROKEN_SPEC = Candidate("spec_without_epics", "51", "A spec nothing has been broken down from")
UNREFLECTED_EPIC = Candidate("retro_missing", "48-04", "The Three-Column Browser and Previews")


def project(candidate: Candidate | None = READY_EPIC) -> ProjectView:
    """A project with one epic, carrying ``candidate`` and holding one story.

    The story matters: the Stories column's target is the *epic's*, and a fixture with no story
    leaves that column empty and its criterion unasserted.
    """
    return ProjectView(
        name="alpha",
        path="/tmp/alpha",
        epics=(
            EpicView(
                id="48-05",
                title="Launch, Attach and Live Sessions",
                state="ready",
                stories=(StoryView("48-05-1", "Launch targets follow the focused column", "pending"),),
                candidate=candidate,
            ),
        ),
    )


def recorder():
    """A launch sink and the list of what reached it: ``(intent, project name, target)``."""
    calls: list[tuple] = []

    def launch(intent, view, target) -> None:
        calls.append((intent, view.name, target))

    return calls, launch


def test_each_focused_column_produces_its_documented_launch_target():
    """Criteria 1 and 2, over all four shapes at once.

    One test rather than four, because the requirement is the *enumeration*: three of these
    passing and one failing is a board that launches the wrong command for one kind of row, and a
    per-shape test set makes that a green suite with a red line in it.
    """
    resolved = {
        ("projects", None): launch_target("projects"),
        ("epics", "epic_ready"): launch_target("epics", READY_EPIC),
        ("epics", "spec_without_epics"): launch_target("epics", UNBROKEN_SPEC),
        ("stories", "retro_missing"): launch_target("stories", UNREFLECTED_EPIC),
    }

    assert resolved == {
        ("projects", None): ["/dpm:do"],
        ("epics", "epic_ready"): ["/dpm:do", "48-05"],
        ("epics", "spec_without_epics"): ["/dpm:epics", "51"],
        ("stories", "retro_missing"): ["/dpm:retro", "48-04"],
    }

    for target in resolved.values():
        assert isinstance(target, list) and all(isinstance(word, str) for word in target), (
            f"a target is not an argv list of strings: {target!r}"
        )


def test_the_stories_column_launches_the_epic_its_stories_belong_to():
    """The asymmetry Story 1 exists to get right, stated on its own.

    A story is not a candidate and has no command of its own, so the Stories column's target is
    the epic above it — the same one the Epics column produces. A resolver keyed on the column
    rather than on the candidate would have to invent a third answer here.
    """
    assert launch_target("stories", READY_EPIC) == launch_target("epics", READY_EPIC)


def test_every_candidate_kind_the_model_has_maps_to_a_command():
    """FR8's commands, reconciled against FR9's kinds.

    The pairing is checked by comparing the two tables rather than by asserting three names, so a
    fourth kind added to the model arrives here as a failure instead of as a launch that silently
    resolves to nothing.
    """
    assert CANDIDATE_KINDS, "the model declares no candidate kinds, so this compares nothing"
    assert missing_commands() == [], (
        f"candidate kinds with no launch command: {missing_commands()}"
    )
    assert set(CANDIDATE_COMMANDS) == set(CANDIDATE_KINDS), (
        f"the command table names kinds the model does not have: "
        f"{sorted(set(CANDIDATE_COMMANDS) - set(CANDIDATE_KINDS))}"
    )


def test_a_row_with_no_candidate_is_refused_rather_than_launched_as_the_project():
    """An epic nothing can be done to next has no documented target.

    The control matters as much as the refusal: the same column *with* a candidate resolves, so
    the raise below is about the row rather than about the column being unknown. Answering with
    the project's bare command would start a session about the whole project while the user was
    pointing at one epic, and nothing on screen would say which had happened.
    """
    assert launch_target("epics", READY_EPIC) == ["/dpm:do", "48-05"]

    with pytest.raises(NoTarget):
        launch_target("epics", None)


def test_an_unknown_candidate_kind_is_refused_rather_than_defaulted():
    """A kind with no command must not fall through to the project's target.

    This is the shape the refusal exists for: a default would launch something plausible for a row
    the board has no command for, and the user would find out by reading what the session did.
    """
    with pytest.raises(NoTarget):
        launch_target("epics", Candidate("something_new", "52", "A kind added later"))


def test_a_target_is_one_argument_rather_than_several():
    """The target becomes Claude's single argument, so it is joined and not quoted here.

    The quoting happens once, in :func:`launcher.launch_command`, around the whole of this line —
    quoting the elements as well would put the quotes *inside* the argument and Claude would be
    handed them as text. Story 2's tests are where the quoting itself is asserted.
    """
    assert target_line(launch_target("epics", READY_EPIC)) == "/dpm:do 48-05"


async def test_the_four_keys_reach_launch_plain_claude_attach_and_copy():
    """Criterion 3 from the board's own keys, with the target the focused column produced.

    Every key is pressed in one session, because they are four bindings on one screen and a test
    per key would not notice two of them landing on the same action.
    """
    calls, launch = recorder()

    async with board([project()], launch=launch) as (app, pilot):
        for key in ("l", "o", "t"):
            await pilot.press(key)
            await pilot.pause()

        await pilot.press("c")
        await pilot.pause()

        from_projects = app.clipboard

        await pilot.press("right")
        await pilot.pause()
        await pilot.press("l")
        await pilot.pause()
        await pilot.press("c")
        await pilot.pause()

        from_epics = app.clipboard

    assert calls == [
        (LAUNCH, "alpha", ["/dpm:do"]),
        (OPEN, "alpha", None),
        (ATTACH, "alpha", None),
        (LAUNCH, "alpha", ["/dpm:do", "48-05"]),
    ], f"the keys did not reach their four actions in order: {calls}"

    # Copy leaves nothing for the sink to record, so its witness is the clipboard — and it is
    # asserted twice, once per column, because a copy that ignored the cursor would pass the first.
    assert from_projects == "cd /tmp/alpha && claude /dpm:do", (
        f"`c` copied {from_projects!r} from the Projects column"
    )
    assert from_epics == "cd /tmp/alpha && claude '/dpm:do 48-05'", (
        f"`c` copied {from_epics!r} from the Epics column"
    )


async def test_the_stories_column_launches_from_the_board():
    """The third column's key path, which is where the resolver's asymmetry is visible.

    Driven through focus rather than by calling the action, so what is asserted is the target a
    user gets with the cursor two columns in.
    """
    calls, launch = recorder()

    async with board([project()], launch=launch) as (app, pilot):
        await pilot.press("right")
        await pilot.press("right")
        await pilot.pause()

        focused = app.focused_column()

        await pilot.press("l")
        await pilot.pause()

    assert focused == "stories", f"the cursor never reached the Stories column: {focused}"
    assert calls == [(LAUNCH, "alpha", ["/dpm:do", "48-05"])], (
        f"the Stories column launched something other than its epic: {calls}"
    )


async def test_a_row_with_no_candidate_launches_nothing_from_the_board():
    """The refusal, at the key rather than at the resolver.

    A board that caught the refusal and launched the project's bare command instead would pass
    every assertion above: this is the one that says the keypress produced no session at all.
    """
    calls, launch = recorder()

    async with board([project(candidate=None)], launch=launch) as (app, pilot):
        await pilot.press("right")
        await pilot.pause()
        await pilot.press("l")
        await pilot.press("c")
        await pilot.pause()

        copied = app.clipboard

    assert calls == [], f"a row with no candidate launched something: {calls}"
    assert copied == "", f"a row with no candidate put {copied!r} on the clipboard"


async def run_from_palette(app, pilot, name: str) -> None:
    """Open the palette, type ``name``, and run the entry it finds — the discoverable route.

    Typed and selected rather than dispatched, because what the criterion is about is the palette
    reaching the action: an entry whose callable was built wrongly runs nothing, and asking the
    provider for its callable would be asking the thing under test for its own answer.
    """
    await pilot.press("ctrl+p")
    await until(pilot, lambda: palette(app))

    for character in name:
        await pilot.press(character)

    await until(pilot, lambda: name in palette(app))
    await pilot.press("down")
    await pilot.press("enter")
    await pilot.pause()
    await pilot.pause()


async def test_the_four_actions_run_from_the_palette():
    """Criterion 3's second half: the same actions, reached the discoverable way.

    Each is *run* rather than merely listed. That a palette entry names an action the app has is
    already checked structurally in `test_palette.py`; what this adds is that choosing the entry
    reaches the same action the key does, with the same target.
    """
    calls, launch = recorder()

    async with board([project()], launch=launch) as (app, pilot):
        for name in ("Launch a session", "Open Claude at the project", "Attach to a live session"):
            await run_from_palette(app, pilot, name)

        await run_from_palette(app, pilot, "Copy the command")

        copied = app.clipboard

    assert calls == [
        (LAUNCH, "alpha", ["/dpm:do"]),
        (OPEN, "alpha", None),
        (ATTACH, "alpha", None),
    ], f"the palette's entries did not reach the launcher: {calls}"
    assert copied == "cd /tmp/alpha && claude /dpm:do", (
        f"the palette's copy action copied {copied!r}"
    )


async def test_the_browsers_epic_rows_carry_the_models_own_candidates(fixture_project):
    """The wiring between FR9's answer and FR8's target, over the real server.

    Everything above drives rows a test built. This is the one that says the rows a *user* gets
    carry the same candidates the model derived — without it, the launch keys would resolve
    perfectly against a column where every row's candidate was ``None``.

    The comparison is against :func:`status_model.candidates` run again, not against a transcribed
    expectation: what is asserted is that the browser's rows agree with the model, which is the
    only thing this layer owes.
    """
    async with ServerPool() as pool:
        view = await read_view(pool, fixture_project, "fixture")

        epics = await rows(pool, fixture_project, EPICS)
        specs = await rows(pool, fixture_project, SPECS)
        retros = await rows(pool, fixture_project, RETROS)
        ready = await ready_epic_ids(pool, fixture_project)

    offered = offered_by_id(candidates(epics, specs, retros, ready))
    carried = {row.id: row.candidate for row in view.epics if row.candidate is not None}

    assert carried, (
        "no epic row carries a candidate, so the agreement below is between two empty sets"
    )
    assert carried == {
        row.id: offered[row.id] for row in view.epics if row.id in offered
    }, "the browser's rows disagree with the model about what could be done next"

    # And every one of them resolves: a candidate the model produces for a real project and that
    # this module has no command for would otherwise surface as a refusal at the keypress.
    resolved = {row.id: launch_target("epics", row.candidate) for row in view.epics if row.candidate}

    assert all(len(target) == 2 for target in resolved.values()), (
        f"a real project's candidate produced a target that is not a command and an id: {resolved}"
    )


def test_the_projects_target_is_the_bare_command():
    """FR8's Projects-column shape, with nothing appended.

    Stated separately because it is the one target that takes no argument, and an implementation
    that appended the project's own path or name would still be an argv list of the right kind.
    """
    assert list(PROJECT_TARGET) == ["/dpm:do"]
    assert launch_target("projects", READY_EPIC) == ["/dpm:do"], (
        "the Projects column used the highlighted candidate rather than the project"
    )
