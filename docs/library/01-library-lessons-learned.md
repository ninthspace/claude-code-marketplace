# Promoted Retro Lessons

**Number**: 01  
**Status**: complete — In force. Each entry names the retro observation it came from; that observation is retired at source, so a lesson lives here or there and never in both.  

**Type**: coding-standards  
**Source**: docs/cpm/library/lessons-learned.md — carried over from CPM at the 2026-08-16 migration, with its amendment blocks folded into the body  
**Scope**: do  

## Reach for it before assuming the surface has it

**Source**: retro 38, Codebase Discoveries — "The surface refuses what it never anticipated, and refuses it quietly." `entityTools` dropped nulls, so a waiver could not be lifted and the refused clear reported success. `list_artifact_document` was scoped one way only. `artifact.url` and `published_at` are both `NOT NULL`. `review_agent` is kind-pinned to `review`. `document_kind` was neither readable nor listable. The shared `Perspectives` procedure loaded a roster without `include_body` and rendered voices off nothing.

A tool surface, schema, or shared procedure will accept a call it was never designed for and answer it wrongly without erroring. Every gap of this kind found in this project was found by a consumer reaching for something; none came from reading the schema. Reading is not a substitute for reaching.

- **Walk the reads before writing the consumer.** Call each read the new skill, migration or client will need, and look at what comes back. It costs minutes; the alternative is a debugging pass, and sometimes a shipped defect.
- **Expect the quiet refusal, not the loud one.** These failures do not throw. A dropped null reports success. A one-way scope returns rows. A withheld column arrives as an absent field rather than an error. Ask what a wrong answer would look like, and whether you could tell.

**A fix at the site is not a fix of the class.** This was recorded in three consecutive retros — 36, 38 and 39 — and each time repaired where it surfaced and nowhere else. Retro 38 named the shared `Perspectives` procedure reading a roster without `include_body`; that was fixed, and the 23 skill files beside it were not. When a surface behaviour bites once, sweep every caller before closing it.

## A check that passes may be passing for a reason other than the one you want

**Sources**: retro 42, Criteria gaps; retro 56, Testing gaps. Promoted because it is the single most re-derived lesson in this project's history — the same rule was found independently, in a different disguise, in **thirteen** retros: 35 (a truncated check reported a pass it never computed), 36 (a green suite proved nothing about whether the server could start; section-scoped assertions alias against nearby prose), 37 (two checks that agree are not two checks), 38 (three quantifier failures, all making the assertion vacuous rather than wrong), 39 (a green assertion is not evidence until the wrong answer is known to be excluded), 40 (a vacuous regex reads exactly like a working one), 41 (a criterion phrased as "the corpus still has N of these" expires the moment the epic succeeds), 42, 44 (a specific assertion placed behind a generic one never runs), 45 (a criterion with two failure shapes gets tested against whichever one the code makes easy), 47 (a token sweep cannot prove a path writes nothing), 49 (a comparator that never sorts passes an ordering test whose code already emits in order), and 56.

**At the criterion.** An absence can be delivered by something other than the mechanism under test. Before marking a criterion of the form "X is not created / does not happen" as met, ask what else in the current state of the tree would produce that absence — a crashed process, a sibling change, a fix that landed elsewhere. Where the answer is "something else could", the criterion needs the mechanism named before it can be verified. Retro 42's case is the hardest kind to see: a correct assertion in one spec, undermined by a sibling spec that removed the condition it discriminated on.

**At the sweep.** A must-NOT that cannot be handed a broken corpus is a must-NOT nobody has checked. All three of spec 50's cross-site sweeps passed on their first run, which is what a vacuous sweep looks like: one matched a phrase that was present either way, one had a control asserting only that the fixture contained a label, and one exercised `String.replace` rather than the reading it was meant to test. The fix was the same move each time — extract the reading into a function taking a `read(skill)` callback, so it can be pointed at a corpus with the defect planted.

The practical form of both: **plant the defect, then watch the check fail.** A check that has never been shown failing is a check whose passing means nothing, and neither reading it nor reviewing it substitutes. Budget the fixture, not just the assertion.

Two corollaries this project paid for separately:

- **A must-NOT placed on the epic that *introduces* a rule, rather than the epic that gives it content, passes vacuously and looks like coverage.** Ask of every must-NOT what would make it pass for the wrong reason on the day it is written.
- **Success can make a check undrivable on its own subject** (retro 41). A criterion counting instances of the thing being removed expires the moment the work succeeds; phrase it against a fixture, not against the corpus.

