# dpm Shared Skill Conventions

Procedures used by several dpm skills. A skill that says "follow the shared **X** procedure" means
the section of that name below.

**Read this file when a skill references it.** dpm ships no session hook, so nothing injects these
sections — a skill names the file and reads it, which costs one read per run rather than seven
sections repeated in twenty-two files.

**What earns a place here.** A section belongs in this file when several skills reference it. One
referenced by a single skill belongs in that skill; one referenced by none is documentation rather
than context, and belongs wherever the project keeps its documentation.

**Nothing here describes what a tool already does.** Prose restating a tool's behaviour is a second
specification of it, and the two drift — the prose being the copy that no test holds to account.
Numbering is the clearest case: `mcp__plugin_dpm_dpm__create_epic` allocates, and a paragraph here explaining
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

Every skill's run is one `session` row, and nothing else on disk records where it reached.

1. `mcp__plugin_dpm_dpm__list_session` for what is open. A row whose `updated_at` is more than three days old
   is stale; present those and let the user decide, deleting nothing that was not named.
2. On a resume, `mcp__plugin_dpm_dpm__adopt_session` with the new session id and the predecessor's, passing
   `include_body` so the state comes back. It returns what the earlier run carried and points the
   old row at this one.
3. Otherwise `mcp__plugin_dpm_dpm__create_session` with the harness's session id, the skill's own name as
   `skill`, and the step or phase about to start as `phase`.

As each step closes, `mcp__plugin_dpm_dpm__update_session` moves `phase` on and carries the accumulated
`state` — a blob the skill defines and dpm does not interpret.

**What `state` holds is the per-skill part, and it is the part worth stating.** It is the run's
memory: what a step settled goes in as it is settled, because a step summarised only in the
conversation is one that has to be re-facilitated after a compaction. **It does not hold anything
that is a column** — a status, a number, a flag — because a copy in the blob is a second answer that
goes stale the moment the row moves.

### Resuming a step

**On a resume, and after a compaction, the rows say what was written and `state` does not.** `state`
records where a run believed it had reached; the rows record what it actually did, and the two part
company exactly when a run is interrupted between a write and the update that would have noted it.

So before a resumed step writes anything, it **lists the rows that step writes, under the parent it
writes them to**, and proposes only what is missing. Never a row a list has just returned. Each
skill names the ordered read for its own step — which lists, scoped to what — because only the
skill knows which rows its step produces.

**A step whose rows exist for some parents and not others resumes at the first parent without
them.** A production loop running once per epic is the common case, and "some are written" is not a
position `state` can express while a list can.

### Reading back what was written

**A run of writes is read back before the next unit begins**, and the read-backs go in **one**
message rather than one message per row. A row written and never read is a row nobody has seen
succeed; a read-back per row is the same information at many times the cost.

**Each row is checked by its label, never by an id held from an earlier call.** A label — `FR7`,
`Story 3`, a slug — is checkable against the artefact in front of the reader. Comparing an id with
an id the run is holding confirms that two calls agree, which is a weaker claim and usually a
vacuous one.

**Every count in a closing summary comes from the last report, not from a tally of the calls sent.**
A run that adds up its own writes is counting what it believes it did; the report counts what is
there, and the difference between the two is precisely what a closing summary exists to surface.

## Library Check

1. `mcp__plugin_dpm_dpm__list_library`, then `mcp__plugin_dpm_dpm__list_library_scope` on each, to find those scoped to
   the skill's own keyword or to `all`.
2. Read the ones that apply with `mcp__plugin_dpm_dpm__list_document_section` and
   `mcp__plugin_dpm_dpm__read_document_section`, passing `include_body` — without it a section comes back as a
   heading with no text, and a run that omitted it has read nothing and does not know.

A section a consolidation has superseded is not returned — the list omits it — so a document that has
been amended and reconciled reads as one document rather than as a body followed by the amendments it
already absorbed.

The per-skill part is the scope keyword and *when* the documents bear: a coding standard is read
before code is written, an architecture document before a structural decision.

## Retro Awareness

1. `mcp__plugin_dpm_dpm__list_retro`, then `mcp__plugin_dpm_dpm__list_observation` on the ones whose subject overlaps this
   work, passing `include_body`.
2. Each observation's category is `mcp__plugin_dpm_dpm__list_observation_category` resolved against
   `mcp__plugin_dpm_dpm__list_taxonomy`, which is called with a `limit` above the seeded count so a project
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

**A gate is two steps, and it is performed as two steps.** The draft goes in the message body as
its own items — the requirements listed, the stories named, the sections written out — and the
`AskUserQuestion` call goes in that same message. Not worked out in reasoning nobody can see, and
not left in an earlier message that is no longer the one being answered: a user approving a gate is
reading the message it arrived in, and anything not in it is not what they approved.

