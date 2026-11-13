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

**What else the mod reads, and the copies it keeps** (from 0.9.0):

- **`turn.step`.** The input's `agentId` (absent on the main loop) and `model` (what the step asked for),
  and the result's `usage.model` (what answered), kept in memory per loop and dropped at that loop's
  `turn.complete`. A change to either field, or to `usage` arriving as null, leaves a loop with no model
  or the asked-for one, and a started story is then recorded with no model or the wrong one.
- **`tool.call` writers.** `agentId` on each `tool.call`, and which epic doc a call writes: the basename at
  the end of an `Edit`, `Write` or `MultiEdit` `file_path`, or any `…-epic-….md` name in a `Bash` command
  (`writtenEpics` in `hooks/timing.ts`). A script that writes an epic doc without naming it is credited
  to no one.
- **`do`'s planned model.** `~/.claude/plugins/installed_plugins.json`, the `cpm-next@` entry, the install
  for this project before the user's, and the `model:` line of that install's `skills/do/SKILL.md`
  frontmatter. A rename of the plugin key, the skill folder or the frontmatter key leaves Pending rows
  with no planned model.
- **Copies from cpm-next-models.** `familyOf` (`cpm-next-models/hooks/pin.ts`) is copied into
  `cpm-next-progress/hooks/progress.ts`, and `pickInstall` and the `model:` reading of `parseFrontmatter`
  (`frontmatterOf` in `cpm-next-models/hooks/register.ts`) as `pickInstall` and `frontmatterModel`; the
  mods import nothing from each other. Change both copies together.
- **The decision prefix.** `[{epic} {S|T}{id}, {kind}]` at the start of a build-order decision attaches it
  to that row (`DECISION_PREFIX` in `hooks/progress.ts`). The form is not part of the cpm-next contract;
  decisions are written in it by the user's own instructions to `do`. A change to the form leaves every
  decision in the page's "Not matched to a row" strip.
- **The row-schema version.** `ROW_SCHEMA` in `hooks/progress.ts` is part of the `checked:` signature and
  the `settled:` mark. Raise it whenever a release adds, removes or changes a field of a row or of
  `meta/tracker`, so the first check after the upgrade reads every tracker, settled ones included, and
  rewrites the rows; and update `hooks/fixtures/tracker-data.ts` (checked by `progress.test.ts` against
  `fixtures/tracker-epics.ts`), which the page harness `hooks/fixtures/tracker-harness.html` renders.
- **The turn-end prompt's context.** `nudge` sets `nudgeContext` and the mod's own `prompt.submit` hook
  attaches it to the prompt `nudge` submits; `PromptSubmitArgs` has no `context`. Under
  `claude plugin test` that hook does not run for the mod's own prompt, so no test sees the context;
  the engine's types say a plugin's other hooks do see its submission. Unverified in a live session. From
  0.9.1 the prompt's text names each pending file and how to apply it (`applyFromFile` in
  `hooks/progress.ts`), so a missing context no longer leaves Claude without the writes.

---

## `cpm-next` ↔ claude-in-chrome, project files and the mods — what `do` reads and what reads it

**The record.** None of this is asserted anywhere; each item is a dependency `do` or a mod has on something outside the plugin.

