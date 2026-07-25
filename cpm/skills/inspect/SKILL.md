---
name: inspect
description: Code, after execution — reviews a change set rather than a path. Resolves an epic, story, branch, commit range or working tree to the files it produced, joins requirement → plan → code → test provenance across pluggable adapters, reports orphan changes and unbacked claims, and produces `file:line` findings over a deterministic JSON record in `docs/inspect/`. Triggers on "/cpm:inspect".
---

# Change-Set Inspection

Review what a piece of work actually produced. `/cpm:inspect` takes a selector — an epic, a
branch, a commit range, the working tree — resolves it to a set of commits and files, works
out which requirement each file traces back to, and reviews that set. It reports the two
gaps a diff cannot show: **orphan changes** (files that changed with no acceptance criterion
behind them) and **unbacked claims** (criteria marked done or verified with no test naming
them).

## Where this sits

| Skill | Subject | When |
|-------|---------|------|
| `/cpm:review` | Plans — epic docs and stories | Before execution |
| `/cpm:inspect` | Code — the change set execution produced | After execution |
| `/cpm:audit` | Code — the whole codebase, by path or keyword | Any time |

`/cpm:review` and `/cpm:inspect` are close enough in name to be confused permanently, so
each one's `description` leads with its subject rather than its verb. They never read the
same thing: `review` reads plans and never opens the implementation; `inspect` reads the
implementation and uses the plans only as provenance.

`/cpm:audit` is a different tool with a different question. It orients on the whole
codebase, ranks six months of churn, and pins to `HEAD`. Ask it "how healthy is this
codebase"; ask `/cpm:inspect` "what did this epic do". This skill does not modify, wrap, or
supersede it.

**The target repository does not need to be a CPM project.** Every CPM-specific channel is
an adapter that reports what it can find and declines what it cannot. In a repository with
no `docs/epics/`, no coverage matrices and no commit trailers, the resolution still works
from git alone, every file is reported as an orphan, and the review still runs. That is the
expected degraded output, not a failure.

## Input

Parse `$ARGUMENTS` as a **selector**. R1 defines two families:

**Git-anchored** — resolved in reverse (files → commits → intent):

| Form | Meaning |
|------|---------|
| `--since <ref>` | Everything from `<ref>` to `HEAD` |
| `<ref>..<ref>` | A commit range |
| `<branch>` | A branch, from its fork point |
| `--working-tree` | Uncommitted changes |

**Intent-anchored** — resolved forward (intent → commits → files): a CPM epic or story
(`epic 41-03`, `story 41-03.2`), or a ticket or issue key that a registered adapter
understands.

If `$ARGUMENTS` is empty, use `--working-tree` and say so before proceeding — it is the
only form that inspects work not yet committed, and a reader should not have to infer that
from the output.

### Resolution order

Direction is decided by the selector's shape, in this order:

1. A `--` flag → git-anchored
2. A selector containing `..` → git-anchored
3. A single token naming an existing branch → git-anchored
4. Anything else → intent-anchored

Rule 3 is the only ambiguous case, and it resolves toward the branch: a branch either
exists in this repository or it does not, whereas "some adapter might understand this
string" cannot be checked without running every adapter. CPM ids contain a space and never
reach it.

The dispatch is `inspect_selector_direction` and `inspect_resolve` in
`cpm/hooks/lib/inspect-resolve.sh`. Do not reimplement the ordering in conversation — call
the function, so what the skill documents and what the tool does cannot drift.

### A selector that matches nothing is an error

R1's must-NOT: an empty change set is never reported as a clean one. The resolvers already
enforce this and echo the selector back. Report that message as-is and stop — do not fall
back to a wider selector, and do not proceed to the review with nothing in scope.

## Process

**State tracking**: Create the progress file once Step 1 has resolved, and update it after
each step. See State Management below for the lifecycle and format. Delete it once the
record has been written.

### Stale-Progress Check (Startup)

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions
loaded at session start).

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before the Library Check.

**Retro incorporation** (this skill):
- **Testing gaps**: Inform Step 4 — a past observation about what a suite failed to cover is
  a place to look when reading the change set's tests, and it is often the same gap R4
  surfaces from the other direction.
- **Codebase discoveries**: Inform Step 4 — surfaced conventions and limitations are treated
  as known context, so a finding reports a real problem rather than rediscovering a
  documented constraint.
- **Patterns worth reusing**: Inform Step 4 recommendations — when a past pattern is the
  answer to a finding, point at it directly rather than describing it again.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `inspect`. Deep-read
selectively when a library document bears on the change set in hand — coding standards
before reviewing implementation files, architecture docs before judging a structural change.

### Step 1: Run the pipeline

