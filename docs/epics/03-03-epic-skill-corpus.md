# Skills that read and accept a reference

**Number**: 03-03  
**Source spec**: 03  
**Status**: complete  

## Story 1 — The convention that governs what a skill says

**Status**: complete  
**Blocked by**: Story 2, Story 4  

### Acceptance Criteria

- `dpm/shared/skill-conventions.md` carries a section governing what a skill says to a person, distinct from Cross-References, stating both the reference-and-title rule and what a skill does when the reference is null. `[integration]`
- The convention section states the stored-prose rule — a document named inside a body is written `{{ref:<id>}}` — as well as the rule for what a skill says to a person. `[integration]`

### Task 1 — Write the new convention section in `dpm/shared/skill-conventions.md`

**Status**: complete  

Beside Cross-References rather than inside it — one governs what is written to the database, the other what is said to a person. States the reference-and-title rule, what a skill does when the reference is null, and the stored-prose rule.

### Task 2 — Write tests for The convention that governs what a skill says

**Status**: complete  

Covers the story's two `integration` criteria: the section exists and is distinct from Cross-References, and it states the stored-prose rule as well as the spoken one.

### Retro

- The first draft of the section was caught by the rule it was written to state. It opened with a worked example — a real epic named by its reference and title — and `corpus.test.js`'s NUMBERED_REFERENCES sweep flagged it as "an artefact named by a number that will move", correctly: a number typed into a sentence in the shared conventions is exactly the stale reference Cross-References exists to prevent, and it does not stop being one because the sentence is teaching the rule.

The fix was to write the shape rather than an instance — `<reference>`, then the title — and to say in the section why it carries no worked example. Notably the sweep was right and needed no change; the retro lesson about narrowing a reading rather than adding an allow-list did not apply, because the reading was not the thing at fault. Worth recording as the other direction of the same lesson: a sweep's first report is a question about the reading, and sometimes the answer is that the reading was right.

A convention section can only be tested for being stated. The two criteria here assert the rule is present, distinct from Cross-References, and covers both the spoken and the stored form; none of that has any purchase on whether a skill obeys it, which is Story 2's sweep. The suite says so in its own header rather than leaving the pair to read as one check with a redundant half.

The control was run by deleting the section from a scratchpad-backed copy: all three tests failed, and the reading control inside the first test — renaming the heading and asserting the section reads as empty — is what stops the word-matching assertions passing against a file that merely contains the vocabulary.

## Story 2 — No skill names a document by its id

**Status**: complete  
**Blocked by**: Story 4  

### Acceptance Criteria

- No row of the status skill's *Recommended next steps* table interpolates a document id into a command. `[integration]`
- No skill file in the tree contains a placeholder interpolating a document id into a user-facing command or sentence. The corpus is enumerated by `everySkill()` reading the tree, never by a written list, so a skill added later is covered on the day it lands. `[integration]`
- control — The pattern the check uses, run against the status skill as it stands before this work, finds its four existing occurrences. A pattern that matches nothing passes against a corpus that still leaks, and nothing in the criterion above would say so. `[integration]`

### Task 1 — Write the check that finds document-id interpolation in skill files

**Status**: complete  

The corpus comes from `everySkill()` reading the tree, never from a written list of skill names, so a skill added later is covered on the day it lands. Detection only; the rewrites are tasks 3 and 4.

### Task 2 — Capture the status skill's four current occurrences as a fixture

**Status**: complete — Captured to `tests/skill-text/` rather than `tests/fixtures/`, because `fixtures.test.js` holds that directory to code that calls the tool surface and refuses any document in it.  

Addresses the control, and exists because of the ordering the control forces: the pattern has to be shown finding the leak, and by the time the suite runs the rewrite has removed it from the tree. The fixture is the pre-work text, not the live file.

### Task 3 — Rewrite the status skill's *Recommended next steps* table

**Status**: complete  

The four rows that interpolate an epic, spec or brief id into a command. This is the visible symptom the spec was raised from, and it is one file.

### Task 4 — Rewrite whatever else the check finds across the corpus

