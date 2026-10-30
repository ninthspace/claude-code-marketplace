# Spec: Checks that can fail, lessons that are checked, and proof routed by who can give it

**Date**: 2026-10-30  
**Source**: docs/discussions/04-discussion-harness-loops-graphs-for-cpm-next.md
**Amended**: 2026-10-30 — FR1 lets the red come from mutating any line the cited test covers, reverted through a scratch copy, and names who takes it; FR2 and FR3 carry the failure text and the green rerun after restore; AD2 matches (review 01, docs/reviews/01-review-red-first-evidence.md, user's decision)
**Amended**: 2026-10-30 — FR6-FR9 and FR11-FR15 and NFR1 brought in line with reviews 02-05 and the user's decisions there: lesson reference form and one-persona lesson check; defined scratch directories and isolated suites, with audits parallel and the auditor running no tests in an unisolated suite; a final user-checks epic; browser and user routing details and the waiting state; a fuller upgrade note; a trim to stay within 10%
**Amended**: 2026-10-30 — NFR1's limit raised to 10,300 words (user's decision, resolving the Pivot deferred in 47-05); FR6's amendment reference carries the observation's opening words; FR17-FR21 added for the fixes made after release, built in epic 47-07 (user's decision)

## Problem Summary

Retros from the projects cpm-next runs in show four repeated failures that the plugin, rather than any one project, can prevent:

1. Tests cited as evidence that could not have failed: a negative assertion with no control, a fixture that makes two values agree, an empty-against-empty comparison. Seen in ice-analytics (25+ retros), ice (about 14), ice-services, shortbread, hlh-performance and hlh-net-promoter-score, and repeated after the lesson was promoted to ice-analytics' library. `do` step 4 (`cpm-next/skills/do/SKILL.md:49`) already tells the builder to undo the covered line and see each new test fail, but nothing records the result, so the check is self-reported.
2. Lessons in the library and in retros that `plan` and `review` read but do not check criteria against, so the same lesson is rediscovered (ice 05, ice-services 01, ice-analytics retros 17 and 44).
3. Auditors and the lead colliding over shared scratch files and shared test state (ice 16, ice-coupons 12-14, ice-analytics 76 and 88).
4. Criteria whose proof cannot be produced in the session (a production run, a deploy, a page only a browser renders) being claimed as met, or left with no route to the person who can prove them (ice-services 02, ice 24, castle 02-06).

The files changed are `cpm-next/skills/do/SKILL.md`, `cpm-next/skills/plan/SKILL.md`, `cpm-next/skills/review/SKILL.md`, `cpm-next/agents/auditor.md` and the contract `cpm-next/shared/artifacts.md`. Where a file already states a rule this spec strengthens, the existing rule is amended, never restated beside it.

## Functional Requirements

### Must Have

- **FR1**: `do` step 4's "confirm it fails without the change" becomes a recorded result, per criterion. For every criterion a test proves (any tag the project's Testing Strategy maps to a suite, and untagged legacy criteria a test proves), the criterion's `Evidence` line names the assertion that failed and how it was made to fail: the covered lines undone, or a mutation of the covered line. The red must come from the cited assertion; an error (missing class, route or table) does not count, and a stub that returns a wrong value does. The red is recorded after the simplifier pass, against the code being closed. The undo or mutation may touch any line the cited test covers. It is made on a file copied to the scratch directory first and copied back afterwards, never through `git checkout`, `git show`, `git stash` or `reset`, and the test is run green again after the restore. The builder takes the red in a single build, the lead after a parallel batch in one checkout (never a subagent while siblings run), and the subagent in its own worktree in worktree mode. Criteria not proven by a test record `red: n/a — {manual | user | browser-observed | static}` instead. — AC: `do` step 4 states the rule in place of its current sentence; nothing else in `do` restates it `[manual]`
- **FR2**: The contract's evidence example shows the red result: `Evidence: {test name, file:line} ({command}) — red: {failure text, shortened} with {lines undone | mutation of {file:line}: {change}}; green after restore`, and the `n/a` form, with each `n/a` reason mapped to the tag it fits. — AC: `shared/artifacts.md` gives both examples `[manual]`
- **FR3**: The auditor's check 5 reads each test-proven criterion's red result instead of breaking lines in a scratch copy: it reports as a Warning a red result that is missing, names a test other than the one cited, has failure text showing an error rather than the cited assertion failing, describes an undo or mutation that the cited assertion does not depend on, or lacks the green rerun after restore, and as a Critical an `n/a` reason that does not match the criterion's tag. — AC: `agents/auditor.md` check 5 states this, and no longer tells the auditor to edit or copy source `[manual]`
- **FR4**: On resume, `do` adds a red result to each evidenced story that has no `**Audit**` line before auditing it, so stories evidenced before this rule are audited against it. — AC: the resume rule in `do` states it `[manual]`
- **FR5**: `plan` gives every negative criterion ("must not", "no change to", "never") the control that shows its test can fail, in the criterion's own text. — AC: `plan` states the rule `[manual]`
- **FR6**: Before writing an epic's criteria, `plan` decides which library lessons and unretired retro observations bear on the epic's area; when `docs/retros/` holds more than 20 files, the `scout` agent lists candidates and `plan` judges. A lesson about what the result must satisfy is reflected in a criterion; a lesson about how to build needs none. The epic header names each bearing lesson in a `**Lessons**` line as a lesson reference (`{library path} → "{heading}"`, `{library path} → amendment from {retro path} → "{opening words}"`, or `{retro path} → "{opening words}"`) followed by `(Story {N})` or `(build)`, and omits the line when none bear. — AC: `plan` states the rule; the contract defines the field and the reference forms `[manual]`
- **FR7**: `review` gives the lesson check to one persona (the Test Engineer or QA when picked, otherwise the persona asking "can we build it like this?"), not to the list every persona gets. That persona checks each `(Story {N})` entry against a criterion in that story, finds bearing lessons itself when an epic has no `**Lessons**` line, and reports a bearing lesson no criterion reflects as a Warning. — AC: `review` states it outside the every-persona list `[manual]`
- **FR8**: `do` makes a run directory under the session's scratchpad (or with `mktemp -d`), and inside it a builder directory per story for red copies and a fresh auditor directory per audit round, each created by the lead and passed by absolute path; the auditor's read-only rule allows writing in its directory and nowhere else. — AC: `do` defines the directories in one place; `agents/auditor.md` amends its read-only sentence `[manual]`
- **FR9**: A suite is isolated when every test process, including a single run without a parallel flag, gets its own database and its own copy of every file tests write, and no test binds a fixed port; `do` makes this check once per run before the first audit, and worktree mode uses the same definition. With an isolated suite, audits of stories that share no files run in parallel and the auditor may run tests; otherwise audits still run in parallel and the auditor runs no tests, reading the tests and the full-suite result it was given. No red is taken in the checkout while any auditor is running, and two full-suite runs never run at once. — AC: `do` and `agents/auditor.md` state it `[manual]`
- **FR10**: The contract's tag list gains `[browser]`, for a criterion proved only by a rendered page, and `[user]`, for one only the user can prove (a production run, a deploy, a sign-off, a third-party account). `[manual]` keeps its meaning: a step `do` performs in the session outside the test suite. — AC: `shared/artifacts.md` lists the tags and their meanings `[manual]`
- **FR11**: `plan` tags each criterion by who or what can prove it, splits a criterion needing two kinds of proof, writes a `[user]` criterion with the exact steps and the observation that proves it, and puts a spec's `[user]` criteria in one final user-checks epic that no other epic names in `**Blocked by**`. `plan`'s "every acceptance criterion is something `do` can check" and `review`'s "criteria `do` couldn't verify" both accept a `[user]` criterion written this way. — AC: `plan` and `review` state it `[manual]`
- **FR12**: `do` proves a `[browser]` criterion with the repo's own browser test tool when its manifest declares one (`laravel/dusk`, `pestphp/pest-plugin-browser`, `@playwright/test`) and it runs in the session; that test gets a red result, and its result goes to the auditor when it runs outside the project's test command. Otherwise the lead, never a subagent, uses claude-in-chrome: it loads the tools with ToolSearch and lists connected browsers once per run, takes the URL from `APP_URL` on a `localhost`, `127.0.0.1` or `.test` host, confirms the app answers, uses the browser's existing session behind a login, and records the URL, the steps and a page excerpt. It starts no server, enters no credentials and creates no users; any other case is a **Needs you** item. In a parallel batch, `[browser]` criteria are left to the lead. — AC: `do` states the order of tools, the host rule and each fallback `[manual]`
- **FR13**: `do` writes a `[user]` criterion's `Evidence` line only from the user's answer to the **Needs you** question for it, in the form `Evidence (user, {YYYY-MM-DD}): {what the user reported} — red: n/a — user`; a reported failure becomes `Not met`, and a reported success is audited and closed. A story whose only criteria without `Evidence` are `[user]` waits on the user: `do` skips it when picking work and counts it as done for the run's finish line. A criterion `do` cannot carry out in the session is treated as `[user]` whatever its tag. — AC: `do` states it; the contract shows the form and the waiting rule `[manual]`
- **FR14**: The auditor treats a `[user]` `Evidence` line not in FR13's form as Critical, and a `[browser]` criterion with neither a test and its red result nor a `browser-observed` record with a local URL, steps and page excerpt as a Warning, using the same forms as its check of `n/a` reasons. It checks presence and form only. — AC: `agents/auditor.md` states it `[manual]`
- **FR15**: The cpm-next README gains one bullet per change of this release, and its upgrade note says that `[manual]` criteria keep their meaning except one `do` cannot carry out in the session, which is treated as `[user]`, and that `whats-next` and the progress tracker show a story waiting on the user as next. — AC: the README entry covers every change and both notes `[manual]`

