# Stories waiting on the user, everywhere

**Source spec**: docs/specifications/49-spec-cheaper-red-first-evidence.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: —  
**Lessons**: docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 2), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 3), docs/library/02-library-planning-time-lessons.md → "Read what iterates a set before adding a member to it" (Story 3)

## The marker line, the criterion grammar and the shared fixtures
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 2 findings fixed  
**Blocked by**: —  
**Satisfies**: FR9  
**Inline change**: criterion 4 names the fixture files as the modules `fixtures/waiting.ts` in each mod, with the verdicts as `EXPECTED` in the module, in place of directories `fixtures/waiting/` holding a file per story (2026-10-31)  
**Signal**: spec-drift — project — the criterion named fixture directories where the files written are one module per mod (docs/epics/49-04-epic-waiting-on-user.md, Story 1, audit round 1)  
**Signal**: fix-not-carried-through — project — the waiting rule gained the `Waiting on user:` line but the same bullet's sentence about reporting steps still named only `[user]` criteria (`cpm-next/skills/status/SKILL.md:21`, audit round 1) — promoted 2026-10-31

**Acceptance Criteria**:

- The contract defines the indented `- Waiting on user: {steps}` line under a criterion, and states the criterion grammar: a criterion is a `- ` line under `**Acceptance Criteria**:`, continued on indented lines that are not sub-bullets; its tag is the last backticked word in it; its indented `- Evidence`, `- Evidence (user, …)`, `- Not met:` and `- Waiting on user:` lines belong to it; a legacy story-level `**Evidence**:` field counts as evidence for every criterion `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:145` shows the `- Waiting on user: {the steps the user carries out}` line in the evidence block, `:152` defines it, and `:154` states the grammar once — a criterion is a `- ` line under `**Acceptance Criteria**:` continued on indented non-sub-bullet lines, its tag the last backticked word, its indented `Evidence`, `Evidence (user, …)`, `Not met:` and `Waiting on user:` lines belong to it, a legacy story-level `**Evidence**:` field counts for every criterion — red: n/a — manual
- `do` step 3 writes the line when it treats a criterion not tagged `[user]` as `[user]`, and removes it when it writes that criterion's `Evidence` line `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:47` (the `[browser]` fallback) and `:48` (`[user]`, and a criterion not tagged `[user]`) say `do` writes an indented `- Waiting on user: {steps}` line under the criterion, and `:48` that it removes the line when it writes the criterion's `Evidence` line — red: n/a — manual
- `status` counts a criterion with a `- Waiting on user:` line as one only the user can prove, in its rule for stories waiting on a user check `[manual]`
  - Evidence: `cpm-next/skills/status/SKILL.md:21` now reads "every criterion without `Evidence` is tagged `[user]` or has an indented `- Waiting on user:` line" in its rule for stories waiting on a user check, and reports the steps of each criterion without `Evidence` (the text of its `- Waiting on user:` line where it has one) — red: n/a — manual
- One fixture set of two-story epics, with an `EXPECTED` verdict per story in the module, covers each case of FR10 (a waiting `Pending` story, a waiting `In Progress` story, and each control), and is written byte for byte as `cpm-next-progress/hooks/fixtures/waiting.ts` and `whats-next/hooks/fixtures/waiting.ts`; `cmp` reports the two copies identical `[manual]`
  - Evidence: `cpm-next-progress/hooks/fixtures/waiting.ts` (its stories now carry a `### Task` section and trailing line breaks like real docs) holds ten two-story epics (including `09-01-epic-old` listed in `ARCHIVED`) and `EXPECTED`, a verdict for each of 20 stories: waiting `Pending` (`20-01#1`) and `In Progress` (`20-01#2`), and controls — story blocker not Complete (`21-01#2`), epic blocker not Complete (`22-01#1`, `#2`), archived-Complete blocker (`23-01#1`, true), blocked note (`24-01#1`), Not met line (`25-01#1`), untagged criterion without Evidence (`26-01#1`) against a `Waiting on user` line standing in for the tag (`26-01#2`, true), every criterion evidenced (`27-01#1`) and the legacy field (`27-01#2`), a dependent of a waiting story (`28-01#2`); `cmp cpm-next-progress/hooks/fixtures/waiting.ts whats-next/hooks/fixtures/waiting.ts` printed nothing (identical); `tsc` over both fixtures directories printed no errors — red: n/a — manual

### Edit the contract, do and status; write the fixtures
**Task**: 1.1  
**Description**: Amend `artifacts.md`, `do/SKILL.md` step 3 and `status/SKILL.md`; write the fixture set into both mods.  
**Status**: Complete

