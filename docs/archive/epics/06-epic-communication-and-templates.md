# Communication & Templates

**Source spec**: docs/specifications/14-spec-cpm-lifecycle-expansion.md
**Date**: 2026-02-12
**Status**: Complete
**Blocked by**: —

## Build the cpm:present skill
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Content is derived from source artifacts, not generated from scratch
- All audience types from the spec are supported (executive, client, technical stakeholder, team onboarding, custom)
- All format types from the spec are supported (summary memo, status update, presentation outline, changelog, onboarding guide)
- Output is regenerable (re-running with same inputs produces updated output)
- Standard CPM structural patterns followed (state management, library checks, AskUserQuestion gating)

### Create skill directory and SKILL.md with front-matter and input discovery
**Task**: 1.1
**Description**: Set up `cpm/skills/present/SKILL.md` with YAML front-matter, artifact input discovery (reads from docs/plans/, docs/briefs/, docs/specifications/, docs/architecture/, docs/epics/), and startup checks.
**Status**: Complete

### Design audience and format selection flow
**Task**: 1.2
**Description**: Implement the two-step selection — audience (executive, client, technical stakeholder, team onboarding, custom) then format (summary memo, status update, presentation outline, changelog, onboarding guide) — using AskUserQuestion.
**Status**: Complete

### Implement derived content generation and output
**Task**: 1.3
**Description**: Build the transformation logic that produces content derived from source artifacts (not from scratch), saves to `docs/communications/{nn}-{format}-{slug}.md`, and supports regeneration when source artifacts change.
**Status**: Complete

### Add state management and template hint
**Task**: 1.4
**Description**: Add `.cpm-progress.md` state tracking, compaction resilience, and presentational template hint at startup.
**Status**: Complete

---

## Build the cpm:templates skill
**Story**: 2
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Lists all artifact-producing skills with template metadata (skill name, output format, structural/presentational, override path)
- Can preview any template skeleton via `preview {skill}` subcommand
- Scaffolds override files at `docs/templates/` only for presentational templates via `scaffold {skill}` subcommand
- Correctly distinguishes structural from presentational templates

### Create skill directory and SKILL.md with list command
**Task**: 2.1
**Description**: Set up `cpm/skills/templates/SKILL.md` with the `list` subcommand that shows all CPM artifact templates with skill name, output format, structural/presentational classification, and override path.
**Status**: Complete

### Add preview and scaffold subcommands
**Task**: 2.2
**Description**: Add `preview {skill}` to show any template skeleton, and `scaffold {skill}` to create override files at `docs/templates/` for presentational templates only.
**Status**: Complete

---

## Add template hints to all artifact-producing skills
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2

**Acceptance Criteria**:
- Every artifact-producing skill shows the appropriate hint at startup
- Presentational skills reference the correct override path ("Using default template. To customise, place your template at `docs/templates/{path}`.")
- Structural skills reference `cpm:templates preview` ("Output format is fixed (used by downstream skills). Run `/cpm:templates preview {skill}` to see the format.")

### Add template hints to existing structural skills
**Task**: 3.1
**Description**: Add structural template hints to cpm:discover, cpm:spec, cpm:epics, cpm:do, cpm:review, cpm:retro ("Output format is fixed...").
**Status**: Complete

### Add template hints to new presentational skills
**Task**: 3.2
**Description**: Add presentational template hints to cpm:brief, cpm:architect, cpm:present ("Using default template..."). These are added as part of their initial SKILL.md creation in Epics 04-05, verified here.
**Status**: Complete

---
