# Documentation and Release

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Date**: 2026-07-25
**Status**: Complete
**Blocked by**: Epic 41-01-epic-convention-restructure, Epic 41-02-epic-pivot-interpretations, Epic 41-03-epic-per-skill-artifact-guidance, Epic 41-04-epic-retire-mirrors
**Retro applied**: 18 · Scope surprises · Applied — Story 1 re-reads every skill's frontmatter `description` against what that skill now produces, not just the README and training guide. Three of the four prior epics changed outputs, and this is the last gate before 3.1.0 ships.
**Retro applied**: 14 · Codebase discoveries · Applied — Task 2.1 greps every version site before any edit and records the full result set, and additionally checks whether any site is *already* stale against the manifest, which is how the README heading was found last release.
**Retro applied**: 17 · Codebase discoveries · Applied — the two older companion-asset wordings of the earns-its-place heuristic in `spec` and `architect` are folded into the canonical phrasing while Story 1 is already reading those files, preventing a fourth variant.
**Retro applied**: 18 · Criteria gaps · Applied — each story's criteria have their premises checked before work starts (does the README describe faithful renders today, does the training guide carry the named `SKILLS` fields, is the current version what the epic assumes), rather than discovering a stale premise at the gate.

## Update the documentation
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: In-scope item — documentation updates
**Inline change**: The premise check (retro 18, applied) found the first criterion largely already satisfied and pointed at the wrong residue. `cpm/README.md` contained **no** faithful-render text at all — the sections were never described there — and no local-HTML claim for `status` or `epics`. Its one stale claim was `present`'s *"optionally alongside a self-contained `.html` version"*. What the criterion missed is the opposite defect: `status` and `epics` were now *under*-described, `status` still asserting "no files created or modified" (false since a confirmed publish appends a register row) and `epics` never mentioning the dependency view at all. Both corrected; the criterion is satisfied and the sections are true, which are not the same thing here. (2026-07-25)
**Inline change**: The README's `What's Included` file tree listed **18 of 21** skills — `ralph`, `audit` and `artifact` missing — and omitted `assets/` and `shared/` entirely. Out of the criterion's letter, squarely inside the must-NOT's subject: an enumeration is a snapshot by construction, and this one had rotted through three releases. Repaired, and the new suite asserts the tree against the filesystem rather than against a pinned list, so it cannot rot again silently. (2026-07-25)
**Inline change**: The two older companion-asset wordings of the earns-its-place heuristic in `spec` and `architect` folded into the canonical phrasing (retro 17, applied at this epic's gate). The clause is now identical at all eleven occurrences across nine skills, asserted by a `sort -u` check. Two of the eleven — the companion-asset sections in `spec` and `architect` — continue with a site-appropriate imperative, *"— don't generate it"*, which the nine artifact-guidance sentences correctly omit: those decide whether to *publish* on request, not whether to *generate*. The split falls exactly on generation-vs-publishing and is deliberate, not residual drift. (2026-07-25)

**Acceptance Criteria**:

- `cpm/README.md` describes no faithful-render capability and no local HTML output for `status`, `epics` or `present` [integration]
- `cpm-training-guide.html`'s `SKILLS` records show artifact outputs where the skill now publishes rather than writes HTML [integration]
- The `artifact` skill record and the register are described as the durable trace for published work [integration]
- must NOT introduce a skill count, version literal, or other snapshot value that a later change silently invalidates [integration]

### Update cpm/README.md
**Task**: 1.1
**Description**: Covers the README criterion. The README's own section headings have carried stale content in each of the last three releases — read it end to end rather than patching the sections the diff suggests.
**Status**: Complete

### Update the training guide's skill records
**Task**: 1.2
**Description**: Covers the training-guide and artifact-record criteria. The guide is data-driven — the `SKILLS` array's `output` and `outputFile` fields are what change, not the prose around them.
**Status**: Complete

### Write tests for documentation updates
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Verification** (2026-07-25): `cpm/hooks/tests/test-docs-artifact-pivot.sh` — 19/19 passed; `run-all-tests.sh` green at 23 suites. `cpm/README.md` carries no `faithful` hit, no `.html version` sibling for `present`, no HTML-dashboard claim for `status`, no skill count and no version literal; its file tree now matches `cpm/skills/` exactly. The training guide's `SKILLS` array still parses and holds 21 records, all with `output` and `outputFile`; the `present`, `status`, `epics` and `artifact` records describe publishing and the register. The heuristic has exactly one wording across all nine skills. Every assertion is a pairing — retired claim absent *and* replacing claim present — because an absence check alone passes equally on a section that was updated and one that was deleted.

**Retro**: [Criteria gap] The criterion described the wrong defect, and the premise check is what revealed it. "Describes no faithful-render capability and no local HTML output for `status`, `epics` or `present`" was satisfied on arrival for two of its three subjects and for the faithful-render half entirely — the README simply never documented those features. The real drift was the inverse: `status` asserting an absolute read-only guarantee that a confirmed publish had made false, and `epics` not mentioning the dependency view at all. A documentation criterion phrased as *"describes no X"* can only find text that is present and wrong; it is blind to text that is absent and needed, which is the more common shape after a feature is added. Worth pairing every "describes no X" with a "describes Y" for the thing that replaced it — which is, not coincidentally, the shape every assertion in the new suite ended up taking.

---

## Release 3.1.0
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: In-scope item — plugin version bump

**Inline change**: The pre-edit survey (retro 14, applied) returned **six** sites, not the three the last release found — the two presentation decks and the training guide each carry a version badge nobody had counted. All six agreed at `3.0.0` beforehand, so unlike last release nothing was already stale. Full result set recorded under Task 2.1 below. (2026-07-25)

**Inline change**: The new suite's must-NOT sweep caught one hit outside its own assertions: `test-docs-artifact-pivot.sh`'s header comment spelled out the release number as an example of the anti-pattern it was warning against. Reworded to describe the number rather than write it — a literal in a comment is invisible to a reader but not to the sweep, and a suite that has to be excepted from its own rule is not worth having. (2026-07-25)

**Acceptance Criteria**:

- `grep -rn` for the current version string is run **before** any edit, and its full result set is recorded [integration]
- Every site returned by that grep carries `3.1.0` afterwards [integration]
- Cross-manifest agreement is asserted structurally — semver shape and manifest-to-manifest equality — rather than by comparing against a pinned literal [integration]
- must NOT pin a version literal in any test assertion [integration]

### Survey every version site
**Task**: 2.1
**Description**: Covers the first criterion. Three consecutive releases have found the version at more sites than the plan named — most recently a README section heading already stale by a patch. The grep is the whole task; it costs one command.
**Status**: Complete

**Survey** (2026-07-25, `grep -rn '3\.0\.0'` before any edit — full result set):

| Site | Line | Form |
|------|------|------|
| `cpm/.claude-plugin/plugin.json` | 4 | `"version": "3.0.0"` |
| `.claude-plugin/marketplace.json` | 46 | `"version": "3.0.0"` (cpm entry) |
| `README.md` | 108 | `### Claude Planning Method (v3.0.0)` |
| `cpm-training-guide.html` | 376 | `<span class="version-badge">v3.0.0 …` |
| `cpm-presentation.html` | 456 | `<div class="title-badge">… v3.0.0</div>` |
| `cpm-onboarding-presentation.html` | 468 | `<div class="title-badge">… v3.0.0</div>` |

