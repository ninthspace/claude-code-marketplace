# Spec: Opus 5 Alignment

**Date**: 2026-07-24
**Source**: Anthropic *Prompting Claude Opus 5* — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
**Builds on**: `docs/archive/specifications/29-spec-opus-4-7-compatibility.md`, `docs/archive/specifications/32-spec-opus-4-8-alignment.md`

## Problem Summary

CPM's prompt content has been aligned to a model generation twice: spec 29 moved it to Opus 4.7's literal instruction-following and adaptive thinking, and spec 32 applied a targeted delta for Opus 4.8 (subagent under-delegation, coverage-first audit framing, strict effort adherence). Opus 5 performs well on existing 4.8 prompts, so this is a third delta pass rather than a re-audit — but it is unusual in that its dominant operation is **deletion**. Three of the tunings CPM added deliberately for 4.7/4.8 now push in the wrong direction: the Subagent Delegation section actively encourages fan-out on a model that already over-delegates; the `do`/`quick`/`epics` verification scaffolding compounds with self-verification the model performs unprompted; and the Effort Recommendations table rests on an "extended thinking is off by default" premise that is false on Opus 5. Opus 5 also introduces two pressures CPM has never had to handle: longer default responses that the effort parameter does not shorten, and longer written artefacts on disk — which matters disproportionately for a plugin whose entire output is documents. This spec scopes the delta, keeps CPM's positive-prose style, and treats removal as the default remedy where Anthropic's guidance says to remove rather than rewrite.

## Functional Requirements

### Must Have

- **R1 — Subagent delegation re-balanced for Opus 5.** Reverse spec 32's R1. Amend the `Subagent Delegation` section of `shared/skill-conventions.md` so it no longer states that the model under-delegates or that fan-out is "load-bearing"; state instead that Opus 5 delegates readily and that delegation is warranted only for large, genuinely independent, parallelisable work. Retain both the "Delegate (fan-out) when" and "Work inline when" lists, add an explicit "do not delegate work completable in a handful of tool calls" clause, and add "do not use subagents to verify or double-check your own work". Amend `skills/review/SKILL.md` to drop "fan-out is the expected path here, not an optional optimisation" and impose a spawn cap tied to the selected agent count.

- **R2 — Verification scaffolding triage in `do`, `quick`, and `epics`.** Separate *artefact-producing* verification from *model self-verification*. Artefact-producing verification is retained unchanged: the story verification gate, its acceptance-criteria pass/fail record in the epic doc, test-command execution for tagged criteria, coverage-matrix proof recording, and the Step 5b retest-after-refactor check. Model-directed re-checking layered on top is removed, not rewritten — epic-level re-verification against the source spec, and any "confirm/re-check before reporting" phrasing. Each removal carries a one-line inline rationale so a future pass can tell a deliberate deletion from an omission.

  **Step 5b retest — exempted (amended 2026-07-24).** An earlier draft of this requirement listed the Step 5b retest-after-refactor loop among the removals. Applying this spec's own artefact-production test (see Architecture Decisions) exempts it: its output drives a revert of the working tree rather than the model's confidence, its result is written into the `**Simplifier outcomes**:` line and reported per story in the batch summary (the `reverted` outcome exists only because the retest does), and Step 5b's third precondition skips the entire refactoring pass when no test command is cached precisely because the retest is the only check catching a behaviour-changing refactor. Removing it would delete a safety net, not scaffolding. The retest stays.

- **R3 — Effort Recommendations table and effort note corrected for Opus 5.** Rewrite the effort note: thinking is **on** by default on Opus 5 and can be disabled only at effort `high` or below, so the "extended thinking is off by default" premise and the strict-adherence rationale both go. Retain `xhigh` as the starting point for coding and agentic skills (`do`, `ralph`, `epics`, `quick`). Re-assess the ten `xhigh` facilitation skills — Opus 5's `low`/`medium` outperform the same settings on prior Opus models, so the 4.8 under-thinking floor no longer justifies `xhigh` for conversational work. Replace the medium-tier "strict adherence carries no under-thinking risk" rationales, which are 4.8 artefacts.

- **R4 — Response-length and narration conventions.** Add a new shared convention section covering conversational output. Opus 5's default responses run longer than prior models' and effort does not reliably shorten them, so length must be prompted explicitly. Include a conciseness instruction and a short tone reminder placed near the end of the conventions document. Add narration-cadence guidance describing the update shape wanted between `AskUserQuestion` gates, expressed as positive examples of the desired style rather than prohibitions.

