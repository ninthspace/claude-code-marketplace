# dpm Shared Skill Conventions

Procedures used by several dpm skills. A skill that says "follow the shared **X** procedure" means
the section of that name below.

**Read this file when a skill references it.** dpm ships no session hook, so nothing injects these
sections — a skill names the file and reads it, which costs one read per run rather than seven
sections repeated in twenty-two files.

**What earns a place here.** A section belongs in this file when several skills reference it. One
referenced by a single skill belongs in that skill; one referenced by none is documentation and
belongs in `docs/`.

**Nothing here describes what a tool already does.** Prose restating a tool's behaviour is a second
specification of it, and the two drift — the prose being the copy that no test holds to account.
Numbering is the clearest case: `mcp__dpm__create_epic` allocates, and a paragraph here explaining
how would be a rule nothing enforces.

**A procedure carrying judgement the tool does not is a different thing, and it belongs here.**
Which sessions are stale, how many observations to select and on what, whether a retro's lesson is
presented before it is used — none of that is in a tool, and all of it has to be the same in every
skill or the corpus behaves differently depending on which one a project happens to run. The test is
not "does this mention a tool" but "would two skills implementing it separately agree". **Perspectives**
has always been here on those terms, and the three startup procedures below joined it for the same
reason: they were near-verbatim in ten files, which is ten places for one of them to drift.

**Where a skill's own judgement lives.** Each procedure names the small part that is genuinely
per-skill — the scope keyword, what the session `state` must hold, what an incorporated lesson
changes — and the skill states that part and nothing else.

## Session Startup

Every skill's run is one `session` row. There is no progress file.

1. `mcp__dpm__list_session` for what is open. A row whose `updated_at` is more than three days old
   is stale; present those and let the user decide, deleting nothing that was not named.
2. On a resume, `mcp__dpm__adopt_session` with the new session id and the predecessor's, passing
   `include_body` so the state comes back. It returns what the earlier run carried and points the
   old row at this one.
3. Otherwise `mcp__dpm__create_session` with the harness's session id, the skill's own name as
   `skill`, and the step or phase about to start as `phase`.

As each step closes, `mcp__dpm__update_session` moves `phase` on and carries the accumulated
`state` — a blob the skill defines and dpm does not interpret.

**What `state` holds is the per-skill part, and it is the part worth stating.** It is the run's
memory: what a step settled goes in as it is settled, because a step summarised only in the
conversation is one that has to be re-facilitated after a compaction. **It does not hold anything
that is a column** — a status, a number, a flag — because a copy in the blob is a second answer that
goes stale the moment the row moves.

## Library Check

1. `mcp__dpm__list_library`, then `mcp__dpm__list_library_scope` on each, to find those scoped to
   the skill's own keyword or to `all`.
2. Read the ones that apply with `mcp__dpm__list_document_section` and
   `mcp__dpm__read_document_section`, passing `include_body` — without it a section comes back as a
   heading with no text, and a run that omitted it has read nothing and does not know.

A section a consolidation has superseded is not returned — the list omits it — so a document that has
been amended and reconciled reads as one document rather than as a body followed by the amendments it
already absorbed.

The per-skill part is the scope keyword and *when* the documents bear: a coding standard is read
before code is written, an architecture document before a structural decision.

## Retro Awareness

1. `mcp__dpm__list_retro`, then `mcp__dpm__list_observation` on the ones whose subject overlaps this
   work, passing `include_body`.
2. Each observation's category is `mcp__dpm__list_observation_category` resolved against
   `mcp__dpm__list_taxonomy`, which is called with a `limit` above the seeded count so a project
   that added terms does not lose them to the default page.
3. **Select the few most relevant rather than everything from the newest retro**, judging by subject
   overlap and category and using recency only to break a tie.
4. Present the selection, naming its source retro, and ask whether to incorporate.

A retired observation is not returned — the list omits it — so there is nothing to skip and no
marker in the text to read for.

The per-skill part is what an incorporated lesson *changes*: which step or phase a category routes
to, or, where a skill has no such routing, what a lesson turns into instead. A lesson that cannot be
turned into something this skill does is one to leave.

**A skill that must not merely offer this may replace step 4 with a gate of its own** — `dpm:do`
does, requiring a disposition per observation and recording each as a row. Steps 1 to 3 are the same
either way.

## Gate Presentation

`AskUserQuestion` carries the *gate*, not the *content*. The preview panel that renders it is sized
for short prompts and short option labels, and long content is truncated there.

Render documents, drafts, alternatives, tables and lists of proposed changes in the message body
**before** the `AskUserQuestion` call. The question itself carries only the decision — "Approve" /
"Request changes" / "Stop", or "Choose A / B / C". If what the user needs to read runs past a
sentence or two, it belongs in the message body.

Option `preview` fields are for small presentational comparisons — a wording choice, a short
layout variant. They are transient and easy to miss, so nothing the user needs to keep goes there.

## Perspectives

Some sections invite agent personas to weigh in before the user decides.

1. **Load the roster** with `mcp__dpm__list_agent`. Its rows carry `display_name`, `icon`, `role`,
   `personality` and `communication_style`. A project that added a persona has it in that list;
   nothing is read from a file and nothing is invented beyond the row.
2. **Select two or three** whose `role` and `personality` bear on the decision at hand.
3. **Each gives one or two sentences in character**, formatted `{icon} **{display_name}**:
   {perspective}`. Let `communication_style` and `personality` drive tone and framing so the voices
   stay distinct.
4. **A perspective that only echoes what has been said is skipped.** The value is in surfacing a
   trade-off or challenging an assumption.
5. **Weave them into the facilitation** before the user decides, rather than presenting them as a
   section of their own.

If `mcp__dpm__list_agent` returns nothing, skip perspectives and carry on.

## Conversational Output

Aim for the shortest response that does the job. A skill's product is the rows it writes and the
artefact rendered from them; the conversation around it is scaffolding.

Between gates the useful shapes are: the content itself followed by the gate; one line recording
what was decided and where it went; the step and what it found rather than the process; and
anything unexpected said plainly with its evidence, at the moment it turns up rather than saved for
a summary.

The test is whether someone reading only the narration still knows where they are and what was
decided.

### Correcting yourself

Narrate a correction to something said earlier when the error would change the user's conclusions
or decisions. When it would not, make the correction and carry on without remarking on it. A
running commentary on your own earlier wording spends attention the user was giving to the decision
in front of them.

## Written Deliverable Length

Let a document's length match what the task needs. A spec covering three requirements is shorter
than one covering thirty, and that is the right outcome rather than an incomplete one.

Leave out padding that restates a point because a section looked thin, closing recaps of what the
reader has just read, and headings kept because a template offered them and then filled with "N/A".

This is calibration, not a budget. No artefact carries a fixed word or section count.

## Artifact Publishing

A skill may publish an HTML artifact from its output **on request**. It is always separately
confirmed and never the default.

1. **Offer only when asked**, or when the skill's own text names an artifact worth offering.
2. **Confirm with a gate** before publishing. Publishing puts the content on a URL.
3. **Justify it in one line** — what the visual carries that the prose cannot. If that line cannot
   be written, the artifact has not earned its place.
4. **The artifact is a view, never a source.** Nothing reads it back; the rows remain the record.

## A Closing Note on Length and Tone

Say what the step found and what happens next, then stop. Where two phrasings carry the same
meaning, use the shorter one.

Keep the tone plain and direct, warm enough to be good company across a long facilitation. State
confidence where the evidence supports it and uncertainty where it does not; neither needs padding.
