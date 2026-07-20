---
name: cpm:status
description: Project status reconnaissance. Scans CPM artifacts, git history, and codebase changes to produce an ephemeral status report with recommended next steps, plus an optional full-picture HTML dashboard on request. Triggers on "/cpm:status".
---

# Project Status

Scan the current project's CPM artifacts and git history to produce a structured status report. Print the report to stdout — no files saved, no state modified.

This is a read-only reconnaissance skill. It gathers information and reports it. All scan operations are read-only — source files and git state remain untouched.

**Optional full-picture HTML document.** On request, `status` can *additionally* generate a standalone, self-contained HTML document that presents the comprehensive project picture the one-screen narrative deliberately omits — full epic/story completion grid, in-progress + blocked panel, RAG indicators, recent git activity, and recommended next steps. This is an **opt-in extra, never the default**: the stdout narrative below is always produced and unchanged. See **Phase 4** for the mechanics.

## Input

If `$ARGUMENTS` is provided, use it as focus context:

- If it's a **file path** (e.g. `docs/epics/02-epic-auth.md`), focus the report on that specific artifact and its related context.
- If it's a **description** (e.g. "what's the state of authentication work?"), use it to guide which parts of the report to emphasise.
- If it **requests the HTML document** (e.g. contains `html`, `dashboard`, "full picture", or "open it in a browser"), produce the stdout narrative as usual **and** generate the optional full-picture HTML document (Phase 4). A focus path/description still applies — it shapes both outputs.

If no arguments are given, produce a full project status report covering all CPM artifacts and recent activity. Do **not** generate the HTML document unless it is requested.

## State Management

**This skill is stateless and ephemeral.** No progress file is created or maintained. The stdout report is printed and the skill is done. If the user needs to discuss or act on the status, they can invoke other CPM skills (e.g. `/cpm:do`, `/cpm:retro`, `/cpm:archive`).

**The optional HTML document is ephemeral by default — and must NOT be persisted unless the user asks.** This preserves `status`'s stateless nature; the document is a regenerated-on-demand view, not a tracked artifact.

- **Default status run** (no HTML requested): nothing is written at all — stdout only, exactly as before.
- **HTML requested** (Phase 4): write the document to the ephemeral scratch path **`docs/plans/status-dashboard.html`** so it can be opened in a browser, then tell the user the path and that it is **ephemeral — regenerated on demand and overwritten in place**, safe to delete. This file is deliberately **not** a numbered/tracked CPM artifact: it carries no `{nn}` prefix, the skill never commits it, and re-running with an HTML request simply overwrites it. Writing this regenerated view is *not* "saving" — it is the rendering mechanism; the document is never persisted as durable, user-owned state on its own.
- **Persist on request only**: if the user explicitly asks to keep the document, save a copy to a durable location they specify (or, if they don't specify one, offer a sensible default and confirm before writing). Only this explicit step "saves" the document. Absent such a request, the ephemeral file is the only output and remains throwaway.

This is the ephemeral-default / save-on-request contract: the user must ask for the HTML at all (it never appears on the default path), and must ask again to persist it durably.

## Stale-Progress Check

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions loaded at session start).

## Process

Work through three phases sequentially. Each phase gathers data; the final phase synthesises everything into the report.

### Phase 1: Artifact Inventory Scan

Scan CPM documentation directories for artifacts. For each directory, use the Glob tool. If the directory doesn't exist or contains no matching files, skip it silently — always degrade gracefully on missing data.

**Directories to scan:**

| Directory | Glob pattern |
|-----------|-------------|
| Briefs | `docs/briefs/[0-9]*-brief-*.md` |
| Specifications | `docs/specifications/[0-9]*-spec-*.md` |
| Epics | `docs/epics/[0-9]*-epic-*.md` (exclude coverage matrices) |
| Discussions | `docs/discussions/[0-9]*-discussion-*.md` |
| Retros | `docs/retros/[0-9]*-retro-*.md` |
| Architecture | `docs/architecture/[0-9]*-adr-*.md` |

**For each directory**, count the files found. Report only the count, not individual files.

**Epic deep-read:** For each epic file, use the Read tool to extract the `**Status**:` field and story completion counts. Read each file individually with the Read tool directly (Bash loops with shell variables lose context). **Read each status by its leading token** — the text up to the first delimiter (`—` / `–`, ` - `, `(`, `;`); normalise *that* against the vocabulary and treat any tail as a human note (see `cpm/shared/status-model.md`, *Status parsing*). So `Complete — folded into Story 10` reads as `Complete`. Only report epics that have **remaining work** — Status is not `Complete`/`Done` (readers treat `Done` as a synonym for `Complete`) and not retired (`Superseded` / `Withdrawn`, the terminal user-set statuses for work no longer needed). A retired epic has no remaining work: its stories still count as done in progress counts (the work is closed out), and it never appears as something needing attention. Completed epics are summarised as a single count (e.g. "17 epics complete"); retired epics are likewise summarised as a count (e.g. "2 epics superseded/withdrawn"), with `/cpm:archive` suggested to sweep them. Epics with remaining work get individual lines: "{Epic name}: {completed}/{total} stories — {status}".

