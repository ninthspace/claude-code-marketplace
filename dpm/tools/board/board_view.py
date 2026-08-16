"""What the three columns show, with no Textual import anywhere in it (AD2, FR4).

The board's view model and its labels live here so that what a row *says* is testable without
standing up an app — the same split `cpm/tools/board` uses, and the reason its view helpers were the
part of that board worth forking.

**Nothing here derives state.** Every value on the dataclasses below arrived from
:mod:`status_model`, which is the board's half of the contract at ``dpm/shared/status-model.md``.
A view that recomputed "is this blocked" from the rows it was handed would be the second
implementation AD5 exists to prevent, and it would be the one the user actually looks at.

**Colour carries state, so the label does not repeat it** (FR4). An epic row is its identity and its
progress; which state it is in comes from the style mapping applied to ``state``. The one
exception is a project the board could not read, where there is no progress to show and the state
*is* the row's content.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass, field
from pathlib import Path

from status_model import (
    BLOCKED,
    COMPLETE,
    EPIC_STATES,
    IN_PROGRESS,
    PENDING,
    READY,
    RETIRED,
    SUPERSEDED,
    WITHDRAWN,
    Candidate,
    Progress,
)

#: The states `z` hides, and the states it does not (FR19). Finished work is work that is finished:
#: complete, and the two ways a row is retired without being delivered.
#:
#: **Built from the model's own words rather than written out here.** `status_model.RETIRED` is
#: where "which statuses are terminal" is decided, and a second list in the view would agree with it
#: until the day a status was added — at which point the board would quietly go on showing rows the
#: model considers finished, which is the failure this filter exists to prevent.
HIDDEN_STATES = (COMPLETE, *RETIRED)

#: What a row shows in place of a figure it does not have — an epic with no stories, a project with
#: no epics. Not ``0/0``: that reads as complete, which is the whole of `progress()`'s rule.
NOTHING = "—"

#: A style per derived state (FR4). **Keyed on :data:`status_model.EPIC_STATES`, not written
#: alongside it**: a state added to the model has no style here and :func:`style_for` refuses it,
#: rather than the row rendering in whatever the default happens to be — which is indistinguishable
#: from every other row and therefore indistinguishable from a working board.
#:
#: Live work is bright and retired work is dim, so the two groups separate before any individual
#: colour is read. **No two states share a style**, which is what makes the colour carry the state
#: rather than merely accompany it: a mapping where blocked and in-progress are both "attention"
#: satisfies "colour carries state" and tells a user nothing.
STATE_STYLE: dict[str, str] = {
    READY: "green",
    IN_PROGRESS: "yellow",
    BLOCKED: "red",
    PENDING: "white",
    COMPLETE: "dim green",
    SUPERSEDED: "dim magenta",
    WITHDRAWN: "dim red",
}

#: The style for a project the board could not read. Outside the palette above, because it is not
#: a state of the *work* — it is a statement about the board's access to it.
UNREADABLE_STYLE = "bold red"

#: What a project shows while its own server is still being asked (NFR3). **A word, not a blank.**
#: The figure a read project shows in place of a count it does not have is :data:`NOTHING`, and a
#: project still being read would otherwise show the same thing — so a board that is working
#: correctly and a project with no epics at all would be one row on screen.
READING = "reading…"

#: The style for that row. Dim, like retired work: it is on screen, it is not yet news.
READING_STYLE = "dim"

#: The live-session pill (FR12): a project with work running in a session the board launched.
#:
#: The dot is what makes it readable at a glance in a column of names and figures; the word is what
#: makes it readable at all in a terminal that renders the dot as a box.
LIVE = "● live"

#: The pill's own colour, which is **not** the row's (FR19). Blue is unused by everything else the
#: Projects column paints — a read row's default foreground, a dim `reading…` row, a bold red
#: unreadable one — so the pill reads as its own thing on any row it lands on.
#:
#: Foreground only, and deliberately: the cursor bar samples a row's colour *and its background*
#: from the strip, so a pill carrying a background of its own would be a second background on a
#: highlighted row and the bar would blend toward whichever came first.
PILL_STYLE = "bold blue"


#: The integrity badge (FR17): a project whose `check_integrity` sweep found something wrong.
#:
#: **A third marker on this board, and it is deliberately not either of the other two.** The pill's
#: `●` says a session is running now and the ralph `▸` says a keypress would start one; both are
#: about work in flight, and this is about the database underneath it being wrong. A user who has to
#: tell three markers apart by position has one marker as far as a glance is concerned.
#:
#: The word is here for the reason the pill's is: a terminal that renders `⚠` as a box would leave
#: a project's row saying nothing at all, on the one row where saying nothing is worst.
BROKEN = "⚠ integrity"

#: The badge's own colour, decided here rather than ported: the CPM board has no integrity check and
#: therefore no badge to copy the styling of. Red because what it reports is a database that is
#: wrong, which is the one thing on this column that is an error rather than a state — and the only
#: other red on the board belongs to a row the badge never appears on, since a project the board
#: could not read carries no claim about a database nobody opened.
#:
#: Foreground only, for :data:`PILL_STYLE`'s reason.
BADGE_STYLE = "bold red"


#: The marker an epic carries while it is in the ralph selection (FR14).
#:
#: **Not the pill's ``●``**, which is on this same board and means something else — a session running
#: now, rather than one a keypress would start. Two markers a user has to tell apart by position are
#: one marker as far as a glance is concerned.
RALPH_MARKER = "▸"


def ralph_label(row: "EpicView", selected: bool) -> str:
    """An epic row's label with its selection marker in front of it (FR14).

    **In front, and the blank is as deliberate as the marker.** Every epic row carries one or the
    other, always, so a selection never shifts the column sideways and a row's text stays where the
    eye left it. Leading rather than trailing because a row is as wide as its title and its figure:
    a marker on the end is the first thing a narrow column clips, which is a selection the board
    holds and the user cannot see.
    """
    return f"{RALPH_MARKER if selected else ' '} {row.label}"


def live_pill(sessions: int) -> str:
    """The pill for ``sessions`` running sessions, or nothing when none are (FR12).

    The count appears only when there is more than one, because "● live 1" invites the reader to
    work out what the other number would have been. One session is the ordinary case and the bare
    pill is its answer.
    """
    if sessions <= 0:
        return ""

    return LIVE if sessions == 1 else f"{LIVE} {sessions}"


def integrity_badge(broken: int) -> str:
    """The badge for ``broken`` findings, or nothing when there are none (FR17).

    **The count is always shown**, unlike the live pill's, and the difference is what the number is
    for. One running session is the ordinary case, so "● live 1" invites a reader to wonder what the
    other number would have been; one integrity violation is not ordinary, and the count is the size
    of the problem rather than a detail beside it.
    """
    if broken <= 0:
        return ""

    return f"{BROKEN} {broken}"


def style_for(state: str) -> str:
    """The style a row in ``state`` renders in.

    Raises rather than defaulting. A state with no style is a bug in this table, and the shape it
    takes if this returns something is a row that renders exactly like every other row — a failure
    that looks, on screen, like a board with nothing to report.
    """
    try:
        return STATE_STYLE[state]
    except KeyError:
        known = ", ".join(EPIC_STATES)

        raise KeyError(f"no style for state {state!r}; the model's states are: {known}") from None


def style_collisions(rendered: dict[str, str]) -> list[str]:
    """States that come out the same, named — empty when every one of them is distinguishable.

    Takes a state to whatever it renders as: a style for an epic row (FR4), the whole label for a
    project in one of FR11's named states (48-06). The rule is the same either way and worth
    stating once — two states a user cannot tell apart are one state as far as the screen is
    concerned, whatever the code calls them.

    Returns complaints rather than asserting, so the must-NOT can drive this same function over a
    planted mapping instead of restating its rule in a second place.
    """
    by_rendering: dict[str, list[str]] = {}

    for state, rendering in rendered.items():
        by_rendering.setdefault(rendering, []).append(state)

    return [
        f"{' and '.join(sorted(states))} both render as {rendering!r}"
        for rendering, states in sorted(by_rendering.items())
        if len(states) > 1
    ]


@dataclass(frozen=True)
class StoryView:
    """One row of the Stories column. ``state`` is the story's own status word."""

    id: str
    title: str
    state: str

    @property
    def label(self) -> str:
        return self.title