- **claude-in-chrome tool names.** `do` (`cpm-next/skills/do/browser.md`: the probe before the first story and **Step 3**, the `[browser]` check) loads the claude-in-chrome tools with `ToolSearch` and lists the connected browsers, then drives the browser with whichever of them the session exposes (`mcp__claude-in-chrome__list_connected_browsers`, `navigate`, `get_page_text`, `read_page`, `tabs_context_mcp`, `tabs_create_mcp`). The skill names no tool beyond "claude-in-chrome", so a rename or a change in how the tools are loaded breaks the fallback without an error. An unattended check can stall on a site-permission prompt, which the once-per-run connection check does not detect.
- **`APP_URL` and the host rule.** `do` (`cpm-next/skills/do/browser.md`) reads `APP_URL` from the project's `.env` and accepts only a `localhost`, `127.0.0.1` or `.test` host, because a "development" URL can be deployed and hold real data.
- **Browser test tool package names.** `do` detects `laravel/dusk`, `pestphp/pest-plugin-browser` and `@playwright/test` in a project's manifest. A new tool is not detected until the list in `cpm-next/skills/do/browser.md` (**Step 3**) is extended.
- **Scratch location.** A red pass's copies, `manifest` and `tree` file are in `{git common dir}/cpm-next/scratch/{epic file stem}-{story}/` (`quick-{nn}/`), found with `git rev-parse --path-format=absolute --git-common-dir`; the directory exists only while a pass runs. The `cpm-next/hooks` module reads that folder, and its `tree` files, to refuse a `git commit` in a checkout with a pass open; a change to the path or to what `tree` holds breaks it. Auditor directories stay in the run directory under the session scratchpad, with `mktemp -d` as the fallback. A story's audit round records are in `{git common dir}/cpm-next/rounds/{epic file stem}-{story}/` with their own `tree` file; the commit guard and the restore step read only `scratch/`, so the records must not move under it, where any story holding records would make the guard refuse every commit.
- **Waiting stories in the mods.** `whats-next` (`whats-next/hooks/plan.ts`, `register.tsx`) and `cpm-next-progress` (`hooks/progress.ts`) each read a story's criteria as the contract states (a `- ` line under `**Acceptance Criteria**:`, its last backticked word the tag, its indented `Evidence`, `Evidence (user,`, `Not met:` and `Waiting on user:` lines, a legacy story-level `**Evidence**:` field) and decide whether a story waits on the user by the same rule as `status`. The two keep identical copies of `hooks/fixtures/waiting.ts`; compare them with `cmp` when either changes. A change to the criterion grammar or the `- Waiting on user:` line changes the contract, `status`, `do` step 3 and both mods.
- **The blocked note.** `do` marks a blocked story by keeping its status and adding ` — blocked: {reason}`. Both mods' `normaliseStatus` (`whats-next/hooks/plan.ts`, `cpm-next-progress/hooks/progress.ts`) match the status by prefix, so `In Progress — blocked: …` reads as In Progress and puts the story first in `whats-next`'s order; a bare `Blocked` would read as Pending.
- **The sweep's repository list.** `library sweep` keeps `~/.claude/cpm-next/repos.txt`, one symlink-resolved absolute path per line, outside every repository; reading other repositories raises permission prompts, and a listed path that moves is reported, not repaired.
- **The fixed list and the issue draft.** A release that fixes a `process` failure adds a row to `cpm-next/shared/fixed.md`, the file and step as the skill names them, or the sweep cannot leave the failure out. A section that moves to another file keeps its signals' place through the moved-places table in `cpm-next/skills/library/sweep.md` (**Moved places**), which a `fixed.md` row naming the new file covers; a move adds a row to that table. The draft `library sweep` makes outside the plugin's repository files to the `repository` field of cpm-next's `.claude-plugin/plugin.json`; a fork changes the field.
- **On-demand files.** Rarely needed sections live in their own files, each read only when a pointer says, which also says to read it again if it is not in context: `cpm-next/skills/do/independent-tests.md` (`do`, when a story in scope has an `**Independent tests**` line other than `skipped`: steps 1, 3, 4 and 5, the parallel rules and **Audit**), `cpm-next/skills/do/browser.md` (`do`, when the scope holds a `[browser]` criterion, an `**Amended**` line's included: the probe before the first story, step 3, **Finishing**), `cpm-next/shared/auditor-independent-tests.md` (the auditor, for a story with an `**Independent tests**` line other than `skipped`: check 5), `cpm-next/skills/library/sweep.md` (`library`, for `sweep` and `sweep add`, `remove`, `list`) and `cpm-next/skills/library/consolidate.md` (`library`, for `consolidate` alone or with a path). A pointer that changes its trigger without its file, or a section that moves without its pointer, leaves the rule unread.
- **The test-run rules.** `cpm-next/shared/test-runs.md` holds the targeted set, the wide-reach list, the exempt kinds and the snapshot; only `do` and the auditor read it, so the contract (read by every skill) holds only the `**Test run**` field. The wide-reach list names Laravel's convention-wired code; a project on another stack relies on the "anything the framework wires by convention or by a string" entry, so extend the list there when a framework hides coupling the list does not name.
- **The review record's Source and date.** `review` writes a record's **Source** (every epic path in the scope, in full and comma-separated), its title (`— Story N` for one story) and its **Date**, in the form `cpm-next/shared/artifacts.md` gives; `cpm-next/skills/status` reads them to decide whether an epic has been reviewed (its **Next** suggestion). `status` also compares the date with the epic's latest-dated `**Amended**` line, in the header form or a story's (the contract's **Amending an existing artefact** names both and where each date sits), so a change to the field form, the title form, the date or the `**Amended**` line breaks `status`'s **Next** check; a record written before the form (a range such as `48-01 … 48-08`) names only its two ends. No mod reads the records.
- **The spec's Challenge section.** `plan` writes a spec's `## Challenge` section and `review` reads it, in the forms `cpm-next/shared/artifacts.md` gives (the `**Personas**:` line and the bullets with their marks); a change to a form breaks the other skill's reading of it. The **Reviewers** reuse form and the `Decided at challenge:` and `Reopens challenge:` entries are written for the reader and parsed by nothing. `status` reads neither, and no mod does: the section's only field line is `**Personas**:` and every other line is a bullet, which keeps `whats-next/hooks/plan.ts:201,204` (header fields matched at the start of any line) from reading it as a header.
- **Unknown fields in the mods.** `whats-next/hooks/plan.ts` reads `**Story**`, `**Task**`, `**Status**`, `**Blocked by**` and `**Source spec**` (and `**Withdrawn**` and `**Superseded by**` in specs); `cpm-next-progress/hooks/progress.ts` reads `**Story**`, `**Task**`, `**Status**`, `**Blocked by**`, `**Effort**` and `**Model**`, and `register.ts` reads `**Source spec**`. Both drop every other `**Field**:` line and read neither `docs/library/` nor `docs/quick/`, so `**Signal**`, `**Class**`, `**Audit**`, `**Test run**` and `**Independent tests**` are safe to add (the `**Audit**` suffix ` — full run due` and the `fix due` form included, since neither parser reads the field), provided `**Test run**` and `**Independent tests**` each stay one line in the header block before `**Acceptance Criteria**`, since both parsers count `- ` lines after that heading as criteria; `hooks/testrun.test.ts` in both mods holds this for `**Test run**` (no test covers `**Independent tests**`), with a control that a `- ` bullet under the criteria is read as one; the `**Test run**` line is rewritten on every run, so a story's epic doc changes more often and the `whats-next` note goes stale more often; a change to the format of any field listed here breaks a mod.
- **Contract strings a mod may later parse.** `red:` in `Evidence` lines, `red: n/a — existing (reaches …)`, the indented `- Waiting on user:` line under a criterion, `Evidence (user,`, `**Lessons**`, `**Scratch**`, `**Test run**`, `**Audit**` with its ` — full run due: …` suffix and `fix due (…) — full run failed: …` form (and `story tree {hash}`), the red forms `red: {failure text} — deferred full run, before the fix` and `red: {message} — before the build`, `**Independent tests**` in its three states (`due`, `{path} {blob}, … ({YYYY-MM-DD})` with its ` — revised {YYYY-MM-DD}: {path} ({citation})` notes, and `skipped — test-writer unavailable`), and `**Signal**` (with ` — cpm-next {version}` on a `process` signal, ` — recurs:`, ` — raised`, ` — promoted`, ` — declined`) in epics, stories and quick records, and `**Class**` in library lessons and amendments.
- **cpm-next ships a hooks module.** `cpm-next/hooks` (`hooks.json`, `register.ts`, `guard.ts`, `guard.test.ts`) and `cpm-next/tsconfig.json` make cpm-next a mod as well as a skill plugin, so the load failures recorded above can now reach the required plugin; load it headless under every installed engine before a release. Its laid types are ignored (`cpm-next/.claude-plugin/types/`).

**What asserts it.** Nothing automated asserts these dependencies, apart from the commit guard's tests (`cpm-next/hooks/guard.test.ts`), which read the scratch path and `tree` file as the contract describes. `claude plugin validate cpm-next` checks the plugin's own files, and the mods' suites (`claude plugin test cpm-next-models`, `cpm-next-progress`, `whats-next`) cover their own parsers, not these dependencies.
