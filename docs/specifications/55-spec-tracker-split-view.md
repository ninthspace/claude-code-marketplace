# Spec: The progress tracker in split view, with model, time and what needs you

**Date**: 2026-11-11  
**Source**: docs/discussions/24-discussion-amend-progress-tracker-command.md; reference mockup https://claude.ai/artifact/39M6y3ST9AzL3PFt8VDJQg (board D, `project/D.dc.html`)  
**Amended**: 2026-11-11 — FR13: the prompt submitted at a turn's end names each pending file and tells Claude to apply the writes from it, in place of "the writes given with this message" (from 55-01 Story 4's Pivot deferred; the user's choice)

## Problem Summary

The tracker page (`cpm-next-progress/page/tracker.html`) lists stories with Item, Title, Status, Blocked by, Risk / notes and Updated, and a box of decisions above the table. Before and during a long `do` run the reader cannot see, per story, what is waiting on them, which model built or is building it, how long it took or is likely to take, or how far its acceptance criteria have got. The decisions box lists every decision with no link to the story it concerns.

The change extends the existing page and the mod's rows; it adds no second page. The page becomes a split view: a table on the left (#, Title, Status, Model, Effort, Time, Needs you) and the selected row's detail on the right. The mod records the model each story was built on, carries effort and criteria progress on each row, keeps the typical ranges in the tracker's meta, and matches each decision to its row by the decision's `[epic story, kind]` prefix.

## Functional Requirements

### Must Have

