# Retro: Retire the Mirrors

**Date**: 2026-07-25
**Source**: docs/epics/41-04-epic-retire-mirrors.md
**Stories**: 3/3 complete

## Summary

The faithful-render mechanism is gone — three skill sections, three write paths, one test suite, three validators — and the companion-asset carve-out it sat beside survived intact. All seven coverage rows verified; the runner is green at 22 suites with no new failures against a baseline captured before any deletion.

The epic's lesson is about **deletion stories specifically**: three of its criteria could not be verified as written, and all three failed the same way — the breakdown reasoned about a repo state that had already moved. A deletion criterion is unusually brittle because its subject may already be gone, may have moved, or may be re-created by the same story.

## Observations

### Criteria Gaps

- **A deletion criterion's premise expires faster than the criterion does.** Three failed here. (1) Task 1.2's storage row had already been removed by epic 41-01 — the task had no work, and a reader of the diff will find no deletion where the criterion promises one. (2) Task 2.3's premise that `check_communication_path` "is referenced by `present`'s test suite" was one epic stale: the caller was `test-present-html.sh`, deleted in 41-02. (3) The suite-count criterion — "one fewer suite than the pre-story baseline" — is arithmetically unsatisfiable by a story whose own Task 2.4 adds a suite; 22 − 1 + 1 = 22. None of the three is a wrong *intention*; all three are correct intentions whose stated observable had stopped matching the repo. Verifying a criterion's **premise** at hydration — does this thing still exist, does this caller still call it, does this story also add one? — costs one grep each and would have caught all three before the gate.

- **A `git diff` criterion protects nothing after the commit.** Story 3's guard was phrased as "`git diff` shows no change to…", which is true only for as long as the work is uncommitted. It is exactly backwards from where the risk is: the carve-out becomes vulnerable *after* this chain lands, when a later sweep meets an exception it has no reason to keep. Converted to five assertions naming the rules the blocks carry. Any criterion whose oracle is the working tree is a criterion with a shelf life measured in one commit.

### Scope Surprises

- **A skill's frontmatter `description` is a site every output-changing story touches.** `architect`'s still advertised *"an on-request HTML render"* after the section was deleted — caught by the end-to-end read, not by the zero-hit grep, which was scoped to the heading and the write path. This is the **fifth consecutive epic** where the named sites were not the only sites, and the **second** where the straggler was a frontmatter description (41-02 hit the same thing in `status`). The pattern is now specific enough to be a rule rather than a lesson: the `description` field summarises what the skill produces, so any story that adds or removes an output has a frontmatter edit in it whether its criteria say so or not.

### Codebase Discoveries

- **A retro's recommendation can name the right action for the wrong reason.** Retro 16 recommended reworking `test-dashboard-export.sh` "because 41-04 prunes `check_uses_shared_template`". That validator was never pruned and keeps a live caller in `test-companion-assets.sh` — companion assets retain the shared template under R6, so it has a subject and a user. The suite did need reworking, but because its *fixture* modelled a local template-built document that the pivot retired, not because a validator vanished underneath it. The recommendation survived contact with the facts; its justification did not. Worth carrying: when acting on a prior retro's recommendation, re-derive the reason rather than inheriting it.

- **Removing a validator needs an inverse assertion, not just an absence one.** "No file references `check_render_path`" is satisfied equally by a clean prune and by an over-prune that removed the caller too. `test-suite-prune.sh` therefore asserts the nine surviving validators present *by name* alongside the three removed ones absent. Absence assertions cannot distinguish "gone as intended" from "gone too far".

### Patterns Worth Reusing

- **Capturing the baseline before touching anything made "no new failures" a real criterion.** Retro 14's lesson, applied as Task 2.1. The baseline (22 suites, all green, exit 0) turned the post-story comparison into arithmetic rather than judgement, and it is what let the suite-count discrepancy be diagnosed as a criterion defect in seconds rather than investigated as a regression.

- **A boundary that explains itself survives the sweep that would remove it.** The companion-asset carve-out came through four epics of deletion untouched, and `cpm:do` was not edited at all. R6 was written with its mechanism attached — *"a URL would make a pipeline step depend on network reachability"* — not as a preference. An exception stated as a preference reads as an oversight to the next editor; an exception stated with its failure mode reads as load-bearing.

## Recommendations

- **At hydration, verify each criterion's premise, not just its intent.** For deletion stories especially: does the target still exist, does the named caller still call it, does this story also create the thing it counts? Three of this epic's criteria failed this check, each catchable by one grep.
- **Never phrase a durable guard as a `git diff` assertion.** Diff-based criteria are fine for confirming a story did not touch something during execution; they are worthless as protection afterwards. Pair every one with an assertion naming the rule it protects.
- **Add the frontmatter `description` to the standard edit surface for any story that changes a skill's outputs.** Two of five epics found it stale; it is cheaper as a checklist item than as a retro observation.
- **When acting on a prior retro's recommendation, re-derive its reasoning.** Retro 16's rework recommendation was right and its premise was wrong; inheriting the premise would have produced the wrong rework.
- **Spec 41 is one epic from done.** Epic 41-05 (documentation and 3.1.0 release) should carry retro 17's open item — three wordings of the earns-its-place heuristic now coexist in `spec` and `architect` — and retro 14's release discipline of grepping every site of the version string before bumping.
