"""What a project's state *is*, derived from rows (FR5, FR6, FR9).

This module is the board's half of the contract at ``dpm/shared/status-model.md``. Everything it
answers is derived from rows that arrived as ``tools/call`` responses — never from prose, never
from a file, and never from a rule restated here that dpm already holds.

**The difference from CPM's board is the whole point of dpm.** CPM derives blocking by parsing a
``**Blocked by**`` line and matching titles; here a blocking edge is a row, so a blocked epic names
its blocker because the blocker has an id. The same holds for readiness: dpm answers "can this be
worked on now" itself, through the ``ready`` filter, and the board asks rather than recomputes.

**Two rules are dpm's and are read, not restated:**

- *Readiness* is ``readyClause`` — the row is ``pending``, unarchived, and no incomplete blocker
  reaches it over an edge kind whose ``gates_work`` is set. The board passes ``ready`` and takes
  the answer. A locally recomputed readiness is a second implementation of a rule that already
  exists, and it drifts silently the first time ``readyClause`` changes.
- *Which edge kinds gate* comes from ``list_dependency_kind``'s ``gates_work`` column, never from
  a list of kind names written here. That is why ``dependency_kind`` is a table at all: a project
  adding a fifth kind decides for itself whether it gates, and nothing here has to be edited to
  agree.

**Two values are the board's own**, because dpm's status enum has no such member: *in progress*
(some stories complete, some pending) and the ordered candidate list. Those are derivations, and
they are what the contract is for.

**Every read is complete.** :data:`PAGE` is the size of a request, not a bound on the answer: a
list that comes back with ``more`` set is read again from the next offset, because every figure
here is a count of these rows and a page boundary would take stories out of a denominator with
nothing anywhere saying so.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from mcp_client import ServerPool, declare

#: How many rows one request asks for. Not a bound on the answer — :func:`rows` follows ``more``.
PAGE = 500

# The board's read surface, declared where it is called (NFR5). One declaration per tool name,
# here rather than in `board.py`, because `SURFACE` is keyed on the name: two `declare("list_epic",
# …)` calls in two modules would leave whichever imported last, and the reconciliation would check
# a set that depends on import order.
EPICS = declare("list_epic", "limit", "offset", "ready")
STORIES = declare("list_story", "limit", "offset", "ready")
TASKS = declare("list_task", "limit", "offset", "story_id", "include_body")
DEPENDENCIES = declare("list_dependency", "limit", "offset")
DEPENDENCY_KINDS = declare("list_dependency_kind", "limit", "offset", "include_retired")
SPECS = declare("list_spec", "limit", "offset")
RETROS = declare("list_retro", "limit", "offset")

# FR16's two reads, both unscoped: `list_requirement` is scoped by `spec_id` and `list_coverage` by
# `requirement_id`, so an unscoped call to each returns the whole table with the foreign key on
# every row — which is what makes the difference below two calls rather than one per requirement.
# `include_body` is deliberately absent: `label` and `spec_id` are columns, and the withheld body is
# the requirement's `text`, which nothing here reads.
REQUIREMENTS = declare("list_requirement", "limit", "offset")
COVERAGE = declare("list_coverage", "limit", "offset")

#: FR17's read. **It takes no arguments at all** — not even `limit`, and that is the tool's own
#: decision rather than an oversight here: an integrity report truncated at a page is the one report
#: whose job is to be trusted lying by omission, so dpm serves it unbounded. It is also not a
#: `list_*` tool, so it is read through `pool.read` directly rather than through :func:`rows`.
INTEGRITY = declare("check_integrity")

# What a preview is built from (FR7). One declaration per tool name — `list_task` above serves both
# the count on a board row and the tasks under a story, because `SURFACE` is keyed on the name and
# a second `declare("list_task", …)` would leave whichever module imported last.
SECTIONS = declare("list_document_section", "limit", "offset", "document_id", "include_body")
STORY_CRITERIA = declare("list_story_criterion", "limit", "offset", "story_id", "include_body")

#: FR15's read. The board sends the query and the bound and nothing else — no ``entity:`` scope is
#: added to it, because the scope is the *user's* to write and a board that quietly narrowed the
#: corpus would answer "no matches" over half of it, which is the false negative dpm's own search
#: tool documents at length.
SEARCH = declare("search", "limit", "offset", "query")

#: The read behind a document row, per kind. `read_*` takes an id and nothing else: a document has
#: no withheld columns, so there is no `include_body` on it and none is passed. The prose lives in
#: `document_section` rows, which *do* withhold their bodies — that is where the flag belongs, and
#: leaving it off returns every section's heading and none of its text.
DOCUMENT_READS = {
    "epic": declare("read_epic", "id"),
    "spec": declare("read_spec", "id"),
    "retro": declare("read_retro", "id"),
}

#: The states an epic row can be rendered in. Two of them — `BLOCKED` and `IN_PROGRESS` — are the
#: board's, derived; the rest are the status column's own words.
COMPLETE = "complete"
BLOCKED = "blocked"
IN_PROGRESS = "in_progress"
READY = "ready"
PENDING = "pending"

#: Terminal statuses a user sets by hand. They retire an epic; they do not complete it.
SUPERSEDED = "superseded"
WITHDRAWN = "withdrawn"
RETIRED = (SUPERSEDED, WITHDRAWN)

#: Every state :func:`epic_state` can answer with, in its precedence order. **This tuple is the
#: enumeration**, so a display keyed on it gains a state the moment one is added here and has
#: nothing to render it with until someone says what it looks like — which is the point. A parallel
#: list in the view would agree with this one until the day it mattered.
EPIC_STATES = (COMPLETE, SUPERSEDED, WITHDRAWN, BLOCKED, IN_PROGRESS, READY, PENDING)

#: Rule name to the functions that implement it — the board's half of AD5's contract.
#:
#: Filled by :func:`derivation` at import, so it is what the module *does* rather than a list
#: alongside it. That is the same reason `declare()` returns the call it registers one layer down:
#: a hand-kept enumeration agrees with the contract while disagreeing with the code, and the
#: reconciliation it feeds then proves nothing about what runs.
DERIVATIONS: dict[str, list[str]] = {}


def derivation(rule: str):
    """Register a function as part of ``rule``, one of the contract's named derivations.

    Several functions may carry one rule — readiness is asked for twice, once per gated table — and
    a rule with no function, or a function under a rule the contract does not state, is what the
    reconciliation exists to catch.
    """
    def register(function):
        DERIVATIONS.setdefault(rule, []).append(function.__name__)

        return function

    return register


async def rows(
    pool: ServerPool, root: Path, call, arguments: dict | None = None, *, fresh: bool = False
) -> list[dict]:
    """Every row one list tool has, as rows.

    Everything in this module reads through here, so that the *only* way state arrives is a
    ``tools/call`` on that project's own server (FR2).

    ``fresh`` is FR13's force-refresh, passed through to the pool: the answer is asked for again
    whatever the cache holds. It threads down from the action a user pressed rather than being
    decided here, because this function has no way of knowing whether the user has just written
    something the stamp cannot see.

    **A truncated read is a wrong count, not a smaller project**, so this follows ``more`` rather
    than stopping at :data:`PAGE`. Every figure the board renders is a count of these rows, and a
    page boundary would take stories out of a denominator and epics off a candidate list with
    nothing anywhere saying so. `dpm:status` states the same rule for the same reason: raise the
    bound and read again rather than reporting the page.
    """
    found: list[dict] = []

    while True:
        answer = await pool.read(
            root, call, {"limit": PAGE, "offset": len(found), **(arguments or {})}, fresh=fresh
        )
        found += answer["items"]

        if not answer.get("more"):
            return found


@derivation("readiness")
async def ready_epic_ids(pool: ServerPool, root: Path, *, fresh: bool = False) -> set[str]:
    """The epics dpm says can be worked on now — its answer, not ours.

    ``ready`` is the whole of :func:`readyClause`: pending, unarchived, and nothing incomplete
    blocking it over a gating edge. The board sends the flag and keeps the ids; it does not
    reconstruct the predicate from the rows, which is the one thing that would make this a second
    implementation of dpm's rule.
    """
    return {row["id"] for row in await rows(pool, root, EPICS, {"ready": True}, fresh=fresh)}


@derivation("readiness")
async def ready_story_ids(pool: ServerPool, root: Path, *, fresh: bool = False) -> set[str]:
    """The stories dpm says can be worked on now.

    A story's blockers are not all stories — ``dependency`` reaches a story from another story and
    from a whole epic elsewhere — which is a second reason the flag is asked for rather than
    derived: a board reading only story-to-story edges would report a story ready while an epic it
    names holds it up.
    """
    return {row["id"] for row in await rows(pool, root, STORIES, {"ready": True}, fresh=fresh)}


@dataclass(frozen=True)
class Blocker:
    """One thing holding one row up: a *named* blocker, because the edge names it by id.

    ``title`` falls back to the id when the blocker is a document of a kind the board did not
    list. That is a display fallback and nothing more — the edge is still a row, and the state is
    still blocked.
    """

    id: str
    title: str
    status: str | None
    kind: str


def edge_source(edge: dict) -> str:
    """Whichever end of the edge does the blocking. The two source columns are exclusive."""
    return edge["source_document_id"] or edge["source_story_id"]


def edge_target(edge: dict) -> str:
    """Whichever end of the edge is held up. The two target columns are exclusive."""
    return edge["target_document_id"] or edge["target_story_id"]


@derivation("blocking")
async def gating_kinds(pool: ServerPool, root: Path, *, fresh: bool = False) -> set[str]:
    """The edge kinds that hold work up, read from ``gates_work`` rather than named here.

    **A list of kind names in this file would be the hardcoded list dpm removed**, one layer up.
    ``dependency_kind`` is a table precisely so a project adding a fifth kind decides for itself
    whether it gates; a board matching on ``'blocks'`` would answer for its own vocabulary rather
    than the project's.

    **``include_retired`` is passed on purpose, and it is the one place this read departs from the
    tool's default.** A retired edge kind still gates: ``readyClause`` joins ``dependency_kind`` on
    ``gates_work`` alone and mentions ``retired_at`` nowhere, because retirement stops new edges
    arriving rather than releasing the work existing ones already hold. The list tool hides retired
    rows unless asked, so a board taking the default would find an edge whose kind it had never
    heard of, treat it as non-gating, and call an epic workable that dpm says is blocked — a
    disagreement between the two answers about the same project, which is exactly what the
    contract exists to prevent.
    """
    kinds = await rows(pool, root, DEPENDENCY_KINDS, {"include_retired": True}, fresh=fresh)

    return {row["kind"] for row in kinds if row["gates_work"]}


async def hits(pool: ServerPool, root: Path, query: str, *, limit: int) -> list[dict]:
    """One project's search hits, ranked, bounded (FR15).

    **The one read in this module that does not follow ``more``, and the exception is the point.**
    Every other read here is counted — a page boundary would take stories out of a denominator, so
    :func:`rows` raises the bound and reads again. A search is not counted: what a user asked for is
    the best matches, dpm ranks them, and the rows past the bound are by construction the ones it
    ranked worst. Paging through them would trade the interaction time FR15 is about for hits nobody
    scrolled to.

    ``limit`` is required rather than defaulted, so the bound is a decision made at the call site
    and visible there rather than a number hidden in this function.
    """
    answer = await pool.read(root, SEARCH, {"query": query, "limit": limit, "offset": 0})

    return answer["items"]


def violation_count(report: dict) -> int:
    """How many things an integrity report found wrong (FR17).

    **Rows, not failed entries**, and the difference is what the number means. A register entry is
    an invariant and its ``rows`` are the places that invariant is broken, so counting entries
    reports two bad edges as one problem — and the count on a badge is there to say how much there
    is to fix, not how many rules were involved.

    **Orphans are added rather than reported separately**, because ``ok`` goes false for a dangling
    row as readily as for a failed entry. Left out, a project whose foreign keys no longer resolve
    would carry a badge reading `0`: a claim that nothing is wrong, on a row where something is.

    Pure, and separate from the read below, so the arms can be driven on a planted report — an
    orphan cannot be created through dpm's own write tools, which enforce the keys it would break.
    """
    broken = sum(
        len(entry.get("rows", ()))
        for entry in report.get("entries", ())
        if not entry.get("held")
    )

    return broken + len(report.get("orphans", ()))


async def violations(pool: ServerPool, root: Path, *, fresh: bool = False) -> int:
    """One project's integrity report, counted (FR17).

    **Undecorated, and that is a decision rather than an omission.** Every other read in this module
    that produces a value carries a ``@derivation`` naming a rule in the contract, because the rule
    has two consumers to keep from drifting. No dpm skill calls ``check_integrity``, so this has
    one — and a rule nothing else conforms to would be a contract entry written for a single
    reader, which the reconciliation would then fail from the other side.
    """
    return violation_count(await pool.read(root, INTEGRITY, {}, fresh=fresh))


async def dependencies(pool: ServerPool, root: Path, *, fresh: bool = False) -> list[dict]:
    """Every edge in the project, in one read, to be grouped by target in the caller."""
    return await rows(pool, root, DEPENDENCIES, fresh=fresh)


@derivation("blocking")
def blockers(
    target: str, edges: list[dict], gating: set[str], index: dict[str, dict]
) -> list[Blocker]:
    """What holds ``target`` up, named — the whole difference from a board that parses prose.

    CPM's board reads a ``**Blocked by**`` line and matches a title; here the edge is a row, so
    the blocker has a name because it has an id, and an edge whose kind does not gate work is
    excluded by the project's own vocabulary rather than by a guess about what the phrase meant.

    ``index`` maps id to the row the board already read — its epics and its stories. A blocker
    absent from it is a document of some other kind, and it is kept: an unknown status cannot be
    shown to be ``complete``, and reading it as satisfied is the direction that silently releases
    work.
    """
    held = []

    for edge in edges:
        if edge_target(edge) != target or edge["kind"] not in gating:
            continue

        source = edge_source(edge)
        row = index.get(source)

        if row is not None and not still_gates(row["status"]):
            continue

        held.append(
            Blocker(
                id=source,
                title=row["title"] if row is not None else source,
                status=row["status"] if row is not None else None,
                kind=edge["kind"],
            )
        )

    return held


@derivation("retired blockers")
def still_gates(status: str) -> bool:
    """Whether a blocker in this status still holds up the work waiting on it.

    **Only ``complete`` releases the work, and that is dpm's rule rather than a reading of the
    enum.** ``readyClause`` says ``blocker.status <> 'complete'`` in exactly those words, and the
    reason is that ``superseded`` and ``withdrawn`` retire an epic without delivering what the work
    waiting on it was waiting for. A dependent left pointing at a withdrawn blocker is stuck, and
    the board's job is to say so: retiring a depended-upon epic surfaces as a real blocker, not as
    a silent release.

    The two plausible wrong readings both go the same way. "Terminal means done" reads all three
    of ``complete``, ``superseded`` and ``withdrawn`` as satisfying the edge; "not pending means
    done" does the same by another route. Either one hands the user an epic to pick up that dpm's
    own ``ready`` filter excludes — the two answers disagreeing about one project, which is the
    failure AD5's contract exists to prevent.

    The mirror image of this rule is on the *blocked* row rather than the blocker, and it belongs
    to dpm: a retired epic is not offered as workable either, because ``readyClause`` requires the
    row's own status to be ``pending``. The board takes that half from the ``ready`` filter and
    never restates it.
    """
    return status != COMPLETE


@derivation("in progress")
def in_progress(stories: list[dict]) -> bool:
    """Some stories complete and some not — the value dpm's status enum does not carry.

    ``document.status``, ``story.status`` and ``task.status`` are each one of ``pending``,
    ``complete``, ``superseded`` or ``withdrawn`` — so *in progress* exists nowhere in the database
    and is the board's own derivation. It is stated over the story rows rather than over anything
    remembered between reads, so it is a fact about the project as it is now.

    **All three cases go through here**, which is why the shape is two counts rather than a check
    for one completed story: an epic with every story complete is finished, one with none started
    has not begun, and only the middle is under way. A derivation that answered the middle case
    alone would satisfy FR5 as worded and be wrong at both ends of an epic's life.

    Stated over :func:`progress`, so the retired-story rule holds here too and cannot drift away
    from the counts rendered beside it: an epic whose only unfinished stories were withdrawn is not
    still under way.
    """
    counted = progress(stories)

    return counted is not None and 0 < counted.done < counted.total


@dataclass(frozen=True)
class Progress:
    """Stories done over stories total (FR6). Never constructed for a row set with nothing in it.

    ``complete`` is a property rather than ``done == total`` written at each call site, because
    those two are the same expression everywhere except the one place it matters — and the empty
    case cannot reach here at all, which is what :func:`progress` returning ``None`` buys.
    """

    done: int
    total: int
    retired: int = 0

    @property
    def complete(self) -> bool:
        return self.done == self.total

    def __str__(self) -> str:
        return f"{self.done}/{self.total}"


@derivation("progress counts")
def progress(stories: list[dict]) -> Progress | None:
    """Done over total across ``stories``, or ``None`` when there are none to count.

    **``None`` rather than ``Progress(0, 0)``, and that is the whole of this rule.** Zero of zero
    is complete by every reading available to it: ``done == total`` holds, "every story is done" is
    vacuously true, and a percentage is either 100 or a division by zero. An epic nobody has broken
    down yet would render as finished work on a board whose job is showing what is left — so the
    absence is returned as an absence, and the caller has to say what it renders for one.

    **A retired story leaves the count rather than joining either side of it.** ``story.status``
    has had four values since ``020-status-lifecycle.sql``, and a `superseded` or `withdrawn` story
    is not work waiting to be done: held in the denominator it keeps an epic open for something
    nobody intends to do, and counted as done it reports work that was dropped as delivered. How
    many were retired is carried alongside, so a denominator that shrank does not do it silently.
    This is `dpm:status`'s rule, adopted here by AD5's reconciliation — the board had it wrong.

    Counted from the story rows the tools returned, which is also the roll-up's rule: a project's
    figure is its story rows, not the average of its epics' figures. Averaging gives an epic with
    no stories a completion of its own and lets it lift the project's number.
    """
    counted = [story for story in stories if story["status"] not in RETIRED]

    if not counted:
        return None

    return Progress(
        sum(1 for story in counted if story["status"] == COMPLETE),
        len(counted),
        len(stories) - len(counted),
    )


@derivation("progress counts")
def by_epic(stories: list[dict]) -> dict[str, list[dict]]:
    """Story rows grouped by the epic each one names.

    ``epic_id`` arrives on every row, so one unscoped ``list_story`` answers for every epic in the
    project. The alternative — one scoped call per epic — is the join in the caller that dpm's list
    tools exist to remove, and it costs a round trip per epic to learn what one already said.
    """
    grouped: dict[str, list[dict]] = {}

    for story in stories:
        grouped.setdefault(story["epic_id"], []).append(story)

    return grouped


@derivation("untraced requirements")
async def untraced_requirements(
    pool: ServerPool, root: Path, *, fresh: bool = False
) -> list[dict]:
    """The requirements no coverage row names — FR16, as a set difference over two reads.

    **The question CPM's board could not ask.** A coverage matrix in markdown is a table nobody
    joins; here the binding is a row carrying a ``requirement_id``, so "which requirements has
    nothing been written against" is a difference rather than a search.

    Rows rather than ids, because the view built on this shows each requirement's own ``label`` and
    the ``spec_id`` it belongs to, and both arrive on the row already — returning ids would send the
    caller back for a list it has just been handed.

    **Nothing here reads ``verified_at``.** Whether a coverage row is verified is a different
    question from whether one exists, and a requirement whose rows are merely unverified is work
    under way rather than work nobody planned. Folding the two together would put a planned
    requirement on a list whose remedy is to plan it.

    ``dpm:status`` derives the same set with ``list_coverage`` scoped by ``requirement_id``, once
    per requirement. Both shapes answer the rule; this one is two calls whatever the project's size,
    which is what a board rendering every registered project needs it to be.
    """
    traced = {row["requirement_id"] for row in await rows(pool, root, COVERAGE, fresh=fresh)}

    return [
        row
        for row in await rows(pool, root, REQUIREMENTS, fresh=fresh)
        if row["id"] not in traced
    ]


#: The candidate kinds, **in the order FR9 requires**. The tuple is the ordering: a kind's rank is
#: its index here, so the sort has one place to be wrong and the contract has one thing to state.
CANDIDATE_KINDS = ("epic_ready", "spec_without_epics", "retro_missing")


@dataclass(frozen=True)
class Candidate:
    """One thing that could be done next, naming the row it is about.

    ``kind`` is one of :data:`CANDIDATE_KINDS`; the command each maps to is FR8's and belongs to
    the launcher, not here. What this layer owes the one above is *which row*, and in what order.
    """

    kind: str
    id: str
    title: str
    number: int = 0

    @property
    def rank(self) -> tuple:
        """Kind first, then the row's own number — FR9's ordering, as a sort key."""
        return (CANDIDATE_KINDS.index(self.kind), self.number, self.id)


@derivation("candidate ordering")
def numbering_of(row: dict) -> int:
    """A document's position among its siblings, whichever column its kind numbers by.

    Specs are root-numbered and carry ``number``; epics are child-numbered under a spec and carry
    ``sequence``. Reading one column would order one kind correctly and pile the other at zero.
    """
    return row.get("number") or row.get("sequence") or 0


@derivation("candidate ordering")
def waived(epic: dict) -> bool:
    """Whether this epic's retro has been deliberately waived.

    A waiver is a decision already taken — `retro triage` classified the epic as clean and recorded
    why. Offering it again is how a board teaches its user that the next-action list is noise, and
    the epic will never stop appearing, because nothing about it is going to change.

    Read from ``retro_waived_at`` alone though the schema pairs it with a reason: the CHECK in
    `015-retro-waiver.sql` makes both present or neither, so testing the second would add a
    condition that cannot independently be false.
    """
    return epic.get("retro_waived_at") is not None


@derivation("candidate ordering")
def candidates(
    epics: list[dict], specs: list[dict], retros: list[dict], ready: set[str]
) -> list[Candidate]:
    """What could be picked up next, ordered (FR9).

    Three kinds, each a query over rows rather than a judgement: an epic dpm says is ready, a spec
    nothing has been broken down from, and a finished epic with no retro. They are ordered by kind
    first — work that can start now before work that needs planning, and both before the follow-up
    on work already done — and by the row's own number within a kind, so the order is stable and a
    user sees the same list twice.

    The whole of the ordering lives in :data:`CANDIDATE_KINDS` and :meth:`Candidate.rank`, which is
    what keeps this function from being three appends whose order is an accident of the code.
    """
    broken_down = {epic["parent_id"] for epic in epics if epic["parent_id"]}
    reflected = {retro["parent_id"] for retro in retros if retro["parent_id"]}
    found = []

    # **Emitted in row order, not grouped by kind**, and that is deliberate. Three loops appending
    # one kind each would produce FR9's order with the sort removed — leaving the requirement
    # satisfied by the order the code happens to be written in, where no assertion about the output
    # can see it and the next edit to this function silently changes the answer. Discovering both
    # epic kinds in one pass makes the sort below the only thing that orders anything.
    for epic in epics:
        if epic["id"] in ready:
            found.append(Candidate("epic_ready", epic["id"], epic["title"], numbering_of(epic)))

        if epic["status"] == COMPLETE and epic["id"] not in reflected and not waived(epic):
            found.append(Candidate("retro_missing", epic["id"], epic["title"], numbering_of(epic)))

    for spec in specs:
        if spec["id"] not in broken_down:
            found.append(
                Candidate("spec_without_epics", spec["id"], spec["title"], numbering_of(spec))
            )

    return sorted(found, key=lambda candidate: candidate.rank)


@derivation("in progress")
def epic_state(epic: dict, stories: list[dict], held: list[Blocker], ready: set[str]) -> str:
    """One epic's state, in precedence order.

    The order is what makes the answer single-valued, and it reads downward from the most settled:
    a finished epic is finished, a retired one keeps its own word rather than being flattened into
    a state it does not have, an epic something holds up is *blocked* whatever its stories say —
    because the answer to "can this be picked up" is no — and only then do the stories decide
    between under way and not begun.

    Readiness is dpm's own answer, arriving as membership of ``ready``. An epic that is neither
    blocked nor started and is still not ready is one ``readyClause`` excludes for a reason the
    board did not have to know about — archival today — so it renders as pending rather than as
    something the board invented a state for.
    """
    if epic["status"] == COMPLETE:
        return COMPLETE

    if epic["status"] in RETIRED:
        return epic["status"]

    if held:
        return BLOCKED

    if in_progress(stories):
        return IN_PROGRESS

    return READY if epic["id"] in ready else PENDING
