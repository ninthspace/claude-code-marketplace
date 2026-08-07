# Per-Skill Artifact Guidance

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Date**: 2026-07-25
**Status**: Complete
**Blocked by**: Epic 41-01-epic-convention-restructure
**Retro applied**: 12 · Patterns worth reusing · Applied — the line is placed byte-for-byte at all ten sites and paired with exactly one skill-specific sentence each (Story 2's deliverable); the `sort | uniq -c` assertion is the gate, not per-file presence checks.
**Retro applied**: 16 · Patterns worth reusing · Applied — `cpm/hooks/tests/` surveyed before any edit for suites asserting the superseded line or the sections being touched, deciding rework-or-delete per suite rather than defaulting.
**Retro applied**: 15 · Patterns worth reusing · Applied — each of the ten edited sections is read in place at the gate, checking the skill-specific sentence fits its surroundings rather than merely existing; Story 2's first criterion is `[manual]` precisely because aptness has no automatable oracle.
**Retro applied**: 15 · Codebase discoveries · Applied — Tasks 1.2 and 2.3 keep one claim per `test_start` and extract a named helper where the same check repeats across ten sites.

## Propagate the canonical reference line to all ten sites
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R4, AD4
**Inline change**: Two corrections found by surveying before starting (both approved). (1) The count criterion's command was repo-wide, so it also matched the convention's own fenced copy of the line — the definition, not a use site — and would have reported 11 while the criterion said 10. Scoped to `cpm/skills/`, which is exactly this epic's edit scope. (2) In `architect`, `review` and `spec` the superseded line sits *inside* the `Faithful Render (on request)` section that epic 41-04 deletes (`architect:167`, `review:243`, `spec:213`); replacing it in place would have passed this gate and silently dropped three sites when 41-04 ran. The line is instead placed against each skill's primary saved output, which is also where it is truthful — those skills publish from their Markdown, not from a render that will not exist. (2026-07-25)

**Acceptance Criteria**:

- All ten skills carry the canonical reference line: `discover`, `brief`, `architect`, `spec`, `epics`, `review`, `audit`, `retro`, `status`, `present` [integration]
- `grep -rh "{canonical line}" cpm/skills/ --include="*.md" | sort | uniq -c` reports exactly one unique string with a count of 10 [integration]
- In `architect`, `review` and `spec` the line sits outside the `Faithful Render (on request)` section, so epic 41-04's deletion of that section does not remove it [integration]
- must NOT introduce a variant phrasing, prefix, or suffix at any site [integration]

### Propagate the line to all ten skills
**Task**: 1.1
**Description**: Covers all three criteria. The line is authored in Task 41-01.2.3; this task only places it. Byte identity is the whole point — a prefix at one site passes every per-file check while defeating the propagation guarantee, which is exactly how it broke last time.
**Status**: Complete

### Write tests for reference-line propagation
**Task**: 1.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`. The `sort | uniq -c` assertion is the one that catches variant phrasing; a per-file presence check does not.
**Status**: Complete

**Verification** (2026-07-25): `cpm/hooks/tests/test-reference-line-propagation.sh` — 21/21 passed; `run-all-tests.sh` green. The criterion's own command reports `10` against a single unique string. Placement confirmed by a fence-aware enclosing-heading lookup: `architect` → `## Output`, `review` → `### Step 3: Write Review File`, `spec` → `## Output`; none is a `Faithful Render` section. The superseded line survives nowhere in `cpm/`. Each of the seven new sites was read in place at the gate (retro 15).

**Retro**: [Codebase discovery] Every skill in this epic keeps `##`-level headings *inside* its output-format code fence, so a nearest-preceding-heading scan — the obvious way to ask "which section is this line in?" — answers with a template heading rather than the real section: it put `architect:235` under `## Dependencies` and `spec:311` under `### Unit Testing`, both fiction. The same shape had already mis-reported section boundaries when locating the placement sites. Fence tracking is not an edge case in these files; any structural query over a CPM SKILL.md needs it, and the test asserts it with a negative control rather than trusting a green run.

---

## Add skill-specific earns-its-place guidance
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R4
**Inline change**: The fourth criterion ("must NOT offer publishing during an autonomous run") is satisfied at its single home rather than restated at nine sites. The rule lives in the shared **Artifact Publishing** procedure — *"autonomous runs (`cpm:ralph`) never publish"* — which every one of the nine sites reaches through the canonical reference line placed in Story 1. Nine copies of a prohibition is nine copies to drift, and the repo's own convention rule (CLAUDE.md) is that a section shared by many skills belongs in the shared file. Tested as: the rule exists and names `cpm:ralph`, no site carries automatic- or unconfirmed-publish language, and `ralph` introduces no publishing instruction of its own. (2026-07-25)
**Inline change**: At `status` and `epics` the heuristic is framed as the test for *anything else* the page carries, rather than as a gate on the page itself. Both sections exist to publish an artifact — that decision was made by spec 41 and executed in 41-02 — so a bare "if you cannot justify it, it has not earned its place" would read as re-litigating a settled choice. The heuristic string is verbatim at all nine sites regardless; only the sentence introducing it differs at those two. (2026-07-25)

**Acceptance Criteria**:

- Each of the nine skills names what an artifact could show for *that skill's* output — a problem map for `discover`, a value-proposition canvas for `brief`, an architecture explorer for `architect`, a requirement explorer for `spec`, a dependency and readiness view for `epics`, a findings explorer by severity for `review`, a nine-dimension findings dashboard for `audit`, a trend view across retros for `retro`, a project dashboard for `status` [manual] — content judgement per skill, no automatable oracle for whether a suggestion is apt
- Each carries the conservative heuristic verbatim: **if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place** [integration]
- must NOT make artifact generation a default, automatic, or unconfirmed behaviour in any skill [integration]
- must NOT offer publishing during an autonomous run [integration]

### Write the nine skill-specific sentences
**Task**: 2.1
**Description**: Covers the first criterion. One sentence per skill naming what the artifact would show — not a restatement of the shared procedure, which the reference line already carries.
**Status**: Complete

### Apply the earns-its-place heuristic at each site
**Task**: 2.2
**Description**: Covers the heuristic and both must-NOTs. The heuristic is what keeps generation honest; without it, nine new suggestion sites become nine new default behaviours.
**Status**: Complete

### Write tests for skill-specific guidance
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Verification** (2026-07-25): `cpm/hooks/tests/test-skill-artifact-guidance.sh` — 51/51 passed; `run-all-tests.sh` green. Each of the nine carries a `For \`{skill}\` the artifact is …` sentence naming its own output, sited two lines below the reference line, and the heuristic verbatim. Three negative controls confirm the checks reject a sentence naming another skill, a paraphrased heuristic, and automatic-publish language. The `[manual]` aptness criterion was verified by reading all nine in place (retro 15), which produced three corrections: `discover`'s "which … which" clause, `audit`'s "top ten" against the spec's "maximum 10", and the heuristic framing at `status`/`epics` recorded as an inline change above.

**Retro**: [Criteria gap] A criterion written for nine sites assumed nine sites of the same shape. Seven of the nine only *might* produce an artifact, so "if you cannot write the justification, it has not earned its place" is a live gate there — but at `status` and `epics` the artifact is the section's entire purpose, already decided by the spec, and the same sentence reads as reopening it. The mismatch was invisible in the criterion, invisible to a verbatim-string test, and only surfaced on the end-to-end read. A criterion that applies one sentence across N sites should name the shape it assumes those sites have, so the sites that do not fit are found at breakdown rather than at the gate. This is the second consecutive epic where a criterion phrased once and applied to several skills failed at the skills whose shape differed (see retro 16's first observation).

---
