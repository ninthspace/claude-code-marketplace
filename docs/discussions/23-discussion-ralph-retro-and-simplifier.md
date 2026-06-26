# Discussion: /cpm:ralph — retro application and simplifier consistency

**Date**: 2026-06-26
**Agents**: Jordan (PM), Margot (Architect), Bella (Senior Dev), Sable (DevOps), Casey (Test), Tomas (QA), Ren (Scrum Master)

## Discussion Highlights

### Observation 1 — retros generated but ignored under ralph (CONFIRMED)

- Intentional behaviour. Under autonomous mode the retro **consumption** gate does not block — it auto-defers every observation with `deferred (autonomous run, unreviewed)` (ralph SKILL.md:230; do SKILL.md:52).
- Retro **generation** still fires at each epic completion under ralph (ralph SKILL.md:243).
- Net gap: in a multi-epic run, epic 1 writes a retro, epic 2 sees it and **defers** rather than **applies** it. `ralph` is structurally incapable of learning mid-run.
- Rationale for the original design: "applying" a lesson is open-ended and judged too risky to do without a human in the loop.

### Observation 2 — laravel-simplifier inconsistent (CONFIRMED: it ran, but not every story)

- Not a permissions issue. Structural gating in `cpm:do` Step 5b (SKILL.md:280-298):
  - Fires **only on verification-gate tasks** (skips implementation tasks — line 282).
  - Only **after the gate passes** (line 280).
  - **Skipped** for stories with no implementation tasks (docs/config — line 298).
  - Net: runs once per story that reaches a passing verification gate. Stuck/skipped stories (autonomous threshold) never reach it.
  - Also: Step 5b reverts refactoring that breaks tests and continues silently (line 294) — a pass could be silently rolled back.
- Real defect, per Bella: "inconsistent **and** invisible." The run summary records nothing about what the simplifier did per story.

### Shared root cause

Both observations resolve to the same thing: **`ralph` does work silently and skips silently.** The cheap/safe fix is *visibility*; the deeper fix is *behaviour change*.

### Decisions taken by Chris

1. **Simplifier: always run.**
2. **Retros: apply only on safe categories** (Margot's path 3).

### Pressure-test findings

- **Casey (simplifier safety net):** decoupling Step 5b from the verification gate removes the retest guard. "Always run" must mean *always run where there's something to safely refactor* — story touched code **and** a cached test command exists to retest against. Where no test exists, skip-with-reason or run in a stricter rename/format-only mode. Don't refactor untested code blind.
- **Tomas (preconditions + scepticism on "safe"):** never run the simplifier on stuck/blocked stories (partial, possibly-broken code) — only on *completed* stories. On retros, "safe" is not risk-free: an autonomously-applied lesson can be stale or wrong, so auto-applied lessons need **more** visibility than deferred ones, surfaced as "applied autonomously — review this."
- **Margot (concrete category split):**
  - **Auto-apply (low ambiguity, additive):** *Codebase discoveries*, *Patterns worth reusing* — factual/concrete; applying means carrying them as a constraint into the work, not re-planning.
  - **Always defer (judgement-heavy):** *Scope surprises*, *Criteria gaps*, *Complexity underestimates* — each implies re-planning / a scope call a human must own.
  - **Nothing to apply:** *Smooth deliveries* (informational). *Testing gaps* leans **defer** (which test, at which level, is a design decision).
  - Auto-apply breadcrumb: `**Retro applied**: {nn} · {category} · applied (autonomous, safe-category) — {what it did}`, listed separately from deferred ones in the run summary.
- **Jordan (product guardrail):** both changes add per-loop work; the run summary must make the value legible (e.g. "simplifier ran on 6/8 stories (2 skipped: no test command), 3 retro lessons auto-applied, 2 deferred for review") or users won't trust the output. Visibility is what makes the extra steps worth doing.

### Team recommendation (consensus)

1. **Simplifier — always run, with guardrails.** Decouple Step 5b from the verification gate so it runs after every *completed* story that touched code — but only with a retest safety net where a test command exists (skip-with-reason or rename/format-only where there isn't), and never on stuck/blocked stories.
2. **Retros — auto-apply safe categories only.** Auto-apply *Codebase discoveries* and *Patterns worth reusing*; defer *Scope surprises*, *Criteria gaps*, *Complexity underestimates*, and (leaning) *Testing gaps*; *Smooth deliveries* is informational. Record auto-applied lessons with their own breadcrumb and surface them prominently for review.
3. **Cross-cutting:** the `ralph` run summary logs, per story, what the simplifier did (ran / skipped + reason / reverted) and lists auto-applied vs deferred retros — fixing the "silent" defect underlying both observations.

### Next step

Chris chose to carry this into `/cpm:spec` to turn the recommendation into a concrete change specification.
