"""Story 4 — the footer and the palette say what the board actually does (FR19).

Stories 1 and 3 settled which key reaches what. This is the half a user reads: a key map nobody can
see is a key map nobody uses, and the two boards agreeing on `a` while one calls it *Add* and the
other *Register a project* leaves the muscle memory intact and the eye retraining every time.

**The footer is read from the widgets it built, never from `BINDINGS`.** That is not fussiness — it
is the failure this story found. `OptionList` inherits horizontal scroll bindings, and while a
column has focus they sit nearer than the app's own, so Textual answered `left` with "Scroll Left"
carrying `show=False` and the footer printed neither arrow. Every key worked; two of them were
undocumented. A test comparing the binding table with itself reports a footer that never appeared.
"""

from __future__ import annotations

from key_maps import SAME_MEANING, cpm_bindings, cpm_labels
from pilot import board, footer

from board import COMMANDS, BoardApp

#: This board's map, as the three things each binding is: a key, an action, and a footer label.
BINDINGS = [tuple(binding) for binding in BoardApp.BINDINGS]


def shared() -> dict[str, str]:
    """The keys both boards bind to the same capability, to the CPM board's label for it.

    Translated through :data:`key_maps.SAME_MEANING` before the comparison, so a capability the two
    boards named differently is still recognised as one — which is the case criterion 1 is *for*.
    A dpm extra is absent from this map and free to be labelled however it likes, having nothing on
    the other board to match.
    """
    cpm, labels = cpm_bindings(), cpm_labels()
    mine = {key: action for key, action, *_ in BINDINGS}

    return {
        key: labels[key]
        for key, action in cpm.items()
        if key in mine and mine[key] == SAME_MEANING.get(action, action)
    }


async def test_the_footer_shows_every_bound_key_in_the_cpm_boards_words():
    """Criterion 1 [feature], from the footer the running board built.

    Both halves in one test because they are one claim about one artefact: a footer that documented
    every key in the wrong words and one that used the right words for half of them are the same
    failure to a user looking for `x`.
    """
    async with board([]) as (app, _):
        printed = footer(app)

    assert set(printed) == {key for key, *_ in BINDINGS}, (
        "the footer and the binding table do not hold the same keys — missing "
        f"{sorted({key for key, *_ in BINDINGS} - set(printed))}, extra {sorted(set(printed) - {key for key, *_ in BINDINGS})}"
    )

    borrowed = shared()

    assert borrowed, "no key was read as shared with the cpm board, so nothing below is being checked"

    differing = {
        key: (label, printed[key]) for key, label in borrowed.items() if printed[key] != label
    }

    assert differing == {}, "\n".join(
        f"`{key}` reads {mine!r} here and {theirs!r} on the cpm board"
        for key, (theirs, mine) in differing.items()
    )


def test_nothing_is_documented_that_no_key_or_entry_reaches():
    """Criterion 2's first direction [unit]. A label for an action the app does not have.

    Textual does not refuse a binding naming a missing action — it prints the label in the footer
    and does nothing when the key is pressed, which is the worst of both: the capability is
    advertised and absent. The palette is checked the same way and for the same reason.
    """
    missing = [
        (key, action)
        for key, action, *_ in BINDINGS
        if not hasattr(BoardApp, f"action_{action}")
    ]

    assert missing == [], f"the footer documents keys that reach nothing: {missing}"

    unreachable = [
        command.name for command in COMMANDS if not hasattr(BoardApp, f"action_{command.action}")
    ]

    assert unreachable == [], f"the palette offers entries that reach nothing: {unreachable}"


def test_no_bound_key_goes_undocumented():
    """Criterion 2's second direction [unit]. A key with no label never reaches the footer.

    Textual takes an empty description as *do not show*, so a binding written without one is a key
    that works and is documented nowhere. Asserted over the table rather than over the rendered
    footer because this is the property that has to hold for every binding whatever has focus —
    the rendered check above is about one screen, and this is about the map.

    Both directions are needed and neither is enough. A board with no bindings and no palette
    entries satisfies the test above completely.
    """
    undocumented = [(key, action) for key, action, *rest in BINDINGS if not (rest and rest[0])]

    assert undocumented == [], f"bound keys with nothing to print in the footer: {undocumented}"
