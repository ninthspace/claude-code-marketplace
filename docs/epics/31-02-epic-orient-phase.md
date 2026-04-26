# Orient Phase

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Date**: 2026-04-25
**Status**: Pending
**Blocked by**: Epic 31-01-epic-skill-scaffolding

## Orient — codebase reads, git history, commit SHA capture
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: #3 (orient phase), #5 (commit SHA capture)

**Acceptance Criteria**:

- Skill reads README during orient (when present) `[manual]`
- Skill reads each detected package manifest (`package.json`, `composer.json`, `pyproject.toml`/`requirements.txt`/`setup.py`, `Cargo.toml`, `go.mod`) `[manual]`
- Skill reads top-level directory structure `[manual]`
- Skill captures git history via `git log --oneline -200` and `git log --stat --since="6 months ago"` `[manual]`
- Skill identifies top-20 largest files and top-20 most-modified files in the past 6 months `[manual]`
- `git rev-parse HEAD` is captured during orient and recorded in deliverable header as `**Audited at**: <40-char-sha>` `[unit]`

### Document orient reads
**Task**: 1.1
**Description**: Document the orient phase reads of README, package manifests for each stack, and top-level directory structure in SKILL.md. Covers the first three criteria.
**Status**: Complete

### Document git history invocations
**Task**: 1.2
**Description**: Document the git log invocations in SKILL.md: `git log --oneline -200` for recent commit summary and `git log --stat --since="6 months ago"` for file-change activity. Covers the git-history criterion.
**Status**: Complete

### Document top-20 file ranking
**Task**: 1.3
**Description**: Document the procedure for identifying top-20 largest files (by line count) and top-20 most-modified files in the past 6 months. Note the source skill's framing — "the intersection is where debt usually hides." Covers the file-ranking criterion.
**Status**: Complete

### Document commit SHA capture
**Task**: 1.4
**Description**: Document `git rev-parse HEAD` capture during orient and the `**Audited at**: <sha>` header field in the deliverable. Covers the SHA criterion.
**Status**: Complete

### Write tests for commit SHA capture
**Task**: 1.5
**Description**: Write automated tests asserting that audit deliverable headers contain `**Audited at**:` followed by a 40-character hex string matching the project's `git rev-parse HEAD` at audit time.
**Status**: Complete

**Retro**: [Codebase discovery] The "test deliverable shape" pattern needs to handle the case where deliverables don't yet exist (skill hasn't been run). Vacuous-pass when `docs/audits/` is empty plus per-file format checks when files do exist gives a clean structural test that grows automatically as the skill is used. Reusable for any test verifying runtime-produced artifacts.

---

## Passive cpm2 artifact read (no bias)
**Story**: 2
**Status**: Pending
**Blocked by**: —
**Satisfies**: #4 (passive cpm2 artifact read)

**Acceptance Criteria**:

- Skill reads `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` if present, surfacing them as context to the user `[manual]`
- (must NOT) Skill must NOT use cpm2 artifact contents to skip dimensions, shortcut findings, or otherwise bias the independent sweep `[manual]`

### Document passive cpm2 artifact read
**Task**: 2.1
**Description**: Document the read of `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` as passive context only. Include the must-NOT clause prominently as a non-negotiable rule in SKILL.md — passive reads must not bias the independent sweep. Covers both criteria.
**Status**: Pending

---

## Stack detection
**Story**: 3
**Status**: Pending
**Blocked by**: —
**Satisfies**: #6 (stack detection)

**Acceptance Criteria**:

- `package.json` present → TS/JS detected `[manual]`
- `composer.json` present → PHP detected `[manual]`
- `composer.json` + `artisan` present → Laravel detected (PHP overlay remains active) `[manual]`
- `pyproject.toml` or `requirements.txt` or `setup.py` present → Python detected `[manual]`
- `Cargo.toml` present → Rust detected `[manual]`
- `go.mod` present → Go detected `[manual]`
- Multi-stack projects detect every applicable stack `[manual]`

### Document stack detection table
**Task**: 3.1
**Description**: Document the manifest-presence detection table in SKILL.md: file → stack mapping, the Laravel-as-PHP-overlay rule, and explicit multi-stack support (every applicable stack contributes its tooling). Covers all detection criteria.
**Status**: Pending

---

## User-shaping question after orient
**Story**: 4
**Status**: Pending
**Blocked by**: Story 1, Story 3
**Satisfies**: #9 (user-shaping question)

**Acceptance Criteria**:

- After orient completes, skill presents an `AskUserQuestion`: "Specific areas to focus on, or sweep all 9 dimensions evenly?" `[manual]`
- User input shapes the subsequent sweep (focus area noted as a hint) but does NOT cause any dimension to be skipped `[manual]`
- (must NOT) Skill must NOT use the user response as license to skip dimensions `[manual]`

### Document user-shaping AskUserQuestion
**Task**: 4.1
**Description**: Document the post-orient AskUserQuestion in SKILL.md, including the question text, the must-NOT clause about not skipping dimensions, and how user input is incorporated downstream as a focus hint (not a scope reducer). Covers all criteria.
**Status**: Pending

---
