# Adversarial Review Skill

**Source spec**: docs/specifications/13-spec-review.md
**Date**: 2026-02-11
**Status**: Complete
**Blocked by**: —

## Build the core review SKILL.md
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Skill accepts epic doc path via `$ARGUMENTS` or auto-discovers most recent epic doc
- Roster loading follows party mode pattern (project `docs/agents/roster.yaml` → plugin default)
- Library docs filtered by `review` or `all` scope are referenced during review
- Agent selection is dynamic: 2-3 for single stories, 3-4 for full epics, based on content relevance
- Each agent reviews in character, producing findings grouped by concern type with agent attribution
- Findings are tagged with severity: critical, warning, or suggestion
- Review file saved to `docs/reviews/{nn}-review-{slug}.md` with auto-incrementing number
- State management via `.cpm-progress.md` follows established CPM patterns
- Graceful degradation: roster/library/format issues degrade without blocking

### Write input resolution and roster loading
**Task**: 1.1
**Description**: Handle `$ARGUMENTS` file path or auto-discover most recent epic doc; load agent roster with project override → plugin default fallback
**Status**: Complete

### Write library check and agent selection logic
**Task**: 1.2
**Description**: Library doc filtering by `review`/`all` scope; dynamic agent selection (2-3 for stories, 3-4 for epics) based on content relevance
**Status**: Complete

### Write the adversarial review instructions
**Task**: 1.3
**Description**: Core review loop — each selected agent reviews in character, findings grouped by concern type with severity tags and agent attribution
**Status**: Complete

### Write review output file generation and state management
**Task**: 1.4
**Description**: Review file format, `docs/reviews/` directory convention, auto-incrementing numbering, `.cpm-progress.md` pattern, graceful degradation
**Status**: Complete

---

## Add autofix task generation
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- After review, user is offered autofix option via AskUserQuestion
- If epic has pending work: appends a remediation story with tasks to the epic doc
- If epic is complete or missing: creates standalone Claude Code tasks via TaskCreate
- Autofix is additive only — never removes or edits existing stories/tasks
- User can decline autofix and proceed to handoff
- Only critical and warning findings generate fix tasks (suggestions are informational)

### Write autofix decision logic and user gate
**Task**: 2.1
**Description**: Offer autofix via AskUserQuestion after review; determine epic status to choose adaptive path; filter to critical/warning findings
**Status**: Complete

### Write epic amendment path
**Task**: 2.2
**Description**: For active epics — append remediation story with tasks to the epic doc using Edit tool
**Status**: Complete

### Write standalone task creation path
**Task**: 2.3
**Description**: For complete/missing epics — create Claude Code tasks via TaskCreate from actionable findings
**Status**: Complete

---

## Add adaptive pipeline handoff
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Pre-execution epics (pending/in-progress) offer: pivot, do, or exit
- Post-execution epics (complete) offer: retro, pivot, discover, spec, or exit
- Handoff passes the review file path and reviewed artifact path as context for the downstream skill
- Review output format is structured so pivot can use findings as "what needs changing" context

### Write adaptive handoff with status detection
**Task**: 3.1
**Description**: Read epic `**Status**:` field; present pre-execution options (pivot/do/exit) or post-execution options (retro/pivot/discover/spec/exit) via AskUserQuestion
**Status**: Complete

---

## Register plugin and update documentation
**Story**: 4
**Status**: Complete
**Blocked by**: Story 2, Story 3

**Acceptance Criteria**:
- `cpm/skills/review/SKILL.md` exists and follows plugin skill conventions (YAML front-matter with name and description)
- `plugin.json` version is bumped
- `plugin.json` keywords include `review` and `adversarial`
- README pipeline diagram includes `/cpm:review`
- README has a `/cpm:review` section matching the style of other skill descriptions
- README "What's Included" tree includes the review skill directory

### Create skill directory and update plugin metadata
**Task**: 4.1
**Description**: Create `cpm/skills/review/` directory; update `plugin.json` version and keywords
**Status**: Complete

### Update README with review skill documentation
**Task**: 4.2
**Description**: Add `/cpm:review` to pipeline diagram, add skill section, update "What's Included" tree
**Status**: Complete

---
