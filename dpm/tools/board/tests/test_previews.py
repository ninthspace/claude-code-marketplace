"""Story 2 — previews built from rows (FR7).

Integration tests against the real server and the real fixture database, because the thing this
story can get wrong is the *call*: a preview assembled from the right rows read the wrong way looks
identical in a unit test with hand-built dicts. `include_body` is the argument in question — leave
it off `list_document_section` and every heading comes back with no text, leave it off
`list_story_criterion` and every criterion comes back with no criterion.

The scoping criterion runs against a fixture epic holding three stories whose criteria are worded to
be unmistakable in each other's previews. Against an epic with one story, "not the whole epic" is
not a claim a test can fail.
"""

from __future__ import annotations

import builtins

from fixture_database import CONTENT
from pilot import board, preview

from board import previews, read_document_preview, read_story_preview
from board_view import EpicView, ProjectView, StoryView
from mcp_client import ServerPool
from status_model import EPICS, RETROS, SPECS, STORIES, rows


def sections_of(name: str) -> list[dict]:
    """The sections :data:`CONTENT` writes on the document remembered under ``name``."""
    return [
        arguments
        for call, arguments, _ in CONTENT
        if call == "create_document_section" and arguments["document_id"] == f"{{{name}}}"
    ]


def criteria_of(name: str) -> list[str]:
    """The criterion texts :data:`CONTENT` writes on the story remembered under ``name``."""
    return [
        arguments["text"]
        for call, arguments, _ in CONTENT
        if call == "create_story_criterion" and arguments["story_id"] == f"{{{name}}}"
    ]


async def document_row(pool, root, call, title: str) -> dict:
    """The row the fixture created under ``title``, found through the list tool for its kind."""
    return next(row for row in await rows(pool, root, call) if row["title"] == title)


async def test_an_epics_preview_is_its_row_and_its_sections(fixture_project):
    """Criterion 1 for an epic: the text is what the read tools returned, headings and bodies."""
    async with ServerPool() as pool:
        epic = await document_row(pool, fixture_project, EPICS, "Second epic")
        text = await read_document_preview(
            pool, fixture_project, EpicView(epic["id"], epic["title"], "ready")
        )

    assert text.splitlines()[0] == "Second epic"

    for section in sections_of("open_epic"):
        assert section["heading"] in text, f"a section heading is missing: {section['heading']}"
        assert section["body"] in text, (
            f"the heading rendered without its body — `include_body` was not asked for: "
            f"{section['heading']}"
        )


async def test_a_spec_and_a_retro_preview_through_their_own_read_tools(fixture_project):
    """Criterion 1's other two kinds, which is why ``kind`` is on the row.

    The read tool is named for the kind and refuses an id of another one, so a preview built
    through ``read_epic`` would answer for the epic and fail on both of these.
    """
    async with ServerPool() as pool:
        spec = await document_row(pool, fixture_project, SPECS, "The fixture spec")
        retro = await document_row(pool, fixture_project, RETROS, "A retro already written")

        spec_text = await read_document_preview(
            pool, fixture_project, EpicView(spec["id"], spec["title"], "pending", kind="spec")
        )
        retro_text = await read_document_preview(
            pool, fixture_project, EpicView(retro["id"], retro["title"], "complete", kind="retro")
        )

    assert sections_of("spec")[0]["body"] in spec_text
    assert sections_of("retro")[0]["body"] in retro_text


async def test_a_storys_preview_is_its_own_criteria_and_tasks(fixture_project):
    """Criterion 2: this story's rows, and the task description that only ``include_body`` returns."""
    async with ServerPool() as pool:
        story = next(
            row
            for row in await rows(pool, fixture_project, STORIES)
            if row["title"] == "The second previewed story"
        )
        text = await read_story_preview(
            pool, fixture_project, StoryView(story["id"], story["title"], "pending")
        )

    assert criteria_of("second_previewed")[0] in text
    assert "The second story's own task" in text
    assert "And the description only it carries." in text, (
        "the task rendered without its description — `include_body` was not asked for"
    )


async def test_a_storys_preview_holds_no_other_storys_criteria(fixture_project):
    """Criterion 3, against the fixture built for it: three stories, each saying only its own.

    A wrong scope here is *visible* rather than merely possible. An unscoped read would put all
    three criteria in every preview; a client-side filter on the wrong key would put the wrong
    one in.
    """
    others = criteria_of("first_previewed") + criteria_of("third_previewed")

    assert others, "the fixture no longer holds other stories' criteria, so this asserts nothing"

    async with ServerPool() as pool:
        story = next(
            row
            for row in await rows(pool, fixture_project, STORIES)
            if row["title"] == "The second previewed story"
        )
        text = await read_story_preview(
            pool, fixture_project, StoryView(story["id"], story["title"], "pending")
        )

    for criterion in others:
        assert criterion not in text, f"another story's criterion reached this preview: {criterion}"


