# Spec: Opus 4.7 Compatibility (cpm2)

**Date**: 2026-04-18
**Discussion**: docs/discussions/16-discussion-opus-4-7-migration-approach.md
**Plan**: docs/plans/02-plan-opus-4-7-deferred-optimisations.md

## Problem Summary

Anthropic's Claude Opus 4.7 introduces literal instruction following, adaptive thinking with no fixed budget (the "ambiguity tax"), a heavier tokenizer (1.0–1.35x), and fewer tool calls with more reasoning. CPM's skill prompts were tuned for 4.6's intent-interpreting behaviour �� under 4.7, vague stop criteria burn tokens, negative-only instructions leave the model free to choose unwanted positive actions, missing fallbacks produce guesses, and ambiguous acceptance criteria produce "passing but wrong" implementations. Pass 1+2 stripped emphatic scaffolding (~2,800 tokens saved) but did not address the imprecise instructions that are the larger risk. The entire skill chain (ralph → do → epics → spec) is the unit of compatibility — partial updates produce incoherent behaviour. The 4.7-compatible version ships as a new plugin under the `cpm2` namespace — a new top-level directory (`cpm2/`) alongside `cpm/` in the existing marketplace repo — allowing the original `cpm` plugin to continue serving earlier model versions.

## Functional Requirements

### Must Have

- **R1. Rewrite negative instructions as positive guidance (U4)**: Audit all 115 occurrences of "Don't / Do not / Never / Avoid" across 18 skill files. Triage each as behaviour-shaping, hard constraint, or hint. Rewrite to positive form where the positive is at least as clear; preserve load-bearing negatives with inline rationale.
- **R2. Add explicit stop criteria to all loops (U2)**: Every loop in CPM must have a Termination section with three exit conditions: success, blocker, and ambiguity. Affected: `/cpm2:do` per-task workflow loop, `/cpm2:do` Step 4 verification gate, `/cpm2:spec` and `/cpm2:epics` facilitation loops, `/cpm2:ralph` autonomous loop.
- **R3. Rewrite the `/cpm2:ralph` autonomous prompt (U1)**: Replace the ~500-char prompt template with positive task framing, explicit stop criteria per task, explicit failure rules (what counts as a "failure" for the 3-strike skip), task budget advisory, and fallback for ambiguous acceptance criteria. Must pass all five Smart Ape migration questions.
- **R4. Add explicit fallback rules to graceful degradation sections (U3)**: Rewrite every graceful degradation scenario across `do`, `pivot`, `library`, `architect`, and `review` from vague actions to explicit action sequences with visible results.
- **R5. Add "must NOT" clauses to acceptance criteria templates (H1)**: Update `/cpm2:spec` Section 6b to prompt for negative acceptance criteria. Update `/cpm2:epics` Step 3 to surface "must NOT" clauses from spec and propose them on security/data/external stories.
- **R6. Document effort calibration per skill (H2)**: Add an "Effort Recommendations" table to shared conventions mapping each skill to xhigh/high/medium with rationale.
- **R7. Add subagent delegation guidance (H3)**: Add a delegation section to shared conventions referencing Anthropic's rule. Audit each skill for fan-out opportunities and add explicit subagent invocations where they would parallelise independent work.
- **R8. Add codebase grounding sections to exploratory skills (H4)**: Add "Codebase grounding" instructions to spec, discover, and architect requiring Read/Glob/Grep before user-facing responses.
- **R9. Tighten TDD sub-loop (M1)**: Assess under 4.7 whether the 25-line red-green-refactor micro-direction can be compressed. Compress if 4.7 reliably runs all three phases; expand if it skips.
- **R10. Review [plan] tag heuristic (M2)**: Assess whether the `[plan]` tag assignment heuristic suits 4.7's improved planning. Confirm or adjust with rationale.
- **R11. Ralph defensive scaffolding review (M3)**: Review remaining ralph scaffolding after R3. Remove unjustified scaffolding; document what remains.
- **R12. Rename plugin namespace to cpm2**: Update all 169 occurrences of `cpm:` across 18 skill files, hook scripts, progress file fields, plugin registration, and supporting files.

### Should Have

(none — all requirements promoted to Must Have)

### Could Have

(none)

### Won't Have (this iteration)

- Changes to hook logic or behaviour (namespace references only)
- New skills or entry points
- Agent roster changes
- Original `cpm` plugin maintenance
- Tokenizer-specific optimisations beyond Pass 1+2

## Non-Functional Requirements

### Token Efficiency
Total token count across `cpm2/skills/*/SKILL.md` must not increase versus the post-Pass-1+2 baseline. Positive rewrites that are slightly longer than negatives must be offset by removing redundancy discovered during audit.

### Consistency
Termination sections follow the same Success/Blocker/Ambiguity triplet format across all skills. Graceful Degradation entries follow the same explicit-action-with-visible-result format. Terminology is uniform across the skill chain.

### Maintainability
Load-bearing negatives preserved from the U4 rewrite are documented inline with rationale (not in a separate file). Shared conventions additions (effort table, delegation guidance) are self-documenting.

## Architecture Decisions

### AD1: Plugin Namespace
**Choice**: New `cpm2/` plugin directory in the existing marketplace repo, created by forking `cpm/` and renaming the namespace.
**Rationale**: Users can install either `cpm` or `cpm2` (or both). The marketplace repo already hosts multiple plugins (`cpm`, `noteplan`, `php-lsp`, `js-simplifier`) — `cpm2` follows the same pattern.
**Alternatives considered**: Separate repository (unnecessary given the marketplace structure); dynamic namespace resolution (too complex for LLM-consumed prompts); single namespace with backward compat (dropped — going straight to 4.7).

