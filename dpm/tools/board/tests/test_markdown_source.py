"""Story 1 — the preview builders emit markdown source (FR6).

Both builders used to return display text: a title on its own line, a bare `Acceptance criteria:`
label, a task's description indented beside it. Every one of those is a paragraph to a markdown
renderer, so a panel that rasterises this source would show a run of prose where the structure the
rows already carry ought to be.

**Parsed rather than pattern-matched.** What "is a heading" and "is nested under" mean is decided by
the markdown parser Rich itself uses — `Markdown.parsed` is the markdown-it token stream that the
panel will render in story 2 — rather than by a rule about leading hashes written here. A second
model of markdown would agree with the renderer until the day it did not.
"""

from __future__ import annotations

import pytest
from rich.markdown import Markdown

from board_view import StoryView, document_preview, story_preview

#: A task description, held here because three tests ask a different question about the same string.
DESCRIPTION = "Addresses the error path, not the happy path."


def a_document() -> tuple[dict, list[dict]]:
    """A document row and its sections, as the read tools return them."""
    return (
        {"id": "01ABC", "title": "The eighth epic"},
        [
            {"heading": "What this delivers", "body": "A paragraph of prose.\n"},
            {"heading": "What it does not", "body": ""},
        ],
    )


def a_story() -> tuple[StoryView, list[dict], list[dict]]:
    """A story, one criterion and one task carrying a description."""
    return (
        StoryView("01STORY", "Builders that emit markdown source", "pending"),
        [{"id": "01CRIT", "text": "The builder returns the title as a heading."}],
        [{"id": "01TASK", "title": "Rewrite the builder", "description": DESCRIPTION}],
    )


def headings(source: str) -> list[tuple[str, str]]:
    """Every heading in ``source`` as the parser sees it: its tag, and the text under it.

    Rich's own parse, because the panel that renders this source in story 2 renders *these* tokens.
    A test asking whether a line starts with `#` would agree with it right up until a heading was
    written some other way, or a `#` appeared inside a fenced block.
    """
    tokens = Markdown(source).parsed
    found = []

    for index, token in enumerate(tokens):
        if token.type == "heading_open":
            found.append((token.tag, tokens[index + 1].content))

    return found


def test_a_documents_title_is_a_heading_over_its_sections():
    """Criterion 1 [unit]. One h1 for the document, an h2 per section, in that order.

    The levels matter rather than the mere presence of headings: a section heading at the same level
    as the document's title is a sibling of it, and a preview of a document with four sections then
    reads as five documents.
    """
    document, sections = a_document()

    found = headings(document_preview(document, sections))

    assert found[0] == ("h1", "The eighth epic"), found
    assert [tag for tag, _ in found[1:]] == ["h2", "h2"], found
    assert [text for _, text in found[1:]] == [section["heading"] for section in sections], found


def test_a_section_with_no_body_still_has_its_heading():
    """Criterion 1's other half, which the markdown rewrite could quietly have dropped.

    A heading followed immediately by another heading is what a missing body looks like, and that is
    the point — an `include_body` nobody asked for produces exactly this, and a builder that skipped
    empty sections would render a plausible outline instead.
    """
    document, sections = a_document()

    assert sections[1]["body"] == "", "the fixture no longer holds a section with an empty body"

    found = headings(document_preview(document, sections))

    assert ("h2", "What it does not") in found, found


def test_a_storys_criteria_and_tasks_are_markdown_lists():
    """Criterion 2 [unit]. Both groups are lists under headings of their own."""
    story, criteria, tasks = a_story()

    source = story_preview(story, criteria, tasks)
    found = headings(source)

    assert found[0] == ("h1", story.title), found
    assert [text for _, text in found[1:]] == ["Acceptance criteria", "Tasks"], found

    for token in Markdown(source).parsed:
        if token.type == "bullet_list_open":
            break
    else:
        raise AssertionError(f"neither group rendered as a list: {source!r}")

    assert f"- {criteria[0]['text']}" in source.splitlines(), source
    assert f"- {tasks[0]['title']}" in source.splitlines(), source


def test_a_task_description_is_nested_under_its_task():
    """Criterion 2's second half [unit]. Subordinate to the task, not beside it.

    Read from the token stream's nesting level rather than from the indent, because two spaces is
    only *usually* enough — what decides it is the content column the list marker left, and the
    parser is the thing that knows.
    """
    story, criteria, tasks = a_story()

    depths = nesting(story_preview(story, criteria, tasks))

    assert depths[DESCRIPTION] > depths[tasks[0]["title"]], (
        f"the description sits at the task's own level, so it reads as a second task: {depths}"
    )


def nesting(source: str) -> dict[str, int]:
    """Each inline run in ``source`` against the depth the parser puts it at."""
    return {token.content: token.level for token in Markdown(source).parsed if token.type == "inline"}


#: What a builder is allowed to contribute that came from no row: a markdown heading and nothing
#: else. A list marker is not on it because a marker never appears alone — it introduces row text,
#: and :func:`scaffolding` strips it before deciding.
STRUCTURE = "#"


def scaffolding(source: str, *, content: list[str]) -> list[str]:
    """Every line of ``source`` the builder invented rather than took from a row.

    A line is the rows' if what remains after its list marker appears in any of them. What is left
    is the builder's own — headings, and any label it wrote out as prose.
    """
    invented = []

    for line in source.splitlines():
        stripped = line.strip().removeprefix("- ")

        if stripped and not any(stripped in text for text in content):
            invented.append(line.strip())

    return invented


def no_label_survives(source: str, *, content: list[str]) -> None:
    """Assert every line the builder contributed itself is structure rather than prose.

    Shared by the rejection and its control, so what the control demonstrates is this assertion
    failing rather than a weaker copy of it written to be failed.
    """
    for line in scaffolding(source, content=content):
        assert line.startswith(STRUCTURE), (
            f"{line!r} came from no row and is not markdown structure, so it renders as a paragraph "
            "of prose above whatever it was introducing"
        )


def test_neither_builder_writes_a_plain_text_label():
    """Criterion 3, the must-NOT [unit]. Both builders, over everything they emit.

    Stated as a property rather than as a search for the two labels that were there: a rejection
    naming `Acceptance criteria:` is satisfied by a builder that renames it to `Criteria:`.
    """
    document, sections = a_document()
    story, criteria, tasks = a_story()

    no_label_survives(
        document_preview(document, sections),
        content=[document["title"], *(section["heading"] for section in sections)]
        + [section["body"] for section in sections],
    )
    no_label_survives(
        story_preview(story, criteria, tasks),
        content=[story.title, criteria[0]["text"], tasks[0]["title"], DESCRIPTION],
    )


def test_the_labelled_composition_is_what_the_rejection_catches():
    """The control for criterion 3, and it is the composition this story replaced.

    Without it the rejection is an absence, and an absence is satisfied by a builder that emits
    nothing at all. So the same assertion is run against the shape the builder used to produce —
    the story's title as a bare line and `Acceptance criteria:` as a bare label — and what it says
    is read, not merely that it raised.
    """
    story, criteria, tasks = a_story()
    labelled = "\n".join([story.title, "", "Acceptance criteria:", f"- {criteria[0]['text']}"])

    with pytest.raises(AssertionError) as raised:
        no_label_survives(labelled, content=[story.title, criteria[0]["text"]])

    assert "Acceptance criteria:" in str(raised.value), (
        f"the failure did not name the label it found: {raised.value}"
    )
