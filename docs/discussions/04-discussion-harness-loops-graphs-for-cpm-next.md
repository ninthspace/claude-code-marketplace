# Discussion: What "Harness, Loops, Graphs" teaches cpm-next

**Date**: 2026-10-30  
**Participants**: Margot (Software Architect), Bella (Senior Developer), Casey (Test Engineer), Ren (Scrum Master)  
**Status**: Concluded

## Context

Source: m4lka, "Harness, Loops, Graphs: What Each Layer Fixes and What It Breaks" (X article, 2026-10-25), read from `~/Downloads`. Its claims, as used here:

- Three jobs a person quietly does for an agent: give it a place to work (harness), tell it whether it was right (loop), decide what happens next (graph). Seven levels, each added because the one below breaks in a known way.
- L2 memory and walls: state outside the context window; limits that hold when the model is wrong (permissions, not prompts).
- L3 check: a check is as strong as the weakest thing it accepts as proof. Evidence ladder: deterministic, observable, independent, self-report. The check must be seen to fail once before the fix.
- L4 feedback: expected vs saw, a fence, dead ends, exits (same result twice means stop and escalate; budget spent means stop).
- L5 shape: split where things fail separately, give each worker its own context, code for same-answer steps, gate where work leaves a node.
- L6 gates: freeze what passed; gate on the price of undo (one-click, cleanup, no undo), not on model confidence; the model labels the change, code decides what the label unlocks.
- L7 learning: each failure becomes a lesson on the layer that owns it (a tool, a never-list entry, a required check, a split rule), stored as a constraint and never as a transcript.

Where cpm-next stands (read from `cpm-next/skills/*`, `cpm-next/README.md`, `docs/retros/07-10`):

- L2: epic doc is the memory. Subagents are told what to leave alone by prompt, which the article calls a wish; nothing is a permission.
- L3: per-criterion `Evidence`, an independent Opus auditor with no conversation context. No rule that a criterion's test is shown failing before the change. Retros 07-10 record four checks that could not fail (a must-NOT whose control lived in another criterion, checks not running, reads that succeed on the wrong thing).
- L4: audits are capped at two, three for a Critical. `Not met` records what was tried. No expected/saw record, no rule that an identical failure twice stops the story, no per-story budget.
- L5: `Blocked by` is "real ordering only"; parallel stories are in separate subagents; worktree mode exists. Close to the article's early-start test already.
- L6: `**Effort**` is set by cost of a mistake, but audit rounds and approval are the same for every story. "Destructive stops the run" is the model's judgement at run time.
- L7: `do` writes retros; `library learn` promotes lessons only when the user chooses them; `do` skims retros as context. Lessons land as prose in `lessons-learned.md` regardless of which layer owns them.

Two goals from the user: (a) change existing skills to reflect what running cpm-next in several projects has shown; (b) make cpm-next more autonomous and self-learning, split between the plugin and each install.

## Evidence from other projects

Two read-only agents skimmed retros, library and epic markers in 15 of the 23 repos that have cpm artefacts (grep and targeted reads; counts approximate). Most retros outside ice-analytics predate cpm-next and say `/cpm:do`; no retro names a cpm-next skill instruction as wrong, so the plugin changes below are inferences.

Seen in two or more repos (point at the plugin):

- **Checks that cannot fail**: ice-analytics 25+ retros, ice about 14, ice-services 4, shortbread 2, hlh-performance 1, hlh-net-promoter-score 1. Recurred after promotion to the library (ice-analytics retro 17).
- **Lessons recur and are not enforced**: ice-analytics library entry is `scope: do` only, so `plan` and `review` never read it; "record this" recommendations were not recorded (retro 44); the factory-audit lesson recurred in ice 05 and ice-services 01; the unattended-gate lesson in ice and ice-coupons.
- **Test-run and scratch collisions**: two PHPUnit processes on one fake disk (ice 16); a `--parallel` gate that cannot pass (ice-coupons 12-14); auditor scripts overwriting the lead's in a shared scratchpad (ice-analytics 76, 88).
- **Spec drift left as `**Pivot deferred**`**: ice 24, ice-analytics epics 23-02, 34-01, 34-03, 43-01, hlh-net-promoter-score 10. The user must run `plan` by hand to clear them.
- **Criteria naming an instance instead of the rule**: ice 10 and 12, hlh-net-promoter-score 12 and 13.
- **Proof that cannot run in the session** (manual prod run, browser-only form, deploy): ice-services 02, ice 24, castle 02-06.

Single project:

- ice-analytics: a wrong premise that looks clean (empty join read as "none"); a Provisional decision whose decider is a later skill; structural-move epics where mutation records keyed on line numbers go stale after the simplifier pass; about 9 audits on story 43-03, almost all "pass, one finding fixed", while a three-finding remainder was fixed unaudited.
- castle: seven stories where the second audit returned `fix needed`; its review before epics was well spent.

No clear evidence of loop stop-rule failures or dependency-error classes in either report, so levels 4 and 5 are not backed by the data.

## Decisions

Build these four changes, in this order (user, after round two):

1. **Red-first check rule** — Casey: a tagged test is shown failing against the pre-change code, or by a mutation, and the auditor names criteria that pass without the new code. Backed by the cross-repo "checks that cannot fail" class, which recurred after library promotion.
2. **Library enforcement in `plan` and `review`** — Margot: lessons are checked against criteria before `plan` writes and `review` approves; promotion on a second occurrence. ice-analytics' lesson entry was `scope: do` only.
3. **Per-auditor scratch directory** — Bella: each auditor gets its own scratch subdirectory; `do` records the repo's test-run rule and never runs two suites at once.
4. **Criteria tagged manual or browser-only** — `plan` tags them up front so they route to **Needs you** rather than being claimed as met. User's constraint: browser-only proof can be realised through a repo's own browser test tools (Dusk, Playwright) or through claude-in-chrome, so the tag must not assume one.

Part (b), autonomy and self-learning, is split: the plugin owns the mechanisms above; each install owns its lessons (`docs/library`, retros, allowlists).

## Open Questions

- Red-first for criteria that no test can prove (manual, browser) and for stories that add a test over unchanged code: what counts as the control?
- How `plan` and `review` match a library lesson to a criterion without reading every entry each time.
- What "second occurrence" means mechanically: same retro observation text, a shared tag, or the user's call in `library learn`.
- Whether `do` should drive claude-in-chrome itself when a browser-only criterion has no repo tool, or leave it to **Needs you**.

## Positions Not Taken

- Undo tiers on stories, with code deciding what a tier unlocks — Margot still favours; Ren and Bella say the retros give no evidence of gate failures that undo tiers would fix.
- Hard per-story fence enforced as a permission — Bella: breaks when a story legitimately touches a neighbour file; use a recorded `**Touches**` list that the auditor checks if breaches appear.
- Audit rounds scaled by `**Effort**` and skipped audits as **Needs you** items — Ren; ice-analytics 43-03 had about 9 audits with low yield. Not in the user's four, so not decided.
- Loop stop rules (identical failure twice) and graph changes — neither report found evidence.
- Auto-promoting lessons without the user choosing — Bella: fills the library with advice nobody reads.

## Recommended Next Step

`/cpm-next:plan docs/discussions/04-discussion-harness-loops-graphs-for-cpm-next.md`
