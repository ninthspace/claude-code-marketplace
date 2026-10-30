# Proof routed by tag

**Source spec**: docs/specifications/47-spec-checks-that-can-fail.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 47-01-epic-red-first-evidence, Epic 47-03-epic-audit-isolation  
**Retro waived**: observations are in docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md (2026-10-30)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 3)  
**Amended**: 2026-10-30 — Stories 1-4 rewritten after review 04 (docs/reviews/04-review-proof-routed-by-tag.md): one `[user]` evidence form shared with 47-01; a story waiting on the user is skipped, not picked forever, and closes only on the user's answer; a negative report is `Not met`; how `do` finds a browser tool, a connected browser and a local URL; logins, worktrees and small changes; controls on negative criteria; NFR2 checks; blocked by 47-01 and 47-03

The `[user]` evidence form used throughout this epic is, literally:
`Evidence (user, {YYYY-MM-DD}): {what the user reported} — red: n/a — user`

## The contract defines the browser and user tags
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 1 findings fixed  
**Blocked by**: —  
**Satisfies**: FR10, FR13  
**Effort**: low

**Acceptance Criteria**:

- The spec template's tag list in `cpm-next/shared/artifacts.md` reads `[unit|feature|integration|browser|manual|user]` `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:70` reads `[unit|feature|integration|browser|manual|user]` — red: n/a — manual
- The contract states what each of `[browser]`, `[manual]` and `[user]` means, with `[manual]` unchanged (a step `do` performs in the session outside the test suite) and `[user]` illustrated by a production run, a deploy, a sign-off and a third-party account `[manual]`
  - Evidence: `artifacts.md:92` defines `[browser]` (proved only by a rendered page), `[manual]` unchanged (a step `do` performs in the session outside the test suite) and `[user]` (a production run, a deploy, a sign-off, a third-party account) — red: n/a — manual
- The evidence section shows the `[user]` form above, next to 47-01's forms, and says a story whose only criteria without `Evidence` are `[user]` is waiting on the user: it keeps its status, and `do` does not pick it `[manual]`
  - Evidence: `artifacts.md:140` shows the `[user]` form next to the two forms at `:136` and `:138` (`user` is no longer a reason in the generic form); `:147` says a story with at least one criterion lacking `Evidence`, every such criterion being `[user]` or treated as `[user]` by `do`, is waiting on the user, keeps its status, and `do` does not pick it — red: n/a — manual

### Extend the tag list and evidence forms
**Task**: 1.1  
**Description**: Edit the spec template, the status section and the evidence section of `cpm-next/shared/artifacts.md`.  
**Status**: Complete

---

## plan and review route criteria by who can prove them
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-30), 2 findings fixed  
**Blocked by**: —  
**Satisfies**: FR11, NFR2

**Acceptance Criteria**:

- `cpm-next/skills/plan/SKILL.md` says each criterion is tagged by who or what proves it, that a criterion needing two kinds of proof (a browser check and a test, or a test and a user step) is split into one criterion per proof, and that a `[user]` criterion states the exact steps and the observation that proves it `[manual]`
  - Evidence: `cpm-next/skills/plan/SKILL.md:52` — tag by who or what proves it, split a criterion needing two kinds of proof into one per proof, write a `[user]` criterion with exact steps and the observation — red: n/a — manual
- `plan` says a spec's `[user]` criteria go in one final epic of that spec, which no other epic names in `**Blocked by**`; within it, stories holding them are blocked by nothing that holds a `[user]` criterion. A spec with no `[user]` criteria gets no such epic. Control: the sentence names `**Blocked by**`, so a builder who places them elsewhere has nothing to cite `[manual]`
  - Evidence: `plan/SKILL.md:52` — a spec's `[user]` criteria go in one final epic that no other epic names in `**Blocked by**` and that is blocked by the epics whose work its criteria check; its stories are blocked by nothing that holds a `[user]` criterion; a spec with none gets no such epic; a `00-` epic uses a final story blocked by the stories it checks — red: n/a — manual
- `plan`'s **Done means** bullet "every acceptance criterion is something `do` can check" accepts a `[user]` criterion written that way `[manual]`
  - Evidence: `plan/SKILL.md:20` accepts a `[user]` criterion written with its exact steps and observation — red: n/a — manual