---

## cpm-next-progress shows Waiting on input
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-31), 3 findings fixed
**Blocked by**: Story 1  
**Satisfies**: FR10  
**Inline change**: criterion 4 says what "story timing is unchanged" means: timings are still recorded as before, and a story shown as waiting is not shown in progress, so it has no running time and is not in the overview's in-progress list (2026-10-31)  
**Signal**: spec-drift — project — the criterion said story timing was unchanged where a waiting story's displayed running time and in-progress listing change by design (`cpm-next-progress/hooks/register.ts:158`, `progress.ts:570`, audit round 1)  
**Signal**: check-cannot-fail — project — several rules and tests had no recorded red (the empty-criteria guard, the parser test, the no-criteria test) (`cpm-next-progress/hooks/waiting.test.ts`, audit round 1)

**Acceptance Criteria**:

- A story is shown `Waiting on input` when every story and epic its own and its epic's `**Blocked by**` name is `Complete`, its `**Status**` carries no ` — blocked:` note, no criterion has a `- Not met:` line, at least one criterion lacks `Evidence`, and every such criterion is tagged `[user]` or has a `- Waiting on user:` line, whether its status is `Pending` or `In Progress`; tests read the shared fixtures `[unit]`
  - Evidence: every fixture story is Waiting on input exactly when the contract says it waits (`cpm-next-progress/hooks/waiting.test.ts:20`, `claude plugin test cpm-next-progress`; reads `fixtures/waiting.ts`), and a waiting story shows so whether Pending or In Progress (`:30`) — red: Expected: ["20-01#2", true], Received: ["20-01#2", false] with mutation of `progress.ts` `trackerStatus`: the `In Progress` line placed before the waiting line; and Expected: ["26-01#2", true], Received: ["26-01#2", false] with mutation of `isWaitingOnUser`: `unproven.every(c => c.tag === 'user' || c.hasWaitingLine)` → `unproven.every(c => c.tag === 'user')`
- Controls, each leaving the story not `Waiting on input`: a story blocker not `Complete`; the epic's own `**Blocked by**` not `Complete`; a ` — blocked:` note; a `Not met` line; an untagged criterion without `Evidence`; every criterion evidenced. Each control's fixture differs from the waiting fixture in that one respect `[unit]`
  - Evidence: the same test (`:20`) checks each control against `EXPECTED` — red: Expected: ["21-01#2", false], Received: ["21-01#2", true] with mutation of `buildItems`: `isUserWait = task === undefined && isWaitingOnUser(story)` (blockers ignored); Expected: ["22-01#1", false], Received: ["22-01#1", true] with mutation: `epic.blockedBy` dropped from `blockers`; Expected: ["24-01#1", false], Received: ["24-01#1", true] with mutation of `isWaitingOnUser`: the `story.isBlockedNote` test removed; Expected: ["25-01#1", false], Received: ["25-01#1", true] with `c.hasNotMet` removed; Expected: ["26-01#1", false], Received: ["26-01#1", true] with `every` → `some`; Expected: ["27-01#2", false], Received: ["27-01#2", true] with `story.hasLegacyEvidence` removed; Expected: ["27-01#1", false], Received: ["27-01#1", true] (and `waiting.test.ts:91` 'a story with no criteria does not wait', Expected: false, Received: true) with `unproven.length > 0 &&` removed from `isWaitingOnUser`
- A blocker epic that is `Complete` in `docs/archive/epics` counts as `Complete`: the reader reads the archive for blockers, and a test with the blocker only in the archive shows the story `Waiting on input` `[unit]`
  - Evidence: a blocker epic that is Complete only in the archive counts as Complete, and without it the story is blocked (`waiting.test.ts:42`, `claude plugin test cpm-next-progress`); `register.ts` `readEpics` reads `<docs>/archive/epics` (falling back to `docs/archive/epics`), marks those files `archived`, and filters them out of `saveTimes` and `defaultBuildOrder` — red: Expected: "Waiting on input", Received: "Pending" with mutation of `progress.ts` `buildItems`: `known = [...epics]` in place of the archived epics added