**Retro waiver:** when deciding whether a completed epic needs a retro, honour an epic-level `**Retro waived**:` marker (a header-block field, distinct from the story-level `**Retro**:` observation fields; set by `/cpm:retro triage` on a clean epic — see `cpm/shared/status-model.md`, *Retro waiver*). A waived completed epic is **retro-satisfied**: do not flag it as needing a retro, exactly as if a `docs/retros/` retro existed for it.

**Unrecognised statuses:** a status whose leading token is *not* in the recognised vocabulary (story: `Pending`/`In Progress`/`Complete`/`Done`; epic: those plus `Superseded`/`Withdrawn` — story-level `Superseded`/`Withdrawn` is unrecognised, those being epic-level only) is **flagged, never guessed**. Do not infer intent from free prose; record the raw text and its location. Such a status **counts as not-done** (conservative). Collect these for a callout in the report — do not silently drop them.

**Progress files:** Glob `docs/plans/.cpm-progress-*.md`. If any exist, read the first few lines to extract `**Skill**:` and `**Current task**:`/`**Phase**:` fields. Report which skills have active sessions.

**Collect the data** — save it for Phase 3, which handles formatting.

### Phase 2: Git Activity Scan

Gather recent git activity using Bash commands. All git commands must be read-only.

**Step 2a: Branch and working tree status**

Run `git status --short` and `git branch --show-current` using the Bash tool. Capture:
- Current branch name
- Whether there are uncommitted changes (staged or unstaged)
- Whether there are untracked files

If on a non-main branch, also run `git diff --stat main...HEAD` to summarise the in-flight changes on this branch relative to main. If the `main` branch doesn't exist, try `master`. If neither exists, skip the branch diff.

**Step 2b: Recent commit history**

Use an **adaptive time window** to determine how far back to look:

1. Run `git log --oneline -1 --format=%ct` to get the timestamp of the most recent commit.
2. Calculate the gap between now and the last commit:
   - **Gap < 1 day**: Look at the last 3 days
   - **Gap 1-7 days**: Look at the last 2 weeks
   - **Gap > 7 days**: Look at the last 20 commits regardless of date

Run `git log --oneline` with the appropriate filter to get the commit list. Also run `git log --format="%s"` with the same filter to get the full subject lines — these are the raw material for the narrative synthesis in Phase 3.

**Collect the data** — save it for Phase 3, which handles formatting.

### Phase 3: Synthesis and Report

Combine data from Phase 1 and Phase 2 into a **narrative summary** that tells the user what's been happening and where things stand. The goal is contextual understanding, not raw data. Print directly to stdout.

**Section 1 — Summary**: Write a narrative briefing that would orient someone picking up this project for the first time. It should answer the questions a new developer would ask: "What is this? What's been done? What's in flight? What needs attention?" Write it as 2-4 short paragraphs:

1. **What this project is**: Infer the project's purpose from artifact names, epic titles, commit messages, and any README or CLAUDE.md. One or two sentences that describe the project to someone who has never seen it.

2. **What's been built**: Summarise the body of completed work. Group epics into themes rather than listing individually (e.g. "Core planning pipeline (discover → spec → epics → do), facilitation skills (party, consult), quality infrastructure (TDD, coverage matrices, review)"). This gives a sense of the project's maturity and scope.

3. **What happened recently**: Read the commit subjects from Phase 2 and identify the themes of recent work. Group related commits into a narrative thread (e.g. "Recent work focused on coverage matrix improvements and adding the consult skill"). Mention the time since last commit if there's been a notable gap.

4. **What needs attention now** (if anything): In-progress epics or stories, active CPM sessions, uncommitted changes, feature branches with in-flight work, stale progress files. If everything is clean and complete, say so — that's useful information too.

**Unrecognised-status callout:** if the Phase 1 scan collected any unrecognised statuses, add a distinct callout here — e.g. "⚠ Unrecognised statuses: docs/epics/05-…, Story 3 — `Folded into Story 10`. These count as not-done; rewrite to `Complete — note` (or the correct status) to resolve." Name each offending epic/story and show its raw status verbatim. This is the only place the report exposes off-vocabulary statuses; keep it separate from the normal progress narrative so it reads as an anomaly to fix, not a state to accept.

If no CPM artifacts exist, say: "No CPM planning artifacts found. This project hasn't started the CPM planning pipeline yet."

If the project has active work (in-progress epics or sessions), lead with that — it's the most urgent context.

**Section 2 — Recommended Next Steps**: Based on everything gathered, suggest 1-3 concrete next actions. Use this decision logic:

| Project state | Recommendation |
|--------------|---------------|
| No CPM artifacts at all | "Start planning with `/cpm:discover` or `/cpm:brief`" |
| Briefs exist but no specs | "Turn your brief into a spec with `/cpm:spec {brief path}`" |
| Specs exist but no epics | "Break your spec into epics with `/cpm:epics {spec path}`" |
| Epics with pending/in-progress stories | "Continue work with `/cpm:do {epic path}`" (show the specific epic with remaining work) |
| All epic stories complete, no retro **and not waived** | "Run a retrospective with `/cpm:retro {epic path}`" |
| Completed epic carries a `**Retro waived**:` marker | Retro-satisfied — do **not** suggest a retro (waived clean epics; see below) |
| Retros exist, completed epics | "Archive completed work with `/cpm:archive`" |
| Active progress files | "Resume active session — {skill name} is in progress" |
| Uncommitted changes | "You have uncommitted changes — consider committing before starting new work" |

Multiple recommendations can apply simultaneously. List them in priority order — the most impactful action first.

### Phase 4: Optional Full-Picture HTML Document (on request only)

This phase runs **only when the HTML document was requested** (see Input). If it was not requested, skip Phase 4 entirely — the skill ends after the stdout report. Phase 4 never alters Phases 1–3: the stdout narrative is produced and printed exactly as before, then the document is generated *in addition*.

The document is **HTML-native** — synthesised directly from the Phase 1 + Phase 2 scan data already gathered, with **no Markdown intermediate**. There is no stored status artifact to render *from*; the same read-only scan that fed the narrative feeds the document. Because both draw from one scan, their numbers must agree — the document's completion counts, in-progress/blocked lists, and git activity are the same data the narrative reports, just shown in full rather than synthesised to a screenful.

Follow the shared **HTML Output** convention for the template mechanics; this phase states only the `status`-specific particulars.

1. **Consume the shared template** (`cpm/assets/html/template.html`) — substitute the `CPM:` tokens, **never fork the `<style>` block**. Populate: `CPM:TITLE` (e.g. "Project Status — Full Picture"), `CPM:SUBTITLE` (the project name / focus), `CPM:META` (scan date + "generated from a live scan"), `CPM:NAV` (a `.cpm-toc` contents list of in-page anchors to the sections below), `CPM:CONTENT` (the sections), `CPM:FOOTER` (a one-line "ephemeral — regenerated on demand" note).
2. **Sections** (give each an `id` so the nav anchors resolve):
   - **At a glance (RAG)** — green = complete, amber = in progress, red = blocked/partial, using the template's `.sev-minor` / `.sev-major` / `.sev-critical` / `.sev-info` badges for the colour language. State the headline figure as **"{complete} of {total} epics complete"** — the canonical agreement statement that must match the count the stdout narrative reports.
   - **In progress & blocked** — the active and blocked stories/epics, as `.cpm-callout--warn` / `.cpm-callout--note` panels.
   - **Epic / story completion grid** — every epic with its complete/total story count and a status pill, in a `<table>`. Apply the **graceful schema tolerance** rule: where an epic doc's structure varies (missing status, partial counts), render what parsed and visibly flag the gap rather than omitting the row or erroring.
   - **Recent git activity** — the Phase 2 commit list.
   - **Recommended next steps** — the same actions as the stdout report's Section 2.
3. **Tier 2 — optional export affordances.** Unlike Spec 1's static-only renders, this document **may** include inline vanilla JS for **copy-as-prompt / copy-as-JSON** export — follow the shared **HTML Output → Tier 2 export affordances** convention for the canonical pattern and rules (inline-only, read-only/export-only, data embedded at generation time). Useful here: **copy-as-prompt** on each recommended next step (e.g. `/cpm:do docs/epics/05-…`) and **copy-as-JSON** of the status summary (the completion counts + in-progress/blocked lists). Interactivity is an *enhancement, not the point* — a purely static document is a valid deliverable.
4. **Self-contained** — a single file: inline CSS/SVG and inline JS only, no external CSS/JS/images/fonts, no CDN, no build step. It must open correctly when double-clicked or sent to someone.

For where the file is written and the save-on-request lifecycle, see **State Management** below.

## Report Format

Print the report to stdout using this structure:

```
# Project Status

## Summary
{Narrative paragraph — what the project is, what's been happening, where things stand}

## Recommended Next Steps
{1-3 concrete actions with copy-pasteable commands}
```

**Brevity is paramount.** The entire report should fit in one screenful. The summary is a narrative, not a data dump — synthesise into themes and patterns.

## Guidelines

- **Read-only.** Use only read-only operations: `git log`, `git status`, `git diff`, `git branch`. All files and git state remain untouched.
- **Graceful degradation.** If a directory doesn't exist, skip it silently. If no artifacts are found, say so and suggest where to start. Always degrade gracefully on missing data.
- **Scannable output.** Use clear section headers, concise summaries, and bullet points. The entire report should be digestible in under a minute.
- **Actionable recommendations.** Every recommended next step should include a copy-pasteable command (e.g. `` `/cpm:do docs/epics/02-epic-auth.md` ``).
- **Adaptive detail.** Match report depth to what's found. An empty project gets a short "getting started" report. A project with 5 epics gets a detailed inventory.
