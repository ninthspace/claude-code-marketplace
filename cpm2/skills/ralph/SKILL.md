---
name: cpm2:ralph
description: Autonomous multi-epic execution via the Ralph Wiggum plugin. Discovers epics, generates a Ralph-compatible prompt that wraps /cpm2:do with autonomous behaviour overrides, validates prerequisites, and launches the loop. Triggers on "/cpm2:ralph".
---

# Autonomous Multi-Epic Execution

Generate and launch a Ralph Wiggum loop that wraps `/cpm2:do` for autonomous, unsupervised multi-epic execution. The skill discovers epics, validates prerequisites, assembles a self-contained prompt with autonomous behaviour overrides, and presents it for review before launching.

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
2. Use Grep to search for `**Status**:` across the matched files, then filter to epics that are not `Complete`. Use Grep and Read tools directly (Bash loops with shell variables lose context).
3. If no incomplete epics found, report to the user and stop: "No incomplete epics found. Nothing to run."
4. Present the discovered epics and confirm with AskUserQuestion.

For range-style references (e.g. `23 through 26`), expand to matching files: `docs/epics/23-epic-*.md`, `docs/epics/24-epic-*.md`, etc.

#### 1b. Strip `[plan]` Tags

Formal plan mode (`EnterPlanMode`) creates an interactive approval gate that stalls autonomous execution. Strip `[plan]` tags from epic docs before launching the loop so `/cpm2:do` uses inline planning for all stories.

**Ordering**: this step runs after epic discovery and before any other pre-flight checks — autonomous execution depends on it.

1. For each resolved epic path, use the Read tool to read the file. Scan the content for any heading line (lines starting with `##` or `###`) that contains the literal text `[plan]`. Use Read for this — reading each file directly avoids regex escaping issues with square brackets in Grep.
2. For each heading that contains `[plan]`, use the Edit tool to remove the `[plan]` tag and any trailing whitespace it leaves behind (e.g. `## Set up OAuth integration [plan]` → `## Set up OAuth integration`).
3. Track which stories were modified. Log a line per stripped tag for inclusion in the execution log: "Stripped `[plan]` from Story {N}: {heading text}".
4. If no `[plan]` tags are found, skip silently.

#### 1c. Ralph Wiggum Stop Hook Detection

The ralph-wiggum plugin's stop hook is the only external dependency — it intercepts session exit and feeds the prompt back to continue the loop. `cpm2:ralph` writes the state file directly (no dependency on the setup script).

1. Check if the ralph-wiggum stop hook is registered by scanning the session's available hooks for a "Stop" hook referencing `ralph-wiggum` or `stop-hook.sh`.
2. If not detected, warn the user: "Ralph Wiggum stop hook not detected. The loop mechanism requires the ralph-wiggum plugin to be installed — without the stop hook, writing the state file will have no effect. Install the plugin from the Claude Code marketplace." Use AskUserQuestion with options: "Continue anyway" or "Stop".

**Permissions note**: The loop will pause on permission denials at runtime; the stop hook re-invokes after the user grants them. To avoid mid-loop stalls, users can pre-add common Bash permissions (`Bash(git:*)`, `Bash(bash:*)`, `Bash(find:*)`, `Bash(grep:*)`) to `~/.claude/settings.json` before launching.

#### 1d. Test Runner Discovery

Discover the project's test runner for inclusion in the generated prompt:

1. Check project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) for test commands.
2. If found, report: "Discovered test runner: {command}. This will be referenced in the generated prompt."
3. If not found, note: "No test runner discovered. The generated prompt will instruct `/cpm2:do` to discover one at runtime."

#### 1e. Resume Detection

Check for evidence of a previous Ralph run:

1. **Glob** `docs/plans/ralph-log-*.md` for existing execution logs.
2. If an execution log exists, read it and summarise the state: which epics completed, which are in progress, any skipped tasks.
3. Use Grep to check the target epic docs' `**Status**:` fields to confirm the current state. Use Grep and Read tools directly.
4. If a previous run is detected, present the state to the user with AskUserQuestion: "Found a previous Ralph run. {N} epics completed, {M} remaining. Resume from where it left off?" Options: "Resume" or "Start fresh (ignore previous state)".

### Step 2: Prompt Assembly

Assemble the ralph-loop prompt as plain text — no markdown, code fences, backticks, or XML tags (the stop hook feeds the prompt back verbatim on each iteration). Interpolate these variables into the template:

- `{epic_count}`, `{epic_range}`, `{epic_glob}` — from Step 1 pre-flight
- `{max_iterations}` — from arguments or default (50)
- `{story_filter_clause}`, `{test_runner_clause}`, `{resume_clause}` — include when applicable, omit otherwise
- `{task_budget_clause}` — "Task budget: {N} tasks, estimate ~2000 tokens per task." Count `###` task headings in target epic docs.

**Template** (written into `.claude/ralph-loop.local.md` body; use `--` for dashes; `ALL_EPICS_COMPLETE` must match `completion_promise` frontmatter; keep under 800 chars):

