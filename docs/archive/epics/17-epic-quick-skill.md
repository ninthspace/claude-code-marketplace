# Quick Skill

**Source spec**: docs/specifications/20-spec-cpm-quick.md
**Date**: 2026-02-21
**Status**: Complete
**Blocked by**: —

## Create the `/cpm:quick` skill
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Accept change description (Req 1), Scope assessment (Req 2), Propose scope & criteria (Req 3), Execute the work (Req 4), Write completion record (Req 5), State management (Req 6), Verify acceptance criteria (Req 8), Library awareness (Req 9), Task system integration (Req 11)

**Acceptance Criteria**:
- Skill accepts description via `$ARGUMENTS` or prompts interactively [manual]
- Scope assessment provides qualitative evaluation after codebase exploration [manual]
- If change appears too large, offers escalation once then honours user's decision [manual]
- Presents single concise block with proposed changes, affected files, and done-criteria for user confirmation [manual]
- Creates and manages Claude Code tasks to implement the change [manual]
- Writes completion record to `docs/quick/{nn}-quick-{slug}.md` with correct auto-incrementing number [manual]
- Completion record contains title, date, context, acceptance criteria, changes made, and verification outcome [manual]
- Progress file created before work, updated during, deleted after record saved [manual]
- Resume adoption works if session is resumed [manual]
- Checks `docs/library/*.md` for `quick` or `all` scope and uses as context [manual]
- Self-assesses acceptance criteria against codebase after execution and records outcome [manual]

### Create the skill directory and SKILL.md skeleton
**Task**: 1.1
**Description**: Covers the YAML front-matter, input handling section (`$ARGUMENTS` or interactive prompt), and overall document structure. Produces the file that subsequent tasks fill in.
**Status**: Complete

### Write the scope assessment and escalation gate
**Task**: 1.2
**Description**: Covers the qualitative scope evaluation after codebase exploration, escalation offer to full pipeline, and honouring the user's override decision.
**Status**: Complete

### Write the propose, confirm, and execute sections
**Task**: 1.3
**Description**: Covers the single concise confirmation block (changes, files, done-criteria), Claude Code task creation/management, and the execution flow.
**Status**: Complete

### Write the completion record and verification sections
**Task**: 1.4
**Description**: Covers the completion record format at `docs/quick/{nn}-quick-{slug}.md` (title, date, context, criteria, changes, verification), auto-incrementing numbering, and post-execution acceptance criteria self-assessment.
**Status**: Complete

### Write the state management and library awareness sections
**Task**: 1.5
**Description**: Covers the session-scoped progress file (create, update, delete lifecycle), resume adoption for `--resume` sessions, and library check for `docs/library/*.md` with `quick` or `all` scope.
**Status**: Complete
**Retro**: [Smooth delivery] SKILL.md assembled cleanly in 5 tasks — splitting by document section worked well for a prompt-only deliverable with no code dependencies between tasks.

---

## Update documentation for `/cpm:quick`
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Update HTML documentation (Req 7)

**Acceptance Criteria**:
- `cpm-onboarding-presentation.html` includes `/cpm:quick` in skill overview [manual]
- `cpm-presentation.html` includes `/cpm:quick` in skill overview [manual]
- `cpm-training-guide.html` includes `/cpm:quick` in skill overview and usage examples [manual]
- `cpm/README.md` includes `/cpm:quick` in the workflow diagram and skill list [manual]
- Repo `README.md` includes `/cpm:quick` in the skill table and usage examples [manual]

### Update `cpm-onboarding-presentation.html`
**Task**: 2.1
**Description**: Add `/cpm:quick` to the skill overview section of the onboarding presentation.
**Status**: Complete

### Update `cpm-presentation.html`
**Task**: 2.2
**Description**: Add `/cpm:quick` to the skill overview section of the main presentation.
**Status**: Complete

### Update `cpm-training-guide.html`
**Task**: 2.3
**Description**: Add `/cpm:quick` to the skill overview and usage examples in the training guide.
**Status**: Complete

### Update `cpm/README.md`
**Task**: 2.4
**Description**: Add `/cpm:quick` to the workflow diagram and the skill list with description and usage examples.
**Status**: Complete

### Update repo `README.md`
**Task**: 2.5
**Description**: Add `/cpm:quick` to the marketplace skill table and usage examples in the repository root README.
**Status**: Complete
**Retro**: [Smooth delivery] Five documentation files updated in parallel with consistent patterns — each file had a clear integration point for the new skill, making updates mechanical.

---

## Lessons

### Smooth Deliveries
- Story 1: SKILL.md assembled cleanly in 5 tasks — splitting by document section worked well for a prompt-only deliverable with no code dependencies between tasks.
- Story 2: Five documentation files updated with consistent patterns — each file had a clear integration point for the new skill, making updates mechanical.
