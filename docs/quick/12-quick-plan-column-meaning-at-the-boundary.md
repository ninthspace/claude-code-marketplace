# The plan column says what its values mean, where the run is handed them

**Number**: 12  
**Status**: complete — Closed with all seven criteria met. Criterion 1's note records one imprecision in its own wording: `read_story` declares no `plan` property, so the gloss reaches a run through the create and update schemas rather than through the read response. The fix makes the correct sentence available and does not enforce it; the stronger candidate stays open in 02.  

**Closed**: 2026-09-07T09:05:00.000Z  

## What is changing, and why here

The symptom is a run printing the literal `plan: 0` or `plan: 1` in conversational output, seen on a fresh 0.7.4 install in another project over the weekend of 5–6 September 2026, in prose addressed to the user rather than inside a tool-call specification.

The rule against this is present and current. 0.7.2 fixed `do`, `epics` and `ralph` and added `Saying what a row holds` under Conversational Output; 0.7.3 added four tests over that section and the clause about a column at its default. All 23 skills cite Conversational Output and all 23 instruct the startup read of the shared conventions. The diagnosis is in 02.

What was missing is not another statement of the rule. It is that the value arrives with no meaning attached. `plan` is declared as an `extra` column on the delivery tools, `enum: [0, 1]` with `default: 0`, and its description says what the column is about rather than what either value means. `dpm/src/tools/spine/delivery.js` treats only `description` as a body column, so `plan` comes back on `read_story` and on every row of `list_story`, while the markdown projection never renders it at all — the tool result is the only place the string exists. A run is handed a bare integer and no gloss, and reaches for the integer.

So the fix rewrites that description to name both values. It is placed at the tool boundary because that is the one channel with unconditional reach: the description travels with every call, in every skill, in every project, with no dependence on whether the run performed a file read. That is retro 09's lesson about reach coming from placement rather than from a rule existing, applied one layer down from where it was learned.

The description deliberately does not restate the narration rule. Two statements of one rule drift, and the conventions file already argues that in the other direction. It supplies the meaning and leaves the rule where it is.

**Scope is one site because there is only one site.** `plan` is the only `enum: [0, 1]` integer in the whole tool surface. `met` is a boolean whose description already names its unset state; `status` and `polarity` are string enums whose values read as words. The rule's own text explains why the integer is the sharp case — a reader who has not seen the schema cannot tell which way round a flag runs.

**The second candidate was dropped, not deferred by oversight.** Withholding `plan` from `list_story` as a body column would stop a nine-story list shipping eight defaults, and is the stronger fix on paper. It also breaks ralph step 1b, which scans that list to find the stories whose gates need clearing — `dpm/tests/skill-ralph.test.js:188` reads `story.plan` off listed rows and is that mechanism's check. And there is no evidence the list path is where this leaked, because the transcript was on another machine and which skill was talking is still unknown. It stays open in the discussion record rather than being taken blind.

## Files affected

- `dpm/src/tools/index.js` — the `plan` column's `description`, rewritten to name what 0 and 1 each mean. The `enum` and the `default` are untouched.
- `dpm/tests/reachability.test.js` — a new standalone test over that description, placed beside the existing planning-mark test that already reaches into `inputSchema.properties.plan` rather than in a file of its own.
- `dpm/.claude-plugin/plugin.json`, `dpm/package.json`, `README.md`, `.claude-plugin/marketplace.json` — the version to 0.7.5 at the four sites the agreement suite pins, and the marketplace's own version with them.

Nothing in `dpm/skills/` changes. The three skills that read this column were corrected in 0.7.2 and the rule they follow is unchanged; this increment is about what the tool hands them.

## What changed, and how it was verified

The `plan` column's description in `dpm/src/tools/index.js` now reads *"whether this story is designed in full before any of its tasks are executed: 1 means it is, 0 means its tasks are planned inline as each is picked up"*, with a three-line comment above it recording why the description is the site: it is the one channel that carries the meaning alongside the number, because `plan` returns on every read and every listed row and the projection renders it nowhere. `type`, `enum: [0, 1]` and `default: 0` are untouched, so AD10's conformance seam compares the same sets it did before.

`dpm/tests/reachability.test.js` gains one test, standing on its own beside the existing planning-mark test. It reads the `plan` property off `create_story` and `update_story`'s input schemas and asserts each names what both values mean.

