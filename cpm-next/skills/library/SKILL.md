---
name: library
description: Curate the project reference library in docs/library/ — import a local file or URL with front-matter that tells every skill what the document constrains and when to read it, promote durable lessons from retros into it, back-fill front-matter on documents that have none, or fold accumulated amendment blocks into a clean current version. Use whenever the user wants to add standards, architecture notes, API contracts, domain glossaries or other reference material for planning and building to draw on. Triggers on "/cpm-next:library".
---

# Library

Keep `docs/library/` useful as context. Every skill reads it, and v3 skills filter it by the front-matter `scope`, so a document with vague or missing front-matter is one nobody reads at the right moment.

The front-matter schema, scope values and amendment block format are in `shared/artifacts.md` at the plugin root, two levels above this skill's directory. Read it before writing anything.

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

1. Read the source: the Read tool for a path, WebFetch for a URL. If it can't be read, say so with the path or URL and stop.
2. Write the front-matter. `summary` is written for the skills that will read it, not for a person browsing: the constraints, decisions and rules the document imposes, in two to five sentences. "PSR-12 enforced by Pint. Repository pattern for data access. No inline SQL outside migrations." rather than "This document describes the team's PHP standards." Choose `scope` from what the document constrains, using the mapping in the contract.
3. Show the front-matter and the filename in one message, then save unless the user redirects. Ask only when the scope is genuinely ambiguous, and then in one AskUserQuestion call with a recommended option.
4. Save to `docs/library/{kebab-case-title}.md`, front-matter first, the source content after it unchanged. Library documents have no number prefix. If the filename is taken, say so and ask whether this replaces it.

## Learn

Retros are where a lesson first appears; the library is where one that keeps holding true belongs. A lesson in a retro is only read if it happens to look relevant, while a lesson in the library is read by every skill whose scope it names.

1. Collect every observation bullet in `docs/retros/` that has no `**Retired` marker, narrowed to one retro or a keyword if one was given. If none are left, say so and stop.
2. Pick out the durable ones for the user: lessons that name a constraint, convention or trap that will outlast the epic they came from, especially where several retros say the same thing. Leave out one-off reports about a single run. Also mark any that have obviously stopped being true, such as a lesson about code that has since been removed.
3. Show them in one message, grouped by source retro, each with its proposed outcome: an amendment to a named library document when it changes what that document says, an entry in `lessons-learned.md` when nothing covers it, or retirement as spent, with the reason. The user picks which to act on in one AskUserQuestion call, multi-select, with your recommended set first.
4. For each chosen lesson, write the library side first, then the `**Retired` marker in the retro. If the library write fails, leave the retro untouched, so a lesson is never retired without being promoted. Skip any lesson whose `**Source**` already appears in the library, and report it as already promoted.

## Back-fill

Find every `docs/library/*.md` whose first line isn't `---`. If there are none, say so and stop. Otherwise list them, write front-matter for each as in an import (with `source` set to the file's own path), show it all in one message, and prepend it on one confirmation. The body of each file is left exactly as it was. A document that can't be analysed or written is skipped with a one-line reason, and the rest carry on.

## Consolidate

Split the document into front-matter, body, and the `## Amendment` blocks in order. If there are no blocks, say so and stop.

Produce a clean current version: the amendments integrated into the body where they belong, not appended to it, and the blocks removed. Set `last-reviewed` to today and rewrite `summary` to match. Where an amendment contradicts the body or another amendment, don't choose silently: show each contradiction with both passages quoted and ask which holds, all in one AskUserQuestion call.

Show what changed (sections rewritten, amendments absorbed, contradictions and how they were settled) and save when the user approves. This rewrites the whole file, so it always waits for that approval, and it runs only when the user asks for it.

## Finishing

End with the path of each file written or skipped, and for an import, the scope it was given. After a `learn`, also name each retro that was marked.
