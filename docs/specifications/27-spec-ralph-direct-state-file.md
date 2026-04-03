# Spec: cpm:ralph Direct State File Write

**Date**: 2026-04-03
**Brief**: docs/discussions/12-discussion-ralph-direct-state-file.md
**Amends**: docs/specifications/26-spec-cpm-ralph-integration.md

## Problem Summary

`cpm:ralph` currently depends on the ralph-wiggum plugin's `setup-ralph-loop.sh` bash script to initialise a ralph loop. The script fails when invoked through Claude Code's Bash tool because execute permissions (`+x`) aren't preserved during marketplace plugin installation. The user must manually copy-paste and run the underlying bash command to start the loop. Since the setup script's only job is writing `.claude/ralph-loop.local.md` with YAML frontmatter — and the stop hook (which drives the actual loop) reads that file regardless of how it was created — `cpm:ralph` can write the state file directly via the Write tool, eliminating the bash script dependency entirely.

## Functional Requirements

### Must Have

1. **Direct state file write** — `cpm:ralph` writes `.claude/ralph-loop.local.md` directly via the Write tool instead of invoking `setup-ralph-loop.sh`. The file uses the exact frontmatter schema the stop hook expects: `active`, `iteration`, `max_iterations`, `completion_promise`, `started_at`, followed by the prompt text after the closing `---`.
2. **Existing state file guard** — Before writing, check if `.claude/ralph-loop.local.md` already exists. If it does, read it and warn the user (show current iteration and prompt snippet). Confirm overwrite or abort via AskUserQuestion.
3. **Updated plugin detection (Step 1b)** — Change pre-flight check from "is the `/ralph-wiggum:ralph-loop` skill available" to "is the ralph-wiggum stop hook registered". The stop hook is the only remaining dependency on the ralph-wiggum plugin.
4. **Remove setup script permission check (Step 1c)** — Drop the check for `Bash("...setup-ralph-loop.sh":*)` from the permissions validation. No longer relevant since the setup script is no longer invoked.
5. **State file schema coupling notice** — Add a maintenance coupling entry documenting the `.claude/ralph-loop.local.md` frontmatter contract, pinned to the current ralph-wiggum plugin schema.

### Should Have

6. **Updated dry-run output (Step 3a)** — Dry-run shows the state file content that would be written (not a `/ralph-wiggum:ralph-loop` command). Still provides a clear preview of what will happen.
7. **Activation message** — After writing the state file, output an activation message: iteration count, max iterations, completion promise status, and the prompt text — matching the information `setup-ralph-loop.sh` would have printed.

### Won't Have (this iteration)

- Changes to the ralph-wiggum plugin itself (not controlled by this project)
- Concurrent loop support / session-isolated state files (ralph-wiggum design limitation)
- Changes to `cpm:do`

## Non-Functional Requirements

### Data Integrity
- The state file write is atomic from the stop hook's perspective — the Write tool creates the file in a single operation, and the stop hook only reads it after Claude exits (not during execution). No race condition.
- The existing state file guard (requirement 2) prevents accidental clobbering of an active loop.

All other NFRs from spec 26 (reliability, usability, error handling) continue to apply unchanged.

## Architecture Decisions

### Direct Write over Shell Execution
**Choice**: `cpm:ralph` writes `.claude/ralph-loop.local.md` directly via the Write tool, bypassing the setup script entirely.
**Rationale**: The setup script is a thin wrapper that parses arguments and writes a file — functionality `cpm:ralph` already has. The plugin is a third-party dependency with no control over its packaging or permissions. Writing the file directly eliminates the permission issue with zero behavioural change — the stop hook reads the state file regardless of how it was created.
**Alternatives considered**: (1) Fix plugin permissions via upstream PR — rejected because Chris doesn't control the ralph-wiggum plugin. (2) Use v2.1.91 `bin/` feature — only applies to Bash tool invocations, not hook commands, and still requires upstream plugin changes.
**Coupling risk**: Introduces implicit dependency on the stop hook's expected file format. Mitigated by documenting the schema contract in the maintenance coupling section. Risk is low — the format is a simple 5-field YAML frontmatter that hasn't changed since the plugin's creation.

## Scope

### In Scope
- Modify `cpm:ralph` SKILL.md Steps 1b, 1c, 3, 3a, 3b to implement direct state file write
- Add `.claude/ralph-loop.local.md` schema to maintenance coupling section
- Add existing state file guard logic before state file creation

### Out of Scope
- Any changes to the ralph-wiggum plugin
- Any changes to `cpm:do`
- Changes to the prompt template content (Step 2) — the assembled prompt text is unchanged
- Concurrent loop / session isolation
- Help page updates (already done in spec 26)

### Deferred
- Revisit if ralph-wiggum plugin adds `bin/` support — could switch back to plugin invocation if permissions are fixed upstream

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[manual]` — Manual inspection, observation, or user confirmation
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. Direct state file write | SKILL.md Step 3 instructs writing `.claude/ralph-loop.local.md` via Write tool | `[manual]` |
| 1. Direct state file write | Written state file contains correct frontmatter: `active`, `iteration`, `max_iterations`, `completion_promise`, `started_at` | `[manual]` |
| 1. Direct state file write | Prompt text appears after the frontmatter closing `---` | `[manual]` |
| 1. Direct state file write | A ralph loop starts and completes successfully using the direct-write mechanism | `[feature]` |
| 2. Existing state file guard | SKILL.md checks for existing `.claude/ralph-loop.local.md` before writing | `[manual]` |
| 2. Existing state file guard | User is warned and asked to confirm overwrite when file exists | `[manual]` |
| 2. Existing state file guard | Abort path leaves existing state file untouched | `[feature]` |
| 3. Updated plugin detection | Step 1b checks for ralph-wiggum stop hook registration instead of setup script skill | `[manual]` |
| 3. Updated plugin detection | Pre-flight warns if stop hook is not detected | `[feature]` |
| 4. Remove permission check | Step 1c no longer checks for `Bash("...setup-ralph-loop.sh":*)` permission | `[manual]` |
| 5. Schema coupling notice | Maintenance coupling section documents the `.claude/ralph-loop.local.md` schema contract | `[manual]` |
| 5. Schema coupling notice | Schema lists all five frontmatter fields with types | `[manual]` |
| 6. Updated dry-run | Dry-run shows the state file content that would be written | `[manual]` |
| 7. Activation message | After writing state file, skill outputs iteration count, max iterations, and completion promise status | `[manual]` |

### Integration Boundaries
1. **`cpm:ralph` → ralph-wiggum stop hook** — mediated by `.claude/ralph-loop.local.md` file format. This replaces the previous integration boundary of `cpm:ralph` → ralph-wiggum setup script CLI.

### Test Infrastructure
None required. The deliverable is a SKILL.md edit. Testing is manual inspection of the SKILL.md instructions plus an end-to-end ralph loop run against real epics.

### Unit Testing
Not applicable — the deliverable is a skill instruction file, not executable code.
