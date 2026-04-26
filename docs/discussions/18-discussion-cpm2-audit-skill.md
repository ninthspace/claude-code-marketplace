# Discussion: Adapt the `tech-debt-audit` skill into cpm2 as a new skill (`cpm2:audit`)

**Date**: 2026-04-25
**Agents**: Margot (Architect), Bella (Senior Developer), Jordan (PM), Tomas (QA), Elli (Writer), Ren (Scrum Master), Priya (UX)

## Source material

External skill: [ksimback/tech-debt-skill @ 5a15c1c](https://github.com/ksimback/tech-debt-skill/blob/5a15c1ca4a929b2759461c218478de391a8bda0f/SKILL.md)

Source skill summary:

- Name `tech-debt-audit`, `disable-model-invocation: true`, user-invoked only.
- **Phase 1 — Orient**: README, manifests, git history (`git log --oneline -200`, `--stat --since="6 months ago"`), entry points, top-20 largest + most-modified files, mental model.
- **Phase 2 — Audit** across 9 dimensions with `file:line` citations:
  1. Architectural decay
  2. Consistency rot
  3. Type & contract debt
  4. Test debt
  5. Dependency & config debt
  6. Performance & resource hygiene
  7. Error handling & observability
  8. Security hygiene
  9. Documentation drift
- **Phase 3 — Deliverable**: `TECH_DEBT_AUDIT.md` with executive summary, mental model, findings table (30–80 entries), top 5 priorities, quick wins, "looks bad but is actually fine" (required), open questions.
- Stack-specific tooling per language; large-repo subagent dispatch (>50k LOC); repeat-run mode marks RESOLVED/NEW.
- Hard rules: every finding cited file:line, no rewrites, no padding, scoped recommendations only.

## Decisions

### 1. Land as a new cpm2 skill, not a merge

**Decision**: Add as `cpm2:audit`. Do not merge into existing skills (`status`, `architect`, `retro`, `discover`).

**Why**: The user has observations about an inherited/existing project that no spec or epic ever surfaced — that's a genuine gap in the cpm2 pipeline. cpm2 today catches what *planning* surfaces; it has no skill for systematically auditing what's actually in a codebase. Existing skills are oriented around future work (status, architect) or post-hoc reflection on planned work (retro), not independent codebase inspection.

### 2. Position as input to the pipeline, not a stage in it

**Decision**: `cpm2:audit` is an input source. Findings fan out into the existing pipeline via handoffs:

- Findings → `cpm2:library` (as reference docs)
- Top 5 priorities → `cpm2:spec` (as starting brief)
- Quick wins → `cpm2:quick` (one-shot execution)
- Done

**Why**: The original skill terminates at a markdown file. The cpm2 value-add is the handoff — turning audit output into actionable downstream work. Don't try to insert audit between discover→brief→spec→epics; it sits beside that pipeline.

### 3. Skill name: `cpm2:audit`

**Decision**: Name is `cpm2:audit`. Description should make the cpm2-aware angle explicit, e.g. *"Surface observations the planning pipeline missed — debt, drift, and inherited code that no spec or epic ever touched."*

**Why**: `audit` is the most-recognised verb for this activity and pairs naturally with the existing roster (`status`, `retro`, `review`). `tech-debt-audit` over-scopes to debt; the actual scope is broader. `inspect`/`survey` were considered but `audit` is clearest.

### 4. Output location and numbering

**Decision**: Output to `docs/audits/{nn}-audit-{slug}.md` via the shared Numbering procedure. The hardcoded `TECH_DEBT_AUDIT.md` at repo root from the source skill is dropped.

**Why**: Aligns with cpm2's numbered-artifact convention and supports multiple audits over time (different scopes, refresh runs).

### 5. v1 procedure (sequenced)

1. Library Check (scope keyword `audit`) + Retro Awareness
2. Input parsing — optional scope hint (e.g. `/cpm2:audit src/auth/`)
3. **Orient phase**: README, manifests, structure, git history, top-20 largest + most-modified files, *and* existing cpm2 artifacts (`docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/`) as **passive context only** — explicitly noted as "context, not constraint". The full independent sweep proceeds regardless.
4. **User-shaping question** (AskUserQuestion): "I've mapped the codebase. Before I go deep, are there specific areas you want me to focus on, or should I sweep all 9 dimensions evenly?" — gives the user a chance to point at known concerns without biasing the orient phase.
5. **9-dimension sweep** with `file:line` citations preserved verbatim from source.
6. **Deliverable** — all source sections including `file:line` findings table (30–80 entries), top 5 priorities, quick wins, and "looks bad but is actually fine".
7. **Handoff offer** (AskUserQuestion): library / spec / quick / done — concrete actionable buttons, not abstract suggestions.
8. Progress file lifecycle follows shared Progress File Management.

### 6. Non-negotiables preserved from source

- **`file:line` citations on every concrete finding** — load-bearing rule; turns vague observations into actionable items.
- **"Things that look bad but are actually fine" section** — surfaces considered-but-rejected findings; separates real audits from checklist regurgitation.
- **No rewrites** — recommend scoped changes only.
- **No padding** — remove empty categories entirely; only write "Nothing material" if justified.

### 7. Cuts from v1 (deferred to future enhancements)

- **Subagent dispatch for >50k LOC repos**: cpm2 has no precedent for parallel `Task` fan-out; build it carefully later, not as part of v1.
- **Repeat-run mode** (RESOLVED/NEW tagging): adds state-management complexity v1 doesn't need.
- **Contrast against existing cpm2 artifacts**: explicitly cut. Past planning doesn't constrain future debt assessment, and contrasting findings against old specs adds implementation surface without changing what the audit catches.

These are documented in the SKILL.md as "future enhancements" so users know what's deliberately missing.

## Key points and rationale

- **Orientation reads are passive fuel, not constraint.** Reading existing `docs/` artifacts during orient gives the auditor context but must not let them shortcut the full independent sweep. The auditor sees what's there *and* what planning says about it, then audits the codebase fresh.
- **One AskUserQuestion moment between orient and sweep is the right user-shaping balance.** The source skill is silent end-to-end and dumps a 30–80-finding document on the user. cpm2's idiom is conversational; one well-placed question lets the user steer without biasing the orient phase.
- **The skill must explicitly distance itself from `retro` and `architect`.** Description should make clear: use `cpm2:audit` for inherited/existing code that wasn't planned through cpm2; use `retro` for reflecting on cpm2-planned work; use `architect` for forward-looking decision exploration.
- **Ship v1 narrow, validate against real observations, then layer cleverness.** Subagent dispatch and existing-artifact contrast are tempting but back-load risk. v1 should be a faithful retrofit + handoffs, nothing more.

## Open questions

None blocking. All major v1 design questions resolved during the discussion.

## Next step

Write up as a problem brief via `/cpm2:brief`, using this discussion record as input context.
