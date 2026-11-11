# The split-view tracker page

**Source spec**: docs/specifications/55-spec-tracker-split-view.md  
**Date**: 2026-11-11  
**Status**: Complete  
**Blocked by**: —  
**Amended**: review 12 (docs/reviews/12-review-tracker-split-view.md) — the data shape taken from 55-01's header and a check that the mod's output renders (Story 6); the harness's capabilities named; widths 1280 and 900; the iframe's document for 390 px; every blocker form; Ready in the Time rule; the date when not today; the steady-range and untimed cases; items before meta; implicit live regions; the "{n} more" control; the narrow-width focus control; opacity and the Ready pill in the contrast check; Story 6's template check moved to a grep, the eight-write limit and the settled control (2026-11-11)  
**Lessons**: docs/library/01-library-lessons-learned.md → "Ask the runtime the question rather than modelling its answer" (Story 1), docs/library/01-library-lessons-learned.md → "Ask the runtime the question rather than modelling its answer" (Story 5), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 5), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 2), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 4), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (build)

All page work is in `cpm-next-progress/page/tracker.html`. Stories 1–5 edit that one file, so they run in order. The rows and meta the page reads have the shape given in the header of `docs/epics/55-01-epic-rows-and-meta.md`; the page capitalises `model` for display. `[browser]` criteria are checked with claude-in-chrome on the harness Story 1 builds, as the spec's Testing Strategy describes; positions come from `getBoundingClientRect` and colours from `getComputedStyle`, read through `javascript_tool`, not from screenshots; key presses are real ones (the computer tool), not synthetic events.

