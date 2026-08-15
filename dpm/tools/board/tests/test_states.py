"""Story 1 — the four named per-project states (FR11, ENV2).

Three of FR11's four conditions arrive as **the same symptom**: a project with no rows. A board
that named them all `server-failed` would satisfy every criterion written as "renders a named
state", and the user would be told to read a server's diagnostics when what they need is a newer
plugin, or a newer Node, or a database at all. So every test here asserts on *which* state and on
the remedy that came with it, and the last one asserts that no two of them come out the same.

**Each condition is produced, not simulated** — see ``support/failures.py``, which builds them for
this story and for Story 2's mixed registry. The missing database is a directory without one; the
schema-ahead case is a real dpm database with a version row above the server's own, read by the
real `bin/dpm-mcp.js`; the Node floor is dpm's own `assertNodeFloor` refusing, so the refusal text
is the one dpm actually writes rather than a sentence transcribed here (Task 1.4). The one stub is
a server that exits at once, which is a stub only in that nothing else about it matters.
"""

from __future__ import annotations

import ast
from pathlib import Path
from shutil import which

import pytest
from conftest import DPM_ROOT
from failures import BELOW_THE_FLOOR, ahead, exiting_server, floor_version, old_node
from pilot import board, lines

from board import survey_project
from board_view import ProjectView, style_collisions
from mcp_client import (
    DIAGNOSTIC_STATES,
    NO_DATABASE,
    NODE_TOO_OLD,
    REMEDIES,
    SCHEMA_AHEAD,
    SERVER_FAILED,
    SERVER_MISSING,
    SURFACE_MISMATCH,
    ServerPool,
    Unreadable,
    server_path,
)

#: Where each state's signature has to be found in dpm's own source. The board's copies are
#: fragments of sentences dpm builds; this is what makes a rewording over there fail over here
#: rather than silently retiring a state.
DPM_SOURCES = ("src/server/index.js", "src/server/node-floor.js")

#: FR11's enumeration, and the two states the board adds for conditions of its own.
#:
#: Written as {state: the words the requirement uses} so both halves can be checked: that the
#: phrase is still in the spec, and that the set of states the board has remedies for is exactly
#: this set — a state added to the board with nothing requiring it fails as loudly as one removed.
REQUIRED_STATES = {
    # The article is left off each phrase: FR11 opens its sentence with one of them, so "a missing"
    # is "A missing" in the document and matching it would fail on the capital.
    NO_DATABASE: "missing `.dpm/dpm.db`",
    SCHEMA_AHEAD: "schema version ahead of the server",
    NODE_TOO_OLD: "Node below dpm's floor",
    SERVER_FAILED: "server that fails to start",
    # NFR5's state and the board's own: dpm has no requirement about a board that cannot find it.
    SURFACE_MISMATCH: None,
    SERVER_MISSING: None,
}

#: FR11's body, where the four phrases above have to appear.
SPEC = DPM_ROOT.parent / "docs" / "specifications" / "48-spec-dpm-board.md"


async def state_of(root: Path, *, pool: ServerPool) -> ProjectView:
    """The row one project ends up as, through the board's own survey."""
    async with pool:
        return await survey_project(pool, ProjectView(name=root.name, path=root, pending=True))


async def painted(view: ProjectView) -> str:
    """What the Projects column actually paints for that row.

    The criterion is about what renders, and a view carrying a state that no row shows is a state
    nobody is told about — the same nothing as a board that never classified it.
    """
    async with board([view]) as (app, _):
        return next(iter(lines(app, "projects")), "")


async def test_a_project_with_no_database_renders_its_state_and_remedy(project):
    """Criterion 1. The row names the state *and* what to do about it.

    Both halves are asserted from the painted row rather than from the view: a remedy the board
    holds and does not show is FR11 unsatisfied in the only place it matters.
    """
    view = await state_of(project("bare", database=False), pool=ServerPool(server_path()))
    row = await painted(view)

    assert view.unreadable == NO_DATABASE, f"a project with no database is {view.unreadable!r}"
    assert NO_DATABASE in row, f"the row does not name the state: {row!r}"
    assert REMEDIES[NO_DATABASE] in row, f"the row names a state with no remedy: {row!r}"