- **FR17**: A story `do` has to stop on (a `Not met` line, an unresolved audit finding, an unexplained failure) keeps its status and adds the note ` — blocked: {reason}`; `do` neither picks it with no argument nor resumes it, and clears the note only when nothing that blocked it remains. — AC: the contract's status vocabulary defines the note; `do` states each rule `[manual]`
- **FR18**: A story waits on the user only when everything named in its own and its epic's `**Blocked by**` is `Complete`, it is not marked blocked, and every criterion without `Evidence` is `[user]` or treated as `[user]`. — AC: the contract and `do` state the same definition `[manual]`
- **FR19**: `status` reports blocked stories with their reason and stories waiting on a user check with their steps under **Needs you**, and recommends `/cpm-next:do {epic}` to record a check's result. — AC: `status` states it `[manual]`
- **FR20**: The six skills are shortened with no rule lost, and `do`'s worktree rules live in `skills/do/worktree.md`, read only with `--parallel`, `--parallel check`, or when unblocked stories that share files are waiting. — AC: word counts and a rule comparison against the pre-shortening text `[manual]`
- **FR21**: The contract's amendment block and amendment lesson reference identify one observation, and `library learn` does not promote again an observation already in the library. — AC: the contract and `library` state it `[manual]`

### Should Have

- **FR16**: When `do` writes a retro observation whose failure an earlier unretired observation or a library lesson already describes, it cites that source in the bullet as `**Recurrence**: {path}` and reports it under **Found**. When the source is a library lesson, the lesson did not prevent the failure, so it also goes under **Needs you** as a lesson to turn into a criterion rule in `plan` or a check in the auditor. — AC: `do` states it; the contract defines the marker `[manual]`