- **R5 — Written deliverable length calibration.** Add length calibration to the shared conventions covering every skill that writes a file, instructing that document length match what the task needs without padding, redundant summaries, or boilerplate sections. Verify the instruction reaches the highest-volume producers: `present`, `audit`, `spec`, `epics`, `retro`.

- **R6 — Scope constraint for `quick` and `do`.** Opus 5 can widen a task's scope, adding steps that were not requested. Add an explicit scope-constraint instruction to both skills: deliver what was asked at the scope intended, make routine judgment calls without checking in, raise a better approach in a sentence and continue rather than silently transforming the task. `quick` is the priority — bypassing pipeline ceremony for small changes is its entire purpose.

- **R7 — Model identity bump.** Update the README's "v2 is tuned for Opus 4.7 and later" line and the `.claude-plugin/plugin.json` description to reflect Opus 5. Bump the plugin version.

### Should Have

- **R8 — `review` conservative-instruction reframing.** Revisit spec 32's Won't-Have. Opus 5 follows conservative review instructions literally and reports less as a result; the documented remedy is to report everything and filter in a separate pass. `review`'s 2–5 finding curation should move from the finding step to a filtering step, matching the find/rank separation `audit` already has. `audit` itself needs no change — its coverage-first framing is now reinforced by the Opus 5 guidance.

- **R9 — Self-correction narration limit.** Opus 5 narrates corrections to its own earlier statements more than prior models, which is corrosive in a facilitated conversation. Add a shared instruction limiting correction narration to errors that would change the user's conclusions or decisions. Applies to `party`, `consult`, `discover`, `brief`, `spec`, `architect`.

- **R10 — Emphatic-language drift sweep.** Spec 32 recorded CPM as having near-zero ALL-CAPS/CRITICAL/MUST language. That no longer holds: `skills/do/SKILL.md` carries 68 occurrences and `shared/skill-conventions.md` 65. Under Opus 5's literalism, emphatic phrasing over-applies. Sweep the highest-density files back to positive prose, preserving genuine safety constraints (destructive-operation guards, no-overwrite rules) as plain statements.

### Could Have

- **R11 — Progress-file machinery cost/benefit review.** Opus 5 defaults to a 1M token context window with consistent instruction-following throughout, so compaction fires far less often than the compaction-resilience design assumed. The progress file remains correct and is not removed; this requirement covers only whether the Stale-Progress Check needs to run as an early startup step in every `/cpm:*` skill, or whether a lighter trigger suffices.

### Won't Have (this iteration)

- API-parameter configuration guidance (`thinking`, `effort`, `max_tokens`) beyond R3's advisory note — CPM ships prompts, not API calls.
- XML behavioural blocks; CPM keeps positive-prose conventions.
- Skill frontmatter extensions (`model:`, `context: fork`, `allowed-tools:`) — a Claude Code platform capability, not an Opus 5 alignment concern; warrants its own spec.
- A from-scratch re-audit of all 21 skills. The 29/32 foundation holds.
- Changes to `noteplan`, `php-lsp`, `js-simplifier`, or `filament-mockup`.
- Hook logic changes; R7 touches manifest strings only.
- Changes to the `cpm board` companion tool.

## Non-Functional Requirements

### Backward Compatibility
Prompt-content only. No skill behaviour, output format, progress-file format, or hook interface changes. A session started before these edits continues working after them. R2 and R8 are intentional behavioural shifts — R2 changes how much re-checking happens (not what the epic doc records), R8 changes how many findings surface (not the review document schema).

### Consistency
Load-bearing changes land in `shared/skill-conventions.md` so per-skill edits stay thin. R4, R5, and R9 use identical phrasing wherever they appear across skills.

### Token Efficiency
This pass should **reduce** net token count across `cpm/skills/*/SKILL.md` and `shared/`. R2 and R10 are net deletions; R4, R5, R6, and R9 are short additions. Measure once at the end of the change set, not per edit.

### Maintainability
Every deletion under R2 and R10 carries an inline rationale. Reversals of prior specs (R1, R8) name the spec they reverse and why, so the 29 → 32 → 40 chain reads as a deliberate sequence rather than churn.