@dataclass(frozen=True)
class EpicView:
    """One row of the Epics column, with the stories that belong under it.

    ``state`` is :func:`status_model.epic_state`'s answer and ``progress`` is
    :func:`status_model.progress`'s — both computed before this object exists, so a caller cannot
    get a different answer by asking the view.

    ``kind`` is the document kind the row's preview is read through. Every row this story puts in
    the column is an epic, and the field is not speculative: FR7 requires the preview to work for a
    spec and a retro too, and the read tool is named for the kind — ``read_spec`` refuses an id
    that turns out to be an epic rather than answering for it.

    ``candidate`` is :func:`status_model.candidates`' answer for this row, when it has one — what
    could be done to it next (FR9), and therefore which command a launch from this row runs (FR8).
    It is carried rather than recomputed for the same reason ``state`` is: a row that worked out
    "this epic is ready" for itself would be a second implementation of the rule the user is
    actually looking at.
    """

    id: str
    title: str
    state: str
    progress: Progress | None = None
    stories: tuple[StoryView, ...] = ()
    kind: str = "epic"
    candidate: Candidate | None = None

    @property
    def label(self) -> str:
        return f"{self.title}  ·  {self.progress or NOTHING}"


@dataclass(frozen=True)
class ProjectView:
    """One row of the Projects column: a registered project, or the reason it has no rows.

    ``unreadable`` carries the named state from :mod:`mcp_client` when the project could not be
    read — a project with no database, a server that would not answer. **It is a row rather than an
    absence** (FR11): every other project goes on rendering, and this one says why it cannot.

    ``remedy`` is what to do about it, and it arrives here rather than being looked up: this module
    derives nothing, and a lookup would make the row's text depend on a table it would then have to
    import. The pair is FR11's requirement — a state without its remedy names a problem and stops.

    ``pending`` is the third thing a row can be, and it exists because the first two do not cover
    it (NFR3): the browser opens on rows built from the registry alone and fills each one in as its
    own server answers. Between those two moments the project is neither read nor unreadable.
    """

    name: str
    path: Path
    epics: tuple[EpicView, ...] = ()
    progress: Progress | None = None
    unreadable: str | None = None
    remedy: str | None = None
    pending: bool = False
    live: int = 0

    #: How many things `check_integrity` found wrong in this project (FR17). Zero for a project
    #: reporting `ok`, and zero for one the board never got to read — an unreadable project shows
    #: its FR11 state instead, and a badge beside it would be a claim about a database nobody opened.
    violations: int = 0

    @property
    def summary(self) -> str:
        """The row's left-hand side: what the project is called and how it is getting on.

        Separate from :attr:`label` because the pill and the badge are no longer part of the same
        run of text — the board lays them out in cells of their own against the column's right edge
        (FR19) — and the name is the part that gives when there is not room for everything.
        """
        if self.unreadable is not None:
            named = f"{self.name}  ·  {self.unreadable}"

            return f"{named}: {self.remedy}" if self.remedy else named

        if self.pending:
            return f"{self.name}  ·  {READING}"

        return f"{self.name}  ·  {self.progress or NOTHING}"

    @property
    def label(self) -> str:
        """The whole row as one string — the summary with whatever markers it carries after it.

        **Composed from the same pieces the board lays out**, rather than written out a second time
        here: this is the row as anything that wants a plain string reads it, and a second spelling
        of the pill would be a second answer to what the row says.

        The pill and the badge each appear only when there is one, so a project with nothing running
        and nothing wrong reads exactly as it did before either existed.
        """
        if self.unreadable is not None or self.pending:
            return self.summary

        return self.summary + "".join(
            markers(badge=integrity_badge(self.violations), pill=live_pill(self.live))
        )


