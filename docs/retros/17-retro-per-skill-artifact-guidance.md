# Retro: Per-Skill Artifact Guidance

**Date**: 2026-07-25
**Source**: docs/epics/41-03-epic-per-skill-artifact-guidance.md
**Stories**: 2/2 complete

## Summary

All ten skills now carry the canonical Artifact Publishing reference line byte-identically, and nine of them carry a sentence naming what an artifact would show for their own output plus the conservative heuristic verbatim. Both coverage rows for Story 1 and both for Story 2 verified; 72 new assertions across two suites, full runner green throughout. The epic's two defects were both found by *reading* rather than by testing — one before starting, one at the gate — and both were the same shape: **a criterion written once and applied to N sites assumed all N sites had the same shape**.

## Observations

### Criteria Gaps

- **A criterion applied to N sites should name the shape it assumes those sites have.** Story 2's heuristic criterion — *"if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place"* — is a live gate at the seven skills that only *might* produce an artifact. At `status` and `epics` the artifact is the section's entire purpose, decided by spec 41 and executed in epic 41-02, so the identical sentence reads as reopening a settled decision. Nothing detected this: the criterion says "each of the nine", the verbatim-string test says the bytes are present, and both are satisfied by prose that is wrong at two sites. This is the **second consecutive epic** where a criterion phrased once and propagated to several skills failed at the skills whose shape differed — retro 16 recorded the same defect against R5's `**Artifacts**:` backlink, which was unsatisfiable at `status`/`epics` for the same underlying reason (they have no single source artifact; their section *is* the artifact). Two instances with the same two skills on the wrong side is a pattern, not a coincidence: `status` and `epics` are the skills whose output is a projection rather than a document, and criteria written for document-producing skills keep landing badly on them.

- **The count criterion claimed a repo-wide edit scope the epic did not have.** `grep -rh … cpm/` also matches the canonical line's own *definition* in `cpm/shared/skill-conventions.md`, so it would have reported 11 against a criterion asserting 10. Scoped to `cpm/skills/` before starting. This is the **third** instance of the "repo-wide grep criterion implies repo-wide edit scope" defect that epic 41-01's retro first named — it recurs because grep is the natural way to express a propagation criterion and the natural expression is always broader than the story that owns it.

### Patterns Worth Reusing

- **Surveying before starting found a defect that no gate in this epic would have caught.** In `architect`, `review` and `spec` the superseded reference line sat *inside* the `Faithful Render (on request)` section that epic 41-04 deletes. Replacing it in place satisfies every criterion at this epic's gate and then silently drops the count from ten to seven when 41-04 runs — with nothing failing at either gate, because by then no test asserts a count of ten against a section that no longer exists. The line was instead placed against each skill's primary saved output, which is also where it is truthful: those skills publish from their Markdown, not from a render that will not exist. A new coverage row (2b) binds the placement so the guarantee survives the next epic. **When an epic edits text a later epic deletes, the placement is part of the requirement, not an implementation detail.**

- **The end-to-end read at the gate earned its place for the third consecutive epic.** A green 51-assertion suite left three defects standing in prose: a `which … which` clause in `discover` that parses two ways, `audit` claiming the Executive Summary "ranks the top ten" where the skill says *maximum* 10 bullets, and the heuristic framing at `status`/`epics` above. None is detectable by any structural assertion — they are wrong in meaning while correct in structure. Retro 15 proposed this practice, retro 16 confirmed it, and it has now caught defects at three gates in a row; it should stop being a per-epic retro disposition and become part of the verification gate itself.

### Codebase Discoveries

- **Every CPM SKILL.md keeps `##`-level headings inside its output-format code fence, so any structural query over these files needs fence tracking.** A nearest-preceding-heading scan — the obvious way to ask "which section is this line in?" — reported `architect:235` under `## Dependencies` and `spec:311` under `### Unit Testing`, both headings from inside a template fence and both fiction. The same shape mis-reported section boundaries earlier when locating placement sites, naming `## Why` / `## Vision` / `## Context` as sections that do not exist. This is not an edge case in this codebase; it is the default. `test-reference-line-propagation.sh` carries a fence-aware `enclosing_heading` helper with a negative control asserting it ignores fenced headings, rather than trusting a green run.

- **The heuristic's original phrasing exists at only two sites, differently worded at each.** `spec:207` and `architect:161` each carry a companion-asset variant ("if you cannot write a one-line justification, the visual has not earned its place"; "If you cannot write that one-line justification, the diagram has not earned its place"). The nine new sites carry the criterion's phrasing verbatim, which is a *third* wording of the same rule now present in the same two files. Not a defect this epic owns — the criterion specified the string — but worth naming before it becomes four.

### Testing Gaps

- **A verbatim-string assertion proves propagation, never aptness.** Story 2's first criterion is correctly tagged `[manual]`: whether a value-proposition canvas is the right artifact for `brief` has no automatable oracle. The risk is that a suite reporting 51 green assertions *reads* like it verified the story. The suite's header names what it does not test for exactly that reason, and the aptness half was verified by reading all nine sites in place — which is where all three prose corrections came from.

## Recommendations

- **Fold the end-to-end read into the verification gate.** Three consecutive epics, three sets of defects that survived green suites, all in prose that was structurally correct and semantically wrong. It is no longer a lesson to dispose of per run; `cpm:do`'s Step 4 should require reading each edited section in place before coverage rows are marked.
- **At breakdown, check any criterion applied to `status` or `epics` against their shape specifically.** Both produce projections over other documents rather than documents of their own, and criteria written for document-producing skills have now failed on them twice in two epics — on the backlink invariant (retro 16) and on the earns-its-place heuristic (here).
- **Scope propagation-by-grep criteria to the epic's edit scope when writing them.** Third instance. The fix is mechanical: if the criterion is a `grep -r` over a directory, that directory must be the one the story owns.
- **Epic 41-04 should re-run `test-reference-line-propagation.sh` after deleting the `Faithful Render` sections**, and expect it green without modification. That is the whole point of coverage row 2b — if the count drops to seven, the placement guarantee failed and the suite is the thing that says so.
- **Consider consolidating the three wordings of the earns-its-place heuristic** when 41-05 sweeps the docs. `spec` and `architect` now each carry two variants of one rule.
