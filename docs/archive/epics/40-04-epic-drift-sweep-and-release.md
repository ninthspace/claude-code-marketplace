# Drift Sweep and Release

**Source spec**: docs/specifications/40-spec-opus-5-alignment.md
**Date**: 2026-07-24
**Status**: Complete
**Blocked by**: Epic 40-02-epic-execution-skill-behaviour, Epic 40-03-epic-review-skill-reshaping
**Retro applied**: 11 · Codebase discovery · Applied — Story 1's sweep runs per-instance rather than per-rule: after rewording a rule, check the surrounding section intro and list lead-in for a restatement of the same emphasis.
**Retro applied**: 12 · Codebase discovery · Applied — every emphatic token in Story 1 is classified by what its rule does before rewording; the two must-NOT criteria are the classifier, not the grep hit.
**Retro applied**: 13 · Codebase discovery · Applied — Story 2 greps for every occurrence of the version string and model identity before editing, rather than trusting the epic's two named files.
**Retro applied**: 13 · Pattern worth reusing · Applied — Story 4's gate is treated as a real cross-epic integration check: measure after Story 1's sweep lands, and report direction rather than a bare number.

The finishing pass: the emphatic-language sweep (R10), the model identity bump and version (R7), the optional progress-machinery review (R11), and the end-of-change-set token measurement (Token Efficiency NFR). Blocked by 40-02 and 40-03 because the spec's Sequencing decision runs R10 last so it also catches emphatic language introduced during this pass.

**R10 baseline (2026-07-24)**, measured before breakdown so "materially reduced" has a reference point:

| File | Emphatic tokens | Composition |
|---|---|---|
| `cpm/skills/do/SKILL.md` | 55 | 21 `never`, 13 `must`, 5 `Never`, 3 `always`, 3 `Always`, 2 `must not`, 2 `Forbidden`, 1 each of `required`/`must NOT`/`important`/`forbidden`/`critical`/`MUST` |
| `cpm/shared/skill-conventions.md` | 56 | 30 `never`, 9 `must`, 6 `Never`, 4 `always`, 3 `Always`, 1 each of `required`/`must not`/`forbidden`/`critical`/`Ensure` |

Genuine ALL-CAPS is nearly absent — one `MUST`, one `must NOT`, two `Forbidden`. The bulk is lowercase `never`/`must` inside ordinary positive prose, plus `must NOT` clauses that are the spec's own acceptance-criteria vocabulary. A count target is therefore a weak proxy for prose quality: driving the number down mechanically would strip legitimate language. The third criterion keeps the spec's wording verbatim and adds "attributable to rewritten prose rather than removed rules" as the guard.

## Sweep emphatic language in `do` and `shared/skill-conventions.md`
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R10 *(should-have)* — Emphatic-language drift sweep

**Acceptance Criteria**:

- Genuine ALL-CAPS emphatic tokens are converted to plain prose [manual]
- Prohibition-stacked phrasing — repeated "never / do not / forbidden" reinforcing one rule — is reduced to a single plain statement per rule [manual]
- Emphatic-language count in `do` and `skill-conventions` materially reduced against the 2026-07-24 baseline (`do`: 55, `skill-conventions`: 56), with the reduction attributable to rewritten prose rather than removed rules [manual]
- must NOT remove destructive-operation guards or no-overwrite rules; they become plain statements [manual]
- must NOT weaken any rule whose emphasis was carrying a genuine safety constraint [manual]

### Sweep `shared/skill-conventions.md`
**Task**: 1.1
**Description**: Runs after 40-01's additions land so it also catches emphatic language introduced during this pass.
**Status**: Complete

### Sweep `do/SKILL.md`
**Task**: 1.2
**Description**: Same criteria for `do`, after 40-02's edits, for the same reason.
**Status**: Complete

**Retro**: [Pattern worth reusing] The count fell 82% (115 → 20) without a single rule being weakened, because nearly all the emphasis turned out to be *duplicate statements of rules already made elsewhere* — collapsing prohibition stacks, not softening language, is what an emphatic-language target actually buys.

**Verification outcome (2026-07-25)**: all five criteria met. Zero genuine ALL-CAPS remain (the one surviving `must-NOT` at `skill-conventions.md:293` is the artefact-field noun inside a quoted example, not emphasis). Criterion 3's guard is evidenced structurally rather than by the count alone: both files keep their exact line counts (493, 483) and heading counts (19, 33), and total words fell 176 of 16,907 — 1.0% — which is inconsistent with rules having been deleted. Three sentences were removed outright, each stating a rule that survives verbatim at another site (`Verification of your own work stays inline` heading; the Step 2 note-tail rule referenced from Step 6; the `Forbidden phrasings` example list kept at its single canonical home).

