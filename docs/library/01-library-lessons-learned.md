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

## Derive it from the source, and check the derivation is the production rule

Six independent instances, one of which counted itself as "the fifth and sixth of that class this run". A literal written into a test is a copy of something the tree already states, and it goes stale exactly as a written number does — `targetVersion() === 25`, `REGISTER.length, 13`, `report.checked, 14`, `{"complete", "pending"}`, and three tests that derived "the previous migration" from its distance to the newest one and silently became tests about a database that already had the table.

- **An additive change should cost no test edits.** Where it costs some, those are the assertions that wrote down what the files say instead of reading it. That is the cheapest signal available, and it arrives as a red run.
- **Name the thing, not its position or its distance.** The migration a test is about; a requirement looked up by label (`requirements.find((row) => row.label === 'FR1')`) rather than `requirements[2]`. A fixture that indexes a shared array by position is extensible only at the tail, and nothing enforces that — inserting a requirement into the middle re-aimed a criterion onto a different requirement and the whole suite stayed green, because nothing asserts which requirement a criterion hangs off.
- **Deriving is not enough on its own.** `test_containment.py` derived its expected figure from the fixture and still broke, because the derivation counted every story the fixture creates while the production rule drops a retired one. Derive from the source data *and* check the derivation is the rule it stands in for — a disagreement looks exactly like the defect it hides.

## Ask the runtime the question rather than modelling its answer

Four instances. A model of someone else's behaviour written into a test agrees with the real thing until the day it does not, and then reports the disagreement as a pass.

- **Read the structure the library produced, not the syntax you fed it.** Criteria read from `rich.markdown.Markdown(source).parsed` rather than from a leading `#`: a two-space indent with no marker is a lazy paragraph continuation that merges into the parent's inline token, and only the token's `level` knows that. Asserting the `#` would have been a second markdown parser living in a test file.
- **Read the artefact the framework built, not the table it was built from.** A footer printed neither arrow because `OptionList` shadows the app's `left`/`right` with `show=False` bindings that sit nearer the focused widget. Both keys worked, so every existing test passed — they compared the binding table against itself — and the bug had been shipping since the board's first story. When a criterion is about what a user *sees*, read what the framework built.
- **Let the runtime do its own downgrade.** Quantisation goes through Rich's `downgrade` rather than a nearest-colour rule written in the test, because a second colour model agrees with the terminal until the day it does not. And pick the metric a reader actually perceives: Rec. 709 weights red at a fifth, so a blocked row's bar sits 2 from the surface by luminance and 77 in the channel someone sees.
- **Where the framework offers the event, take the framework's event.** A re-render driven from the app's `on_resize` rasterises at the width the panel had a moment ago; moving it onto the widget's own `Resize`, which is delivered with the new size, is the difference between a fix and the same stale layout one step later.

## A must-NOT stated as an equality is a change detector, and a set comparison needs a floor

Three instances. A rejection written as an exact list passes while it is that list and fails on the next legitimate change, which is the behaviour of a change detector rather than of a check.

- **State it over the category it is actually about.** An ENVX4 test deep-equalled a module's imports against three builtins and broke when a sibling module was imported — the reuse the spec's own AD3 called for. The criterion is about what the module can reach *outside this process*: assert over the builtins, and require everything else to be a relative path inside the project.
- **Resolve what a declaration provisions, transitively.** Comparing an import surface against `{"textual"}` is green on the day it is written and wrong as soon as something arrives through a declared distribution's own dependencies. Resolve the closure through `importlib.metadata.requires`.
- **A comparison between two sets needs a floor that names members.** "No extra sits on a shared key" is exactly what an empty extras set says, and there are several ways for that set to empty itself by accident — an AST reader failing to find the other class, a same-meaning entry swallowing a capability the other side does not have. Name `force_refresh`, `search` and `coverage_gaps` and assert each is being read as an extra; asserting the set is non-empty is not enough, because it does not distinguish a rejection that holds from one that has stopped looking.
- **A translation table comes before the comparison, not after the first false report.** Two boards naming the same capability differently produce disagreements that are only spellings, and a check that reports them goes on reporting them after the real ones are fixed, until nobody reads the output. Compare over the intersection of the two maps rather than asserting an equality between them.

## A withheld body arrives as undefined, and the comparison passes on the defect

Twice, and the second time the observation noted it was the second. A read tool withholds `text`, `spec_fragment` and the other body columns unless the caller passes `include_body`, while the matching update tool returns them. So a test that writes through `update_*` and reads back through `read_*` without asking compares a string against `undefined` — and that comparison passes on a call that blanked the column, which is the exact defect it was written to catch.

- **Pass `include_body` on every read whose value an assertion consumes** — not only where the column is the subject. A "nothing else changed" comparison is consuming it too.
- **The failure mode is a pass, so no red run will find it.** It reads as the assertion agreeing with itself.
- **It generalises past this surface.** Any read that answers an absent field rather than an error will satisfy an equality against another absent field. Ask what a wrong answer would look like, and whether the assertion could tell.

This is the quiet-refusal entry above, narrowed to the one form it takes most often in this project's own suites; both instances cost a red run in an epic where the assertion had already been written.

## A helper whose docblock explains a hazard names every check that has the hazard

Three occurrences of the shape, across retros 08 and 09. When a suite grows a helper because some hazard bit once, the docblock usually explains that hazard at length — and it is written for the one call site that prompted it. Every other check subject to the same hazard is then a latent instance, and the ones written *before* the helper existed are where to look.

`prose` exists because SKILL.md files are hard-wrapped, and it says so: an assertion written against the current wrapping either breaks on an untouched edit or silently stops constraining anything. It was applied to matching a phrase inside a section and never to matching a citation across a file. A check counting which skills name `Conversational Output` read the raw source and filed one skill as the exception on the strength of a line break — green because it could not see its subject, and reporting the absence of a citation that was there.

**When a helper's docblock states a hazard, grep the suite for what else has it.** That is a bounded, mechanical sweep, and it is the only thing that finds a check whose failure mode is a pass. Fix it at the helper rather than at the call site, so the next check written cannot reach the hazard.
