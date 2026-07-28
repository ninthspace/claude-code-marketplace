---
name: present
description: Audience-aware transformation of CPM artifacts. Takes one or more CPM artifacts as input, offers audience and format selection, and produces derived communication content — optionally published as a shareable hosted page. Regenerable when source artifacts change. Triggers on "/cpm:present".
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

### Stale-Progress Check (Startup)

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions loaded at session start).

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `present`. Deep-read selectively when audience or format choices depend on library context — e.g. brand guidelines when formatting for clients, or glossaries when writing for non-technical audiences.

### Template Hint (Startup)

After startup checks and before artifact selection, display the template hint:

> Using default templates. To customise, place format-specific templates at `docs/templates/present/{format-name}.md`.

If a project-level override exists at `docs/templates/present/{format-name}.md` for the selected format, read it and use that structure for the output instead of the embedded default. Full replacement — no merging.

## Process

After source artifacts are selected, work through these steps. Use AskUserQuestion for gating.

**State tracking**: Create the progress file before Step 1 and update it after each step completes. See State Management below for the format and rationale. Delete the file once the final output has been saved.

### Step 1: Select Audience

Present the audience options using AskUserQuestion:

- **Executive** — High-level, outcome-focused. Assumes no technical knowledge. Emphasises business value, risks, and decisions needed.
- **Client** — External-facing, professional. Focuses on what's being delivered and why it matters to them. Avoids internal process details.
- **Technical stakeholder** — Peers who understand technology but aren't in the code. Covers architecture, trade-offs, and technical decisions without implementation details.
- **Team onboarding** — New team members getting up to speed. Provides context, explains decisions, and maps the landscape.
- **Custom** — Let the user describe their audience. Ask follow-up questions to understand their knowledge level, what they care about, and what tone to use.

### Step 2: Select Format

Present the format options using AskUserQuestion. Not all formats suit all audiences — highlight which formats work best for the selected audience:

- **Summary memo** — Concise overview (1-2 pages). Best for executives and clients.
- **Status update** — Progress-focused. What's done, what's in progress, what's blocked. Best for stakeholders and team leads.
- **Presentation outline** — Slide-ready structure with key points per slide. Best for executives and clients.
- **Changelog** — What changed and why. Best for technical stakeholders and team onboarding.
- **Onboarding guide** — Comprehensive context document. Best for team onboarding.

### Step 3: Generate Derived Content

Read the selected source artifacts fully. Then generate content that is **derived from** the artifacts — transforming, summarising, and reframing their content for the selected audience and format.

**Derivation rules**:
- Every claim, number, status, and decision in the output must trace back to a source artifact. Only include information present in the sources.
- Adapt language and detail level for the audience. An executive summary omits technical specifics; an onboarding guide includes them.
- Adapt structure for the format. A presentation outline uses slide headings with bullet points; a changelog uses chronological entries.
- Reference source artifacts in the output metadata so the reader knows where to find detail.

Render the full draft in the message body. Then use AskUserQuestion as a short gate to capture the decision (e.g. "Approve this draft?" with options `Approve` / `Request changes` / `Stop`). Refine based on feedback. See the shared **Gate Presentation** convention.

### Step 4: Save Output

Follow the shared **Written Deliverable Length** convention — let the document's length match what the task needs, without padding, redundant summaries, or boilerplate sections.

Save the communication to `docs/communications/{nn}-{format}-{slug}.md`.

- `{nn}` is assigned by the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).
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
**Artifact**: {published URL — omit this field entirely when the communication has not been published}

---

{Derived content appropriate to audience and format}
```

The `**Source artifacts**` field enables regeneration — when source artifacts change, re-running `cpm:present` with the same sources and audience/format selections produces an updated output. The `**Artifact**` field, when present, is what lets a later session update the published page at its existing URL instead of minting a new one.

After saving, tell the user the document path.

An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.

For `present` the artifact is the communication itself in a form the recipient can open — the audience the content was reframed *for* is usually the audience without the repository, which is the whole reason this skill exists.

The Markdown above is the record of what was communicated: it stays committed and greppable, and publishing never replaces it. There is no local HTML copy — a second file carrying the same content earns nothing that the Markdown and the hosted page do not already cover between them.

Three `present`-specific particulars:

- The scratch fragment path is `docs/plans/present-artifact-{nn}-{format}-{slug}.html`. It stays out of `docs/communications/` deliberately — that directory's path contract describes complete documents, and a fragment is neither.
- The URL is recorded in the communication's own `**Artifact**` field (see the format above), in the progress file, and in the register the shared procedure requires. **`**Artifact**` *is* this skill's backlink** — the shared convention calls that field `**Artifacts**:`, but `present` had its own singular field for the same purpose first, and it holds the same URL for the same reason: so the relationship reads from both ends. Do **not** add a second `**Artifacts**:` field beside it. The near-identical names are a known collision; one URL, one field.
- **The prohibitions bite hardest here.** `present` writes client-facing and executive communications, which are the outputs most likely to carry an organisation's branding. Where a communication presents itself as issued by an organisation the user does not represent, keep it local and do not offer publishing. "Keep it local" means the Markdown alone — the absence of a local HTML option is not a reason to publish something that should not be published.

**When the Artifact tool is absent**, say so plainly. The Markdown is already written and is the deliverable of record, so nothing is lost — do not hard-fail, and do not write a local HTML file in its place.

**Regeneration**: If the user runs `cpm:present` and an existing communication already exists for the same source artifacts, audience, and format, offer to update it in place rather than creating a new file. Use AskUserQuestion to confirm. This covers two outputs: the Markdown, and the published artifact if one exists. For the artifact, "update in place" means republishing to the URL recorded in the `**Artifact**` field — passing that URL is what redeploys the existing page instead of minting a second one and leaving every link already shared pointing at a stale copy.

## Arguments

If `$ARGUMENTS` is provided, use it as the starting context. If it references file paths, read those as source artifacts. If it contains a description, use that to guide artifact discovery.

## State Management

Follow the shared **Progress File Management** procedure, writing to `docs/plans/.cpm-progress-{session_id}.md` — or `docs/plans/.cpm-progress.md` when `CPM_SESSION_ID` is not in context. `/cpm:clean`, the Stale-Progress Check and compaction recovery all locate the file by globbing that exact stem, so one named anything else is invisible to every reader it exists for.

**Lifecycle**:
- **Create**: before starting Step 1 (ensure `docs/plans/` exists).
- **Update**: after each step completes.
- **Delete**: only after the final communication has been saved and confirmed written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm:present
**Step**: {N} of 4 — {Step Name}
**Output target**: docs/communications/{nn}-{format}-{slug}.md
**Artifact URL**: {published URL, or "not published"}

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

- **Derive, always trace.** Every statement in the output must trace back to a source artifact. Only include content that maps to a specific source.
- **Transform, always reframe.** The value is in reframing — adapting language, structure, and detail level for the audience. A straight copy-paste of the source is not a transformation.
- **Audience dictates tone.** An executive summary is crisp and outcome-focused. An onboarding guide is thorough and explanatory. Let the audience drive every writing decision.
- **Format dictates structure.** A presentation outline needs slide headings. A changelog needs chronological entries. Follow the format's conventions.
- **Source traceability enables regeneration.** Always record which artifacts were used so the output can be updated when sources change.
- **Publishing is a separate decision from producing.** The Markdown is the artifact of record and stays inside the repository. Publishing puts the content on the open web under a URL the user can pass on, so it is confirmed on its own terms every time — and the URL is recorded, because an unrecorded one becomes a stale link the moment the communication is regenerated.
