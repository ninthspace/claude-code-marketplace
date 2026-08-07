# Retro: Delivery Autonomy — the first live run

**Date**: 2026-07-27
**Source**: docs/specifications/45-spec-delivery-autonomy.md
**Stories**: 14/17 complete

## Summary

Spec 45 exists so a spec can be handed to `cpm:ralph` and finished without supervision. Epics
45-01 through 45-03 shipped at 3.5.0 with 46 suites green and 81 new assertions. The first live
spec-mode run — project "Split", a greenfield Laravel repo — never worked a single story: it
spent its whole iteration cap regenerating epic documents.

This retro is not about those three epics; each has its own (25, 26, 27). It is about the gap
between *the suites pass* and *the loop works*, which is the only thing a field test can measure
and the reason this one was worth running. Two commits of repair followed (`69320ef`, `905b36b`),
and the fallout reshaped what remains of the spec.

## Observations

### Testing Gaps

- **Every suite passed, and none of them asserted that a branch was reachable.** The prompt-clause  
  suites tested the clauses for *what they say* — that a sentence exists, that a length matches,  
  that a forbidden word is absent — never for *which branch a real situation lands in*. So a phase  
  clause routing every non-zero untraced count to `/cpm:epics` read correctly and looked tested.  
  The remedy is the shape now in `test-ralph-two-phase-prompt.sh`: build a fixture in the situation,  
  run the real script for its exit code, assert which branch that code selects, and add a control  
  restoring the pre-fix wording so the assertion is shown to discriminate. The other prompt-clause  
  suites still have the blind spot.

- **A registration check passed throughout a run the thing it checked was destroying.** Pre-flight  
  verified the ralph-wiggum Stop hook was *installed*. It was — and it deleted the loop's state file  
  at the first iteration boundary and exited 0, because upstream selected the last transcript record  
  matching `"role":"assistant"` and read a `tool_use`-only record as "the model said nothing". Every  
  `cpm:do` story ends in a commit, so that is the normal turn shape, not a corrupt one. Presence was  
  never the property that mattered; *direction of failure* is. `ralph-hook-probe.sh` now runs the  
  hook against a scratch state file and reports which way it fails. Worth generalising: a  
  dependency check that asks "is it there?" about something that can fail either way is not a check.

### Scope Surprises

- **No component was wrong; three were right about the same fact in incompatible ways.**  
  `cpm:epics` is licensed to leave a Should Have uncovered — *"Should-have requirements not covered  
  are warnings, not blockers"* (`epics/SKILL.md:308`). `coverage-rollup.sh` counted every  
  non-`Won't Have` requirement as untraced. `cpm:ralph` read any non-zero untraced count as "phase 1  
  unfinished". Each is defensible alone; together the loop demanded what the generator may decline  
  to produce. Where the failure lives is *between* the three, and no unit test of any one of them  
  could have found it — which is the general lesson, not a fact about these three.

- **The spec predicted this and sequenced the guard last.** Line 54 records the consequence  
  verbatim: *"if `cpm:epics` legitimately leaves a Must Have uncovered, phase 1 never completes and  
  the loop spins … it needs FR11 to turn it into stop-and-report rather than fifty wasted  
  iterations."* FR11 went into epic 45-04, the last of four, on the stated reasoning that it is *"the  
  safety net over a loop that must first exist."* That sequencing is not obviously wrong — you cannot  
  guard a loop you have not built — but the spec named a failure mode, deferred its guard to the end,  
  and then hit exactly that failure on the first run. When a spec records a consequence it is not yet  
  fixing, that sentence is a prediction with a date on it, and the ordering deserves a second look.

### Criteria Gaps

- **The new Scope parser read spec 45's own Deferred bullet as a deferral.** That bullet begins  
  *"Nothing. FR12 was the one candidate for deferral…"* — it mentions requirement labels while  
  deferring none. The count moved 19 → 18, which is a real regression caught only because the change  
  was run against this repository's own specifications before it shipped. The fix ("a bullet defers  
  only the labels it *opens with*") is now fixture 76. A parser for prose written by humans needs its  
  ambiguous cases found in real documents, not invented in fixtures.

### Codebase Discoveries

- **A property correct in isolation became the amplifier.** Epic sub-numbers are assigned `max + 1`  
  and gaps are preserved deliberately, because sub-numbers are identifiers rather than ordinals —  
  which is right, and which turned "the loop retried generation" into "the loop wrote fifty distinct  
  generations of epic documents". The non-termination was one bug; the mess it made was a second,  
  independent design decision working as designed. Worth asking of any idempotency assumption: what  
  does the *repeat* cost, separately from the fact that it repeats?

### Patterns Worth Reusing

- **Run a parser change over the repository's real documents before shipping it.** This is what  
  caught the 19 → 18 regression above, and it cost one command. It is the same instinct as spec 46's  
  NFR1 baseline and Bella's *"real specs, not only fixtures"* constraint, and it keeps proving itself.

## Recommendations

- **Re-read epic 45-04 against what the repair commits shipped, rather than implementing it as  
  written.** Story 3 (FR11) asks for per-iteration count reporting and an N-iteration threshold;  
  `69320ef` already stops the same stall structurally — exit 4 is the only route into `/cpm:epics`,  
  and phase 2's exit-3 branch continues only while an epic has unfinished work. The threshold would  
  sit on top of a guard that prevents the case. Stories 1–2 (FR9, FR12, NFR6) are narrowed by the  
  same guard but not obviously closed: nothing has touched FR12's subject, the Stale-Progress guard  
  printing `SUPPRESS` during ralph runs. Settle it with `/cpm:pivot` on the spec — withdrawing the  
  epic outright reverses a decision the spec recorded deliberately at line 123, where FR12 was  
  considered for deferral and brought into scope instead.

- **Apply the branch-reachability test shape to the remaining prompt-clause suites.** Four of them  
  locate the prompt template by grepping its opening sentence and assert wording. None asserts a  
  routing outcome.

- **The upstream Stop-hook bug has no PR.** The project switched to `ralph-loop`, the maintained  
  fork that already fixes it, so the hand-applied `ralph-wiggum` cache patch is disabled and inert —  
  and `/plugin update` would have silently reverted it anyway. The pre-flight probe is what makes any  
  future revert loud instead of silent, but the fix is still not upstream.

- **Split is still running CPM 3.5.0** and will reproduce the original hang until it picks up 3.5.3.  
  A second field test on the current version is the only thing that will tell us whether the guards  
  hold — the first one is the reason any of this was found.