### Won't Have (this iteration)

- Undo tiers on stories, enforced per-story file fences, loop stop rules for identical failures, and audit rounds scaled by effort (Positions Not Taken in the discussion).
- Automatic promotion of lessons to the library without the user choosing them.
- The auditor re-running a recorded red itself.
- Any change to the `cpm-next-models`, `cpm-next-progress` or `whats-next` mods.

## Non-Functional Requirements

- **NFR1**: The combined word count of `do`, `plan`, `review`, the auditor and the contract is no more than 10,300 words (`wc -w`; 8,225 at commit `2f406b1`), with no rule lost to reach it.
- **NFR2**: No sentence added to a SKILL.md or agent file records history (what a past version did, which retro prompted it, the projects it came from), per `CLAUDE.md` "A SKILL.md is not a change log".
- **NFR3**: `claude plugin validate cpm-next` reports no errors after the change.

## Architecture Decisions

### AD1: The red result lives in the `Evidence` line

The red is appended to the criterion's existing `Evidence` line. A separate field would split one proof across two places, which is what per-criterion evidence exists to stop. Rejected: a story-level `**Red**` field; a separate mutation report.

### AD2: Undo first, mutation where undoing proves nothing

Undoing the covered lines is the cheapest red and shows the test exercises the change. Where there is nothing to undo to (new code whose absence only errors, a refactor, a characterisation test, a "no change to" criterion), a mutation of any line the test covers stands in, including lines outside the story, and a wrong-value stub counts. The scratch-copy revert keeps either from touching anything else uncommitted. Rejected: mutation for every criterion (cost on every story).