---

## Bump model identity and plugin version
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R7 — Model identity bump; Integration Boundaries — `plugin.json` ↔ hook tests

**Acceptance Criteria**:

- README's "v2 is tuned for Opus 4.7 and later" line (`README.md:114`) reflects Opus 5 and the v3 major version [unit]
- `.claude-plugin/plugin.json` description reflects Opus 5 [unit]
- Plugin version bumped from `2.9.1` to `3.0.0` [unit]
- Hook suite green — `cpm/hooks/tests/run-all-tests.sh` passes, including `test-audit-skill.sh`'s manifest-field assertions [unit]

**Inline change**: Three stale assertions in `cpm/hooks/tests/test-audit-skill.sh` repaired so criterion 4 could pass (2026-07-25). All three pre-dated spec 40 — the file was last touched at commit `cdfa750` ("Promote cpm2 → cpm (v2.0.0)") and both version assertions had been failing at every release since, including at `2.9.1` before this story began. `:35` `name: cpm:audit` → `name: audit` (stale since `be60304` dropped the prefix); `:53` hard-coded `2.0.0` → a semver-shape check; `:69` hard-coded `2.0.0` → an assertion that `marketplace.json` agrees with `plugin.json`. Chris chose the consistency form over re-pinning `3.0.0` so the assertions stop rotting at each bump. Test count unchanged at 23; suite now 23/23.

**Scope note (2026-07-25)**: the version string lives at **three** sites, not the two the epic named — `cpm/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json:46`, and the README section heading at `:108`, which read `(v2.9.0)` and was already stale by a patch against the manifest's `2.9.1`. All three updated. No criterion text changed, only the surface it applies to, so this is a scope note rather than an inline change.

*Decision (2026-07-24): major bump to `3.0.0`, chosen with Chris. R2's verification reduction and R8's finding change are behavioural shifts worth signalling, even though the backward-compatibility NFR keeps in-flight sessions working. The major bump also means the README's "v2" prefix becomes "v3", not just the model name.*

### Update the README model-identity line
**Task**: 2.1
**Description**: Covers criterion 1 — both the model name and the v2 → v3 version prefix.
**Status**: Complete

### Update the `plugin.json` description and version
**Task**: 2.2
**Description**: Covers criteria 2–3.
**Status**: Complete

**Retro**: [Testing gap] The suite this story was told to run had been red since v2.0.0 — two assertions pinned a literal version that every release since had invalidated — so a criterion phrased as "suite green" was unsatisfiable by the story's own work and only surfaced because the story happened to run the tests.

### Run the hook test suite for model identity bump
**Task**: 2.3
**Description**: Testing task for the `[unit]` criteria. The suite already exists, so this runs `run-all-tests.sh` rather than writing new tests — per the spec's Test Infrastructure section, "None required."
**Status**: Complete

---

## Review the Stale-Progress Check trigger
**Story**: 3
**Status**: Complete
**Blocked by**: —
**Satisfies**: R11 *(could-have)* — Progress-file machinery cost/benefit review

**Acceptance Criteria**:

- The Stale-Progress Check's early-startup-step trigger is reviewed against Opus 5's 1M default context and reduced compaction frequency [manual]
- The review's outcome is documented — whether the check stays an early startup step in every `/cpm:*` skill or moves to a lighter trigger [manual]
- A no-change outcome is acceptable and recorded with its reasoning [manual]
- must NOT remove the progress file itself — R11 covers the check's trigger only [manual]

**Review outcome (2026-07-25): no change.** The check stays an early startup step in all 20 `/cpm:*` skills. Four findings:

1. **The guard is already the lighter trigger R11 imagines.** `hooks/lib/cleancheck-guard.sh` gates on a per-session sentinel: the first `/cpm:*` skill of a session gets `RUN` and writes `docs/plans/.cpm-cleancheck-{session_id}`; every later skill gets `SKIP` and exits immediately. An autonomous ralph run gets `SUPPRESS` before any output. So the classifier and the presentation run **once per session**, not once per skill — what runs 20 times is one Bash call returning a token.
2. **Per-skill cost is one line.** 19 skills carry the single sentence "Follow the shared **Stale-Progress Check** procedure"; the ~25-line body lives once in `skill-conventions.md`, loaded at session start. There is no per-skill duplication available to remove.
3. **R11's premise does not reach this check.** R11 reasons from compaction frequency — 1M context, so less compaction, so less need for progress machinery. But this check's driver is not compaction: the section exists because a slash-command invocation "would otherwise steamroll the SessionStart hook's advisory output". Its subject is *other* sessions' orphaned files — from crashes, abandoned runs, `/clear`, `--resume` — whose likelihood is independent of how long this session's context lasts. A longer session is if anything more likely to be the one that encounters another session's orphan.
4. **Live evidence.** This session began with an orphaned `.cpm-compact-summary-02093cf5-….md` in `docs/plans/` belonging to a different session — precisely the artefact the check surfaces, still occurring under Opus 5.

