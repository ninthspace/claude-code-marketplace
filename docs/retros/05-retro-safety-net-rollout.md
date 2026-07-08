# Retro: Safety-Net & Skill Rollout

**Date**: 2026-07-08
**Source**: docs/epics/38-02-epic-safety-net-rollout.md
**Stories**: 4/4 complete

## Summary

Epic 38-02 built the once-per-session safety-net on top of epic 38-01's classifier.
Story 1 added `cpm/hooks/lib/cleancheck-guard.sh` — a tiny fail-safe gate that
prints `SUPPRESS`/`SKIP`/`RUN` keyed on a `CPM_SESSION_ID` sentinel
(`docs/plans/.cpm-cleancheck-{id}`), suppressing entirely when an active ralph
loop is present. Story 2 authored the shared **Stale-Progress Check** procedure in
`skill-conventions.md` (guard decides *whether*, classifier decides *how*, three-way
non-blocking presentation, deletion only on explicit confirmation). Story 3 rolled a
single-line reference into all 19 `/cpm:*` skills as their first startup step. Story 4
registered the gate in ralph's autonomous-override table as "fully suppressed, no
prompt, no action". Coverage matrix: 6/6 requirements verified (FR3, FR4, FR6, FR11,
AD2, AD3).

The epic delivered its scope cleanly, but epic-level verification caught a regression
Story 2 had introduced and hidden — the most instructive part of the run (see Testing
Gaps). One pre-existing, unrelated failure (`test-audit-skill.sh` version drift) was
carried forward as known, consistent with retro 04.

## Observations

### Patterns Worth Reusing

- **Group-redirect a best-effort write so it fails silently.** A fail-safe write like  
  `: > "$file" 2>/dev/null` still leaks the *open* error to stderr, because bash sets  
  up the `>` redirection before `2>` takes effect. Grouping it —  
  `{ : > "$file"; } 2>/dev/null || true` — makes the whole operation genuinely silent  
  and non-fatal. Reusable anywhere a hook/helper does a best-effort write it must not  
  narrate on failure (sentinels, caches, markers).
- **Roll out across heterogeneous files by semantic anchor, not fixed position.** The  
  19 `/cpm:*` skills have no common structural layout — some use `### X (Startup)`  
  sub-sections, others top-level `## X` sections, some lead with numbered steps. A  
  uniform, auditable rollout came from anchoring on a *role* ("the first startup  
  step") and matching each skill's own heading level, rather than a line/section  
  position no two skills share. Verify with a per-file count (`grep -c`) so "one  
  reference each, nowhere duplicated" is proven, not assumed.

### Codebase Discoveries

- **"Register at every override site" means reason about each site's mechanism —  
  sometimes the right edit is no edit.** Applying retro 03 (grep every  
  autonomous-override site) to Story 4 surfaced a real distinction: ralph's override  
  table documents *prompt-instruction* overrides for `AskUserQuestion` gates, but the  
  new safety-net is suppressed *structurally* by the guard's `.claude/ralph-loop.local.md`  
  detection. So the operative generated prompt needed no clause (one would be  
  redundant and misleading); only the doc table needed a row plus a note explaining  
  guard-level suppression as a valid override mechanism. Blindly editing "every site  
  identically" would have added noise; the lesson is to confirm the mechanism at each  
  site first.

### Testing Gaps

- **Hook-injected documentation can collide with a test's substring proxy — and  
  prose-only stories still need the full suite.** `session-start.sh` injects the  
  *entire* `skill-conventions.md` into context at session start. Story 2 added a  
  "Stale-Progress Check" section containing the phrase "cleanup candidate" — the exact  
  loose substring `test-orphan-detection.sh` used as a proxy for "the hook emitted its  
  stale-cleanup section". Four `assert_not_contains "cleanup candidate"` checks  
  (including the no-files case) went red, because the phrase now appears  
  unconditionally in the injected doc. Two compounding lessons:
  1. **Tests asserting on hook output must key on the hook's own structural markers**  
     (here the section header `STALE PROGRESS FILES`), never on natural-language  
     phrases that can legitimately appear in injected/echoed content. The fix aligned  
     all six assertions with the header marker the same file already used elsewhere.
  2. **"No code touched" ≠ "no test impact" when the prose is runtime-injected.**  
     Story 2 was scored prose-only and its full-suite run was skipped; the regression  
     stayed hidden until the mandatory epic-level verification. When a story edits  
     content that a hook or skill injects at runtime, run the suite even if no  
     executable code changed.
- **`${CLAUDE_PLUGIN_ROOT}` runtime resolution is still unverified.** The convention  
  composes cleanly on paper (guard + classifier both invoked via  
  `${CLAUDE_PLUGIN_ROOT}/hooks/lib/...`), but its correctness rests on that token  
  being present in the skill's Bash environment — a hooks.json substitution whose  
  availability to skill-invoked Bash the `[manual]` prose review cannot confirm. It can  
  only be validated by republishing the plugin and dogfooding a real `/cpm:*` startup.  
  Carry forward as post-install validation (also flagged in retro 04's republish note).

### Smooth Deliveries

- The guard reused epic 38-01's small-testable-bash-lib shape (retro 04) and landed  
  with 13/13 tests green on first assessment; the ralph override registration and the  
  skill rollout were mechanical once the placement rule was fixed.

## Recommendations

- **Post-install validation checklist** (before declaring feature 38 done): republish  
  the plugin, then in a real session confirm (a) `${CLAUDE_PLUGIN_ROOT}` resolves in  
  skill-invoked Bash, (b) the guard writes/reads its sentinel and returns `RUN` once  
  then `SKIP`, (c) a real `/cpm:*` startup presents the three-way check once per  
  session, and (d) an active ralph loop suppresses it silently.
- **Fix the recurring `test-audit-skill.sh` version drift at the source** (asserts  
  `2.0.0`; actual `2.5.0`). It has now been the sole "known-unrelated" failure across  
  two consecutive epics (retro 04, this one). A stale hard-coded version assertion that  
  greens-vs-reds on every version bump should read the version from the manifest, not  
  hard-code it — otherwise it keeps masking real regressions in the aggregate result.