### AD3: The auditor reads the red result; it does not reproduce it

The auditor is read-only and a copied source file is not what the autoloader or test runner loads, so reproducing a red means editing the checkout the lead is using. It checks instead that the recorded red names the cited assertion and an undo or mutation that assertion depends on. Rejected: the auditor re-running one red per story in a worktree under its scratch directory (needs a dependency install per audit; recorded as Won't Have, and worth revisiting if recorded reds prove unreliable).

### AD4: Lessons are traced on the epic header

`plan` names the lessons applied on the epic header, so `review` can check them without re-deriving which lessons bear on the epic. Rejected: a per-story field (most lessons apply to an epic's area); spec Assumptions only (not read by `review` alongside the stories).

### AD5: Proof is routed by tag, set at plan time

Who can prove a criterion is known when it is written, so `plan` sets it and `do` follows it. `[user]` is a new tag rather than a change to `[manual]`, because `[manual]` steps are ones `do` carries out today, and in-flight epics in other projects hold over 200 `[manual]` criteria. Rejected: `do` deciding at build time.

### AD6: claude-in-chrome is the fallback browser tool, on local hosts, by the lead

The user chose claude-in-chrome against the local app, attended or unattended, on 2026-10-30. A repo's own browser tests are preferred because they rerun with the suite. The lead alone drives it because subagents may not have the browser tools. Only `localhost`, `127.0.0.1` and `.test` hosts count as local, since a "development" URL can be deployed and hold real data; `do` uses a server that is already running and does not start one, since a server takes a port.

## Scope

### In Scope

The five files named in the Problem Summary, `cpm-next/skills/{status,library,party}/SKILL.md` and `cpm-next/skills/do/worktree.md` for FR19-FR21, the cpm-next README log with its upgrade note, the plugin and marketplace versions, and a maintenance record of the claude-in-chrome dependency in `docs/maintenance/README.md`.

### Out of Scope

Changes to any project's docs or library; back-filling tags on existing epics; the mods.

## Testing Strategy

The skills are prose; there is no automated suite for them. Each requirement is verified by reading the changed file against the requirement, with `grep` for the required terms (`[manual]`, carried out by `do` and checked by the auditor). NFR1 is checked with `wc -w` on the five files, NFR3 with `claude plugin validate cpm-next`. The mods' suites (`bun test` in `cpm-next-models/hooks`, `cpm-next-progress/hooks`, `whats-next/hooks`) are run once to show no parser broke. Behaviour in a live run can only be seen through an installed release in another project, so it is the final user-checks epic, `47-06`. Commit `2f406b1` is the baseline for every before-and-after count.

## Assumptions

- The cross-project evidence comes from two agents' skims of retros (counts approximate); no retro names a cpm-next instruction as wrong, so the requirements are inferences from failure classes.
- cpm-next reads every library document regardless of `scope`, so the gap FR6 and FR7 close is that lessons are read but criteria are not checked against them.
- "Promote on the second occurrence" from the discussion becomes FR16's report, not an automatic promotion, because the discussion rejected auto-promotion. "Repeats" means the earlier source describes the same failure, and the bullet cites it so the user can judge.
- A recorded red can still be fabricated; AD3 accepts that the auditor checks its plausibility rather than reproducing it.
- An unattended claude-in-chrome check can stall on a site-permission prompt; the once-per-run connection check does not detect that.
- One release (cpm-next 0.9.0) at the end, not one per epic, because most epics edit `do/SKILL.md` and the contract.
- A story waiting on the user keeps its status, so `whats-next` and the progress tracker, which pick by status alone, show it as next; the mods are out of scope, so this is recorded in the maintenance record and the upgrade note.
- `[user]` criteria in a final epic, rather than a closing story per epic, keep an epic waiting on the user from stalling the epics that depend on it, with no change to the contract's dependency rule or the mods.
- The challenge pass (Tomas, Bella, Ren) found FR1 and FR3 duplicating existing rules, the auditor unable to mutate a scratch copy, audits running in parallel past FR9, and `[user]` criteria stalling dependents; each is folded in above.
- The fixes made after release (FR17-FR21) were written outside an epic and their last fix round was not audited; epic 47-07 holds them so `do` records Evidence and audits each, finding the code already written (user's decision, 2026-10-30).
- NFR1 was 10% over the baseline; the user raised it to 10,300 words when trimming further meant deleting rules.
