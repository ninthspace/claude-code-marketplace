# Review: Proof routed by tag

**Date**: 2026-10-30  
**Source**: docs/epics/47-04-epic-proof-routed-by-tag.md  
**Reviewers**: Jordan, Bella, Tomas  
**Findings**: 20 (6 critical, 12 warnings, 2 suggestions)

## Summary

Worth building. Existing `[manual]` criteria keep their meaning, so in-flight epics in other projects are unaffected. The contract has no state for a story waiting on the user. As written, a closing `[user]` story stayed unblocked forever, so `do all` could not finish. Its epic never completed, which stalled any epic depending on it. A `[user]` line could be written without the user, and a failed report closed the story. The epic's `[user]` evidence form also contradicted 47-01's. Everything is fixed in the Pending stories except the cross-epic stall, which needs a spec decision.

## Findings

- **[Critical]** 💻 **Bella**, 📋 **Jordan**, 🔍 **Tomas**: no waiting state. A `[user]` story with `**Blocked by**: —` counts as unblocked, so `do all`'s finish line ("no unblocked story remains", do/SKILL.md:22) is never reached  
  → Story 3, criterion 4
- **[Critical]** 📋 **Jordan**, 🔍 **Tomas**, 💻 **Bella**: the epic never reaches `Complete` while its `[user]` story waits, so an epic in another epic's `**Blocked by**` stalls `do all {spec}`. FR11's closing-story rule covers stories within an epic only  
  → Story 2, FR11
- **[Critical]** 💻 **Bella**, 📋 **Jordan**: the `Evidence (user, date)` form contradicts 47-01's `red: n/a — user` form, so each auditor rule flags the other's line  
  → Story 1 criterion 3, Story 4 criterion 1
- **[Critical]** 🔍 **Tomas**: the auditor checks only form, so `do` can write a `[user]` line in the right form with no user present  
  → Story 3 criterion 4
- **[Critical]** 🔍 **Tomas**: a user's report that the check failed still becomes `Evidence` and closes the story  
  → Story 3 criterion 4
- **[Critical]** 💻 **Bella**, 📋 **Jordan**, 🔍 **Tomas**: `**Blocked by**: —` is wrong. The epic edits the evidence section (47-01 S2), plan's **Epics** paragraph (47-01 S4), the worktree section (47-03) and `auditor.md` (47-01, 47-03), and relies on 47-01's red rule  
  → epic header
- **[Warning]** 📋 **Jordan**, 💻 **Bella**: no handler for the user's answer, and no rule on auditing and closing a user-evidenced story  
  → Story 3
- **[Warning]** 💻 **Bella**: detecting a repo browser tool is unstated. Dusk runs outside `php artisan test`, so the auditor's suite result misses it. Pest browser tests and Playwright start their own server, which conflicts with "does not start a server"  
  → Story 3 criterion 1
- **[Warning]** 🔍 **Tomas**: a repo tool that exists but cannot run is not covered  
  → Story 3 criterion 1
- **[Warning]** 💻 **Bella**: how to check for a connected browser (deferred MCP tools via ToolSearch) and where the URL comes from (`APP_URL`, then a probe) are unstated; Herd answers any `.test` host  
  → Story 3 criterion 2
- **[Warning]** 🔍 **Tomas**: a page behind a login has no rule  
  → Story 3 criterion 2
- **[Warning]** 📋 **Jordan**, 💻 **Bella**: there is no rule for `[browser]` criteria in parallel or worktree batches, and "consistent with the new rule" cannot be checked  
  → Story 3 criterion 5
- **[Warning]** 🔍 **Tomas**: a criterion needing both browser and test proof lets one proof claim both  
  → Story 2
- **[Warning]** 🔍 **Tomas**: an untagged or `[manual]` criterion that `do` cannot perform (a deploy) is still claimed. This is the failure the spec targets  
  → Story 3
- **[Warning]** 🔍 **Tomas**: "from claude-in-chrome" cannot be identified; key the check on `browser-observed`  
  → Story 4 criterion 2
- **[Warning]** 🔍 **Tomas**, 💻 **Bella**: the small-change path gets no routing  
  → Story 3
- **[Warning]** 🔍 **Tomas**, 📋 **Jordan**: negative criteria have no control, and the epic has no `**Lessons**` line  
  → Stories 2-4
- **[Warning]** 📋 **Jordan**: Stories 2-4 claim NFR2 with no criterion checking it  
  → Stories 2-4
- **[Suggestion]** 📋 **Jordan**, 🔍 **Tomas**: an unattended site-permission prompt stalls the run  
  → Story 3
- **[Suggestion]** 📋 **Jordan**: `[user]` items will add to **Needs you** on every epic, with no cap or batching  
  → cross-cutting

## Remediation

- Fixed: waiting state → a story whose only criteria without `Evidence` are `[user]` waits on the user. `do` skips it when picking work, and the finish lines count it as done for the run. The contract states this without a new status value, so the mods' parsers are untouched
- Fixed: conflicting forms → one `[user]` form, `Evidence (user, {date}): … — red: n/a — user`, compatible with 47-01's mapping; Story 4 criterion 4 requires both auditor checks to name the same forms
- Fixed: line written without the user → only the answer to the **Needs you** question writes it, never in a run with no user present
- Fixed: negative report → it becomes `Not met`; on a positive report the story is audited and closed
- Fixed: header → blocked by 47-01 and 47-03
- Fixed: answer handler → a walk-through case in Story 3 criterion 5
- Fixed: repo tool → detected from its manifest, run in the session, its result given to the auditor; a tool may start its own server
- Fixed: unrunnable tool → falls back to claude-in-chrome
- Fixed: browser and URL → ToolSearch for the claude-in-chrome tools and a list of connected browsers, `APP_URL` on a local host, and one HTTP request to confirm the app answers
- Fixed: login → use the browser's existing session; never enter credentials or create users; otherwise **Needs you**
- Fixed: batches → subagents leave `[browser]` criteria to the lead after the batch; the worktree bullet names `[browser]`, with a grep control
- Fixed: mixed proof → `plan` splits such a criterion, and `review` flags one left combined
- Fixed: unperformable criterion → treated as `[user]` whatever its tag
- Fixed: claude-in-chrome identification → keyed on `browser-observed`
- Fixed: small changes → routed by reference
- Fixed: controls and Lessons → controls on the negative criteria; a `**Lessons**` line
- Fixed: NFR2 → a criterion in each story
- Needs you: cross-epic stall → user chose (2026-10-30) a final user-checks epic per spec that no epic depends on; Story 2 amended; FR11 to be amended through `/cpm-next:plan`
- Not acted on: site-permission prompt → recorded in the spec's Assumptions; there is no reliable way to detect it from a skill
- Not acted on: Needs-you volume → each item is a real proof only the user can give; batching them would hide which story each one unblocks
