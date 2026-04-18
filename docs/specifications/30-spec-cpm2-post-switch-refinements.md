# Spec: cpm2 Post-Switch Refinements (Opus 4.7)

**Date**: 2026-04-18
**Parent spec**: docs/specifications/29-spec-opus-4-7-compatibility.md

## Problem Summary

Spec 29 delivered the main Opus 4.7 compatibility pass for cpm2 (voice rewrite, stop criteria, fallbacks, must-NOT clauses, effort calibration, delegation guidance, codebase grounding, namespace rename, ralph prompt rewrite). A post-switch review of all 18 cpm2 skill files identified three classes of issue that 4.7's literal instruction following and stronger default planning make visible and that Spec 29 did not address. First, 8 skills inline the full Library Check procedure and 3 inline the full Roster Loading procedure even though both are defined in `cpm2/shared/skill-conventions.md`, which is loaded into context at session start — the inline copies are pure token cost. Second, several skills (notably `cpm2:ralph`, `cpm2:do`, `cpm2:spec`, `cpm2:epics`) contain step-by-step procedural recipes where 4.7 can produce correct behaviour from a shorter outcome-oriented statement, plus one defensive pre-flight ceremony (ralph Step 1d Permissions Check) that 4.7 handles correctly at runtime. Third, the three items Spec 29 deferred for post-switch observation (R9 TDD compression, R10 `[plan]` heuristic, R11 ralph scaffolding) now have enough signal to resolve: TDD stays as-is (behavioural lock, not instructional), the `[plan]` heuristic can be sharpened, and the ralph Permissions Check is the defensive scaffolding R11 was asking about. The unit of compatibility is the skill file — each refactor is scoped to a single file and verified by grep plus manual prose review.

## Functional Requirements

### Must Have

- **R1. Consolidate Library Check to shared reference across 8 skills**: Convert inline Library Check sections in `cpm2/skills/{do,quick,epics,retro,review,party,present,consult}/SKILL.md` to a one-sentence reference to the shared procedure, followed by one optional sentence of skill-specific guidance (e.g. when to deep-read). `cpm2/skills/library/SKILL.md` retains its expanded logic because it owns the procedure.
- **R2. Consolidate Roster Loading to shared reference across 3 skills**: Convert inline Roster Loading sections in `cpm2/skills/{review,party,consult}/SKILL.md` to a one-sentence reference to the shared procedure. No skill-specific context is needed — Roster Loading behaviour is uniform.
- **R3. Compress ralph Prompt Assembly**: Rewrite the Prompt Assembly section of `cpm2/skills/ralph/SKILL.md` from its current step-by-step specification to a concise outcome statement: list the interpolation variables and show the template, without restating plain-text/no-markdown constraints in multiple forms.
- **R4. Remove ralph Permissions Check (Step 1d)**: Remove the pre-flight permissions audit from `cpm2/skills/ralph/SKILL.md` and replace it with a one-sentence note that the loop will pause on permission denials at runtime and that users who want to avoid stalls can pre-add common Bash permissions. This resolves R11 from Spec 29.
- **R5. De-scaffold procedural recipes in do/spec/epics**: Rewrite three sections from step-by-step recipes to outcome-oriented 2–3 sentence statements — `cpm2:do` Test Execution step, `cpm2:spec` test-approach tag propagation, `cpm2:epics` Epic Filename Convention (removing repeated integer-vs-string warnings while preserving the load-bearing parent-extraction rules).
- **R6. Replace verification round magic number in do**: Rewrite the "If a fix-and-recheck cycle has run 2 times and criteria remain unmet, stop cycling" gate in `cpm2/skills/do/SKILL.md` to an outcome-based gate ("if verification loops without reducing failures after a fix attempt, ask the user to continue / mark as known issue / stop").
- **R7. Sharpen `[plan]` tag heuristic in epics**: Update the `[plan]` tag assignment heuristic in `cpm2/skills/epics/SKILL.md` from the current phrasing (architecture / security / multi-system integration) to explicit categories (data model changes, API contract changes, cross-system integration). The tag's function (forcing an EnterPlanMode pause) is unchanged; only the assignment criteria tighten. This resolves R10 from Spec 29.
- **R8. Record R9 TDD disposition**: Add a brief note (inline comment or retro entry — not a code change) documenting that the TDD sub-loop in `cpm2:do` is intentionally preserved as a behavioural lock rather than an instructional scaffold, so future passes don't mistake its length for verbosity. This resolves R9 from Spec 29.

