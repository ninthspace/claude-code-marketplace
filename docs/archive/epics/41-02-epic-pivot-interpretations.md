# Pivot the Three Interpretations

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Date**: 2026-07-25
**Status**: Complete
**Blocked by**: Epic 41-01-epic-convention-restructure
**Artifacts**: [Artifact clipboard probe](https://claude.ai/code/artifact/60c498ab-587b-4b00-bb7c-ed70f783e183)
**Retro applied**: 15 · Codebase discoveries · Applied — Tasks 1.3, 2.3 and 3.3 assert rc-and-reason together under one `test_start` and extract a named helper where the invoke-and-check triple repeats, so all three new suites report honest counts rather than the framework's inflated ratio.
**Retro applied**: 15 · Testing gaps · Applied — every `sed` range in the new suites is anchored to heading syntax (`^## ` / `^### `), and each range is checked to span the intended region rather than trusted because it went green.
**Retro applied**: 15 · Patterns worth reusing · Applied — each story's verification gate adds an end-to-end read of the rewritten section before coverage rows are marked; all three pivots rewrite prose that currently assumes a local HTML file exists, which is the false-premise shape this caught in 41-01.
**Retro applied**: 12 · Codebase discoveries · Applied — Task 1.2's trigger-word sweep (`html`, `dashboard` at `status:20`) and the secondary-site sweeps in 2.2/3.2 judge each hit by what its rule does before editing; `html` stops being a meaningful request term while `dashboard` does not.

## Pivot the status full-picture document to a published artifact
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R2, R5, AD1, AD3
**Inline change**: The register criterion originally read "Publishing writes the register row and the `**Artifacts**:` backlink". `status` has no single source artifact — its inputs are every scanned epic and spec — and writing a backlink into them would break the read-only guarantee the skill states in its Guidelines. AD1's consequence anticipates exactly this: for `status` and `epics` the register row *is* the durable trace. Criterion narrowed to the register row; the backlink half stays intact on Story 3, where a source artifact exists. (2026-07-25)
**Inline change**: Phase 4 now carries the canonical reference line authored in 41-01 Story 2, one epic ahead of 41-03's propagation. Not a scope grab — the superseded line ("Any HTML output here can additionally be published") sat inside the block this task rewrites and could not survive it, since there is no HTML output here any more. Leaving Phase 4 with no publishing instruction, or with a line whose premise the same edit falsifies, were the only alternatives. 41-03 will find this site already correct; its `grep | sort | uniq -c` identity check is unaffected, the line being byte-identical and on its own line. (2026-07-25)
**Inline change**: `cpm/hooks/tests/test-status-dashboard.sh` deleted (approved). It came from archived epic 34-01 and tested the retired behaviour end to end — a document built from `template.html`, `check_counts_agree` against it, and the `docs/plans/status-dashboard.html` scratch path — so four of its assertions failed the moment Phase 4 was rewritten. No epic in the 41 chain owned it: 41-04 retires only `test-faithful-render.sh`. The surviving contract (stdout narrative mandated, opt-in never default, agreement statement) is covered by `test-status-artifact-pivot.sh`. `check_counts_agree` is now dead — its only caller is gone — but removal is left to 41-04, which owns validator pruning. (2026-07-25)

**Acceptance Criteria**:

- Phase 4 contains no instruction to write a local HTML file [integration]
- All four secondary sites are updated: the frontmatter description, the `**Optional full-picture HTML document**` summary, the Input trigger-word list, and the State Management write path [integration]
- The five sections — at-a-glance RAG, in-progress & blocked, epic/story completion grid, recent git activity, recommended next steps — survive as artifact content [integration]
- The canonical agreement statement **"{complete} of {total} epics complete"** still matches the count the stdout narrative reports [integration]
- Degradation to the Phase 1–3 stdout narrative when the Artifact tool is absent is stated in the skill [manual] — prose adequacy is a judgement with no automatable oracle
- Publishing writes the register row in `docs/artifacts/index.md`; no `**Artifacts**:` backlink is written, because `status` has no single source artifact and its scan is read-only [integration]
- must NOT hard-fail when the Artifact tool is absent [integration]

### Rewrite Phase 4 as an artifact publish
**Task**: 1.1
**Description**: Covers the no-local-file, five-sections, and count-agreement criteria. Phase 4 is HTML-native — it synthesises from the Phase 1+2 scan with no Markdown intermediate — so this changes the output medium, not the content.
**Status**: Complete

### Sweep the four secondary sites
**Task**: 1.2
**Description**: Covers the secondary-sites criterion. The spec named only Phase 4; the survey found four more (`:3`, `:12`, `:20`, `:31`). The trigger words `html` and `dashboard` at `:20` need particular care — `html` stops being a meaningful request term.
**Status**: Complete

### Write tests for the status artifact pivot
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Retro**: [Scope surprise] The breakdown surveyed the *skill* surface (four secondary sites beyond Phase 4) but not the *test* surface, so `test-status-dashboard.sh` — an entire suite from archived epic 34-01 asserting the exact behaviour this story retires — went unowned and turned the runner red four assertions deep the moment Phase 4 changed; the survey that finds secondary sites should run over `cpm/hooks/tests/` too, since a behaviour worth pivoting is usually a behaviour someone already wrote tests for. Separately, the end-to-end read (retro 15, applied) earned its place a second time: three defects survived a green 27-assertion suite — "the page is published *in addition*" (publishing is separately confirmed, so Phase 4 running does not imply a published page), "no stored status artifact" (overloading *artifact* in the one section where it now means a hosted page), and bold nested inside a code span that would not render.

---

## Pivot the epics dependency view to a published artifact
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R2, R5, AD1, AD3
**Inline change**: Register criterion narrowed to the register row, for the same reason recorded on Story 1 — the dependency view is a projection over every epic doc, and `epics` guarantees it modifies none of them. (2026-07-25)

**Acceptance Criteria**:

- No write to `docs/plans/epics-dependency-view.html` remains [integration]
- The readiness rule is unchanged — a story's dependency is satisfied when the referenced story/epic has `**Status**: Complete` (or `**Blocked by**` is `—`), the same rule `cpm:do` hydration applies [integration]
- The schema-tolerance rules survive intact: missing status renders under **Needs attention**, an unparseable epic costs one line rather than the view, and the output is always valid [integration]
- The general glob `docs/epics/[0-9]*-epic-*.md` is retained so legacy flat-shape epics stay visible [integration]
- Degradation to a stated ready/blocked list in conversation is stated in the skill [manual] — prose adequacy is a judgement with no automatable oracle
- Publishing writes the register row in `docs/artifacts/index.md`; no `**Artifacts**:` backlink is written, because the view is a read-only projection with no single source artifact [integration]
- must NOT modify, rewrite, or re-save any epic doc [integration]

### Rewrite the Dependency View section as an artifact publish
**Task**: 2.1
**Description**: Covers the no-local-write, readiness, schema-tolerance and glob criteria. The view is a read-only projection; only its medium changes. The read-only guarantee and the schema-tolerance block are the parts most at risk of being lost in a rewrite.
**Status**: Complete

### Sweep the secondary sites
**Task**: 2.2
**Description**: Covers the frontmatter description and the dependency-view mode-detection block under Input, both of which describe an HTML projection.
**Status**: Complete

### Write tests for the dependency-view pivot
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Retro**: [Pattern worth reusing] Story 1's retro said to survey `cpm/hooks/tests/` alongside the skill surface; doing that here found `test-epics-dependency-view.sh` and `test-epics-schema-tolerance.sh` *before* they went red, and changed the outcome rather than just the timing — unlike `test-status-dashboard.sh`, most of their content (the readiness classification, schema tolerance, and the epic-docs-unchanged proof) tests rules this story must **preserve**, so re-pointing their fixtures at a body fragment validated by `check_valid_fragment` kept real coverage that deletion would have thrown away. Discovering a doomed suite at survey time gets you a choice; discovering it at test-run time gets you a cleanup. Worth noting too that `check_valid_fragment` — built in 41-01 with no caller — earned its place here on its first real use.

---

## Pivot present's HTML communication to a published artifact
**Story**: 3
**Status**: Complete
**Blocked by**: —
**Satisfies**: R2, R5, AD1
**Inline change**: The backlink criterion resolved to `present`'s pre-existing `**Artifact**` field rather than a new `**Artifacts**:` one (approved). R5 wants the relationship to read from both ends — register → source, source → URL — and the singular field already provides the second half, holding the same URL for the same reason. The literal reading would either mutate the input epics/specs `present` only read, or leave two near-identically-named fields carrying one URL. The skill now names the collision and forbids the duplicate. (2026-07-25)

**Acceptance Criteria**:

- No write to `docs/communications/{nn}-{format}-{slug}.html` remains [integration]
- The Markdown output and its `**Source artifacts**` field are retained [integration]
- The `**Artifact**` field is retained so a later session updates the existing page rather than minting a second URL [integration]
- The prohibition on publishing communications that present themselves as issued by an organisation the user does not represent survives [integration]
- Publishing writes the register row, with the communication's existing `**Artifact**` field serving as the backlink R5 requires [integration]
- must NOT remove `present`'s Markdown output or its `**Source artifacts**` field [integration]

### Replace the HTML-output block with an artifact publish
**Task**: 3.1
**Description**: Covers the no-local-write and Markdown-retention criteria. The Markdown is the record of what was communicated; only the HTML sibling was the mirror.
**Status**: Complete

### Reconcile the regeneration paragraph
**Task**: 3.2
**Description**: The regeneration paragraph currently offers update-in-place across three outputs (Markdown, HTML, artifact). With the HTML gone it covers two — and the artifact branch must keep reading the `**Artifact**` field for the URL.
**Status**: Complete

### Write tests for the present pivot
**Task**: 3.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Retro**: [Criteria gap] Both register criteria in this epic were unsatisfiable as written, for opposite reasons, and neither surfaced until execution: `status`/`epics` have no source artifact to hold a backlink, while `present` already had one under a *different name* (`**Artifact**`, singular, predating the register). The criterion was copied verbatim from R5 to all three stories on the assumption that a requirement's wording transfers to every skill it names — but R5's phrase "on the source artifact" presupposes a skill shape only one of the three has. A criterion quoting spec text should be checked against each skill it lands on, not just against the spec it came from.

---

## Settle the clipboard question
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: AD5

**Acceptance Criteria**:

- Clipboard behaviour is verified on a live published artifact, or the selectable `<pre>` fallback is applied [manual] — requires a published page; there is no local oracle for cross-origin permissions policy
- The outcome is recorded in the convention so the next author is not left re-deriving it [integration]

### Publish a status artifact and test the copy control
**Task**: 4.1
**Description**: Exercises the publish path end to end. Inline JS is CSP-permitted, but `navigator.clipboard.writeText` inside a cross-origin embedded frame is permissions-policy gated — this task determines which. Blocked by Story 1 because it needs a real published page to test against.
**Status**: Complete

### Record the outcome in the convention
**Task**: 4.2
**Description**: Whichever way it goes, the convention states it — either the affordance is confirmed, or the `<pre>` fallback becomes the documented pattern. Leaving it unrecorded reproduces the assumption AD5 exists to avoid.
**Status**: Complete

**Retro**: [Codebase discovery] The register the spec calls "the invariant" and AD1 calls the only durable trace for `status` and `epics` — `docs/artifacts/index.md` — **did not exist** until this story published the first artifact; three epics had been enforcing a backlink-and-register rule against a file nobody had created. The clipboard question itself resolved the optimistic way: `writeText` succeeded inside the cross-origin frame with `permissions.query("clipboard-write")` reporting *unsupported* on that engine, which is the useful part — the permissions query is a diagnostic, not a gate, and code branching on it would have disabled a working control.

---
