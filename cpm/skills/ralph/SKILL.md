---
name: cpm:ralph
description: Autonomous multi-epic execution via the Ralph Wiggum plugin. Discovers epics, generates a Ralph-compatible prompt that wraps /cpm:do with autonomous behaviour overrides, validates prerequisites, and launches the loop. Triggers on "/cpm:ralph".
---

# Autonomous Multi-Epic Execution

Generate and launch a Ralph Wiggum loop that wraps `/cpm:do` for autonomous, unsupervised multi-epic execution. The skill discovers epics, validates prerequisites, assembles a self-contained prompt with autonomous behaviour overrides, and presents it for review before launching.

## Input

Parse `$ARGUMENTS` for:

1. **Epic paths** — one or more explicit paths (e.g. `docs/epics/23-epic-*.md docs/epics/24-epic-*.md`) or a range (e.g. `23 through 26`).
2. **`--max-iterations N`** — maximum Ralph loop iterations (default: 50).
3. **`--story-filter`** — include/exclude specific stories (e.g. `--story-filter "1-3"` or `--story-filter "!4"`).
4. **`--dry-run`** — generate and display the prompt without launching.

If no epic paths are provided, auto-discover all incomplete epics (see Process Step 1).

## Process

### Step 1: Pre-flight Validation

Before generating the prompt, validate all prerequisites.

#### 1a. Epic Discovery

If explicit epic paths were provided in arguments, resolve them (expand globs). Otherwise, auto-discover:

1. **Glob** `docs/epics/*-epic-*.md` to find all epic files.
2. Use Grep to search for `**Status**:` across the matched files, then filter to epics that are not `Complete`. Do not use Bash loops with shell variables for this — use Grep and Read tools.
3. If no incomplete epics found, report to the user and stop: "No incomplete epics found. Nothing to run."
4. Present the discovered epics and confirm with AskUserQuestion.

For range-style references (e.g. `23 through 26`), expand to matching files: `docs/epics/23-epic-*.md`, `docs/epics/24-epic-*.md`, etc.

#### 1a-ii. Strip `[plan]` Tags

Formal plan mode (`EnterPlanMode`) creates an interactive approval gate that stalls autonomous execution. Strip `[plan]` tags from epic docs before launching the loop so `/cpm:do` uses inline planning for all stories.

1. After resolving epic paths, use Grep to search for `\[plan\]` across the resolved epic docs.
2. For each match, use the Edit tool to remove the `[plan]` tag from the story heading (e.g. `## Set up OAuth integration [plan]` → `## Set up OAuth integration`). Trim any trailing whitespace left by the removal.
3. Track which stories were modified. Log a line per stripped tag for inclusion in the execution log: "Stripped `[plan]` from Story {N}: {heading text}".
4. If no `[plan]` tags are found, skip silently.

#### 1b. Ralph Wiggum Stop Hook Detection

The ralph-wiggum plugin's stop hook is the only external dependency — it intercepts session exit and feeds the prompt back to continue the loop. `cpm:ralph` writes the state file directly (no dependency on the setup script).

1. Check if the ralph-wiggum stop hook is registered by scanning the session's available hooks for a "Stop" hook referencing `ralph-wiggum` or `stop-hook.sh`.
2. If not detected, warn the user: "Ralph Wiggum stop hook not detected. The loop mechanism requires the ralph-wiggum plugin to be installed — without the stop hook, writing the state file will have no effect. Install the plugin from the Claude Code marketplace." Use AskUserQuestion with options: "Continue anyway" or "Stop".

#### 1c. Permissions Check

Autonomous execution will stall if Claude Code prompts for tool approval mid-run. Check that common bash commands are pre-approved:

1. Read `~/.claude/settings.json` and look for a `permissions.allow` array.
2. Check for the presence of these baseline patterns: `Bash(find:*)`, `Bash(grep:*)`, `Bash(git:*)`, `Bash(bash:*)`, `Bash(php:*)`, `Bash(npm:*)`, `Bash(sed:*)`.
3. **If missing patterns are found**, warn the user:

   "**Permissions warning**: Your user settings (`~/.claude/settings.json`) are missing some bash permissions that autonomous execution needs. Without these, the Ralph loop will stall on tool approval prompts."

   List the missing patterns and use AskUserQuestion with options:
   - "Add them for me" — use the Edit tool to add the missing patterns to `~/.claude/settings.json` `permissions.allow` array
   - "I'll handle it" — continue without changes
   - "Stop" — abort

4. **If no permissions block exists at all**, offer to create one with the full set of recommended patterns.

#### 1d. Test Runner Discovery

Discover the project's test runner for inclusion in the generated prompt:

1. Check project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) for test commands.
2. If found, report: "Discovered test runner: {command}. This will be referenced in the generated prompt."
3. If not found, note: "No test runner discovered. The generated prompt will instruct `/cpm:do` to discover one at runtime."

#### 1e. Resume Detection

Check for evidence of a previous Ralph run:

