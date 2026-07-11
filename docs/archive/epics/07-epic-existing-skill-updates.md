# Existing Skill Updates

**Source spec**: docs/specifications/14-spec-cpm-lifecycle-expansion.md
**Date**: 2026-02-12
**Status**: Complete
**Blocked by**: Epic 04-epic-product-brief-skill, Epic 05-epic-architecture-exploration-skill, Epic 06-epic-communication-and-templates

## Update cpm:discover with brief handoff
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Pipeline handoff suggests `cpm:brief` as primary next step
- `cpm:spec` and `/plan` remain available as alternatives for small problems
- Backward compatible — works without `cpm:brief` skill present

### Update pipeline handoff in cpm:discover SKILL.md
**Task**: 1.1
**Status**: Complete

---

## Update cpm:spec with ADR and brief awareness
**Story**: 2
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Section 4 (Architecture) references existing ADRs instead of doing architecture from scratch
- Reads existing ADRs and presents as context; only facilitates new decisions for gaps
- Input chain accepts product briefs from `docs/briefs/`
- New testing strategy section maps acceptance criteria to requirements and documents integration boundaries
- Pipeline handoff suggests `cpm:architect` when ADRs are absent
- Graceful degradation when ADRs or briefs don't exist

### Add product brief input chain and ADR discovery
**Task**: 2.1
**Description**: Extend input handling to accept product briefs from `docs/briefs/`. Add ADR discovery from `docs/architecture/` with graceful degradation.
**Status**: Complete

### Refactor Section 4 to reference ADRs
**Task**: 2.2
**Description**: Change architecture section from doing architecture to referencing existing ADRs, presenting them as context, and only facilitating decisions for gaps.
**Status**: Complete

### Add testing strategy section
**Task**: 2.3
**Description**: New section that maps acceptance criteria to functional requirements, documents integration boundaries from ADRs, and confirms unit testing handled at cpm:do level.
**Status**: Complete

### Update pipeline handoff
**Task**: 2.4
**Description**: Suggest `cpm:architect` when ADRs are absent.
**Status**: Complete

---

## Update cpm:epics with traceability and ADR references
**Story**: 3
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Stories include traceability to spec requirements (which functional requirements each story satisfies)
- ADRs in `docs/architecture/` are discovered and referenced when breaking down architectural work
- Graceful degradation when ADRs don't exist

### Add spec requirement traceability to stories
**Task**: 3.1
**Description**: Stories reference which spec requirements they satisfy.
**Status**: Complete

### Add ADR discovery to input chain
**Task**: 3.2
**Description**: Recognise ADRs in `docs/architecture/` and reference them when breaking down architectural epics.
**Status**: Complete

---

## Update cpm:do with epic verification and ADR awareness
**Story**: 4
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- When all stories in an epic complete, verify the completed epic meets the spec's requirements as a whole (integration-level check)
- When implementing tasks that touch architectural boundaries, read the relevant ADR for context
- Graceful degradation when ADRs don't exist

### Add epic-level verification on completion
**Task**: 4.1
**Description**: When all stories in an epic complete, verify the completed epic meets the spec's requirements as a whole (integration-level check).
**Status**: Complete

### Add ADR awareness during task implementation
**Task**: 4.2
**Description**: When implementing tasks that touch architectural boundaries, read the relevant ADR for context.
**Status**: Complete

---

## Update cpm:review with spec and ADR review capability
**Story**: 5
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Can review whether an epic implements what the spec requires
- Can review whether stories respect architectural decisions from ADRs
- Graceful degradation when spec or ADRs don't exist

### Add spec compliance review
**Task**: 5.1
**Description**: Review whether an epic implements what the spec requires.
**Status**: Complete

### Add ADR compliance review
**Task**: 5.2
**Description**: Review whether stories respect architectural decisions from ADRs.
**Status**: Complete

---

## Update cpm:pivot with new artifact chain discovery
**Story**: 6
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Artifact chain discovery includes `docs/briefs/` and `docs/architecture/`
- Cascade flow: product brief → ADRs → spec → epics
- Graceful degradation when new artifact types don't exist

### Extend artifact chain discovery and cascade flow
**Task**: 6.1
**Description**: Add `docs/briefs/` and `docs/architecture/` to artifact discovery. Update cascade: product brief → ADRs → spec → epics.
**Status**: Complete

---
