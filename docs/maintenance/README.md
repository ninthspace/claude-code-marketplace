# Plugin Maintenance Reference

Development-facing records for the plugins in this repository: dependencies on external components,
formats one component writes that another parses, and coupling between parts that a change to one of
them can break.

**Nothing here is loaded at runtime, and nothing here is referenced from a skill.** That is
the point of the file. A `SKILL.md` is read in full on every invocation of that skill, in
every project the plugin is installed in, so a record aimed at a maintainer is paid for by
every run that will never consult it. This file is the single home for that material, and
`CLAUDE.md` is the only thing that points here — see *A SKILL.md is not a change log* there
for the rule.

**Each record below is a record, not an instruction.** Where a behaviour is recorded here,
its operative counterpart lives in the plugin's source.

The records for CPM and DPM went with their source on 2026-10-08; both are in git history.

---

## `cpm-next-progress` ↔ the harness — tool output it parses, and older engines

**The record.** The mod never writes an artifact; it reads them and parses what the harness prints.
Three formats are load-bearing, all in `cpm-next-progress/hooks/progress.ts`:

- **`ArtifactData` list output.** `parseDocs` takes each line that starts with `{"id"` between the
  `BEGIN`/`END` database markers as one document, `{id, version, data}`. A change to that line shape
  reads as an empty collection: every row is then offered again as new, without `if_version`, and the
  writes are refused as unpinned.
- **A deleted artifact.** `isMissingArtifact` matches `no such artifact` or `HTTP 404` in the error a
  read raises. Missed, a deleted tracker or overview page fails its check on every write instead of
  being settled once.
- **The publish result.** `artifactUrlIn` takes the first `https://claude.ai/[code/]artifact/<id>` in the
  `Artifact` tool's result. Missed, a published tracker's link is never saved to its build-order file,
  nor the overview's to the store.