### Style Fidelity
All additions match CPM's positive-prose voice: no XML behavioural blocks, no ALL-CAPS, no CRITICAL/MUST framing. Where Anthropic's guidance supplies sample wording, adapt it to CPM's voice rather than pasting it.

## Architecture Decisions

### Removal as the default remedy
**Choice**: Where Anthropic's Opus 5 guidance says to remove an instruction, remove it rather than soften or rewrite it. Applies to R2 and to the discarded rationales in R3.
**Rationale**: Verification and re-check instructions compound with behaviour the model already performs, so a softened version still compounds — just less measurably. Removal is the documented remedy.
**Alternatives considered**: Rewriting instructions into weaker forms (rejected — retains the compounding); gating them behind effort level (rejected — CPM does not control effort at runtime).

### Verification triage by artefact-production test
**Choice**: Retain any verification step whose output is written into an artefact a human or a downstream skill reads. Remove any verification step whose only consumer is the model's own confidence.
**Rationale**: Gives R2 a mechanical decision rule rather than case-by-case judgment across 64 verification-language sites in `do` alone. Also protects the acceptance-criteria audit trail, which is CPM's product, from being mistaken for scaffolding.
**Reading the rule (added 2026-07-24)**: "Output written into an artefact" includes a step whose result drives control flow — a revert, a skip, a branch — not only one that writes prose into a document. A step that changes what happens next has a consumer other than the model's confidence, and is retained. The Step 5b retest is the worked example: it was initially mis-listed as a removal under R2 because only its document-writing effect was weighed, and its revert effect was not.
**Alternatives considered**: Removing all verification language (rejected — destroys the verification gate); keeping everything and lowering effort (rejected — does not address the compounding cause).

### Shared-first placement, unchanged from spec 32
**Choice**: R1, R3, R4, R5, R9 land in `shared/skill-conventions.md`; per-skill edits only where behaviour is skill-specific (`review` fan-out and finding stage, `quick`/`do` scope, `do`/`quick`/`epics` verification).
**Rationale**: Propagates to every referencing skill in one reviewable diff. Consistent with the two prior alignment passes.
**Alternatives considered**: Per-skill duplication (rejected — drifts, as R10 demonstrates).

### Sequencing
**Choice**: Shared conventions (R1, R3, R4, R5, R9) → per-skill behavioural edits (R2, R6, R8) → drift sweep (R10) → identity bump (R7, dependency-free) → optional R11.
**Rationale**: Skill edits should write against final convention wording. R10 runs last so it also catches emphatic language introduced during this pass.
**Alternatives considered**: Running R10 first (rejected — would need re-running afterwards).

## Scope

### In Scope

- `shared/skill-conventions.md` — Subagent Delegation (R1), Effort Recommendations table and note (R3), new response-length/narration section (R4), deliverable length calibration (R5), self-correction limit (R9).
- `skills/do/SKILL.md` — verification triage (R2), scope constraint (R6), emphatic-language sweep (R10).
- `skills/quick/SKILL.md` — verification triage (R2), scope constraint (R6).
- `skills/epics/SKILL.md` — verification triage (R2).
- `skills/review/SKILL.md` — fan-out cap (R1), find/rank separation (R8).
- `skills/present/SKILL.md`, `skills/audit/SKILL.md`, `skills/spec/SKILL.md`, `skills/retro/SKILL.md` — deliverable length verification (R5).
- `skills/party/SKILL.md`, `skills/consult/SKILL.md`, `skills/discover/SKILL.md`, `skills/brief/SKILL.md`, `skills/architect/SKILL.md` — self-correction limit (R9).
- `.claude-plugin/plugin.json`, `README.md` — model identity and version (R7).

### Out of Scope
API-parameter configuration; XML blocks; skill frontmatter extensions; `audit`'s finding stage (already correct); the `cpm board` tool; hook logic; other marketplace plugins; the skills with no identified Opus 5 gap (`archive`, `clean`, `library`, `pivot`, `ralph`, `status`, `templates`) beyond what shared conventions propagate.

### Deferred

- Re-validating the R3 effort levels against real Opus 5 telemetry. R3 is a best-judgment pass; Anthropic's guidance is explicit that carried-over effort defaults deserve a fresh sweep on real evals, which CPM does not yet have.
- Building that eval harness — a set of representative CPM sessions with recorded output, so future alignment passes are measured rather than reasoned. This is the largest gap the 29/32/40 sequence has accumulated.
- R11 if not taken in this iteration.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag.