@dataclass(frozen=True)
class Result:
    """One search hit, carrying where it came from and where selecting it goes (FR15).

    ``project`` is the path of the project whose server answered, and it is not optional: results
    from several projects arrive in one list, and a hit that did not name its own is a line of
    matching prose a user cannot act on — it may be in any of the registered trees.

    ``document`` is the row in the Epics column selecting this result lands on, when the board can
    name one. **It is ``None`` for a hit whose row the board holds nothing about**, which is an
    honest state rather than a gap: `search` answers over fifteen indexed entities and the browser's
    three columns hold documents and stories, so a requirement or a review finding matches a query
    the board cannot navigate to any deeper than the project it is in. Hiding those results would be
    the false negative dpm's search tool documents — an empty answer read as an absence.

    ``entity`` and ``entity_id`` are the pair dpm returns for exactly this reason: they are what a
    caller turns into ``read_<entity>({id})``, and they are carried unchanged so the row says what
    it matched rather than what the board made of it.
    """

    project: Path
    name: str
    entity: str
    entity_id: str
    excerpt: str
    document: str | None = None
    heading: str | None = None

    @property
    def label(self) -> str:
        """The row as a user reads it: which project, which row, and the matching prose."""
        where = self.heading or self.document or self.entity_id

        return f"{self.name}  ·  {where}  ·  {self.excerpt}"


