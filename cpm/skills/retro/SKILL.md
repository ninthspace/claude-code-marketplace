---
name: retro
description: Lightweight retrospective. Reads a completed epic doc or quick record, synthesises observations, and writes a retro file for feed-forward into the next planning cycle. Promotes durable lessons into the reference library via "/cpm:retro learn" and retires spent lessons via "/cpm:retro retire". Triggers on "/cpm:retro".
---

# Lightweight Retrospective

Read a completed (or partially completed) epic doc, synthesise observations captured during task execution, and produce a retro file that feeds forward into the next planning cycle.

## Input

This skill operates on two source types: **epic docs** (`docs/epics/`) and **quick records** (`docs/quick/`). Both produce retro-eligible observations during execution; the retro skill consumes either kind.

This skill has four mutually exclusive modes, selected by `$ARGUMENTS`:

- **Synthesis** (the default) — read a completed source and *write* a retro file from its observations. This is everything documented below from **Process** onward.
- **Lesson promotion** (`learn`) — *promote* a durable lesson out of an existing retro into the reference library, then retire it at the source. This is a separate flow; see the **Lesson Promotion (`learn` action)** section below.
- **Lesson retirement** (`retire`) — *retire* a spent lesson at its source: mark it with a durable `**Retired**` marker so it stops resurfacing in Retro Awareness, without deleting it or losing the audit trail. Use this when a lesson is no longer true anywhere — the module it warned about is gone, the constraint no longer holds, the pattern was superseded. This is the deliberate, out-of-cycle home for retirement (`cpm:do`'s in-cycle Obsolete retire is the rare exception). See the **Lesson Retirement (`retire` action)** section below.
- **Triage** (`triage`) — *scan* the project's completed epics and *waive* the ones that don't warrant a retro (clean epics with no lessons to synthesise), so the board and `/cpm:status` stop nagging them as "retro pending". Writes a durable epic-level `**Retro waived**:` marker; never synthesises, promotes, or retires. See the **Triage (`triage` action)** section below.

The four never run together: synthesis produces a retro from execution observations; `learn` graduates an observation into permanent reference (and retires it as it goes); `retire` retires a spent observation outright; `triage` waives clean completed epics so they stop asking for a retro. Decide the mode first:

- **If `$ARGUMENTS` is exactly `learn`, or begins with `learn` followed by an optional retro path/filter** (e.g. `learn`, `learn docs/retros/04-retro-foo.md`), enter the **Lesson Promotion (`learn` action)** flow and ignore the synthesis steps. Any trailing text after `learn` is treated as an optional scope hint (a retro path or keyword) for candidate gathering, not as a synthesis source.
- **If `$ARGUMENTS` is exactly `retire`, or begins with `retire` followed by an optional retro path/filter** (e.g. `retire`, `retire docs/retros/04-retro-foo.md`), enter the **Lesson Retirement (`retire` action)** flow and ignore the synthesis steps. Any trailing text after `retire` is treated as an optional scope hint (a retro path or keyword) for candidate gathering, not as a synthesis source.
- **If `$ARGUMENTS` is exactly `triage`, or begins with `triage` followed by an optional path/filter** (e.g. `triage`, `triage docs/epics/01-01-epic-foo.md`), enter the **Triage (`triage` action)** flow and ignore the synthesis steps. Any trailing text after `triage` is an optional scope hint (an epic path or keyword) that narrows which completed epics are scanned, not a synthesis source.
- **Otherwise**, run synthesis. Check for input in this order:

1. If `$ARGUMENTS` references a file path, use it. Accept paths under `docs/epics/` (epic doc) or `docs/quick/` (quick record).
2. If no path given, look for the most recent file across **both** `docs/epics/*-epic-*.md` and `docs/quick/*-quick-*.md` (compare by filename prefix or modification time). Present the most recent candidate(s) to the user with AskUserQuestion to confirm.
3. If neither directory has matching files, tell the user there's nothing to retro and stop.

**Source detection**: Once the input is resolved, classify it by directory or filename pattern:
- **Epic source** (`docs/epics/...-epic-...md`): observations live in `**Retro**:` fields on completed stories and the optional `## Lessons` section. Steps 1-3 below apply as written.
- **Quick source** (`docs/quick/...-quick-...md`): observations live in the record's `## Retro` section (mandatory single-category observation). Steps 1-3 still apply, with adjustments noted inline.

## Process

**State tracking**: Create the progress file before Step 1 and update it after each step completes. See State Management below for the format and rationale. Delete the progress file once the final retro file has been saved.

### Stale-Progress Check (Startup)

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions loaded at session start).

