# Release cpm-next 0.9.0

**Source spec**: docs/specifications/47-spec-checks-that-can-fail.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 47-01-epic-red-first-evidence, Epic 47-02-epic-lessons-checked, Epic 47-03-epic-audit-isolation, Epic 47-04-epic-proof-routed-by-tag  
**Retro waived**: observations are in docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md (2026-10-30)  
**Amended**: 2026-10-30 — Story 1 rewritten and Story 2 moved to epic 47-06 after review 05 (docs/reviews/05-review-release.md): the upgrade note covers every change the amended epics make, including the `[manual]` exception; a fuller maintenance record; the baseline pinned to commit `2f406b1`; `claude plugin test` in place of `bun test`; target versions; a spec-consistency check

The baseline for every "before" count in this spec's epics is commit `2f406b1`, the head when spec 47 was planned.

## Release with an upgrade note
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 1 finding fixed  
**Blocked by**: Story 2  
**Satisfies**: FR15, NFR1, NFR2, NFR3

**Acceptance Criteria**:

- Spec 47's FR1, FR9 and FR11 read as the epics now build them (any covered line may be mutated; in an unisolated suite audits stay parallel and the auditor runs no tests; `[user]` criteria go in a final user-checks epic). If they do not, the story stops before release and **Needs you** names `/cpm-next:plan` on the spec `[manual]`
  - Evidence: read `docs/specifications/47-spec-checks-that-can-fail.md` FR1 (any covered line may be mutated, reverted through a scratch copy), FR9 (an unisolated suite keeps audits parallel and the auditor runs no tests) and FR11 (a final user-checks epic) against `do/SKILL.md` step 4, the scratch section and Audit, and `plan/SKILL.md:52`; they agree, so no stop. FR11 says nothing on the epic's blocking, which `plan/SKILL.md:52` adds without contradicting it — red: n/a — manual
- `cpm-next/README.md` gains one `**{Name}** (0.9.0):` bullet per change, in the style of the existing entries, covering: the red result in `Evidence` lines and its literal form; a missing red as an audit Warning; resume adding reds to evidenced, unaudited stories; the `**Lessons**` epic field and the `**Recurrence**` retro marker; per-run scratch directories; the auditor running no tests in an unisolated suite; the `[browser]` and `[user]` tags and the literal `[user]` evidence form; a story waiting on the user being skipped; `[user]` criteria going in a final user-checks epic; claude-in-chrome as the fallback for `[browser]` criteria on local hosts; and existing epics not being back-filled `[manual]`
  - Evidence: `cpm-next/README.md` Additions holds thirteen `(0.9.0)` bullets: red-first evidence and its literal form; a missing red as an audit Warning; resume adding reds; the `**Lessons**` field; the `**Recurrence**` marker; per-run scratch directories; no tests in an unisolated suite; the `[browser]` and `[user]` tags and the literal `[user]` form; waiting stories skipped; the final user-checks epic; claude-in-chrome on local hosts; negative criteria carrying their control, with small-change records getting the same rule; no back-fill — red: n/a — manual
- The upgrade note says `[manual]` criteria keep their meaning except one `do` cannot carry out in the session (a deploy, a production run, a sign-off), which is now treated as `[user]`; and that `whats-next` and the progress tracker show a story waiting on the user as the next or in-progress work `[manual]`
  - Evidence: `cpm-next/README.md`, section "Upgrading to 0.9.0": `[manual]` keeps its meaning except a criterion `do` cannot carry out in the session (a deploy, a production run, a sign-off), now treated as `[user]`; `whats-next` and `cpm-next-progress` show a waiting story as next or in progress — red: n/a — manual
- `cpm-next/.claude-plugin/plugin.json` and the cpm-next entry in `.claude-plugin/marketplace.json` read `0.9.0`, the marketplace version reads `4.0.4`, and the versions of `cpm-next-models`, `cpm-next-progress` and `whats-next` are unchanged from `2f406b1` (`git diff 2f406b1 -- .claude-plugin/marketplace.json` shows only those three lines) `[manual]`
  - Evidence: `cpm-next/.claude-plugin/plugin.json` and the cpm-next entry in `.claude-plugin/marketplace.json` read `0.9.0`; the marketplace reads `4.0.4`; `git diff 2f406b1 -- .claude-plugin/marketplace.json` shows exactly two changed lines (`4.0.3` to `4.0.4`, cpm-next `0.8.8` to `0.9.0`; the third version line is `plugin.json`), and the `cpm-next-models`, `cpm-next-progress` and `whats-next` versions are untouched — red: n/a — manual
- `docs/maintenance/README.md` gains a record in the file's existing layout ("The record." and "What asserts it.") covering: the claude-in-chrome tool names `do` calls and their loading through ToolSearch; `APP_URL` read from `.env` and the `localhost` / `127.0.0.1` / `.test` host rule; the browser-tool package names `do` detects (`laravel/dusk`, `pestphp/pest-plugin-browser`, `@playwright/test`); the scratchpad with its `mktemp -d` fallback; the site-permission prompt that can stall an unattended run; that `whats-next` and `cpm-next-progress` pick by status alone and so show a waiting story; and the new contract strings a mod may later parse (`red:`, `Evidence (user,`, `**Lessons**`, `**Recurrence**`). "What asserts it" says nothing automated does `[manual]`
  - Evidence: `docs/maintenance/README.md`, section "`cpm-next` ↔ claude-in-chrome, project files and the mods", in the file's layout: **The record.** covers the claude-in-chrome tool names and `ToolSearch` loading, `APP_URL` and the host rule, the three package names, the scratchpad with `mktemp -d`, the site-permission stall, `whats-next` and `cpm-next-progress` picking by status alone, and the contract strings (`red:`, `Evidence (user,`, `**Lessons**`, `**Recurrence**`, `**Scratch**`); **What asserts it.** says nothing automated does — red: n/a — manual
