# Review: The progress tracker in split view, with model, time and what needs you — epics

**Date**: 2026-11-11  
**Source**: docs/epics/55-01-epic-rows-and-meta.md, docs/epics/55-02-epic-split-view-page.md, docs/epics/55-03-epic-release.md, docs/epics/55-04-epic-user-checks.md  
**Reviewers**: Jordan, Bella, Casey  
**Findings**: 32 (3 critical, 26 warnings, 3 suggestions)

## Summary

The epics cover every Must Have requirement and follow discussion 24. The main risks were that the mod and the page could be built against different data shapes, that several controls could not fail (a guard after `next`, a template the test fakes, a fixture with one epic file), and that the NFR1 criterion stated a fact the code contradicts. All were fixed in the epics but one: AD5 leaves a story's criteria progress stale on the page until the main loop's turn ends, which in a `do` run is the run's end; changing that changes AD5. Suggestions below are those kept; the reviewers' other suggestions were folded into the fixes or did not change what gets built.

## Findings

- **[Critical]** 🏗 **Bella** / 📋 **Jordan**: the key holding the range text in `meta.typical`, and the model's case, were never named, and 55-02 could be built in parallel with its own fixtures  
  → 55-01 header, 55-02 Story 1, Story 6: each side passes its own tests with a different shape; the first catch is the `[user]` check
- **[Critical]** 🏗 **Bella**: the control "with the try/catch removed the test fails" cannot fail: the engine keeps a request's result when a hook throws after `next`  
  → 55-01 Story 1, criterion 7
- **[Critical]** 🧪 **Casey**: the template check reads whatever the fake fs returns, so it can never fail on the old template  
  → 55-02 Story 6, criterion 1
- **[Warning]** 🏗 **Bella** / 📋 **Jordan** / 🧪 **Casey**: "one more story finishes … one write, meta" is false when the finishing story is a row of this tracker, and is not red on today's code unless the range text moves  
  → 55-01 Story 2, NFR1 criterion
- **[Warning]** 🏗 **Bella** / 📋 **Jordan**: the row-`typical` control points at the join inside `checkOne`, which a pure test never runs; `indexEntry` must take times  
  → 55-01 Story 2
- **[Warning]** 🏗 **Bella** / 📋 **Jordan** / 🧪 **Casey**: no end-to-end check that a start is credited to the loop whose Edit set it; writer map key unnamed; no different-file case; no negative cases; the skipped-check criterion is the same test as criterion 1 at the `recordTimes` level  
  → 55-01 Story 1
- **[Warning]** 🏗 **Bella** / 📋 **Jordan** / 🧪 **Casey**: `turn.step` is a streaming generator hook; a tool call may start before the step's `usage` arrives; pass-through needs chunks and errors kept  
  → 55-01 Story 1
- **[Warning]** 🧪 **Casey**: the per-loop map's drop cannot be observed, and the writer map must hold the model, not the loop id  
  → 55-01 Story 1, criterion 8
- **[Warning]** 🏗 **Bella** / 🧪 **Casey**: the SKILL.md read takes `$` and must stay in `register.ts` (older engines refuse `$` across an import); `pickInstall` scopes; Pending status variants; first seen Complete  
  → 55-01 Story 2
- **[Warning]** 🏗 **Bella** / 📋 **Jordan**: Story 3 runs in parallel with Story 2 over the same functions  
  → 55-01 Story 3 `**Blocked by**`
- **[Warning]** 🏗 **Bella**: an `unmatched` left out when every decision matches makes the page fall back to listing every decision  
  → 55-01 Story 3
- **[Warning]** 🧪 **Casey**: decision cases missing (story prefix with only a task row in the build order, a missing entry, `decisions` floor, unmatched-change writes)  
  → 55-01 Story 3
- **[Warning]** 📋 **Jordan** / 🧪 **Casey**: `xhigh` and `timed`'s value unasserted; "no `typical`" absent or `{}`  
  → 55-01 Story 2, meta criterion
- **[Warning]** 🧪 **Casey**: zero-writes criterion has no control  
  → 55-01 Story 2
- **[Warning]** 🏗 **Bella** / 🧪 **Casey**: the criteria-only drift would still toast; `nudges`/`nudgeContext` leak between tests; `nudge` runs as `void`  
  → 55-01 Story 4
- **[Warning]** 📋 **Jordan**: under AD5 a story's criteria progress stays stale on the page until the main loop's turn ends, which in a `do` run is its end  
  → 55-01 Story 4, spec AD5 and FR11
- **[Warning]** 🏗 **Bella** / 📋 **Jordan** / 🧪 **Casey**: the "after 10 timed stories" line is wrong with 10 or more timed but no steady range; the date when not today, the range in the detail, and Ready rows have no case  
  → 55-02 Story 2
- **[Warning]** 🏗 **Bella**: at 1280 px and in a 760–1100 px pane the table may scroll Needs you out of view  
  → 55-02 Story 1
- **[Warning]** 🧪 **Casey**: the 390 px checks must read the iframe's document, and need a two-digit badge  
  → 55-02 Story 1
- **[Warning]** 🏗 **Bella** / 🧪 **Casey**: blockers come in four forms, not one  
  → 55-02 Story 1
- **[Warning]** 🏗 **Bella**: "every new cell of a legacy row shows `—`" contradicts Needs you blank when 0  
  → 55-02 Story 1
