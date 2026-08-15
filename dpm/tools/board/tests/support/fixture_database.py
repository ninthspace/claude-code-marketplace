"""A real dpm database, built by dpm's own write tools (ENV5).

The board is an MCP client and nothing else, so a stub server would let every test pass while the
board asked for fields no tool returns and parsed shapes no server sends. What makes an integration
test here worth its runtime is that the thing on the other end of the pipe is `bin/dpm-mcp.js`, and
what makes *that* possible is a database with something in it.

**Built by calling the server's own `create_*` tools, not by writing SQL.** The schema is dpm's and
it migrates; a fixture that inserted rows directly would be a second, silent implementation of it,
correct until the day a migration lands and wrong in a way that looks like a board bug.

Every later epic's fixtures reuse this, which is why the content is deliberately a little wider than
any one story needs: two epics under one spec, mixed statuses, stories, and tasks — enough for a
board to have something to render and something to sort.
"""

from __future__ import annotations

from pathlib import Path

from mcp_client import MCPClient

#: The fixture's shape, as calls to make in order.
#:
#: Written as data so a later epic can read what is in the database without running it, and so the
#: ids that thread through it are visible: a name in `remember` is referenced as `{name}` in a
#: later call's arguments.
CONTENT = [
    ("create_spec", {"slug": "10-fixture-spec", "title": "The fixture spec"}, "spec"),
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-01-first", "title": "First epic", "status": "complete"},
        "done_epic",
    ),
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-02-second", "title": "Second epic"},
        "open_epic",
    ),
    (
        "create_story",
        {"epic_id": "{open_epic}", "number": 1, "title": "A finished story", "position": 0,
         "status": "complete"},
        "done_story",
    ),
    (
        "create_story",
        {"epic_id": "{open_epic}", "number": 2, "title": "An unfinished story", "position": 1},
        "open_story",
    ),
    (
        "create_task",
        {"story_id": "{open_story}", "number": 1, "title": "A finished task", "position": 0,
         "status": "complete"},
        None,
    ),
    (
        "create_task",
        {"story_id": "{open_story}", "number": 2, "title": "An unfinished task", "position": 1},
        None,
    ),
    # A third epic and the edge that holds it, so the fixture can tell a *blocked* epic from a
    # merely unstarted one. Without an edge in it, a board that never read `dependency` at all
    # would render this project exactly as a correct one does.
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-03-third", "title": "Third epic"},
        "blocked_epic",
    ),
    (
        "create_dependency",
        {"kind": "blocks", "source_document_id": "{open_epic}",
         "target_document_id": "{blocked_epic}"},
        None,
    ),
    # The decoy, and the reason `gates_work` is read rather than assumed: an edge of a kind that
    # does *not* gate work, pointing at an epic that has to go on reading as workable. Its source
    # is deliberately an incomplete epic, so a board that filtered edges by anything other than
    # `gates_work` — or by nothing at all — reports this project's one ready epic as blocked.
    #
    # **`supersedes` rather than `builds_on`, and the difference is not cosmetic.** Register entry
    # 6 admits `builds_on` only between two specs, so the same decoy written that way was an
    # integrity violation sitting in the shared fixture — invisible until 48-08 gave the board a
    # reason to run `check_integrity` over it. `supersedes` has `gates_work = 0` like `builds_on`
    # and no restriction on its ends, so the decoy plays exactly the same part in a project that
    # is now clean.
    (
        "create_dependency",
        {"kind": "supersedes", "source_document_id": "{blocked_epic}",
         "target_document_id": "{open_epic}"},
        None,
    ),
    # FR9's three candidate kinds, **more than one of each**, plus a decoy for each. An ordering
    # asserted over one candidate per kind is satisfied by several wrong comparators, and one
    # asserted over a single kind is satisfied by a comparator that does not sort at all — so the
    # fixture is where that false pass has to be closed, and this is that part of it.
    #
    # A second ready epic, and a second complete one with no retro:
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-04-fourth", "title": "Fourth epic"},
        "second_ready_epic",
    ),
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-05-fifth", "title": "Fifth epic", "status": "complete"},
        "second_done_epic",
    ),
    # The decoy for the retro candidate: complete, and already reflected on. A board offering this
    # one is asking a user to do work that has been done.
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-06-sixth", "title": "Sixth epic", "status": "complete"},
        "reflected_epic",
    ),
    (
        "create_retro",
        {"parent_id": "{reflected_epic}", "slug": "10-06-retro", "title": "A retro already written"},
        "retro",
    ),
    # Two specs nothing has been broken down from, and they are the *only* specs in that state:
    # `{spec}` above has epics, which is the decoy for this kind.
    ("create_spec", {"slug": "20-quiet-spec", "title": "A spec with no epics"}, "quiet_spec"),
    ("create_spec", {"slug": "30-later-spec", "title": "A later spec with no epics"}, "later_spec"),
    # The decoy that distinguishes "has a retro" from "needs no retro": complete, no retro, and a
    # recorded waiver. A waiver is an update to a row that has to exist first, and it is written
    # through `update_epic` because that is how one is actually recorded — both columns together,
    # as `015-retro-waiver.sql`'s CHECK requires.
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-07-seventh", "title": "Seventh epic",
         "status": "complete"},
        "waived_epic",
    ),
    (
        "update_epic",
        {"id": "{waived_epic}", "retro_waived_at": "2026-08-14",
         "retro_waived_reason": "Nothing to reflect on"},
        None,
    ),
    # FR7's previews. Prose lives in `document_section` rows rather than on the document, and each
    # of the three previewable kinds gets sections of its own — a preview built through `read_epic`
    # would answer for an epic and fail on a spec, and the read tools are named for the kind.
    (
        "create_document_section",
        {"document_id": "{open_epic}", "heading": "Why this epic exists",
         "body": "Because the board has to render something.", "position": 0},
        None,
    ),
    (
        "create_document_section",
        {"document_id": "{open_epic}", "heading": "What it does not do",
         "body": "It does not parse markdown.", "position": 1},
        None,
    ),
    (
        "create_document_section",
        {"document_id": "{spec}", "heading": "Scope",
         "body": "Everything the fixture spec covers.", "position": 0},
        None,
    ),
    # On the retro row, **not** on the epic it reflects on. The two are separate documents with
    # separate sections, and a preview that read the parent's would look right here for exactly as
    # long as nobody wrote prose on both.
    (
        "create_document_section",
        {"document_id": "{retro}", "heading": "Observations",
         "body": "The retro's own prose, on the retro's own row.", "position": 0},
        None,
    ),
    # An epic held apart for FR7's scoping criterion: **three** stories, each with criteria and
    # tasks worded so that another story's would be unmistakable in this one's preview. Two would
    # not do it — with one story the claim "not the whole epic" is unfalsifiable, and with two a
    # wrong scope is as likely to look like an off-by-one as like a missing filter.
    (
        "create_epic",
        {"parent_id": "{spec}", "slug": "10-08-eighth", "title": "Eighth epic"},
        "preview_epic",
    ),
    (
        "create_story",
        {"epic_id": "{preview_epic}", "number": 1, "title": "The first previewed story",
         "position": 0},
        "first_previewed",
    ),
    (
        "create_story",
        {"epic_id": "{preview_epic}", "number": 2, "title": "The second previewed story",
         "position": 1},
        "second_previewed",
    ),
    (
        "create_story",
        {"epic_id": "{preview_epic}", "number": 3, "title": "The third previewed story",
         "position": 2},
        "third_previewed",
    ),
    # Named, unlike its two siblings, because FR16's coverage row below binds to it. A criterion is
    # half of what a coverage row *is*, so the fixture has to hold one whose id it can reach.
    (
        "create_story_criterion",
        {"story_id": "{first_previewed}", "text": "Only the first story says this", "position": 0},
        "first_criterion",
    ),
    (
        "create_story_criterion",
        {"story_id": "{second_previewed}", "text": "Only the second story says this", "position": 0},
        None,
    ),
    (
        "create_story_criterion",
        {"story_id": "{third_previewed}", "text": "Only the third story says this", "position": 0},
        None,
    ),
    (
        "create_task",
        {"story_id": "{second_previewed}", "number": 1, "title": "The second story's own task",
         "position": 0, "description": "And the description only it carries."},
        None,
    ),
    # FR16's three requirements, and the one coverage row that makes them tell a derivation apart.
    #
    # **The traced one is the discriminator.** With only untraced requirements in the fixture, "the
    # ones no coverage row names" is satisfied by returning every requirement there is, and nothing
    # about the result would look wrong.
    #
    # **The two untraced ones differ in their spec, not in their tracing.** One belongs to `{spec}`,
    # which has epics; the other to `{quiet_spec}`, which has none. Both are gaps, and a view that
    # resolves a gap to a document can only resolve the first — asserted over a fixture where every
    # gap resolves, or where none does, that boundary is unfalsifiable.
    (
        "create_requirement",
        {"spec_id": "{spec}", "label": "FR1", "class": "functional", "moscow": "must",
         "text": "The requirement a coverage row names.", "position": 0},
        "traced_requirement",
    ),
    (
        "create_requirement",
        {"spec_id": "{spec}", "label": "FR2", "class": "functional", "moscow": "should",
         "text": "A requirement nothing was written against, under a spec that has epics.",
         "position": 1},
        "untraced_requirement",
    ),
    (
        "create_requirement",
        {"spec_id": "{quiet_spec}", "label": "NFR1", "class": "non_functional",
         "text": "A requirement nothing was written against, under a spec that has none.",
         "position": 0},
        "orphan_untraced_requirement",
    ),
    # `spec_fragment` is a verbatim slice of the requirement's own text, which is what the column
    # is for — a summary there would be a paraphrase standing in for the thing asked for. The row
    # is deliberately left unverified: this rule is about a coverage row *existing*, and a fixture
    # whose only coverage row were verified could not tell the two questions apart.
    (
        "create_coverage",
        {"requirement_id": "{traced_requirement}", "spec_fragment": "a coverage row names",
         "story_criterion_id": "{first_criterion}", "position": 0},
        None,
    ),
]