### Template Hint (Startup)

Before Step 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm:templates preview retro` to see the format.

### Step 1: Read Source Document

Read the resolved source document with the Read tool.

**For epic sources** (`docs/epics/`), identify:
- Total number of stories and their statuses (Pending, In Progress, Complete)
- Any `**Retro**:` fields on completed stories (these are per-story observations captured by `cpm:do` Step 6, Part B — mandatory on verification gates)
- Any `## Lessons` section already present (batch summary from `cpm:do` Step 8)
- The overall completion state of the batch

**For quick sources** (`docs/quick/`), identify:
- The change description, classification (`fix` or `change`), and verification summary
- The `## Retro` section's observation — a single category and one-sentence observation per the format defined by `cpm:quick`
- Whether the change shipped successfully (record promoted to completion record per `cpm:quick` Step 4)

Present a brief summary to the user — for epic sources: story counts, completion, observation count. For quick sources: change classification, observation category, outcome.

### Step 2: Synthesise Observations

Gather the observations from the source resolved in Step 1, then hand them to the shared **Retro Synthesis** procedure (in the CPM Shared Skill Conventions). Source-gathering is this skill's responsibility; the grouping, synthesis, and retro-file format live in the shared procedure, so that `cpm:do` and `cpm:retro` produce identical retro files from the same inputs — there is one synthesis implementation, not two.

**Gather the observations** into the shared procedure's input shape — a list of per-story observations, each with a category and a one-sentence note:

**For epic sources**:
- **If `**Retro**:` fields exist**, each field is one observation — its `[category]` is the category and the text is the note. The seven categories are: smooth deliveries, scope surprises, criteria gaps, complexity underestimates, codebase discoveries, testing gaps, patterns worth reusing.
- **If a `## Lessons` section exists but no `**Retro**:` fields** (e.g. fields were lost during editing, or an older `cpm:do` run synthesised them away), use the `## Lessons` section as the observation source — it contains the same observations in pre-grouped form.
- **If both exist**, use the `**Retro**:` fields as the primary observations (they are the raw input) and count each only once, even when it also appears in `## Lessons`.
- **If neither exists**, pass no observations — the shared procedure's status-only fallback produces a Batch Outcome summary from story statuses alone.

**For quick sources**: pass a single observation — the declared category and one-sentence note from the record's `## Retro` section.

**Then follow the shared Retro Synthesis procedure**, passing the gathered observations, the source's story outcomes (story counts and any blocked/stuck stories identified in Step 1), and the source artefact path. The procedure groups by category, writes a brief synthesis per category (or the Batch Outcome fallback), and proceeds to the file write in Step 3.

### Step 3: Write Retro File

The shared **Retro Synthesis** procedure (invoked in Step 2) performs the write: it assigns `{nn}` via the shared **Numbering** procedure, derives `{slug}` from the source artefact name (e.g. epic doc `01-epic-auth.md` produces retro slug `auth`), creates `docs/retros/` if it doesn't exist, and writes the retro file to `docs/retros/{nn}-retro-{slug}.md` in the shared retro-file format.

Tell the user the retro file path after saving.

### Step 3.5: Library Write-Back

After writing the retro file, check if any retro observations should be fed back into library documents. This step closes the loop: `library → ... → retro → library`.

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip this step silently and proceed to Step 4.

2. **Read front-matter** of each library document using the Read tool. Read each file individually with the Read tool directly (Bash loops with shell variables lose context). Filter to documents whose `scope` array includes `do` or `all` — these are the documents that guided task execution and are most likely to benefit from retro observations.

