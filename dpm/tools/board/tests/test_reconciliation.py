"""Story 5 — `dpm:status` reconciled against the contract (AD5).

The board's half of AD5 is checkable directly: `DERIVATIONS` is an enumeration the code built, and
it either matches the contract's rule names or it does not. The skill's half is not. It is prose,
and no parse distinguishes a passage that agrees with a rule from one that never met it — which is
also the failure mode AD5 exists to prevent, since a skill that never met a rule reads fine.

What *is* checkable is that every rule was looked at, and that is what the disposition table in
`docs/maintenance/README.md` asserts. A rule added to the contract later fails until someone says
what happened to `dpm:status` under it.

The second criterion — amended only where the skill contradicts the contract — is checked from both
ends: the amendments the record claims are present and agree with the board's own constants, and the
passages the story was bounded away from are still there.
"""

from __future__ import annotations

from contract import (
    RECORD,
    reconcile_dispositions,
    record_dispositions,
    recorded_dispositions,
    skill_text,
    stated_rules,
)

from status_model import CANDIDATE_KINDS

#: The command `dpm:status` recommends for each of the contract's candidate kinds. The mapping is
#: the skill's; the *order* is not, which is what makes the assertion below a cross-check rather
#: than a transcription — `CANDIDATE_KINDS` is the board's constant and the table is the skill's.
COMMANDS = {
    "epic_ready": "/dpm:do",
    "spec_without_epics": "/dpm:epics",
    "retro_missing": "/dpm:retro",
}

#: The recommendation table's header, which is how the table is found in the prose around it.
RECOMMENDATIONS = "| What the rows say | What to recommend |"


def recommendation_rows(text: str) -> list[str]:
    """The recommendation table's rows, in the order `dpm:status` prints them.

    The *table*, not the file. The paragraph above it names all three commands in the contract's
    order while explaining that the order is the contract's, so a search over the whole text finds
    the sentence about the table rather than the table, and passes with the rows in any order at
    all.
    """
    assert RECOMMENDATIONS in text, "the skill's recommendation table is not where this looks"

    body = text.split(RECOMMENDATIONS, 1)[1].split("\n\n", 1)[0]

    return [line for line in body.splitlines() if line.strip().startswith("|")][1:]


def test_every_contract_rule_carries_a_disposition():
    """Criterion 1, over the live sets: the contract on disk, and the record on disk."""
    complaints = reconcile_dispositions(recorded_dispositions(), stated_rules())

    assert complaints == [], "the record and the contract disagree: " + "; ".join(complaints)
    assert recorded_dispositions(), "the record dispositioned nothing, so this inspected nothing"


def test_a_rule_added_to_the_contract_fails_until_it_is_dispositioned():
    """Planted: the direction that matters most, because it is the one time passes in.

    A rule written into the contract is a rule `dpm:status` has not been read against. Nothing
    about the skill changes when that happens, so nothing about the skill can signal it.
    """
    complaints = reconcile_dispositions(recorded_dispositions(), [*stated_rules(), "freshness"])

    assert complaints == [
        "the contract states 'freshness' and the record gives it no disposition"
    ]


def test_a_disposition_for_a_rule_the_contract_no_longer_states_fails():
    """The other direction — a rule dropped from the contract, leaving its disposition behind."""
    dispositions = {**recorded_dispositions(), "freshness": "conformed"}

    complaints = reconcile_dispositions(dispositions, stated_rules())

    assert complaints == [
        "the record dispositions 'freshness' and the contract does not state it"
    ]


def test_a_disposition_that_does_not_say_what_happened_fails():
    """The cell is prose, so the check on its content is thin — but not nothing.

    Requiring an enum would cost the reasons the record exists to carry. Requiring that the cell
    reach for one of *conformed*, *amended* or *left alone* still rejects the way this decays in
    practice: a row added to keep the count right, with a cell that reads as consideration.
    """
    dispositions = {**recorded_dispositions(), "readiness": "reviewed"}

    complaints = reconcile_dispositions(dispositions, stated_rules())

    assert complaints == [
        "'readiness' carries a disposition that does not say what happened to it: 'reviewed'"
    ]


