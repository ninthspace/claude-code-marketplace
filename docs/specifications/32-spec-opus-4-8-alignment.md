# Spec: Opus 4.8 Alignment (cpm2)

**Date**: 2026-05-28
**Source**: Anthropic *Prompting best practices* — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
**Builds on**: `docs/specifications/29-spec-opus-4-7-compatibility.md`, `docs/plans/02-plan-opus-4-7-deferred-optimisations.md`

## Problem Summary

cpm2 is the Opus 4.7-compatible fork of the CPM plugin; spec 29 aligned it to 4.7's literal instruction-following, adaptive thinking, and reduced tool-calling through positive-prose conventions (negatives→positives, Success/Blocker/Ambiguity stop criteria, explicit fallbacks, must-NOT clauses, an Effort Recommendations table, a Subagent Delegation section, and codebase grounding). Anthropic's prompting guide now covers **Claude Opus 4.8**, which introduces shifts the 4.7 work could not have anticipated: 4.8 spawns *fewer* subagents by default (reversing the 4.6 over-spawn the conventions were written to restrain), under-reports findings when a review harness is told to be conservative, adopts a flatter and less validation-forward default voice, and respects the effort parameter strictly enough to under-think at `low`/`medium`. This spec scopes a **targeted delta pass**: it amends the two shared convention sections plus a small number of skills, keeps cpm2's positive-prose style (no XML behavioural blocks), and applies coverage-first finding framing to `audit` only. It does not re-audit the plugin from scratch — the 4.7 foundation holds.

## Functional Requirements

### Must Have

- **R1 — Subagent delegation re-balanced for 4.8.** Amend the `Subagent Delegation` section of `shared/skill-conventions.md` to state that 4.8 under-delegates by default, framing the "Delegate (fan-out) when" cases as actively encouraged (the "Work inline when" guidance is retained). Verify `review`'s fan-out instruction is imperative enough to fire under 4.8's reluctance.
- **R2 — `audit` coverage-first finding framing.** Reframe `audit` so the finding stage maximises coverage (every issue reported, each tagged with severity **and** confidence) and filtering/ranking happens only at the Executive Summary step. Document schema (findings-table columns, ≤10-bullet Exec Summary cap) is unchanged.
- **R3 — Effort Recommendations table re-validated for 4.8.** Re-assess every medium-tier skill for 4.8 under-thinking risk, update the rationale column to reflect 4.8's strict effort adherence, and add an advisory note (thinking off by default on 4.8; set a large ~64k output budget at `xhigh`/`max`).
- **R4 — Model identity bump.** Update `.claude-plugin/plugin.json` description and any README references from "Opus 4.7+" to reflect Opus 4.8. Version and keywords unchanged.

### Should Have

- **R5 — Persona voice reinforcement.** Reinforce `party`, `consult`, and the Perspectives convention to actively render each agent's roster `communicationStyle`/`personality`, so multi-persona output stays differentiated under 4.8's flatter default. Identical phrasing across the three.
- **R6 — Literalism & tool-use verification pass.** Verify the 4.7 work still holds under 4.8: "apply to every X" instructions state scope explicitly, and the codebase-grounding sections in `spec`/`discover`/`architect` explicitly require Read/Glob/Grep before user-facing answers. Remediate only where a gap is found; a documented no-change outcome is acceptable.

### Could Have

- **R7 — Over-engineering & hard-coding guardrails for `do`/`quick`.** A minimal-change guardrail and a "solve generally, don't hard-code to tests" note, in positive prose. Not 4.8-specific (a 4.5/4.6 carryover in the doc); droppable if time is tight.

### Won't Have (this iteration)