def created(tool: str) -> int:
    """How many rows of one kind :data:`CONTENT` builds.

    Read by tests that would otherwise transcribe the fixture's shape into an expected number.
    A transcribed count is only ever a test of the transcription — it goes stale the moment the
    fixture grows, and it goes stale silently if the growth happens to cancel out.
    """
    return sum(1 for call, _, _ in CONTENT if call == tool)


def titles(tool: str) -> list[str]:
    """The titles :data:`CONTENT` gives one kind of row, in the order it creates them."""
    return [arguments["title"] for call, arguments, _ in CONTENT if call == tool]


def titled(*names: str) -> set[str]:
    """The titles of the rows :data:`CONTENT` remembers under ``names``.

    Rows are referred to by the *role* the fixture built them for — ``blocked_epic``,
    ``waived_epic``, ``preview_epic`` — rather than by a title copied into a test. A title set
    written out in a test is a transcription of the fixture, and it breaks the next time the
    fixture grows for a reason that has nothing to do with the rule under test; naming the roles
    means a new row only joins an expectation when someone says it plays that part.
    """
    return {
        arguments["title"] for _, arguments, name in CONTENT if name in names and "title" in arguments
    }


def labelled(*names: str) -> set[str]:
    """The labels :data:`CONTENT` gives the rows it remembers under ``names``.

    :func:`titled`'s counterpart for the rows that have no title. A requirement's display name is
    its ``label``, and the same argument applies: a set of labels written out in a test is a
    transcription of the fixture, and naming the roles means a new requirement only joins an
    expectation when someone says it plays that part.
    """
    return {
        arguments["label"] for _, arguments, name in CONTENT if name in names and "label" in arguments
    }


def resolve(arguments: dict, known: dict[str, str]) -> dict:
    """Substitute `{name}` references with the ids the earlier calls returned."""
    return {
        key: known[value[1:-1]] if isinstance(value, str) and value.startswith("{") else value
        for key, value in arguments.items()
    }


async def build(root: Path, server: Path, content: list | None = None) -> Path:
    """Create `root/.dpm/dpm.db` and fill it. Returns the database path.

    The server is spawned *writable* — deliberately, and it is the only place in the board's suite
    that is. Everything the board itself spawns is read-only (ENVX3); this is the test harness
    standing in for the Claude Code session that would have created the project.

    ``content`` defaults to :data:`CONTENT`, the shared fixture every integration test reads. A
    caller supplies its own only for a project whose *shape* is the thing under test and which the
    shared fixture cannot be without losing what it is for — a project with no coverage gaps at
    all, say, which the shared fixture is deliberately not.
    """
    client = await MCPClient(server, cwd=root).start()
    known: dict[str, str] = {}

    try:
        for tool, arguments, name in (CONTENT if content is None else content):
            created = await client.call(tool, resolve(arguments, known))

            if name is not None:
                known[name] = created["id"]
    finally:
        await client.close()

    return root / ".dpm" / "dpm.db"
