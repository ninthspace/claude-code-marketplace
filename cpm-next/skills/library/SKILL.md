---
name: library
description: Curate the project reference library in docs/library/ — import a local file or URL with front-matter that tells every skill what the document constrains and when to read it, promote recurring lessons from signals and legacy retros into it, back-fill front-matter on documents that have none, fold accumulated amendment blocks into a clean current version, or sweep a list of repositories for process failures cpm-next could prevent. Use whenever the user wants to add standards, architecture notes, API contracts, domain glossaries or other reference material for planning and building. Triggers on "/cpm-next:library".
model: sonnet
effort: medium
---

# Library

Before writing anything, read `shared/artifacts.md` at the plugin root, two levels above this skill's directory. It defines the library document front-matter, the scope mapping, the amendment block, the `lessons-learned.md` entry and the signal forms and marks. The retro format is below.

## Scope and finish line

Read `$ARGUMENTS`:

| Argument | Action | Done when |
|---|---|---|
| a file path or URL | import it | the document is saved in `docs/library/` with complete front-matter |
| `learn`, optionally with a path or keyword | promote lessons | every lesson the user chose is in the library and its signals marked promoted, or its retro observation retired |
| `sweep` | report process failures across repositories | each group found in two or more listed repositories is reported |
| `sweep add {path}`, `sweep remove {path}`, `sweep list` | maintain the repository list | the list is changed or shown |
| `consolidate` alone | back-fill | every library document starts with complete front-matter |
| `consolidate {path}` | consolidate | that document's amendments are folded into its body and removed |
| nothing | ask which document to import, in one line | as for an import |

## Import

1. Read the source (WebFetch for a URL). If it can't be read, say so with the path or URL and stop.
2. Write the front-matter, with `summary` written for the skills that read it: the constraints, decisions and rules the document imposes, in two to five sentences, such as "PSR-12 enforced by Pint. Repository pattern for data access. No inline SQL outside migrations." rather than "This document describes the team's PHP standards." Choose `scope` by what the document constrains, from the contract's mapping.
3. Show the front-matter and the filename in one message, then save unless the user redirects. Ask only when the scope is genuinely ambiguous, in one AskUserQuestion call with a recommended option.
4. Save to `docs/library/{kebab-case-title}.md`, with no number prefix: front-matter first, then the source content unchanged. If the filename is taken, say so and ask whether this replaces it.

## Learn

1. Collect every recurring signal (a `**Signal**:` field line at the start of a line in `docs/epics/`, `docs/archive/epics/` or `docs/quick/`, with a ` — recurs:` suffix), `project` or `process`, that has no ` — promoted` or ` — declined` mark, and every observation bullet in `docs/retros/` with no `**Retired` marker, narrowed to the path or keyword given. If none are left, say so and stop.
2. Pick out the durable ones. A recurring signal is durable by definition. Of a legacy observation, keep a constraint, convention or trap that will outlast the epic it came from, especially one several retros repeat, and leave out one-off reports about a single run; one that has obviously stopped being true, such as a lesson about code since removed, is proposed for retirement as spent, with the reason. Anything a library lesson already holds is not promoted again: a signal or observation whose `**Class**` and rule are in the library (a lesson with no `**Class**` is compared by reading), or an observation whose `**Recurrence**` names a library lesson or a retro observation already retired as promoted. Propose marking such a signal promoted, or retiring such an observation as promoted to that lesson's document; this applies to `process` signals and to observations naming a cpm-next rule too. Candidates of one class and rule, whether signals from different epics or a signal and the observation it recurs on, are one lesson whose `**Source**` names them all.
3. Show them in one message, grouped by source, each with its proposed owning layer and outcome. A `project` signal, or a legacy observation about this codebase, becomes a library constraint: an entry in `docs/library/lessons-learned.md` (or the existing file ending in `lessons-learned.md`), or an amendment block on a named library document when it changes what that document says, in the contract's form, with a `**Class**` chosen by the contract's slug rule (reuse a slug, a library `**Class**` or a seed first), for a legacy observation too. A `process` signal, or a legacy observation naming a cpm-next rule, is a candidate for the plugin (a `plan` criterion rule, a `do` rule or an auditor check), naming the file and step: write nothing and mark nothing for it. The user answers in one AskUserQuestion call: a multi-select of which to act on (your recommended set first), covering promotions, retirements as spent and the already-in-the-library marks or retirements of step 2, and, when there are `project` signals, a second multi-select of which lessons to decline; a lesson picked in both is promoted.
4. For each chosen lesson, write the library side first, then mark the source: ` — promoted {YYYY-MM-DD}` on each signal, or the `**Retired` marker on the observation; mark every signal of each declined lesson ` — declined {YYYY-MM-DD}`, leaving out a signal whose `recurs` match is declined. A chosen spent observation gets the `**Retired` marker with its reason and no library write. A chosen lesson already in the library, checked again before each write, is not written again: mark or retire its sources as step 2 proposes, and report it as already promoted. An older amendment whose `**Source**` gives only the retro path doesn't identify one observation, so compare its text with the observation. If a library write fails, leave the sources untouched, so that nothing is marked promoted without being promoted.