1. **Glob** `docs/plans/ralph-log-*.md` for existing execution logs.
2. If an execution log exists, read it and summarise the state: which epics completed, which are in progress, any skipped tasks.
3. Use Grep to check the target epic docs' `**Status**:` fields to confirm the current state. Do not use Bash loops for this.
4. If a previous run is detected, present the state to the user with AskUserQuestion: "Found a previous Ralph run. {N} epics completed, {M} remaining. Resume from where it left off?" Options: "Resume" or "Start fresh (ignore previous state)".

### Step 2: Prompt Assembly

Assemble the ralph-loop command as a single, short, plain-text string. The prompt **must not** contain markdown formatting, code fences, backticks, XML tags, or any shell-special characters beyond basic punctuation. Keep it concise — the detailed behaviour comes from `/cpm:do` itself; the prompt only needs to steer autonomous decisions.

Build the prompt by interpolating into the template below:

- `{epic_count}` — number of epics
- `{epic_range}` — human-readable range (e.g. "5-7")
- `{epic_glob}` — glob pattern or explicit paths (e.g. `docs/epics/05-epic-*.md through 07-epic-*.md`)
- `{max_iterations}` — from arguments or default (50)
- `{story_filter_clause}` — if `--story-filter` was provided, append a clause like "Only work on stories 1-3." or "Skip story 4." If no filter, omit entirely.
- `{test_runner_clause}` — if a test runner was discovered, append "Use {command} to run tests." If not found, omit entirely.
- `{resume_clause}` — if resuming, append "This is a resumed run — skip completed work and pick up where the previous run left off." If fresh, omit entirely.

### Prompt Template

```
Run /cpm:do. Work through epics {epic_range} sequentially ({epic_glob}). When an epic completes and offers the next epic choice, always continue to the next epic. Only work on the specified epics -- do not scan for or continue to other epics beyond this list. Do NOT use AskUserQuestion -- make autonomous decisions: fix test failures yourself, use inline planning instead of formal plan mode, keep working until acceptance criteria pass, skip a task after 3 consecutive failures. Commit after each completed story.{story_filter_clause}{test_runner_clause}{resume_clause} When the last specified epic completes, output ALL_EPICS_COMPLETE.
```

**CRITICAL — prompt hygiene rules:**
- The prompt is written into the body of `.claude/ralph-loop.local.md` (after the YAML frontmatter). It is fed back verbatim by the stop hook on each iteration.
- No backticks, no markdown headers, no code fences, no XML/HTML tags.
- Use `ALL_EPICS_COMPLETE` as the plain text marker in the prompt — must match the `completion_promise` frontmatter value exactly.
- Use `--` instead of `—` for dashes in the prompt text.
- Keep the total prompt under 500 characters where possible.

### Step 3: State File Write and Launch

#### 3a. Existing State File Guard

Before writing, check if `.claude/ralph-loop.local.md` already exists using the Read tool:

1. If the file exists, read it and present a warning: "An active ralph loop state file already exists. Iteration: {iteration}, prompt: {first 80 chars of prompt text}..." Use AskUserQuestion with options:
   - "Overwrite" — proceed with writing the new state file
   - "Abort" — stop without writing (leave existing file untouched)
2. If the file does not exist, proceed directly to Step 3b.

#### 3b. Present (Dry-Run)

Display the state file content that would be written:

```
Here's the ralph loop state file that will be written to .claude/ralph-loop.local.md:

---
active: true
iteration: 1
max_iterations: {max_iterations}
completion_promise: "{completion_promise}" (or null)
started_at: "{ISO 8601 UTC timestamp}"
---

{assembled_prompt}
```

If `--dry-run` was specified, stop here.

#### 3c. Confirm and Execute

Use AskUserQuestion: "Ready to launch the Ralph loop?" Options:
- "Launch it" — write the state file and start
- "Edit first" — let the user modify the prompt before launching
- "Save and exit" — save the state file content to `docs/plans/ralph-command-{timestamp}.md` for later use

If "Launch it":
1. Write `.claude/ralph-loop.local.md` using the Write tool with the exact content shown in the dry-run. The file must use the frontmatter schema the stop hook expects:
   - `active: true`
   - `iteration: 1`
   - `max_iterations: {value from arguments or default}`
   - `completion_promise: "{text}"` (quoted) or `null` (unquoted)
   - `started_at: "{current UTC time in ISO 8601 format}"`
   - Followed by `---` and then the assembled prompt text
2. Output an activation message:

```
Ralph loop activated!

Iteration: 1
Max iterations: {N or "unlimited"}
Completion promise: {text or "none"}

The stop hook is now active. When you try to exit, the same prompt will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.
```

3. Then output the assembled prompt text so Claude begins working on it immediately.

