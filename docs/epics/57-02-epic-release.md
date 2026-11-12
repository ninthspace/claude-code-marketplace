# Release 0.19.0

**Source spec**: docs/specifications/57-spec-unattended-audit-rounds.md  
**Date**: 2026-11-12  
**Status**: Complete  
**Blocked by**: Epic 57-01-epic-audit-rounds  
**Amended**: review 14 (docs/reviews/14-review-unattended-audit-rounds.md) — the places that describe the audit, resume, unattended runs and **Changed** listed in full, with a wider search, a positive floor per place and a length cap on the presentation's SVG line; the new README text read against step 5; the maintenance record gains the rounds location (2026-11-12)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 1), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (build)

**Base.** `{base}` is `1493fb6` for every file.

## Docs and versions
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR7, NFR2, NFR4  
**Signal**: fix-not-carried-through — project — the docs gained the audit count and the Found stories at some places that describe **Changed** and **Found** and not at their neighbours (the presentation's headings note), and the README stated Found's stories more broadly than the skill (`cpm-next/README.md:113`, `cpm-next-presentation.html:670`, audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (a change made at one place and not the places beside it)  
**Test run**: 2 (2 full, 0 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 177 passed, 0 failed — tree f346225bf8f229ac4e8bcf2eab255517e47d782c — closes epic; untested: the three guides, plugin.json, marketplace.json — cpm-next-training-guide.html → deferred full run; cpm-next-onboarding.html → deferred full run; cpm-next-presentation.html → deferred full run; cpm-next/.claude-plugin/plugin.json → deferred full run; .claude-plugin/marketplace.json → deferred full run  
**Audit**: pass (2026-11-12), 2 findings fixed

**Acceptance Criteria**:

- `cpm-next/.claude-plugin/plugin.json` and cpm-next's entry in `.claude-plugin/marketplace.json` read `0.19.0`, and `git diff {base} -- .claude-plugin/marketplace.json` shows that one version line changed and no other `"version"` line `[manual]`
  - Evidence: `plugin.json:4` and cpm-next's `marketplace.json` entry read `"version": "0.19.0"`; `git diff 1493fb6 -- .claude-plugin/marketplace.json` shows one `-`/`+` pair, cpm-next's `"version"`, and no other `"version"` line — red: n/a — manual
- `cpm-next/README.md` gains a `(0.19.0)` bullet under **Additions** for the rounds, their stops and their record, a Size bullet giving `wc -w` over `do/SKILL.md` at `{base}` and now, and an **Upgrading to 0.19.0** note that names the record directory and that story timings grow for unattended stories with long fix chains. Floor: every **Additions** bullet at `{base}` is still there `[manual]`
  - Evidence: **More audit rounds when unattended** (`cpm-next/README.md:113`, `(0.19.0)`): the caps, the stops, whole-story audits, the record and the visibility; **Size** (`:114`): `wc -w` over `do/SKILL.md` 7,287 at 1493fb6 and 7,989 now; **Upgrading to 0.19.0** (`:157`) names `{git common dir}/cpm-next/rounds/` and says story timings grow with the extra Opus audits and fix rounds. Floor: all 79 **Additions** bullets at `1493fb6` match a line verbatim — red: n/a — manual
- Every place outside the skill files that describes the rounds, the later audit's inputs, resume, unattended runs, blocked stories or **Changed** describes the new rule, each read against step 5: root `README.md:93`; `cpm-next-training-guide.html:487`, `:1038`, `:1111-1113`, `:1119`, `:1166-1167` and `:1200`; `cpm-next-onboarding.html:497` and `:524-535`; `cpm-next-presentation.html:498` (SVG `<text>`), `:507` and `:633`; and the new `(0.19.0)` bullet and **Upgrading to 0.19.0** note in `cpm-next/README.md`. The search for others is `grep -n -i "third\|fourth\|second audit\|scoped to\|dismissed\|unattended\|won't be watching\|Changed\|Resumes"` over the four docs, each hit read and updated or accounted for in the `Evidence` line. Floor: each listed place in the three guides and `README.md:93` that states the cap names both `five` and `unattended`; the presentation's `:498` text stays within 60 characters, its length at `{base}`. `grep -c -i "never a fourth"` over the three guides gives 0, the attended cap being said another way on purpose `[manual]`
  - Evidence: updated, each read against **Audit rounds**: `README.md:93`; training guide `:487` (blocked after the last round), `:1038` (the count carried on resume), `:1111` (every earlier dismissal, the latest fix's files), `:1112-1113` (How many rounds, The round record), `:1120` (auditor directories numbered by round), `:1168` (unattended rounds), `:1201` (Changed's audit count), `:1202` (Found's stories at four or five audits or stopped); onboarding `:497` and `:535`; presentation `:498` ("Attended: third after a Critical. Unattended: five.", 51 characters), `:507`, `:633`, `:670` (the headings note: Changed's audit count, Found's stories); and `cpm-next/README.md:113`, `:157`. The search's other hits read and accounted for: none describes the rounds, an audit's inputs, or what **Changed** or **Found** holds (test runs, the effort hold, agents, unattended `[user]` handling, the Test run field, the progress mod; onboarding `:501` only names the headings). Floor: `README.md:93`, training `:1112` and `:1168`, onboarding `:497`, presentation `:498`, `:507` and `:633` each name `five` and `unattended` (`grep -ci`; onboarding `:535` says "five … when unattended"); `grep -c -i "never a fourth"` over the three guides 0 each — red: n/a — manual
- `docs/maintenance/README.md`'s **Scratch location** bullet adds the round records' location, `{git common dir}/cpm-next/rounds/`, and that the commit guard and the restore step read only `scratch/`, so the records must not move under it. Floor: `git diff {base} -U0 -- docs/maintenance/README.md` touches that bullet only `[manual]`
  - Evidence: **Scratch location** (`docs/maintenance/README.md:96`) adds the round records' location with their own `tree` file, and that the commit guard and the restore step read only `scratch/`, so the records must not move under it; `git diff 1493fb6 -U0` has one hunk, `@@ -96 +96 @@` — red: n/a — manual
- The three HTML guides pass the tag-balance check with Python's `html.parser` (void elements not pushed, an end tag must match the open tag on top, mismatches and tags left open each 0). Control: a copy of a guide with one `</p>` removed gives at least one `[manual]`
  - Evidence: the `html.parser` checker (`run56/tagcheck.py`) gives mismatches 0 and open 0 for each guide; control: onboarding with its first `</p>` removed gives 5 mismatches and 6 open — red: n/a — manual
- `claude plugin validate cpm-next` and `claude plugin validate .` pass, and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next `[manual]`
  - Evidence: both print "✔ Validation passed"; `claude plugin test`: cpm-next 15, cpm-next-models 20, cpm-next-progress 108, whats-next 34, 0 fail — red: n/a — manual

### Write docs and versions
**Task**: 1.1  
**Description**: Edit the READMEs, the three HTML guides and the version files.  
**Status**: Complete

---
