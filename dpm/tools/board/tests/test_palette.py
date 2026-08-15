"""Story 4 — the command palette opens on the board's own actions (FR18).

Both criteria are read from the palette's **rendered list**, not from the provider. A provider that
yields the right commands into a palette configured to show Textual's is a passing unit test and a
failing requirement, and FR18's whole content is which list a user is looking at when the palette
opens.

The system commands are *derived* rather than transcribed: `App.get_system_commands()` is the
source Textual's own provider reads, so the absence assertion goes on meaning what it means when
that set changes.
"""

from __future__ import annotations

from pilot import board, palette

from board import COMMANDS, BoardApp, BoardCommands


def names() -> list[str]:
    """The board's own commands, in the order the table declares them."""
    return [command.name for command in COMMANDS]


def system_commands(app) -> list[str]:
    """What Textual's default provider would have offered, asked of Textual rather than copied."""
    return [command.title for command in app.get_system_commands(app.screen)]


async def test_ctrl_p_opens_the_palette_on_the_boards_own_actions():
    """Criterion 1: the key opens it, and what it opens on is this board's actions.

    Both halves in one test because either alone passes on the wrong thing — a palette that opens
    on someone else's commands, or the board's commands in a palette no key reaches.
    """
    async with board() as (app, pilot):
        assert palette(app) == [], "the palette was already open before the key was pressed"

        await pilot.press("ctrl+p")
        await pilot.pause()
        await pilot.pause()

        offered = palette(app)

    assert offered, "ctrl+p opened nothing"

    # Row-exact, not substring: the palette paints a command's name and its help on separate
    # lines, and a substring test would let "Quit" match "Quit the board" in either direction.
    for name in names():
        assert name in offered, (
            f"the palette does not offer the board's {name!r} action: {offered}"
        )


async def test_the_palette_holds_no_textual_system_commands():
    """Criterion 2, and the one an unconfigured provider fails.

    Textual's palette shows its own system commands unless the provider set is *replaced*; adding
    a provider leaves the user to filter the board's actions out of a longer list, which is the
    behaviour FR18's word "straight" exists to rule out.
    """
    async with board() as (app, pilot):
        await pilot.press("ctrl+p")
        await pilot.pause()
        await pilot.pause()

        offered = palette(app)
        defaults = system_commands(app)

    assert defaults, "Textual offered no system commands, so this test asserts nothing"

    for title in defaults:
        assert title not in offered, (
            f"Textual's {title!r} system command is in the palette: {offered}"
        )


async def test_the_palette_is_the_boards_provider_and_nothing_beside_it():
    """The must-NOT in structural form: *replaced*, not extended.

    The rendered assertions above are about the commands that happen to exist today. This one is
    about the rule that keeps them true — a second provider added later shows up here rather than
    when someone notices a stranger in the list.
    """
    assert BoardApp.COMMANDS == {BoardCommands}, (
        f"the palette draws on providers besides the board's own: {BoardApp.COMMANDS}"
    )


def test_ctrl_p_is_the_boards_own_binding_rather_than_an_inherited_default():
    """FR18 names the key, so the board states it.

    Textual's default is `ctrl+p` today. A board that inherited it would satisfy the criterion
    above while having no opinion at all, and would follow the framework the day it moved.
    """
    from textual.app import App

    assert BoardApp.COMMAND_PALETTE_BINDING == "ctrl+p", (
        f"FR18's key is ctrl+p; the board binds {BoardApp.COMMAND_PALETTE_BINDING}"
    )
    assert "COMMAND_PALETTE_BINDING" in vars(BoardApp), (
        f"the board inherits its palette key from Textual (currently "
        f"{App.COMMAND_PALETTE_BINDING!r}) rather than stating it"
    )


async def test_every_offered_command_names_an_action_the_app_has():
    """A palette entry that cannot run is worse than an absent one.

    It reports a capability the board does not have, and the user's next move is to find out why
    nothing happened. The table is checked against the app rather than against a list of names,
    so an action renamed on one side and not the other fails here.
    """
    missing = [
        command.name
        for command in COMMANDS
        if not callable(getattr(BoardApp, f"action_{command.action}", None))
    ]

    assert missing == [], f"the palette offers commands the app has no action for: {missing}"