3. **Match observations to library documents**: For each retro observation (from the `**Retro**:` fields collected in Step 1), assess whether it's relevant to any library document. Use the observation category and content to match:
   - **Codebase discoveries** → likely relevant to architecture or coding standards docs
   - **Complexity underestimates** → may indicate missing constraints in architecture docs
   - **Criteria gaps** → may indicate missing rules in coding standards or business rules docs
   - **Scope surprises** → less commonly relevant to library docs, but flag if they reveal missing architectural context
   - **Testing gaps** → may indicate missing testing conventions in library docs or gaps in test infrastructure documentation

4. **Propose amendments**: For each matched observation, draft an amendment block:

   ```markdown
   ## Amendment — {YYYY-MM-DD} (via retro)

   **Source**: {path to retro file just written}
   **Category**: {observation category}

   {Observation text — what was learned and what should change}
   ```

5. **User approval gate**: Present all proposed amendments to the user, grouped by target library document. Use AskUserQuestion:
   - **Apply all amendments** — Write all proposed amendments
   - **Review individually** — Walk through each amendment one at a time
   - **Skip write-back** — Leave all library documents unchanged

6. **Write amendments**: For each approved amendment, use the Edit tool to:
   - Append the `## Amendment` block to the end of the library document
   - Update the `last-reviewed` date in the document's front-matter to today's date

**Graceful degradation**:
- If no library directory exists, skip silently.
- If no observations match any library documents, skip silently — only amend when there is a genuine match.
- If no `**Retro**:` fields were captured (status-only retro), skip this step entirely.
- The retro workflow always continues past write-back failures.

### Step 4: Pipeline Handoff

After presenting the retro file path, offer the user options for what to do next.

**Pivot suggestion check**: Before presenting the handoff options, scan the synthesised observations for scope-affecting categories — **criteria gaps**, **scope surprises**, and **codebase discoveries** that imply the source spec or epic missed something material. If any such observation is present, surface a pivot offer alongside the regular handoff options.

Use AskUserQuestion:

