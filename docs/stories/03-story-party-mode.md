# Stories: CPM Party Mode

**Date**: 2026-02-10
**Source**: docs/specifications/cpm-party-mode.md

## Epic: Agent Roster

### Create default agent roster YAML
**Status**: Complete
**Task ID**: 1

**Acceptance Criteria**:
- `agents/roster.yaml` exists in the CPM plugin directory
- Contains 6-8 named personas with all required fields (name, displayName, icon, role, personality, communicationStyle)
- Each persona has a unique name, icon, and distinct personality
- File includes comment documentation explaining the schema
- Personalities reflect professional roles naturally

---

### Add project-level roster override support
**Status**: Complete
**Task ID**: 2
**Blocked by**: 1

**Acceptance Criteria**:
- Party skill SKILL.md includes instructions to check project `docs/agents/roster.yaml` first
- Falls back to plugin `agents/roster.yaml` if no project override exists
- Override is full replacement, not merged
- Behaviour is documented in the skill

---

## Epic: Party Mode Skill

### Create party mode SKILL.md with orchestration loop
**Status**: Complete
**Task ID**: 3
**Blocked by**: 1

**Acceptance Criteria**:
- `skills/party/SKILL.md` exists with complete orchestration instructions
- Skill loads roster YAML at session start
- Accepts topic from arguments (description, file, URL)
- Each response includes 2-3 agents with visual formatting (icon + bold name)
- Agents interact naturally (reference, build, disagree)
- Exit mechanism works
- Follows CPM SKILL.md conventions (frontmatter, guidelines)

---

### Add discussion summary on exit
**Status**: Complete
**Task ID**: 4
**Blocked by**: 3

**Acceptance Criteria**:
- Exiting party mode triggers a structured summary
- Summary covers key points, agreements, open questions, recommendations
- Summary is formatted clearly in markdown
- Summary content is reusable for pipeline handoff

---

### Add compaction resilience to party mode
**Status**: Complete
**Task ID**: 5
**Blocked by**: 3

**Acceptance Criteria**:
- Party mode creates `.cpm-progress.md` at session start
- State is updated periodically during discussion
- State captures topic, agent participation, discussion highlights
- Existing pre-compact and session-start hooks work without modification
- State file is deleted on clean exit

---

## Epic: Pipeline Integration

### Add party-to-pipeline handoff
**Status**: Complete
**Task ID**: 6
**Blocked by**: 4

**Acceptance Criteria**:
- Exit flow offers pipeline handoff options via AskUserQuestion
- User can choose discover, spec, stories, or plain exit
- Discussion summary is passed as input context to the chosen skill
- Handoff feels seamless — the next skill picks up naturally from the discussion

---

### Add multi-perspective mode to discover
**Status**: Complete
**Task ID**: 7
**Blocked by**: 1

**Acceptance Criteria**:
- discover SKILL.md includes Perspectives instruction block
- Perspectives activate at Why and Constraints phases
- 2-3 agents provide brief viewpoints before user responds
- Agents are selected by relevance to the current topic
- Perspectives are concise (few sentences each)
- Existing discover flow is not disrupted

---

### Add multi-perspective mode to spec
**Status**: Complete
**Task ID**: 8
**Blocked by**: 1

**Acceptance Criteria**:
- spec SKILL.md includes Perspectives instruction block
- Perspectives activate at Architecture Decisions and Scope Boundary sections
- 2-3 agents present competing trade-offs before user decides
- Agents are selected by relevance to the architectural choice
- Perspectives are concise and constructive
- Existing spec flow is not disrupted

---

## Epic: Plugin Release

### Register party skill and bump CPM version
**Status**: Complete
**Task ID**: 9
**Blocked by**: 3

**Acceptance Criteria**:
- `cpm/.claude-plugin/plugin.json` includes party skill
- Version is 1.3.0
- Description mentions multi-perspective / party mode
- Keywords include relevant terms

---

### Update CPM README
**Status**: Complete
**Task ID**: 10
**Blocked by**: 3, 6, 7, 8

**Acceptance Criteria**:
- README documents /cpm:party usage
- README explains roster customisation
- README describes perspectives in discover/spec
- README mentions handoff capability
- Documentation is concise and consistent with existing style

---

### Update marketplace.json for CPM v1.3.0
**Status**: Complete
**Task ID**: 11
**Blocked by**: 9

**Acceptance Criteria**:
- marketplace.json CPM entry shows version 1.3.0
- CPM description mentions party mode capability
- Marketplace version is bumped
- No other plugin entries are affected