**Older engines.** `claude plugin validate` and `claude plugin test` run on the newest Claude Code
installed, but open sessions keep the version they started on (`~/.local/share/claude/versions/`), and
`/reload-plugins` loads the mod into that one. On 2026-10-15 Claude Code 2.1.296 refused 0.4.0 for
passing `$` into a function imported from `overview.tsx` ("$ is followed only into a function declared
in this same file, never across an import"), which 2.1.300 accepts, and `/progress-tracker` vanished
from every open session. Load the mod headless under each installed version before releasing:

```sh
~/.local/share/claude/versions/<v> -p "reply ok" --debug-file /tmp/d.txt --plugin-dir cpm-next-progress
grep -i 'hooks module cpm-next-progress@inline' /tmp/d.txt   # "loaded", or "failed to load: <reason>"
```

**What asserts it.** `cpm-next-progress/hooks/progress.test.ts` covers `parseDocs`, `isMissingArtifact` and
`artifactUrlIn` against the formats above; nothing asserts the harness still prints them. Nothing
automated covers older engines.

---

## `cpm-next` ↔ claude-in-chrome, project files and the mods — what `do` reads and what reads it

**The record.** None of this is asserted anywhere; each item is a dependency `do` or a mod has on something outside the plugin.

- **claude-in-chrome tool names.** `do` (step 3, `[browser]` criteria) loads the claude-in-chrome tools with `ToolSearch` and lists the connected browsers, then drives the browser with whichever of them the session exposes (`mcp__claude-in-chrome__list_connected_browsers`, `navigate`, `get_page_text`, `read_page`, `tabs_context_mcp`, `tabs_create_mcp`). The skill names no tool beyond "claude-in-chrome", so a rename or a change in how the tools are loaded breaks the fallback without an error. An unattended check can stall on a site-permission prompt, which the once-per-run connection check does not detect.
- **`APP_URL` and the host rule.** `do` reads `APP_URL` from the project's `.env` and accepts only a `localhost`, `127.0.0.1` or `.test` host, because a "development" URL can be deployed and hold real data.
- **Browser test tool package names.** `do` detects `laravel/dusk`, `pestphp/pest-plugin-browser` and `@playwright/test` in a project's manifest. A new tool is not detected until the list in `cpm-next/skills/do/SKILL.md` step 3 is extended.
- **Scratch location.** A red pass's copies, `manifest` and `tree` file are in `{git common dir}/cpm-next/scratch/{epic file stem}-{story}/` (`quick-{nn}/`), found with `git rev-parse --path-format=absolute --git-common-dir`; the directory exists only while a pass runs. The `cpm-next/hooks` module reads that folder, and its `tree` files, to refuse a `git commit` in a checkout with a pass open; a change to the path or to what `tree` holds breaks it. Auditor directories stay in the run directory under the session scratchpad, with `mktemp -d` as the fallback.
- **Waiting stories in the mods.** `whats-next` (`whats-next/hooks/plan.ts`, `register.tsx`) and `cpm-next-progress` (`hooks/progress.ts`) each read a story's criteria as the contract states (a `- ` line under `**Acceptance Criteria**:`, its last backticked word the tag, its indented `Evidence`, `Evidence (user,`, `Not met:` and `Waiting on user:` lines, a legacy story-level `**Evidence**:` field) and decide whether a story waits on the user by the same rule as `status`. The two keep identical copies of `hooks/fixtures/waiting.ts`; compare them with `cmp` when either changes. A change to the criterion grammar or the `- Waiting on user:` line changes the contract, `status`, `do` step 3 and both mods.
- **The blocked note.** `do` marks a blocked story by keeping its status and adding ` — blocked: {reason}`. Both mods' `normaliseStatus` (`whats-next/hooks/plan.ts`, `cpm-next-progress/hooks/progress.ts`) match the status by prefix, so `In Progress — blocked: …` reads as In Progress and puts the story first in `whats-next`'s order; a bare `Blocked` would read as Pending.
- **The sweep's repository list.** `library sweep` keeps `~/.claude/cpm-next/repos.txt`, one symlink-resolved absolute path per line, outside every repository; reading other repositories raises permission prompts, and a listed path that moves is reported, not repaired.
- **The fixed list and the issue draft.** A release that fixes a `process` failure adds a row to `cpm-next/shared/fixed.md`, the file and step as the skill names them, or the sweep cannot leave the failure out. The draft `library sweep` makes outside the plugin's repository files to the `repository` field of cpm-next's `.claude-plugin/plugin.json`; a fork changes the field.
- **Unknown fields in the mods.** `whats-next/hooks/plan.ts` reads `**Story**`, `**Task**`, `**Status**`, `**Blocked by**` and `**Source spec**` (and `**Withdrawn**` and `**Superseded by**` in specs); `cpm-next-progress/hooks/progress.ts` reads `**Story**`, `**Task**`, `**Status**`, `**Blocked by**` and `**Effort**`, and `register.ts` reads `**Source spec**`. Both drop every other `**Field**:` line and read neither `docs/library/` nor `docs/quick/`, so `**Signal**` and `**Class**` are safe to add; a change to the format of any field listed here breaks a mod.
- **Contract strings a mod may later parse.** `red:` in `Evidence` lines, `red: n/a — existing (reaches …)`, the indented `- Waiting on user:` line under a criterion, `Evidence (user,`, `**Lessons**`, `**Scratch**` and `**Signal**` (with ` — cpm-next {version}` on a `process` signal, ` — recurs:`, ` — raised`, ` — promoted`, ` — declined`) in epics, stories and quick records, and `**Class**` in library lessons and amendments.
- **cpm-next ships a hooks module.** `cpm-next/hooks` (`hooks.json`, `register.ts`, `guard.ts`, `guard.test.ts`) and `cpm-next/tsconfig.json` make cpm-next a mod as well as a skill plugin, so the load failures recorded above can now reach the required plugin; load it headless under every installed engine before a release. Its laid types are ignored (`cpm-next/.claude-plugin/types/`).

**What asserts it.** Nothing automated asserts these dependencies, apart from the commit guard's tests (`cpm-next/hooks/guard.test.ts`), which read the scratch path and `tree` file as the contract describes. `claude plugin validate cpm-next` checks the plugin's own files, and the mods' suites (`claude plugin test cpm-next-models`, `cpm-next-progress`, `whats-next`) cover their own parsers, not these dependencies.
