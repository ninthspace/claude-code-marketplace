"""Both boards' key maps, and what it means for the two to agree (FR19).

Two boards are opened by the same people in the same week, so a key that refreshes on one and
removes a project on the other is worse than a key that does nothing at all: muscle memory does not
check which board it is looking at before it presses.

**The two sides are read differently, on purpose.** The dpm board's map is taken from the class
that runs — `BoardApp.BINDINGS` — because that is what answers a keystroke, and a second reading of
its source could agree with the file while disagreeing with the app. The CPM board's is parsed from
its source, because it belongs to a different application with its own dependencies and importing
it here would run somebody else's module to read a list of tuples.

**The repository's copy, never the plugin cache.** `~/.claude/plugins/cache/` holds installed
copies that are overwritten on update, so a check reading one asserts against a copy nobody edits —
green while the two boards in this repository drift apart, which is the failure the rejection in
story 5 names. The path below is relative to this file, so it can only reach the checkout it lives
in.
"""

from __future__ import annotations

import ast
from pathlib import Path

#: The marketplace checkout this file lives in: `dpm/tools/board/tests/support/` is five deep.
MARKETPLACE = Path(__file__).resolve().parents[5]

#: The CPM board's source, in the repository rather than in any installed copy of it.
CPM_BOARD = MARKETPLACE / "cpm" / "tools" / "board" / "board.py"

#: How each board titles the class holding its own key map. Both files also hold modal screens with
#: `BINDINGS` of their own — escape, y, n — and those are a dialog's keys rather than a board's.
CPM_TITLE = "cpm board"

#: What one board's action is called on the other, where the two names differ.
#:
#: **Names, not behaviour**, and that is the whole of what this table claims: `add_project` and
#: `register` open a picker that adds a project to the board, and the boards named it differently.
#: A key is in disagreement when it does a *different thing*, so a comparison over raw action names
#: would report four disagreements that are only spellings — and, worse, would go on reporting them
#: after somebody fixed the real ones, until nobody read the output.
#: `toggle_complete` and `toggle_retired` are here on slightly different grounds from the other
#: four, and it is worth saying which: they are the same *capability* over a wider set of states
#: rather than the same behaviour under two spellings. CPM hides `complete` because complete is the
#: only finished state its model has; dpm hides everything `status_model` calls finished, which
#: includes two statuses CPM has no word for. A user pressing `z` on either board is asking for the
#: same thing — take the finished work off the screen — and that is what this table is about.
SAME_MEANING = {
    "add_project": "register",
    "remove_project": "unregister",
    "copy": "copy_command",
    "open_plain": "open",
    "toggle_complete": "toggle_retired",
}


def app_bindings(source: Path, title: str) -> dict[str, str]:
    """The key map of the class in ``source`` whose ``TITLE`` is ``title``, as ``{key: action}``.

    Found by the title rather than by the class's name or by taking the longest `BINDINGS` in the
    file: a name is a thing somebody renames without meaning anything by it, and "the longest one"
    is a rule that quietly starts answering about a modal screen the day one grows a fifth key.
    """
    for node in ast.walk(ast.parse(source.read_text())):
        if not isinstance(node, ast.ClassDef):
            continue

        assigned = {
            target.id: statement.value
            for statement in node.body
            if isinstance(statement, ast.Assign)
            for target in statement.targets
            if isinstance(target, ast.Name)
        }
        named = assigned.get("TITLE")

        if not (isinstance(named, ast.Constant) and named.value == title):
            continue

        return {
            binding.elts[0].value: binding.elts[1].value
            for binding in assigned["BINDINGS"].elts
        }

    raise AssertionError(f"{source} holds no class titled {title!r}")


def cpm_bindings() -> dict[str, str]:
    """The CPM board's key map, read from the repository's own copy of its source."""
    return app_bindings(CPM_BOARD, CPM_TITLE)


def extras(cpm: dict[str, str], dpm: dict[str, str]) -> dict[str, str]:
    """The dpm board's own capabilities — the actions the CPM board has no equivalent of.

    Translated through :data:`SAME_MEANING` before the comparison, so a capability both boards have
    under two names is not reported as one board's extra and then required to move off a key it is
    entitled to share.
    """
    shared = {SAME_MEANING.get(action, action) for action in cpm.values()}

    return {key: action for key, action in dpm.items() if action not in shared}


def extras_on_cpm_keys(cpm: dict[str, str], dpm: dict[str, str]) -> dict[str, str]:
    """The dpm-only capabilities sitting on a key the CPM board binds, as ``{key: action}``.

    The same rule as :func:`disagreements` read from the other end, and it is worth having both:
    that one asks what each of CPM's keys does here, and this asks where each of this board's own
    capabilities has been put. A key CPM does not bind at all is free — that is the whole point of
    an extra — and the ones this returns are the extras that took a key already spoken for.
    """
    return {key: action for key, action in extras(cpm, dpm).items() if key in cpm}


def disagreements(cpm: dict[str, str], dpm: dict[str, str]) -> dict[str, tuple[str, str]]:
    """The keys the two boards both bind and bind to different things, as ``{key: (cpm, dpm)}``.

    **Over the intersection, which is what makes this a rejection rather than an equality.** A key
    the dpm board does not bind at all is not a key that does something else; a capability the dpm
    board has and CPM does not is free to take any key CPM leaves alone. Written as an equality
    between the two maps this would fail every time either board gained anything, which is a change
    detector wearing a rejection's clothes — it would be silenced rather than fixed.
    """
    return {
        key: (action, dpm[key])
        for key, action in cpm.items()
        if key in dpm and dpm[key] != SAME_MEANING.get(action, action)
    }