- The overview's waiting count includes stories waiting on the user; the recording of story timings (`timing.ts`) is unchanged, and a story shown as waiting is shown as waiting, not in progress, so it carries no running time on the page and is not in the overview's in-progress list `[unit]`
  - Evidence: the overview counts the stories waiting on the user (`waiting.test.ts:52`, `claude plugin test cpm-next-progress`); `timing.ts` is untouched (`git diff --stat -- cpm-next-progress` lists only `progress.ts` and `register.ts`; the new files are `hooks/waiting.test.ts` and `hooks/fixtures/waiting.ts`), so timings are recorded as before, and a story shown as waiting is not shown in progress (`:30`: Expected: "Waiting on input", Received: "In progress" with `trackerStatus` putting `In progress` first) — red: Expected: 7, Received: 8 with mutation of `isWaitingOnUser`: the `story.isBlockedNote` test removed
- `claude plugin test cpm-next-progress` passes, each new test shown failing once with the rule removed `[manual]`
  - Evidence: `claude plugin test cpm-next-progress` — 54 pass, 0 fail (46 before); each new test failed once under the mutations above; the criteria parser (`:59`, AssertionError at `toEqual`: Expected the first criterion `{ tag: "user", hasEvidence: true, … }`, Received it with `hasEvidence: false`) with mutation of `parseEpic`: the evidence-line pattern `Evidence\\b` → `Evidencex\\b`; 'a story that is not waiting keeps its own status' (`:36`, Expected: "Pending", Received: "Waiting on input") with `isUserWait = task === undefined && blockers.length === 0` (every unblocked story waiting); and the tag rule (`:85`) — red: Expected: "unit", Received: "" (`:85`) with mutation of `criterionTag`: the first backticked word read in place of the last; `tsc -p cpm-next-progress` prints only two errors, `isDeferred` not in `ToolSpec` at `register.ts:551` and `:557`, in code this story did not touch

### Parse criteria and status notes; read the archive
**Task**: 2.1  
**Description**: Amend `cpm-next-progress/hooks/progress.ts` and `register.ts`, with tests.  
**Status**: Complete

---

## whats-next lists what waits on you
**Story**: 3  
**Status**: Complete  
**Audit**: pass (2026-10-31), 8 findings fixed — the last fixes were not audited, at the user's decision
**Blocked by**: Story 1  
**Satisfies**: FR11  
**Amended**: criterion 3 is split in two: the functions that build the band, the heading and the `/next` text are `[unit]`, and the JSX that draws them, with the pane's 'Waiting on you' list, is `[manual]` (2026-10-31) — cited: `whats-next/.claude-plugin/types/claude-code/index.d.ts:14213-14228` (the test kit mocks only the clock, the store and the environment, so a pane cannot be mounted with a plan in the `plan` atom) and the `[user]` check in docs/epics/49-07-epic-user-checks.md  
**Pivot deferred**: FR11's "`hasWork`, the `/next` text, the band and the pane show the group when it is the only thing left" as a `[unit]` test → docs/specifications/49-spec-cheaper-red-first-evidence.md (Story 3, 2026-10-31) — cited: `whats-next/.claude-plugin/types/claude-code/index.d.ts:14213-14228`  
**Signal**: fix-not-carried-through — project — the shape fix covered the signature that `refresh` compares, while the band and pane read the saved plan without it (`whats-next/hooks/register.tsx`, final audit) — promoted 2026-10-31

**Acceptance Criteria**:

- A story waiting on the user, by the same rule, is not in `order` and not counted among the stories left, and appears in a "Waiting on you" group with each unproven criterion's text; tests read the shared fixtures, with the FR10 controls each keeping the story in `order` `[unit]`
  - Evidence: every live fixture story is listed as waiting exactly when the contract says it waits, and never in the order (`whats-next/hooks/waiting.test.ts:23`, `claude plugin test whats-next`; reads `fixtures/waiting.ts`), and a waiting story lists the text of each criterion still unproven (`:36`) — red: Expected: ["20-01#1", false], Received: ["20-01#1", true] with mutation of `plan.ts` `buildPlan`: `let remaining: Candidate[] = candidates` (waiting stories left in the order); the controls: Expected: ["21-01#2", false] with blockers ignored in `waitingStories`, ["22-01#1", false] with the epic's own blocker ignored, ["24-01#1", false] with `story.isBlockedNote` removed, ["25-01#1", false] with `hasNotMet` removed, ["26-01#1", false] with `every` → `some`, ["26-01#2", true] with the `Waiting on user` line no longer standing for the tag, ["27-01#2", false] with `hasLegacyEvidence` removed, ["23-01#1", true] with archived epics dropped from `buildPlan`'s epics (also the earlier test 'an archived complete epic satisfies a dependency')