- **FR1**: When a check sees a story go from Pending to In Progress, the mod records in the story's timing record (`Times`, `cpm-next-progress/hooks/timing.ts`) the model of the last writer of that story's epic file: the model that answered the latest step (`turn.step` result `usage.model`) of the agent loop (`agentId`, main loop when absent) whose `Edit`, `Write` or `MultiEdit` named that file in `file_path`, or whose `Bash` command contains the file's name. A start in a file with no recorded writer records no model. A `turn.step` with null `usage` leaves the loop's last model as it was. — AC: rules stated over the attribution function and `recordTimes`: a start in a file last written by a loop answered by `claude-opus-5-5` records `opus`, also when the check that saw it was not the one the write triggered (a check skipped while another ran); a start in a file written by two loops records the later writer's; a start with no writer records `started` and no model (control: the same fixture with a writer records one); a null-usage step keeps the previous model `[unit]`
- **FR2**: Each story row carries `model` (the story's `**Model**` field when it has one, whatever its status; otherwise the recorded model's family; for a Pending story with neither, the `model:` of `cpm-next` `do`'s SKILL.md frontmatter, read from the installed plugin's path in `~/.claude/plugins/installed_plugins.json` as cpm-next-models reads it (`cpm-next-models/hooks/register.ts` `frontmatterOf`), with `modelPlanned: true`; absent when none of these gives one), `effort` (the story's `**Effort**` normalised as timings normalise it, `medium` when absent), `took` (whole minutes from start to finish, for a Complete story with both times; a reopened story keeps its first start, so `took` includes the time it lay Complete), and `criteria` (`{ met, total }`, a criterion counting as met when it has an `Evidence` line and no `Not met:` line, or every criterion under a legacy story-level `**Evidence**:` field). A task row carries its story's `model` and `effort`, and no `took` or `criteria`. A story row carries no `typical`. — AC: rows built from fixture epics carry each field by that rule, with cases for the `**Model**` field on a Pending and on an In Progress story first seen after timing began, the `medium` default, a criterion with both `Evidence` and `Not met:`, a legacy-evidence story, a story with no criteria (`{ met: 0, total: 0 }`), a reopened story, and a task row `[unit]`
- **FR3**: The `meta/tracker` document carries `timed` (the number of timed stories) and `typical`: for each effort level with a steady estimate by the existing rule (`estimateFor`: `MIN_STORIES` timed stories of that effort, else of all, and `isSteady`), its range text (`range()`) and its `low` and `high` bounds in minutes as `estimate` gives them. No row in the `items` collection carries a typical range. — AC: from a times fixture with 10 steady medium stories, meta carries `typical.medium` with `range()`'s text and `estimate`'s unrounded bounds, and `typical.low` and `typical.high` from the all-stories fallback; with 9, no `typical`; with 10 whose slower quartile is over three times the quicker, no `typical.medium`; no written row of any status has a `typical` key `[unit]`
- **FR4**: Each decision in the build-order file whose text starts (after leading whitespace) with `[{epic} {S|T}{id}, {kind}]` is attached to that row as `needs: [{ kind, text }]`, in file order, `text` being the decision without its prefix. Read tolerantly: `S` or `s`, a zero-padded story number (`S04` is story 4), spaces around the comma, and a kind of several words. A decision with no such prefix (no comma, an epic-wide `[01-05, review]`, a prefix not at the start), or whose prefix names no row in the build order, goes to `meta/tracker` `unmatched`, whole. `meta/tracker` `decisions` keeps the full list as today. — AC: a table-driven test over each form named here, with a floor naming the rows that must hold needs (`01-05-s4` holds both its decisions, in file order; `01-05-t3.1` holds its task decision), every unmatched decision kept whole in `unmatched`, and `decisions` equal to the input `[unit]`
- **FR5**: The page is a split view: a table with columns # (the row's `{epic} {story}`, e.g. `01-05 S2`, in rows ordered by `seq`), Title, Status, Model, Effort, Time and Needs you, grouped by phase as today, and beside it the selected row's detail, which stays in view while the table scrolls (sticky, with its own scroll when taller than the viewport). Below 760 px wide the detail sits above the table, the table drops its minimum width, and Model and Effort are hidden from the table (they stay in the detail), so no row needs horizontal scrolling to show its Needs you badge. Blockers show under the status as `after {ref}; …` in the same form as the # column, and a row with a note shows its first line, muted and cut with an ellipsis, under its title. Empty cells show `—`. — AC: in the harness at 1280 px, the seven headings show and the detail's box is to the right of the table's (`getBoundingClientRect`); with 60 rows scrolled to the last, selecting it leaves the detail inside the viewport; at 390 px (an iframe of that width) the detail's box is above the table's, `scrollWidth <= clientWidth` for the document, and every row's Needs you cell is inside the table's visible box `[browser]`
- **FR6**: The Time column shows `took {span}` for a Complete row with `took`; `{span} in` and, when `meta.typical` has its effort, `typically {range}` for a timed row in progress; `typically {range}` for a Pending or Waiting row when `meta.typical` has its effort; otherwise `—`. Elapsed time is worked out on the page and redrawn each minute, as today. — AC: in the harness, rows of each kind render the rule's text with `meta.typical` holding their effort and without it, and with meta absent `[browser]`
- **FR7**: The Needs you column shows the count of the row's `needs` items as a badge, blank when 0. The badge and the strip use the `--wait` / `--wait-bg` tokens of the Waiting on input pill. The summary line gives the total that needs the reader (all rows' needs items plus `unmatched`) with a control that selects the next row holding needs items, in table order, wrapping. Decisions in `unmatched` show in a strip above the table, headed "Not matched to a row", each whole, the first three shown and the rest behind "{n} more"; hidden when there are none. A meta without `unmatched` (rows written before this release) shows `meta.decisions` in the strip. — AC: in the harness, a row with two needs items shows `2` and one with none shows no badge; the total counts both kinds; the control steps through the needs rows and wraps; the strip lists the unmatched decisions, collapses past three, disappears when an emitted meta has none, and shows `decisions` for a meta without `unmatched` `[browser]`
- **FR8**: The detail panel for the selected row shows its ref and title, model and effort, and, for a story: started time and expected-by window as local `HH:MM` (with the date when it is not today), running time, the typical range for its effort, `took` for a Complete row (`not timed` when it has none), its blockers, its full note, its Needs you items with their kind (`Nothing needs you` when none), and criteria progress (`{met} of {total} met`, `No criteria` when 0). Without a range it reads `Typical range: after 10 timed stories ({timed} so far)`. A story running past the range's high bound shows `{span} past the typical range` in place of the expected-by window. The panel is a labelled region, not a live region. — AC: in the harness with `started` set relative to load time, an in-progress row inside its range shows expected-by from its start and bounds, one past the range shows the minutes past, a complete row shows took, an untimed complete row shows `not timed`, a row with no needs and no criteria shows both empty lines, and meta without `typical` shows the "after 10 timed stories" line with `timed` `[browser]`
- **FR9**: A row is selected by click, or by keyboard: each row's title is a button in tab order, Enter or Space selects, and the selected button has `aria-pressed="true"`. Below 760 px a selection moves focus to the detail's heading. The selection is the previously selected row while it exists, else the first row with needs items, else the first In progress row, else the first row not Complete, else the first row. A redraw (a snapshot or the minute tick) keeps the selection and keeps keyboard focus on the same row's button. — AC: in the harness, one fixture per step of the rule, including a control with both a needs row and an In progress row where the needs row is chosen; a selection survives an emitted snapshot that changes another row; focus on a row's button survives the minute redraw and a snapshot; Tab then Enter selects a row `[browser]`
- **FR10**: An existing tracker reaches the new page and rows with `/progress-tracker {nn}` and no other step: the page is rewritten from the new template and republished to its link, and the republish runs a check now whose writes are handed to Claude, as a first publish does. A row-schema version is part of the check signature and the settled mark, so the first check after the upgrade reads every tracker, settled ones included, even with no doc changed. — AC: the page `prepare` writes for a build order with an `artifact` contains the detail panel's id, which the old template lacks; after a republish of an existing tracker over unchanged docs, the `Artifact` hook's result carries writes for the rows lacking the new fields; control: live rows and meta that already hold every new field give zero writes `[unit]`
- **FR11**: A row change that touches only `criteria` adds no write note to the tool result that caused it; the project is marked behind and the writes are asked for at the turn's end, as an outstanding drift is today. A change to any other field adds the note as today. — AC: one `Evidence` line added to a story gives exactly one row write, carried by the turn-end prompt and not by the tool result; control: the same story's status moving to Complete adds the note to the tool result `[unit]`