@dataclass(frozen=True)
class Gap:
    """One requirement no coverage row names, and where selecting it goes (FR16).

    The same shape as :class:`Result` and for the same reasons, because it is the same kind of
    answer: rows gathered from every registered project at once, presented in one list, each of
    which a user then wants to *go to*.

    ``project`` is not optional, for :class:`Result`'s reason exactly — a requirement label with no
    project attached could be in any of the registered trees.

    ``document`` is the row in the Epics column selecting this gap lands on, and **it is ``None``
    whenever the board holds no such row**. A requirement belongs to a spec, and the Epics column
    holds epics; a gap therefore usually resolves to nothing, and the cursor moves to the project
    and stops there. Naming the spec anyway would point the column at a row that is not in it —
    the *absence is carried rather than invented*, which is the same answer FR15 reached from the
    other direction.
    """

    project: Path
    name: str
    requirement: str
    spec_id: str
    document: str | None = None

    @property
    def label(self) -> str:
        """The row as a user reads it: which project, and which requirement."""
        return f"{self.name}  ·  {self.requirement}"


def visible(rows: Sequence, *, show_retired: bool) -> tuple:
    """``rows`` with the finished ones dropped, or all of them when ``show_retired`` (FR19).

    One function for both columns, because an epic and a story are hidden on the same grounds: each
    carries a ``state``, and what the filter reads is that word against `HIDDEN_STATES`. A second
    implementation per column is how a board ends up hiding a complete epic and showing a complete
    story under a project that has both.

    `HIDDEN_STATES` is read here rather than closed over, so a test can widen it and watch the
    filter take something it should not — which is the only way to show that the live states are
    kept by the filter rather than by there having been nothing to take.
    """
    return tuple(rows) if show_retired else tuple(row for row in rows if row.state not in HIDDEN_STATES)


@dataclass
class Selection:
    """Where the cursor is in each column, and what the columns below it therefore hold.

    A plain index per column, clamped on every rebuild rather than remembered as an object: an epic
    can vanish from a refreshed project between one read and the next, and a cursor holding the row
    itself would then point at a row that is not in the list. Clamping is what makes a disappearing
    selection a moved cursor instead of an empty column.
    """

    projects: list[ProjectView] = field(default_factory=list)
    project: int = 0
    epic: int = 0
    story: int = 0

    #: Whether finished work is shown (FR19). Off, because a board opened on a long-running project
    #: otherwise opens on its history: the rows a person came to look at are the ones still moving.
    show_retired: bool = False

    def clamp(self) -> None:
        """Pull every index back inside the list it indexes, innermost last."""
        self.project = _clamp(self.project, len(self.projects))
        self.epic = _clamp(self.epic, len(self.epics))
        self.story = _clamp(self.story, len(self.stories))

    @property
    def current_project(self) -> ProjectView | None:
        return _at(self.projects, self.project)

    @property
    def epics(self) -> tuple[EpicView, ...]:
        project = self.current_project

        return visible(project.epics, show_retired=self.show_retired) if project is not None else ()

    @property
    def current_epic(self) -> EpicView | None:
        return _at(self.epics, self.epic)

    @property
    def stories(self) -> tuple[StoryView, ...]:
        epic = self.current_epic

        return visible(epic.stories, show_retired=self.show_retired) if epic is not None else ()

    @property
    def current_story(self) -> StoryView | None:
        return _at(self.stories, self.story)