- XML behavioural blocks (cpm2 keeps positive-prose conventions).
- API-parameter configuration guidance (`thinking: adaptive`, effort defaults, sampling-param removal, `max_tokens`) — except R3's effort advisory note. cpm2 ships prompts, not API calls.
- Coverage-first reframing for `review` (its 2-5-finding curation is intentional planning-critique design).
- Frontend/design house-style guidance — `present` produces memos/decks via the user's tools, not generated frontend.
- Changes to the original `cpm` plugin or to `noteplan`/`php-lsp`/`js-simplifier`.
- Hook *logic* changes (R4 touches only a manifest description string).
- Prefilled-response migration (cpm2 uses no prefill).

## Non-Functional Requirements

### Backward Compatibility
Prompt-content only — no skill behaviour, output format, progress-file format, or hook interface changes. A session started before these edits continues working after them. The one intentional behavioural shift is R2 (what `audit` reports), which changes finding coverage, not the document schema.

### Consistency
Shared changes live in `shared/skill-conventions.md` so per-skill edits stay thin and uniform; R5's reinforcement uses identical phrasing across `party`/`consult`/Perspectives. Honours the parallel-sessions retro finding that uniform SKILL.md structure enables reliable batch edits.

### Token Efficiency
Net token count across `cpm2/skills/*/SKILL.md` + `shared/` should not meaningfully increase; additions are offset by trimming redundancy found during the pass. Token counting is deferred to the end of the full change set, not used as a per-edit gate.

### Maintainability
New 4.8 guidance is self-documenting prose in shared conventions; any preserved item that looks like a change candidate carries an inline rationale.

### Style Fidelity
All additions match cpm2's positive-prose voice — no XML behavioural blocks, no ALL-CAPS/CRITICAL/MUST language (the plugin currently has near-zero of these).

## Architecture Decisions

### Shared-first placement
**Choice**: Load-bearing 4.8 changes go in `shared/skill-conventions.md` (Subagent Delegation, Effort Recommendations); per-skill edits are thin and only where behaviour is skill-specific (`review` fan-out, `audit` finding stage).
**Rationale**: Both convention sections already exist; amending them propagates to every referencing skill with one reviewable diff.
**Alternatives considered**: Per-skill duplication (rejected — drifts; defeats the consistency NFR).

