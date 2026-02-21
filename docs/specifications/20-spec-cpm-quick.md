# Spec: CPM Quick Wins

**Date**: 2026-02-21
**Discussion**: docs/discussions/05-discussion-cpm-quick-skill.md

## Problem Summary

The CPM pipeline (discover → brief → spec → epics → do) is designed for structured, multi-phase work and creates disproportionate overhead for small, well-defined changes. Users either skip CPM entirely (losing traceability) or pay ceremony costs that don't add value. `/cpm:quick` is a standalone skill that provides a lightweight execution path: accept a change description, assess scope, confirm with the user, execute the work using Claude Code tasks, and produce a single completion record for traceability.

## Functional Requirements

### Must Have
1. **Accept change description** — via `$ARGUMENTS` or interactive prompt
2. **Scope assessment** — qualitative evaluation after codebase exploration; suggests escalation to full pipeline if change appears too large; offers once, then honours user's decision
3. **Propose scope and acceptance criteria** — single concise block showing what will change, which files are affected, and done-criteria; user confirms or adjusts before work begins
4. **Execute the work** — creates and manages Claude Code tasks (as many as needed); implements the change directly
5. **Write completion record** — single artifact to `docs/quick/{nn}-quick-{slug}.md` with title, date, context, acceptance criteria, changes made, and verification outcome
6. **State management** — session-scoped progress file following the same structural pattern as other CPM skills

7. **Update HTML documentation** — update `cpm-onboarding-presentation.html`, `cpm-presentation.html`, and `cpm-training-guide.html` to include `/cpm:quick` in the skill descriptions, workflows, and any relevant examples

### Should Have
8. **Verify acceptance criteria** — self-assess proposed criteria against codebase state after execution; record outcome in completion record
9. **Library awareness** — check `docs/library/*.md` for documents scoped to `quick` or `all`; use as context during execution
10. **Reverse gate from heavier skills** — if a user starts `/cpm:spec` or `/cpm:epics` and scope is trivially small, offer once to switch to `/cpm:quick`; honour their choice
11. **Task system integration** — Claude Code tasks always used (implicit, not optional); as many tasks as the work needs

### Could Have
12. **Pipeline escalation handoff** — when scope gate fires and user agrees, hand off directly to `/cpm:discover`, `/cpm:spec`, or `/cpm:epics`
13. **Test runner integration** — discover and run tests after execution as part of verification

### Won't Have (this iteration)
14. **Retro observations** — quick wins don't generate retro fields or feed into `/cpm:retro`

## Non-Functional Requirements

### Consistency
Follow the same structural patterns as existing CPM skills: State Management section with session-scoped progress files, resume adoption, library check, template hint. Copy the State Management template verbatim from an existing skill (per retro recommendation).

### Usability
Single confirmation step before work begins. The skill should feel noticeably faster than the full pipeline path.

### Discoverability
Completion records in `docs/quick/` must be discoverable by other skills (especially `/cpm:archive`). Artifact format uses standard CPM bold-field convention.

### Reliability
Compaction resilience via the standard progress file mechanism. If compaction fires mid-execution, the skill can resume without re-asking the user.

## Architecture Decisions

### Execution Model
**Choice**: Inline execution with Claude Code tasks (always used, as many as needed)
**Rationale**: Tasks provide visibility in `TaskList` and tracking during execution. Inline execution keeps the skill self-contained — no dependency on `/cpm:do`'s story/task hydration machinery. Multiple tasks allowed because a quick win may still involve several discrete steps.
**Alternatives considered**: Pure inline (no tasks) — rejected because task visibility was valued; full `/cpm:do` delegation — rejected because it couples to epic doc format and adds ceremony.

### Completion Record Format
**Choice**: Markdown file at `docs/quick/{nn}-quick-{slug}.md` using standard CPM bold-field convention
**Rationale**: Consistency with other CPM artifacts (specs, epics, discussions all use the same bold-field + section pattern). Self-describing — readable without needing other context. Auto-incrementing number for ordering.
**Alternatives considered**: YAML front-matter — rejected because no other CPM output artifact uses it; inline in progress file — rejected because it's not discoverable after the session ends.

