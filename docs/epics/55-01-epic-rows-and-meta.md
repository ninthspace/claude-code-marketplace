# Rows and meta: model, effort, criteria, typical ranges and needs

**Source spec**: docs/specifications/55-spec-tracker-split-view.md  
**Date**: 2026-11-11  
**Status**: Complete  
**Blocked by**: —  
**Amended**: review 12 (docs/reviews/12-review-tracker-split-view.md) — the row and meta shape named once in this header and used by 55-02; Story 1 tested end to end through the hooks, with writer keys, negative cases, a different-file case, the streaming hook and a guard control that can fail; Story 2's NFR1 fixture, the timing join as a pure function, the planned-model read in `register.ts`, `xhigh` and `timed`; Story 3 after Story 2 with `unmatched` always written; Story 4's toast and test isolation; Story 5 after Story 2 (2026-11-11)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 1), docs/library/01-library-lessons-learned.md → "Two more ways a control fails, and they are opposites (2026-09-21)" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 3), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 2), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 3), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (Story 2), docs/library/01-library-lessons-learned.md → "Reach for it before assuming the surface has it" (build), docs/library/01-library-lessons-learned.md → "Ask the runtime the question rather than modelling its answer" (build), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (build)

All work is in `cpm-next-progress/hooks/`. Test command: `claude plugin test cpm-next-progress`. Rules go in pure functions in `progress.ts` and `timing.ts`; hook wiring is tested in a new `register.test.ts` with the fake the spec's Testing Strategy describes. Each test in `register.test.ts` resets the module state it touches (`isChecking`, `isStarted`, `docsFolders`, `nudges`, `nudgeContext` and the new maps), or reloads the plugin. Code that takes `$` stays in `register.ts`: an older engine refuses a mod that passes `$` into a function imported from another file (`docs/maintenance/README.md`, older engines). Adding fields changes existing deep-equal assertions (`progress.test.ts`, `timing.test.ts`, `waiting.test.ts`); update them, they are not regressions.

