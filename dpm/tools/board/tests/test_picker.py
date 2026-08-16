"""Story 5 — registering a project from inside the browser (FR1).

FR1 is covered only across two epics: 48-02's `add` is the CLI half, and this is the other. The
second criterion is where they meet, and it is asserted by **running the CLI** and comparing what it
printed with what the picker painted — not against a string written down here. A transcribed message
is a third copy of the sentence, and it would go on passing after both real ones had changed.

Everything is read from the rendered screen. The picker's whole content is what a user sees when
they choose a directory that will not do.
"""

from __future__ import annotations

from dataclasses import replace
from io import StringIO
from pathlib import Path

from pilot import board, lines, until
from wiring import registry_wiring

from board import PickerScreen, ProjectTree, registry_views, run_cli
from registry import add_project, list_projects, remove_project


def squashed(rendered: list[str]) -> str:
    """Painted lines as one string with every run of whitespace removed."""
    return "".join("".join(line.split()) for line in rendered)


def registry(tmp_path: Path) -> Path:
    """A registry file this test owns, so nothing here can reach the user's own projects."""
    return tmp_path / "registry.json"


def wired(tmp_path: Path, picker_root: Path) -> dict:
    """The injections `_browse_with` makes, pointed at a registry the test owns."""
    return registry_wiring(registry(tmp_path), picker_root=picker_root)


async def choose(app, pilot, path: Path) -> None:
    """Put the picker's cursor on ``path`` and select it, as a user pressing ↓ and ⏎ would.

    The node is found by the path it carries rather than by counting keystrokes to it — a test that
    pressed ↓ twice would be asserting the order the filesystem happened to return.
    """
    tree = app.screen.query_one(ProjectTree)
    node = next(child for child in tree.root.children if child.data.path == path)

    tree.move_cursor(node)
    await pilot.press("enter")
    await pilot.pause()
    await pilot.pause()


async def open_picker(pilot, app) -> None:
    await pilot.press("a")
    await until(pilot, lambda: isinstance(app.screen, PickerScreen), timeout=2.0)


async def test_the_picker_registers_a_project_and_it_appears_without_a_restart(project, tmp_path):
    """Criterion 1, end to end through the keys and the rendered column.

    The registry file is checked *as well as* the column, because the two failures look nothing
    alike from the outside: a row that appears without the entry is lost at the next launch, and an
    entry without a row is the failure this story's task names — it looks like the picker not
    working.
    """
    root = project("registered")
    app_kwargs = wired(tmp_path, root.parent)

    async with board(**app_kwargs) as (app, pilot):
        assert lines(app, "projects") == [], "the board began with a project already registered"

        await open_picker(pilot, app)
        await choose(app, pilot, root)

        assert not isinstance(app.screen, PickerScreen), "the picker stayed open after a good pick"

        painted = lines(app, "projects")

    registered = [entry.path for entry in list_projects(registry_file=registry(tmp_path))]

    assert registered == [str(root)], f"the registry does not hold the chosen project: {registered}"
    assert any(root.name in row for row in painted), (
        f"the project was registered but never reached the Projects column: {painted}"
    )


async def test_the_picker_refuses_a_directory_with_the_same_message_the_cli_gives(project, tmp_path):
    """Criterion 2 — one condition, one explanation, asserted by running both.

    The CLI's refusal is produced here rather than quoted, so the two affordances cannot drift into
    two different accounts of what is wrong with the directory.
    """
    root = project("not-a-project", database=False)
    err = StringIO()

    code = run_cli(
        ["add", str(root)], registry_file=registry(tmp_path), out=StringIO(), err=err
    )
    from_the_cli = err.getvalue().strip()

    assert code == 1 and from_the_cli, "the CLI accepted a directory that is not a dpm project"

    async with board(**wired(tmp_path, root.parent)) as (app, pilot):
        await open_picker(pilot, app)
        await choose(app, pilot, root)

        still_open = isinstance(app.screen, PickerScreen)
        painted = lines(app, "picker-refusal") if still_open else []

    assert still_open, "the picker closed on a directory it should have refused"

    # Compared with the whitespace taken out of both. The panel is 72 columns and the message
    # carries an absolute path, so it wraps — at a space in one place and mid-path in another, and
    # where a line happens to break is the panel's width rather than anything about the message.
    assert squashed(painted) == squashed([from_the_cli]), (
        f"the picker says {painted} where the CLI says {from_the_cli!r}"
    )

    registered = list_projects(registry_file=registry(tmp_path))

    assert registered == [], f"a refused directory was registered anyway: {registered}"


async def test_cancelling_the_picker_registers_nothing(project, tmp_path):
    """`escape` is a cancel, and a cancel is not a quiet registration of whatever was under the
    cursor."""
    root = project("untouched")

    async with board(**wired(tmp_path, root.parent)) as (app, pilot):
        await open_picker(pilot, app)

        tree = app.screen.query_one(ProjectTree)
        tree.move_cursor(next(child for child in tree.root.children if child.data.path == root))

        await pilot.press("escape")
        await pilot.pause()

        closed = not isinstance(app.screen, PickerScreen)
        painted = lines(app, "projects")

    assert closed, "escape left the picker open"
    assert list_projects(registry_file=registry(tmp_path)) == [], "a cancel registered a project"
    assert painted == [], f"a cancel put a row on the board: {painted}"


async def test_registering_leaves_the_projects_already_read_alone(project, tmp_path):
    """"In place" — the board does not go back to `reading…` because one project was added.

    Asserted as *identity*: the row objects for the projects already on the board are the same
    objects afterwards, so nothing re-read them. A re-survey would replace them with equal-looking
    rows, which a value comparison would accept.
    """
    first = project("already-here")
    second = project("newly-added")
    file = registry(tmp_path)
    add_project(str(first), None, registry_file=file)

    async with board(**wired(tmp_path, first.parent)) as (app, pilot):
        # Stand the first row up as *read* — no survey is injected here, so nothing else will.
        app.rescan()
        app.selection.projects[0] = replace(app.selection.projects[0], pending=False)
        before = app.selection.projects[0]

        await open_picker(pilot, app)
        await choose(app, pilot, second)

        after = app.selection.projects
        painted = lines(app, "projects")

    assert after[0] is before, "an existing project's row was rebuilt by a registration"
    assert len(after) == 2, f"the new project did not join the column: {painted}"
    assert after[1].pending, "the newly registered project was not queued to be read"


def test_both_affordances_reach_the_same_registration():
    """FR1's two ways in, and the rule that keeps them one requirement.

    The picker is reachable by key *and* from the palette: only-bindable is found by reading the
    footer at the moment you happen to need it, and only-in-the-palette costs two keystrokes
    forever. Both routes name the same action, so neither can be wired to a second implementation.
    """
    from board import COMMANDS, BoardApp

    keys = {binding[1] for binding in BoardApp.BINDINGS}
    palette = {command.action for command in COMMANDS}

    assert "register" in keys, f"no key opens the picker: {BoardApp.BINDINGS}"
    assert "register" in palette, f"the palette does not offer the picker: {sorted(palette)}"
