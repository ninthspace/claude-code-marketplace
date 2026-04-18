---
name: cpm2:status
description: Project status reconnaissance. Scans CPM artifacts, git history, and codebase changes to produce an ephemeral status report with recommended next steps. Triggers on "/cpm2:status".
---

# Project Status

Scan the current project's CPM artifacts and git history to produce a structured status report. Print the report to stdout — no files saved, no state modified.

This is a read-only reconnaissance skill. It gathers information and reports it. All operations are read-only — files and git state remain untouched.

## Input

If `$ARGUMENTS` is provided, use it as focus context:

- If it's a **file path** (e.g. `docs/epics/02-epic-auth.md`), focus the report on that specific artifact and its related context.
- If it's a **description** (e.g. "what's the state of authentication work?"), use it to guide which parts of the report to emphasise.

If no arguments are given, produce a full project status report covering all CPM artifacts and recent activity.

## State Management

**This skill is stateless and ephemeral.** No progress file is created or maintained. No output artifact is saved. The report is printed to stdout and the skill is done. If the user needs to discuss or act on the status, they can invoke other CPM skills (e.g. `/cpm2:do`, `/cpm2:retro`, `/cpm2:archive`).

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

**Epic deep-read:** For each epic file, use the Read tool to extract the `**Status**:` field and story completion counts. Read each file individually with the Read tool directly (Bash loops with shell variables lose context). Only report epics that have **remaining work** (Status is not Complete). Completed epics are summarised as a single count (e.g. "17 epics complete"). Epics with remaining work get individual lines: "{Epic name}: {completed}/{total} stories — {status}".

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

If no CPM artifacts exist, say: "No CPM planning artifacts found. This project hasn't started the CPM planning pipeline yet."

If the project has active work (in-progress epics or sessions), lead with that — it's the most urgent context.

**Section 2 — Recommended Next Steps**: Based on everything gathered, suggest 1-3 concrete next actions. Use this decision logic:

| Project state | Recommendation |
|--------------|---------------|
| No CPM artifacts at all | "Start planning with `/cpm2:discover` or `/cpm2:brief`" |
| Briefs exist but no specs | "Turn your brief into a spec with `/cpm2:spec {brief path}`" |
| Specs exist but no epics | "Break your spec into epics with `/cpm2:epics {spec path}`" |
| Epics with pending/in-progress stories | "Continue work with `/cpm2:do {epic path}`" (show the specific epic with remaining work) |
| All epic stories complete, no retro | "Run a retrospective with `/cpm2:retro {epic path}`" |
| Retros exist, completed epics | "Archive completed work with `/cpm2:archive`" |
| Active progress files | "Resume active session — {skill name} is in progress" |
| Uncommitted changes | "You have uncommitted changes — consider committing before starting new work" |

Multiple recommendations can apply simultaneously. List them in priority order — the most impactful action first.

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
- **Actionable recommendations.** Every recommended next step should include a copy-pasteable command (e.g. `` `/cpm2:do docs/epics/02-epic-auth.md` ``).
- **Adaptive detail.** Match report depth to what's found. An empty project gets a short "getting started" report. A project with 5 epics gets a detailed inventory.