Everything except the findings is deterministic and runs in one call. Source the adapters
and the runner, then invoke it:

```sh
source cpm/hooks/lib/link-adapter-git.sh
source cpm/hooks/lib/link-adapter-cpm.sh
source cpm/hooks/lib/intent-adapter-cpm.sh
source cpm/hooks/lib/inspect-run.sh
inspect_run <repo> <work-dir> <budget> <selector>...
```

The first two run the reverse direction and the third the forward one; `inspect_run`
registers whichever it finds defined and skips the rest.

It resolves the selector, joins the provenance, answers both gap queries, chooses the
review's scope and order, builds the review's payload, and writes the JSON record — in that
order, failing at the first step that cannot proceed. It prints a manifest of
`KEY<TAB>value` lines naming the selector, the direction taken, which adapters ran, the
commit and file counts, and a path for each artifact it produced.

Read the manifest and report the selector, the direction, the counts and the adapters
before going further. A change set of an unexpected size is nearly always a selector that
means something other than what the user intended, and it is cheaper to say so now than
after a review of the wrong files.

The budget is the third argument and Step 4 explains how to choose it. The working
directory is scratch — the run's intermediates, not its output — so put it under the
session's scratchpad rather than in the repository, and do not offer it to the user as a
result. The only thing the run leaves in the repository is the record.

Steps 2, 3 and 5 below describe what the run did and what its output means — they are not
separate invocations. Step 4 is the part `inspect_run` deliberately does not do.

### Step 2: The join (`LINKSET`)

Two link adapters run, named by `INSPECT_LINK_ADAPTERS`:

- `gitnative` — commit trailers, conventional-commit scopes, branch names
- `cpm` — epic docs, `**Satisfies**` fields, coverage matrices, co-commit

The join labels every link **declared** (an explicit marker names the intent record) or
**derived** (inferred, principally from co-commit), and every file with no link at all is
**absent**.

An adapter whose file was never sourced is skipped rather than failing the run, and the
manifest's `ADAPTER` lines say which ones actually ran. That matters more than it sounds:
"no links found" and "no adapter looked" produce the same empty result, and the manifest is
the only place they can be told apart.

Registering neither is supported — the join produces every file as an orphan, which is R7's
zero-channel requirement and R9's degraded run.

**These two are link adapters — the reverse direction, files → intent.** They are separate
from the *intent* adapters that resolve an intent-anchored selector forward, which are named
by `INSPECT_INTENT_ADAPTERS` and reported on the manifest's `INTENT_ADAPTER` lines. One ships:
`cpm`, reading the epic document, its coverage matrix, and commit messages naming the id. It
answers `epic NN-MM` and `story NN-MM.K` and declines everything else — an issue key like
`AUTH-4` belongs to the issue-tracker adapters the spec defers.

### Step 3: The gap queries (`GAPS`)

Render the manifest's `GAPS` file with `gap_render`. It holds two answers:

- **Orphan changes (R3)** — files in the change set that no adapter links to any intent
  record. Any link at all disqualifies a file, however weakly it was inferred, so an orphan
  is a file nothing could account for rather than a file that was merely hard to place.
- **Unbacked claims (R4)** — intent records marked `done`, or criteria marked `verified`,
  with no test file naming them. This question is answerable only through an adapter that
  carries verification claims, and the report says which of *"none found"* and *"not
  answerable"* it means. They are not the same, and rendering them alike would turn a
  missing channel into a clean bill of health.

Orphans are not defects. Presented in spec 41's own chain they would have surfaced a README
repair and two presentation decks — real work, done for good reasons, outside any
criterion's letter. The report says what is unaccounted for; the judgement stays with the
reader.

### Step 4: Review the change set — the part that is yours

The run stops here. The manifest's `PAYLOAD` is what the review reads; its `SELECTION` is
the order to read in, which files fit the budget, and which do not.

The budget is `inspect_run`'s third argument: how many files can be read carefully in one
pass. It is a judgement about this run — the files' size, what else is already in context —
not a constant. Pick it deliberately and say what you picked. It has no default, and an
empty or non-numeric value is refused, because a missing limit is not an unlimited one.

**The review consumes the join's data, never its labels (AD3).** `review_payload` strips
every confidence label, and it is the only thing this skill reads the join through — do not
go around it to the raw link set. Do not reintroduce the labels in conversation either, by
describing a file as "only derived" or "declared, so probably fine" —
the labels describe how well the *join* knows something, which is not evidence about the
code. A criterion's `verified` state is not a confidence label and does survive: it is a
claim the plan makes about itself, and R4 rests on it.