Only `[manual]` (grep verification and prompt review) and `[unit]` (the existing `hooks/tests/` suite) apply — this is prompt content with no executable behaviour to exercise end-to-end.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| R1 — Subagent delegation | `Subagent Delegation` no longer claims the model under-delegates; fan-out framed as warranted only for large independent work | `[manual]` |
| R1 — Subagent delegation | "do not use subagents to verify your own work" clause present | `[manual]` |
| R1 — Subagent delegation | `review` fan-out carries a spawn cap; "expected path, not an optional optimisation" removed | `[manual]` |
| R1 — Subagent delegation | must NOT remove the "Work inline when" list or the self-contained-prompt rules | `[manual]` |
| R2 — Verification triage | Story verification gate, criteria pass/fail recording, test execution, coverage-matrix proof, and the Step 5b retest all still present and unchanged | `[manual]` |
| R2 — Verification triage | Epic-level spec re-verification removed | `[manual]` |
| R2 — Verification triage | Every removal carries an inline rationale | `[manual]` |
| R2 — Verification triage | must NOT weaken any verification whose output is written to an artefact | `[manual]` |
| R3 — Effort table | Effort note states thinking on by default; disable only at `high` or below | `[manual]` |
| R3 — Effort table | 4.8 strict-adherence rationales removed from every tier | `[manual]` |
| R3 — Effort table | must NOT downgrade `do`, `epics`, `ralph`, or `quick` below their coding/agentic starting point | `[manual]` |
| R4 — Response length | Conciseness instruction plus a short tone reminder near the end of the conventions document | `[manual]` |
| R4 — Response length | Narration cadence expressed as positive examples, not prohibitions | `[manual]` |
| R5 — Deliverable length | Length-calibration instruction present in shared conventions and reaching `present`, `audit`, `spec`, `epics`, `retro` | `[manual]` |
| R5 — Deliverable length | must NOT impose fixed word or section counts on any artefact template | `[manual]` |
| R6 — Scope constraint | `quick` and `do` both carry the scope-constraint instruction in positive prose | `[manual]` |
| R6 — Scope constraint | must NOT conflict with `do`'s existing inline-change breadcrumb behaviour | `[manual]` |
| R7 — Model identity | README and `plugin.json` description reflect Opus 5; version bumped; hook suite green | `[unit]` |
| R8 — Review reframing *(should)* | Finding step reports all findings; curation to 2–5 happens at a named filtering step | `[manual]` |
| R8 — Review reframing *(should)* | must NOT change the review document schema or the autofix handoff | `[manual]` |
| R9 — Correction narration *(should)* | Identical correction-narration wording present across the six facilitation skills | `[manual]` |
| R10 — Drift sweep *(should)* | Emphatic-language count in `do` and `skill-conventions` materially reduced | `[manual]` |
| R10 — Drift sweep *(should)* | must NOT remove destructive-operation guards or no-overwrite rules; they become plain statements | `[manual]` |
| R11 — Progress machinery *(could)* | Stale-Progress Check trigger reviewed; no-change outcome acceptable and documented | `[manual]` |

Each must-have requirement has at least one testable criterion. The must-NOT clauses fence each requirement against over-application — the dominant risk in a pass whose main operation is deletion.

### Integration Boundaries

- **Shared → skill coherence**: R1/R3/R4/R5/R9 wording must stay consistent with how `do`, `epics`, `review`, and the facilitation skills reference those conventions. Verified by cross-reference after the shared edits land.
- **Verification gate → coverage matrix**: the gate's pass/fail output is the contract feeding coverage-matrix proof recording. R2 must not disturb it; this is the boundary the artefact-production test exists to protect.
- **Review find → filter**: R8 introduces the same two-stage boundary `audit` has. The full finding set must be captured somewhere the filtering step can read before curation happens.
- **`plugin.json` ↔ hook tests**: `test-audit-skill.sh` asserts manifest fields. R7 touches the description and version, so the suite must be re-run.

### Test Infrastructure
None required. The existing `cpm/hooks/tests/` suite (via `run-all-tests.sh`) covers R7. All prompt-quality checks are manual grep and review, consistent with specs 29 and 32.

### Unit Testing
Handled at the `cpm:do` task level. The hook test suite is the only automated component; everything else is manual verification.
