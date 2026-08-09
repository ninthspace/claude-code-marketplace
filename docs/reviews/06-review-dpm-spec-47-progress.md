# Review: Spec 47 progress — epics 47-01 to 47-04

**Date**: 2026-08-09  
**Source**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Scope**: Epic — spec 47 and the four completed epics (47-01 substrate, 47-02 dump and restore, 47-03 server and spine tools, 47-04 projection, guard and merge), with a forward look at 47-05 to 47-09  
**Agents**: Jordan, Margot, Ren, Casey  
**Findings**: 6 (0 critical, 4 warnings, 2 suggestions)

## Summary

The build is in good health and pointed the right way: 147 of the 149 coverage rows in the four
completed epics are verified, 346 tests pass, `dependencies` is empty, and every Must and Should
requirement in the spec is bound to at least one epic — the only unbound labels are the two Could
Haves and the three Won't Haves. Nothing blocks Epic 47-05.

The concerns are all about *sequence* rather than correctness. AD6 designed M2 as a checkpoint at
which the architecture could be judged against real use before the expensive half of the build; M2
is complete and the checkpoint was not taken, leaving the only real-use test as the final story of
the final epic. Everything built so far is substrate whose only consumer is its own test suite, and
the four remaining skill epics repeat one conversion pattern twenty-two times with no evidence
about that pattern until partway through the first of them.

**Requested scope**: this was asked for as a lay-of-the-land check for showstoppers rather than a
critical review, and is written to that depth. There are no showstoppers.

## Findings

### Spec Compliance

- **[Warning]** 🔄 **Ren** · 📋 **Jordan**: The M2 checkpoint was reached and walked past.  
  → AD6 (`:171`): M2 is "the earliest point where the design can be judged against real use… If M2  
  turns out to invalidate a decision here, that is the moment to find out." M2 is complete — spine  
  tools (47-03) and projection (47-04 Stories 1–2). The real-use test, "Verify dpm holds its own  
  planning corpus", is **47-09 Story 6**: the last story of the last epic, behind 103 coverage rows  
  of skill conversion. The one deliberately-designed opportunity to invalidate a decision cheaply  
  now sits where invalidating it is most expensive. Nobody has planned anything through dpm.

### Architectural Risks

- **[Warning]** 🏗️ **Margot**: Everything built so far is substrate, and its only client is its own  
  test suite.  
  → 42 tools, 13 projection templates, a divergence guard and a merge tool, exercised exclusively  
  by tests written in the same sessions, by the same author, against the same mental model as the  
  code under test. AD10's conformance test guards the schema↔tool seam it was designed for, and  
  that guard holds. What nothing guards is tool↔*use* — whether the surface is the one a skill  
  actually needs when it tries to plan with it. That gap does not close by adding tests; it closes  
  by acquiring a consumer.

### Testability Concerns

- **[Warning]** 🧪 **Casey**: NFR1 is verified by nothing, and it is the requirement AD5 rests on.  
  → 47-01 matrix row 86 and 47-03 matrix row 1 are the same check under two wordings; both are  
  `[target]` and neither has been run. `dependencies: {}` in `dpm/package.json` is a proxy for half  
  of it. If a clean clone turns out to need a build step, AD5's choice of language is wrong and it  
  is wrong across all four completed epics. What closes it is one clean clone and one server start.

- **[Suggestion]** 🧪 **Casey**: `SUPPORTED_PROTOCOLS` in `src/server/mcp.js` has never met a real  
  MCP client.  
  → Every server test drives stdio from the test harness. Implementing the protocol layer in-repo  
  rather than taking a package was the right call for NFR1, and it means version negotiation is  
  asserted only against the code that wrote it.

### Dependency Risks

- **[Warning]** 🔄 **Ren**: 103 of the 123 remaining coverage rows are one repeated shape of work.  
  → Epics 47-06 to 47-09 are twenty-two skill conversions against a common pattern. If the pattern  
  is wrong it is wrong twenty-two times, and the first integration evidence arrives at 47-06 Story
  4. Treating 47-06 Story 1 (`spec`) as a spike — convert it, then stop and look before 47-07, 08
  and 09 are touched — costs one story and is the cheapest available place to find out.

- **[Suggestion]** 🔄 **Ren**: 47-05's `Blocked by` over-constraint is moot and still reads as live.  
  → The epic documents its own M3-behind-M4 milestone inversion at length. Epic 47-04 is now  
  Complete, so nothing is actually held back. A line recording that saves the next reader  
  re-deriving the whole argument.

## What is working

Recorded because a review that only lists concerns misrepresents the state of the work.

- 📋 **Jordan**: the requirement roll-up is honest. FR16 and FR17 are unbound because they are  
  Could Haves, FR18 to FR20 because they are Won't Haves. No Must or Should has been quietly bound  
  to a story that does not cover it.
- 🏗️ **Margot**: 47-05 Story 1 is titled "the remaining sixteen entity types" and its acceptance  
  criterion reads the table list from `sqlite_master` instead of from the title. The number in the  
  heading is decorative and structurally cannot produce a false pass — the pattern this spec keeps  
  asking for, applied without being asked.
- 🧪 **Casey**: the mutation passes are finding real defects rather than performing rigour. A  
  pre-commit hook that had never once run from a commit, and a merge repair that silently reordered  
  the committed dump for every future run, were both invisible to every other check in the suite.

## Remediation

**Path**: Mixed — the findings do not share a target. One standalone task (its epics are
Complete), two surgical epic edits, and no appended remediation story: the 47-06 finding has to
take effect *before* that epic's Story 1, which a story appended at the end cannot express.

| # | Finding | Severity | Task |
|---|---|---|---|
| 1 | M2's checkpoint was reached and walked past | warning | Recorded as an open decision in `47-05-epic-parity-and-search.md` Notes |
| 2 | Substrate has no consumer but its own test suite | warning | Folded into the same note — it is the same gap stated structurally |
| 3 | NFR1 is verified by nothing | warning | Task #113 — Verify NFR1 on a clean clone |
| 4 | 103 of 123 remaining rows repeat one pattern | warning | `47-06-epic-skills-spine.md` — Story 1 declared a spike with a stop-and-review gate before Story 2 |
| 6 | 47-05's `Blocked by` over-constraint is moot | suggestion | `47-05-epic-parity-and-search.md` Notes — recorded as satisfied by 47-04's completion |

Finding 5 (`SUPPORTED_PROTOCOLS` unverified against a real MCP client) is a suggestion and was
left as-is.
