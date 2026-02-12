# Product Brief Skill

**Source spec**: docs/specifications/14-spec-cpm-lifecycle-expansion.md
**Date**: 2026-02-12
**Status**: Complete
**Blocked by**: —

## Build the cpm:brief facilitation engine
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Skill follows all standard CPM structural patterns (retro check, library check, AskUserQuestion gating)
- Facilitation uses AskUserQuestion for phase gating — never dumps multiple phases at once
- State management via `.cpm-progress.md` with compaction resilience
- Agent perspectives use roster (project override then plugin default)
- Input chain reads problem briefs from `docs/plans/` and accepts `$ARGUMENTS`

### Create skill directory and SKILL.md with front-matter and input discovery
**Task**: 1.1
**Description**: Set up `cpm/skills/brief/SKILL.md` with YAML front-matter, input chain (reads problem briefs from `docs/plans/`, accepts arguments), and startup checks (retro, library).
**Status**: Complete

### Design facilitation phases for product ideation
**Task**: 1.2
**Description**: Define the phase sequence — solution approaches, vision framing, value propositions, feature identification, differentiation analysis, user journey narratives — with AskUserQuestion gating and agent perspective integration points.
**Status**: Complete

### Add state management and pipeline handoff
**Task**: 1.3
**Description**: Add `.cpm-progress.md` state tracking per phase, compaction resilience, and pipeline handoff suggesting `cpm:architect` (when architecture needs exploration) or `cpm:spec` (when ready for requirements).
**Status**: Complete

---

## Design the product brief artifact format
**Story**: 2
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Artifact format captures all spec-required fields (vision, value propositions, key features, differentiation, user journey narratives)
- Template hint displays on startup ("Using default template. To customise, place your template at `docs/templates/brief.md`.")
- Directory `docs/briefs/` created if absent
- Auto-incrementing numbered file naming (`{nn}-brief-{slug}.md`)

### Define the product brief output format and template hint
**Task**: 2.1
**Description**: Design the markdown artifact structure covering vision, value propositions, key features, differentiation, and user journey narratives. Add auto-incrementing file naming to `docs/briefs/{nn}-brief-{slug}.md`, directory creation, and presentational template hint at startup.
**Status**: Complete

---