### AD2: Execution Order
**Choice**: R12 (namespace rename) → R1 (voice rewrite) → R2 + R4 + R5 + R8 (structural additions) → R6 + R7 (shared conventions) → R3 (ralph prompt) → R9–R11 (post-switch observation).
**Rationale**: Namespace rename first keeps subsequent diffs clean. Voice rewrite (R1) establishes the positive language that structural additions write within. Ralph prompt (R3) last because it must reflect the chain's final terminology. R9–R11 require 4.7 observation.
**Alternatives considered**: U1 first (original plan sequencing — rejected because ralph prompt should use vocabulary from the completed chain); single atomic pass (harder to review and debug).

### AD3: Standard Section Formats
**Choice**: Termination sections use a three-exit triplet (Success / Blocker / Ambiguity). Graceful Degradation entries specify an explicit action sequence ending with a visible result — no silent fallbacks.
**Rationale**: Under 4.7's literal interpretation, vague fallbacks produce vague behaviour. Uniform format across skills enables batch review and catches gaps.
**Alternatives considered**: Free-form per-skill (inconsistent, harder to audit).

### AD4: Don't-Strip List Location
**Choice**: Documented inline next to each preserved negative in the skill file, not in a separate file.
**Rationale**: A separate list rots when contributors add or remove negatives without updating it. Inline rationale is self-documenting and survives refactoring.
**Alternatives considered**: Separate companion doc (maintenance burden); in the spec only (not visible to contributors editing skill files).

## Scope

### In Scope

- All 18 skill SKILL.md files (namespace rename, voice rewrite, structural additions)
- Shared conventions file (effort table, delegation guidance)
- Ralph prompt template (full rewrite)
- Hook scripts (namespace references only)
- Plugin registration under `cpm2`
- All supporting files (agents, templates, shared) with namespace updates
- Post-switch assessment of R9–R11 on Opus 4.7

### Out of Scope

- Original `cpm` plugin (maintained independently in its existing directory)
- New skills or entry points
- Hook logic or behaviour changes
- Agent roster changes
- Tokenizer-specific optimisations beyond Pass 1+2

### Deferred

- R9 (TDD sub-loop): assess after running `/cpm2:do` with `[tdd]` story on 4.7
- R10 ([plan] tag heuristic): assess after observing `/cpm2:epics` on 4.7
- R11 (ralph scaffolding): assess after R3 lands and ralph runs on 4.7

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting hook test suites (namespace updates)
- `[manual]` — Grep verification, prompt review, and functional testing on Opus 4.7

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| R1 — Negative→positive rewrite | Every negative triaged: rewritten or preserved with inline rationale | `[manual]` |
| R1 — Negative→positive rewrite | No net-new negative instructions introduced (grep) | `[manual]` |
| R1 — Negative→positive rewrite | Preserved negatives annotated with load-bearing rationale | `[manual]` |
| R2 — Stop criteria | Each loop has Termination section with Success/Blocker/Ambiguity | `[manual]` |
| R2 — Stop criteria | Facilitation loops have explicit "good enough" criteria | `[manual]` |
| R3 — Ralph prompt | Prompt uses only positive instructions (grep) | `[manual]` |
| R3 — Ralph prompt | Prompt defines "task complete" in testable terms | `[manual]` |
| R3 — Ralph prompt | Prompt defines "failure" for 3-strike skip | `[manual]` |
| R3 — Ralph prompt | Prompt includes task budget advisory | `[manual]` |
| R3 — Ralph prompt | Prompt includes fallback for ambiguous criteria | `[manual]` |
| R3 — Ralph prompt | Passes all five Smart Ape migration questions | `[manual]` |
| R4 — Fallback rules | Every degradation scenario has explicit action + visible result | `[manual]` |
| R4 — Fallback rules | TDD without test runner produces visible artefact | `[manual]` |
| R4 — Fallback rules | User-affecting degradation uses AskUserQuestion | `[manual]` |
| R5 — Must-NOT clauses | cpm2:spec Section 6b prompts for "must NOT" lines | `[manual]` |
| R5 — Must-NOT clauses | cpm2:epics Step 3 surfaces/proposes "must NOT" clauses | `[manual]` |
| R6 — Effort calibration | Table covers all skills with level and rationale | `[manual]` |
| R7 — Delegation guidance | Shared conventions includes delegation section | `[manual]` |
| R7 — Delegation guidance | At least one skill has explicit subagent fan-out | `[manual]` |
| R8 — Codebase grounding | spec, discover, architect have grounding instructions | `[manual]` |
| R9 — TDD sub-loop | Assessed on 4.7; direction documented | `[manual]` |
| R10 — Plan tag heuristic | Reviewed; confirmed or adjusted with rationale | `[manual]` |
| R11 — Ralph scaffolding | Post-R3 review completed; justified or removed | `[manual]` |
| R12 — Namespace rename | Zero `cpm:` occurrences in skill files (grep) | `[manual]` |
| R12 — Namespace rename | All `cpm2:` references resolve correctly | `[manual]` |
| R12 — Namespace rename | Hook test suites updated and passing | `[unit]` |
| R12 — Namespace rename | Plugin registers and invokes under cpm2 | `[manual]` |

### Integration Boundaries
The skill chain (ralph → do → epics → spec) is the primary integration seam. Ralph's prompt template must use terminology matching do/epics/spec instructions. Verified by manual cross-reference after all content changes land.

### Test Infrastructure
Existing hook test infrastructure (`cpm/hooks/tests/`, `test-helpers.sh`, 38 tests) is adequate. No new frameworks or infrastructure needed. Hook tests require namespace updates only.

### Unit Testing
Hook test suite namespace updates are the only automated testing component. All prompt quality verification is manual.