### Should Have

(none — all requirements promoted to Must Have)

### Could Have

- **R9. Consolidate Implementation Guidelines references**: Several skills paraphrase rules that are already in `shared/skill-conventions.md` Implementation Guidelines (no bulk edits, Edit over sed, etc.). Deferred because the paraphrases are short and the consolidation win is small.

### Won't Have (this iteration)

- New skills or skill entry points
- Hook logic or behaviour changes
- Agent roster changes
- Changes to the shared conventions file itself (this spec edits skill files that *reference* it)
- Changes to the original `cpm` plugin

## Non-Functional Requirements

### Token Efficiency
Total token count across `cpm2/skills/*/SKILL.md` must not increase versus the post-Spec-29 baseline. Expected reduction is ~2,000–2,500 tokens, concentrated in Library Check and Roster Loading consolidation.

### Consistency
All Library Check references follow the same one-sentence form: `Follow the shared **Library Check** procedure with scope keyword \`{skill}\`.` followed by zero or one sentence of skill-specific deep-read guidance. All Roster Loading references follow: `Follow the shared **Roster Loading** procedure.` — no additional context.

### Behavioural Preservation
No change to what any skill does under normal operation. Library Check and Roster Loading still run at the same points in each skill's flow; the refactor only removes duplicated instruction text. The ralph Permissions Check removal is the one intentional behaviour change — graceful runtime failure replaces pre-flight validation.

## Architecture Decisions

### AD1: Reference-style Consolidation Over Full Removal
**Choice**: Keep one-sentence inline references at the same structural position each skill occupied, rather than removing Library Check and Roster Loading sections entirely.
**Rationale**: Section headers and reference lines preserve the skill file's narrative flow — a reader still sees *when* Library Check fires in the skill's sequence, just without the procedure's full body. This protects skills where timing matters (e.g. `cpm2:do` fires Library Check after epic resolution but before task selection).
**Alternatives considered**: Remove the sections entirely and rely on session-level convention knowledge (rejected — loses skill-specific timing). Move all startup checks into a shared "Startup Checklist" (rejected — too much coupling for a refinement pass, revisit in a later spec).

### AD2: Runtime Graceful Degradation Over Pre-Flight Validation
**Choice**: Remove ralph Step 1d Permissions Check; let Bash permission prompts surface at runtime and let the Ralph Wiggum stop hook re-invoke after the user grants them.
**Rationale**: Under 4.7, pre-flight validation of uncommitted settings state is speculative — the skill can't know whether the user is about to add permissions or has already approved them via session-scoped grants. Runtime failure is deterministic and self-healing via the stop-hook resume pattern.
**Alternatives considered**: Keep the check but simplify (rejected — still ceremonial). Replace with a session-start warning only (possible future refinement; out of scope here).

### AD3: Outcome-Based Gates Over Numeric Thresholds
**Choice**: Rewrite "run 2 times and stop" in `cpm2:do` verification to "loops without reducing failures, ask the user."
**Rationale**: 4.7 applies outcome-based gates ("not making progress") more reliably than arbitrary counters. A numeric threshold is a proxy for the real question; asking it directly aligns with 4.7's literal-instruction strength.
**Alternatives considered**: Keep the numeric gate for predictability (rejected — proxy measure). Remove the gate entirely and always ask (rejected — too interruptive for tight convergence loops).

### AD4: `[plan]` Heuristic Category Sharpening Only
**Choice**: Keep the `[plan]` tag and its EnterPlanMode gate as-is; refine only the assignment criteria in `cpm2:epics`.
**Rationale**: The tag's job is to force a physical pause for user approval before code writing — it's a workflow lock, not a planning-quality signal. 4.7's better planning doesn't remove the need for the gate; it just makes the assignment heuristic easier to sharpen.
**Alternatives considered**: Remove the tag (rejected — workflow lock is load-bearing). Apply the tag to all stories (rejected — defeats its purpose).

## Scope

### In Scope

- `cpm2/skills/do/SKILL.md` (Library Check reference, Test Execution de-scaffold, verification gate rewrite, R9 disposition note)
- `cpm2/skills/ralph/SKILL.md` (Prompt Assembly compression, Permissions Check removal)
- `cpm2/skills/spec/SKILL.md` (test-tag propagation de-scaffold — Library Check already references)
- `cpm2/skills/epics/SKILL.md` (Library Check reference, Filename Convention de-scaffold, `[plan]` heuristic sharpening)
- `cpm2/skills/quick/SKILL.md` (Library Check reference)
- `cpm2/skills/retro/SKILL.md` (Library Check reference)
- `cpm2/skills/review/SKILL.md` (Library Check reference, Roster Loading reference)
- `cpm2/skills/party/SKILL.md` (Library Check reference, Roster Loading reference)
- `cpm2/skills/present/SKILL.md` (Library Check reference)
- `cpm2/skills/consult/SKILL.md` (Library Check reference, Roster Loading reference)