def document_preview(document: dict, sections: list[dict]) -> str:
    """A document's preview: its title, then each section as a heading over its body (FR7).

    Built from the rows the tools returned and nothing else — never from the projected ``.md``
    file, which is a rendering of these same rows and can be stale, absent, or edited by hand into
    something the database does not say.

    A section whose body is empty still shows its heading. That is not padding: a read that forgot
    ``include_body`` returns every heading and no text, and a preview that hid empty sections would
    render an *apparently reasonable* outline instead of showing that the prose is missing.

    **Markdown source, not display text** (FR6). The title is a level-1 heading and each section a
    level-2 one beneath it, so the panel can rasterise the structure the rows already have — a
    section's own body is markdown as it was written, and nothing here escapes or reflows it.
    """
    lines = [f"# {document.get('title') or document.get('id', '')}"]

    for section in sections:
        heading = f"## {section.get('heading') or ''}".rstrip()
        lines += ["", heading, "", (section.get("body") or "").rstrip()]

    return "\n".join(lines).rstrip()


def story_preview(story: StoryView, criteria: list[dict], tasks: list[dict]) -> str:
    """A story's own acceptance criteria and tasks (FR7) — this story's, not its epic's.

    The rows arrive already scoped by ``story_id``, so what is rendered here is what was asked
    for. Filtering an epic's whole criterion set in the caller would be a join the list tools exist
    to remove, and it goes wrong quietly the moment there are more rows than one page.

    **A criterion is its text, and ``list_story_criterion`` withholds that text by default.** A
    read that forgot ``include_body`` returns a row per criterion carrying no criterion, so the
    fallback is the id rather than an empty bullet: a preview of blank lines reads as a story
    nobody wrote criteria for, and an id reads as something missing.

    **Markdown source, not display text** (FR6). The two groups are headings rather than the bare
    ``Acceptance criteria:`` label they used to be — a label ending in a colon is a paragraph to
    every markdown renderer, and it reads as prose sitting above a list rather than as the list's
    own title. A task's description is a *nested* item rather than a second line beside its task:
    two spaces is the indent the ``- `` marker leaves, and it is what makes the description belong
    to the task instead of to whatever follows it.
    """
    lines = [f"# {story.title}"]

    if criteria:
        lines += ["", "## Acceptance criteria", ""]
        lines += [f"- {row.get('text') or row['id']}" for row in criteria]

    if tasks:
        lines += ["", "## Tasks", ""]

        for row in tasks:
            lines.append(f"- {row.get('title') or row['id']}")

            if row.get("description"):
                lines.append(f"  - {row['description']}")

    return "\n".join(lines)


def markers(*, badge: str, pill: str) -> list[str]:
    """Whichever markers a row carries, each with the gap that goes before it (FR19).

    **The badge first and the pill outermost**, which is where the CPM board puts the pill and
    therefore where a reader of both looks for it; dpm's badge, which that board has no equivalent
    of, goes inboard rather than displacing it.

    **Two spaces before each**, which is the gap the CPM board puts before its pill. A row carrying
    both therefore needs 25 cells for its markers alone, and one more for whatever is left of the
    name — so below 26 cells a row with a live session *and* a broken database cannot show both
    whole, and what a too-narrow layout gives up is the end of the outermost one. That is a floor
    rather than a bug to route around: the Projects column is 24 cells at its narrowest and sizes to
    its content above that, so it is reached only by a terminal too narrow for the third column to
    hold anything either.

    One list rather than a suffix apiece, because the gap before a marker depends on what is beside
    it: a rule each marker knew for itself would be a rule each one got right alone and wrong
    together — which is how the string form and the painted row came to disagree about their order.
    """
    return [f"  {text}" for text in (badge, pill) if text]


def _clamp(index: int, length: int) -> int:
    """An index inside ``length``, or 0 for an empty list."""
    if length <= 0:
        return 0

    return max(0, min(index, length - 1))


def _at(rows, index: int):
    """The row at ``index``, or ``None`` — an empty column has no current row."""
    return rows[index] if 0 <= index < len(rows) else None
