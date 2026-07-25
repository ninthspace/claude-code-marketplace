---
name: artifact
description: Register and track published Claude artifacts against the CPM work that produced them. Maintains docs/artifacts/index.md — URL, what it is, why it was made, and which planning documents it belongs to — plus backlinks in those documents, so an artifact can be found, reviewed, and amended later without digging through chat history. Triggers on "/cpm:artifact".
---

# Artifact Register

Published artifacts are hosted web pages whose only handle is a URL. Unregistered, that URL exists solely in the transcript of the session that made it — which is why an artifact produced three weeks ago is effectively lost even though the page is still live.

This skill keeps a durable, in-repo record of every artifact produced alongside the project's CPM work: **what it is, why it was made, and what it is associated with**. That record is what makes an artifact findable later, so it can be picked up, reviewed, or amended rather than rebuilt.

The register is a plain Markdown file — `docs/artifacts/index.md` — so it is greppable, diffable, reviewable, and travels with the repo.

**This skill is stateless**: it creates no progress file. Every action is a single bounded read-and-write.

## Input

Parse `$ARGUMENTS`:

- **No arguments** — run the **review flow**: show the register, and offer to add, amend, or retire entries.
- **Contains a URL** — run the **register flow** for that URL. Any text alongside it is taken as the description and association hint (e.g. `/cpm:artifact https://… auth flow explorer for the client review, from spec 12`).
- **Begins with `list`** — print the register and stop. Read-only.
- **Anything else** — treat it as a search term and show matching entries (matched against name, why, and association), so `/cpm:artifact auth` finds the auth-related artifacts.

## Process

### Step 1: Read the register

Read `docs/artifacts/index.md` if it exists. If it does not, this is the first registration — create the directory and seed the file with the header from **Register format** below. Do not create the file merely to display an empty register; report "No artifacts registered yet" instead.

### Step 2: Establish the four facts

Every entry records four things. Never invent any of them — ask.

1. **URL** — the artifact's address. Required; without it there is no entry to make.
2. **Name** — what it is, in a few words. Default to the artifact's own title when it can be read; confirm rather than assume.
3. **Why** — one sentence on why it was made and who it was for. This is the field that makes an entry worth having: a URL and a date do not tell you, six weeks later, whether a page is worth reopening.
4. **Associated with** — the CPM document(s) it belongs to, as repo-relative paths. Use `—` when an artifact genuinely stands alone; do not force an association that is not real.

When registering, offer to read the artifact so the name and a description can be proposed rather than typed. Confirm what is proposed before writing it — a page's own title is often not how its author would describe it.

For the association, **Glob** the CPM artifact directories and offer the plausible candidates rather than asking for a path to be typed:

- `docs/specifications/[0-9]*-spec-*.md`, `docs/briefs/[0-9]*-brief-*.md`, `docs/plans/[0-9]*-plan-*.md`
- `docs/architecture/[0-9]*-adr-*.md`, `docs/epics/[0-9]*-epic-*.md`
- `docs/reviews/[0-9]*-review-*.md`, `docs/retros/[0-9]*-retro-*.md`
- `docs/communications/[0-9]*-*.md`, `docs/audits/[0-9]*-audit-*.md`

Multi-select — an artifact drawing on several epics names all of them.

### Step 3: Write the entry

Append a row to `docs/artifacts/index.md`, newest first (immediately under the table header). Use the Edit tool. Never rewrite rows other than the one being changed.

**Re-registering a URL already in the register** updates that row in place rather than adding a second one — the register holds one row per artifact, keyed by URL.

### Step 4: Write the backlink

For each associated document, add or extend an `**Artifacts**:` field in its top-level metadata block, so the relationship is discoverable from either end:

```markdown
**Artifacts**: [Auth flow explorer](https://claude.ai/code/artifact/…)
```

Where the field already exists, append to it. This is the reverse of the register's "Associated with" column: the register answers *"what have we produced?"*, the backlink answers *"what came out of this spec?"*. Both directions matter, and each is cheap.

If a named document cannot be found, say so and still write the register row — a missing backlink is a smaller loss than a lost URL.

### Step 5: Report

Show the entry as written and the paths touched. Where the register was created for the first time, say so — it is a new tracked file the user will want to commit.

## Register format

`docs/artifacts/index.md`:

```markdown
# Artifact Register

Published artifacts produced alongside this project's CPM work. Newest first.
Maintained by `/cpm:artifact` — see the associated documents for the work each one came from.

| Artifact | URL | Registered | Associated with | Why |
|---|---|---|---|---|
| Auth flow explorer | https://claude.ai/code/artifact/… | 2026-07-25 | `docs/specifications/12-spec-auth.md` | Interactive walkthrough of the token-refresh path, built for the client review |
```

- **Registered** is the date the entry was made, not necessarily the date the artifact was published — say so if they differ and it matters.
- **Associated with** holds repo-relative paths in backticks, comma-separated, or `—` for a standalone artifact.
- **Why** is one sentence. Where an artifact needs more explanation than that, link the document that carries it rather than growing the cell.

### Retiring an entry

An artifact that has been superseded or deleted is **struck through, not removed** — `~~Auth flow explorer~~` with the reason appended to **Why**. A register that silently drops entries cannot answer "what happened to that page?", which is one of the questions it exists to answer.

## Guidelines

- **The register is written when the artifact is made, not later.** Anything relying on a memory of the URL has already failed — that is the problem this skill exists to solve. Skills that publish artifacts register them as part of publishing.
- **Four facts or it is not worth writing.** A bare URL is what the transcript already had. Name, why, and association are the entry's value.
- **One row per artifact, keyed by URL.** Re-registering updates in place; the register never accumulates duplicates of the same page.
- **Never invent an association.** A standalone artifact records `—`. A forced link to a loosely-related spec is worse than none, because it sends a future reader to the wrong document.
- **Both directions, always.** The register lists what was produced; the backlink in each associated document shows what that work produced. Neither substitutes for the other.
- **The register is a record, not a lifecycle.** This skill does not publish, update, or delete artifacts themselves — it records where they are and what they were for.
