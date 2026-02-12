# Spec: CPM Lifecycle Expansion

**Date**: 2026-02-12
**Brief**: Party discussion summary (cpm:party handoff)

## Problem Summary

The CPM plugin's current pipeline (discover → spec → epics → do) with supporting skills (review, pivot, retro, archive, library, party) has gaps that limit its usefulness across the full development lifecycle. There is no product ideation phase between problem discovery and requirements, architecture exploration is a single pass within spec rather than a dedicated facilitation, stakeholder communication requires ad-hoc prompting, output templates are invisible and non-customisable, and testing strategy lacks structure above the unit level. Existing skills also need updates to support new artifact types and a richer pipeline flow.

## Functional Requirements

### Must Have

1. **`cpm:brief` skill** — Facilitated product ideation. Takes a problem brief as input, explores solution approaches, and produces a product brief artifact with vision, value propositions, key features, differentiation, and user journey narratives. Saves to `docs/briefs/{nn}-brief-{slug}.md`.

2. **`cpm:architect` skill** — Facilitated architecture exploration. Takes a product brief as input, identifies key architectural decisions derived from the product (not boilerplate), explores trade-offs per decision (complexity, scalability, team capability, operational cost, time to market), captures dependencies between decisions, gives operational architecture first-class treatment, explores existing codebase before proposing, and produces ADRs. Saves to `docs/architecture/{nn}-adr-{slug}.md`.

3. **`cpm:present` skill** — Audience-aware transformation of CPM artifacts. Takes one or more CPM artifacts as input. Offers audience selection (executive, client, technical stakeholder, team onboarding, custom) and format selection (summary memo, status update, presentation outline, changelog, onboarding guide). Produces derived content — not written from scratch. Output to `docs/communications/{nn}-{format}-{slug}.md`. Regenerable when source artifacts change.

4. **`cpm:templates` skill** — Template discoverability and scaffolding. Lists all CPM artifact templates showing each skill, its output format, whether structural or presentational, and the override path if applicable. Previews any template skeleton. Scaffolds override files at `docs/templates/` for presentational templates.

5. **`cpm:discover` update** — Pipeline handoff suggests `cpm:brief` as primary next step (spec and plan remain as shortcuts for small problems).

6. **`cpm:spec` update** — Section 4 (Architecture Decisions) shifts from doing architecture to referencing ADRs from `docs/architecture/`. Reads existing ADRs, presents as context, only facilitates new decisions for gaps ADRs didn't cover. New testing strategy section consolidates what gets tested at which level, maps acceptance criteria to functional requirements, documents integration boundaries from ADRs, confirms unit testing handled at cpm:do level. Input chain accepts product briefs from `docs/briefs/`. Pipeline handoff suggests `cpm:architect` when ADRs are absent.

7. **`cpm:epics` update** — Stories reference which spec requirements they satisfy (traceability). Input chain recognises ADRs in `docs/architecture/` and references them when breaking down architectural epics.

8. **`cpm:do` update** — Epic-level verification: when all stories in an epic complete, verify the completed epic meets the spec's requirements as a whole (integration-level check). ADR awareness: when implementing tasks that touch architectural boundaries, read the relevant ADR for context.

9. **`cpm:review` update** — Can review against the spec and ADRs, not just the epic's own acceptance criteria. Answers "does this epic implement what the spec requires?" and "do these stories respect the architectural decisions?"

10. **`cpm:pivot` update** — Artefact chain discovery learns about product briefs (`docs/briefs/`) and ADRs (`docs/architecture/`). Cascade flows through: product brief → ADRs → spec → epics.

11. **Pipeline-scoped awareness** — Each skill references only what is available at its point in the pipeline. No assumptions about upstream artifacts that aren't explicitly passed forward or discoverable via known directory conventions.

12. **Two-tier template system** — Structural templates (problem briefs, specs, epic docs, review files, retro files) remain embedded in skill definitions and are not overridable — they are data contracts parsed by downstream skills. Presentational templates (product briefs, ADRs, present outputs) are overridable via `docs/templates/{skill-name}.md` or `docs/templates/present/{format-name}.md`. Project-level override fully replaces the embedded default (no merging).