Then read the selected files and produce findings. Each finding is
`review_emit_finding <path> <line> <text>` and must cite a `file:line` inside the change
set; `review_validate_findings` rejects anything else. Findings are about the code — its
correctness, its duplication, its structure — not about whether the plan was followed,
which is `/cpm:do`'s verification gate and already ran.

**If the change set did not fit the budget**, the `SELECTION` file marks itself incomplete
and lists what was skipped. Render it with `review_render_coverage` and name every file not
examined. A review that silently samples reads as "clean" when it means "unexamined", which
is worse than refusing.

**Then persist them.** Pipe the validated findings through
`inspect_findings_write <repo> <selector>`, which writes `docs/inspect/<slug>.findings.md`
beside the record and prints its path:

```sh
source cpm/hooks/lib/inspect-findings.sh
review_emit_finding ... | inspect_findings_write <repo> <selector>
```

They are a sidecar rather than a field in the record for the reason R6 gives: the record is
byte-identical across runs of the same selector, and findings are a reading of code that two
runs may legitimately differ on. Writing them in would make every record differ from every
other for reasons unconnected to the repository, and the run-to-run delta is what the record
exists to produce.

A review that found nothing still writes the file, saying so in words. An absent file means
the selector was never reviewed, and that is a different statement — the same distinction R4
draws between "none found" and "not answerable".

### Step 5: The record (`RECORD`)

The manifest's `RECORD` is `docs/inspect/<slug>.json`, written relative to the repository
root. It was written *last*, so a run that failed earlier left no record claiming to
describe it.

**The JSON is the record (R6, AD4).** It is deterministic — the same selector over the same
commits produces a byte-identical document, with no timestamp and no run id — so two runs
of the same selector diff against each other and the delta is the signal. One file per
selector, overwritten in place.

Tell the user the path and that the file is uncommitted. Committing it is theirs to do.

### Step 6: Report

Render, in this order: the selector and direction; the coverage line from
`review_render_coverage`; the findings from `review_render_findings`; the gap report from
`gap_render`; the record path.

Findings before gaps, because the findings are the review and the gaps are context for it.

## Publishing

An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.

For `/cpm:inspect` an artifact shows the provenance the run resolved: which files traced to
which requirement and how confidently, and which traced to nothing at all — the view that is
worth sending to someone who does not have the repository, and the one no diff can render.

Four things are specific to this skill.

**Compose from three sources, and no others.** Source `cpm/hooks/lib/inspect-project.sh`
and run `inspect_projection <json-file>` over the record Step 5 wrote; read the findings
sidecar Step 4 wrote; and quote source only at lines the findings actually cite. Nothing
else — not the change set, not files that drew no finding, not the raw link set.

The purpose is a page that stands in for reading the work, so that someone reviewing a chain
does not have to trawl diffs. A citation the reader has to go and open is trawling with
better signposting, which is why the excerpt is allowed. It is bounded by the findings
because an unbounded excerpt is a diff, and the spec is explicit that "rendering a diff is a
mirror and earns nothing".

The record and the projection remain source-free, and that boundary is asserted in
`test-inspect-artifact.sh`. What is relaxed here is only what the *page* may add on top of
the projection.

**Let the data choose the page's structure.** There is no template, and the organising axis
is not fixed: use intent records where adapters supplied them, ticket or issue ids where only
trailers exist, and where a repository carries neither, let the findings and the shape of the
tree organise it. AD1 requires this skill to work with no CPM artifacts present, so a page
built around epics would be richest exactly where provenance is already good and empty where
it is thinnest. Note that in a repository with no intent source R9 makes *every* file an
orphan, so the orphan list carries no signal there and the findings carry the page.

**Build to the path `inspect_artifact_path <slug>` gives**, which is
`docs/plans/inspect-artifact-<slug>.html`. It is a pure function of the selector, so every
publish of the same run builds to the same path and redeploys to the same artifact rather
than minting a second one. That holds within a session. Across sessions the path is not
enough — a session that did not itself publish mints a new URL unless the recorded one is
passed, so read it from `docs/inspect/<slug>.artifacts.md` and pass it.

**Record it at both ends as soon as the URL comes back.** A row in
`docs/artifacts/index.md` per the `cpm:artifact` register format — `inspect_register_row`
emits one in that file's column order — and the backlink via
`inspect_sidecar_write <repo> <slug> <url>`, which writes
`docs/inspect/<slug>.artifacts.md`.

The backlink is a sidecar rather than a field in the record, and this is the one place
`/cpm:inspect` departs from where the `**Artifacts**:` invariant usually puts it. R6 requires
the record to be byte-identical across runs of the same selector; a published URL is not,
so writing one in would make two runs differ for a reason that has nothing to do with the
work — and the diff between runs is what the record exists for. The sidecar keeps the
relationship readable from the source end without putting a disposable value inside the
durable one.