### Scope Gate Mechanism
**Choice**: Qualitative assessment after codebase exploration, no hard thresholds, user can override
**Rationale**: Hard thresholds (e.g. file count) are brittle and don't capture what makes a change "big" (architectural decisions, cross-cutting concerns, data model changes). Qualitative assessment with transparent reasoning lets the skill explain *why* it thinks something is too big, and the user — who has the most context — makes the final call.
**Alternatives considered**: Hard thresholds (e.g. >5 files = not quick) — rejected as too rigid; no gate at all — rejected because it defeats the purpose of having a separate lightweight path.

## Scope

### In Scope
- Core skill: `cpm/skills/quick/SKILL.md` with full flow (describe → assess → confirm → execute → record)
- Claude Code task creation and management (implicit, always used)
- Scope gate with qualitative assessment and upward escalation offer
- Completion record artifact at `docs/quick/{nn}-quick-{slug}.md`
- State management with session-scoped progress file
- Acceptance criteria verification post-execution
- Library awareness (structural consistency with other skills)
- Update HTML documentation: `cpm-onboarding-presentation.html`, `cpm-presentation.html`, and `cpm-training-guide.html` to incorporate the new `/cpm:quick` skill

### Out of Scope
- Reverse gate in heavier skills (requires modifying `/cpm:spec`, `/cpm:epics` — separate effort)
- Retro observations for quick wins

### Deferred
- Pipeline escalation handoff (direct handoff to discover/spec/epics when scope gate fires)
- Test runner integration (automated test execution as part of verification)
- Reverse gate from heavier skills (as a future enhancement to existing skills)

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[manual]` — Manual inspection, observation, or user confirmation

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. Accept change description | Skill accepts description via `$ARGUMENTS` | `[manual]` |
| 1. Accept change description | If no arguments, skill prompts user | `[manual]` |
| 2. Scope assessment | Skill provides qualitative assessment after reading codebase | `[manual]` |
| 2. Scope assessment | If too large, offers escalation once then honours decision | `[manual]` |
| 3. Propose scope & criteria | Presents single concise block with changes, files, and done-criteria | `[manual]` |
| 3. Propose scope & criteria | User can confirm or adjust before work begins | `[manual]` |
| 4. Execute the work | Skill creates Claude Code tasks and implements the change | `[manual]` |
| 4. Execute the work | Multiple tasks created if work warrants it | `[manual]` |
| 5. Write completion record | Record written to `docs/quick/{nn}-quick-{slug}.md` with correct numbering | `[manual]` |
| 5. Write completion record | Record contains Context, Acceptance Criteria, Changes Made, Verification | `[manual]` |
| 6. State management | Progress file created before work, updated during, deleted after record saved | `[manual]` |
| 6. State management | Resume adoption works if session is resumed | `[manual]` |
| 7. Update HTML documentation | `cpm-onboarding-presentation.html` includes `/cpm:quick` in skill overview | `[manual]` |
| 7. Update HTML documentation | `cpm-presentation.html` includes `/cpm:quick` in skill overview | `[manual]` |
| 7. Update HTML documentation | `cpm-training-guide.html` includes `/cpm:quick` in skill overview and usage examples | `[manual]` |
| 8. Verify acceptance criteria | Skill self-assesses criteria against codebase after execution | `[manual]` |
| 8. Verify acceptance criteria | Verification outcome recorded in completion record | `[manual]` |
| 9. Library awareness | Skill checks `docs/library/*.md` for `quick` or `all` scope | `[manual]` |
| 9. Library awareness | Relevant library documents used as context during execution | `[manual]` |

### Integration Boundaries
- Skill ↔ Claude Code task system (TaskCreate/TaskUpdate/TaskList)
- Skill ↔ artifact directory (`docs/quick/`)
- Skill ↔ progress file (`docs/plans/.cpm-progress-{session_id}.md`)
- Skill ↔ library system (`docs/library/*.md`)

### Test Infrastructure
None required. The deliverable is a SKILL.md prompt document — verification is by running the skill and observing behaviour.

### Unit Testing
Not applicable — no compiled code components.
