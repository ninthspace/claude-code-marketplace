# Library: back-fill and consolidate

Read this file when the argument is `consolidate`, alone or with a path, and read it again whenever it is not in context. The contract (`shared/artifacts.md`, two levels above this file's directory) defines the library document front-matter and the amendment block; `SKILL.md` beside this file says how an import writes front-matter.

## Back-fill

Find every `docs/library/*.md` whose first line isn't `---`; if there are none, say so and stop. Write front-matter for each as in an import, with `source` set to the file's own path, show the list and all the front-matter in one message, and prepend it on one confirmation, leaving each body exactly as it was. Skip a document that can't be analysed or written, with a one-line reason, and carry on with the rest.

## Consolidate

Consolidate only when the user asks for it. Split the document into front-matter, body and its `## Amendment` blocks in order; if there are none, say so and stop.

Write a clean current version: each amendment integrated into the body where it belongs, not appended, and the blocks removed; `last-reviewed` set to today and `summary` rewritten to match. Where an amendment contradicts the body or another amendment, don't choose silently: quote both passages of each contradiction and ask which holds, all in one AskUserQuestion call.

Show what changed: sections rewritten, amendments absorbed, contradictions and how they were settled. This rewrites the whole file, so save only when the user approves.
