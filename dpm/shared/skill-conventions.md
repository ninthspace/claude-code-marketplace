# dpm Shared Skill Conventions

Procedures used by several dpm skills. A skill that says "follow the shared **X** procedure" means
the section of that name below.

**Read this file when a skill references it.** dpm ships no session hook, so nothing injects these
sections — a skill names the file and reads it, which costs one read per run rather than seven
sections repeated in twenty-two files.

**What earns a place here.** A section belongs in this file when several skills reference it. One
referenced by a single skill belongs in that skill; one referenced by none is documentation and
belongs in `docs/`.

**Nothing here describes what a tool already does.** Numbering, session state, roster loading,
library lookup and retro selection are each a tool call, written at the point of use. Prose
restating a tool's behaviour is a second specification of it, and the two drift — the prose being
the copy that no test holds to account.

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

1. **Load the roster** with `dpm_list_agent`. Its rows carry `display_name`, `icon`, `role`,
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

If `dpm_list_agent` returns nothing, skip perspectives and carry on.

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
