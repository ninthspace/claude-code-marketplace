# Architecture Exploration Skill

**Source spec**: docs/specifications/14-spec-cpm-lifecycle-expansion.md
**Date**: 2026-02-12
**Status**: Complete
**Blocked by**: —

## Build the cpm:architect facilitation engine
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Decisions are product-derived, not generic boilerplate
- Trade-off analysis covers all spec-required dimensions (complexity, scalability, team capability, operational cost, time to market)
- Existing codebase explored (Read, Glob, Grep) before proposing architecture
- Dependencies between decisions are captured
- Operational architecture given first-class treatment
- Standard CPM structural patterns followed (retro check, library check, AskUserQuestion gating)

### Create skill directory and SKILL.md with front-matter and input discovery
**Task**: 1.1
**Description**: Set up `cpm/skills/architect/SKILL.md` with YAML front-matter, input chain (reads product briefs from `docs/briefs/`, accepts arguments), and startup checks (retro, library).
**Status**: Complete

### Design the architecture exploration facilitation process
**Task**: 1.2
**Description**: Define phases for identifying product-derived decisions, exploring trade-offs (complexity, scalability, team capability, operational cost, time to market), capturing decision dependencies, and giving operational architecture first-class treatment. Include codebase exploration before proposing.
**Status**: Complete

### Add state management, perspectives, and pipeline handoff
**Task**: 1.3
**Description**: Add `.cpm-progress.md` state tracking, compaction resilience, agent perspective integration, and pipeline handoff to `cpm:spec`.
**Status**: Complete

---

## Define the ADR artifact format
**Story**: 2
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- ADR format follows established conventions (context, options considered, decision, rationale, consequences)
- Each architectural decision produces its own ADR file
- Template hint displays on startup ("Using default template. To customise, place your template at `docs/templates/architect.md`.")
- Directory `docs/architecture/` created if absent
- Auto-incrementing numbered file naming (`{nn}-adr-{slug}.md`)

### Design the ADR output format and template hint
**Task**: 2.1
**Description**: Design the ADR markdown structure (context, options, decision, rationale, consequences). Add auto-incrementing file naming to `docs/architecture/{nn}-adr-{slug}.md`, directory creation, and presentational template hint at startup.
**Status**: Complete

---
