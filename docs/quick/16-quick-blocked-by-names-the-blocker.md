# Every story's "Blocked by" names what it blocks

**Number**: 16  
**Status**: complete — Closed 2026-09-21 with all four criteria met. B1 is fixed and the fix is in git rather than in an untracked plugin cache. The two renderers now agree, so the commit the guard was refusing can proceed.  

**Closed**: 2026-09-21T18:30:00Z  

## Both halves of the render pointed outward

`dependency` has a source and a target, and `readiness.js` reads the pair one way: the target is the row held back, the source is what holds it. The epic projection read it the other way and did so twice over.

`load.js` collected each story's edges by `source_story_id` — the edges the story is the *source* of, which is the set of things it blocks. The epic template then rendered each of those edges' *target*. Two outward readings compose into a list of what the story holds up, printed under the heading "Blocked by". Every story line in every epic document has been inverted since the projection was written.

Neither half is wrong on its own terms. Read by `target_story_id`, rendering the target would name the story itself; read by `source_story_id`, rendering the source would do the same. It is the pairing that inverts, which is why reading either file alone leaves it looking correct.

**The fix is to take the blocked end and name the source**, and to rename `edgeTarget` to `edgeSource` so the function says which end it returns. A comment at each site records the direction, because the next reader arrives at one file and not both.

## How it survived, and how it was found

The corpus every projection test runs against has had a story blocking another story all along. The direction was checkable from the first day and nothing asked: the assertions over `Blocked by` were about its formatting — a hard line break, an em dash where there are no edges — and the one test that did exercise a real edge was written from the same inverted reading as the code, so it agreed with the defect and passed.

That is the shape retro 10 names from the other side: the useful question is not whether a check was written but whether the corpus could have told it it was wrong. Here it could, and no assertion put the question.

**It was found by two renderers disagreeing.** A `/dpm:publish` through the MCP server rewrote fifteen epic files that no row in this session had touched, because the installed plugin cache carried a hand-made fix that this repository does not. The fix was never committed — `git log --all -S` finds nothing — and it had been sitting in a directory a plugin reinstall overwrites. The divergence was what surfaced it; without a second renderer to disagree with, the inverted output would have gone on looking like the output.

The two files were copied out before anything could take them, and this record is the fix landing where git can keep it.

## What changed, and the third place the inversion had been written down

`load.js` reads story edges from the blocked end and `epic.js` renders each edge's source, with `edgeTarget` renamed to `edgeSource` so the function says which end it returns. Both files came out byte-identical to the patch captured from the plugin cache, which was checked rather than assumed.

**The fix broke two tests, and only one of them was expected.**

The cross-epic test in `templates.test.js` was the known one: it made the local story the source and then asserted that the local story rendered the other under "Blocked by". It had been agreeing with the inverted template, so it passed on exactly the defect its title suggests it guards.

The second was a sweep in `tool-corpus.js`, which proves each table reaches the projection by looking for a string the render produces. Its probe for `dependency_kind` was `**Blocked by**: Story 1`, and the comment beside it explained that story 2 was the one held back. Both were written from the inverted reading. The fixture's own titles say otherwise — the blocking story is called *"And the one it waits on"* — so the edge was always right and the prose describing it was wrong.

That is three separate places the inversion had been written down, in code, in a test and in a comment, each one making the next look correct. A fourth was the variable name `blocked` in the shared corpus, held on the story that does the blocking; it is why the new test reads the edge out of the table rather than trusting what the fixture calls its ends.

**Verified**: 1001 tests passing; the inverted reading restored as a mutation fails two of them; the working tree's publish leaves all fifteen epic files unchanged and the guard reports the tree clean.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A story carrying an incoming blocking edge names its blocker under "Blocked by", and the blocker's own line reads as blocked by nothing. | Asserted at both ends in one test, because one end alone cannot tell the directions apart: a template reading the wrong end produces the same two lines with the stories swapped, so "some story is blocked" passes either way. On the shared corpus the blocking story now reads as blocked by nothing and the blocked story names it. The test carries a control reading the edge out of the table rather than from the fixture's variable names, which were themselves written from the inverted reading — the blocking story is held in a variable called `blocked`. |
| ✓ | Restoring the reading by `source_story_id` makes a test fail, so the corpus can tell the two directions apart — which is what it could not do while this defect survived. | The mutation was run: restoring `source_story_id` fails two tests against 999 passing, where before this work it failed none. The corpus needed no new rows to make that true — it has held one story blocking another since it was written, and the direction was checkable from the first day. What was missing was an assertion that asked. |
| ✓ | A story blocked from another epic still names that epic, with the edge pointing in the direction the label claims rather than against it. | The cross-epic test's fixture was reversed so the other epic's story is the source, which is what holds work back. It had named the local story as the source while asserting that the local story rendered the other one under "Blocked by" — so it agreed with the inverted template and passed on the defect it reads as written to catch. Its target also moved from story 1 to story 2: story 1 already carries a blocker from the shared corpus, and a second would render as a list where the assertion wants the cross-epic name alone, which an ordering change could otherwise satisfy quietly. |
| ✓ | The working tree's guard reports the already-published epic files clean, so the repository renderer and the installed one agree and a commit is no longer refused. The full suite passes. | The working tree's publish reported all fifteen epic files unchanged — they already held the corrected render, written earlier by the installed server — and the guard reports 83 projected files and the dump matching the database. The two renderers now produce identical bytes, which is the whole of what was refusing the commit. Full suite 1001 passing, up from 1000 by the one test added here. |
