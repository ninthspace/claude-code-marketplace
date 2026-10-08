# Claude Code Marketplace

A Claude Code plugin marketplace whose main offering is **cpm-next**: a planning and building method for Claude Code, plus the mods that keep its model, effort and progress in view. It also holds smaller development tools.

## cpm-next in brief

cpm-next turns an idea into working, tested code through a short chain of artefacts kept in your repository's `docs/` folder: a discussion record, a product brief, a specification, and epics made of stories with acceptance criteria. Six skills cover the whole path:

| Skill | What it does | Finished when |
|---|---|---|
| `/cpm-next:party` | Discussion with named specialist personas (PM, Architect, Developer, UX, QA and others) | A discussion record is saved and the next step is named |
| `/cpm-next:plan` | Writes whatever is missing of brief, spec and epics, from whatever already exists | The artefacts down to the epics exist and trace upward |
| `/cpm-next:review` | Independent challenge of the epics before they are built | Critical and Warning findings are fixed or waiting on you |
| `/cpm-next:do` | Builds stories, verifies each acceptance criterion with evidence, and has each story audited | Every story in scope is Complete and the tests pass |
| `/cpm-next:library` | Curates reference documents in `docs/library/` that planning and building read | Documents carry complete front-matter |
| `/cpm-next:status` | Read-only report of where things stand and the next command to run | Nothing is written |

Each skill declares its model and effort: Opus plans and reviews, Sonnet builds, an Opus `auditor` agent checks every story before it closes, a Haiku `scout` agent answers lookups, and `status` runs on Haiku. The artefact formats are defined in `cpm-next/shared/artifacts.md`; the plugin's own log of changes is in `cpm-next/README.md`.

**Training material** (open in a browser):
- [`cpm-next-onboarding.html`](cpm-next-onboarding.html) — install it and run your first spec in an afternoon
- [`cpm-next-presentation.html`](cpm-next-presentation.html) — a slide deck introducing the method
- [`cpm-next-training-guide.html`](cpm-next-training-guide.html) — the full guide: every skill, the artefacts, the mods and day-to-day practice

CPM and DPM, the earlier planning plugins, were withdrawn on 2026-10-08. Their source is in this repository's git history.

## Installation

Inside Claude Code:

```bash
/plugin marketplace add ninthspace/claude-code-marketplace
```

**The suffix is the marketplace's name, not the repository's.** `marketplace.json` declares `ninthspace-marketplace`, and every installed plugin is keyed by it, so `cpm-next@claude-code-marketplace` resolves to nothing.

### The cpm-next set

Install these at user scope (the default), so one install serves every repository:

```bash
/plugin install cpm-next@ninthspace-marketplace           # the six skills, the auditor and scout agents
/plugin install cpm-next-models@ninthspace-marketplace    # mod: holds each skill's model and effort, per-story effort
/plugin install cpm-next-progress@ninthspace-marketplace  # mod: /progress-tracker, a claude.ai tracker for a spec's epics
/plugin install whats-next@ninthspace-marketplace         # mod: /next, a live pane of the work left in the repository
/plugin install plugin-sync@ninthspace-marketplace        # mod: reloads open sessions when a plugin here is updated
/reload-plugins
```

Only `cpm-next` is required. The four mods are optional, and each adds one thing:

| Plugin | Kind | Without it |
|---|---|---|
| `cpm-next` | Skills and agents | — |
| `cpm-next-models` | Mod (function hooks) | A skill's model and effort last only for the turn that invoked it; later turns of a `do` run fall back to the session model, and stories are not given their own effort |
| `cpm-next-progress` | Mod, adds `/progress-tracker` | No shareable progress page; read the epic docs or run `/cpm-next:status` |
| `whats-next` | Mod, adds `/next` | No live pane; run `/cpm-next:status` |
| `plugin-sync` | Mod | After an update, run `/reload-plugins` in each open session |

**Mods** are plugins of function hooks that run inside Claude Code. They load like any plugin, run no model calls of their own unless stated, and are switched off and on with the plugin. A session that was open before you installed one needs `/reload-plugins` to load it.