## A control mutation needs a revert that cannot take the tree with it

**Source**: retro 56, Testing gaps.

Proving a control means deliberately breaking a file, running the suite, and putting the file back. The reflex for the last step is `git checkout -- <file>`, and it is wrong: it discards whatever else is uncommitted in that file, and a run that has been editing all session has plenty. Spec 50's run did exactly this and had to correct mid-flight.

**Copy the file to a scratchpad before mutating it, and `cp` it back afterwards.** The revert is then bounded to the file and to the change you made, and it cannot reach anything else.

Two guidelines sit behind this and are worth restating because a control mutation is the moment both get bent:

- **Version control stays with the user.** No `checkout`, `reset`, `stash` or `commit` on the agent's own initiative — including as a convenience during testing.
- **Edits go through the Edit tool, file by file.** Not `sed`, `perl` or `awk`. Same run, same session, also breached: a bulk edit is opaque, bypasses review, and corrupts files on partial matches.

Neither breach was caught by the suite. Both were caught by noticing, and written into the session's conduct notes so the rest of the run would not repeat them.

## A control is only a control once you have watched it fail, and read why

**Synthesised from** retros 37, 39, 44, 46, 47, 48 and 55 — the second theme this project re-derived repeatedly. Unlike the entries above this is a synthesis rather than the promotion of one observation, so those retros keep their originals rather than carrying a retirement marker.

A control is the run that proves a check can fail. Six ways this project has had one that did not do its job:

- **A control needs a body, not just a row** (37). A fixture that exists but carries none of the content the check reads passes for the wrong reason.
- **A mutation is only caught when the mutation ran** (39). Confirm the mutated code path was actually reached before believing the failure it produced — or the pass it did not.
- **A control belongs in the same fixture as the arm it controls, not beside it** (47). Two fixtures drift, and the control ends up proving something about a state the real arm never enters.
- **A control that fails by propagating someone else's exception is half a control** (55). The remove-the-condition control caught its mutation by throwing "table schema_version already exists" four frames down: a true verdict about the wrong harm.
- **An assertion message that names the presumed cause is wrong for every other way it can fail** (45, 46). Retro 44's control caught its mutation and said nothing about why; the whole difference is what the next person reads at 2am.
- **Assert the exception *type*, not merely that something was raised** (48). "DID NOT RAISE" is a true verdict that names the wrong harm — twice in one epic.

The positive form, from retro 44: **to close a must-NOT, remove the condition and watch the same inputs produce what was refused.** "X does not happen under condition C" is satisfied by a feature that never works at all, and only removing C distinguishes them.

And read the failure text every time, not just the failure. Retro 55: three of seventeen mutations were about *where* a line sits rather than what it does, and two of those either survived or produced a misleading message. Neither is visible from a green suite.

## A sweep that reads this repository's own text will read its prose and its planted controls

Several checks in this suite work by reading source files as text — the import sweeps, the corpus sweeps, the `.dpm/` anchoring check. Each has reported a file that broke no rule, and each time two wrong repairs were available: exempt the file by name, or delete the control. Both hide the next genuine breach in the one file most likely to hold it.

- **A regex reading is not a parser, and prose is in its corpus.** A quoted phrase downstream of the word `from`, a doc comment distinguishing one term from another, a pattern written to extract imports — all have failed an import sweep as dependencies on packages whose names were English sentences. Keep quoted phrases away from the words a sweep anchors on, and assemble any pattern that contains the forbidden shape from fragments.
- **Assemble the forbidden string rather than writing it.** `['plugins', 'cache'].join('/')` keeps a control real, keeps the file inside the sweep's corpus, and costs one line. This was rediscovered in three consecutive stories before it was written down.
- **Empty the string literals before scanning, keeping the quotes so the parentheses stay balanced.** An assertion quoted inside a string is not an assertion — that is the rule, and it is what an exemption by filename fails to say.
- **A sweep whose first run reports offenders is usually reading the wrong thing.** The fix is a narrower reading, not an allow-list: anchor at `^\s*import` rather than matching `from`; ask *anchored at the project* rather than *named as a string*.
- **Sometimes the reading was right and the text was wrong.** A worked example naming a real artefact by its number is a stale reference whether or not the sentence is teaching the rule. Write the shape, not an instance, and say in the section why it carries no example.

A warning is only read where the reader already is. A note in the file that tripped the sweep does not reach the next author of a different file; the note belongs at the sweep.
