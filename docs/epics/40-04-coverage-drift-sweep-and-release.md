# Coverage Matrix: Drift Sweep and Release

**Source spec**: docs/specifications/40-spec-opus-5-alignment.md
**Epic**: docs/epics/40-04-epic-drift-sweep-and-release.md
**Date**: 2026-07-24

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | R10 — Drift sweep *(should)* | "Sweep the highest-density files back to positive prose" | "Genuine ALL-CAPS emphatic tokens are converted to plain prose" | Story 1 | `[manual]` | ✓ |
| 2 | R10 — Drift sweep *(should)* | "Under Opus 5's literalism, emphatic phrasing over-applies." | "Prohibition-stacked phrasing — repeated "never / do not / forbidden" reinforcing one rule — is reduced to a single plain statement per rule" | Story 1 | `[manual]` | ✓ |
| 3 | R10 — Drift sweep *(should)* | "Emphatic-language count in `do` and `skill-conventions` materially reduced" | "Emphatic-language count in `do` and `skill-conventions` materially reduced against the 2026-07-24 baseline (`do`: 55, `skill-conventions`: 56), with the reduction attributable to rewritten prose rather than removed rules" | Story 1 | `[manual]` | ✓ |
| 4 | R10 — Drift sweep *(should)* | "must NOT remove destructive-operation guards or no-overwrite rules; they become plain statements" | "must NOT remove destructive-operation guards or no-overwrite rules; they become plain statements" | Story 1 | `[manual]` | ✓ |
| 5 | R10 — Drift sweep *(should)* | "preserving genuine safety constraints (destructive-operation guards, no-overwrite rules) as plain statements" | "must NOT weaken any rule whose emphasis was carrying a genuine safety constraint" | Story 1 | `[manual]` | ✓ |
| 6 | R7 — Model identity | "Update the README's "v2 is tuned for Opus 4.7 and later" line" | "README's "v2 is tuned for Opus 4.7 and later" line (`README.md:114`) reflects Opus 5 and the v3 major version" | Story 2 | `[unit]` | ✓ |
| 7 | R7 — Model identity | "and the `.claude-plugin/plugin.json` description to reflect Opus 5" | "`.claude-plugin/plugin.json` description reflects Opus 5" | Story 2 | `[unit]` | ✓ |
| 8 | R7 — Model identity | "Bump the plugin version." | "Plugin version bumped from `2.9.1` to `3.0.0`" | Story 2 | `[unit]` | ✓ |
| 9 | Integration Boundaries — `plugin.json` ↔ hook tests | "`test-audit-skill.sh` asserts manifest fields. R7 touches the description and version, so the suite must be re-run." | "Hook suite green — `cpm/hooks/tests/run-all-tests.sh` passes, including `test-audit-skill.sh`'s manifest-field assertions" | Story 2 | `[unit]` | ✓ |
| 10 | R11 — Progress machinery *(could)* | "this requirement covers only whether the Stale-Progress Check needs to run as an early startup step in every `/cpm:*` skill, or whether a lighter trigger suffices" | "The Stale-Progress Check's early-startup-step trigger is reviewed against Opus 5's 1M default context and reduced compaction frequency" | Story 3 | `[manual]` | ✓ |
| 11 | R11 — Progress machinery *(could)* | "Stale-Progress Check trigger reviewed; no-change outcome acceptable and documented" | "The review's outcome is documented — whether the check stays an early startup step in every `/cpm:*` skill or moves to a lighter trigger" | Story 3 | `[manual]` | ✓ |
| 12 | R11 — Progress machinery *(could)* | "no-change outcome acceptable and documented" | "A no-change outcome is acceptable and recorded with its reasoning" | Story 3 | `[manual]` | ✓ |
| 13 | R11 — Progress machinery *(could)* | "The progress file remains correct and is not removed" | "must NOT remove the progress file itself — R11 covers the check's trigger only" | Story 3 | `[manual]` | ✓ |
| 14 | Token Efficiency NFR | "This pass should **reduce** net token count across `cpm/skills/*/SKILL.md` and `shared/`." | "Net token count across `cpm/skills/*/SKILL.md` and `shared/` is measured once, after the full change set lands — not per edit" | Story 4 | — | ✓ |
| 15 | Token Efficiency NFR | "Measure once at the end of the change set, not per edit." | "The measurement compares against a pre-change baseline and reports the net direction" | Story 4 | — | ✓ |
| 16 | — *(story-originated)* | — | "A net increase is reported rather than hidden" | Story 4 | — | ✓ |

## Notes

- **Row 3** — the spec's criterion is a count target, which is a weak proxy for prose quality. The baseline recorded in the epic doc shows the counts are dominated by lowercase `never`/`must` in ordinary positive prose, not by ALL-CAPS emphasis. The clause "attributable to rewritten prose rather than removed rules" is the guard against mechanically satisfying the count by deleting rules.
- **Row 6** — the criterion goes beyond the spec's text by including the v2 → v3 version prefix. That follows from Chris's decision on 2026-07-24 to bump to `3.0.0`; leaving "v2" would contradict the manifest.
- **Row 8** — `3.0.0` is not in the spec, which says only "Bump the plugin version." Chosen with Chris to signal R2's and R8's behavioural shifts.
- **Row 16** — story-originated; the NFR asks for a measurement but does not say what to do with an unfavourable result.
- **Rows 14–16** — trace to a non-functional requirement, so the spec's Acceptance Criteria Coverage table assigns them no tag.
