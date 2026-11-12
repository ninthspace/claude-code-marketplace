# Discussion: cpm-next optimisation survey

**Date**: 2026-11-12  
**Participants**: the user; four read-only survey agents (do and worktree; the contract and fixed.md; test-runs and the agents; plan, review, library, status and party)  
**Status**: Concluded

## Context

Since 0.15.0 `do/SKILL.md` grew from 6,415 to 7,989 words, and `plan`, `review`, the contract and the auditor grew 12–35%. Specs 56 and 57 each added rules under floors that kept every earlier sentence verbatim, and their audits kept finding the same classes (`fix-not-carried-through`, `procedure-gap`, `definition-in-two-places`). The user asked whether the plugin as a whole could be optimised. A survey of every skill, agent and shared file looked for repeated rules, unreachable clauses, history, long passages that bullets would shorten, inconsistencies, and rarely-run text that could load on demand. It changed no file. Line numbers below are as of 479c406.

## Findings: size

| Area | Cut outright | Moved to an on-demand file |
|---|---|---|
| `do/SKILL.md`, `worktree.md` | ~1,050 | ~1,150 (Independent tests ~620, `[browser]` handling ~350, small change ~210) |
| `shared/artifacts.md`, `shared/fixed.md` | ~900 (fixed.md's 18 rows at or below 0.11.0 ~540: signals carry a version only from 0.12.0, so no row at or below it can cover one) | — |
| `shared/test-runs.md`, `auditor.md`, `test-writer.md` | ~1,050 | ~170 (the auditor's independent-test checks, for marked stories only) |
| `plan`, `review`, `library`, `status`, `party` | ~600 | ~1,080 (library's Sweep ~910, Back-fill and Consolidate ~170) |

About 3,600 words can go and 2,400 more load only when needed. A `do` run (do, the contract, test-runs) would read ~3,100 fewer words (~22%), and each audit ~960 fewer. Almost no history was found; the bulk is rules restated from the file that owns them (the contract, `test-runs.md`, the auditor), and single-line paragraphs (step 5, the resume bullet, plan's **Epics**, the deferred full run, auditor check 5) that parallel bullets shorten.

Highest-value cuts:

- **Restatement of `test-runs.md` in `do`** (the baseline paragraph, step 4's run bullet, step 5): ~200 words; also removes two summaries that contradict `test-runs.md`.
- **The deferred full run as bullets** (`test-runs.md:71-81`): ~260 words, read by `do` and every audit.
- **Auditor check 5 and "What you are given" restructured**: ~270 words on every audit.
- **The `existing` rule stated once**, in the contract (it is word for word in the contract, `do` and the auditor).
- **`fixed.md`'s inert rows deleted**: ~540 words on every sweep, with no change to what a sweep reports.
- **On-demand files**: `do`'s Independent tests and `[browser]` handling, library's Sweep, read under the triggers they already have, as `worktree.md` is.

## Findings: correctness (fix whatever happens to size)

1. **The unblocked rule differs.** `do:45` needs a blocker `Complete` with an `**Audit**` line; the contract (`:38`), `status` and both mods need only `Complete`. A foreign epic `plan` converts (`plan:60`) marks finished items `Complete` with no `**Audit**` line, so `do` never unblocks their dependents while `status` shows them ready.
2. **A resumed `fix due` story's audit is defined three ways.** `do:41` audits it "as a whole story, that audit being its scoped round"; `test-runs.md:77` and `auditor.md:60` make a scoped round audit the fix only; `do:99` counts whole-story audits and `do:101` says this one is not counted. Its auditor directory name (`do:111`, `r{n}`) is undefined.
3. **The auditor does not know two prompt kinds `do` sends.** `auditor.md` **What you are given** omits the files on the `**Independent tests**` line (`do:123`), and **A later audit** has no rule for a whole-story audit given only dismissed findings (`do:132`), so it may take the dismissed list as its scope.
4. **Test runs may overlap in one checkout.** `do:68` lets each subagent of a batch run its targeted tests when the suite is isolated; `do:115` says two test runs never overlap in one checkout. `do:113` checks isolation "before the first audit", after the fan-out that needs it.
5. **`fixed.md` is behind 0.18.0.** No `identity-key` rows for `do` step 4 and auditor check 6, which 0.18.0 changed; its `shared-assumption` row names "The loop", where the rule now sits in **Independent tests**.
6. **A stale `before the build` red passes the blob check.** After a writer's revision the line carries the new blob, so a red taken before the revision still matches (`auditor.md:24`); the check should also need no ` — revised` note for that file.
7. **The auditor's order-dependent Warning fires on a correct run.** After a failing targeted run, the reruns before the audit are targeted (`test-runs.md:62,65`), so `auditor.md:24` flags a run the rules require.
8. **The `existing` finding list omits a condition.** It leaves out "the test must have passed in the baseline", so a test that failed at baseline is a finding nowhere (contract `:170`, `do:56`, `auditor.md:24`).
9. **Pointers left by 0.19.0.** `test-runs.md:73,77` point to "step 5's rounds", which now live in `do`'s **Audit rounds**; the mismatch rule sits inside **A pass** though the comparison is made before the run.
10. **Smaller ones.** `status:21` looks for raised signals outside `docs/archive/epics/`, which `do` and `library` read; `review`'s `all` and no-argument scopes can pick a `Withdrawn` or `Superseded` epic; `library:38` leaves unmarked a signal whose match was declined, against the contract's `:208`; the contract's two `**Amended**` forms (`:185`, `:303`) are not said to apply where; `do:10` never tells a run to read the contract, though most "as the contract says" cuts rely on it; `test-runs.md:85` lists `audit: run too narrow` with no rule that uses it; `test-runs.md:5` says a full story takes a targeted run and then that it takes targeted runs before its audit.

## Decisions

- Run the survey read-only, and act on it through `/cpm-next:plan` — the user (2026-11-12).

## Open Questions

- Whether to take the correctness fixes and the consolidation in one spec or two.
- How far to move text into on-demand files: each file is one more read and one more place a rule can drift.

## Positions Not Taken

- **Moving shared rules (the `[user]` placement, the identity criteria, the Needs-you walk) into the contract.** Every skill would load more, and `fixed.md` rows and the test-writer point at `plan`'s **Epics**, so a sweep would stop matching future signals.
- **Trimming `review`'s checklist where it restates `plan`.** Its personas are subagents with no other copy.
- **Changing any parsed form, field placement or check number.** The mods, the commit guard and `fixed.md` rows depend on them.
- **Merging the red-pass manifest with the test-runs snapshot.** Their exclusions differ, and a restore depends on the manifest exactly.

## Recommended Next Step

`/cpm-next:plan docs/discussions/25-discussion-plugin-optimisation-survey.md`: a spec whose requirement is the same behaviour with less text, its correctness fixes first, each consolidation checked by walk-throughs of real epic histories against the old and new text, and a word target per file.