**Per-project setup for `/progress-tracker`.** In a repository whose spec has epics in `docs/epics/`, run `/progress-tracker 01` (the spec's number), then ask Claude to publish the page it writes. The mod saves the tracker's link and keeps the table in step with the epic docs from then on. Details under [CPM Next Progress](#cpm-next-progress-v031).

**Keeping up to date.** The marketplace auto-updates when Claude Code starts. `plugin-sync` then reloads sessions that were already open. To update straight away, from any directory:

```bash
claude plugin marketplace update ninthspace-marketplace
claude plugin update cpm-next@ninthspace-marketplace      # and each other plugin that changed
```

### Other plugins

```bash
/plugin install noteplan@ninthspace-marketplace
/plugin install php-lsp@ninthspace-marketplace
/plugin install js-simplifier@ninthspace-marketplace
/plugin install filament-mockup@ninthspace-marketplace
/plugin install generated-files@ninthspace-marketplace
/plugin install weather@ninthspace-marketplace
```

## Available Plugins

### CPM Next (v0.7.2)

**Plan and build with six skills: party, plan, review, do, library, status**

The skills read and write Markdown artefacts under `docs/`: `discussions/`, `briefs/`, `architecture/`, `specifications/`, `epics/`, `reviews/`, `retros/`, `quick/` and `library/`. The artefacts are the only state; there are no progress files to clean up. A typical path:

1. `/cpm-next:party` to talk an idea through (optional).
2. `/cpm-next:plan` to write the brief, spec and epics. It reads what exists, asks its questions in one batch, and fills only the gaps. In a brownfield project it grounds every requirement in the current code.
3. `/cpm-next:review` before a large or risky epic (optional).
4. `/cpm-next:do` to build: one story (`/cpm-next:do 3`), one epic, or `all`, which runs unattended and marks a blocked story instead of stopping. Each acceptance criterion gets an `Evidence` line, and each story is audited before it closes.
5. `/cpm-next:status` whenever you return to the project.

**Story effort.** `plan` gives a story `**Effort**: high` where a mistake is costly or hard to see, and `**Effort**: low` for mechanical edits; with `cpm-next-models` installed, `do` builds each story at that effort and raises it for a fix after a failed audit. A `low` story marked `**Model**: haiku` is built by a Haiku subagent.

**Agents:** `auditor` (Opus, read-only) checks a finished story's evidence, diff, scope and tests; `scout` (Haiku, read-only) answers lookups such as where something is used or what a read-only query returns.

**Quick Start:**
```bash
/plugin install cpm-next@ninthspace-marketplace
/reload-plugins
/cpm-next:plan a CSV export for the bookings report
```

### CPM Next Models (v0.3.0)

**Holds each cpm-next skill's model and effort for its whole run**

A Claude Code mod. A skill's `model` and `effort` frontmatter normally lasts only for the turn that invoked it. This mod keeps them for every later turn of the run, including your replies to the skill's questions, until another skill runs, you switch model or effort yourself, or `/clear`. It runs `do all` at `high` effort, and gives `/cpm-next:do` a `set_story_effort` tool so each story is built at its own `**Effort**`, never below `high` in a `do all` run. The footer shows what is held, for example `cpm-next:do · story 3 · sonnet · low`.

**Commands:** `/cpm-models` shows what is held; `/cpm-models off` releases it.

**Quick Start:**
```bash
/plugin install cpm-next-models@ninthspace-marketplace
/reload-plugins
```

**Develop:** `claude plugin validate cpm-next-models` and `claude plugin test cpm-next-models`.

### CPM Next Progress (v0.3.1)

**A claude.ai progress tracker for a cpm-next spec's epics, with a check that it matches the epic docs**

A Claude Code mod (a plugin of function hooks). Name a spec and the mod writes a build order for its stories to a small JSON file, which you can edit; Claude then publishes a private claude.ai artifact showing that order as a table, grouped by phase. The mod compares the table with the epic docs in `docs/epics/` whenever they change, and tells Claude which rows to update. Status, titles and outstanding blockers come from the epic docs; the order, phase labels, notes and open decisions come from the build-order file.

**The mod only reads.** It lists the artifact's rows through the `ArtifactData` tool, which auto mode does not ask about, and never writes to it. Claude's own `ArtifactData` calls do the writing, so no permission rule is needed. An earlier version wrote to the artifact itself, and auto mode refused those calls intermittently with "The server-side auto mode classifier gave no verdict for ArtifactData".

**Build-order file:** `docs/specifications/NN-build-order.json`:
```json
{
  "title": "01-Series Build Order",
  "spec": "docs/specifications/01-spec-requirements-matrix-todos.md",
  "decisions": ["Questions still open, shown in a box above the table"],
  "phases": [
    { "label": "No visible change", "items": [
      { "epic": "01-05", "story": 1, "note": "Default value keeps today's text" },
      { "epic": "01-05", "task": "3.1" }
    ] },
    { "label": "Waiting on input", "note": "Shown beside the phase label", "items": [
      { "epic": "01-05", "story": 2, "waitingOn": "new name from the client" }
    ] }
  ]
}
```
An item is a story (`story`) or one task (`task`) of an epic, named by the epic's number prefix. `waitingOn` shows the item as **Waiting on input** until it is removed from the file or the item starts. `artifact` holds the tracker's link; the mod adds it when Claude publishes the page.

**The first build order** is written from the spec's epics (those whose number starts with the spec's): one phase per epic, epics ordered by their `**Blocked by**` epics, each epic's stories ordered by their `**Blocked by**` stories and then by number. Superseded and withdrawn epics and stories are left out. Edit the file afterwards to reorder, regroup, split a story into tasks or add `waitingOn`.

**Statuses:** Complete, In progress (the story says so, or one of its tasks has started), Waiting on input, Pending. A row's date moves only when its status changes. Blockers shown are the story's and epic's `**Blocked by**` items not yet Complete, earlier unfinished tasks of the same story, and any `waitingOn`.

**How it works:**
1. After any tool call that writes (Edit, Write, Bash and so on), the mod checks whether an epic doc or build-order file changed since the last check. If none did, it does nothing more.
2. If one did, it reads the tracker and works out the writes that would bring it in line. If there are none, it says nothing.
3. If there are some, it saves them to `.claude/cpm-next-progress/NN-build-order.pending.json`, shows you a one-line notice, and gives Claude a note with the artifact link and the writes. Claude applies them with one `ArtifactData` batch. More than eight writes stay in the file, and Claude hands them to a Haiku subagent, which reads the file and applies each batch, so they never enter the main conversation.

The folder `.claude/cpm-next-progress/` holds generated files (the page and the pending writes); `/progress-tracker 01` adds it to the project's `.gitignore`.

**Commands:**
- `/progress-tracker` — checks every tracker in the repository now and prints what differs, or "up to date".
- `/progress-tracker 01` (or a spec file, or a build-order file) — writes `docs/specifications/01-build-order.json` from the spec's epics if it does not exist yet, writes the page to `.claude/cpm-next-progress/`, and adds that folder to `.gitignore`. Then ask Claude to publish the page. When it does, the mod saves the link to the build-order file and gives Claude the rows to write. `init` before the name still works.

**Data layout** (in the artifact's database, readable by anyone it is shared with, writable by editors): collection `items`, one document per row (`01-05-s1`, `01-05-t3.1`); document `meta/tracker` with the title, spec, last update and decisions.

**Quick Start:**
```bash
/plugin install cpm-next-progress@ninthspace-marketplace
/reload-plugins

/progress-tracker 01
```
Then ask Claude to publish the page. The spec needs its epics in `docs/epics/` first.

**Reads:** the cpm-next epic format (`cpm-next/shared/artifacts.md`), as What's Next does.

**Develop:** `claude plugin validate cpm-next-progress` and `claude plugin test cpm-next-progress`. To run the working tree, start Claude Code with `--plugin-dir cpm-next-progress`.

### What's Next (v0.2.2)

**A live pane and band showing the cpm-next work left in the current repository**

A Claude Code mod (a plugin of function hooks). It reads the `docs/epics/` and `docs/specifications/` folders of the repository the session runs in — or the nearest folder above it that has either — and shows every story not yet `Complete`, in the order to build them, and every spec no epic has been planned from yet. It reads the files directly, with no model calls, so it stays current as `/cpm-next:do` or you edit the epics.

**What it shows:**
- **Pane** — the story in progress and its next task, every remaining story in order (`doing`, `ready`, or `after Story 1` / `after Epic …`), and each open epic's story count. Opens by itself in a repository with work left when the terminal is at least 144 columns wide; `/next` opens it at any width.
- **Specs without epics** — each spec in `docs/specifications/` that no epic was planned from, in number order. A spec counts as planned when an epic is numbered after it (`03-spec-…` → `03-01-epic-…`) or an epic names its file in `**Source spec**`; a spec whose own `**Status**` is `Complete`, `Superseded` or `Withdrawn` is left out, as is a withdrawal notice (a `**Withdrawn**` or `**Superseded by**` field, or `WITHDRAWN` / `SUPERSEDED` in its title).
- **Band** — one line above the prompt with the next story, its next task, and how many stories are left; with no stories left, the first spec to plan.
- **Next steps** — an `Ask Claude` button (hotkey `a`) that asks Sonnet for a short note on what to do next, from the ordered list and the first two stories in full. The note is kept per repository across sessions and dimmed once the epics change after it was written.

**Order of execution:** stories already `In Progress` first; then the other stories of epics under way (the epic's own `**Status**` is `In Progress`, or one of its stories is); then everything else. Within each group, repeatedly, the ready story with the lowest epic number and story number, treating each as done before choosing the next. So working on a higher-numbered epic out of order moves it to the top once its Status says `In Progress`. A story is ready when everything its own `**Blocked by**` and its epic's `**Blocked by**` name is `Complete`; epics in `docs/archive/epics/` count when resolving those dependencies. Stories whose dependencies can never be met (an unknown epic, a cycle) are listed last.

**Quick Start:**
```bash
/plugin install whats-next@ninthspace-marketplace
/reload-plugins

# Open the pane and print the ordered list into the conversation
/next
```

**Reads:** the cpm-next epic format (`cpm-next/shared/artifacts.md`) — `**Status**`, `**Blocked by**`, `**Story**` and `**Task**` fields, read case-insensitively, with `Done` read as `Complete`. `Superseded` and `Withdrawn` epics are skipped.

**Develop:** `claude plugin validate whats-next` and `claude plugin test whats-next`. To run the working tree instead of the installed release, start Claude Code with `--plugin-dir whats-next` (and uninstall the release, or both draw).

### Plugin Sync (v0.1.0)

**Open sessions pick up plugin updates without a manual `/reload-plugins`**

A Claude Code mod (a plugin of function hooks). Every five minutes, and after each answer, it compares `~/.claude/plugins/installed_plugins.json` with the versions of this marketplace's plugins that the session loaded. When one differs, it shows a one-line notice naming the plugins and versions, and runs `/reload-plugins`, which waits until the session is idle. A project-scope install is compared for sessions in that project, and the user-scope install for all others.

**It does not install updates.** The marketplace's auto-update does that when any new session starts, or run it yourself once, from any directory:
```bash
claude plugin marketplace update ninthspace-marketplace
claude plugin update cpm-next@ninthspace-marketplace   # each plugin that changed
```

**Quick Start:**
```bash
/plugin install plugin-sync@ninthspace-marketplace
/reload-plugins
```
Install it at user scope so every session loads it. A session already open needs one manual `/reload-plugins` to load the mod; after that it reloads itself.

**Develop:** `claude plugin validate plugin-sync` and `claude plugin test plugin-sync`.

### NotePlan Search (v1.0.0)

**Search and query NotePlan notes from Claude Code**

A skill for searching NotePlan content across:
- **Notes folder** - Standalone notes
- **Calendar folder** - Daily/weekly/monthly notes
- **Spaces** - Team/shared notes (SQLite database)
- **iCloud** - If syncing via iCloud Drive

Results are sorted by most recently modified first.

**Quick Start:**
```bash
# Search for a term
/noteplan coffee

# List all Spaces notes
/noteplan --list --spaces

# Fetch full note by ID
/noteplan --get UUID

# Search with date filters
/noteplan meeting --after 2025-01-01

# Natural language queries
/noteplan find me everything about project planning
```

**Key Features:**
- Full-text search across all NotePlan sources
- Date filtering (--after, --before)
- JSON output for AI tools
- Direct noteplan:// URLs to open notes in the app
- Excludes @Templates, @Trash, @Archive by default (use --all to include)

**Requirements:**
- macOS with NotePlan 3 installed
- Python 3

[View full documentation](./noteplan/SKILL.md)

---

### PHP LSP (v1.0.0)

**PHP semantic code intelligence for Claude Code**

Adds 24 LSP tools to Claude Code for PHP files via [intelephense](https://intelephense.com/) and the [lsp-mcp-server](https://github.com/ProfessioneIT/lsp-mcp-server) bridge.

**Capabilities:**
- Go-to-definition, find references, find implementations
- Hover info (type signatures, documentation)
- Code completion and signature help
- Diagnostics (errors, warnings) per file and project-wide
- Safe rename across entire codebase
- Code actions (quick fixes, refactoring)
- Call hierarchy and type hierarchy
- File analysis (imports, exports, related files)
- Document formatting

**Quick Start:**
```bash
# One-time setup (installs intelephense + lsp-mcp-server, configures project)
/php-lsp:setup

# Restart Claude Code — LSP auto-starts on first use

# Check everything is working
/php-lsp:status
```

**Requirements:**
- Node.js >= 18
- Git

[View full documentation](./php-lsp/README.md)

---

### JS/TS Simplifier (v1.0.0)

**Simplify and improve JavaScript and TypeScript code across an entire codebase**

A skill that scans all JS/TS files (or a configurable subset) and applies clarity, consistency, and maintainability improvements while preserving exact functionality. Unlike targeted simplification of recently changed files, this skill works across the whole codebase.

**Three parallel analysis agents:**
- **Modern Syntax** — ES2015+ and ES2020+ upgrades (optional chaining, nullish coalescing, async/await, const/let)
- **Code Quality** — Dead code removal, conditional simplification, naming improvements, error handling
- **Structure & Reuse** — DRY violations, module organisation, function complexity, async patterns

**Quick Start:**
```bash
# Simplify all JS/TS files in the project
/js-simplify

# Narrow to a specific directory
/js-simplify src/

# Only git-modified files
/js-simplify only changed

# Focus on a specific pattern
/js-simplify focus on async patterns
```

**Key Features:**
- Parallel three-agent analysis for comprehensive coverage
- Respects project conventions (CLAUDE.md, ESLint, Prettier, tsconfig)
- Configurable scope — all files, specific directories, globs, or git-changed only
- Safety-first — never changes what the code does, only how it does it
- Flags ambiguous cases for manual review rather than auto-applying

**Supported File Types:**
- `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`

[View full documentation](./js-simplifier/SKILL.md)

### Filament Mockup (v1.1.0)

**Build high-fidelity Filament v5 admin mockups for stakeholder sign-off**

A skill that turns a product brief or spec into a single self-contained HTML file that looks pixel-accurate to a real Filament v5 admin panel — clickable enough to walk a stakeholder through every screen and flow, and throwaway by design (the real Filament build regenerates all of it natively). Mockups use the real captured Filament theme CSS and Filament's exact `fi-*` markup, so what stakeholders sign off on is what gets built. **Not** for production Filament code or customer-facing/front-end mockups.

**Workflow:**
- **Capture** — lift the compiled theme CSS and design tokens from a real Filament v5 panel
- **Inventory** — build an FR → screen matrix so every element traces back to a numbered functional requirement
- **Build** — reuse Filament's exact `fi-*` grammar; mark genuinely custom components with the `mk-` namespace
- **Verify** — measure with Playwright rather than eyeballing, then sign off with a coverage audit
- **Hand off** — write the durable routing table (`docs/mockups/surface-routing.md`) so the downstream builder `mockup-to-filament` knows which surfaces it owns (works stand-alone — no `brief-to-mockups` prerequisite)

**Quick Start:**
```bash
# Turn a brief/spec into clickable admin screens
create a Filament mockup from docs/specifications/05-spec-admin-panel.md

# Or describe it directly
mock up the admin panel for this PRD
```

**Key Features:**
- Single self-contained HTML file — opens by `file://`, zero environment to stand up
- Maximum fidelity to Filament's real design language (captured theme, Albert Sans, standard layouts)
- Every element traces to a functional requirement — invented UI is flagged, not silently added
- Visible `mk-` vs `fi-*` boundary distinguishes mockup scaffolding from real Filament
- Bundled scaffold, capture/verify scripts, and an `fi-*` grammar cheat-sheet
- Part of the mockup→build family — a *producer* whose output the *builders* consume (`mockup-to-filament` for Filament, `mockup-to-blade` for bespoke); emits a routing handoff naming the lane per surface

**Requires:** Node + Playwright for the capture/verify scripts (`npm i -D playwright && npx playwright install chromium`).

[View full documentation](./filament-mockup/SKILL.md)

### Generated Files (v0.1.1)

**A pane listing the files Claude generated this session, each with an Open button**

A Claude Code mod (a plugin of function hooks). Skills such as `code-to-uml`, `filament-mockup` and the md2docx wrapper write HTML, Office and image files, often into the session scratchpad; this pane collects them so they can be opened without finding the path.

**What it records:** files with the extensions `.html` `.htm` `.svg` `.png` `.jpg` `.jpeg` `.gif` `.webp` `.docx` `.xlsx` `.pptx` `.pdf` that are
- written or edited with the Write or Edit tools, or
- named in a Bash command and changed while it ran (a leading `cd <dir> &&` sets the folder relative paths resolve against). For `md2docx` and `pandoc` runs, the `.docx` beside each `.md` named is checked too, since md2docx writes there by default.

**What it shows:** a "Files" pane, newest first, up to 30 files: each file's name and folder with **Open** (hotkeys `1`–`9`, macOS `open`, the default app) and **Reveal** (shows it in Finder), and a **Clear** button. The pane opens by itself when the first file is recorded, where the terminal is at least 144 columns wide; `/files` opens it at any width and prints the list into the conversation. The list covers the current session only.

**Quick Start:**
```bash
/plugin install generated-files@ninthspace-marketplace
/reload-plugins

/files
```

**Requires:** macOS (`open`).

**Develop:** `claude plugin validate generated-files` and `claude plugin test generated-files`.

### Weather (v0.1.2)

**The current weather for a place you set, in the prompt footer**

A Claude Code mod (a plugin of function hooks). Shows the condition and temperature, e.g. `☁️ Overcast 18°C · Inverness`, dimmed at the right-hand end of the footer beside the mode labels. Data comes from Open-Meteo (no API key), refreshed every 15 minutes; if a refresh fails, the last reading stays.

**Location:** the plugin's **Location** row in `/config`, default `Inverness, GB`. A trailing two-letter country code narrows the search: a bare `Inverness` finds a US Inverness first. Each location is geocoded once and remembered across sessions.

**When it fails:** with no reading yet, the footer shows `weather: <reason>` (for example `forecast HTTP 503`). `/weather` refreshes at once and prints the reading, or why the refresh failed.

**Quick Start:**
```bash
/plugin install weather@ninthspace-marketplace
/reload-plugins
```

**Develop:** `claude plugin validate weather` and `claude plugin test weather`.

## Removing Plugins (when in Claude Code)

```bash
/plugin uninstall cpm-next@ninthspace-marketplace
/plugin uninstall cpm-next-models@ninthspace-marketplace
/plugin uninstall cpm-next-progress@ninthspace-marketplace
/plugin uninstall whats-next@ninthspace-marketplace
/plugin uninstall plugin-sync@ninthspace-marketplace
/plugin uninstall noteplan@ninthspace-marketplace
/plugin uninstall php-lsp@ninthspace-marketplace
/plugin uninstall js-simplifier@ninthspace-marketplace
/plugin uninstall filament-mockup@ninthspace-marketplace
/plugin uninstall generated-files@ninthspace-marketplace
/plugin uninstall weather@ninthspace-marketplace

# Remove the entire marketplace
/plugin marketplace remove ninthspace-marketplace
```

## License

MIT - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please:
1. Follow the existing plugin structure
2. Include comprehensive documentation
3. Add tests where applicable
4. Update the marketplace manifest
5. Submit a pull request

## Support

For issues or questions:
- Open an issue on GitHub
- Check plugin-specific documentation
- Review the [Claude Code plugin docs](https://docs.claude.com/en/docs/claude-code/plugins)

## Author

Chris Aves

## Links

- [Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Marketplace Documentation](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