- **FR13**: The prompt the mod submits when a turn ends with a tracker behind, and the one `/progress-tracker` submits after a check, tells Claude where the writes are: for each drift, its pending file and the artifact link, with the instruction to apply that file's batches with the `ArtifactData` tool (`action` `batch`), or, for a drift of more than eight writes, to hand the file to a Haiku subagent as the tool-result note does. It no longer says the writes are given with the message. The writes still go as context, which the model may or may not receive. — AC: `turnEndNote`'s text for a drift of up to eight writes and one of more than eight names the pending file and the link and gives the matching instruction, and holds no "given with this message"; through the hooks, the prompt `nudge` submits names the pending file and the link; control: the old text fails the same assertions `[unit]`

### Should Have

- **FR12**: `/progress-tracker times` and the `story_times` tool name the recorded model of each story in progress beside its effort. — AC: the line for an in-progress story with a recorded model reads `{key} ({effort}, {model}): …`; control: one with none reads `{key} ({effort}): …` as today `[unit]`

### Could Have

### Won't Have (this iteration)

- Default actions per pending item (discussion 24: a timeout is not approval).
- A second dashboard page or a dashboard subagent.
- Changes to the overview page or pane.
- The per-criterion list of open criteria named in the mockup ("Open: duplicates, …"); the panel gives the count.
- A "last checked" time on the page: it would rewrite meta at every check.

## Non-Functional Requirements

- **NFR1**: A change in the timing estimates writes at most the one `meta/tracker` document; no row is rewritten because an estimate moved. A check over unchanged docs, times and live data writes nothing. — AC: from times before and after one more story finishes, with two other stories of that effort In Progress, the only write is `meta/tracker`; unchanged inputs give zero writes `[unit]`
- **NFR2**: `claude plugin validate cpm-next-progress` and `claude plugin test cpm-next-progress` pass; `claude plugin test` still passes for cpm-next-models and whats-next; the mod loads headless under each installed Claude Code version, as `docs/maintenance/README.md` describes.
- **NFR3**: The page meets the artifact contract the current template meets: colour tokens on `:root` with the dark-mode overrides, no horizontal page scroll at 390 px, and text contrast of at least 4.5:1 for the badge, the strip, muted text and every status pill in both themes; the badge's colours differ from every status pill's but the Waiting on input pill's. — AC: in the harness, computed colours checked per theme (`data-theme` light and dark) with a contrast calculation in `javascript_tool` `[browser]`
- **NFR4**: The `turn.step` hook passes every request through unchanged, never fails it (its recording is wrapped so an error is dropped), and drops a subagent's entry when that loop's `turn.complete` arrives, so the per-loop map holds only live loops.

## Architecture Decisions

### AD1: The mod observes the model per writer; it reads no other plugin's state

The model is taken from the `turn.step` result's `usage.model`, the model that answered, kept in memory per agent loop (keyed by the input's `agentId`). Each write `tool.call` that names an epic file records that loop's model as the file's last writer. A start seen in that file, by whichever check sees it, records the last writer's model. The story's `**Model**` field takes precedence on the row, since `do` sets a story In Progress in its main loop and then hands a `**Model**: haiku` story to a Haiku subagent.

Considered: crediting the loop whose write triggered the check (wrong when checks collide, since `checkAll` drops a check while another runs, or when a Bash that wrote nothing triggers it); reading cpm-next-models' `pin` through `$.state.get` (couples the mods, holds only the main loop's model and the last story number, and gives nothing without cpm-next-models); reading the model from the epic doc only; having `do` write a field to the story (a contract change across cpm-next, both mods and `status`, for data the mod can observe). The discussion asked that the mod capture it.

