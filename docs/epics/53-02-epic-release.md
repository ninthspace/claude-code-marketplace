# Release cpm-next 0.15.0

**Source spec**: docs/specifications/53-spec-plan-runs-the-review.md  
**Date**: 2026-11-10  
**Status**: Pending  
**Blocked by**: Epic 53-01-epic-plan-runs-the-review  
**Amended**: review 10 (docs/reviews/10-review-plan-runs-the-review.md) — a named base commit, the onboarding and command-table passages in the floor, a rule grep over the docs, the maintenance record for the review record `status` reads, the tag check described (2026-11-10)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 1), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (Story 1)

**Base.** `{base}` is the 0.14.0 release commit, as epic 53-01 names it; every diff below is `git diff {base} --`, and each `Evidence` line cites its hash.

## Release with the docs
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR8, NFR2, NFR3

**Acceptance Criteria**:

- `cpm-next/README.md` gains `(0.15.0)` bullets after the 0.14.0 bullets and an **Upgrading to 0.15.0** section, saying `plan` runs the review for a qualifying epic and `review` takes several epics or a spec's prefix; its skills table rows for `plan` and `review` (lines 8 and 11) are read and changed only where the finish line changes; `git diff {base} -U0 -- cpm-next/README.md` removes no line of an earlier entry `[manual]`
- Every passage that calls the review optional, tells the user to run it after `plan`, or gives its scope is updated to one phrasing: `plan` runs it for a qualifying epic, and you run it yourself for any other. `grep -n -i "review" README.md cpm-next/README.md cpm-next-training-guide.html cpm-next-onboarding.html cpm-next-presentation.html`, each hit read and accounted for. Floor: root `README.md` 13 and 92; the training guide's quick start (384), plan finishing passage (819), review section (831-853, including 835 and 851), review-record template (725), worked example (1345), pivot line (1360) and command table (1497-1498); onboarding 212, 253, 461-467 and 668; the presentation's review card (269) `[manual]`
- The docs restate no part of `plan`'s rule: `grep -n -i "unfamiliar" README.md cpm-next/README.md cpm-next-training-guide.html cpm-next-onboarding.html cpm-next-presentation.html` gives no hit (training guide 819 gives one at `{base}`), and the passages that name the review read beside it `[manual]`
- Each of the three HTML files passes a tag-balance check: a Python `html.parser` script in the scratchpad that pushes each start tag on a stack and pops it on the matching end tag, skipping void elements and counting a mismatch, gives 0 mismatches and 0 unclosed tags; control: the same script over `git show {base}:cpm-next-training-guide.html` gives 0 and 0 `[manual]`
- The three HTML files' version lines read cpm-next 0.15.0 and the current mod versions in `.claude-plugin/marketplace.json` `[manual]`
- `cpm-next/.claude-plugin/plugin.json` and its marketplace entry read `0.15.0`, the marketplace `4.0.11`; `git diff {base} -- .claude-plugin/marketplace.json` changes no other plugin's version line `[manual]`
- `cpm-next/README.md` gains a **Size** (0.15.0) bullet: `wc -w` over `plan`, `review` and `status` at `{base}` and after `[manual]`
- `docs/maintenance/README.md` gains a record that `status` reads the review record's **Source** and date, which `review` writes in the contract's form, so a change to either breaks the other; `shared/fixed.md` is unchanged (`git diff {base} --stat -- cpm-next/shared/fixed.md` is empty) `[manual]`
- `claude plugin validate cpm-next` and `claude plugin validate .` pass `[manual]`
- `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next `[manual]`

### Write the docs and versions; run the checks
**Task**: 1.1  
**Description**: Edit the READMEs, the three HTML guides, the maintenance record and the JSON files, and run the commands.  
**Status**: Pending

---
