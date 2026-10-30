# Release cpm-next 0.10.0

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 48-01-epic-signal-contract, Epic 48-02-epic-signals-in-do, Epic 48-03-epic-plan-review-status, Epic 48-04-epic-library-learn, Epic 48-05-epic-library-sweep, Epic 48-06-epic-planning-hygiene  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

## Release with an upgrade note
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 3 findings fixed — the round-2 Warning, a `Not met` line added in error, was removed after the last audit  
**Blocked by**: —  
**Satisfies**: NFR1, NFR2, NFR3

**Acceptance Criteria**:

- `cpm-next/README.md` gains one `(0.10.0)` bullet for each epic 48-01 to 48-06, and the `library` row of its command table names `sweep` `[manual]`
  - Evidence: `cpm-next/README.md` Additions holds one `(0.10.0)` bullet for each epic 48-01 to 48-06 (signals and class-keyed lessons in the contract; `do` records signals; `do` finds recurrences; `plan`, `review` and `status` read what recurred; `library learn`; `library sweep`; rules not instances and Pivot deferred) plus a Size bullet, and the `library` row of the command table (`:10`) names `sweep` — red: n/a — manual
- The upgrade note tells the user to run `/cpm-next:library learn` on existing retros; says that `library sweep` reads other repositories, which raises permission prompts, and that with one repository process signals appear only under **Found**; and says that a user's own instructions naming "Retro" items (for example a progress-tracker rule) should name promotion candidates and **Found** items instead `[manual]`
  - Evidence: `cpm-next/README.md` section "Upgrading to 0.10.0": run `/cpm-next:library learn` on existing retros; `library sweep` reads other repositories, which raises permission prompts, and with one repository process signals appear only under **Found**; a user's own instructions naming "Retro" items (a progress-tracker rule) should name promotion candidates and **Found** items — red: n/a — manual
- `cpm-next/.claude-plugin/plugin.json` and the cpm-next entry of `.claude-plugin/marketplace.json` read `0.10.0` and describe library as promoting recurring lessons; the marketplace reads `4.0.5`; the other plugins' versions are unchanged `[manual]`
  - Evidence: `cpm-next/.claude-plugin/plugin.json` and the cpm-next entry of `.claude-plugin/marketplace.json` read `0.10.0` and describe library as "promoted recurring lessons and a cross-repository sweep"; the marketplace reads `4.0.5`; `git diff 70c789c -- .claude-plugin/marketplace.json` shows only those version and description lines, so the other plugins' versions are unchanged — red: n/a — manual
- The root `README.md` line listing `docs/` folders describes `retros/` as legacy, read by `library` `[manual]`
  - Evidence: the root `README.md` line listing `docs/` folders now ends "`reviews/`, `quick/` and `library/`, with legacy `retros/` read by `library`" — red: n/a — manual
- `docs/maintenance/README.md` gains a record of `~/.claude/cpm-next/repos.txt`, the new contract strings (`**Signal**`, ` — recurs:`, ` — raised`, ` — promoted`, ` — declined`, `**Class**`), and which fields the mods' parsers read (`Story`, `Task`, `Status`, `Blocked by`, `Effort`, `Source spec`) and that they ignore the rest `[manual]`
  - Evidence: `docs/maintenance/README.md` records `~/.claude/cpm-next/repos.txt` ("The sweep's repository list"), the contract strings (`**Signal**` with ` — recurs:`, ` — raised`, ` — promoted`, ` — declined`, and `**Class**`), and the fields the mods' parsers read, the rest being ignored ("Unknown fields in the mods") — red: n/a — manual
- The README's 0.10.0 entry records `wc -w` over `do`, `plan`, `review`, `library`, `status`, the auditor and the contract before (10,978 at `70c789c`) and after; no limit applies `[manual]`
  - Evidence: the README's Size bullet records `wc -w` over `do`, `plan`, `review`, `library`, `status`, the auditor and the contract as 10,978 at `70c789c` (reproduced here with `git show 70c789c:{path}`) and 12,748 now; no limit applies — red: n/a — manual
- `claude plugin validate cpm-next` reports no errors, and `claude plugin test` passes for `cpm-next-models`, `cpm-next-progress` and `whats-next` `[manual]`
  - Evidence: `claude plugin validate cpm-next` — Validation passed; `claude plugin test` passes for `cpm-next-models` (18), `cpm-next-progress` (46) and `whats-next` (18); added lines of `git diff -U0 70c789c -- cpm-next/skills cpm-next/agents cpm-next/shared` read, the history grep returning one line, the **Sweep** rule line in `library/SKILL.md`, which is a rule — red: n/a — manual

**Amended**: the size criterion records the before and after counts with no limit (2026-10-30) — cited: the user's decision in review 06 (docs/reviews/06-review-learning-at-recurrence.md)

**Inline change**: criterion 5 names the fields the mods read as `Story`, `Task`, `Status`, `Blocked by`, `Effort` and `Source spec`, and `Withdrawn` and `Superseded by` in specs (2026-10-30)
**Pivot deferred**: spec AD1's statement that the parsers read only `Status`, `Blocked by` and `Source spec` is incomplete (it omits `Story`, `Task`, `Effort`, `Withdrawn` and `Superseded by`) → docs/specifications/48-spec-learning-at-recurrence.md (Story 1, 2026-10-30) — cited: `whats-next/hooks/plan.ts:98` and `cpm-next-progress/hooks/progress.ts:109`

### Write the README entries, versions and maintenance record; run the checks
**Task**: 1.1  
**Description**: Edit `cpm-next/README.md`, the two JSON files, the root `README.md` and `docs/maintenance/README.md`, and run the commands.  
**Status**: Complete

---