The grep also returned hits under `docs/epics/40-04-*`, `docs/retros/14-*` and `docs/plans/.cpm-compact-summary-*`. Those are **historical records of what shipped when** and were deliberately left alone; the new suite asserts they survive, so a future release that sweeps `docs/` fails rather than silently erasing the record.

### Apply the bump and assert agreement structurally
**Task**: 2.2
**Description**: Covers the remaining criteria. Retro 14's testing gap was two assertions pinning the literal `2.0.0`, stale since that release and failing silently because nobody runs the suite between releases. Assert the invariant, not the snapshot.
**Status**: Complete

### Write tests for the release bump
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Verification** (2026-07-25): `cpm/hooks/tests/test-version-agreement.sh` — 14/14 passed; `run-all-tests.sh` green at 24 suites. Every one of the six surveyed sites reads `3.1.0`; the three CPM-only documents carry that version and no other, and the marketplace README's five plugin headings match the set `marketplace.json` declares. Cross-manifest agreement is asserted structurally in both directions — semver shape on `plugin.json`, `marketplace.json`'s cpm entry against it, and every plugin's own manifest against its marketplace entry via the `source` field, so a plugin added later is covered without editing the test. No file under `cpm/hooks/tests/` contains the current version as a literal, and the forbidden string is read from the manifest at run time rather than written into the assertion — the sweep keeps working after the next bump without being touched. Both sweeps carry negative controls against fixtures. `test-audit-skill.sh`'s existing semver and manifest-agreement checks were left in place rather than duplicated.

**Retro**: [Testing gap] Asserting the invariant is not enough on its own — the invariant has to be *derived at run time* for the assertion to outlive the release. The obvious reading of "don't pin a literal" produces `assert_equals "3.1.0" "$found"`, which is still a pin; the version has to be read from `plugin.json` and used as the expected value, so the same test that passes today passes at 3.2.0 without an edit. Two things fell out of building it that way. First, the must-NOT sweep can be written as "no test contains *the current version*" rather than "no test contains *a semver*", which avoids false-positiving on spec and task numbers that happen to look like versions. Second, the sweep found a literal in a comment — invisible to a reader, but a pin the moment someone greps for it. Worth carrying: a version-agreement check is a per-file claim only where the file is about one thing. The root README lists five plugins, and the equivalent claim there is set equality against the manifest, not "one version appears."

---