- **Continue to /cpm:pivot** *(only when scope-affecting observations exist)* — Use the retro to amend the source spec/epic. Pass the source artefact path (from the retro's `**Source**:` field) as `$ARGUMENTS` to `/cpm:pivot`.
- **Continue to /cpm:discover** — Use the retro as starting context for problem discovery.
- **Continue to /cpm:spec** — Use the retro as starting context for requirements specification.
- **Continue to /cpm:epics** — Use the retro as starting context for work breakdown.
- **Just exit** — End the session, no handoff.

If the user chooses a pipeline skill, pass the retro file path (or source artefact path for pivot) as the input context for that skill.

Delete the progress file after handoff or exit.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Step 1 (ensure `docs/plans/` exists).
- **Update**: after each step completes.
- **Delete**: only after the final retro file has been saved and confirmed written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm:retro
**Step**: {N} of 4 — {Step Name}
**Output target**: docs/retros/{nn}-retro-{slug}.md
**Input source**: {path to epic doc}

## Completed Steps

### Step 1: Read Epic Doc
{Summary — story count, completion status, observation count}

### Step 2: Synthesise Observations
{Summary — categories found, key patterns identified}

### Step 3: Write Retro File
{Summary — file path written, recommendation count}

{...include only completed steps...}

## Next Action
{What to do next}
```

## Lesson Promotion (`learn` action)

`/cpm:retro learn` graduates a **durable** retro lesson — one that keeps proving true across runs — into the permanent reference library at `docs/library/lessons-learned.md`, then retires it at the source so it stops resurfacing in Retro Awareness while persisting durably for Library Check. Retros are transient feed-forward; a lesson that has earned its keep belongs in the library, not in the retro layer where it must be re-judged every run.

This flow is **manual** (a human chooses what to promote), **mutually exclusive** with synthesis (it never writes or reads a retro *as a synthesis source*), and runs only when `$ARGUMENTS` selects it (see **Input**). It proceeds in two steps: select a candidate lesson, then promote-and-retire it as one atomic operation.

### Step L1: Gather and Select Candidates

1. **Find the retros.** Glob `docs/retros/[0-9]*-retro-*.md`. If none exist or the directory is absent, tell the user there are no lessons to promote and stop.
2. **Collect candidate observations.** Read each retro and gather its observations — the bullets under the category headings (Smooth Deliveries, Scope Surprises, Criteria Gaps, Complexity Underestimates, Codebase Discoveries, Testing Gaps, Patterns Worth Reusing). For each, retain its source retro path, its category, and the observation text.
3. **Exclude already-retired lessons (offer-side idempotency).** Skip any observation carrying a `**Retired` marker — per the shared **Retro Retirement** convention, a retired observation has already been dismissed or promoted, so it must **never** be offered as a candidate. This is what stops a promoted lesson being promoted twice.
4. **Apply the optional scope hint.** If `$ARGUMENTS` carried text after `learn` (a retro path or keyword), narrow the candidate set accordingly — a path restricts to that retro; a keyword filters to observations whose text or source matches. With no hint, offer all non-retired observations.
5. **Present candidates, grouped.** Show the candidates grouped by source retro and category, each line giving the observation text plus its source retro filename and category so the user can see provenance before choosing. Use AskUserQuestion (or a numbered list the user picks from) and **support selecting more than one** lesson in a single invocation. If no candidates remain after filtering, tell the user there is nothing to promote and stop.
6. **Preview before any write.** For each selected lesson, render a confirmation preview showing both halves of what Step L2 will do as one operation: (a) the proposed library entry — its title, the **derived `scope`** (computed via the auto-scope rules referenced in Step L2), the summary, and the provenance line; and (b) the **retirement** that will follow — the `**Retired {YYYY-MM-DD}**: promoted to docs/library/lessons-learned.md` marker that will be written back to the source observation. Confirm with the user. **No file is written until this preview is confirmed** — proceed to Step L2 only on confirmation.

### Step L2: Promote and Retire (atomic)

For each lesson confirmed in Step L1, perform the promotion **and** retirement as one atomic operation. The two are inseparable — a lesson lives in exactly one place (see the **Promotion is graduation** guideline). Repeat the whole step per selected lesson when multiple were chosen.

**Write the library entry**:

1. **Derive the entry's `scope`.** Apply `cpm:library`'s **Auto-Scope Suggestion** heuristics (in the `cpm:library` SKILL) to the lesson's content — do **not** reimplement them here. The retro category is a useful hint (e.g. a *Testing Gaps* lesson likely scopes to `do`), but the content drives the result.
2. **Create or append to `docs/library/lessons-learned.md`.**
   - **First promotion (file absent)**: create it with a single file-level front-matter block conforming to `cpm:library`'s **Generate Front-Matter** six-field model (`title` / `source` / `added` / `last-reviewed` / `scope` / `summary`) — again, follow that section rather than restating the rules. Use `title: Promoted Retro Lessons`; `source: docs/retros/ (promoted via /cpm:retro learn)`; `added` and `last-reviewed` both today; `scope` the derived scope; a `summary` noting these are durable lessons promoted from retros.
   - **Subsequent promotions (file present)**: **append** a new `##` entry — **never overwrite or rewrite existing content**. Update the file-level front-matter in place: set `scope` to the **union** of the existing scope and the new entry's derived scope, and bump `last-reviewed` to today (`added` is unchanged).
3. **Write the entry** as a `##` section with library-side provenance:

   ```markdown
   ## {Lesson title}
   **Promoted**: {YYYY-MM-DD}
   **Source**: docs/retros/{nn}-retro-{slug}.md → {Category} → "{verbatim observation text}"
   **Scope**: {scope derived for this lesson}

   {The lesson, written as durable standalone guidance.}
   ```

   The `**Source**` line is the library→retro half of the provenance trail and the key used by the idempotency guard below.

**Retire at the source (same operation)**:

4. Immediately after the library entry is written, retire the source observation in its retro per the shared **Retro Retirement** convention: append `**Retired {YYYY-MM-DD}**: promoted to docs/library/lessons-learned.md` to that observation's bullet, in place. This is the retro→library half of the provenance trail, and it is what makes the shared **Retro Awareness** selection skip the lesson from now on (so it lives only in the library).
5. **Ordering rule — promotion is atomic, library-first.** Write the library entry (steps 1–3) *before* the retirement marker (step 4). If the library write fails, do **not** write the retirement marker — never leave a lesson retired-but-not-promoted, and never report success on a half-done promotion. The pair succeeds together or not at all.

**Idempotency (write side)**:

6. Before appending an entry, check `docs/library/lessons-learned.md` for an existing entry whose `**Source**` line matches the lesson being promoted. If one exists, the lesson is already promoted — **no-op**: do not write a duplicate entry and do not re-retire. Report it as already promoted. (Offer-side idempotency is handled earlier in Step L1, which never offers a `**Retired`-marked observation; this guard is the belt-and-braces for the rare case where the same lesson reaches L2 twice.)

Report each promoted lesson with both its library entry location and the retirement applied to its source retro.

## Lesson Retirement (`retire` action)

`/cpm:retro retire` marks a **spent** retro lesson — one whose usefulness has permanently passed — with a durable `**Retired**` marker at its source, so it stops resurfacing in Retro Awareness while staying in place as a visible, reversible audit record. This is retirement's deliberate, out-of-cycle home: unlike `cpm:do`'s in-cycle Obsolete retire (reserved for the rare can't-miss case mid-run), `retire` is the review pass you run when you sit down to prune the retro corpus.

It differs from `learn` only in terminus: `learn` retires a lesson *because it graduated to the library*; `retire` retires a lesson *because it is spent*. Both write the same `**Retired**` marker via the shared **Retro Retirement** convention; neither deletes the observation. This flow is **manual** (a human chooses what to retire), **mutually exclusive** with synthesis and `learn`, and runs only when `$ARGUMENTS` selects it (see **Input**). It proceeds in two steps: select candidates, then retire them.

### Step R1: Gather and Select Candidates

1. **Find the retros.** Glob `docs/retros/[0-9]*-retro-*.md`. If none exist or the directory is absent, tell the user there are no lessons to retire and stop.
2. **Collect candidate observations.** Read each retro and gather its observations — the bullets under the category headings (Smooth Deliveries, Scope Surprises, Criteria Gaps, Complexity Underestimates, Codebase Discoveries, Testing Gaps, Patterns Worth Reusing). For each, retain its source retro path, its category, and the observation text.
3. **Exclude already-retired lessons.** Skip any observation carrying a `**Retired` marker — per the shared **Retro Retirement** convention, a retired observation has already been dismissed or promoted, so it must **never** be offered as a candidate.
4. **Apply the optional scope hint.** If `$ARGUMENTS` carried text after `retire` (a retro path or keyword), narrow the candidate set accordingly — a path restricts to that retro; a keyword filters to observations whose text or source matches. With no hint, offer all non-retired observations.
5. **Present candidates, grouped.** Show the candidates grouped by source retro and category, each line giving the observation text plus its source retro filename and category so the user can see provenance before choosing. Use AskUserQuestion (or a numbered list the user picks from) and **support selecting more than one** lesson in a single invocation. If no candidates remain after filtering, tell the user there is nothing to retire and stop.
6. **Capture a reason and preview before any write.** For each selected lesson, ask the user for a one-line **reason** the lesson is spent (what changed so it no longer holds), then render a confirmation preview showing the exact retirement that will follow: the `**Retired {YYYY-MM-DD}**: {reason}` marker appended to the source observation's bullet, named by source retro and category. Confirm with the user. **No file is written until this preview is confirmed** — proceed to Step R2 only on confirmation.

### Step R2: Retire at the Source

For each lesson confirmed in Step R1, retire the source observation in its retro per the shared **Retro Retirement** convention: append `**Retired {YYYY-MM-DD}**: {reason}` to that observation's bullet, **in place** under its existing category heading, using the reason captured in Step R1. The bullet is not moved or deleted — retirement is reversible by removing the marker. This is what makes the shared **Retro Awareness** selection skip the lesson from now on.

**Idempotency**: if a selected observation already carries a `**Retired` marker, it is a no-op — do not append a second marker. (Step R1 already excludes retired observations from candidates; this is the belt-and-braces guard.)

Report each retired lesson with its source retro location and the marker applied.

## Triage (`triage` action)

`/cpm:retro triage` sweeps the project's **completed** epics and, with confirmation, **waives** the ones that finished clean — epics with nothing worth reflecting on. A retro is not mandatory in CPM: `cpm:do` deliberately skips end-of-epic retro generation for a clean epic (no retro-trigger signal fired), yet the board and `/cpm:status` keep flagging every retro-less completed epic as "retro pending". Triage is how you clear that nag honestly — it records a durable epic-level `**Retro waived**:` marker that the board, `/cpm:status`, and the status-model contract treat as retro-satisfied.

This flow **never synthesises, promotes, or retires** — it only waives clean epics and *reports* the ones that still merit attention. It is **mutually exclusive** with the other modes and runs only when `$ARGUMENTS` selects it (see **Input**). It proceeds in two steps: scan and classify, then confirm and waive.

### Step T1: Scan and Classify

1. **Find completed epics.** Glob `docs/epics/[0-9]*-epic-*.md` (exclude `-coverage-` files). If a scope hint was passed after `triage`, narrow to matching epics. Read each and consider only those whose **epic-level `**Status**:` reads Complete/Done** (by its leading token — see `cpm/shared/status-model.md`, *Status parsing*). **Skip** epics that are Pending / In Progress (not finished) and retired `Superseded` / `Withdrawn` epics (those never nag a retro anyway).
2. **Classify each completed epic** using only durable, persistent signals (the ephemeral `cpm:do` retro-trigger flags are gone once an epic finishes):
   - **Already settled — skip silently**: the epic already carries a `**Retro waived**:` marker, **or** a standalone `docs/retros/` retro references it (its filename appears in a retro's text). Nothing to do.
   - **Waivable (clean)**: no matching `docs/retros/` retro **and** no substantive inline observations — i.e. it has zero story-level `**Retro**:` fields, or only `[Smooth delivery]`-category ones, and carries no `**Inline change**` breadcrumbs.
   - **Has observations — report, don't waive**: no retro yet, but the epic carries substantive inline `**Retro**:` observations (any category other than `[Smooth delivery]`). These hold real lessons; recommend `/cpm:retro <epic>` to synthesise them rather than waiving them away.
3. **Present the findings.** Show two lists: the **waivable** epics (each with the one-line reason it reads clean — e.g. "no retro, no observations" or "only Smooth-delivery notes"), and, separately and informationally, the **has-observations** epics as "consider `/cpm:retro <epic>`". If there are no waivable candidates, say so and stop (still surface the has-observations list if any).

### Step T2: Confirm and Waive

1. **Confirm before any write.** Present the waivable candidates via `AskUserQuestion` (or a numbered list) and **support per-epic opt-out** — the user may waive all, some, or none. Never waive without confirmation; never waive a has-observations epic.
2. **Write the marker.** For each confirmed epic, use the Edit tool to insert a `**Retro waived**: {YYYY-MM-DD} — clean epic, no lessons to synthesise` line **immediately after the epic-level `**Status**:` line** (in the epic header block, before the first `##` story). This is a distinct field from the story-level `**Retro**:` observations — do not confuse or merge the two.
3. **Idempotency.** If a `**Retro waived**:` marker already exists on the epic, it is a no-op — never write a second (Step T1 already skips settled epics; this is the belt-and-braces guard).
4. **Report.** List each epic waived (with the marker date) and, separately, restate the has-observations epics left for `/cpm:retro`. Waiving is reversible — deleting the marker line restores the nudge.

## Guidelines

- **Signal over noise.** A retro with 2 sharp observations is better than one with 10 vague ones. Synthesise into patterns, not just reformatted lists.
- **Actionable recommendations.** Every recommendation should be something concrete that changes how the next cycle is planned or executed.
- **Works without observations.** If no `**Retro**:` fields were captured, still produce a useful retro from story status — what completed, what didn't, what that implies.
- **Scannable.** The entire retro file should be digestible in under a minute. Use bullet points and short paragraphs.
- **Promotion is graduation, not duplication.** `learn` always retires what it promotes (Step L2) — a lesson lives in exactly one place: the retro layer until it proves durable, then the library. Never leave a promoted lesson active in both.
- **Retirement is deliberate and reversible.** `retire` (and `cpm:do`'s gated in-cycle Obsolete) only *append* a `**Retired**` marker — the observation stays in place and un-retires by deleting the marker. Retirement means the lesson is no longer true *anywhere*; it is never the right response to "this lesson doesn't apply to the work in front of me" — that is `cpm:do`'s per-run **Not relevant here**, which leaves the source untouched. Prefer this deliberate `retire` pass over the in-cycle path for anything that isn't a can't-miss, just-superseded case.
