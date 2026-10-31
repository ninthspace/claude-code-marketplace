# Release cpm-next 0.11.0, whats-next 0.3.0, cpm-next-progress 0.8.0

**Source spec**: docs/specifications/49-spec-cheaper-red-first-evidence.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: Epic 49-01-epic-red-passes, Epic 49-02-epic-auditor-checks, Epic 49-03-epic-commit-guard, Epic 49-04-epic-waiting-on-user, Epic 49-05-epic-browser-checks

## Release with an upgrade note
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 3 findings fixed
**Blocked by**: —  
**Satisfies**: FR15, NFR1, NFR2, NFR3  
**Amended**: the last criterion adds the `tsc` result and its two known errors (2026-10-31) — cited: `cpm-next-progress/hooks/register.ts:551` and `:557` (`isDeferred` is not in `ToolSpec` of the types laid for the installed engine), in lines this spec did not change  
**Pivot deferred**: reword NFR3's "`tsc -p` passes for `cpm-next`, `whats-next` and `cpm-next-progress` once their types are laid" to allow the two `isDeferred` errors in `cpm-next-progress/hooks/register.ts` that this spec did not change → docs/specifications/49-spec-cheaper-red-first-evidence.md (Story 1, 2026-10-31) — cited: `cpm-next-progress/hooks/register.ts:551` and `:557`
**Signal**: spec-drift — project — the criteria listed no `tsc` check for NFR3, whose clause the cpm-next-progress types cannot meet (`cpm-next-progress/hooks/register.ts:551`, audit round 1)  
**Signal**: fix-not-carried-through — project — the root README's What's Next section was left describing the old pane, band, order and reads (`README.md:205-228`, audit rounds 1 and 2) — promoted 2026-10-31

**Acceptance Criteria**:

- `cpm-next/README.md` gains one `(0.11.0)` bullet for each epic 49-01 to 49-05, and an "Upgrading to 0.11.0" note saying that reds run in passes kept under `.git/cpm-next/scratch/`, that a commit through Claude is refused while one is open, and that the `whats-next` and `cpm-next-progress` updates are needed for waiting stories to show correctly `[manual]`
  - Evidence: `cpm-next/README.md` Additions now holds `(0.11.0)` bullets for 49-01 (Red passes; `existing` reds), 49-02 (Auditor checks and the suite-free handshake), 49-03 (Commit guard), 49-04 (Waiting on you, in the mods) and 49-05 (Browser checks said early), plus a Size bullet; a section "Upgrading to 0.11.0" says reds are taken in passes kept under `.git/cpm-next/scratch/`, a `git commit` through Claude is refused while a pass for that checkout is open, and `whats-next` and `cpm-next-progress` must be updated too — red: n/a — manual
- The root `README.md` sections for `whats-next` and `cpm-next-progress` describe the "Waiting on you" group and `Waiting on input` for stories waiting on the user (its Statuses list and the `waitingOn` description included), and the line saying cpm-next is skills only, if any, names the commit guard `[manual]`
  - Evidence: root `README.md` — the plugin table's `cpm-next` row reads "Skills and agents, and a commit guard (a hooks module)" and the `whats-next` row "Mod, adds `/next` and lists the stories waiting on you apart from those to build"; the `waitingOn` description ends "until it is removed from the file"; the Statuses line lists "Waiting on input (a `waitingOn` item, or an unblocked story, not marked blocked, whose only criteria without `Evidence` are `[user]` or carry a `- Waiting on user:` line, whether Pending or In Progress)"; the What's Next section describes the **Waiting on you** block in the pane (with `(your check)` after a dependency that is a story waiting on you), the band's waiting line when nothing is left to build, the order of execution (waiting stories leave it), the next-steps note, and the criteria fields it reads — red: n/a — manual