## Legacy retros

Files in `docs/retros/` are legacy input that no skill writes. An observation is a bullet under `## Observations`, usually in a `### {Category}` group (Smooth Deliveries, Scope Surprises, Criteria Gaps, Complexity Underestimates, Codebase Discoveries, Testing Gaps or Patterns Worth Reusing): `- {observation}: {what it means for the next piece of work}`. Read other layouts tolerantly: a category written inline in the bullet is the `{Category}` of a `**Source**` (the first, when there are two), a retro with no groups is read bullet by bullet, and an observation runs from its bullet to the next one, so a `**Retired` paragraph anywhere in it retires it. A promoted observation, or one that has stopped being true, is retired in place by appending `**Retired {YYYY-MM-DD}**: {reason, or "promoted to {library path}"}` to its bullet; every skill skips a retired observation, and removing the marker restores it. An observation carrying `**Recurrence**: {lesson reference}` names a lesson that already describes it.

## Sweep

The repository list is `~/.claude/cpm-next/repos.txt`, one absolute path per line. `sweep add {path}` appends the symlink-resolved absolute path (for a path that doesn't exist yet, its existing parent resolved with the rest appended, which is not refused), creating the directory and file on the first add, and refuses one already listed; `sweep remove {path}` resolves its argument the same way and removes it; `sweep list` shows the list and whether each path exists. A missing or empty list is reported with how to add a repository. A listed path that no longer exists or holds none of `docs/epics/`, `docs/archive/epics/`, `docs/quick/` and `docs/retros/` is reported with `sweep remove {path}` or a corrected path, and skipped; one that can't be read is reported with the advice to allow the read; the sweep carries on with the rest. Read each distinct resolved path once, and count distinct resolved paths when applying the two-repository threshold.

`sweep` reads each listed repository's `docs/epics/`, `docs/archive/epics/` and `docs/quick/` and collects every `process` signal, counting only a `**Signal**:` field line at the start of a line, not a template quoted in prose or code. It also collects unretired legacy retro observations that name a cpm-next skill or rule (a v3 skill counts as its cpm-next counterpart). It places each at the cpm-next file and step it involves, reading that file as it now stands when a signal's parenthesis or an observation names no step, and lists one it can't place as unplaced rather than dropping it. It groups by that file and step, using the slug as a hint and reading to confirm, and reports each group found in two or more repositories with its signals (repository, signal reference, what failed). A group found in one repository only is named as not reported.

It writes nothing in any scanned repository and never marks or edits a signal. On the user's choice it writes one discussion record in the current repository, `docs/discussions/{nn}-discussion-sweep-{YYYY-MM-DD}.md` (numbered by the contract), for `/cpm-next:plan`, even when the current repository is also listed. The record lists the reported groups with their signals, the groups not reported, the unplaced items and the skipped paths, and carries `**Status**: Concluded`; end with `/cpm-next:plan {record path}`.

## Back-fill

Find every `docs/library/*.md` whose first line isn't `---`; if there are none, say so and stop. Write front-matter for each as in an import, with `source` set to the file's own path, show the list and all the front-matter in one message, and prepend it on one confirmation, leaving each body exactly as it was. Skip a document that can't be analysed or written, with a one-line reason, and carry on with the rest.

## Consolidate

Consolidate only when the user asks for it. Split the document into front-matter, body and its `## Amendment` blocks in order; if there are none, say so and stop.

Write a clean current version: each amendment integrated into the body where it belongs, not appended, and the blocks removed; `last-reviewed` set to today and `summary` rewritten to match. Where an amendment contradicts the body or another amendment, don't choose silently: quote both passages of each contradiction and ask which holds, all in one AskUserQuestion call.

Show what changed: sections rewritten, amendments absorbed, contradictions and how they were settled. This rewrites the whole file, so save only when the user approves.

## Finishing

End with the path of each file written or skipped and, for an import, the scope it was given. After a `learn`, also name each signal or retro that was marked.
