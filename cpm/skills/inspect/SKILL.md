---
name: inspect
description: Code, after execution — presents what a change set actually did and where it sits in the repository. Resolves a commit range, branch or working tree, works out the axis that best explains the change, situates it against what was already there and what was deliberately left alone, joins it to whatever records intent, and publishes the analysis as an artifact. Triggers on "/cpm:inspect".
---

# Change-Set Inspection

`/cpm:inspect` answers one question: **what did this work actually do, and where does it sit?**

Not "is this code any good" — that is `/cpm:audit`, and it is a different question over a
different scope. Not "does this plan hold up" — that is `/cpm:review`, and it runs before
execution rather than after. This skill takes a change set and produces the account a
colleague would want if they had to understand the work without opening the repository.

## Where this sits

| Skill | Question | When |
|-------|----------|------|
| `/cpm:review` | Do these plans hold up? | Before execution |
| `/cpm:inspect` | What did this change do, and where does it sit? | After execution |
| `/cpm:audit` | How healthy is this codebase? | Any time |

`/cpm:review` and `/cpm:inspect` are close enough in name to be confused permanently, so
each one's `description` leads with its subject rather than its verb.

The line against `/cpm:audit` is the one worth holding. Findings about code quality are
`audit`'s output, and a change-set analysis that drifts into them stops answering its own
question. If the work under inspection has quality problems worth raising, name them in a
sentence and point at `/cpm:audit` — do not turn the page into a review.

**The target repository does not need to be a CPM project.** Everything below degrades to
whatever the repository actually has, and says which channel it fell back to.

## Input

Parse `$ARGUMENTS` as a selector: a commit, tag, branch, range, `--since <ref>`,
`--working-tree`, or a phrase like "3 days ago".

**If it is absent**, work out a sensible baseline — the last release tag, the last merge to
the default branch — and **state which you chose and why** before going further.

**Always include uncommitted working-tree changes, and always report them separately from
committed ones.** Whether work has landed is a fact about the change set, not a footnote.

### Resolving it

Selector resolution is deterministic and fiddly enough to be worth a library rather than a
judgement — fork points in particular have a right answer that is easy to get plausibly
wrong. Source it and call it:

```sh
source cpm/hooks/lib/changeset.sh
source cpm/hooks/lib/changeset-resolve.sh
changeset_resolve_git <repo> <selector>...
```

It emits `COMMIT<TAB><sha>` and `FILE<TAB><path>` records, handles `--since <ref>`,
`<A>..<B>`, a branch name (measured from its actual fork point) and `--working-tree`, and
**errors with the selector echoed back rather than returning an empty change set**. Report
that message as-is and stop; do not widen the selector to find something to talk about.

For anything the library does not cover — a date phrase, a tag, a derived baseline — resolve
it with git directly and say what you resolved it to.

## Process

**State tracking**: Create the progress file once the selector has resolved, and update it
as each section is settled. See State Management below.

### Stale-Progress Check (Startup)

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions
loaded at session start).

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before the Library Check.

**Retro incorporation** (this skill):
- **Codebase discoveries**: a past observation about a convention or a constraint is context
  for Section 2 — it often explains why something sits where it does, and saves reporting a
  deliberate arrangement as an oddity.
- **Testing gaps**: inform Section 4 — a suite's known blind spot is worth naming when
  reporting what the change set's own tests do and do not reach.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `inspect`. Deep-read
selectively when a document bears on the change set in hand — an architecture document
before judging where a change sits, coding standards before calling something a deviation.

### 1. Derive the axis before you use it

The organising question is which changes are **static** and which are **dynamic** — but that
distinction is domain-relative, and you must define it for **this** repository before
classifying anything. Read enough of the codebase to work out what the split actually is
here. Depending on the stack it may mean:

- deterministic code vs. model-driven prose or configuration
- build-time, compile-time or generated vs. run-time
- static assets and pre-rendered output vs. dynamically served or hydrated
- schema, migrations, config and DI wiring vs. request-path behaviour
- statically analysable surface vs. reflection, magic methods, dynamic dispatch, runtime
  registration
- server-rendered vs. client-interactive
- vendored or generated vs. hand-authored

**State the definition you chose in one or two sentences, and say what in the repository made
it the right one.** If more than one reading is defensible, pick the one that explains the
most of *this* change set and name the runner-up.

If the repository has no meaningful static/dynamic split, **say so plainly and propose the
axis that does explain the change set instead**. Do not force the frame — a forced axis
produces a page that describes the frame rather than the work.

Then classify every changed component. **Components sitting on the boundary — especially
ones that are one tier guarding the other — are usually the most interesting thing in the
change set.** Call them out rather than rounding them to a side.

### 2. Situate the changes in the repository

Answer with figures you actually measured:

- **Proportion** — how large is each touched area relative to what was already there?
  *"This directory held 2 files and now holds 17"* is worth more than any diffstat.
- **Layering** — where do the changes sit: entry points, domain, infrastructure, tests,
  build, docs? Does the change set introduce a new layer, thicken an existing one, or cut
  across all of them?
- **Negative space** — what sits immediately adjacent and was **not** touched, and is that
  deliberate or an omission? Unchanged config, unchanged public API, unchanged shared or
  global files, unchanged sibling modules. **This is often the highest-signal part of the
  analysis** — a file that everything pays a cost for and that this work avoided touching is
  a finding in its own right.
- **Naming vs. reality** — does anything now live somewhere whose name no longer describes
  what it is?

### 3. Join the changes to whatever records intent