- `cpm-next/.claude-plugin/plugin.json` and the cpm-next entry of `.claude-plugin/marketplace.json` read `0.11.0` and mention the commit guard; `whats-next` reads `0.3.0`, `cpm-next-progress` `0.8.0`, the marketplace `4.0.6`; `git diff` on `marketplace.json` shows no other plugin's version changed `[manual]`
  - Evidence: `git diff -- '*/.claude-plugin/plugin.json' .claude-plugin/marketplace.json`: cpm-next 0.10.0 → 0.11.0 in both files with the description ending "and a commit guard that refuses a git commit while a red pass is open", whats-next 0.2.4 → 0.3.0, cpm-next-progress 0.7.2 → 0.8.0, the marketplace 4.0.5 → 4.0.6; no other plugin's version line changed — red: n/a — manual
- `docs/maintenance/README.md` amends the "Scratch location" and "Waiting stories in the mods" records so neither describes the old behaviour, and records the scratch path, the `- Waiting on user:` line, the criterion grammar, `red: n/a — existing`, and that cpm-next ships a hooks module `[manual]`
  - Evidence: `docs/maintenance/README.md` — "Scratch location" now describes the pass directory under the git common directory and the guard that reads it; "Waiting stories in the mods" describes the shared criterion grammar, the `- Waiting on user:` line and the identical `hooks/fixtures/waiting.ts` copies; the contract-strings record lists `red:`, `red: n/a — existing (reaches …)` and the `- Waiting on user:` line (and no longer `green after restore`); a last record says cpm-next ships a hooks module — red: n/a — manual
- The README's 0.11.0 entry records `wc -w` over `do`, `worktree.md`, the auditor, `status` and the contract at `134ece1` and after; no limit applies `[manual]`
  - Evidence: the README's Size bullet: `wc -w` over `do`, `worktree.md`, the auditor, `status` and the contract is 8,873 at `134ece1` (`git show 134ece1:{path} | wc -w`: 4,219 + 507 + 1,251 + 751 + 2,145) and 10,771 now (counted again after the sweep suggestion was added to `do` and `status`); no limit applies — red: n/a — manual
- The added lines of `git diff 134ece1 -- cpm-next/skills cpm-next/agents cpm-next/shared` are read and none records history `[manual]`
  - Evidence: the added lines of `git diff -U0 134ece1 -- cpm-next/skills cpm-next/agents cpm-next/shared` were read and searched for history wording (used to, formerly, previously, no longer, earlier, old, review and audit references, version numbers); the hits are rules ("a path that no longer exists", "a retaken red replaces the earlier one", "per audit round", an IP address), none a record of how a rule came to be — red: n/a — manual
- `claude plugin validate` passes for `cpm-next`, `whats-next` and `cpm-next-progress`; `tsc` prints no error for `cpm-next/hooks` and `whats-next`, and for `cpm-next-progress` only the two `isDeferred` errors in `register.ts` that this spec's changes did not touch; `claude plugin test` passes for `cpm-next`, `cpm-next-models`, `whats-next` and `cpm-next-progress`; `cmp` reports the two waiting fixture sets identical; cpm-next loads headless under every engine installed on the machine with its skills listed `[manual]`
  - Evidence: `claude plugin validate` — Validation passed for cpm-next, whats-next, cpm-next-progress and cpm-next-models; `claude plugin test` — cpm-next 15, cpm-next-models 18, whats-next 32, cpm-next-progress 54 pass, 0 fail; `tsc` printed nothing for `cpm-next/hooks` (a scratch tsconfig against another plugin's laid types: cpm-next has none laid) and for `tsc -p whats-next`, and for `tsc -p cpm-next-progress` two errors, `isDeferred` not in `ToolSpec` at `register.ts:551` and `:557` (`git diff -U0 cpm-next-progress/hooks/register.ts` has hunks only at lines 69, 109 and 356); `cmp` on the two `hooks/fixtures/waiting.ts` copies printed nothing; cpm-next loaded headless under engines 2.1.301, 2.1.306, 2.1.309, 2.1.310, 2.1.311, 2.1.312 and 2.1.314, each listing cpm-next:do, library, party, plan, review and status, and the 2.1.314 debug log shows `hooks module cpm-next@inline loaded … events: tool.call` — red: n/a — manual

### Write the READMEs, versions and maintenance record; run the checks
**Task**: 1.1  
**Description**: Edit the READMEs, the JSON files and `docs/maintenance/README.md`, and run the commands.  
**Status**: Complete

---