13. **In-skill template hints** — All artifact-producing skills show a one-line hint at startup. Presentational: "Using default template. To customise, place your template at `docs/templates/{path}`." Structural: "Output format is fixed (used by downstream skills). Run `/cpm:templates preview {skill}` to see the format."

### Won't Have (this iteration)

- Estimation, prioritisation, or tech-debt skills
- Release management or dependency mapping skills
- Overridable structural templates (epic docs, specs, review files, retro files)
- Auto-migration of existing specs/epics to reference new artifact types

## Non-Functional Requirements

### Consistency
All new skills follow existing structural patterns: state management via `.cpm-progress.md`, AskUserQuestion for gating, library checks, retro checks (where applicable), pipeline handoffs, compaction resilience. Output artifact format conventions are consistent (YAML-style metadata fields, markdown headings for structure).

### Reliability / Compaction Resilience
Every new skill maintains the progress file with the same discipline as existing skills. The progress file contract is non-negotiable — it's the only recovery path after context compaction.

### Backward Compatibility
Existing skills continue to work with existing artifacts. Updated skills gain new capabilities (ADR awareness, template hints, spec/brief references) but don't break when those artifacts are absent. Graceful degradation: new features fail silently when the relevant files don't exist.

### Usability
New skills are discoverable via the same `/cpm:{name}` convention. Template override paths are self-documenting via the in-skill hint.

## Architecture Decisions

### Artifact Directory Structure
**Choice**: Each artifact type gets its own directory under `docs/`, following existing convention.
**Rationale**: Consistent with how briefs, specs, epics, reviews, and retros already work. Discoverable and parseable.
**Alternatives considered**: Single `docs/artifacts/` directory with type prefixes — rejected for discoverability reasons.

| Skill | Directory | Pattern |
|-------|-----------|---------|
| `cpm:brief` | `docs/briefs/` | `{nn}-brief-{slug}.md` |
| `cpm:architect` | `docs/architecture/` | `{nn}-adr-{slug}.md` |
| `cpm:present` | `docs/communications/` | `{nn}-{format}-{slug}.md` |
| `cpm:templates` | `docs/templates/` | `{skill-name}.md` or `present/{format}.md` |

### Upstream Artifact Discovery
**Choice**: Same glob-and-discover pattern as existing skills. Each skill only checks directories it directly consumes.
**Rationale**: Proven pattern. Keeps startup scanning minimal by scoping to relevant directories.
**Alternatives considered**: Central artifact registry — rejected as over-engineering for a prompt-based plugin.

### Template Override Mechanism
**Choice**: Project-level `docs/templates/{skill-name}.md` overrides embedded default. Full replacement, no merging. Applies only to presentational templates.
**Rationale**: Follows the roster.yaml precedent (project override replaces plugin default). Simple, predictable.
**Alternatives considered**: Partial merge (override specific sections) — rejected for complexity and unpredictable results.

### Skill File Structure
**Choice**: New skills at `cpm/skills/{name}/SKILL.md`. No new structural concepts.
**Rationale**: Existing pattern works. No reason to introduce additional file types or directories.
**Alternatives considered**: None — this was the obvious choice.

## Scope

### In Scope
- New skills: `cpm:brief`, `cpm:architect`, `cpm:present`, `cpm:templates`
- Existing skill updates: `cpm:discover`, `cpm:spec`, `cpm:epics`, `cpm:do`, `cpm:review`, `cpm:pivot`
- Two-tier template system with override convention
- In-skill template hints on all artifact-producing skills
- Pipeline-scoped awareness principle
- New artifact directories: `docs/briefs/`, `docs/architecture/`, `docs/communications/`, `docs/templates/`
- Plugin README update reflecting expanded pipeline

### Out of Scope
- Estimation, prioritisation, tech-debt, release management, dependency mapping skills
- Overridable structural templates
- Auto-migration of existing artifacts
- Changes to `cpm:retro`, `cpm:archive`, `cpm:library`
- Changes to agent roster format or party mode mechanics

### Deferred
- ADR status lifecycle (proposed → accepted → superseded)
- Enriched testing strategy thread (architect tagging integration boundaries, epics mapping to test levels)
- Cross-epic dependency visualisation