- **[Warning]** 🏗 **Bella** / 📋 **Jordan** / 🧪 **Casey**: the harness's capabilities (clock, interval, separate emits, the working template, the `fillTemplate` substitution) unnamed  
  → 55-02 Story 1
- **[Warning]** 🏗 **Bella**: items arriving before meta is never tested  
  → 55-02 Story 2
- **[Warning]** 🧪 **Casey**: "no aria-live" misses implicit live regions  
  → 55-02 Story 2
- **[Warning]** 📋 **Jordan**: "{n} more" not checked as an operable control; narrow-width focus move has no control  
  → 55-02 Story 3, Story 4
- **[Warning]** 🏗 **Bella** / 🧪 **Casey**: computed colours ignore the Complete rows' opacity and the Ready pill's transparent background  
  → 55-02 Story 5
- **[Warning]** 🏗 **Bella** / 🧪 **Casey**: the republish check ignores the eight-write limit; the settled-mark criterion has no control  
  → 55-02 Story 6
- **[Warning]** 🏗 **Bella** / 📋 **Jordan** / 🧪 **Casey**: the release docs miss the upgrade's cost, old pages losing "typically", several formats in the maintenance record, two guides; the "rule stated once" lesson had no criterion  
  → 55-03 Story 1
- **[Warning]** 🏗 **Bella** / 📋 **Jordan** / 🧪 **Casey**: "the summary total is 2" fails with existing decisions and skips the check; the model check can pass on the planned model; the sticky detail is only proved in the harness  
  → 55-04 Story 1
- **[Suggestion]** 🧪 **Casey**: per-loop attribution is never checked against the real engine  
  → 55-04
- **[Suggestion]** 📋 **Jordan**: AD1 says the mod reads no other plugin's state, while FR2 now reads cpm-next's installed SKILL.md  
  → spec AD1
- **[Suggestion]** 🏗 **Bella** / 📋 **Jordan**: a read-only `Bash` naming an epic file counts as its writer  
  → 55-01 Story 1

## Remediation

- Fixed: data shape and model case → 55-01 header names the row and meta shape (lowercase `model`, `typical.{effort} = { range, low, high }`, `unmatched` and `typical` always present); 55-02 reads it; 55-02 Story 6 adds a shared `hooks/fixtures/tracker-data.ts` checked against 55-01's output and rendered by the harness
- Fixed: guard control → 55-01 Story 1: the recording is a pure function whose guard control throws when removed
- Fixed: template check → 55-02 Story 6: a `[manual]` grep of `page/tracker.html`, 0 before the epic
- Fixed: NFR1 criterion → 55-01 Story 2: the finishing story is in another spec's build order and the range text moves
- Fixed: row-`typical` control → 55-01 Story 2: the join becomes a pure function; `indexEntry` takes times
- Fixed: attribution → 55-01 Story 1: end-to-end sonnet Edit, writer before `checkAll`, basename key, different-file and negative cases, skipped check through the hooks with a control
- Fixed: streaming hook → 55-01 Story 1: `async function*` per cpm-next-models, `e.model` recorded before `next` and replaced by `usage.model`, chunks and errors pass through
- Fixed: map drop → 55-01 Story 1: pure `forgetLoop`; writer map holds models
- Fixed: SKILL.md read → 55-01 Story 2: in `register.ts`, both scopes, Pending variants, first seen Complete
- Fixed: Story 3 ordering → 55-01 Story 3 blocked by Story 2; Story 5 blocked by Story 2
- Fixed: `unmatched` empty → 55-01 Story 3
- Fixed: decision cases → 55-01 Story 3
- Fixed: `xhigh`, `timed`, `{}` → 55-01 Story 2
- Fixed: zero-writes control → 55-01 Story 2
- Fixed: toast and test isolation → 55-01 Story 4 and the epic's preamble
- Not acted on: criteria progress stale until the turn ends → the user kept AD5 (2026-11-11): status, model and time stay immediate, and criteria catch up at the turn's end
- Fixed: range-less wording and missing cases → 55-02 Story 2 (a "too spread out" line for 10 or more timed; the spec's FR8 wording covers only fewer than 10)
- Fixed: widths → 55-02 Story 1 at 1280 and 900
- Fixed: iframe document → 55-02 Story 1
- Fixed: blocker forms → 55-02 Story 1
- Fixed: legacy `—` vs blank → 55-02 Story 1
- Fixed: harness capabilities → 55-02 Story 1
- Fixed: items before meta → 55-02 Story 2
- Fixed: implicit live regions → 55-02 Story 2
- Fixed: "{n} more" and focus control → 55-02 Story 3, Story 4
- Fixed: opacity and Ready → 55-02 Story 5
- Fixed: eight-write limit and settled control → 55-02 Story 6
- Fixed: release docs → 55-03 Story 1
- Fixed: 55-04 checks → 55-04 Story 1 (rises by 2 after `/progress-tracker`, decisions removed, muted then not, `times` line, sticky detail)
- Not acted on: per-loop attribution against the real engine → the only distinguishable case, a Haiku subagent, is a `**Model**: haiku` story whose field takes precedence; recording `e.model` before `next` removes the ordering risk
- Not acted on: AD1 wording → reading an installed file is not plugin state; the release's maintenance record lists the dependency
- Not acted on: read-only `Bash` as writer → a reader is credited only when a start appears in that file before any real write, which `do` does not do; recorded for the build