async def test_a_database_ahead_of_the_server_renders_a_distinct_state(fixture_project):
    """Criterion 2, over the real server and a real database it will not fully understand.

    **This is the state with no protocol-level symptom.** The server does not refuse an ahead
    database: it serves it read-only and says so on stderr, so every read succeeds and the project
    renders as one that simply holds less work. That is why the assertion below is on the state and
    not on an error, and why the board watches diagnostics at all.
    """
    # Renamed short: a Miller column clips, and `fixture-project` spends most of the row's width on
    # a name. The clipping is real — it is why the remedies are short — and a test asserting a
    # remedy is not the place to also assert how much of it a long name leaves room for.
    root = fixture_project.rename(fixture_project.parent / "ahead")
    view = await state_of(ahead(root), pool=ServerPool(server_path()))
    row = await painted(view)

    assert view.unreadable == SCHEMA_AHEAD, (
        f"a database from a newer dpm rendered as {view.unreadable!r}"
    )
    assert REMEDIES[SCHEMA_AHEAD] in row, f"the row names a state with no remedy: {row!r}"


async def test_a_server_that_exits_immediately_renders_a_third_state(project, tmp_path):
    """Criterion 3. The state for a failure the board has no signature for.

    It is the fallback, and that is the point of asserting it separately: if this were the answer
    to everything the other three tests would still pass one at a time, and the fourth criterion is
    the only thing that would notice.
    """
    view = await state_of(
        project("dead"), pool=ServerPool(exiting_server(tmp_path), node="python3")
    )
    row = await painted(view)

    assert view.unreadable == SERVER_FAILED, f"a server that exited rendered as {view.unreadable!r}"
    assert REMEDIES[SERVER_FAILED] in row, f"the row names a state with no remedy: {row!r}"


async def test_a_node_below_dpms_floor_is_captured_and_rendered(project, tmp_path):
    """ENV2's criterion: the executable's refusal is captured, and rendered per FR11.

    Two things, and they land in different places. The *rendered* half is the named state with its
    remedy, which is what a column has room for. The *captured* half is dpm's own sentence — naming
    the version found and the version required — which the board keeps as the occurrence's detail;
    without it the board would be able to say Node is too old and not which Node.
    """
    if which("node") is None:
        pytest.skip("no node on PATH to build the refusal from dpm's own source")

    root = project("old-node")
    view = await state_of(root, pool=ServerPool(server_path(), node=str(old_node(tmp_path))))
    row = await painted(view)
    captured = None

    async with ServerPool(server_path(), node=str(old_node(tmp_path))) as pool:
        try:
            await pool.read(root, "list_epic")
        except Unreadable as refusal:
            captured = refusal

    assert view.unreadable == NODE_TOO_OLD, (
        f"a Node below dpm's floor rendered as {view.unreadable!r}"
    )
    assert REMEDIES[NODE_TOO_OLD] in row, f"the row names a state with no remedy: {row!r}"

    # The captured half. `str(...)` is what `board.py list` prints for a row, so this is the text a
    # user sees rather than a field only this test knows about — and it has to be the executable's
    # own sentence: "the server closed its stdout" is what the client saw, is true, and is not why.
    required = floor_version()

    assert required, "dpm's Node floor could not be read, so the assertion below names no version"
    assert captured is not None, "the refusal never reached the board as a state"
    assert BELOW_THE_FLOOR in str(captured) and required in str(captured), (
        f"the refusal was not captured — the versions did not reach the row: {captured}"
    )


def reconcile(remedies: dict[str, str], required: dict[str, str | None]) -> list[str]:
    """Both directions, with a floor — the states with remedies against the states there must be.

    Returns complaints rather than asserting, so the floor can be driven over nothing at all. That
    case is the one a set difference cannot fail on: with either side populated the loops complain
    anyway, and only nothing-against-nothing distinguishes a reconciliation from a no-op.
    """
    complaints = [
        f"{state} is required and the board has no remedy for it"
        for state in required
        if state not in remedies
    ]
    complaints += [
        f"{state} has a remedy and nothing requires it" for state in remedies if state not in required
    ]
    complaints += [f"{state}'s remedy is empty" for state, remedy in remedies.items() if not remedy]

    if not remedies and not required:
        complaints.append("nothing was reconciled against nothing")

    return complaints


def test_the_states_are_exactly_the_ones_the_requirements_name():
    """Criterion 5's first half: the enumeration, checked in both directions and with its floor."""
    assert reconcile(REMEDIES, REQUIRED_STATES) == [], "the board's states and FR11's disagree"
    assert reconcile({}, {}), "the reconciliation passes on nothing against nothing"
    assert reconcile({}, REQUIRED_STATES), "a board with no states at all reconciles clean"