async def test_the_panel_paints_what_the_reader_returned(fixture_project):
    """FR4 and FR7 joined: the text reaches the panel beneath the column, for the highlighted row.

    Read through the app rather than the function, because a preview that is correct and never
    painted satisfies every test above.
    """
    async with ServerPool() as pool:
        epics = await rows(pool, fixture_project, EPICS)
        stories = await rows(pool, fixture_project, STORIES)

        epic = next(row for row in epics if row["title"] == "Eighth epic")
        under = [row for row in stories if row["epic_id"] == epic["id"]]
        second = next(row for row in under if row["title"] == "The second previewed story")

        view = ProjectView(
            "fixture",
            fixture_project,
            epics=(
                EpicView(
                    epic["id"],
                    epic["title"],
                    "ready",
                    stories=tuple(
                        StoryView(row["id"], row["title"], row["status"]) for row in under
                    ),
                ),
            ),
        )

        async with board([view], reader=previews(pool)) as (app, pilot):
            await pilot.pause()
            await pilot.pause()

            assert epic["title"] in "\n".join(preview(app, "epic"))

            # Down to the second story, whose criterion no other story shares.
            await pilot.press("right", "right", "down")
            await pilot.pause()
            await pilot.pause()

            painted = "\n".join(preview(app, "story"))

    assert app.selection.current_story.title == second["title"]
    assert criteria_of("second_previewed")[0] in painted
    assert criteria_of("first_previewed")[0] not in painted


#: What the planted projected files say. A board reading one would put this in a preview, and it
#: appears nowhere in the database, so finding it in preview text is unambiguous.
PROJECTED = "PROJECTED-FILE-CONTENT: this line exists only on disk."


def project_markdown(root) -> list:
    """Plant projected `.md` files where a board looking for them would look.

    **The fixture project has none of its own** — dpm's write tools put rows in the database and
    nothing on disk — so a must-NOT asserted against it as built is satisfied by a board that reads
    projected files whenever they are there, which is every real project. The files have to exist
    for their not being read to mean anything.
    """
    planted = []

    for relative in ("docs/epics/10-08-eighth.md", "docs/stories/second-previewed.md"):
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"# Eighth epic\n\n{PROJECTED}\n")
        planted.append(path)

    return planted


async def test_building_a_preview_opens_no_projected_file(fixture_project, monkeypatch):
    """must NOT — a preview is built from rows, never from the projected `.md` on disk.

    The static sweep in `test_isolation.py` bounds what the board's modules *can* open; this bounds
    what actually happens while previews are being built, against a project that has projected
    files to be tempted by.

    Two independent checks, because either alone has a hole: the recorded opens catch a read
    however the path was arrived at, and the absence of :data:`PROJECTED` from the preview text
    catches one that reached the file by some route other than :func:`open`.

    Both previews run. The story preview reads different tools from the document one, and a
    must-NOT that covered one of them would leave the other free.
    """
    planted = project_markdown(fixture_project)

    assert all(path.exists() for path in planted), "nothing was planted, so nothing is refused"

    opened: list[str] = []
    real_open = builtins.open

    def watched(file, *args, **kwargs):
        opened.append(str(file))

        return real_open(file, *args, **kwargs)

    async with ServerPool() as pool:
        epic = await document_row(pool, fixture_project, EPICS, "Eighth epic")
        story = next(
            row
            for row in await rows(pool, fixture_project, STORIES)
            if row["title"] == "The second previewed story"
        )

        monkeypatch.setattr(builtins, "open", watched)

        document = await read_document_preview(
            pool, fixture_project, EpicView(epic["id"], epic["title"], "ready")
        )
        told = await read_story_preview(
            pool, fixture_project, StoryView(story["id"], story["title"], "pending")
        )

        monkeypatch.undo()

    inside = [path for path in opened if str(fixture_project) in path]

    assert inside == [], f"a preview was built by opening a file in the project: {inside}"
    assert PROJECTED not in document, "the epic preview is rendering the file, not the rows"
    assert PROJECTED not in told, "the story preview is rendering the file, not the rows"
    assert document and told, "no preview was produced, so the checks above watched nothing"
