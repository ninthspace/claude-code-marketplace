# Discussion: Opus 4.7 Migration Approach

**Date**: 2026-04-18
**Agents**: Jordan, Margot, Bella, Ren

## Key Decisions

1. **All URGENT items (U1–U4) must ship as a single atomic pass** — no partial migration to 4.7. The skill chain (ralph → do → epics → spec) is the unit of compatibility, not individual skills. Updating ralph alone while do/epics still use 4.6 terminology produces incoherent behaviour under 4.7's literal instruction following.

2. **Execution order within the URGENT pass**: U4 (negative-to-positive voice rewrite across all skills) → U2 (explicit stop criteria for every loop) → U3 (explicit fallback rules in graceful degradation sections) → U1 (ralph autonomous prompt rewrite). This reverses the plan's original U1-first sequencing so the ralph prompt is written in the vocabulary established by the other three changes.

3. **HIGH and MEDIUM items are quality optimisations, not compatibility requirements.** They should be assessed after switching to 4.7 and observing real behaviour, not planned upfront. The line is: U1–U4 gates the 4.7 switch; H1–H4 and M1–M3 improve quality once running on 4.7.

4. **Commit Pass 1+2 as a clean baseline first** before starting the URGENT pass. This provides a known revert point and keeps diffs reviewable.

## Key Points

- **Interdependency**: ralph calls /cpm:do, do reads epics, epics reference spec output. The entire chain must speak 4.7-compatible language simultaneously.
- **U4 establishes the new voice**: rewriting negatives as positives across all skills is the foundation. U2 and U3 add structural sections within that new voice. U1 is written last to reflect the chain's final terminology.
- **Facilitation skills won't burn money on 4.7** — they'll be suboptimal but tolerable. The autonomous loops (ralph, do) are the actual cost risk.
- **The plan's 11 items should be organised as epics by urgency tier**: URGENT as the migration gate, HIGH as post-migration quality, MEDIUM as observational follow-ups.

## Context

- Source plan: `docs/plans/02-plan-opus-4-7-deferred-optimisations.md`
- Prior audit: `docs/discussions/15-discussion-opus-4-7-skill-emphatic-pattern-audit.md`
- Pass 1+2 already completed locally (14 skill files, ~2,800 tokens saved, uncommitted)
- Currently running Opus 4.6; goal is to switch to 4.7 with CPM compatibility