```
Run /cpm2:do on epics {epic_range} sequentially ({epic_glob}). Continue to each next epic automatically. Make all decisions autonomously -- choose the most reasonable option for every AskUserQuestion. Use inline planning for all stories. Task complete means: all tagged criteria ([unit]/[integration]/[feature]) have passing test results, and all [manual] criteria have self-assessment lines in the progress file. A failure (for the 3-strike skip rule) is a test command exit code != 0 after a code change attempt -- tool errors and permission denials are retries, not failures. If acceptance criteria are ambiguous and completion cannot be determined, mark the story Blocked -- criteria ambiguous and continue to the next story. Commit after each completed story. Keep all commits local.{story_filter_clause}{test_runner_clause}{task_budget_clause}{resume_clause} When the last specified epic completes, output ALL_EPICS_COMPLETE.
```

### Step 3: State File Write and Launch

#### 3a. Existing State File Guard

Before writing, check if `.claude/ralph-loop.local.md` already exists using the Read tool:

1. If the file exists, read it and present a warning: "An active ralph loop state file already exists. Iteration: {iteration}, prompt: {first 80 chars of prompt text}..." Use AskUserQuestion with options:
   - "Overwrite" — proceed with writing the new state file
   - "Abort" — stop without writing (leave existing file untouched)
2. If the file does not exist, proceed directly to Step 3b.

#### 3b. Present (Dry-Run)

**Capture the current UTC time** before displaying or writing the state file. Run `date -u +"%Y-%m-%dT%H:%M:%SZ"` via the Bash tool and store the output as `{utc_timestamp}`. Always use the Bash tool for timestamps — LLM-generated times are unreliable.

Display the state file content that would be written:

```
Here's the ralph loop state file that will be written to .claude/ralph-loop.local.md:

---
active: true
iteration: 1
max_iterations: {max_iterations}
completion_promise: "{completion_promise}" (or null)
started_at: "{utc_timestamp}"
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
   - `started_at: "{utc_timestamp}"` (the value captured via Bash in Step 3b)
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

**Skill**: cpm2:ralph
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

> **This section documents dependencies between `cpm2:ralph` and external components.** Changes to `cpm2:do`'s interaction gates or the ralph-wiggum plugin's state file format may require updates to this skill.

### Ralph Wiggum State File Schema

`cpm2:ralph` writes `.claude/ralph-loop.local.md` directly instead of invoking the ralph-wiggum plugin's `setup-ralph-loop.sh` script. The stop hook (`stop-hook.sh`) parses this file to drive the loop. The file format is the implicit contract between `cpm2:ralph` and the stop hook.

**State file path**: `.claude/ralph-loop.local.md`

**Expected format** (YAML frontmatter + markdown body):

```markdown
---
active: true
iteration: 1
max_iterations: {integer, 0 = unlimited}
completion_promise: "{text}" or null
started_at: "{utc_timestamp from Bash: date -u +\"%Y-%m-%dT%H:%M:%SZ\"}"
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

### cpm2:do Interaction Gates

The prompt's autonomous instruction ("choose the most reasonable option for every AskUserQuestion") overrides the following `cpm2:do` gates:

| `cpm2:do` Location | Gate Purpose | Prompt Override |
|---|---|---|
| Input — Epic Doc (multiple epics) | Ask user which epic to work on | Auto-select from the epic list in order |
| Test Runner Discovery | Ask user for test command | Proceed with self-assessment |
| Termination — Blocker | Confirm external blocker with user | Skip the task and continue to next |
| Termination — Ambiguity | Ask user to clarify unclear criteria | Mark story "Blocked -- criteria ambiguous" and continue |
| Step 4 — Verification gate test failure | Ask user: fix, continue, or stop | Fix automatically; skip after stuck threshold |
| Step 4 — Verification round limit | 2 fix attempts exhausted; ask user | Mark unmet criteria as known issues and proceed |
| Step 4 — TDD Red phase unexpected pass | Ask user: investigate, skip TDD, or stop | Investigate and fix the test |
| Step 4 — TDD Green phase still failing | Ask user: continue, skip TDD, or stop | Continue working on implementation |
| Step 5 — Unmet acceptance criteria | Ask user: continue working or mark complete | Continue working; skip after stuck threshold |
| Step 5 — Coverage matrix edit failure | Ask user: continue or stop | Continue without recording proof |
| Step 8 — Next epic check | Ask user: continue to next epic or stop | Continue to next epic automatically |
| Graceful Degradation — Test command fails | Ask user: new command, continue, or stop | Continue without tests |
| Graceful Degradation — No test + TDD | Ask user: provide runner or acknowledge | Fall back to standard workflow |

**When to update**: If `cpm2:do` adds, removes, or changes an `AskUserQuestion` gate, review the prompt template's Autonomous Behaviour section and this table. A new gate that isn't overridden will cause the Ralph loop to pause and wait for user input — defeating the purpose of autonomous execution.

## Guidelines

- **Facilitate the setup, automate the execution.** The skill's interactive phase is pre-flight and launch confirmation. Once Ralph starts, everything is autonomous.
- **Deterministic prompts.** Same epics + same config = same prompt. No randomness.
- **Fail fast on pre-flight.** If prerequisites are missing, tell the user immediately — only generate a prompt that can succeed.
- **Dry-run is the default first step.** Always show the user what will run before running it.
- **The execution log is the audit trail.** It survives across Ralph iterations and is the primary post-run artifact for the user to review.
