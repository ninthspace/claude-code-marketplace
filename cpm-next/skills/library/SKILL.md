---
name: library
description: Curate the project reference library in docs/library/ — import a local file or URL with front-matter that tells every skill what the document constrains and when to read it, promote durable lessons from retros into it, back-fill front-matter on documents that have none, or fold accumulated amendment blocks into a clean current version. Use whenever the user wants to add standards, architecture notes, API contracts, domain glossaries or other reference material for planning and building. Triggers on "/cpm-next:library".
model: sonnet
effort: medium
---

# Library

Before writing anything, read `shared/artifacts.md` at the plugin root, two levels above this skill's directory. It defines the library document front-matter, the scope mapping, the amendment block, the `lessons-learned.md` entry and the `**Retired` marker.

## Scope and finish line

Read `$ARGUMENTS`:

| Argument | Action | Done when |
|---|---|---|
| a file path or URL | import it | the document is saved in `docs/library/` with complete front-matter |
| `learn`, optionally with a retro path or keyword | promote lessons | every lesson the user chose is in the library and retired in its retro |
| `consolidate` alone | back-fill | every library document starts with complete front-matter |
| `consolidate {path}` | consolidate | that document's amendments are folded into its body and removed |
| nothing | ask which document to import, in one line | as for an import |

## Import

1. Read the source (WebFetch for a URL). If it can't be read, say so with the path or URL and stop.
2. Write the front-matter, with `summary` written for the skills that read it: the constraints, decisions and rules the document imposes, in two to five sentences, such as "PSR-12 enforced by Pint. Repository pattern for data access. No inline SQL outside migrations." rather than "This document describes the team's PHP standards." Choose `scope` by what the document constrains, from the contract's mapping.
3. Show the front-matter and the filename in one message, then save unless the user redirects. Ask only when the scope is genuinely ambiguous, in one AskUserQuestion call with a recommended option.
4. Save to `docs/library/{kebab-case-title}.md`, with no number prefix: front-matter first, then the source content unchanged. If the filename is taken, say so and ask whether this replaces it.

## Learn

1. Collect every observation bullet in `docs/retros/` with no `**Retired` marker, narrowed to the retro or keyword given. If none are left, say so and stop.
2. Pick out the durable ones: a constraint, convention or trap that will outlast the epic it came from, especially one several retros repeat. Leave out one-off reports about a single run. Mark any that have obviously stopped being true, such as a lesson about code since removed. An observation whose `**Recurrence**` names a library lesson, or a retro observation already retired as promoted, is already in the library: propose retiring it as promoted to that lesson's document, not promoting it again.
3. Show them in one message, grouped by source retro, each with its proposed outcome: an amendment block on a named library document when it changes what that document says, an entry in `lessons-learned.md` when nothing covers it, or retirement as spent, with the reason. The user picks in one multi-select AskUserQuestion call, your recommended set first.
4. For each chosen lesson, write the library side first, then the `**Retired` marker in its retro. If the library write fails, leave the retro untouched, so that no lesson is retired without being promoted. Skip any lesson whose `**Source**` already appears in the library, and report it as already promoted. An older amendment whose `**Source**` gives only the retro path doesn't identify one observation, so compare its text with the observation before skipping.

## Back-fill

Find every `docs/library/*.md` whose first line isn't `---`; if there are none, say so and stop. Write front-matter for each as in an import, with `source` set to the file's own path, show the list and all the front-matter in one message, and prepend it on one confirmation, leaving each body exactly as it was. Skip a document that can't be analysed or written, with a one-line reason, and carry on with the rest.

## Consolidate

Consolidate only when the user asks for it. Split the document into front-matter, body and its `## Amendment` blocks in order; if there are none, say so and stop.

Write a clean current version: each amendment integrated into the body where it belongs, not appended, and the blocks removed; `last-reviewed` set to today and `summary` rewritten to match. Where an amendment contradicts the body or another amendment, don't choose silently: quote both passages of each contradiction and ask which holds, all in one AskUserQuestion call.

Show what changed: sections rewritten, amendments absorbed, contradictions and how they were settled. This rewrites the whole file, so save only when the user approves.

## Finishing

End with the path of each file written or skipped and, for an import, the scope it was given. After a `learn`, also name each retro that was marked.