**Nothing a gate decides is written before it is answered.** A row created while the question is
still open is a decision taken on the user's behalf and then presented as a choice. Where a draft
has to be assembled first, assemble it in the message; where a write cannot wait, the gate was in
the wrong place.

## Perspectives

Some sections invite agent personas to weigh in before the user decides.

1. **Load the roster** with `mcp__plugin_dpm_dpm__list_agent`, passing `include_body`. Its rows carry
   `display_name`, `icon`, `role`, `personality` and `communication_style` — **the last two are body
   columns**, so without that argument the list comes back with names and roles and the voices below
   are woven from nothing. A project that added a persona has it in that list; nothing is read from
   a file and nothing is invented beyond the row.
2. **Select two or three** whose `role` and `personality` bear on the decision at hand.
3. **Each gives one or two sentences in character**, formatted `{icon} **{display_name}**:
   {perspective}`. Let `communication_style` and `personality` drive tone and framing so the voices
   stay distinct.
4. **A perspective that only echoes what has been said is skipped.** The value is in surfacing a
   trade-off or challenging an assumption.
5. **Weave them into the facilitation** before the user decides, rather than presenting them as a
   section of their own.

If `mcp__plugin_dpm_dpm__list_agent` returns nothing, skip perspectives and carry on.

## Conversational Output

Aim for the shortest response that does the job. A skill's product is the rows it writes and the
artefact rendered from them; the conversation around it is scaffolding.

Between gates the useful shapes are: the content itself followed by the gate; one line recording
what was decided and where it went; the step and what it found rather than the process; and
anything unexpected said plainly with its evidence, at the moment it turns up rather than saved for
a summary.

The test is whether someone reading only the narration still knows where they are and what was
decided.

Keep the tone plain and direct, warm enough to be good company across a long facilitation. State
confidence where the evidence supports it and uncertainty where it does not; neither needs padding.

### Saying what a row holds

**Narration names what a column means, never the value it holds.** A run that has read `plan` on a
story says *this story needs designing in full first*, or *planning this one inline* — not "Story 1
has plan: 1, so I'll explore". The same goes for every other column a skill reads and then talks
about: a criterion that was met, a rejection rather than `polarity: 'must_not'`, work that is
finished rather than `status: complete`.

The two are not the same sentence with different formatting. The value says how the decision is
stored, which is a fact about the database; the meaning says what happens next, which is the only
half the reader can act on — and the value is not even reliable as shorthand, because a reader who
has not seen the schema cannot tell which way round a flag runs.

**Where a value is an argument to a tool call, write it as the argument it is.** `plan: 1` in a
sentence specifying a `create_story` call is a specification, not commentary, and the two are
distinguished by who reads them: one is read by the run about to make the call, the other by the
person the run is talking to.

**A column sitting at its default is not narrated at all.** Having words for what a column means is
not a reason to spend them on every row. `plan` is unset on eight stories of nine, so *planning this
one inline* against each of them is a line the reader pays for in order to learn nothing — and the
one story that does need designing in full stops standing out, which is the whole reason the mark is
there. Say it where the value is news, or where the distinction is the step's own subject: a step
that routes on it and a report of what a run cleared both qualify, and a list of stories does not.

**And a document is named the way Naming a Document says**, which is the same rule one table over:
its reference and its title, never its id. That section carries the detail.

### Disposition

Every item a report mentions carries one of four dispositions, and the disposition names what the
**reader** has to do about it rather than what you did:

- **Fixed** — the repo is different now; read it and carry on.
- **Left alone** — it was seen and deliberately not acted on; nothing is waiting.
- **Unverified** — the check was impossible here, so the claim is still open; the reason names what
  would close it.
- **Needs you** — it is waiting on the reader, and nothing else in the report is.

The four are the `disposition` domain. Read them with `list_taxonomy` and render them in the
`position` order the domain carries, rather than transcribing the labels or the order into a skill.

**The label follows the reader's obligation, not your action.** Something fixed that is also worth a
glance is Fixed with the note attached, never Needs you. A Needs you that absorbs "and you may want
to look at this" stops meaning anything, and the one item that was genuinely waiting is then lost
among the ones that were not.

**An item that fits none of the four is not reported.** Work considered and rejected, the steps
taken to reach an answer, and a restatement of what the reader has just approved carry no
disposition, because there is nothing for the reader to do with any of them.

**A disposition with no items is not rendered at all** — no heading, no "nothing to report" line.
The same rule one level up: a block saying it is empty is a block the reader has to read to learn
there was nothing in it, and a report whose four headings are always present costs its reader four
readings to find the one or two that carry anything. A run that fixed everything it touched says so
in one block and stops. Absence is read from the absence of the heading, so the surviving blocks
still arrive in the order above and the reader may still stop once the actionable one has passed.