**Status**: complete — The check reported nothing outside the status table — across 23 skills read from the tree and the shared conventions — so this task's scope was empty rather than skipped.  

Scope is what the check from task 1 reports, not a judgement pass over the skills. A file the check does not name is out of scope for this task.

### Task 5 — Write tests for No skill names a document by its id

**Status**: complete  

Covers the story's three `integration` criteria: the status table specifically, the whole tree generally, and the control that the pattern finds the four occurrences in the pre-work fixture.

### Retro

- The whole corpus leaked in exactly one file. The check ran against all 23 skills read from the tree plus the shared conventions before any rewrite, and reported four occurrences, all four in the status skill's *Recommended next steps* table — which is the file the spec was raised from. Task 4 ("rewrite whatever else the check finds") therefore had an empty scope, and it is recorded as complete-with-a-note rather than skipped: an empty scope decided by a reading is a different fact from a task nobody got to.

The reading is over the placeholder, not the ULID, and that choice is the whole of whether the check works. A skill file holds no real id — it holds `{epic id}` inside a command a person is told to run, and the id only appears when the run substitutes one. A check for the literal matches nothing in this corpus and passes over every leak in it, which is the failure mode retro 04 describes: a criterion whose sentence names a shape the code never takes.

The must-NOT was controlled once per path a leak could reach a reader: a placeholder back inside the status table (criteria 1 and 2 both failed), the same placeholder in ordinary prose in a different skill (criterion 2 failed, criterion 1 correctly did not), and one in the shared conventions, which no per-skill sweep covers and every skill reads (criterion 2 failed). Each planted and removed in turn from scratchpad copies.

One registration cost that reading-the-sweeps-first did not catch: `fixtures.test.js` asserts `tests/fixtures/` holds no markdown at all — fixtures there are code that calls the tool surface, never documents to read — so the captured pre-work text failed the suite until it moved to `tests/skill-text/`. The rule is right and the capture is genuinely a document; the lesson is that "read what each sweep reads" has to include the sweeps over the test tree itself, not only the ones over `src/`.

## Story 3 — Seven skills accept a reference

**Status**: complete  
**Blocked by**: Story 4  

### Acceptance Criteria

- Each of the seven skills' Input section states that a human reference is accepted alongside a ULID, and names `resolve_reference` — which the existing binding then holds to being a tool that exists. `[integration]`
- must NOT — The seven must not be swept from the tree. They are a fixed set this spec chose, so a skill added later is not silently in scope and its absence from the list is a decision rather than an oversight. `[integration]`

### Task 1 — State the seven as a fixed set in the suite

**Status**: complete  

architect, brief, do, epics, review, retro and spec, named rather than swept from the tree. Addresses the must-not: a skill added later is then not silently in scope, and its absence is a decision.

### Task 2 — Amend each of the seven skills' Input section

**Status**: complete  

Each states that a human reference is accepted alongside a ULID and names `resolve_reference`. The Input section only — nothing else in these files is in scope here.

### Task 3 — Write tests for Seven skills accept a reference

**Status**: complete  

Covers the story's two `integration` criteria: each of the seven states the contract and names the tool, and the set is fixed rather than derived from the tree.

### Retro

- The must-NOT here inverts the rule every other corpus check in this suite follows, and writing the test made the reason concrete. Elsewhere a claim about the corpus must read the tree, because the skill nobody thought about is exactly the one a written list excludes while the suite reports full coverage. This claim is not about the corpus: FR7 names seven skills because those are the ones whose argument contract takes a document, and sweeping would put a skill added later silently in scope — passing unexamined, or failing and being repaired by adding a sentence nobody decided to add. Naming them is what makes an absence readable as a decision.

The first draft of the check for that got it wrong in the way the retro predicts. It asserted `skillNames()` is never called in the file, and failed on a legitimate call three lines further down that validates the written names are real skills. The reading was too broad rather than the code being wrong: what the must-NOT is about is *where the seven come from*, which is one line, so the check is now over the declaration — a literal array of string literals, no call inside it. The narrower reading also keeps the tree-reading call available, which is what stops the list rotting when a skill is renamed.