**The shape 55-02 renders.** A row in `items` holds today's fields except `typical`, plus: `model` (lowercase family, `opus`; the page capitalises), `modelPlanned` (`true` only on a planned model), `effort` (`low`, `medium`, `high` or `xhigh`), `took` (minutes, rounded), `criteria` (`{ met, total }`, story rows only) and `needs` (`[{ kind, text }]`, present only when non-empty). `meta/tracker` holds today's fields plus `timed` (a number), `typical` (always present, `{}` when empty; each key an effort level, each value `{ range, low, high }`, `range` being `range()`'s text and `low`/`high` the unrounded minutes) and `unmatched` (always present, `[]` when empty).

## The model each story was built on
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR1, NFR4  
**Effort**: high  
**Test run**: 2 (1 full, 1 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 148 passed, 0 failed — tree 7174c8e4a02001b92df4fc6f9bbb7a2165c3e447 — wide reach: cpm-next-progress/hooks/register.ts (boot-time registration: the module `hooks.json` loads) — cpm-next-progress/hooks/timing.ts → hooks/timing.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/timing.test.ts → itself; cpm-next-progress/hooks/register.test.ts → itself; cpm-next-progress/hooks/register.ts → deferred full run  
**Audit**: pass (2026-11-11)

**Acceptance Criteria**:

- `recordTimes` takes a map of epic file name (basename) → last writer's model, and records on a story seen to go Pending → In Progress in a file the model's family, lowercase (`claude-opus-5-5` → `opus`, likewise `sonnet`, `haiku`, `fable`; an unrecognised id is kept whole), table-driven over the four families and an unrecognised id; `Observed` carries the file name `[unit]`
  - Evidence: "a start records the family of its epic doc's last writer, lowercase, and an unrecognised id whole", cpm-next-progress/hooks/timing.test.ts:162 — red: expected `{…, started: 1792054860000, model: "opus"}`, received it without `model` with lines undone in cpm-next-progress/hooks/timing.ts:67
- A start in file B, when only file A has a writer, records `started` and no `model`; a start in a file with no writer at all records `started` and no `model`; control: the same fixtures with a writer for B record its model `[unit]`
  - Evidence: "a start in a file with no writer of its own records no model", cpm-next-progress/hooks/timing.test.ts:173; "a writer of one epic doc is not credited with a start in another", cpm-next-progress/hooks/register.test.ts:204 — red: expected `{status: "In Progress", effort: "medium", started: 1792054860000}`, received it with `model: "opus"` with mutation of cpm-next-progress/hooks/timing.ts:66: `writers[file]` → `Object.values(writers).at(-1)`
- A reopened story (Complete → In Progress) keeps its first `started` and its first `model` `[unit]`
  - Evidence: "a reopened story keeps its first start and its first model", cpm-next-progress/hooks/timing.test.ts:185 — red: expected `{…, started: 1792054860000, model: "opus"}`, received `{…, started: 1792055520000, model: "sonnet"}` with mutation of cpm-next-progress/hooks/timing.ts:64: `prior.status === 'Pending'` → `prior.status !== 'In Progress'`
- Through the hooks in `register.test.ts`: a subagent loop whose `turn.step` is answered by `claude-sonnet-*` makes an `Edit` setting a story In Progress, and `times:` holds `sonnet` for that story, from the check that `Edit` triggered (the writer is recorded before `checkAll` runs) `[unit]`
  - Evidence: "a subagent answered by Sonnet that sets a story In Progress is recorded as its writer…", cpm-next-progress/hooks/register.test.ts:115 — red: expected `{…, started: 2000, model: "sonnet"}`, received it without `model` with lines undone in cpm-next-progress/hooks/register.ts:684-685
- Through the hooks: loop A (`haiku`) edits an epic while the fake listing still returns the old mtime, so that check skips on its signature; the main loop (`opus`) then runs a `Bash` that names no epic file and the listing shows the new mtime; the start records `haiku`; control: crediting the triggering loop records `opus` and fails `[unit]`
  - Evidence: "a start is credited to the last writer of its file, not to the loop whose call let the check see it", cpm-next-progress/hooks/register.test.ts:128; "a start in a file written by two loops records the later writer", :147 — red: expected `{…, model: "haiku"}`, received `{…, model: "opus"}` with mutation of cpm-next-progress/hooks/register.ts:685: iterate `[...Object.keys(writers), ...writtenEpics(…)]` (the triggering loop credited)
- Through the hooks, each of these records no writer: a `Read` of an epic file, a `NotebookEdit`, a `Bash` whose command names no epic file, and an `Edit` that is denied or returns an error; a `Bash` whose command contains an epic file's basename, and an `Edit`, `Write` or `MultiEdit` whose `file_path` ends in one, do record a writer `[unit]`
  - Evidence: "… records no writer" (Read, NotebookEdit, Bash naming no epic doc, denied Edit, Edit that errors) and "… records its loop as the writer" (Bash naming the doc, Edit, Write, MultiEdit), cpm-next-progress/hooks/register.test.ts:170, :193 — red: negatives expected `{…, started: 2000}`, received it with `model: "opus"` with mutations of cpm-next-progress/hooks/register.ts:682 (`WRITING_TOOLS` gate and the deny/error guard removed) and cpm-next-progress/hooks/timing.ts:117-118, :122 (any tool's path recorded; Bash `?? []` → `?? ['01-01-epic-first.md']`); positives expected `{…, model: "opus"}`, received it without `model` with lines undone in cpm-next-progress/hooks/timing.ts:117-122
- The `turn.step` hook is an `async function*` that returns `yield* next(e)` with `e` unchanged, as `cpm-next-models/hooks/register.ts:80-105` does: it records the loop's requested `e.model` before `next` and replaces it with `usage.model` after, so a tool call made during the step sees the step's model; through the hooks with the bottom fake of `cpm-next-models/hooks/register.test.ts:32-38` extended with `usage`, every chunk the fake yields reaches the caller and an error thrown by `next` propagates `[unit]`
  - Evidence: "the turn.step hook passes every chunk and the result through, and lets an error propagate", cpm-next-progress/hooks/register.test.ts:219; "a tool call made during a step sees the model the step asked for; one after sees the model that answered", :235 — red: expected the two text chunks, received `[]` with mutation of cpm-next-progress/hooks/register.ts:648: drain `next(e)` without yielding; expected an instance of Error, received `undefined` with mutation of register.ts:648: a try/catch returning a stub result; expected `"haiku"`, received `undefined` with lines undone in register.ts:647; expected `"opus"`, received `"haiku"` with lines undone in register.ts:649
- A `turn.step` result with `usage: null` leaves the loop's model as recorded from `e.model`; control: one with a usage replaces it `[unit]`
  - Evidence: "a step with no usage keeps the model the loop asked for; one with usage replaces it", cpm-next-progress/hooks/register.test.ts:251; "a step records the model that answered it…", cpm-next-progress/hooks/timing.test.ts:193 — red: expected `"haiku"`, received `undefined` with mutation of cpm-next-progress/hooks/timing.ts:90: a null usage deletes the loop's entry
- The per-loop recording is a pure function (`recordStep(map, agentId, model)` or similar) that drops its own errors: given a result whose `usage` getter throws, it returns the map unchanged and does not throw; control: with its guard removed the test throws `[unit]`
  - Evidence: "a step records the model that answered it, keeps the loop's model on a null usage, and drops its own errors", cpm-next-progress/hooks/timing.test.ts:193 — red: `expect(received).toBe()` expected the same map, received an equal copy with mutation of cpm-next-progress/hooks/timing.ts:94: `return map` → `return new Map(map)`; control seen: with the try/catch at timing.ts:88, 93-95 removed the test throws `Error: no usage` from its throwing getter
- `forgetLoop(map, agentId)` (or similar, pure) removes a subagent's entry and leaves the main loop's; through the hooks a subagent's `turn.complete` calls it; a start seen after that subagent's `turn.complete` in a file it wrote still records its model, since the writer map holds the model, not the loop id `[unit]`
  - Evidence: "a subagent's turn.complete forgets its loop, while the files it wrote keep its model", cpm-next-progress/hooks/register.test.ts:268; "a subagent's loop is forgotten and the main loop's is kept", cpm-next-progress/hooks/timing.test.ts:205 — red: expected `{…, started: 3000}`, received it with `model: "haiku"` with mutation of cpm-next-progress/hooks/timing.ts:100: unconditional `return map`, and with lines undone in cpm-next-progress/hooks/register.ts:656 (the `forgetLoop` call)

### Record writers and models
**Task**: 1.1  
**Description**: Per-loop model map from `turn.step`; per-file last-writer map from write `tool.call`s, recorded before `checkAll`; `recordTimes` takes the writer map; `StoryTime` and `Observed` gain `model` and the file name.  
**Status**: Complete

---

## Row fields and typical ranges in meta
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR2, FR3, NFR1  
**Test run**: 2 (1 full, 1 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 158 passed, 0 failed — tree 6874a3b20d9777a7c3f229257d49ac1841e24601 — wide reach: cpm-next-progress/hooks/register.ts (boot-time registration: the module `hooks.json` loads) — cpm-next-progress/hooks/progress.ts → hooks/progress.test.ts, hooks/timing.test.ts, hooks/waiting.test.ts, hooks/testrun.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/timing.ts → hooks/timing.test.ts, hooks/progress.test.ts, hooks/waiting.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/progress.test.ts, timing.test.ts, waiting.test.ts, register.test.ts → themselves; cpm-next-progress/hooks/register.ts → deferred full run  
**Audit**: pass (2026-11-11)

**Acceptance Criteria**:

- A story row carries `model` from the story's `**Model**` field (lowercased) when it has one, at any status, including an In Progress story first seen after timing began; otherwise the recorded model; otherwise, for a story whose work status is Pending (shown as Pending, Ready or Waiting on input), the `model:` of the installed `cpm-next` `do` SKILL.md frontmatter, as a family, with `modelPlanned: true`; with none of these (an unreadable SKILL.md, or a started story or one first seen Complete with no recorded model), no `model` key; control: a Pending story with `**Model**: haiku` carries `haiku` and no `modelPlanned` `[unit]`
  - Evidence: "a row's model: the Model field at any status, else the recorded model, else for a story not started the planned model", cpm-next-progress/hooks/progress.test.ts:502 — red: expected "haiku", received "opus" with mutation of cpm-next-progress/hooks/progress.ts:299: the `**Model**` field branch removed; expected false, received true (`'model' in` the started story with no record) with mutation of cpm-next-progress/hooks/progress.ts:301: `work === 'Pending' &&` dropped
- The SKILL.md read lives in `register.ts`, once per check: it picks the install from `~/.claude/plugins/installed_plugins.json` as `cpm-next-models/hooks/register.ts` `frontmatterOf` and `pin.ts` `pickInstall` do, the project-scoped install for this project before the user-scoped one; tested in `register.test.ts` with a fake holding both scopes, the project one winning `[unit]`
  - Evidence: "a story not started takes the planned model from the project-scoped install of cpm-next before the user one, read once per check", cpm-next-progress/hooks/register.test.ts:290 — red: expected `{ model: "sonnet", modelPlanned: true }`, received `model: "opus"` with mutation of cpm-next-progress/hooks/progress.ts:648: `pickInstall` checks the user scope first; expected 1, received 2 reads with mutation of cpm-next-progress/hooks/register.ts:306: `planned ??=` → `planned =`
- A story row carries `effort` normalised by `timing.ts` `effortOf`, now exported, giving `medium` when the story has no `**Effort**` `[unit]`
  - Evidence: "a row's effort is normalised as timings normalise it, medium when absent", cpm-next-progress/hooks/progress.test.ts:520 — red: expected `["low", "medium", "high", "xhigh"]`, received `["low", "", "high", "xhigh"]` with mutation of cpm-next-progress/hooks/progress.ts:371: `effortOf(story.effort)` → `story.effort`
- A Complete story with both times carries `took`, rounded to whole minutes; a reopened story's `took` runs from its first start; a Complete story without a start, or with `finished <= started`, carries no `took` `[unit]`
  - Evidence: "a timed Complete story carries the whole minutes it took; …", cpm-next-progress/hooks/progress.test.ts:525 — red: expected false, received true with mutation of cpm-next-progress/hooks/progress.ts:306: `&& record.finished > record.started` dropped; expected 45, received 44 with mutation of cpm-next-progress/hooks/progress.ts:307: `Math.round` → `Math.floor`
- A story row carries `criteria: { met, total }`, table-driven over: a criterion with an `Evidence` line (met), one with `Evidence (user, …)` (met), one with both `Evidence` and `Not met:` (not met), one with neither (not met), a legacy story-level `**Evidence**:` (every criterion met), and a story with no criteria (`{ met: 0, total: 0 }`) `[unit]`
  - Evidence: "a story row counts its criteria met: …", cpm-next-progress/hooks/progress.test.ts:536 — red: expected `{ met: 2, total: 4 }`, received `{ met: 3, total: 4 }` with mutation of cpm-next-progress/hooks/progress.ts:285: `&& !c.hasNotMet` dropped; expected `{ met: 2, total: 2 }`, received `{ met: 0, total: 2 }` with lines undone in cpm-next-progress/hooks/progress.ts:283 (the legacy return)
- A task row carries its story's `model`, `modelPlanned` and `effort`, and no `took` or `criteria` `[unit]`
  - Evidence: "a task row carries its story's model and effort, and no time or criteria", cpm-next-progress/hooks/progress.test.ts:543 — red: expected false, received true with mutation of cpm-next-progress/hooks/progress.ts:372: `criteria` put on every row
- `meta/tracker` carries `timed` and `typical` in the shape this epic's header gives: from a fixture with 10 steady medium stories and 2 started-but-unfinished ones, `timed` is 10, `typical.medium` holds `range()`'s text and `estimate`'s unrounded `low` and `high`, and `typical.low`, `typical.high` and `typical.xhigh` come from the all-stories fallback; with 9 finished, `typical` is `{}`; with 10 whose slower quartile is over three times the quicker, `typical` has no `medium` `[unit]`
  - Evidence: "the meta carries how many stories are timed, and each steady effort's range and unrounded bounds", cpm-next-progress/hooks/timing.test.ts:225 — red: expected 10, received 12 with mutation of cpm-next-progress/hooks/timing.ts:223: `timed` counts every record with `started`; expected `low: 36.25, high: 48.75`, received `low: 36, high: 49` with mutation of cpm-next-progress/hooks/timing.ts:220: bounds rounded; expected false, received true with mutation of cpm-next-progress/hooks/timing.ts:220: `isSteady === true` → `found !== undefined`
- The timing join that today sits in `checkOne` (`register.ts:155-162`) moves into a pure function in `progress.ts`, and no row it returns has a `typical` key, at any status; control: today's join puts one on a timed in-progress row, so the test fails on it `[unit]`
  - Evidence: "no row carries a typical range, at any status", cpm-next-progress/hooks/progress.test.ts:554 — red: expected `[]`, received the In progress row `02-01 S3` with `typical: 'x'` with mutation of cpm-next-progress/hooks/progress.ts:305: the start assignment also sets `typical`, as the join in `checkOne` did
- `indexEntry` takes the times and fills each in-progress story's `typical` from `timingOf`, still for rows whose status is `In progress` only; the overview's timings are unchanged for the same inputs `[unit]`
  - Evidence: "an index entry takes each in-progress story's range from the times, for In progress rows only", cpm-next-progress/hooks/timing.test.ts:243; "timings pass from tracker rows to the index and the overview rows…", :136 — red: expected only `04-01 S5`, received the Waiting on input row `04-01 S7` too with mutation of cpm-next-progress/hooks/timing.ts:201: `r.status === 'In progress' &&` dropped; expected `typical: "36–49 min"`, received `typical: ""` with mutation of cpm-next-progress/hooks/timing.ts:202: the `timingOf` lookup → `''`
- With the docs fixed and only the times changing (a medium story in another spec's build order finishes, which changes `range()`'s text for medium), and two medium stories of this tracker In Progress, `diff` returns one write, `meta/tracker`, and no `items` write `[unit]`
  - Evidence: "a moved estimate writes only the meta; unchanged inputs write nothing, and one more Evidence line writes one row", cpm-next-progress/hooks/progress.test.ts:562 — red: expected `["meta/tracker"]`, received every `items/02-01-s*` row and `meta/tracker` with mutation of cpm-next-progress/hooks/progress.ts:372: story rows carry a count of the Complete timing records
- Unchanged docs, times, SKILL.md and live data give zero writes; control: the same fixture with one `Evidence` line added gives exactly one write `[unit]`
  - Evidence: "a moved estimate writes only the meta; …", cpm-next-progress/hooks/progress.test.ts:562 — red: expected `[]`, received a `meta/tracker` write with mutation of cpm-next-progress/hooks/progress.ts:505: the meta always written; control: expected `["items/02-01-s1"]`, received `[]` with mutation of cpm-next-progress/hooks/progress.ts:372: `criteria` without `met`

### Rows and meta
**Task**: 2.1  
**Description**: `parseEpic` reads `**Model**`; the pure timing join; `buildItems` gains the fields; meta gains `timed` and `typical`; `indexEntry` takes times; the SKILL.md read in `register.ts`.  
**Status**: Complete

---

## Decisions matched to their rows
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR4  
**Test run**: 3 (1 full, 2 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 165 passed, 0 failed — tree fd12658392578ce2d23369caa98d0ec53dfb2efe — wide reach: cpm-next-progress/hooks/register.ts (boot-time registration) — cpm-next-progress/hooks/progress.ts → hooks/progress.test.ts, hooks/timing.test.ts, hooks/waiting.test.ts, hooks/testrun.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/progress.test.ts → itself; cpm-next-progress/hooks/register.test.ts → itself; cpm-next-progress/hooks/register.ts → deferred full run  
**Audit**: pass (2026-11-11), 1 finding fixed  
**Signal**: check-cannot-fail — project — the criteria on what `meta/tracker` holds were proved only on `buildItems` and on a meta the test built, so dropping `unmatched` from `checkOne`'s meta left the suite green (cpm-next-progress/hooks/register.ts:211, 55-01 S3 audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (a check green for a reason other than the mechanism it names)

**Acceptance Criteria**:

- A table-driven test over decision forms: `[01-05 S4, review]`, `[01-05 s4, review]`, `[01-05 S04, review]`, `[01-05 S4 , review]`, `[01-05 S4,review]`, `  [01-05 S4, input]` (leading spaces), `[01-05 S4, Blocked on me]` (a kind of several words), `[01-05 T3.1, input]` and `[01-05 t3.1, input]` each attach to their row as `{ kind, text }`, `text` trimmed, prefix removed; floor: `01-05-s4` holds every S4 decision in file order and `01-05-t3.1` holds both task decisions `[unit]`
  - Evidence: "a decision prefixed with a row of the tracker is attached to that row, in each form the prefix is written", cpm-next-progress/hooks/progress.test.ts:634 — red: the `needs` expect at :638 received a list without "second" with mutation of cpm-next-progress/hooks/progress.ts:320: the `i` flag dropped from `DECISION_PREFIX`; and without "third" with mutation of cpm-next-progress/hooks/progress.ts:331: the zero-padded number kept as written
- `[01-05 S4 review]` (no comma), `[01-05, review]` (epic-wide), `see [01-05 S4, review]` (not at the start), a decision with no prefix, `[01-05 S9, review]` (no such row), `[07-01 S1, review]` (an epic not in the build order), `[01-05 S3, review]` where the build order lists only S3's task `T3.1`, and a prefix naming a build-order entry that `buildItems` reports missing, each go to `meta/tracker` `unmatched` whole; control: the matched forms in the same fixture are not in `unmatched` `[unit]`
  - Evidence: "a decision with no prefix, or naming no row of the tracker, is kept whole as unmatched", cpm-next-progress/hooks/progress.test.ts:647; control in :634 — red: expected the eight unmatched decisions, received a list without `[01-05 S4 review] no comma` with mutation of cpm-next-progress/hooks/progress.ts:320: `\s*,\s*` → `\s*,?\s*`; control expected false, received true at :644 with mutation of cpm-next-progress/hooks/progress.ts:349: a matched decision also pushed to `unmatched`; through the hooks, "a check writes the meta with every decision and the unmatched ones, an empty list when all match", cpm-next-progress/hooks/register.test.ts:312 — red: expected `{ decisions: […], unmatched: ["no prefix", "[09-09 S1, input] no such row"] }`, received a meta with no `unmatched` with mutation of cpm-next-progress/hooks/register.ts:211: `unmatched` left out of the meta (audit round 1 fix)
- When every decision matches, `unmatched` is `[]`, present; a row with no needs has no `needs` key `[unit]`
  - Evidence: "every decision matched leaves an empty unmatched list, and a row with no decision has no needs", cpm-next-progress/hooks/progress.test.ts:652 — red: expected false, received true at :656 with mutation of cpm-next-progress/hooks/progress.ts:341: every row given `needs ??= []`; expected `[]`, received `undefined` at :655 with mutation of cpm-next-progress/hooks/progress.ts:420: `unmatched` returned only when non-empty; through the hooks, "a check writes the meta with every decision and the unmatched ones, an empty list when all match", cpm-next-progress/hooks/register.test.ts:312 — red: expected `{ decisions: […], unmatched: ["no prefix", "[09-09 S1, input] no such row"] }`, received a meta with no `unmatched` with mutation of cpm-next-progress/hooks/register.ts:211: `unmatched` left out of the meta (audit round 1 fix)
- `meta/tracker` `decisions` equals the build-order file's list, over a fixture holding both matched and unmatched decisions `[unit]`
  - Evidence: "the meta keeps every decision as the build-order file lists it", cpm-next-progress/hooks/progress.test.ts:662 — red: expected the seventeen decisions in file order, received the unmatched ones with mutation of cpm-next-progress/hooks/progress.ts:547: the meta's `decisions` replaced by `meta.unmatched`; through the hooks, "a check writes the meta with every decision and the unmatched ones, an empty list when all match", cpm-next-progress/hooks/register.test.ts:312 — red: expected `{ decisions: […], unmatched: ["no prefix", "[09-09 S1, input] no such row"] }`, received a meta with no `unmatched` with mutation of cpm-next-progress/hooks/register.ts:211: `unmatched` left out of the meta (audit round 1 fix)
- Changing the text of an unmatched decision writes `meta/tracker` only; changing a matched one writes that row and meta, and no other row `[unit]`
  - Evidence: "a changed unmatched decision writes only the meta; a changed matched one writes its row and the meta", cpm-next-progress/hooks/progress.test.ts:670 — red: expected `["meta/tracker"]`, received `["items/01-05-t3.1", "items/01-05-s4", "meta/tracker"]` at :683 with mutation of cpm-next-progress/hooks/progress.ts:420: every row given a field from the unmatched list; expected `["items/01-05-t3.1", "meta/tracker"]`, received `items/01-05-s4` too at :684 with mutation of cpm-next-progress/hooks/progress.ts:349: each need attached to every row of its epic

### Match decisions
**Task**: 3.1  
**Description**: Parse each decision's prefix in `progress.ts`; attach `needs` to rows; meta gains `unmatched`.  
**Status**: Complete

---

## Criteria-only changes wait for the turn's end
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR11  
**Effort**: high  
**Amended**: the first criterion reads the turn-end prompt's text (the row and the pending file) in place of its context (2026-11-11) — cited: under `claude plugin test` the plugin's own `prompt.submit` hook did not run for the prompt `nudge` submits, so `nudgeContext` was never attached (a hook test showed no context and no run of that hook), and `PromptSubmitArgs` omits `context` (cpm-next-progress/.claude-plugin/types/claude-code/index.d.ts:8356), so the submission cannot carry it either; the documented contract says the plugin's other hooks do see its submission (index.d.ts:2720-2721), so whether a live session attaches the context is unverified  
**Signal**: spec-drift — project — FR11's test assumed the turn-end prompt's context could be read under `claude plugin test`, where the plugin's own `prompt.submit` hook does not run for the prompt it submits (cpm-next-progress/hooks/register.ts `nudge`, `prompt.submit` hook; 55-01 S4 build) — recurs: docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (a criterion's claim about the code that the code does not bear out)  
**Test run**: 3 (1 full, 2 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 168 passed, 0 failed — tree e94abd8db96c5617db8c2964bd318badc3137b47 — closes epic; wide reach: cpm-next-progress/hooks/register.ts (boot-time registration) — cpm-next-progress/hooks/progress.ts → hooks/progress.test.ts, hooks/timing.test.ts, hooks/waiting.test.ts, hooks/testrun.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/register.test.ts → itself; cpm-next-progress/hooks/register.ts → deferred full run  
**Audit**: pass (2026-11-11), 1 finding fixed

**Acceptance Criteria**:

- Through the hooks: one `Evidence` line added to a story's criterion gives exactly one row write; the tool call's result carries no write note and no toast is shown; the project is marked behind; after `turn.complete` the test awaits the `prompt.submit` that `nudge` fires and finds the row and the pending file holding its write named in its text; control: the same story's status moving to Complete adds the note to that tool call's result and toasts, as today `[unit]`
  - Evidence: "a change to a row's criteria alone puts no note on the tool result; the writes are asked for at the turn's end", cpm-next-progress/hooks/register.test.ts:376 (one write, `01-01-s1` with `criteria { met: 1, total: 1 }`; no note; no toast; `behind:` true; the turn-end prompt names `01-01-s1` and the pending file); "control: the same story moving to Complete puts the note on the tool result and toasts", :399 — red: expected `[]`, received the "Progress tracker out of date" note with mutation of cpm-next-progress/hooks/register.ts:708: the quiet check → `found.drift.length === 0` (retaken after the round-1 fix changed the test file's comment); expected `[]`, received a toast with mutation of cpm-next-progress/hooks/register.ts:708-709: the toast moved above the quiet return; expected 1, received 0 prompts with mutation of cpm-next-progress/hooks/register.ts:544: `nudge` drops quiet drifts; control expected `/Progress tracker out of date/`, received `""` with mutation of cpm-next-progress/hooks/progress.ts:636: `isCriteriaOnly` without its `criteria` comparison
- A drift holding both a criteria-only row change and another row change adds the note for all its writes `[unit]`
  - Evidence: "a drift with a criteria-only row change and another row change puts the note for all its writes on the result", cpm-next-progress/hooks/register.test.ts:409 — red: expected `/"doc_id":"01-01-s1"/`, received a note holding only `01-02-s1` with mutation of cpm-next-progress/hooks/register.ts:224: criteria-only writes dropped from a mixed drift

### Split the note
**Task**: 4.1  
**Description**: Classify a drift's writes; a drift of criteria-only row changes is left to `nudge`, without a toast.  
**Status**: Complete

---

## The times report names the model
**Story**: 5  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR12  
**Effort**: low  
**Test run**: 1 (0 full, 1 targeted) — targeted — `claude plugin test cpm-next-progress`: 95 passed, 0 failed — tree 12d0a785e05a93bda024e33bfff56cc298ca74bf — cpm-next-progress/hooks/timing.ts → hooks/timing.test.ts, hooks/progress.test.ts, hooks/waiting.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/timing.test.ts → itself  
**Audit**: pass (2026-11-11)

**Acceptance Criteria**:

- `timesReport`'s line for an in-progress story with a recorded model reads `{key} ({effort}, {model}): …`, the model lowercase; control: one with none reads `{key} ({effort}): …` as today `[unit]`
  - Evidence: "the report names the model of a timed story in progress, and leaves it out when none was recorded", cpm-next-progress/hooks/timing.test.ts:253 — red: expected `/04-01 S5 \(medium, sonnet\): 20 min in/`, received `04-01 S5 (medium): 20 min in; …` with mutation of cpm-next-progress/hooks/timing.ts:267: the model part removed; control: expected `/04-01 S6 \(high\): 20 min in;/`, received `04-01 S6 (high, undefined): …` with mutation of cpm-next-progress/hooks/timing.ts:267: the model always appended

### Report line
**Task**: 5.1  
**Description**: Add the model to the in-progress line in `timesReport`.  
**Status**: Complete

---