## Degradation

Every dependency below is optional, and each absence has a defined output rather than a
failure (R9). **Say which channel was missing.** Nothing in the output distinguishes an
adapter that found nothing from one that was never there, so an unreported degradation reads
as a clean result — and the whole point of R3 and R4 is to stop absence being mistaken for
health.

| Missing | Behaviour |
|---------|-----------|
| No CPM artifacts in the repository | The `cpm` adapter returns no links. Resolution, join, review and record all run; files it would have linked become orphans. |
| No commit trailers or conventional-commit subjects | The `gitnative` adapter returns no links. Same as above. |
| Both adapters find nothing | Every file is an orphan and the review still runs. This is R7's zero-channel requirement, and the output is correct rather than empty. |
| No registered intent adapter | Reachable by setting `INSPECT_INTENT_ADAPTERS` empty or not sourcing `intent-adapter-cpm.sh`. Intent-anchored selectors error with the selector echoed back: *"no adapter can answer this selector"*. Say plainly that no intent channel is registered, since the message reports that nothing answered and not why. Git-anchored selectors are unaffected — they never consult an intent adapter. |
| A selector no intent adapter recognises | The `cpm` adapter answers `epic NN-MM` and `story NN-MM.K` only, so an issue key or a ticket id is *declined* rather than answered empty, and resolution errors with the same "no adapter can answer this selector". Distinguish it from the row above when reporting: a channel is registered, and this selector is outside its vocabulary. |
| A CPM selector nothing in the repository names | The adapter answered, and found no commits. Resolution errors with *"selector matched no changes"* and the selector echoed back (R1's must-NOT). This is a real answer, not a missing channel — the epic or story has no commits here. |
| A link adapter's file was not sourced | It is skipped and the manifest omits it from `ADAPTER`. The run is otherwise unchanged; whatever that channel would have linked becomes an orphan. |
| `gap-queries.sh` not in scope | Cannot happen through `inspect_run`, which sources it. A caller composing the libraries by hand gets `review_select` falling back to a deterministic file order instead of orphans-first, and its `ORDER` line says which it took. |
| Not a git repository | Resolution fails. There is no degraded reading of a change set without a repository to take it from, so this one stops. |
| The Artifact tool is absent | Say so plainly and skip publishing. Steps 1–6 are unaffected and the record is still written — publishing is an offer made after the run, never a step the run depends on. Write no sidecar and no register row: both record a URL, and there is none. |

## Output

Two things: the report in conversation, and `docs/inspect/<slug>.json` on disk. The JSON is
the durable half — greppable, diffable, and the input to anything built over it later. The
conversation is the disposable half.

A published run adds two more, both recording the URL rather than the work:
`docs/inspect/<slug>.artifacts.md` and a row in `docs/artifacts/index.md`.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**: Create the file after Step 1 resolves — before that there is nothing worth
recovering, and the selector is the one thing a resumed run cannot re-derive. Update it
after each step. Delete it once `inspect_write` has confirmed the record, not before: the
JSON is the only durable output, and an early deletion loses the run if compaction fires
between the two.

**Format**:

```markdown
# CPM Progress

**Skill**: inspect
**Selector**: {the selector as given}
**Direction**: git | intent
**Change set**: {commit count} commits, {file count} files
**Step**: {1-6}

## Completed
- {step}: {what it produced}

## Findings so far
- {path}:{line} — {text}
```

Findings are carried in the progress file because they are the expensive half of the run —
resolution and the join are deterministic and cheap to redo, while a review pass that has
already read thirty files is not.

## Notes

- The resolution, join, gap queries, review scaffolding and record are shell libraries under
  `cpm/hooks/lib/`, each with its own test suite. They are deterministic and auditable on
  purpose: the provenance answer should not change because a model had a different day.
  The model's work is Step 4's findings, which is the part that genuinely needs judgement.
- A selector's *meaning* is the adapter's, not this skill's. `epic 41-03` means whatever the
  CPM adapter says it means and `AUTH-123` means whatever an issue-tracker adapter would
  say; both are passed on verbatim. The resolution order reads a selector's **shape** —
  whether it starts with `--`, contains `..`, or names a branch — and nothing beyond it.
  That is what keeps the deferred issue-tracker adapters cheap to add later.
- Version control stays with the user. The only lasting file this skill writes is the JSON
  record, and it commits nothing.

## Next Action

After the report, offer one of:

- `/cpm:quick` — for a finding small enough to fix directly
- `/cpm:spec` — when the findings describe work that needs planning
- `/cpm:retro` — when the run is the end of an epic chain and the gaps belong in the
  retrospective

Offer; do not run. Which of these is right depends on what the findings say, and that is
the user's read to make.
