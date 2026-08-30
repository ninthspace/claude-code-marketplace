# Say a story requires a plan, rather than narrating plan: 1

**Number**: 09  
**Status**: complete — All seven criteria met; shipped in 0.7.2 as commit 0c1d501. Written twice: the first record was allocated against a database that had been rolled back to an August state, and was lost when the working database was restored from the committed dump.  

**Closed**: 2026-08-30T17:10:00.000Z  

## What changed

Whether a story is designed in full before it is built is a column, and the skills that read it handed the agent the column's value as the sentence to say. The commentary that followed was "Story 1 has plan: 1, so I'll explore first" — a run narrating its own storage. What a reader needs is the meaning: this story needs designing in full first, or it does not.

The column did not move. Nothing about the schema, the tools or the create argument changed; only the prose that tells a run what to say about it.

`dpm:do` reads the column in two places and now speaks neither value. The story-load bullet says the column reports whether the story has to be designed in full before any of it is built; the planning step branches on *where the story requires a plan* and *where it does not*, and closes with the two sentences a run should actually say. `dpm:ralph` selects "every story that requires a plan" and reports each one as no longer requiring one, while still writing the flag through `update_story`. `dpm:epics` keeps `plan: 1` as the create argument and gains a paragraph requiring the story to be described in words when it is put to the user. The shared **Conversational Output** section carries the general rule under a new heading, *Saying what a row holds*, with the carve-out that a value written as a tool argument is a specification rather than commentary — the two are told apart by who reads them.

**A fifth site came from the user mid-run, and it is the same fault one table over.** This run named a retro observation by its id at its own confirmation gate. **Naming a Document** has forbidden that since 0.6.0 — the id keeps a tool argument and a foreign key, and neither is read aloud — but only `dpm:status` cites that section, while all 23 skills cite **Conversational Output**. So the new subsection ends by pointing at it, and the rule now reaches every skill that speaks about a row.

## Files affected, and how it was verified

- `dpm/skills/do/SKILL.md` — the story-load bullet naming the column, and the planning step that branches on it.
- `dpm/skills/ralph/SKILL.md` — step 1b, clearing the plan gates.
- `dpm/skills/epics/SKILL.md` — step 3, where the flag is set on the story.
- `dpm/shared/skill-conventions.md` — **Conversational Output**.
- `README.md`, `.claude-plugin/marketplace.json`, `dpm/package.json`, `dpm/.claude-plugin/plugin.json` — the release, 0.7.1 to 0.7.2.

Two suites read these files as text and pin what they contain: `skill-do.test.js` requires the planning step to name a backticked `plan` and to contain no reference to a title, and `skill-epics.test.js` requires its step 3 to carry the literal `plan: 1`. Both are claims about where the decision is read from rather than about how it is spoken, so the rewording was written to keep them true rather than to change them.

Verification: `node --test` in `dpm/` — 964 pass, 0 fail, run after the edits and again after the version bump and the database restore below. Shipped as commit 0c1d501.

## The working database had been rolled back, and this record was written twice

The release was ready before this was found. Bumping the version meant committing, and the guard refused: 39 generated files did not match the database, ~30 of them files on disk that no document produced.

`.dpm/dpm.db` held 28 documents. The committed `.dpm/dpm.sql` held 72, matching what was under `docs/` — eight quick records, eight retros, four specs, and epics 03 and 04. Both were at schema 27 and stamped 0.7.1, so this was not version skew. The working database had been rolled back to a state from mid-August, and it happened during the day: quick record 08 was written at 13:20 and was in the dump and not in the database. Nothing this run did could have caused it — the first write it made was against the rolled-back file.

**The dump is the record and `dpm.db*` is ignored, so the recovery was a replay rather than a repair.** The old file was copied aside, `.dpm/dpm.sql` was replayed into a fresh database, and that was moved into place; the guard then reported all 55 projected files and the dump matching, and the suite passed again. Publishing before noticing would have deleted about thirty committed documents, which is what the guard exists to prevent and what it did.

The cost was this record. It was created against the rolled-back database, where it was allocated number 02 — a number the real corpus had already given to another quick record — and it did not survive the restore. What is written here is the second copy, allocated 09 against the restored database. The lesson is the cheap one: a number allocated against a database nobody has checked is not yet a number, and the guard is the thing that checks.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | dpm:do's planning step branches on the story's plan column and states the branch as whether the story requires a plan, prescribing no raw column value in what the run says aloud. | Step 3 now branches on "where the story requires a plan" / "where it does not", names the column once as the source, and adds a sentence giving the two things to say. |
| ✓ | dpm:do's story-load bullet names the column as the source of the decision without offering its value as the sentence to say. | The read_story bullet says the column reports whether the story has to be designed in full before any of it is built, and that this is what Step 3 branches on. |
| ✓ | dpm:ralph's plan-gate clearing reports each cleared story as no longer requiring a plan, rather than as a flag moving from one value to another. | Step 1b selects "every story that requires a plan" and reports each cleared story as no longer requiring one; the write is still update_story with plan set to 0. |
| ✓ | dpm:epics still records the flag as the create_story argument plan: 1, and describes such a story to the user as one requiring a plan. | Step 3 keeps "takes `plan: 1`" as the argument and gains a paragraph requiring the story to be described in words when it is put to the user. |
| ✓ | The shared Conversational Output section carries the general rule that narration names what a column means rather than the value it holds, with the story plan column as its worked example. | Added as "Saying what a row holds": the rule, the plan example, the extension to met, polarity and status, and the carve-out for a value written as a tool argument. |
| ✓ | node --test passes in dpm/, including the source assertions in skill-do.test.js and skill-epics.test.js that read these two files. | 964 pass, 0 fail — run once after the edits and again after the version bump and the database restore. |
| ✓ | Conversational Output points at Naming a Document for how a document is named aloud, so the rule against speaking an id reaches every skill rather than only the one that cites that section today. | All 23 skills cite Conversational Output; only dpm:status cited Naming a Document, which is why the id-aloud rule was not reaching the runs that speak one. |
