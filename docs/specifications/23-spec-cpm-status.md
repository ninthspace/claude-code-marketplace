# Spec: CPM Status Skill

**Date**: 2026-03-01
**Brief**: docs/discussions/10-discussion-cpm-status-skill.md

## Problem Summary

Returning to a project after a break requires manual archaeology — poking around epic docs, reading git logs, piecing together what happened and what's next. `/cpm:status` automates this reconnaissance by scanning CPM artifacts and recent git activity, then printing a structured status report with concrete next-step recommendations. It is read-only, ephemeral (stdout only), and handles any project state naturally — from empty to fully complete.

## Functional Requirements

### Must Have
- **Artifact inventory scan**: Glob and read CPM artifacts across `docs/specifications/`, `docs/epics/`, `docs/discussions/`, `docs/retros/`, `docs/briefs/`, `docs/plans/`. Report what exists with counts and completion status (e.g., "Epic 02: 4/6 stories complete").
- **Git recent activity summary**: Show recent commits with adaptive time window. Group by category (code changes, doc changes, config changes). Highlight commits that touched CPM artifacts.
- **Current state assessment**: Report branch status, uncommitted changes, and in-progress work visible from epic task statuses (stories marked "In Progress").
- **Recommended next steps**: Based on project state, suggest concrete CPM actions with copy-pasteable commands (e.g., "Run `/cpm:do docs/epics/02-epic-auth.md` to continue Epic 02").
- **Ephemeral output**: Print structured markdown report to stdout. No file saved, no progress file.

### Should Have
- **Adaptive git time window**: If last commit was recent, show a short window; if there's been a gap, widen to capture the last burst of activity before the gap.
- **In-progress work detection**: Detect active progress files in `docs/plans/.cpm-progress-*` and report which skills have sessions in flight.

### Could Have
- **Branch-aware diff summary**: If on a feature branch, show `git diff --stat` against main to summarise in-flight code changes.

### Won't Have (this iteration)
- Claude session log analysis
- Saved report artifact
- Modifying any files or git state
- Historical trend tracking

## Non-Functional Requirements

### Safety
Must never modify files, create artifacts, or change git state. All git commands must be read-only (`git log`, `git status`, `git diff` — never `git commit`, `git checkout`, etc.).

### Usability
Report must be scannable — clear section headers, concise summaries, actionable next-step recommendations with copy-pasteable commands.

## Architecture Decisions

### Skill Structure
**Choice**: Standard `cpm/skills/status/SKILL.md` with YAML front-matter. Explicit "no state management" declaration.
**Rationale**: Follows existing skill conventions while clearly opting out of state management (per retro recommendation that stateless skills should declare themselves as such). No progress file, no saved output artifact.
**Alternatives considered**: Could have added a `--save` flag to optionally persist the report, but this adds complexity counter to the ephemeral design decision.

### Data Gathering Sequence
**Choice**: Three-phase gather-then-synthesise — (1) artifact scan via Glob + Read, (2) git activity via Bash, (3) synthesise report with recommendations.
**Rationale**: Artifact scan provides the structural picture, git fills in the activity timeline, and recommendations emerge from combining both. Each phase gracefully degrades if no data is found.
**Alternatives considered**: Interleaving artifact and git data collection, but sequential phases are simpler to reason about and easier to extend.

## Scope

### In Scope
- `cpm/skills/status/SKILL.md` — complete skill definition
- YAML front-matter with name, description, and trigger
- Four-section report logic (inventory, recent activity, current state, next steps)
- Graceful handling of empty/partial/complete project states
- Skill registration in plugin config

### Out of Scope
- Claude session log analysis
- Saved report artifact or progress file
- Modifying any project files or git state
- Hook scripts or test suites for this skill
- Historical trend tracking

### Deferred
- Cross-project status (scanning multiple repos)
- Custom report sections or filtering
- Integration with external project management tools

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[manual]` — Manual inspection, observation, or user confirmation

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| Artifact inventory scan | Scans all CPM doc directories and lists found artifacts with counts | `[manual]` |
| Artifact inventory scan | Reports epic completion status (e.g., "4/6 stories complete") | `[manual]` |
| Artifact inventory scan | Handles missing directories silently | `[manual]` |
| Git recent activity summary | Shows recent commits grouped by category (code/docs/config) | `[manual]` |
| Git recent activity summary | Highlights commits that touched CPM artifacts | `[manual]` |
| Current state assessment | Reports current branch and uncommitted changes | `[manual]` |
| Current state assessment | Shows in-progress stories from epic docs | `[manual]` |
| Recommended next steps | Suggests concrete CPM commands based on project state | `[manual]` |
| Recommended next steps | On empty project, recommends starting skills | `[manual]` |
| Recommended next steps | On completed project, recommends closing skills | `[manual]` |
| Ephemeral output | Prints to stdout only, no files created or modified | `[manual]` |

### Integration Boundaries
No traditional integration boundaries — this is a prompt-only skill. The only integration point is adherence to CPM artifact conventions (file paths, document structure, story status markers) shared with other skills.

### Test Infrastructure
None required. Verification is manual — run `/cpm:status` against projects in various states (empty, mid-flight, complete) and inspect output.

### Unit Testing
Not applicable — this skill has no executable code. The SKILL.md is the complete deliverable.