### Audit coverage-first via find/rank separation
**Choice**: Separate `audit`'s finding stage (maximise coverage; severity + confidence per finding) from its ranking stage (the existing ≤10-bullet Executive Summary). Add a coverage-first instruction at the finding step; leave the schema untouched.
**Rationale**: The doc's own remedy — move confidence-filtering out of the finding step. `audit` already has the two-stage shape, so this is framing, not restructuring.
**Alternatives considered**: A separate verification subagent pass (heavier than warranted); raising effort only (doesn't fix the root "follows the conservative instruction faithfully" cause).

### Sequencing
**Choice**: Shared conventions (R1, R3) → per-skill (R2 audit, R5 persona voice) → verification pass (R6) → identity bump (R4, standalone) → optional R7.
**Rationale**: Land the shared contract first so skill edits write against final wording; R6 verifies the whole set last and doubles as the pass's acceptance check; R4 is dependency-free.
**Alternatives considered**: Per-skill-first (rejected — skill edits would reference not-yet-final convention wording).

## Scope

### In Scope

- `shared/skill-conventions.md` — Subagent Delegation (R1), Effort Recommendations table + advisory note (R3).
- `skills/audit/SKILL.md` — coverage-first finding framing (R2).
- `skills/review/SKILL.md` — fan-out instruction verified/strengthened (R1).
- `skills/party/SKILL.md`, `skills/consult/SKILL.md`, Perspectives convention — persona-voice reinforcement (R5).
- `skills/spec/SKILL.md`, `skills/discover/SKILL.md`, `skills/architect/SKILL.md` — literalism/tool-use verification (R6).
- `.claude-plugin/plugin.json`, `README.md` — model identity (R4).
- *(Could-Have)* `skills/do/SKILL.md`, `skills/quick/SKILL.md` — guardrails (R7).

### Out of Scope
XML blocks; API-parameter config (except R3 advisory); `review` coverage-first; frontend house-style; the original `cpm` plugin and other marketplace plugins; hook logic; prefill migration; the 12 stateful skills with no identified 4.8 gap.

### Deferred

- Revisiting medium-tier effort levels against real 4.8 telemetry (R3 is a best-judgment pass).
- M1/M2/M3 from `02-plan-opus-4-7-deferred-optimisations` (TDD sub-loop, `[plan]` tag heuristic, ralph scaffolding) — still 4.7-era assessments.
- Wiring new subagent fan-out into `spec`/`epics`/`discover` (R1 sets the convention; per-skill adoption is a follow-up if 4.8 warrants it).

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

Only `[manual]` (grep verification + prompt review) and `[unit]` (the existing `hooks/tests/` suite) apply to this pass — it is prompt-content with no executable behaviour to exercise end-to-end.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| R1 — Subagent delegation | `Subagent Delegation` section states 4.8 under-delegates by default; fan-out cases framed as encouraged | `[manual]` |
| R1 — Subagent delegation | `review` fan-out instruction fires under 4.8 (spawns subagents when 3+ agents selected) | `[manual]` |
| R1 — Subagent delegation | must NOT remove the "Work inline when…" guidance (no regression to 4.6 over-spawning) | `[manual]` |
| R2 — Audit coverage-first | Finding stage instructs maximise-coverage: every issue reported with severity **and** confidence | `[manual]` |
| R2 — Audit coverage-first | Filtering/ranking is explicitly the Executive Summary step, not the finding stage | `[manual]` |
| R2 — Audit coverage-first | must NOT change findings-table columns or remove the ≤10-bullet Exec Summary cap | `[unit]` |
| R3 — Effort table | Every medium-tier skill assessed for 4.8 under-thinking; rationale references 4.8 strict adherence | `[manual]` |
| R3 — Effort table | Advisory note added (thinking off by default on 4.8; ~64k output budget at xhigh/max) | `[manual]` |
| R3 — Effort table | must NOT downgrade do/epics/spec/architect/ralph below `xhigh` | `[manual]` |
| R4 — Model identity | `plugin.json` description + README reflect Opus 4.8 | `[manual]` |
| R4 — Model identity | must NOT alter `plugin.json` version or keywords; hook suite stays green | `[unit]` |
| R5 — Persona voice | party/consult/Perspectives instruct active use of roster `communicationStyle`/`personality`; identical phrasing | `[manual]` |
| R5 — Persona voice | must NOT invent persona traits outside the roster | `[manual]` |
| R6 — Verification pass | spec/discover/architect grounding requires Read/Glob/Grep before answers; literalism scoping confirmed | `[manual]` |
| R6 — Verification pass | must NOT add new behavioural instructions — verification only; documented no-change result acceptable | `[manual]` |
| R7 — Guardrails *(could)* | do/quick carry minimal-change + solve-generally (no hard-coding) guardrails in positive prose | `[manual]` |

Each must-have requirement has at least one testable criterion with a tag. The must-NOT clauses fence each requirement against 4.8's literal over-application.

### Integration Boundaries

- **Skill-chain coherence**: R1/R3 wording in `shared/skill-conventions.md` must stay consistent with how `do`/`epics`/`review` reference those conventions — verified by manual cross-reference after edits land.
- **Audit find→rank boundary**: the findings table is the contract between coverage (find) and filtering (Exec Summary); confidence must be captured where the ranking step can read it.
- **plugin.json ↔ hook tests**: `test-audit-skill.sh` asserts version `0.1.0` and the `audit` keyword; R4 touches only the description, so the suite must stay green.

### Test Infrastructure
None required. The existing `cpm2/hooks/tests/` suite (run via `run-all-tests.sh`) is adequate; R4 is verified by re-running it. All prompt-quality checks are manual grep + review, consistent with specs 25 and 29.

### Unit Testing
Unit testing of individual components is handled at the `cpm2:do` task level — the hook test suite (R4) is the only automated component; all prompt-quality verification is manual.