**Verification was by planting defects, not by reading assertions.** Removing the *"1 means it is"* clause turned exactly one test red. Restoring it and removing the *"0 means…"* clause turned the same one test red and left the other seven green. Both plants were reverted before the suite run. That separation is the point of the test standing alone: the assertion it complements is the `enum` check, which no description edit can break, so a shared test would have left both glosses effectively unguarded — retro 08's finding, applied deliberately rather than rediscovered.

The full suite is 969 of 969, which is the 968 standing before this increment plus the one it adds. The version is 0.7.5 at the four pinned sites and the marketplace is 3.22.4.

**One imprecision in criterion 1 is recorded rather than smoothed over.** It named `read_story` alongside the two write tools, and `read_story` takes only `id` — it declares no `plan` property, so the gloss is not attached to its response. The meaning reaches a run through the create and update schemas, which are in context for any session with the server loaded. The criterion's purpose holds and it is marked met, but the record says where the description actually lives, because a later reader checking `read_story` for it will not find it there.

**What this fix does not do.** It gives the run the meaning; it does not stop the run printing the number. Nothing in DPM observes a run's prose, so the narration rule remains unenforced at runtime and this change makes the correct sentence available rather than mandatory. Whether that is enough is answered by whether the leak recurs.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | `create_story`, `update_story` and `read_story` report the `plan` property with a description that names what both 0 and 1 mean, so a run handed the value also holds its meaning without reading a separate file. | Met in substance, with one imprecision in the wording worth recording. `create_story` and `update_story` declare the glossed description on their input schema, and a test asserts both. `read_story` takes only `id`, so it declares no `plan` property and the gloss is not attached to its response — the meaning reaches a run through the listed create and update schemas, which are in context for any session with the server loaded, rather than through the read. The criterion's purpose holds: a run handed the value holds its meaning without a separate file read. |
| ✓ | The description no longer stops at the column's subject with neither value glossed, which is the shape it had when the leak was observed. | The description now reads "whether this story is designed in full before any of its tasks are executed: 1 means it is, 0 means its tasks are planned inline as each is picked up". The previous wording stopped at the subject with neither value glossed; the diff on `dpm/src/tools/index.js` shows that line as the only one replaced. |
| ✓ | A test asserts both glosses are present and turns red when either one is removed, verified by planting that removal rather than by reading the assertion. | Verified by planting each removal separately rather than by reading the assertions. Removing the "1 means it is" clause turned exactly one test red; restoring it and removing the "0 means…" clause turned the same one test red and left the other seven green. Both plants were reverted and the description is as stated in criterion 2. |
| ✓ | That test stands on its own rather than joining the existing planning-mark test, so it is not verified only when the enum assertion beside it happens to fail first — retro 08's finding. | The new test is `the plan column's description names what both of its values mean` in `dpm/tests/reachability.test.js`, with its own `openPlanningDatabase` and `spineTools` setup. It sits beside the existing planning-mark test rather than inside it, and the comment above it records why: the positive it complements is the `enum` assertion, which a description edit cannot break, so a shared test would have left both glosses unguarded. |
| ✓ | The `plan` enum, the `CHECK (plan IN (0, 1))` constraint and ralph step 1b's `list_story` scan are unchanged: the fix adds meaning and removes no access. | The diff on `dpm/src/tools/index.js` replaces one line and adds a three-line comment; `type`, `enum: [0, 1]` and `default: 0` are untouched, and no schema file changed, so the `CHECK` constraint stands as it was. Nothing under `dpm/skills/` is in the diff at all, so ralph step 1b's `list_story` scan and `dpm/tests/skill-ralph.test.js:188`, which reads `story.plan` off listed rows, both work exactly as before — confirmed by that suite passing. |
| ✓ | The version reads 0.7.5 at the four sites the version-agreement suite pins, and the marketplace's own version advances with it. | 0.7.5 at all four: `dpm/.claude-plugin/plugin.json`, `dpm/package.json`, `README.md` and the dpm entry in `.claude-plugin/marketplace.json`. The marketplace's own version went 3.22.3 to 3.22.4 with them. The agreement suite passes, which is what confirms none was left behind. |
| ✓ | The full suite passes. | 969 of 969 pass, 0 fail, on `npm test` from `dpm/`. That is 968 before this increment plus the one test it adds. |