### Out of Scope

- `cpm2/skills/library/SKILL.md` (owns the Library Check procedure — keeps expanded logic)
- `cpm2/shared/skill-conventions.md` (this spec consumes conventions; it does not edit them)
- `cpm2/skills/brief/SKILL.md`, `cpm2/skills/architect/SKILL.md`, `cpm2/skills/discover/SKILL.md` (already use reference-style Library Check)
- Original `cpm` plugin
- R9 Could-Have (Implementation Guidelines consolidation)

### Deferred

- Broader "Startup Checklist" refactor across all facilitation skills (AD1 alternative) — revisit after 30-01 lands and the reference-style pattern is proven at scale.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[manual]` — Grep verification, prose review, and skill-file byte-count diff against Spec-29 baseline.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| R1 — Library Check consolidation | All 8 target skills contain exactly one `Follow the shared **Library Check** procedure` line and zero inline Library Check procedure bodies (grep) | `[manual]` |
| R1 — Library Check consolidation | Each reference line names a scope keyword matching the skill name | `[manual]` |
| R1 — Library Check consolidation | `cpm2:library` still contains the expanded Library Check logic | `[manual]` |
| R2 — Roster Loading consolidation | All 3 target skills contain exactly one `Follow the shared **Roster Loading** procedure` line and zero inline Roster Loading procedure bodies (grep) | `[manual]` |
| R3 — ralph Prompt Assembly compression | Prompt Assembly section is ≤ 10 lines and names all interpolation variables | `[manual]` |
| R3 — ralph Prompt Assembly compression | Plain-text / no-markdown constraint appears exactly once | `[manual]` |
| R4 — ralph Permissions Check removal | Zero occurrences of "Permissions Check" section heading in `cpm2/skills/ralph/SKILL.md` | `[manual]` |
| R4 — ralph Permissions Check removal | Replacement note references runtime stall behaviour and the stop-hook resume pattern | `[manual]` |
| R5 — Procedural de-scaffolding | `cpm2:do` Test Execution step is ≤ 3 sentences and covers tagged + manual cases | `[manual]` |
| R5 — Procedural de-scaffolding | `cpm2:spec` test-tag propagation is ≤ 4 sentences and covers propagate / propose / skip cases | `[manual]` |
| R5 — Procedural de-scaffolding | `cpm2:epics` Filename Convention integer-vs-string warning appears exactly once; parent-extraction rules preserved verbatim | `[manual]` |
| R5 — Procedural de-scaffolding | must NOT: no skill drops a load-bearing rule while de-scaffolding (manual cross-check against Spec-29 baseline) | `[manual]` |
| R6 — Verification gate rewrite | `cpm2:do` verification gate uses outcome language ("not reducing failures") with explicit user prompt path (AskUserQuestion) | `[manual]` |
| R6 — Verification gate rewrite | No numeric threshold ("2 times", "3 times") remains in the verification gate | `[manual]` |
| R7 — `[plan]` heuristic sharpening | `cpm2:epics` heuristic lists data model / API contract / cross-system integration as the assignment categories | `[manual]` |
| R7 — `[plan]` heuristic sharpening | `[plan]` tag behaviour in `cpm2:do` (EnterPlanMode gate) is unchanged | `[manual]` |
| R8 — R9 disposition note | `cpm2:do` TDD section carries an inline rationale line documenting the behavioural-lock intent | `[manual]` |
| Token efficiency | Total bytes across `cpm2/skills/*/SKILL.md` decrease versus Spec-29 baseline | `[manual]` |
| Behavioural preservation | Library Check still fires at the same point in each skill's flow (section header position preserved) | `[manual]` |

### Integration Boundaries
The `cpm2/shared/skill-conventions.md` → `cpm2/skills/*/SKILL.md` reference relationship is the primary integration seam. Verified by confirming each reference line names the correct shared procedure by title and that the shared procedure section exists and is current.

### Test Infrastructure
Existing grep-based manual verification is sufficient. No hook test changes. No automated test infrastructure additions.