Alternatives rejected: narrowing to progress-file-writing skills gains nothing (every pipeline skill writes one, and the files being surfaced belong to other sessions); moving it into the SessionStart hook alone reinstates the steamrolling problem it was built to solve.

Recorded in `cpm/shared/skill-conventions.md` beside the procedure, so the question is answered where it will next be asked. The progress file itself is untouched — R11 covers the trigger only.

### Review and document the Stale-Progress Check trigger
**Task**: 3.1
**Description**: Single task; the deliverable is the documented decision, whichever way it goes.
**Status**: Complete

**Retro**: [Codebase discovery] The requirement reasoned from compaction frequency about a check whose stated driver is a slash-command steamrolling the SessionStart hook — and the "lighter trigger" it asked us to consider was already implemented in `cleancheck-guard.sh`, so reading the machinery answered the question the premise had mis-aimed.

---

## Measure net token change across the change set
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Token Efficiency NFR

**Acceptance Criteria**:

- Net token count across `cpm/skills/*/SKILL.md` and `shared/` is measured once, after the full change set lands — not per edit [manual]
- The measurement compares against a pre-change baseline and reports the net direction [manual]
- A net increase is reported rather than hidden [manual]

*This story spans all four epics and serves the cross-story integration role for 40-04; no separate integration story is generated, which would only duplicate it.*

**Measurement (2026-07-25) — net direction: UP. The Token Efficiency NFR's "should reduce" is not met.**

Measured once, after Stories 1–3 landed. Scope: 22 files — `cpm/skills/*/SKILL.md` (20) and `cpm/shared/` (2). Baseline: the same paths at `be60304`, the commit immediately before spec 40's first epic.

| Metric | Baseline | Current | Delta | |
|---|---:|---:|---:|---:|
| Bytes | 467,842 | 475,995 | **+8,153** | +1.74% |
| Words | 69,385 | 70,728 | **+1,343** | +1.94% |
| Tokens *(est. bytes ÷ 4)* | ≈116,960 | ≈119,000 | **≈+2,040** | +1.7% |

Bytes and words are proxies — no tokeniser was run, so the token row is an estimate and is labelled as one.

**Where it came from:**

| File(s) | Δ words | Cause |
|---|---:|---|
| `shared/skill-conventions.md` | **+830** | 40-01's five convention additions and amendments (R1, R3, R4, R5, R9), plus Story 3's review note — net of Story 1's sweep, which took 55 words off this file on its own |
| `skills/review/SKILL.md` | **+283** | 40-03's new Step 2b/2c find-filter separation (R8) |
| 11 other skills | **+367** | one-line pointers to the new shared conventions (+24 to +54 each), plus R6's scope bullet in `quick` (+67) |
| `skills/do/SKILL.md` | **−137** | the only net reduction — R2's verification removal and Story 1's sweep, partly offset by R6's scope guideline |

**Assessment.** The drift sweep was the pass's only reducing operation and it worked — 95 emphatic tokens and 192 words out of the two densest files, with no rule removed. But five of spec 40's eleven requirements *add* text, and retro 11's "section + per-skill pointer" propagation shape multiplies each shared addition across every consuming skill. R10 alone was never going to offset R1/R3/R4/R5/R9 plus R8.

This is reported rather than gated: the NFR says the pass *should* reduce net tokens, and the epic's own task description fixed that reading in advance. The honest conclusion is that a spec which adds five conventions cannot also be a net token reduction, and pairing a sweep with additions in one pass makes the NFR unmeetable by construction — a planning-time observation, not an execution failure.

### Measure and report net token change
**Task**: 4.1
**Description**: Single task, deliberately last. The NFR says the pass "should reduce" net tokens, not must — so this reports the direction rather than gating on it.
**Status**: Complete

**Retro**: [Criteria gap] A "should reduce net tokens" NFR was attached to a pass whose other requirements add five shared conventions and a new review step — the target and the scope contradicted each other at planning time, and only the end-of-pass measurement could reveal it.

---
