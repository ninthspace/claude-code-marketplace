# Retro: Ralph Retro Application & Simplifier Consistency

**Date**: 2026-06-26
**Source**: docs/epics/37-01-epic-ralph-retro-and-simplifier.md
**Stories**: 3/3 complete

## Summary

Reworked `cpm:do` and `cpm:ralph` so the simplifier refactoring pass runs after every completed code-touching story (with completed/touched-code/test-command preconditions), so autonomous runs auto-apply safe-category retros instead of deferring everything, and so both outcomes surface in the run summary. All three stories landed cleanly; the only friction was discovering that one behaviour was encoded in more places than the spec implied. Verification was entirely `[manual]` (skill-prose changes), so the gates were genuine prose reads rather than test runs.

## Observations

### Codebase Discoveries

- The autonomous retro-handling behaviour lives in **three coupled sites** — `do/SKILL.md`'s autonomous override, `ralph/SKILL.md`'s override table, and `ralph`'s **generated prompt template** (~L87) — and the generated prompt is the *operative* one. Editing only the documentation table would have left the autonomous loop behaving the old way. Lesson: when changing an autonomous-mode behaviour, grep for every site that re-states it (doc table + generated prompt + the overridden skill) and change them together; the prompt the loop actually receives is the load-bearing one.

### Patterns Worth Reusing

- **Single-source the behaviour, let the wrapper inherit.** The "ralph run summary" requirements (FR11/FR12) were satisfied by editing `do`'s shared Step 8 Report step — which `ralph` inherits by running `/cpm:do` — rather than forking a separate `ralph` summary block. Put cross-cutting loop behaviour in `do`; reserve `ralph` edits for genuinely autonomous-only overrides.
- **Test-gated guardrails self-exercise when you dogfood them.** Because this epic edits skill-prose under all-`[manual]` verification (no test command), the new Step 5b "no test command → skip" precondition fired on the epic's own verification gates — the guardrail validated itself live. When a change adds a precondition, look for whether the current work already exercises that path.

## Recommendations

- **When overriding autonomous behaviour, change every encoding site at once.** Maintain the doc/override table and the generated prompt as a single logical change; a future audit should confirm the generated prompt and the override table never drift.
- **Prefer `do`-level changes over `ralph`-level forks** for anything that isn't strictly autonomous-only — it keeps one code path and avoids divergence.
- **`[manual]`-only specs need the human read scheduled explicitly.** This epic's verification depended entirely on reading the edited prose (retro 02's lesson, applied). Keep treating `[manual]` skill-prose criteria as real review gates, not presence checks.
- **These changes only take effect after republish/reinstall.** The edits are in the repo source (`cpm/skills/...`); the cached/operational skills (and any live `ralph` loop) won't reflect them until the marketplace is bumped and reinstalled. Validate with an observational `ralph` run on a throwaway multi-epic project post-install.