def test_the_floor_rejects_two_empty_sets():
    """must NOT — the reconciliation passes over an empty rule set on either side.

    With one side populated the per-rule loops complain anyway, so a one-sided check would pass
    with the floor deleted. Nothing in a set-difference is wrong about `{} == {}`.
    """
    assert reconcile_dispositions({}, []), "a reconciliation of nothing against nothing passed"
    assert reconcile_dispositions({}, stated_rules()), "a record dispositioning nothing passed"
    assert reconcile_dispositions(recorded_dispositions(), []), "an empty contract passed"


def test_the_parse_finds_nothing_in_a_file_that_records_nothing():
    """The control for the parse, which is the input the floor above is protecting against.

    A renamed section is the realistic way the record stops being read: the reconciliation goes on
    passing against an empty dict, and nothing about its result reads as wrong.
    """
    assert record_dispositions("# Notes\n\n| readiness | conformed |\n") == {}

    table = (
        "## `dpm:status` ↔ `dpm/tools/board` — the status-model reconciliation record\n\n"
        "| Contract rule | Disposition | What happened |\n"
        "|---|---|---|\n"
        "| readiness | conformed | Nothing to change. |\n\n"
        "## A later section\n\n"
        "| readiness | amended | A table that is not the record. |\n"
    )

    assert record_dispositions(table) == {"readiness": "conformed"}


def test_the_skill_recommends_the_candidate_kinds_in_the_contracts_order():
    """Criterion 2 for *candidate ordering*, cross-checked against the board's own constant.

    The record says the table was reordered; this is what that claim means. The order comes from
    `CANDIDATE_KINDS` in the board, the table comes from the skill, and neither transcribes the
    other — so a reordering of either side alone fails.

    Rows carrying commands the contract has no kind for — `/dpm:discover` on an empty project — sit
    between them and are not asserted, because the contract does not claim them.
    """
    rows = recommendation_rows(skill_text("status"))
    at = {
        kind: next((index for index, row in enumerate(rows) if COMMANDS[kind] in row), -1)
        for kind in CANDIDATE_KINDS
    }

    for kind, position in at.items():
        assert position >= 0, f"no row of the table recommends {COMMANDS[kind]} (for {kind})"

    ordered = sorted(at, key=lambda kind: at[kind])

    assert ordered == list(CANDIDATE_KINDS), (
        f"the skill's recommendations run {ordered}, the contract's order is "
        f"{list(CANDIDATE_KINDS)}"
    )


def test_the_skill_asks_for_readiness_rather_than_inferring_it():
    """Criterion 2 for *readiness* and *blocking* — the contradiction the record names.

    The skill offered `/dpm:do` without asking dpm's own filter, so an epic held by a blocker was
    recommended as workable. The amendment is the `ready` argument and the blocker being named from
    a row; both are asserted here because the record claims them.
    """
    text = skill_text("status")

    assert "Readiness is asked for, not inferred from the stories" in text
    assert "mcp__plugin_dpm_dpm__list_dependency" in text, (
        "the skill names no way to say what holds a blocked epic"
    )
    assert "dpm/shared/status-model.md" in text, "the amended skill cites no contract"


def test_the_passages_the_story_was_bounded_away_from_are_still_there():
    """Criterion 2's *only*: the amendments are amendments, not a rewrite.

    The spec bounds this story to contradictions with the contract; `dpm:status`'s narrative,
    artifact and coverage-rollup behaviour are out of scope. Those passages have no counterpart in
    the contract, so nothing in the reconciliation would have complained had they been rewritten
    along the way — which is exactly why the bound needs its own check.
    """
    text = skill_text("status")

    for passage in (
        "Phase 3b: Spec coverage roll-up",
        "**Never a proportion.**",
        "aggregation, not verification",
        "An artifact can be published from this output on request",
        "narrative rather than a data dump",
    ):
        assert passage in text, f"a passage out of this story's scope is gone: {passage!r}"


def test_the_record_is_where_the_maintenance_records_live():
    """`CLAUDE.md` gives maintenance records one home, and this one is a maintenance record.

    Checked because the path is reached from a test five directories down and would otherwise be a
    silent assumption: a record moved under `dpm/` would leave this suite reading a file that no
    longer exists, which fails loudly, but a *second* record left behind here would not.
    """
    assert RECORD.name == "README.md"
    assert RECORD.parent.name == "maintenance"
    assert RECORD.exists(), f"the reconciliation record is not at {RECORD}"
