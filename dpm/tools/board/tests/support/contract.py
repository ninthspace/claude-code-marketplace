"""Reading AD5's contract, and reconciling it against its two consumers.

Against the board that is `DERIVATIONS` — an enumeration the code built. Against `dpm:status` it is
the disposition table in `docs/maintenance/README.md`, because the skill is prose and there is no
enumeration to derive from it.


**Why this is not a test that asserts the document says what it says.** The obvious way to verify a
written contract is to check it contains certain sentences, which tests the transcription and
nothing else — it stays green while the code walks away from the document it is quoting. What
happens here instead is that two independently derived enumerations are compared: the rule headings
the contract states, and the rule names the board registered in ``DERIVATIONS`` at import. Either
side moving alone fails.

**It lives in test support rather than in the board.** Nothing at runtime needs to read the
contract, and a board module that opened a file would widen the very surface FR2's sweeps bound.

``reconcile_rules`` returns complaints rather than asserting, so the must-NOT can drive the real
reconciliation on planted inputs instead of restating its rules in a second place — a control that
reimplements what it guards tests the reimplementation.
"""

from __future__ import annotations

import re
from pathlib import Path

#: The contract, relative to this file: ``dpm/tools/board/tests/support`` → ``dpm/shared``.
CONTRACT = Path(__file__).resolve().parents[4] / "shared" / "status-model.md"

#: The section whose subheadings are the rule names, and the heading depth they sit at.
RULES_SECTION = "## Derivation rules"
RULE_HEADING = re.compile(r"^### (.+)$", re.MULTILINE)

#: The reconciliation record, relative to this file: ``dpm/tools/board/tests/support`` → the
#: repository root. It sits above ``dpm/`` rather than inside it because ``CLAUDE.md`` gives
#: maintenance records a single home, and dpm already keeps three of its own there.
RECORD = Path(__file__).resolve().parents[5] / "docs" / "maintenance" / "README.md"

#: The record's own section, and the header cell above the rule names.
RECORD_SECTION = "## `dpm:status` ↔ `dpm/tools/board` — the status-model reconciliation record"
RECORD_HEADER = "Contract rule"

#: What a disposition has to say happened. The cell is prose otherwise — it is written for a
#: reader, and flattening it to an enum would cost the reasons that are the point of the record —
#: but one that reaches for none of these words has not dispositioned anything.
OUTCOMES = ("conformed", "amended", "left alone")


def contract_rules(text: str) -> list[str]:
    """The rule names the contract states, in the order it states them.

    Scoped to the *Derivation rules* section rather than every ``###`` in the file, so a later
    section growing subheadings of its own does not silently add rules nothing implements.
    """
    if RULES_SECTION not in text:
        return []

    body = text.split(RULES_SECTION, 1)[1].split("\n## ", 1)[0]

    return [heading.strip() for heading in RULE_HEADING.findall(body)]


def stated_rules() -> list[str]:
    """The rules the contract on disk states."""
    return contract_rules(CONTRACT.read_text())


def skill_text(name: str) -> str:
    """A skill's source, for the assertions that check what the record claims was amended."""
    return (Path(__file__).resolve().parents[4] / "skills" / name / "SKILL.md").read_text()


def record_dispositions(text: str) -> dict[str, str]:
    """Rule name → what the reconciliation record says happened to it.

    Scoped to the record's own section, for the same reason the rule parse is scoped: the file
    holds other tables, and reading them would disposition rules nobody dispositioned.
    """
    if RECORD_SECTION not in text:
        return {}

    body = text.split(RECORD_SECTION, 1)[1].split("\n## ", 1)[0]
    dispositions = {}

    for line in body.splitlines():
        if not line.strip().startswith("|"):
            continue

        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]

        if len(cells) < 2 or cells[0] == RECORD_HEADER or set(cells[0]) <= set("-: "):
            continue

        dispositions[cells[0]] = cells[1]

    return dispositions


def recorded_dispositions() -> dict[str, str]:
    """The dispositions the record on disk carries."""
    return record_dispositions(RECORD.read_text())


def reconcile_dispositions(dispositions: dict[str, str], stated: list[str]) -> list[str]:
    """Complaints about the record against the contract's rules, both directions and over a floor.

    The same shape as :func:`reconcile_rules` and for the same reason, but against the consumer no
    parse can check directly: ``dpm:status`` is prose, and a passage that agrees with a rule reads
    exactly like one that never met it. What is mechanically checkable is that every rule was
    *looked at*, which is what a disposition asserts.
    """
    if not dispositions:
        return ["the record dispositions no rules at all, so there is nothing to reconcile"]

    if not stated:
        return ["the contract states no rules at all, so any record would pass"]

    complaints = []

    for rule in sorted(set(dispositions) - set(stated)):
        complaints.append(f"the record dispositions '{rule}' and the contract does not state it")

    for rule in sorted(set(stated) - set(dispositions)):
        complaints.append(f"the contract states '{rule}' and the record gives it no disposition")

    for rule, disposition in sorted(dispositions.items()):
        if rule in stated and not any(word in disposition.lower() for word in OUTCOMES):
            complaints.append(
                f"'{rule}' carries a disposition that does not say what happened to it: "
                f"{disposition!r}"
            )

    return complaints


def reconcile_rules(implemented: dict[str, list[str]], stated: list[str]) -> list[str]:
    """Complaints about the board's derivations against the contract's rules, both directions.

    **The floor comes first, and it is what makes the rest mean anything.** A contract nothing
    parses out of and a board that registered nothing agree perfectly, and a reconciliation over
    two empty sets is a passing check that inspected nothing — indistinguishable, from its result,
    from a working one. Once the live sets agree, only planted inputs can tell those apart.
    """
    if not implemented:
        return ["the board implements no derivation rules at all, so there is nothing to reconcile"]

    if not stated:
        return ["the contract states no rules at all, so any set of derivations would pass"]

    complaints = []

    for rule in sorted(set(implemented) - set(stated)):
        complaints.append(
            f"the board derives '{rule}' ({', '.join(implemented[rule])}) and the contract does "
            f"not state it"
        )

    for rule in sorted(set(stated) - set(implemented)):
        complaints.append(f"the contract states '{rule}' and nothing in the board implements it")

    for rule, functions in sorted(implemented.items()):
        if rule in stated and not functions:
            complaints.append(f"'{rule}' is registered with no function behind it")

    return complaints