If "Edit first": present the prompt for the user to modify, then re-present from 3b.
If "Save and exit": write the state file content to `docs/plans/ralph-command-{timestamp}.md`.

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` during the pre-flight phase for compaction resilience.

**Path resolution**: All paths are relative to the current Claude Code session's working directory.

**Session ID**: Use `CPM_SESSION_ID` from context. Fall back to `.cpm-progress.md` if not present.

**Resume adoption**: Follow the standard CPM resume adoption procedure — if an old progress file matches this skill's `**Skill**:` field but has a different session ID, adopt it.

**Create** before Step 1. **Delete** after the Ralph loop is launched (or after dry-run output is presented).

Use the Write tool to write the full file each time. Format:

```markdown
# CPM Session State

**Skill**: cpm:ralph
**Step**: {N} — {Step Name}
**Epic list**: {resolved epic paths}
**Max iterations**: {value}

## Pre-flight Results
- Epics found: {count} ({list})
- Ralph plugin: {detected/not detected}
- Test runner: {command or "none"}
- Resume: {yes — resuming from log {path} / no — fresh run}

## Next Action
{What to do next}
```

**Delete** the progress file after the Ralph loop is launched or after dry-run output. Also delete `docs/plans/.cpm-compact-summary-{session_id}.md` if it exists.

## Maintenance Coupling

> **This section documents dependencies between `cpm:ralph` and external components.** Changes to `cpm:do`'s interaction gates or the ralph-wiggum plugin's state file format may require updates to this skill.

### Ralph Wiggum State File Schema

`cpm:ralph` writes `.claude/ralph-loop.local.md` directly instead of invoking the ralph-wiggum plugin's `setup-ralph-loop.sh` script. The stop hook (`stop-hook.sh`) parses this file to drive the loop. The file format is the implicit contract between `cpm:ralph` and the stop hook.

**State file path**: `.claude/ralph-loop.local.md`

**Expected format** (YAML frontmatter + markdown body):

```markdown
---
active: true
iteration: 1
max_iterations: {integer, 0 = unlimited}
completion_promise: "{text}" or null
started_at: "{ISO 8601 UTC, e.g. 2026-04-03T12:00:00Z}"
---

{prompt text}
```

| Field | Type | Stop Hook Usage |
|---|---|---|
| `active` | boolean | Not currently checked by stop hook (presence of file implies active) |
| `iteration` | integer | Compared against `max_iterations`; incremented each loop |
| `max_iterations` | integer | Loop stops when `iteration >= max_iterations` (0 = unlimited) |
| `completion_promise` | string or null | Matched against `<promise>` tags in assistant output |
| `started_at` | ISO 8601 string | Informational; not parsed by stop hook |

**When to update**: If the ralph-wiggum plugin changes the state file path, frontmatter field names, or parsing logic in `stop-hook.sh`, this skill's Step 3c must be updated to match. The stop hook uses `sed`, `grep`, and `awk` to parse the frontmatter — any format change that breaks these parsers will break the loop.

### cpm:do Interaction Gates

The prompt template's "Autonomous Behaviour" section overrides the following `AskUserQuestion` locations in `cpm:do`:

| `cpm:do` Location | Gate Purpose | Prompt Override |
|---|---|---|
| Input — Epic Doc (multiple epics) | Ask user which epic to work on | Auto-select from the epic list in order |
| Test Runner Discovery | Ask user for test command | Proceed with self-assessment |
| Step 4 — Verification gate test failure | Ask user: fix, continue, or stop | Fix automatically; skip after stuck threshold |
| Step 4 — TDD Red phase unexpected pass | Ask user: investigate, skip TDD, or stop | Investigate and fix the test |
| Step 4 — TDD Green phase still failing | Ask user: continue, skip TDD, or stop | Continue working on implementation |
| Step 5 — Unmet acceptance criteria | Ask user: continue working or mark complete | Continue working; skip after stuck threshold |
| Step 5 — Coverage matrix edit failure | Ask user: continue or stop | Continue without recording proof |
| Step 8 — Next epic check | Ask user: continue to next epic or stop | Handled natively: `cpm:do` skips the scan when an explicit epic path is provided |
| Graceful Degradation — Test command fails | Ask user: new command, continue, or stop | Continue without tests |
| Graceful Degradation — No test + TDD | Ask user: provide runner or acknowledge | Fall back to standard workflow |

**When to update**: If `cpm:do` adds, removes, or changes an `AskUserQuestion` gate, review the prompt template's Autonomous Behaviour section and this table. A new gate that isn't overridden will cause the Ralph loop to pause and wait for user input — defeating the purpose of autonomous execution.

## Guidelines

- **Facilitate the setup, automate the execution.** The skill's interactive phase is pre-flight and launch confirmation. Once Ralph starts, everything is autonomous.
- **Deterministic prompts.** Same epics + same config = same prompt. No randomness.
- **Fail fast on pre-flight.** If prerequisites aren't met, tell the user immediately — don't generate a prompt that will fail.
- **Dry-run is the default first step.** Always show the user what will run before running it.
- **The execution log is the audit trail.** It survives across Ralph iterations and is the primary post-run artifact for the user to review.
