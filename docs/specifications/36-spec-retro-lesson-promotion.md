# Spec: Retro Lesson Promotion (`cpm:retro learn`)

**Date**: 2026-06-17
**Brief**: n/a (inline description; follows quick #15 cross-retro selection + #16 Retro Retirement — see `docs/quick/15-quick-retro-awareness-all-retros-spec.md` and `docs/quick/16-quick-durable-obsolete-retro-lessons-spec.md`)

## Problem Summary

Retros are transient feed-forward, but a lesson repeatedly given the *Applied* disposition across `cpm:do` runs is a durable truth stuck in the wrong layer — it must be re-surfaced and re-judged every run. This feature adds a manual `cpm:retro learn` action that graduates a chosen retro lesson into the permanent reference library (`docs/library/lessons-learned.md`) and, atomically, retires the source retro observation via the #16 Retro Retirement marker so it stops resurfacing in Retro Awareness while persisting durably for Library Check.

## Functional Requirements

### Must Have

- **`learn` action on `cpm:retro`** — invoking `/cpm:retro learn` enters a promotion flow (distinct from the default synthesis flow).
- **Candidate selection** — scan `docs/retros/` observations, **excluding any already carrying a `**Retired` marker**, present them grouped by source retro/category, and let the user pick the lesson(s) to promote.
- **Library write** — append the lesson as a `##` entry to `docs/library/lessons-learned.md`, creating the file with conformant `cpm:library` front-matter on first promotion.
- **Front-matter conformance** — the file uses `cpm:library`'s six-field model (`title`/`source`/`added`/`last-reviewed`/`scope`/`summary`); `scope` derived via `cpm:library`'s **auto-scope heuristics** (unioned across entries); `last-reviewed` bumped on each append.
- **Atomic retirement** — on a successful write, retire the source observation in its retro via the #16 marker, reason = `promoted to docs/library/lessons-learned.md`. Promotion and retirement are one operation.
- **Bidirectional provenance** — the library entry records its source retro path + category + observation text + promotion date; the retro marker points back to the library doc.
- **Idempotency** — an observation already retired/promoted is not offered and not duplicated.

### Should Have

- Multi-select promotion in one invocation.
- A confirmation preview (proposed entry + derived scope + the retirement that will follow) before writing.

### Could Have

- Surface "frequently Applied" lessons as *suggested* candidates by scanning `**Retro applied**` breadcrumbs across epic docs — a read-only seed for a future automatic trigger.

### Won't Have (this iteration)

- Automatic / threshold-based promotion.
- File-per-lesson layout.
- Demote / un-promote tooling (reversible by hand: remove the entry + the retirement marker).
- Editing existing library entries.

## Non-Functional Requirements

- **Consistency** — promoted entries must be structurally indistinguishable from hand-imported library docs, so Library Check treats `lessons-learned.md` uniformly.
- **Safety** — never delete retro content (retirement is the in-place #16 marker only); never destructively overwrite `lessons-learned.md` (append-only).
- **Reversibility** — the bidirectional trail makes manual reversal unambiguous.

## Architecture Decisions

### Host: `cpm:retro learn` action
**Choice**: Promotion is a new action on `cpm:retro`, not a new `cpm:library` action or a `cpm:do` gate hook.
**Rationale**: Retros are the source of lessons; "learn" frames graduating a lesson into durable knowledge, keeping curation within the retro lifecycle.
**Alternatives considered**: `cpm:library promote` (rejected — keeps source-side curation together with the retro); `cpm:do` at the gate (rejected — bloats the run loop).

### `cpm:library` intake format is the single source of truth
**Choice**: `learn` *conforms to* `cpm:library`'s front-matter model and auto-scope heuristics by reference; it does not reimplement them.
**Rationale**: Avoids divergence between two skills writing `docs/library/`. If duplication of the rules proves awkward, factoring them into a shared convention (e.g. in `shared/skill-conventions.md`) is the implementation option — a call for `cpm:epics`.
**Alternatives considered**: Reimplementing front-matter generation inside `cpm:retro` (rejected — drift risk).

### Single themed doc with per-entry sections
**Choice**: One `docs/library/lessons-learned.md` with a single file-level front-matter block; each promoted lesson is a `##` section. `scope` is the union of entry scopes; `summary` stays general ("accumulated durable lessons promoted from retros").
**Rationale**: Keeps lessons together, one doc to triage, no file sprawl.
**Alternatives considered**: File-per-lesson (rejected — sprawl; precise per-file scope not worth it at this volume).

### Atomic promote-then-retire
**Choice**: Retirement is part of the `learn` action, not a separate step.
**Rationale**: Prevents a promoted lesson double-surfacing (library via Library Check *and* retro via Retro Awareness). Graduation implies retirement.

## Scope

### In Scope

- Manual `cpm:retro learn` action.
- Candidate selection excluding retired observations.
- Single themed `docs/library/lessons-learned.md`.
- Auto-scope derivation (unioned across entries).
- Atomic retirement on promotion.
- Bidirectional provenance.
- Idempotency / no duplication.

### Out of Scope

- Automatic / threshold-based promotion.
- File-per-lesson layout.
- Demote / un-promote tooling.
- Editing existing library entries.

### Deferred

- Read-only suggestion of frequently-Applied candidates (Could Have) → seed for a later automatic trigger.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: red-green-refactor loop, composable with any level tag

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| `learn` action | `/cpm:retro learn` is documented in `cpm:retro` SKILL and enters the promotion flow, distinct from synthesis | `[manual]` |
| Candidate selection | Only non-retired observations are offered; **must NOT** present an observation carrying a `**Retired` marker | `[manual]` |
| Library write | First promotion creates `lessons-learned.md` with conformant front-matter; later ones append; **must NOT** overwrite existing content | `[manual]` |
| Front-matter conformance | `scope` derived via library auto-scope heuristics (unioned); `last-reviewed` bumped per append; file passes Library Check consumption | `[manual]` (+ `[integration]` at consume time — see boundaries) |
| Atomic retirement | Successful write retires the source observation with reason → library doc; **must NOT** leave a promoted lesson un-retired | `[manual]` |
| Bidirectional provenance | Library entry → retro (path/category/observation/date); retro marker → library doc | `[manual]` |
| Idempotency | Re-running on an already-promoted lesson is a no-op; **must NOT** create a duplicate entry | `[manual]` |

*All criteria are `[manual]`: the behaviour is skill-instruction prose plus a generated Markdown artifact — there is no executable code path, so verification is inspection plus a dry-run of the action. Justification recorded per `cpm:epics` Default-to-automation guidance: no test harness covers SKILL.md prose behaviour.*

### Integration Boundaries
`cpm:retro` ↔ `docs/library/` **format contract**: `lessons-learned.md` must satisfy `cpm:library`'s front-matter expectations so Library Check consumes it like any other library doc. This is the one seam worth an explicit conformance check (could be automated later against the library doc shape).

### Test Infrastructure
None required.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — here, inspection-based, given no executable surface.