**In a report, the order is fixed** — Fixed, Left alone, Unverified, then Needs you last and
together, each one written as an imperative naming the action and where to take it. A reader who
stops after the third block has missed nothing that was waiting for them, which is what fixing the
order buys. This is the arrangement of a report; something unexpected found mid-work is still said
when it turns up, and carries its disposition there.

**Unverified means the check is impossible in this environment**, and the item says why. Two cases
qualify, both structural: a `target` criterion, whose environment nobody here has, and a must-NOT
with no control, where nothing available can make the check fail. A reason about how the run went —
the tests fail, it was not implemented, there was no time — is **Needs you** instead, however
genuinely it blocked you.

### Correcting yourself

Narrate a correction to something said earlier when the error would change the user's conclusions
or decisions. When it would not, make the correction and carry on without remarking on it. A
running commentary on your own earlier wording spends attention the user was giving to the decision
in front of them.

## Writing a Criterion

A criterion records an outcome, and the document supplies the negation around it. A `must_not` row
is already rendered under a heading that says what is forbidden, so the text **names the outcome as
though it had happened**: *"A story with a task still outstanding beneath it is set finished."*

Written as a denial — *"a story is not set finished while a task is outstanding"* — it reads as a
double negative the moment the document wraps it, and the reader has to work out which way round
the claim runs before they can judge it.

**A clause that only restates the denial is dropped, never inverted.** *"…and must not be allowed"*
adds nothing to a row already marked as forbidden; inverting it instead produces a sentence that
says the opposite of what the spec does. Drop the clause and leave the outcome standing.

The same holds for a `control`: it names what succeeds, in the words the rejection uses, so the two
read as one pair rather than as a claim and its rebuttal.

## Written Deliverable Length

Let a document's length match what the task needs. A spec covering three requirements is shorter
than one covering thirty, and that is the right outcome rather than an incomplete one.

Leave out padding that restates a point because a section looked thin, closing recaps of what the
reader has just read, and headings kept because a template offered them and then filled with "N/A".

This is calibration, not a budget. No artefact carries a fixed word or section count.

## Cross-References

A sentence in one artefact naming another — an epic's notes saying which epic holds the other half,
an observation citing the spec it came from — is written `{{ref:<id>}}`, carrying the target's id.
The renderer resolves the marker to that document's current human identifier.

**Never write the number.** It is correct on the day it is written and stops being correct the
moment anything renumbers its target, and by then nothing can find it to repair: a number inside a
sentence is indistinguishable from every other number in that sentence. The id is already in hand —
it is what the list or read tool that found the artefact returned — so the marker costs nothing that
the number does not.

**A structural reference is not this.** Where the relationship is a column — an epic's spec, a
coverage row's requirement, an artifact's document — write the foreign key and leave the prose
alone. A marker beside a foreign key is one fact recorded twice, and the two disagree the first time
either is edited.

**Something that is not a document gets no marker.** A commit, a ticket, a URL, a file in the
repository: none has an id, so each is named plainly in the prose as what it is. A marker naming
something that cannot be resolved is refused at render time, so inventing one to look consistent
turns a loose reference into a projection that will not build.

## Naming a Document

**Say the reference and the title** — `<reference>`, then the document's own title, taken from the
row you already hold. That pair is what a person can read back to you, type as an argument, and find
in the rendered tree, and every list or read tool returns the reference on the row beside the columns
it was asked for — so the naming costs the run nothing it has not already paid for.

The reference goes in as the row gave it, never written out from memory: a number typed into a
sentence is correct on the day it is typed, which is the failure Cross-References describes at
length and the reason this section carries no worked example of one.

**The id keeps the two places it works**: a tool argument and a foreign key. Both are read by
software that has the row in hand, and neither is read aloud.

**Where a reference is `null`, say the title and the kind and say the document has no reference
yet.** A row comes back unnamed when it is numbered `none` or when its parentage reaches no
root-numbered ancestor — legitimate states, not failures — and the honest sentence is *the untitled
scratch document, which has no reference yet*. Reaching for the id instead answers a question the
person did not ask, in a string they cannot use.

**This governs what is said; Cross-References governs what is stored.** They are separate because
the answers differ: a sentence spoken now is read once and a sentence written into a body is
re-rendered for as long as the row lives. So a document named inside stored prose — a body, a plan,
a decision, an observation — is written `{{ref:<id>}}` and resolved at render, for the reasons that
section gives. Speaking a reference and storing a marker are the same rule under one derivation:
both end at the identifier the projection computes.

## Artifact Publishing

A skill may publish an HTML artifact from its output **on request**. It is always separately
confirmed and never the default.

1. **Offer only when asked**, or when the skill's own text names an artifact worth offering.
2. **Confirm with a gate** before publishing. Publishing puts the content on a URL.
3. **Justify it in one line** — what the visual carries that the prose cannot. If that line cannot
   be written, the artifact has not earned its place.
4. **The artifact is a view, never a source.** Nothing reads it back; the rows remain the record.