def test_fr11s_own_wording_still_names_the_four_conditions():
    """The other side of the enumeration is a document, so it is read rather than remembered.

    A condition dropped from or reworded in FR11 fails here — which is the point: the board's four
    states are answerable to the requirement, and a requirement that changed underneath them would
    otherwise leave a state nothing asks for and a condition nothing renders.
    """
    # Whitespace-normalised, because the requirement is wrapped: two of the four phrases straddle a
    # line break in the document and neither is about how the paragraph was laid out.
    requirement = " ".join(SPEC.read_text().split())
    missing = [words for words in REQUIRED_STATES.values() if words and words not in requirement]

    assert SPEC.is_file(), f"no spec at {SPEC}, so this test read nothing"
    assert not missing, f"FR11 no longer names: {missing}"


def test_no_two_states_render_the_same_row():
    """Criterion 5's second half, over the row a user actually compares.

    Distinct *names* are not the requirement — two states are distinguishable only if what they put
    on screen differs, and the row is state and remedy together. The planted control is two states
    sharing a remedy, which is exactly the shape a fifth state added by copying a fourth takes.
    """
    rows = {
        state: ProjectView(name="p", path=Path("/p"), unreadable=state, remedy=remedy).label
        for state, remedy in REMEDIES.items()
    }

    assert style_collisions(rows) == [], "two named states render as the same row"
    assert style_collisions({**rows, "invented": rows[SERVER_FAILED]}), (
        "two states rendering identically produced no complaint, so the check above is idle"
    )


def signatures_in(source: str) -> list[str]:
    """Which of the board's diagnostic signatures appear in one file of dpm's source."""
    return [signature for signature, _ in DIAGNOSTIC_STATES if signature in source]


def test_every_diagnostic_signature_is_dpms_own_wording():
    """The classification reads dpm's stderr, so its fragments are checked against dpm's source.

    Without this the two states that are read from diagnostics degrade silently: dpm rewords a log
    line, the board stops matching it, and the project renders as `server-failed` — or, for the
    schema-ahead case, as a perfectly ordinary project with less work in it than it has.
    """
    found: list[str] = []

    for relative in DPM_SOURCES:
        source = (DPM_ROOT / relative)

        assert source.is_file(), f"no {relative} under {DPM_ROOT}, so this test read nothing"

        found += signatures_in(source.read_text())

    unmatched = [signature for signature, _ in DIAGNOSTIC_STATES if signature not in found]

    assert not unmatched, f"the board looks for wording dpm does not write: {unmatched}"
    assert not signatures_in("a source file that says nothing of the kind"), (
        "the search matches a file that contains none of the signatures"
    )


def test_the_state_names_are_not_built_from_each_other():
    """A guard on the constants themselves: no state's name contains another's.

    `style_collisions` compares whole rows, so two states whose names differ by a suffix render
    differently and pass it — while a `in` test anywhere else in the board (or in a test) would
    match both. The states are compared as text here because that is how everything downstream
    finds them.
    """
    overlapping = [
        f"{one} contains {other}"
        for one in REMEDIES
        for other in REMEDIES
        if one != other and other in one
    ]

    assert not overlapping, f"one state's name is inside another's: {overlapping}"


def test_the_board_names_no_state_it_has_no_remedy_for():
    """Every `Unreadable(...)` raised with a named constant is a state `REMEDIES` knows.

    Swept from the source rather than from a list, so a state raised by a path this file never
    drives is still held to the pair. A raise with a *computed* state — the classifier's own, which
    is the point of it — is a local variable rather than one of this module's constants, and is
    skipped by the upper-case test below; that path is covered by the four integration tests above,
    each of which asserts the state it produced.
    """
    raised: set[str] = set()

    for module in sorted(Path(__file__).resolve().parent.parent.glob("*.py")):
        for node in ast.walk(ast.parse(module.read_text())):
            called = isinstance(node, ast.Call) and getattr(node.func, "id", "") == "Unreadable"

            if called and node.args and isinstance(node.args[0], ast.Name):
                named = node.args[0].id

                if named.isupper():
                    raised.add(named)

    unknown = sorted(name for name in raised if globals().get(name) not in REMEDIES)

    assert raised, "the sweep found no Unreadable raised anywhere, so it inspected nothing"
    assert not unknown, f"the board raises states with no remedy: {unknown}"
