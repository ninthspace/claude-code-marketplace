# Discussion: cpm:ralph — Bypass Setup Script via Direct State File Write

**Date**: 2026-04-03
**Agents**: Jordan, Margot, Bella, Tomas, Sable, Ren

## Problem

The `/cpm:ralph` skill depends on the ralph-wiggum plugin's `setup-ralph-loop.sh` bash script to initialise a ralph loop. When invoked through Claude Code's Bash tool, the script fails because the execute bit (`+x`) isn't preserved during plugin marketplace installation. Chris has to manually copy-paste the bash command and run it outside Claude Code to get the loop started.

## Key Findings

1. **The setup script is a thin wrapper.** `setup-ralph-loop.sh` does three things: parse arguments, write `.claude/ralph-loop.local.md` with YAML frontmatter, and print a status message. `cpm:ralph` already assembles all the required parameters by Step 2.

2. **The stop hook works fine.** The ralph-wiggum stop hook (`stop-hook.sh`) executes correctly — it's only the setup script invocation that fails. The hook system apparently handles execution differently from the Bash tool.

3. **v2.1.91 `bin/` feature doesn't fully help.** The new `bin/` directory feature solves executable permissions for Bash tool invocations, but doesn't apply to hook commands. Since Chris doesn't control the ralph-wiggum plugin, upstreaming changes isn't an option.

4. **The state file is the only contract.** The stop hook reads `.claude/ralph-loop.local.md` — it doesn't care how the file was created. Writing it directly from `cpm:ralph` is functionally identical to running the setup script.

5. **Concurrent loop risk.** The ralph-wiggum plugin uses a single hardcoded state file path — no session isolation. This is a plugin limitation, not ours to fix, but `cpm:ralph` should check for an existing state file before overwriting.

## Recommendation

### Changes to `cpm:ralph` SKILL.md

1. **Step 1b (Plugin Detection)** — Change from checking if the setup script can execute to verifying the stop hook registration exists. The stop hook is the only ralph-wiggum dependency remaining.

2. **Step 1c (Permissions Check)** — Remove the check for `Bash("...setup-ralph-loop.sh":*)` permission pattern. No longer relevant.

3. **Step 3 (Launch)** — Instead of presenting a `/ralph-wiggum:ralph-loop` command, have the skill Write `.claude/ralph-loop.local.md` directly. Before writing, check if the file already exists and warn if so (another loop may be active).

4. **Step 3a/3b (Dry-run and Confirm)** — Update to reflect the new mechanism. Dry-run shows the state file content that would be written. Confirm writes the file and outputs the prompt.

5. **Maintenance Coupling** — Add a section documenting the `.claude/ralph-loop.local.md` state file schema contract:

```yaml
---
active: true
iteration: 1
max_iterations: {N}
completion_promise: "{text}" | null
started_at: "{ISO 8601 UTC}"
---

{prompt text}
```
