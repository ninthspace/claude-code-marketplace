---
name: cpm:present
description: Audience-aware transformation of CPM artifacts. Takes one or more CPM artifacts as input, offers audience and format selection, and produces derived communication content. Regenerable when source artifacts change. Triggers on "/cpm:present".
---

# Audience-Aware Artifact Transformation

Transform CPM planning artifacts into audience-appropriate communications. Content is **derived** from source artifacts — not written from scratch. The same artifacts can be presented differently for different audiences and formats.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references one or more file paths, read those files as the source artifacts.
2. If `$ARGUMENTS` contains a description of what to present, use that as guidance for artifact discovery.
3. If neither, discover available artifacts:
   a. **Glob** across all CPM artifact directories:
      - `docs/plans/[0-9]*-plan-*.md` (problem briefs)
      - `docs/briefs/[0-9]*-brief-*.md` (product briefs)
      - `docs/specifications/[0-9]*-spec-*.md` (specifications)
      - `docs/architecture/[0-9]*-adr-*.md` (ADRs)
      - `docs/epics/[0-9]*-epic-*.md` (epic docs)
      - `docs/retros/[0-9]*-retro-*.md` (retrospectives)
      - `docs/reviews/[0-9]*-review-*.md` (review files)
   b. Present discovered artifacts grouped by type with AskUserQuestion. Let the user select which artifacts to include as source material. Support multi-select — communications often draw from multiple artifacts.
   c. If no artifacts found, tell the user there's nothing to present yet and suggest running other CPM skills first.

### Library Check (Startup)

Before artifact selection, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently.
2. **Read front-matter** of each file found. Filter to documents whose `scope` array includes `present` or `all`.
3. **Report to user**: "Found {N} library documents relevant to presentations: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** when generating content — e.g. brand guidelines when formatting for clients, or glossaries when writing for non-technical audiences.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the process due to a malformed library document.

**Compaction resilience**: Include library scan results in the progress file so post-compaction continuation doesn't re-scan.

### Template Hint (Startup)

After startup checks and before artifact selection, display the template hint:

> Using default templates. To customise, place format-specific templates at `docs/templates/present/{format-name}.md`.

If a project-level override exists at `docs/templates/present/{format-name}.md` for the selected format, read it and use that structure for the output instead of the embedded default. Full replacement — no merging.

## Process

After source artifacts are selected, work through these steps. Use AskUserQuestion for gating.

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After saving the final output, delete the file.

### Step 1: Select Audience

Present the audience options using AskUserQuestion:

- **Executive** — High-level, outcome-focused. Assumes no technical knowledge. Emphasises business value, risks, and decisions needed.
- **Client** — External-facing, professional. Focuses on what's being delivered and why it matters to them. Avoids internal process details.
- **Technical stakeholder** — Peers who understand technology but aren't in the code. Covers architecture, trade-offs, and technical decisions without implementation details.
- **Team onboarding** — New team members getting up to speed. Provides context, explains decisions, and maps the landscape.
- **Custom** — Let the user describe their audience. Ask follow-up questions to understand their knowledge level, what they care about, and what tone to use.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 1 summary before continuing.

### Step 2: Select Format

Present the format options using AskUserQuestion. Not all formats suit all audiences — highlight which formats work best for the selected audience:

- **Summary memo** — Concise overview (1-2 pages). Best for executives and clients.
- **Status update** — Progress-focused. What's done, what's in progress, what's blocked. Best for stakeholders and team leads.
- **Presentation outline** — Slide-ready structure with key points per slide. Best for executives and clients.
- **Changelog** — What changed and why. Best for technical stakeholders and team onboarding.
- **Onboarding guide** — Comprehensive context document. Best for team onboarding.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 2 summary before continuing.

### Step 3: Generate Derived Content

Read the selected source artifacts fully. Then generate content that is **derived from** the artifacts — transforming, summarising, and reframing their content for the selected audience and format.

**Derivation rules**:
- Every claim, number, status, and decision in the output must trace back to a source artifact. Do not invent information.
- Adapt language and detail level for the audience. An executive summary omits technical specifics; an onboarding guide includes them.
- Adapt structure for the format. A presentation outline uses slide headings with bullet points; a changelog uses chronological entries.
- Reference source artifacts in the output metadata so the reader knows where to find detail.

Present the draft to the user for review using AskUserQuestion. Refine based on feedback.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 3 summary before continuing.

### Step 4: Save Output

Save the communication to `docs/communications/{nn}-{format}-{slug}.md`.

- `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/communications/[0-9]*-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
- `{format}` is the kebab-case format name (e.g., `summary-memo`, `status-update`, `presentation-outline`, `changelog`, `onboarding-guide`).
- `{slug}` is a short kebab-case name derived from the content (e.g., `q1-progress`, `auth-system-overview`).

Create the `docs/communications/` directory if it doesn't exist.

Use this format:

```markdown
# {Title}

**Date**: {today's date}
**Audience**: {selected audience}
**Format**: {selected format}
**Source artifacts**:
- {path to source artifact 1}
- {path to source artifact 2}

---

{Derived content appropriate to audience and format}
```

The `**Source artifacts**` field enables regeneration — when source artifacts change, re-running `cpm:present` with the same sources and audience/format selections produces an updated output.

After saving, tell the user the document path.

**Regeneration**: If the user runs `cpm:present` and an existing communication already exists for the same source artifacts, audience, and format, offer to update it in place rather than creating a new file. Use AskUserQuestion to confirm.

## Arguments

If `$ARGUMENTS` is provided, use it as the starting context. If it references file paths, read those as source artifacts. If it contains a description, use that to guide artifact discovery.

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context on startup — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Do not attempt adoption if `CPM_SESSION_ID` is absent from context — the fallback path handles that case.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after the final communication has been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:present
**Step**: {N} of 4 — {Step Name}
**Output target**: docs/communications/{nn}-{format}-{slug}.md

## Source Artifacts
{List of selected source artifact paths}

## Completed Steps

### Step 1: Select Audience
{Selected audience and any custom audience description}

### Step 2: Select Format
{Selected format}

### Step 3: Generate Derived Content
{Brief summary of what was generated, key themes covered}

{...include only completed steps...}

## Next Action
{What to ask or do next}
```

The "Completed Steps" section grows as steps complete.

## Guidelines

- **Derive, don't invent.** Every statement in the output must trace back to a source artifact. If you can't point to where something came from, don't include it.
- **Transform, don't copy.** The value is in reframing — adapting language, structure, and detail level for the audience. A straight copy-paste of the source is not a transformation.
- **Audience dictates tone.** An executive summary is crisp and outcome-focused. An onboarding guide is thorough and explanatory. Let the audience drive every writing decision.
- **Format dictates structure.** A presentation outline needs slide headings. A changelog needs chronological entries. Follow the format's conventions.
- **Source traceability enables regeneration.** Always record which artifacts were used so the output can be updated when sources change.