- `wc -w cpm-next/skills/{do,plan,review}/SKILL.md cpm-next/agents/auditor.md cpm-next/shared/artifacts.md` totals no more than 10,300 words, the limit as amended below; control: the same five files read with `git show 2f406b1:{path} | wc -w` total 8,225 `[manual]`
  - Evidence: `wc -w` over the five files totals 10,262, within the limit of 10,300 as amended in this epic; `git show 2f406b1:{path} | wc -w` over the same five totals 8,225 — red: n/a — manual
- Every added line in `git diff 2f406b1 -- cpm-next/skills cpm-next/agents cpm-next/shared` is read, and none names a project, a retro, a cpm-next version, or what the plugin did before; `grep -nE "no longer|used to|previously|0\.[0-9]+\.[0-9]|retro [0-9]|ice-" ` over those added lines returns only matches that are rules, each listed in the `Evidence` line `[manual]`
  - Evidence: added lines in `git diff -U0 2f406b1 -- cpm-next/skills cpm-next/agents cpm-next/shared` read; the grep returns one line, the `[browser]` rule in `do/SKILL.md` step 3, which matches only on the package names it lists and is a rule — red: n/a — manual
- `claude plugin validate cpm-next` reports no errors `[manual]`
  - Evidence: `claude plugin validate cpm-next` — Validation passed — red: n/a — manual
- `claude plugin test cpm-next-models`, `claude plugin test cpm-next-progress` and `claude plugin test whats-next` pass `[manual]`
  - Evidence: `claude plugin test cpm-next-models` 18 pass, `cpm-next-progress` 46 pass, `whats-next` 18 pass, 0 fail — red: n/a — manual

### Write the README entry and bump versions
**Task**: 1.1  
**Description**: Edit `cpm-next/README.md`, `cpm-next/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.  
**Status**: Complete

### Write the maintenance record
**Task**: 1.2  
**Description**: Edit `docs/maintenance/README.md`.  
**Status**: Complete

### Run the consistency, size, history, validation and mod checks
**Task**: 1.3  
**Description**: Run the commands the criteria name.  
**Status**: Complete

---

## Trim the five files to the NFR1 limit
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-30), 2 findings fixed  
**Blocked by**: —  
**Satisfies**: NFR1, NFR2  
**Effort**: high

**Acceptance Criteria**:
- `wc -w cpm-next/skills/{do,plan,review}/SKILL.md cpm-next/agents/auditor.md cpm-next/shared/artifacts.md` totals no more than 10,300 words (8,225 at `2f406b1` plus 25%, raised from 9,047 by the user's decision on 2026-10-30); control: when the total is already within the limit before any cut, the `Evidence` line says so and no text is cut `[manual]`
  - Evidence: `wc -w cpm-next/skills/{do,plan,review}/SKILL.md cpm-next/agents/auditor.md cpm-next/shared/artifacts.md` totals 10,262, within 10,300; at `2f406b1` the five total 8,225 (`git show 2f406b1:{path} | wc -w`) — red: n/a — manual
- Each cut is listed in the `Evidence` line: the file, the sentence or passage removed or shortened, and why it can go (said twice, an example the rule does not need, a clause that restates the heading) `[manual]`
  - Evidence: all cuts are in `cpm-next/skills/do/SKILL.md` (comparison against the pre-trim copy by an auditor, 2026-10-30): the two baseline paragraphs merged into one ("In every case", "since that run" dropped, said twice); the small-change paragraph condensed ("A description doesn't say what complete means" shortened; sentences about the contract format and verdict merged); the "Before the first story" bullets shortened and the resume rule reordered with its restore step first; step 3 split into `[browser]` and `[user]` bullets with "so each proof sits beside the claim it proves" dropped; step 4 split into bullets with "these are the findings a first audit most often returns" dropped; step 5 and the parallel, worktree and Audit paragraphs shortened ("Each worktree runs its own tests" and the third-audit `given the second audit's findings`, which the Audit section repeats at `do/SKILL.md:118`); the "When to stop" list turned into prose; the Needs-you bullet's "they belong under the other headings or nowhere" dropped (a rationale) — red: n/a — manual
- No rule is lost: for each cut, the rule it carried is either still stated where the cut was made or stated elsewhere, cited by `file:line`. Control: a cut whose rule has no citation is restored `[manual]`
  - Evidence: the auditor's word-by-word comparison of the pre-trim and current `do/SKILL.md` found no dropped rule; its two meaning shifts (step 5's third audit, the audit's "no limit on its length") were restored at `do/SKILL.md:57` and `:116` — red: n/a — manual
- Cuts may come from text that existed at `2f406b1` as well as text spec 47 added, but no rule spec 47 added is removed `[manual]`
  - Evidence: the cuts above are condensations of text from `2f406b1` and of spec 47's own text; every rule spec 47 added (scratch line and red method, resume after a stopped red, no red while an auditor runs, builder and auditor directories, `[browser]` and `[user]` routing, lesson and tag rules for quick records) is still present per the auditor's comparison — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: no sentence was added by this story; the rewrite only condenses — red: n/a — manual

**Amended**: the size limit is 10,300 words in Story 1's size criterion and Story 2's first criterion (2026-10-30) — cited: the user's decision on 2026-10-30, after Story 2 could reach 10,262 words only by deleting rules
**Amended**: 2026-10-30 — added after review 05 (docs/reviews/05-review-release.md), on the user's decision to keep NFR1 at 10% and trim

### Measure, cut and list
**Task**: 2.1  
**Description**: Edit the five files until the total fits.  
**Status**: Complete

---
