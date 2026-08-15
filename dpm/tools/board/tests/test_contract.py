"""Story 4 — the derivation contract, reconciled against the board (AD5).

The load-bearing test is the two-way reconciliation: every rule the board implements appears in
`dpm/shared/status-model.md`, and every rule the contract states is implemented. It has two ways of
passing for nothing — a contract nothing parses out of, and a board that registered no derivations —
so the floor is checked on planted inputs, because once the live sets agree they can no longer tell
a working check from a vacuous one.

The rules the contract must state are named in the criterion itself, so those are asserted by name
as well. That is not a transcription test: it fails when a rule is dropped from the document, which
is the direction the reconciliation alone cannot see (dropping a rule from *both* sides leaves them
agreeing).
"""

from __future__ import annotations

from contract import CONTRACT, contract_rules, reconcile_rules, stated_rules

from status_model import DERIVATIONS

#: The rules AD5's criterion names, as the contract writes them, plus the ones added since.
#:
#: `untraced requirements` is 48-08's, and it is in this list rather than merely in `DERIVATIONS`
#: for the reason the list exists at all: a rule dropped from *both* sides leaves the reconciliation
#: agreeing, so the document needs one place that says the rule is expected to be there.
REQUIRED = [
    "readiness",
    "blocking",
    "retired blockers",
    "in progress",
    "progress counts",
    "untraced requirements",
    "candidate ordering",
]


def test_the_contract_states_every_rule_the_criterion_names():
    """Criterion 1. Dropping a rule from both sides leaves the reconciliation agreeing."""
    assert stated_rules() == REQUIRED, (
        f"the contract's rules are not the expected names, in order: {stated_rules()}"
    )


def test_the_contract_states_each_rule_in_rows_and_tool_calls():
    """AD5's "expressed in rows and tool calls" — the contract's own inputs table.

    A contract written as narrative would satisfy the reconciliation perfectly while telling a
    reader nothing they could implement from. Every input this model has is a `list_*` call, and
    the table naming them is what makes the rules below it checkable rather than evocative.
    """
    text = CONTRACT.read_text()

    for call in ("list_epic", "list_story", "list_spec", "list_retro", "list_dependency",
                 "list_dependency_kind", "list_requirement", "list_coverage"):
        assert call in text, f"the contract names no tool call for {call}"

    assert "`ready: true`" in text, "the contract does not say how readiness is asked for"
    assert "`include_retired: true`" in text, "the contract omits the flag a retired kind needs"


def test_the_board_and_the_contract_agree_in_both_directions():
    """Criterion 2, over the live sets: the enumeration the code built, and the document on disk."""
    complaints = reconcile_rules(DERIVATIONS, stated_rules())

    assert complaints == [], "the board and the contract disagree: " + "; ".join(complaints)
    assert DERIVATIONS, "the board registered no derivations, so the check above inspected nothing"


def test_a_rule_the_board_derives_and_the_contract_omits_fails():
    """The first direction, planted — a derivation added to the board and never written down."""
    complaints = reconcile_rules({**DERIVATIONS, "freshness": ["stamp"]}, stated_rules())

    assert complaints == [
        "the board derives 'freshness' (stamp) and the contract does not state it"
    ]


def test_a_rule_the_contract_states_and_the_board_omits_fails():
    """The second direction, planted — a rule written into the contract with no implementation."""
    complaints = reconcile_rules(DERIVATIONS, [*stated_rules(), "freshness"])

    assert complaints == ["the contract states 'freshness' and nothing in the board implements it"]


def test_the_floor_rejects_a_board_with_no_derivations():
    """The must-NOT, first direction: two empty sets agree perfectly."""
    complaints = reconcile_rules({}, stated_rules())

    assert complaints, "a board implementing nothing passed the reconciliation"
    assert "no derivation rules" in complaints[0]


def test_the_floor_rejects_a_contract_with_no_rules():
    """The must-NOT, second direction — and the shape a broken parse takes.

    A parse that matches nothing is the realistic way this happens: the section is renamed, the
    heading depth changes, and the reconciliation goes on passing while checking an empty list
    against a full one. Nothing about it reads as wrong from its result.
    """
    complaints = reconcile_rules(DERIVATIONS, [])

    assert complaints, "an empty contract passed the reconciliation"
    assert "states no rules" in complaints[0]


def test_the_floor_rejects_two_empty_sets():
    """The must-NOT in its bare form, and the only case a comparison alone cannot fail on.

    With one side populated the per-rule loops complain anyway, so the two tests above would pass
    with the floor deleted. Nothing in a set-difference is wrong about `{} == {}` — the floor is a
    separate claim, that a reconciliation which inspected nothing is not evidence.
    """
    assert reconcile_rules({}, []), "a reconciliation of nothing against nothing passed"


def test_the_parse_finds_nothing_in_a_document_that_states_nothing():
    """The control for the parse itself, which is the input the floor above is protecting against."""
    assert contract_rules("# A document\n\n### readiness\n\nWith no rules section.\n") == []
    assert contract_rules("## Derivation rules\n\n### readiness\n\nA rule.\n") == ["readiness"]


def test_rules_from_a_later_section_are_not_read_as_derivations():
    """The parse is scoped, so a section growing subheadings does not add rules nothing implements."""
    text = (
        "## Derivation rules\n\n### readiness\n\nA rule.\n\n"
        "## Graceful degradation\n\n### no-database\n\nNot a derivation rule.\n"
    )

    assert contract_rules(text) == ["readiness"]
