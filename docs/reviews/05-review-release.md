# Review: Release cpm-next 0.9.0

**Date**: 2026-10-30  
**Source**: docs/epics/47-05-epic-release.md  
**Reviewers**: Ren, Sable, Elli  
**Findings**: 15 (3 critical, 9 warnings, 3 suggestions)

## Summary

Checks were run on HEAD `2f406b1`:

- `wc -w` gives 8,225, so the baseline is correct.
- `claude plugin validate cpm-next` reports no errors.
- The mod suites pass under `claude plugin test`: cpm-next-models 18/18, cpm-next-progress 46/46, whats-next 18/18.
- `bun` is not on PATH, so the `bun test` criterion could never pass.

The upgrade note still reflected the spec before review: it said `[manual]` keeps its meaning, which 47-04 no longer makes true, and it left out most changes that affect in-flight epics. The `[user]` story sat inside the release epic, against the user-checks-epic rule. Everything is fixed except NFR1's word budget, which the amended epics will probably exceed and which waits on the user.

## Findings

- **[Critical]** 📅 **Ren**, ✍️ **Elli**: the note says `[manual]` keeps its meaning, but 47-04 Story 3 treats a `[manual]` deploy, production run or sign-off as `[user]`  
  → Story 1, criterion 1
- **[Critical]** 📅 **Ren**, ✍️ **Elli**: the note leaves out changes that affect in-flight epics: reds on resume, a missing red as a Warning, the `[user]` form, waiting stories skipped, the user-checks epic, `**Lessons**` and `**Recurrence**`, scratch directories, the auditor running no tests in an unisolated suite, claude-in-chrome, and no back-fill  
  → Story 1, criterion 1
- **[Critical]** ⚙️ **Sable**: `bun` is not on PATH here; the repo runs mod suites with `claude plugin test`  
  → Story 1, criterion 7
- **[Warning]** 📅 **Ren**: the `[user]` story belongs in a final user-checks epic, and it would keep the release epic open after shipping  
  → Story 2
- **[Warning]** 📅 **Ren**, ⚙️ **Sable**: no step pushes to `main` or confirms the update reached the install  
  → Story 2
- **[Warning]** 📅 **Ren**, ✍️ **Elli**: spec FR9 and FR11 still disagree with the user's review decisions, and nothing checks this before release  
  → Story 1
- **[Warning]** 📅 **Ren**, ⚙️ **Sable**, ✍️ **Elli**: "the commit before epic 47-01" is undefined, since `do` leaves commits to the user  
  → Story 1, criteria 4-5 (and the controls in 47-01 and 47-02)
- **[Warning]** ⚙️ **Sable**: `wc -w` cannot run on a commit  
  → Story 1, criterion 4
- **[Warning]** ✍️ **Elli**: the maintenance record omits the tool names, ToolSearch, `APP_URL`, the host rule, the package names, the scratchpad fallback, the permission-prompt stall and the new contract strings  
  → Story 1, criterion 3
- **[Warning]** 📅 **Ren**, ✍️ **Elli**: `whats-next` and `cpm-next-progress` pick by status alone, so they show a waiting `[user]` story as next; this is unrecorded  
  → Story 1
- **[Warning]** ✍️ **Elli**: the maintenance record's layout is not required  
  → Story 1, criterion 3
- **[Warning]** ⚙️ **Sable**: NFR1's 10% limit (822 words) is probably exceeded: the amended epics' criteria add about 1,640 words, and no story trims anything  
  → Story 1, NFR1
- **[Suggestion]** 📅 **Ren**, ⚙️ **Sable**: target versions (marketplace 4.0.4; other plugins unchanged) are unstated  
  → Story 1, criterion 2
- **[Suggestion]** ✍️ **Elli**: make the history check runnable, and use one `**Name** (0.9.0):` bullet per change  
  → Story 1
- **[Suggestion]** 📅 **Ren**: give the live check's exact prompt  
  → Story 2

## Remediation

- Fixed: `[manual]` exception → the note states it
- Fixed: incomplete note → one bullet per change, with every change listed in criterion 2
- Fixed: `bun` → `claude plugin test` for each mod, tagged `[manual]`
- Fixed: `[user]` story → moved to a new final epic, `docs/epics/47-06-epic-user-checks.md`, which no epic depends on
- Fixed: push and install → 47-06 Story 1's first criterion has the user push, confirm `.git/plugin-update.log` and `claude plugin list`, and start a new session
- Fixed: spec drift → Story 1's first criterion stops the release until FR1, FR9 and FR11 read as built
- Fixed: baseline commit → pinned to `2f406b1` in the epic header
- Fixed: `wc -w` on a commit → `git show 2f406b1:{path} | wc -w`
- Fixed: maintenance record → names every coupling listed, in the file's existing layout
- Fixed: mods showing waiting stories → recorded in the maintenance record and the upgrade note
- Fixed (applied with their Warnings): target versions; a runnable history check; the bullet style; the live check's prompt
- Needs you: NFR1 budget → user chose (2026-10-30) to keep 10% and trim; Story 2 added to cut existing text until the total fits, with every cut listed and no rule lost; Story 1 is blocked by it
- Not acted on: the 0.8.8 `do` that builds 47-06 does not know `[user]` → the epic's header and every criterion say the user carries them out and `do` writes no `Evidence` of its own