Two control arms, one per way a sweep could get in: the declaration rewritten to filter `skillNames()` (the second test failed, the first passed — correctly, the skills still say the right thing), and the sentence removed from one of the seven (the first failed, the second passed). Both from scratchpad copies.

The refactoring pass found the seven Input sentences are near-verbatim, which is the shape epic 47-08 resolved by extracting into the shared conventions. It was left alone deliberately: the criterion requires each of the seven to state the contract in its own Input section and name the resolver there, and extraction would satisfy the corpus and empty the sections a run actually reads to decide what it was given.

## Story 4 — Verify cross-story integration for skill-corpus

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A reference taken from a real document's tool output, substituted into the command the status skill's *Recommended next steps* table recommends, is accepted by the receiving skill's Input contract and resolves back to that same document. `[integration]`

### Task 1 — Write the recommend-then-run join test

**Status**: complete  

Reads a reference from a document tool's own output, substitutes it into the status skill's recommended command, and asserts the receiving skill's Input contract accepts it and `resolve_reference` returns the same document. The join FR7 names, which no single story observes.

### Retro

- The join test is the only thing in three epics that fails when the pieces stop fitting. Stories 2 and 3 and epic 03-02's resolver each pass with the other two broken, because each is a claim about one file: the status table recommends by reference, the seven say they accept one, a reference resolves. What none of them observes is that the string leaving the first is the string the third takes, and that the skill named in the recommendation is one of the seven — which is precisely what FR7's sentence is about.

Running the whole path on one document made two seams visible that a per-story check cannot reach. The reference is taken off the row `list_epic` returns, which is the call the status skill actually makes in its Phase 1, rather than from a read or from a recomputation — so the test fails if the reference stops arriving on list rows even though every read-tool test would still pass. And the recommended command is read out of the live skill file rather than written into the test, so a table rewritten to stop naming a target fails here rather than passing against a stale expectation. The control confirmed that: rewording the row to `/dpm:do` on whichever epic looks readiest failed this test and nothing else in the suite.

The second test in the file is the guard on the first. A reference typed into the test as a literal would make every assertion agree with itself and pass whether or not any tool ever printed that string, so the file checks its own source for one.

## Retro Applied

- 05 · codebase-discoveries · applied — Before budgeting the derived sweeps, read what each one reads. This epic's sweeps are over dpm/skills/*/SKILL.md and dpm/shared/skill-conventions.md rather than over the schema, so the existing skill-* suites are the ones to enumerate, not parity/conformance/prose-columns.
- 02 · complexity-underestimates · applied — A cost carried over from a differently-shaped change is a guess wearing a precedent's clothes. Epic 03-01 predicted five registrations and cost one; this epic edits twenty skill files, so the count is established by enumerating the corpus before Story 3 starts rather than by carrying either number forward.
- 04 · criteria-gaps · applied — A criterion can read as the natural test of a rule and have no purchase on it. Story 1 adds a convention to a shared markdown file; a criterion asserting the section exists has no purchase on whether any skill obeys it, so the purchase has to come from Story 2's sweep.
- 05 · patterns-worth-reusing · applied — A sweep whose first run reports offenders is usually reading the wrong thing, and the fix is a narrower reading rather than an allow-list. Story 2's sweep runs against the real skill corpus before its assertion is written, and whatever it flags is read as a question about the reading first.
- 05 · patterns-worth-reusing · applied — Assemble the forbidden string rather than writing it. Story 2 sweeps the skill corpus for a document id named in conversational output; the sweep's own suite file will contain planted examples, so any ULID-shaped literal used as a control is assembled rather than written, and no file is exempted by name.
- 02 · testing-gaps · applied — A must-NOT control needs one arm per path that could reach the rejected behaviour. For Story 2 the id can reach a skill's output as a bare literal, as an interpolated argument placeholder, or inside a recommended command; each is planted and removed in turn.
- 04 · testing-gaps · applied — Read the criterion for the failure it protects against, not the shape its sentence names. Story 2's must-NOT says a skill must not name a document by its id; the failure includes an id interpolated into an example command, which no literal-ULID reading would catch.