## Harness and the split layout
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR5  
**Test run**: 3 (1 full, 2 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 148 passed, 0 failed — tree 7174c8e4a02001b92df4fc6f9bbb7a2165c3e447 — untested: cpm-next-progress/page/tracker.html (read by `register.ts` `prepare` and written out; no test runs it); wide reach: cpm-next-progress/hooks/fixtures/tracker-harness.html (fixtures) — cpm-next-progress/page/tracker.html → deferred full run; cpm-next-progress/hooks/fixtures/tracker-harness.html → deferred full run  
**Audit**: pass (2026-11-11), 2 findings fixed  
**Signal**: instance-not-rule — project — the layout was checked at the three named widths only and left Title 34 px wide at 760 px, and the blocker rule read every `Epic …` token as a resolved epic (cpm-next-progress/page/tracker.html, 55-02 S1 audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (a rule written for the cases in view and stopping short of what FR5 covers)

**Acceptance Criteria**:

- `cpm-next-progress/hooks/fixtures/tracker-harness.html` loads `page/tracker.html` from the working tree on each load (fetched, not copied), fills its `{{…}}` placeholders as `fillTemplate` does (the substitution repeated in the harness, since `fillTemplate` is TypeScript), and writes it with the skeleton a publish adds into an iframe document (`srcdoc` or `document.write`) whose width the harness sets (1280, 900, 390). Before the page script runs it stubs `Date.now` (settable), captures the page's `setInterval` callback (fired on demand), and stubs `window.claude.use("db")` keeping each `onSnapshot` callback, exposing `__emitItems(items)`, `__emitMeta(meta)` and `__emit(items, meta)`. Its fixtures: 5 rows, 60 rows across three phases, legacy rows without the new fields, zero rows, a null meta, a meta without `typical` or `unmatched`, and no `window.claude`; it is served from the repository root by `python3 -m http.server`, is not published, and `grep -n tracker-harness cpm-next-progress/hooks/*.ts` gives no hit `[manual]`
  - Evidence: `cpm-next-progress/hooks/fixtures/tracker-harness.html` fetches `/cpm-next-progress/page/tracker.html` with `cache: "no-store"` on each load (:244), fills the three placeholders with escaping as `fillTemplate` does (:41-43), writes the page with the publish skeleton into an iframe by `srcdoc` sized by `?w=`; in the iframe `__setNow`, `__getNow`, `__tick`, `__emitItems`, `__emitMeta` and `__emit` are functions and `Date.now() === __getNow()`; fixtures `five`, `sixty`, `legacy`, `zero`, `nullmeta`, `nometa-fields`, `noclaude` load; served by `python3 -m http.server 8755 --bind 127.0.0.1` from the repo root; `grep -n tracker-harness cpm-next-progress/hooks/*.ts` exits 1 with no hit — red: n/a — manual
- At 1280 px the table shows the headings #, Title, Status, Model, Effort, Time, Needs you in that order, the # cell holds `{epic} {story}` (e.g. `01-05 S2`), rows follow `seq`, and phase rows group them as today `[browser]`
  - Evidence: http://127.0.0.1:8755/cpm-next-progress/hooks/fixtures/tracker-harness.html?w=1280&f=five, read in the iframe: headings `#, Title, Status, Model, Effort, Time, Needs you`; # cells `55-01 S1, 55-01 S2, 55-02 S1, 55-02 T2.1, 55-02 S3`; two phase rows (`Phase 1 · 55-01 Rows and meta`, `Phase 2 · 55-02 The split-view tracker page`); `f=sixty`, emitted in reverse order, renders `60-01 S1 … 60-03 S20` ascending under three phase rows — red: n/a — browser-observed
- At 1280 px and at 900 px the detail's box is to the right of the table's and every row's Needs you cell lies inside the table's visible box; with the 60-row fixture scrolled to the last row, selecting it leaves the detail's box inside the viewport `[browser]`
  - Evidence: `f=sixty` at `w=1280`: detail left 939.5 ≥ table right 915.5 (five-row) and detail right of table, every Needs you cell inside the table box; last row `60-03 S20` scrolled into view and its button clicked: scrollY 3554, detail box top 16, inside the viewport, heading `60-03 S20 Story number 60`. At `w=900`: detail right of table, Needs you cells inside, column widths 76/174/108/66/66/84/56, `scrollWidth` 900; last row selected at scrollY 4303, detail top 16, bottom 158, inside the viewport; after the round-1 fix, with the iframe set to each width over `f=sixty`, the detail is to the right of the table from 760 px up and above it below, `scrollWidth <= clientWidth` and every Needs you cell inside the table box at 320, 360, 390, 759, 760, 790, 820, 899, 900, 1000, 1099, 1100 and 1280 px, and the Title column is at least 160 px at every width from 760 up (166 at 760, 174 at 900, 160 at 1100), where it was 34 px at 760 before the fix (audit round 1); Model and Effort are hidden below 900 px — red: n/a — browser-observed
- At 390 px, read inside the iframe's document: the detail's box is above the table's, `scrollWidth <= clientWidth`, Model and Effort are hidden from the table, and every row's Needs you cell, including a row with a two-digit badge, lies inside the table's visible box with the badge's own box inside it `[browser]`
  - Evidence: `f=sixty&w=390`, read in the iframe's document: detail bottom ≤ table top; `scrollWidth` 390 = `clientWidth` 390; `th.c-model` and `td.c-effort` `display: none`; no row's Needs you cell or badge outside the table box (the row `60-02 S18` badge reads `12`); title column 116 px — red: n/a — browser-observed
- Blockers show under the status, one per item, in the form each comes in: a story or task of this tracker as `after {ref}` in the # column's form (`after 01-05 S2`, `after 01-05 T3.1`), an epic as `after Epic 01-03`, and free `waitingOn` text or an unresolved token as `waiting on {text}`; a fixture holds each kind `[browser]`
  - Evidence: `f=five&w=1280`: `55-02 S1` blockers `after 55-01 S2`, `after Epic 01-03`; `55-02 T2.1` `after 55-02 T1.2`; `55-02 S3` `waiting on Chris to approve the <b>mockup</b>` (shown as text), each a separate `li` under the status pill; unresolved tokens `Epic 99-99-epic-gone` and `epic 99-98` (a full id and a lowercase token, as `outstanding()` passes an epic it cannot find) show as `waiting on Epic 99-99-epic-gone` and `waiting on epic 99-98`, where before the round-1 fix the first showed `after Epic 99-99-epic-gone` (audit round 1) — red: n/a — browser-observed
- A row with a note shows its first line, muted and cut with an ellipsis, under its title; empty cells show `—`, including the new cells of a legacy row, except Needs you, which is blank when 0; a row with `modelPlanned: true` shows its model in the muted colour and one without in the body colour; `model` shows capitalised (`opus` → `Opus`) `[browser]`
  - Evidence: `f=five&w=1280`: note lines `Runs on Sonnet` and `A note holding <i>markup</i> shows as text, …` with `text-overflow: ellipsis`, `white-space: nowrap`, colour rgb(93, 107, 100) (`--muted`); Model cells `Opus`, `Sonnet`, `Opus` (planned, class `planned`, rgb(93, 107, 100)), `—`, `Haiku`, the others rgb(29, 38, 34) (body); task row Model/Effort/Time `—`, Needs you blank where 0, `2` where two; `f=legacy`: every row's Model and Effort `—`, Time `—` but for the In progress row that has `started` (`30 min in`), Needs you blank — red: n/a — browser-observed
- The zero-row fixture shows the empty-table message across all seven columns and an empty detail ("No rows yet"); with no `window.claude` the unavailable message spans all seven columns `[browser]`
  - Evidence: `f=zero`: `td.empty` "No items yet. Claude adds the build order here." with `colSpan` 7, detail heading "No rows yet"; `f=noclaude` (`'claude' in window` false): `td.empty` "Progress data is not available in this view. Sign in to claude.ai to see it." with `colSpan` 7 — red: n/a — browser-observed

### Harness
**Task**: 1.1  
**Description**: The local harness and its fixtures.  
**Status**: Complete

### Layout
**Task**: 1.2  
**Description**: Table columns, sticky detail, narrow layout, blockers and empty cells.  
**Status**: Complete

---

## Time column and detail panel
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR6, FR8  
**Test run**: 2 (1 full, 1 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 158 passed, 0 failed — tree 6874a3b20d9777a7c3f229257d49ac1841e24601 — untested: cpm-next-progress/page/tracker.html; wide reach: cpm-next-progress/hooks/fixtures/tracker-harness.html (fixtures) — cpm-next-progress/page/tracker.html → deferred full run; cpm-next-progress/hooks/fixtures/tracker-harness.html → deferred full run  
**Audit**: pass (2026-11-11)  
**Amended**: the Needs you total's redraw on a late meta is checked with Story 3, which builds the total; this story checks the Time cells and the detail (2026-11-11) — cited: 55-02 Story 3, second criterion (the summary's total of `needs` plus `unmatched`)  
**Signal**: spec-drift — project — a criterion asked Story 2 to check the redraw of the Needs you total, which Story 3 builds (docs/epics/55-02-epic-split-view-page.md Story 2, last criterion) — recurs: docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (a criterion that cannot hold with a sibling story's criteria)

**Acceptance Criteria**:

- The Time cell reads `took {span}` for a Complete row with `took`; `{span} in` plus `typically {range}` for a timed In progress row whose effort `meta.typical` holds, and `{span} in` alone when it does not; `typically {range}` for a Pending, a Ready and a Waiting on input row whose effort `meta.typical` holds; `—` otherwise, including an untimed In progress row and every row when meta is null; checked for each shown status with and without the range `[browser]`
  - Evidence: `f=times` (harness, `w=1280`), meta `typical` holding medium only: Complete with took `took 1 h 20 min`, Complete untimed `—`; In progress medium `20 min in · typically 15–45 min`, In progress high `20 min in`, untimed In progress `—`; Pending medium `typically 15–45 min`, Pending high `—`; Ready medium `typically 15–45 min`, Ready low `—`; Waiting on input medium `typically 15–45 min`, xhigh `—`; `f=times-nullmeta`: every Time cell `—` — red: n/a — browser-observed
- The detail shows the selected row's ref, title, model and effort; for an in-progress story with `started` 20 min before the stubbed now and a 15–45 min range, started and expected-by as local `HH:MM` (expected-by from start plus each bound), the running time and the typical range; with `started` 60 min before, `15 min past the typical range` in place of expected-by; with `started` the previous day, started shows the date before `HH:MM` `[browser]`
  - Evidence: `f=times` (harness, `w=1280`), stubbed now 12:51: `70-01 S3` (medium, started 20 min before, range 15–45): `#detail-model` Sonnet, `#detail-effort` medium, `#detail-started` `12:31`, `#detail-expected` `12:46–13:16`, `#detail-running` `20 min in`, `#detail-typical` `15–45 min`, heading `70-01 S3` and title; `70-01 S5` (started 60 min before): `#detail-past` `15 min past the typical range` and no `#detail-expected`; `70-01 S6` (started the previous day): `#detail-started` `2026-11-10 12:51` — red: n/a — browser-observed
- The detail shows `took` for a timed Complete row and `not timed` for an untimed one, the row's blockers, its full note, its needs items with their kind or `Nothing needs you`, and `{met} of {total} met` or `No criteria` `[browser]`
  - Evidence: `f=times` (harness, `w=1280`): `70-01 S1` `#detail-took` `took 1 h 20 min`, `70-01 S2` `not timed`; `70-02 S1` blockers `after 70-01 S3`, `after Epic 01-03`, `waiting on legal sign-off`, `#detail-note` the three-line note with `<b>markup</b>` as text, needs `review` / `Walk through the detail at 390 px` and `input` / `Pick a <i>date</i>` (kind in `span.needs-kind`), `#detail-criteria` `2 of 5 met`; `70-02 S2` `Nothing needs you`, `No criteria` — red: n/a — browser-observed
- With no range for the row's effort, the detail reads `Typical range: after 10 timed stories ({timed} so far)` when `meta.timed` is under 10, and `Typical range: too spread out to predict ({timed} timed)` when it is 10 or more `[browser]`
  - Evidence: `f=times-untimed` (`timed` 4, no `typical`): `70-01 S3` `#detail-typical` `after 10 timed stories (4 so far)` (label `Typical range`), no expected-by; `f=times-spread` (`timed` 12, `typical` `{}`): `too spread out to predict (12 timed)` — red: n/a — browser-observed
- Neither the detail nor any element inside it has `aria-live`, or a role or element that is live by default (`status`, `log`, `alert`, `timer`, `marquee`, `<output>`); the detail is a region labelled by its heading `[browser]`
  - Evidence: `f=times` (harness, `w=1280`): `#detail` is a `SECTION` with `aria-labelledby="detail-heading"` and no `role`; elements in it with `aria-live`, a role of status, log, alert, timer or marquee, or tag `OUTPUT`: 0 — red: n/a — browser-observed
- After the harness moves `Date.now` on by 2 min and fires the captured interval, the Time cell and the detail's running time show 2 more minutes `[browser]`
  - Evidence: `f=times` (harness, `w=1280`), `70-01 S3` selected: before `20 min in · typically 15–45 min` / `#detail-running` `20 min in`; after `__setNow(+2 min)` and `__tick()`: `22 min in · typically 15–45 min` / `22 min in` — red: n/a — browser-observed
- Items emitted first and meta emitted later: on the meta's arrival the Time cells, the detail and the Needs you total redraw from it `[browser]`
  - Evidence: `f=times&emit=0`, `__emitItems(items)` then `__emitMeta(meta)`: before the meta the first Time cells read `—, —, —, —` and the detail had no `#detail-typical`; after it `took 1 h 20 min, —, 20 min in · typically 15–45 min, 20 min in` and `#detail-typical` `15–45 min`; the Needs you total is checked under Story 3 (see **Amended**) — red: n/a — browser-observed

### Time and detail
**Task**: 2.1  
**Description**: Time column text and the detail panel fields.  
**Status**: Complete

---

## Needs you: badge, total and strip
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR7  
**Test run**: 2 (1 full, 1 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 165 passed, 0 failed — tree fd12658392578ce2d23369caa98d0ec53dfb2efe — untested: cpm-next-progress/page/tracker.html; wide reach: cpm-next-progress/hooks/fixtures/tracker-harness.html (fixtures) — cpm-next-progress/page/tracker.html → deferred full run; cpm-next-progress/hooks/fixtures/tracker-harness.html → deferred full run  
**Audit**: pass (2026-11-11)  
**Amended**: the second criterion also checks that the total redraws on a late meta, moved from Story 2 (2026-11-11) — cited: 55-02 Story 2, last criterion

**Acceptance Criteria**:

- A row with two needs items shows a badge reading `2`; a row with none shows no badge `[browser]`
  - Evidence: `f=needs` (harness, `w=1280`): `80-01 S2` (two needs items) badge `2`; `80-01 S1` and `80-01 S3` (none) no `.needs-badge`; `80-01 S4` `1`, `80-01 T6.1` `3` — red: n/a — browser-observed
- The summary gives the total of all rows' needs items plus `unmatched` (plus `decisions` under the legacy fallback); its control is a button that selects the next row with needs items in table order and wraps from the last to the first; when only `unmatched` holds items, the control is absent; with items emitted first and meta later, the total redraws on the meta's arrival `[browser]`
  - Evidence: `f=needs` (harness, `w=1280`): `#needs-total-text` `10 need you` (6 row needs + 4 unmatched); `#needs-next` is a BUTTON, clicked four times from `80-01 S2`: `80-01 S4`, `80-01 T6.1`, `80-01 S2`, `80-01 S4` (wraps); `f=needs-unmatched-only`: `2 need you`, `#needs-next` hidden, no badges; `f=needs-legacy` (meta without `unmatched`): `8 need you`; items emitted with a null meta: `6 need you`, then `__emitMeta(meta)`: `10 need you` — red: n/a — browser-observed
- The strip is headed "Not matched to a row" and shows each `unmatched` decision whole, as text (a decision holding `<b>` shows the characters); with 3 decisions it shows all three and no "more"; with 4 it shows three and a "1 more" button that, pressed by mouse or by Enter, shows the fourth; it is hidden after `__emitMeta` with an empty `unmatched` `[browser]`
  - Evidence: `f=needs` (harness, `w=1280`): `#unmatched` heading `Not matched to a row`, items written as text (`Choose between <b>bold</b> and plain wording` with no child element), three shown and the fourth `hidden`, `#unmatched-more` a BUTTON reading `1 more`; a real mouse click on it, and on a fresh load a real Enter with it focused, each showed all four and hid the button; `f=needs-3`: three items, no more button; `__emitMeta` with `unmatched: []`: `#unmatched` hidden — red: n/a — browser-observed
- With a meta that has `decisions` and no `unmatched`, the strip lists `decisions` `[browser]`
  - Evidence: `f=needs-legacy` (meta keys title, spec, updated, decisions, timed, typical; no `unmatched`): the strip lists both `decisions`, `[80-01 S2, review] Walk …` and `Legacy <b>decision</b> …` as text — red: n/a — browser-observed
- The badge's and strip's computed colours equal the Waiting on input pill's (`--wait` / `--wait-bg`) `[browser]`
  - Evidence: `f=needs` (harness, `w=1280`): badge, strip and a `pill s-waiting` each compute color rgb(107, 79, 163) on background rgb(238, 232, 248); with `data-theme="dark"` each rgb(185, 162, 234) on rgb(44, 36, 64) — red: n/a — browser-observed

### Needs you
**Task**: 3.1  
**Description**: Badge, summary total and next control, unmatched strip.  
**Status**: Complete

---

## Selection and focus
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 3  
**Satisfies**: FR9  
**Test run**: 2 (1 full, 1 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 168 passed, 0 failed — tree e94abd8db96c5617db8c2964bd318badc3137b47 — untested: cpm-next-progress/page/tracker.html; wide reach: cpm-next-progress/hooks/fixtures/tracker-harness.html (fixtures) — cpm-next-progress/page/tracker.html → deferred full run; cpm-next-progress/hooks/fixtures/tracker-harness.html → deferred full run  
**Audit**: pass (2026-11-11)

**Acceptance Criteria**:

- The default selection follows each step of the rule, one fixture per step: a needs row, else an In progress row, else the first row not Complete, else the first row; control: with both a needs row and an earlier In progress row, the needs row is selected `[browser]`
  - Evidence: harness `w=1180`, fixtures emitted in turn: `f=sel-needs` (S2 In progress before S4 Waiting on input with needs) selects `90-01 S4` (the control); `f=sel-progress` (S2 Pending, S3 and S4 In progress) selects `90-02 S3`; `f=sel-open` (only S3 not Complete) selects `90-03 S3`; `f=sel-complete` (all Complete) selects `90-04 S1` — red: n/a — browser-observed
- A selection survives an `__emitItems` that changes another row, and falls to the rule when an `__emitItems` removes the selected row `[browser]`
  - Evidence: `f=sel-needs`: `90-01 S3` clicked; `__emitItems` with S5 retitled and set In progress keeps `90-01 S3`; `__emitItems` without S3 selects `90-01 S4` by the rule — red: n/a — browser-observed
- Each row's title is a button; Tab to one then Enter selects its row, as does Space; the selected button has `aria-pressed="true"` and the others `false` `[browser]`
  - Evidence: `f=sel-needs` `w=1180`, with focus on `90-01 S1`'s button, a real Tab then Enter: focus and selection `90-01 S2`, `aria-pressed` S2 `true` and S1, S3, S4, S5 `false`; a real Tab then Space: selection `90-01 S3`, only S3 `true` — red: n/a — browser-observed
- With focus on a row's button, the fired interval and an `__emitItems` that changes another row leave `document.activeElement` on the same row's button `[browser]`
  - Evidence: `f=sel-needs`, focus on `90-01 S3`'s button: after `__setNow(+2 min)` and `__tick()` the old button is detached and focus is on the new `90-01 S3` button; after an `__emitItems` that retitles S1 (`S1 changed`) focus is still on `90-01 S3` — red: n/a — browser-observed
- At 390 px, selecting a row by click or key moves focus to the detail's heading; control: the default selection on load, an `__emitItems` and the fired interval do not move focus `[browser]`
  - Evidence: `f=sel-needs` `w=390` (`matchMedia('(max-width: 759.98px)')` true): on load, after `__emitItems` and after `__tick()` focus stays on BODY (control); a real click on `90-01 S2`'s button selects it and focuses `#detail-heading`; Enter on `90-01 S5`'s button selects it and focuses `#detail-heading` — red: n/a — browser-observed

### Selection
**Task**: 4.1  
**Description**: Selection rule, keyboard access, focus kept across redraws.  
**Status**: Complete

---

## Contrast in both themes
**Story**: 5  
**Status**: Complete  
**Blocked by**: Story 4  
**Satisfies**: NFR3  
**Test run**: 3 (1 full, 2 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 175 passed, 0 failed — tree 50a8865c2d0c20865fb323812da08a67f42cf3ce — closes epic; untested: cpm-next-progress/page/tracker.html — cpm-next-progress/page/tracker.html → deferred full run  
**Audit**: pass (2026-11-11), 1 finding fixed  
**Signal**: fix-not-carried-through — project — the contrast fix muted every cell of a Complete row, the Model cell included, and so broke Story 1's criterion that an observed model shows in the body colour (cpm-next-progress/page/tracker.html:90, 55-02 S5 audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (a change checked against its own criteria and not the sibling criteria that read the same cells)

**Acceptance Criteria**:

- With `data-theme` light and then dark, a contrast calculation in `javascript_tool` gives at least 4.5:1 for the badge, the strip, muted text, the Time cell, the Model cell and the Complete, In progress, Pending, Ready and Waiting on input pills; it composites each colour with the opacity of the element and its ancestors over the background actually behind it (the surface, for the Ready pill's transparent background, and for cells of a dimmed Complete row) `[browser]`
  - Evidence: http://127.0.0.1:8755/cpm-next-progress/hooks/fixtures/tracker-harness.html?w=1180&f=times and `f=five`, a WCAG ratio computed in `javascript_tool` for every visible element of each group with each row selected in turn, each colour composited through the opacity and backgrounds of the element and its ancestors over the body background (the Ready pill's transparent background resolving to the surface or the selected row's `--bg` behind it); the lowest ratio per group, light / dark: badge 5.36 / 6.57, strip 5.36 / 6.57, muted text (note lines, blockers, detail labels) 5.21 / 6.55, Time cell 5.21 / 6.55, Model cell 5.21 / 6.55, Complete pill 4.97 / 7.35, In progress 4.97 / 6.96, Pending 5.46 / 6.52, Ready 5.36 / 8.81, Waiting on input 5.36 / 6.57; before the change the builder measured the light Complete pill at 4.36, In progress at 4.42 and a dimmed Complete row's Time cell at 2.58; after the round-1 fix a Complete row mutes every cell but its status and Model (`55-01 S1` Model rgb(29, 38, 34), title rgb(93, 107, 100)), so Story 1's body-colour Model criterion holds — red: n/a — browser-observed
- In both themes the badge's colour pair differs from each of the Complete, In progress, Pending and Ready pills' `[browser]`
  - Evidence: `f=times`, light: badge rgb(107, 79, 163) / rgb(238, 232, 248), differing from the Complete, In progress, Pending and Ready pills' pairs and equal to Waiting on input's; dark: rgb(185, 162, 234) / rgb(44, 36, 64), the same comparisons — red: n/a — browser-observed
- Colours are tokens on `:root` with the dark overrides under `@media (prefers-color-scheme: dark)` guarded by `:root:not([data-theme="light"])` and under `:root[data-theme="dark"]`, and `body` sets its background: read in the file `[manual]`
  - Evidence: cpm-next-progress/page/tracker.html:6 `:root {` tokens, :25-26 `@media (prefers-color-scheme: dark)` with `:root:not([data-theme="light"])`, :32 `:root[data-theme="dark"]`, :37 `body { background: var(--bg); … }`; the change alters two light tokens (`--ok`, `--work`) and replaces the Complete row's `opacity: .62` with `color: var(--muted)`, adding no token — red: n/a — static

### Contrast
**Task**: 5.1  
**Description**: Check and fix colour pairs in both themes.  
**Status**: Complete

---

## Existing trackers reach the new page and rows
**Story**: 6  
**Status**: Complete  
**Blocked by**: Story 1, Epic 55-01-epic-rows-and-meta  
**Satisfies**: FR10, FR5  
**Effort**: high  
**Test run**: 2 (1 full, 1 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 175 passed, 0 failed — tree 50a8865c2d0c20865fb323812da08a67f42cf3ce — closes epic; wide reach: cpm-next-progress/hooks/register.ts (boot-time registration); wide reach: cpm-next-progress/hooks/fixtures/tracker-epics.ts, tracker-data.ts, tracker-harness.html (fixtures) — cpm-next-progress/hooks/progress.ts → hooks/progress.test.ts, hooks/timing.test.ts, hooks/waiting.test.ts, hooks/testrun.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/progress.test.ts, register.test.ts → themselves; cpm-next-progress/hooks/register.ts and the fixtures → deferred full run  
**Audit**: pass (2026-11-11)  
**Inline change**: the last criterion's 5-row fixture is the harness's `f=data`, read from `tracker-data.ts`, beside Story 1's hand-written `f=five`, whose rows Stories 1–4's evidence cites (2026-11-11)  
**Signal**: spec-drift — project — the last criterion named the harness's 5-row fixture as the one read from `tracker-data.ts`, while Stories 1–4's evidence cites that fixture's hand-written rows (docs/epics/55-02-epic-split-view-page.md Story 6) — recurs: docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (a criterion that cannot hold with sibling stories' evidence)

**Acceptance Criteria**:

- `grep -c 'id="detail"'` (or the detail panel's id as built) over `cpm-next-progress/page/tracker.html` gives 1, and 0 at the commit before this epic `[manual]`
  - Evidence: `grep -c 'id="detail"' cpm-next-progress/page/tracker.html` gives 1; `git show 0a4e609:cpm-next-progress/page/tracker.html | grep -c 'id="detail"'` gives 0 — red: n/a — static
- A row-schema version constant joins the `checked:` signature and the `settled:` mark: a store holding marks written without it makes the next `ifChanged` check read every tracker, a settled one included; control: marks written with the current version leave the settled tracker unread `[unit]`
  - Evidence: "marks stored without the row-schema version make the next check read every tracker, a settled one included", cpm-next-progress/hooks/register.test.ts:448; "control: marks stored with the current row-schema version leave the settled tracker unread", :459 — red: expected > 0, received 0 ArtifactData reads with mutation of cpm-next-progress/hooks/progress.ts:620, 623: the row-schema version dropped from `checkSignature` and `settledMark`; control expected 0, received 2 with mutation of cpm-next-progress/hooks/register.ts:172: the settled mark ignored
- After a republish of an existing tracker (the `Artifact` hook with a page file whose build order has an `artifact`), over unchanged docs whose 6 live rows lack the new fields, the hook's result carries the writes inline with `if_version`; with 12 such rows it carries the subagent instruction and the pending file holds the writes; control: live rows and meta already holding every new field give no writes and no note `[unit]`
  - Evidence: "a republish over unchanged docs hands over the writes for rows that lack the new fields: inline for 6 rows", cpm-next-progress/hooks/register.test.ts:482 (7 writes, each with `if_version`); "a republish with 12 such rows hands the writes to a subagent through the pending file", :495 (13 writes in the pending file); "control: a republish over rows and meta that already hold every new field gives no writes and no note", :506 — red: expected `/Writes: \[/` and `/Start a subagent/`, received `""` with mutation of cpm-next-progress/hooks/register.ts:495-499: the existing-artifact branch back to `return null`; control expected `[]`, received `["republished"]` with mutation of cpm-next-progress/hooks/register.ts:498: `: null` → `: 'republished'`
- `prepare`'s message for an existing tracker no longer says its rows are untouched, and says the rows are brought up to date after the republish `[unit]`
  - Evidence: "preparing an existing tracker says its rows are brought up to date after the republish", cpm-next-progress/hooks/register.test.ts:516 — red: expected `/rows are brought up to date once it is republished/`, received the old message with mutation of cpm-next-progress/hooks/register.ts:412: the sentence removed
- `hooks/fixtures/tracker-data.ts` exports one object literal of rows and meta written as plain JSON; a test in `progress.test.ts` asserts it deep-equals the rows and meta 55-01's code builds from the fixture epics beside it, `[unit]`
  - Evidence: "the data the page harness renders is the rows and meta the mod builds from the fixture epics", cpm-next-progress/hooks/progress.test.ts:689, over cpm-next-progress/hooks/fixtures/tracker-epics.ts and cpm-next-progress/hooks/fixtures/tracker-data.ts — red: deep-equal failed at `took`, expected 38, received 39 with mutation of cpm-next-progress/hooks/progress.ts:314: `took` + 1
- The harness reads `hooks/fixtures/tracker-data.ts` (stripping the `export` line) for its 5-row fixture, and every row renders with its Model, Effort and Time cells filled from it `[browser]`
  - Evidence: http://127.0.0.1:8755/cpm-next-progress/hooks/fixtures/tracker-harness.html?w=1280&f=data (rows and meta read from `tracker-data.ts`): `55-01 S1` Opus / high / `took 38 min`; `55-01 S2` Sonnet / medium / `3 h 49 min in · typically 27–40 min`; `55-01 S3` Opus (class `planned`) / medium / `typically 27–40 min`; `55-01 S4` Opus (planned) / low / `typically 28–40 min`, Needs you `1`; `55-01 T4.1` Opus (planned) / low / `typically 28–40 min` — red: n/a — browser-observed

### Migration
**Task**: 6.1  
**Description**: Row-schema version in the marks; a check on republish; the shared data fixture.  
**Status**: Complete

---