- A story that depends on a waiting story is labelled as waiting on that check and is not ready, rather than falling into the cycle-or-unknown tail `[unit]`
  - Evidence: a story that depends on a waiting story is not ready and is labelled as waiting on that check, with its controls (`waiting.test.ts:43`, `claude plugin test whats-next`) — red: Expected: ["Story 1"], Received: [] with mutation of `plan.ts` `toStory`: `waitsOnChecks: []`; and Expected: [], Received: ["Story 1"] with `waitsOnChecks: waitsOn` (every dependency labelled)
- `hasWork` is true when the only thing left is a waiting story; `describePlan` (the `/next` text), `waitingBand` (the band's content) and `summaryOf` (the pane heading) carry the group; `NextPlan` in `whats-next/types/index.d.ts` carries it `[unit]`
  - Evidence: when only waiting stories are left there is still work to show (`waiting.test.ts:53`, `claude plugin test whats-next`; `hasWork` true, `describePlan` reads "no stories left to build", "Waiting on you (2)" and the check text) and 'the stories the user waits on are not counted among the stories left' (`:77`, "2 stories left"); `NextPlan` in `whats-next/types/index.d.ts` carries `waiting` and `waitsOnChecks`; `register.tsx` takes the band's content from `waitingBand` (`waiting.test.ts:133`) and the pane heading from `summaryOf` (`:140`), both tested; the band draws when `hasWork` is true (tested); the `plan` atom carries `{ shape: 'plan-2' }` with `plan: Shaped<NextPlan | null>` in the types, so a plan written by the previous version reads as absent and is rebuilt (engine behaviour, not unit-tested); `describePlan` counts the epics in the order (Expected: containing "2 stories left across 1 epics", Received: "2 stories left across 2 epics" with `plan.epics.length`) — red: Expected: true, Received: false with mutation of `plan.ts` `hasWork`: `plan.waiting.length > 0` removed; and Expected: containing "Waiting on you (2)", Received: "r: no stories left to build." with the `describePlan` waiting block's condition made false
- `register.tsx` draws the band from `waitingBand`, the pane heading from `summaryOf`, and a 'Waiting on you' section that lists each waiting story with each of its checks `[manual]`
  - Evidence: `whats-next/hooks/register.tsx:212-224` draws the band from `waitingBand(current)` ("Waiting on you", the first waiting story's label and title, the count); `:271` takes the pane heading from `summaryOf(current)`; `:304-315` draws a "Waiting on you" section with each waiting story's label and title and one dimmed line per check (`w.checks.map`); the gate at `:209` is `!hasWork(current)`; the live check is the `[user]` criterion in docs/epics/49-07-epic-user-checks.md — red: n/a — manual
- `claude plugin test whats-next` passes, each new test shown failing once with the rule removed, and `tsc -p whats-next` passes `[manual]`
  - Evidence: `claude plugin test whats-next` — 32 pass, 0 fail (18 before); `claude plugin validate whats-next` passes; `tsc -p whats-next` printed no errors; each new test failed once under the mutations above, and the tag rule (`:84`); a story with several dependencies shows all of them and marks only the checks (Expected: containing "waits on Story 1 (your check), Story 3", Received: "… waits on Story 1, Story 3 …" with the mark removed from `describePlan`, and Expected: "after S1 (your check), S3", Received: "after S1, S3" with it removed from `afterLabel`); an epic with work to build is not a check (Expected: [], Received: ["Epic 30-01-epic-mixed"] with `left.every` → `left.some`) and an epic whose only stories left are checks is one (Expected: ["Epic 30-01-epic-mixed"], Received: [] with the condition made false); the band names the first waiting story only when nothing is left to build (Expected: undefined, Received: { label: "20-01 S1", … } with the `plan.order.length > 0` test removed from `waitingBand`); the pane summary counts the epics the stories are in (Expected: "2 stories · 1 epic left · 2 waiting on you", Received: "2 stories · 2 epics left · 2 waiting on you" with `plan.epics.length`); every non-waiting, non-Complete fixture story stays in the order (Expected: ["24-01#1", true], Received: ["24-01#1", false] with blocked stories dropped from `remaining`) — red: Expected: { text: "does `thing`", tag: "unit" }, Received: { text: "does `thing` `[Unit]`", tag: "" } with mutation of `splitTag`: the first backticked word read in place of the last

### Exclude, group and label waiting stories
**Task**: 3.1  
**Description**: Amend `whats-next/hooks/plan.ts`, `register.tsx` and `types/index.d.ts`, with tests.  
**Status**: Complete

---