### AD2: Typical ranges live in meta, per effort, and nowhere on the rows

A row's Time text depends on its effort's range, which changes whenever a story finishes. On rows it would rewrite every pending and in-progress row at each finish. Meta carries one range per effort level and the page joins it to the row's `effort`. The `typical` now written on a timed in-progress row is no longer written; the index and overview take their timings from `timingOf` directly, as they read in-memory items, not the database.

### AD3: Decisions are matched in the mod

Matching in `progress.ts` keeps the rule under `claude plugin test` and gives the page data it renders without parsing. Rows change only when a decision naming them changes. `meta/tracker` `decisions` keeps the full list, so a page published before this release still shows every decision, and the new page falls back to it before the first check writes `unmatched`.

### AD4: One template, rewritten; a row-schema version forces the first check

`page/tracker.html` is rewritten in place to the split view; `/progress-tracker {nn}` already republishes from the current template. A constant row-schema version joins the `checked:` signature and the `settled:` mark, so stored marks from the earlier release no longer match and the first check reads every tracker.

### AD5: Criteria-only changes are written at the turn's end

Every `Evidence` line `do` writes would otherwise make a write note on that tool's result, in whichever loop wrote it, parallel subagents included. A drift whose only changed field is `criteria` is left to the turn-end nudge, which already applies outstanding writes.

## Scope

### In Scope

- `cpm-next-progress/hooks/progress.ts`, `timing.ts`, `register.ts` and their tests.
- `cpm-next-progress/page/tracker.html`.
- A local harness for browser checks of the page under `cpm-next-progress/hooks/fixtures/` (not published).
- `README.md` (CPM Next Progress section: statuses, page, data layout, mod store), the plugin and marketplace versions, `docs/maintenance/README.md`.

### Out of Scope

- The overview page, the pane and `whats-next`.
- cpm-next skills and the artefact contract (no new field).
- cpm-next-models.

## Testing Strategy

Command: `claude plugin test cpm-next-progress` (runs `hooks/*.test.ts` with `claude-code/testing`, which gives no fs, network or process). `[unit]` criteria are tests, red first:

- Rules as pure functions in `progress.ts` and `timing.ts`, tested in `progress.test.ts` and `timing.test.ts`: attribution (`recordTimes` with the writers' models, the per-loop and per-file maps), row fields, meta `typical` and `timed`, decision matching, the criteria-only split, the row-schema mark.
- One integration test file, `hooks/register.test.ts`, for FR1's hook wiring, FR10 and FR11, with a shared fake: `fs.list` (with `mtimeMs` and `size` that change between steps, or `checkAll` skips on an unchanged signature), `fs.read`, `fs.exists`, `fs.write`, `session.cwd`, `env.get`, `ArtifactData` reads, and a bottom `turn.step` that returns `usage: { model }`. Module state (`isChecking`, `isStarted`, `docsFolders`, the per-loop map) is reset or the plugin reloaded per test.

`[browser]` criteria are checked with claude-in-chrome on a harness served locally (`python3 -m http.server` from a scratch copy): it wraps `fillTemplate` output in the document skeleton a publish adds, defines `window.claude.use("db")` with a stub that keeps the `onSnapshot` callbacks and exposes `window.__emit(items, meta)`, sets `started` relative to load time, and loads the page in a 390 px iframe for the narrow cases (desktop Chrome will not size a window that narrow). Positions are read with `getBoundingClientRect` and colours with `getComputedStyle` through `javascript_tool`. The harness includes legacy rows (no `model`, `effort`, `needs` or `criteria`), a null meta, and meta without `typical` or `unmatched`. `[manual]` covers docs, version lines and the headless load under each installed engine. `[user]` covers the republished tracker seen during a real `do` run.

## Assumptions

- The model is shown by family, capitalised (`Opus`, `Sonnet`, `Haiku`, `Fable`), found as cpm-next-models' `familyOf` finds it (`cpm-next-models/hooks/pin.ts:84`), written again in cpm-next-progress rather than imported across plugins.
- A Pending story with no `**Model**` field shows `do`'s default model, muted, as the planned model (user's choice, 2026-11-11); once it starts, the recorded model replaces it. If the installed `do` SKILL.md cannot be read, the cell shows `—`.
- The Effort column shows the epic doc's `**Effort**`, not the effort a `do all` floor raised it to.
- "Expected by" is replaced by "{span} past the typical range" once a story runs past the range's high bound (discussion 24, open question 2).
- The stored status values are unchanged (`Waiting on input` stays; the mockup's "Blocked on me" chip is not adopted), so the overview and the index read rows as now.
- Rows gain fields, so every row of an existing tracker is rewritten once at the first check after the upgrade; above eight writes this goes through the existing Haiku subagent path.
- Selection is kept in memory for the page's life; it is not stored.
- The `Bash` attribution matches the epic file's name in the command text; a write by a script that names no file is credited to no one.
- The turn-end prompt points to the pending file because, under `claude plugin test`, the mod's own `prompt.submit` hook does not run for the prompt it submits, so the context that hook attaches never arrived there, and `$.prompt.submit` takes no `context` (`cpm-next-progress/.claude-plugin/types/claude-code/index.d.ts:8356`); the engine's types say a live session runs that hook (`:2720-2721`). Pointing to the file works either way; the context is kept (user's choice, 2026-11-11).

## Challenge
**Personas**: architect, qa, ux (2026-11-11)

- architect / qa: the `typical` kept on in-progress rows is rewritten whenever an estimate moves, contradicting NFR1, and nothing tested it → Folded in: FR2, FR3, AD2 (no row carries `typical`; index uses `timingOf`), NFR1 AC
- architect: a republish runs no check and stored signatures and settled marks survive the upgrade, so the new page shows old rows and no decisions until a doc changes → Folded in: FR10, AD4 (row-schema version, check on republish), FR7 (strip falls back to `decisions`)
- architect / qa: crediting the loop whose write triggered the check misattributes when checks collide or a Bash writes nothing, and the "records none" AC can pass with no start seen → Folded in: FR1, AD1 (last writer per epic file), FR1 AC control asserting `started`
- architect: a `criteria` field on rows turns every `Evidence` line into a mid-turn write note, in subagents too → Folded in: FR11, AD5
- architect: rows would carry the raw `**Effort**` while timings normalise it → Folded in: FR2 (same normalisation)
- architect: the `turn.step` hook needs a null-usage guard, error isolation and pruning → Folded in: FR1, NFR4
- qa: a `**Model**` field on a story first seen In Progress was ignored → Folded in: FR2 (the field applies at any status)
- qa: a register test needs a fake fs and changing listings, and module state leaks between tests → Folded in: Testing Strategy
- qa: FR10's first AC passes before any change → Folded in: FR10 AC (detail panel id), zero-write control
- qa: the browser checks as worded cannot be made: no 390 px window, the template is a fragment, the stub emits once, times depend on load time, expected-by had no format → Folded in: Testing Strategy (iframe, skeleton, `__emit`, relative `started`), FR8 (`HH:MM`)
- qa: reopened stories, `Evidence` with `Not met:`, zero criteria and task rows were undefined → Folded in: FR2
- qa: FR4's AC listed instances, not the rule's forms → Folded in: FR4 (forms stated, table-driven AC with a floor)
- qa: FR3's AC proved only the count threshold → Folded in: FR3 AC (steadiness, fallback, unrounded bounds, no row `typical`)
- qa: FR11 (now FR12) was ambiguous about finished stories and had no control → Folded in: FR12 (in-progress only, control)
- qa: NFR3 had no check → Folded in: NFR3 AC
- ux: the detail panel scrolls out of view on a long tracker → Folded in: FR5 (sticky, own scroll), FR5 AC
- ux: at phone width the detail sits below the whole table and Needs you is off-screen → Folded in: FR5 (detail above, Model and Effort hidden, no min width), FR9 (focus to detail)
- ux: the page no longer says at a glance what is waiting on the reader, and the default selection preferred the running story → Folded in: FR7 (total and next control), FR9 (needs rows selected first)
- ux: the mockup's amber badge would match the amber In progress pill → Folded in: FR7 (`--wait` tokens), NFR3
- ux: dropping the Item column loses the ref that blockers and decisions use → Folded in: FR5 (# shows `{epic} {story}`)
- ux: the minute redraw destroys the focused button, and selection had no state semantics → Folded in: FR8 (not a live region), FR9 (`aria-pressed`, focus kept)
- ux: blank cells and no empty wording before timings exist; the note leaves the list → Folded in: FR5 (`—`, note excerpt), FR3 (`timed`), FR8 (empty lines)
- ux: a mid-run reader cannot tell the page is live → Rejected: a "last checked" stamp would write meta at every check (NFR1); the running time, redrawn each minute, shows the page is live — confirmed by the user (2026-11-11)
- ux: task-row decisions went to the strip while the row is in the table, and the strip had no cap → Folded in: FR4 (task prefixes match), FR7 (heading, cap of three)