- `review`'s bullet "criteria that `do` couldn't verify" accepts such a `[user]` criterion, and flags one that is outside the spec's final user-checks epic, an epic that names that epic in `**Blocked by**`, or a criterion that combines two kinds of proof `[manual]`
  - Evidence: `cpm-next/skills/review/SKILL.md:35` accepts such a criterion in the final user-checks epic and flags one outside it (or outside a `00-` epic's final story), a `00-` final story not blocked by the stories it checks, an epic naming it in `**Blocked by**`, a user-checks epic not blocked by the epics it checks, and a criterion combining two kinds of proof — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep over them returns only rules ("no longer exists" in the resume rule, "earlier session") — red: n/a — manual

**Amended**: 2026-10-30 — `[user]` criteria go in a final user-checks epic per spec rather than a closing story per epic (review 04, user's decision)

### Add tagging, splitting and the final user-checks epic rule to plan
**Task**: 2.1  
**Description**: Edit **Done means** and step 3 **Epics** in `cpm-next/skills/plan/SKILL.md`.  
**Status**: Complete

### Amend review's verifiability bullet
**Task**: 2.2  
**Description**: Edit step 2 of `cpm-next/skills/review/SKILL.md`.  
**Status**: Complete

---

## do proves browser criteria and waits on user criteria
**Story**: 3  
**Status**: Complete  
**Audit**: pass (2026-10-30), 5 findings fixed — the round-3 Warning was fixed after the last audit and accepted unaudited by the user (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR12, FR13, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `do` step 3 says a `[browser]` criterion is proved with the repo's own browser test tool when its manifest declares one (`laravel/dusk`, `pestphp/pest-plugin-browser`, `@playwright/test`) and it runs in the session; that test gets a red result like any other; and when the tool runs outside the project's test command, `do` runs it and gives its result to the auditor with the full-suite result. A tool that starts its own server may do so `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:51` — `[browser]` proved with the repo's own tool when its manifest declares `laravel/dusk`, `pestphp/pest-plugin-browser` or `@playwright/test` and it runs in the session; red like any other; a tool outside the project's test command is run by `do` and its result goes to the auditor with the full-suite result; a tool that starts its own server may — red: n/a — manual
- Without a runnable repo tool, the lead, never a subagent, uses claude-in-chrome: once per run, in **Before the first story**, it loads the claude-in-chrome tools with ToolSearch and lists the connected browsers, and tools not found or no browser listed count as not connected. It takes the URL from the project's `APP_URL` when that host is `localhost`, `127.0.0.1` or a `.test` host, and confirms with one HTTP request that the app answers there; it records the URL, the steps, and what the page showed, with a short excerpt of its text `[manual]`
  - Evidence: `do/SKILL.md:42` loads the claude-in-chrome tools with ToolSearch and lists connected browsers once per run, tools not found or no browser listed counting as not connected; `:51` has the lead, never a subagent, take `APP_URL` on `localhost`, `127.0.0.1` or `.test`, confirm with one HTTP request, and record URL, steps and a page excerpt — red: n/a — manual
- It says `do` does not start a server, enter credentials or create users for a browser check; a page behind a login uses the browser's existing session, and otherwise the criterion goes to **Needs you**. Control: each of these cases (other host, no answering server, no browser, a login with no session, a browser that disconnects later) is named with its outcome, **Needs you** `[manual]`
  - Evidence: `do/SKILL.md:51` — starts no server, enters no credentials, creates no users; uses the browser's existing session; names each case (another host, no answering server, no connected browser, a login with no session, a browser that disconnects later) with the outcome **Needs you**, after which the criterion is treated as `[user]` — red: n/a — manual
- In a parallel batch, a subagent leaves `[browser]` criteria to the lead, who checks them after the batch; the worktree-mode bullet listing "a browser check, Dusk" keeps such stories out of worktree batches and names `[browser]` criteria. Control: `grep -n "a browser check, Dusk" cpm-next/skills/do/SKILL.md` shows the bullet still present, now naming `[browser]` `[manual]`
  - Evidence: `do/SKILL.md:65` leaves `[browser]` criteria to the lead after a batch; `:80` keeps the bullet "a browser check, Dusk" (`grep -n "a browser check, Dusk"` finds it) and now names `[browser]` — red: n/a — manual
- `do` never writes a `[user]` `Evidence` line except from the user's answer to the **Needs you** question for that criterion: the walk-through gains a case that writes the line in the form above when the user reports success, writes a `Not met` line when they report failure, then audits the story and closes it as step 6 says. In a run with no user present the line is never written `[manual]`
  - Evidence: `do/SKILL.md:51` writes a `[user]` `Evidence` line only from the user's answer; `:173` has the walk-through write the line in the literal form on success, a `Not met` line on failure, then, once no criterion in the story lacks `Evidence`, take step 4, audit and close as step 6 says; with no user present the line is never written — red: n/a — manual
- A story whose only criteria without `Evidence` are `[user]` is waiting on the user: `do` skips it when picking work, and the finish lines in the scope table ("no unblocked story remains") count a waiting story as done for the run; **Needs you** lists each such criterion with its steps `[manual]`
  - Evidence: `do/SKILL.md:51` — a story with a criterion lacking `Evidence`, every such criterion being `[user]` or treated as `[user]`, waits and lists each with its steps under **Needs you**; `:47` skips it when picking work and `:25` picks only an epic whose `**Blocked by**` epics are Complete and that has an open, unblocked story (no `Not met` line) that is not waiting, and stops if none; `:27` counts it as done for the finish lines `:56` exempts a waiting story from the re-read rule and `:157` fires the retro rule for an epic the user's answer completes; `:163` adds a `[user]` criterion with its steps to **Needs you** — red: n/a — manual
- A criterion `do` cannot carry out in the session, whatever its tag (an untagged or `[manual]` deploy, production run or sign-off), is treated as `[user]` and never claimed as met `[manual]`
  - Evidence: `do/SKILL.md:51` — a criterion `do` can't carry out in the session, whatever its tag, is treated as `[user]` and never claimed as met — red: n/a — manual
- The small-change paragraph applies the same routing to a `docs/quick/` record, by reference `[manual]`
  - Evidence: `do/SKILL.md:35` — tag each criterion and route `[browser]` and `[user]` as step 3 does, by reference — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep over them returns only rules — red: n/a — manual

### Add browser and user routing to do
**Task**: 3.1  
**Description**: Edit the scope table, **Before the first story**, step 3, the parallel and worktree-mode sections, the small-change paragraph and **Finishing** in `cpm-next/skills/do/SKILL.md`.  
**Status**: Complete

---

## The auditor checks the form of browser and user evidence
**Story**: 4  
**Status**: Complete  
**Audit**: pass (2026-10-30), 2 findings fixed  
**Blocked by**: —  
**Satisfies**: FR14, NFR2

**Acceptance Criteria**:

- `cpm-next/agents/auditor.md` check 1 reports as Critical an `Evidence` line on a `[user]` criterion that is not in the `[user]` form above `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:20` (check 1) reports a `[user]` `Evidence` line not in the full contract form, `Evidence (user, {YYYY-MM-DD}): … — red: n/a — user`, as Critical — red: n/a — manual
- It reports as a Warning a `[browser]` criterion whose `Evidence` line has neither a test with its red result nor a `browser-observed` record with a local URL, steps and a page excerpt `[manual]`
  - Evidence: `agents/auditor.md:20` reports as Warning a `[browser]` criterion with neither a test with its red result nor a `browser-observed` record with a local URL, steps and page excerpt, nor the `[user]` form — red: n/a — manual
- It says the auditor checks these for presence and form and does not repeat the browser check or contact the user `[manual]`
  - Evidence: `agents/auditor.md:20` — "Check these for presence and form only: don't repeat the browser check or contact the user" — red: n/a — manual
- The `n/a` reason checks of 47-01's check 5 and these checks name the same forms, so one line cannot satisfy one and fail the other `[manual]`
  - Evidence: check 1 names `red: n/a — user` and `red: n/a — browser-observed`, the same reasons check 5 and `artifacts.md:145` pair with `[user]` (or a criterion `do` treats as `[user]`, in the form `Evidence (user, …)`) and `[browser]` — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Add the evidence-form checks
**Task**: 4.1  
**Description**: Edit check 1 of `cpm-next/agents/auditor.md`.  
**Status**: Complete

---
