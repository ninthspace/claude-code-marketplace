# Spec Testing Strategy

**Source spec**: docs/specifications/15-spec-cpm-testing-activities.md
**Date**: 2026-02-12
**Status**: Complete
**Blocked by**: —

## Enhance Section 6 testing strategy facilitation
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Requirement 1 (test approach per criterion), Requirement 6 (test infrastructure requirements)

**Acceptance Criteria**:
- Section 6 defines the four-tag vocabulary (`[unit]`, `[integration]`, `[feature]`, `[manual]`) before assigning tags [manual]
- For each must-have functional requirement, Section 6 facilitates assigning a test approach tag to its acceptance criteria [manual]
- Criteria without a test approach tag are flagged as incomplete rather than just flagging vague criteria [manual]
- Section 6 captures test infrastructure requirements (frameworks, fixtures, databases, CI) as a distinct subsection [manual]
- Backward compatibility: if the user declines to tag criteria, Section 6 falls back to current lightweight behaviour [manual]

### Rewrite Section 6 in SKILL.md
**Task**: 1.1
**Description**: Replace current Section 6 content with enhanced facilitation: tag vocabulary definition, per-criterion tag assignment, infrastructure capture, and graceful fallback
**Status**: Complete

### Update Section 6 progress file format
**Task**: 1.2
**Description**: Ensure the progress file captures tag assignments and infrastructure needs for compaction resilience
**Status**: Complete

---

## Update spec output template for testing strategy
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Requirement 1 (test approach per criterion), Requirement 5 (pipeline thread — spec stage), Requirement 6 (test infrastructure)

**Acceptance Criteria**:
- The output template's Testing Strategy section includes a "Tag Vocabulary" reference defining the four tags [manual]
- The Acceptance Criteria Coverage subsection includes test approach tags inline with each criterion [manual]
- A new "Test Infrastructure" subsection captures infrastructure requirements [manual]
- The output is parseable by `cpm:epics` — tags follow a consistent `[tag]` format within acceptance criteria text [manual]

### Update the output template markdown in SKILL.md
**Task**: 2.1
**Description**: Amend the Testing Strategy section of the spec output template to include tag vocabulary, tagged criteria, and test infrastructure subsection
**Status**: Complete

---