Use whatever is present, in this order of preference.

**If CPM artifacts exist** — `docs/specifications/`, `docs/epics/` with paired
`*-coverage-*.md` matrices, `docs/retros/`, `docs/quick/`, `docs/briefs/`,
`docs/artifacts/index.md`, `**Satisfies**` fields, or a `cpm/` plugin tree — read them and
map the change set onto that chain: which spec requirement, which epic and story, which
coverage rows, which retro. Note requirements with no code behind them, code with no
requirement behind it, and coverage rows marked verified with no test naming them. Note
where the documented pipeline has gaps — a completed epic with no retro, for instance.

**Otherwise** fall back through whatever the repository does have: ADRs or decision records,
RFCs, design docs, CHANGELOG, README, issue references, commit trailers,
conventional-commit scopes, branch names.

**If nothing records intent, say so and move on.** Absence of a planning record is a finding
to report, never a reason to fail or to invent one.

Beware the signal that cannot discriminate. If every file in the change set traces to the
same record — one squashed commit carrying a whole epic chain, say — then that mapping tells
a reader nothing about any individual file, and reporting it as provenance overstates it.
Say that it is uniform and why.

### 4. Verify before you assert

If the repository has tests, a linter, a type checker or a build, **run what is cheap and
relevant and report what you actually observed**. Never describe a suite as passing without
running it. If you could not run something, say which and why.

**Distinguish throughout between what you measured, what you read in a document, and what you
inferred.** Do not present an inference in the same voice as a count.

### 5. Say what you did not read

A large change set will not fit in one careful pass. That is expected; hiding it is not.

**Name every file you did not examine**, or characterise them exactly if the list is long
(*"the 25 test suites under `cpm/hooks/tests/`, none read"*). A count is not enough — it is
precisely the shape of disclosure that lets a reader move on without checking. An analysis
that silently samples reads as complete, and the larger the change set the more confident
that silence sounds.

### 6. Report

In conversation, lead with the finding: the one sentence that characterises this change set.
Then the axis and what sits either side of it, where the change sits in the repository, what
it traces to, what you verified, and what you did not read.

## Publishing

An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.

This skill's output is the case where a page usually earns itself: the analysis is what a
reader wants instead of the diff, and it is the thing no diff can render.

**Lead with the finding, not the diffstat.** A reader can already run `git diff`. The page
should stand in for reading the change set: someone without the repository open should finish
it knowing what changed, which tier it belongs to, where it sits, and what it traces back to.

**Report counts and paths, not wholesale source.** Quote code only where a specific point
needs it — an unbounded excerpt is a diff, and rendering a diff is a mirror that earns
nothing.

**Design for the subject rather than from a template.** The axis you derived in Section 1 is
usually the page's organising idea, and it is often worth encoding structurally rather than
labelling repeatedly.

**If the change set is small, unremarkable, or has no interesting structure, say that and keep
the page short.** Do not inflate a routine change into an architectural narrative.

Register the artifact per the shared procedure once the URL comes back.

## Degradation

| Missing | Behaviour |
|---------|-----------|
| No CPM artifacts | Section 3 falls back to ADRs, CHANGELOG, commit trailers, branch names. Say which channel you used. |
| No intent record of any kind | Report that plainly. Sections 1, 2, 4 and 5 are unaffected, and 2 usually carries the analysis on its own. |
| No tests, linter or build | Section 4 reports that there was nothing to run. Do not describe the change as verified. |
| No meaningful static/dynamic split | Section 1 says so and proposes the axis that does explain the change set. |
| A selector matching nothing | `changeset_resolve_git` errors with the selector echoed back. Report it and stop. |
| Not a git repository | Resolution fails. There is no degraded reading of a change set without a repository to take it from. |
| The Artifact tool is absent | Say so and skip publishing. The conversational report is unaffected. |

## Output

The report in conversation, and — on request — a published artifact plus its row in
`docs/artifacts/index.md`. This skill writes no other file and commits nothing.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**: Create the file once the selector has resolved — before that there is nothing
worth recovering, and the selector is the one thing a resumed run cannot re-derive. Update it
as each section is settled. Delete it after the report.

**Format**:

```markdown
# CPM Progress

**Skill**: inspect
**Selector**: {the selector as given, and what it resolved to}
**Change set**: {commit count} commits, {file count} files, {n} uncommitted
**Axis**: {the static/dynamic definition chosen for this repo}
**Section**: {1-6}

## Settled
- {section}: {what it established}

## Not examined
- {path or characterisation}
```

The axis is carried because it is the expensive decision — re-deriving it after compaction
risks a resumed run classifying the second half of the change set on a different definition
from the first.

## Notes

- Selector resolution is the only deterministic machinery here, and deliberately so. An
  earlier version of this skill resolved provenance mechanically, through adapters and a
  join, and its headline answer on a real change set was both reproducible and wrong: every
  file linked to every record, reported as "no orphan changes". Reading the planning
  documents directly gives a better answer, and one that can say *this signal does not
  discriminate here* — which no adapter can.
- Everything above resolution is a reading, and it should sound like one. Counts are counts;
  inferences are inferences; the page and the conversation both keep them apart.

## Next Action

After the report, offer one of:

- `/cpm:audit` — when the change set raised code-quality questions worth a proper sweep
- `/cpm:quick` — for something small and well-defined the analysis turned up
- `/cpm:spec` — when it describes work that needs planning
- `/cpm:retro` — when the change set is the end of an epic chain

Offer; do not run.
