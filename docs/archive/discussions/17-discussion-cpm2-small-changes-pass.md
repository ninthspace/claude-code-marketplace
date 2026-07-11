# Discussion: cpm2 small-changes pass

**Date**: 2026-04-25
**Agents**: Jordan (PM), Margot (Architect), Bella (Dev), Priya (UX), Tomas (QA), Casey (Test), Sable (DevOps), Elli (Writer), Ren (Scrum Master)

## Discussion Highlights

### Key points so far

**Issues 1–7**: Gate Presentation / Mid-epic stops / Default to automation / (4 parked) / Tool Operations / State Management extraction / Retro consumption loop. All done.

**Issue 8 — Pivot clarity + tension with retros + mid-execution changes (DONE)**:

- `## Change Type Decision` shared convention added; mid-execution Guidelines entry in `cpm2:do`; pivot Step 5 retro handoff; retro Step 4 pivot handoff scan. Cross-link triangle complete.

**Consistency Audit (DONE)**: Cross-skill audit ran after Issue 8 completion. Two findings, both fixed:

1. **DRIFT — Section ordering in shared conventions**: `## Change Type Decision` was placed before Numbering. Reordered to canonical sequence: Progress File Management → Numbering → Change Type Decision → Tool Operations → Gate Presentation. Verified via heading list.
2. **MISSING — `cpm2:brief` Retro Check refactoring**: brief was the lone holdout still using inline retro discovery logic. Refactored to "Follow the shared **Retro Awareness** procedure" + per-skill incorporation block (patterns→Phase 2, codebase→Phase 6, scope→Phase 5, criteria→Phase 4).

**Audit cleared everything else**: Progress File Management referenced consistently across all 16 affected skills; Gate Presentation referenced cleanly in 7 skills with no logic duplication; Change Type Decision cross-link triangle (do→pivot→retro→pivot) intact; inline-edit breadcrumb format matches between shared convention and `cpm2:do` Guidelines; Tool Operations semantic framing has no stragglers; Numbering procedure has no inline duplication; Retro Awareness covered by all 9 consumer skills (do, epics, spec, pivot, architect, discover, quick, review, brief).

### Detailed issue log

**Issue 1 — Gate Presentation (DONE)**:

- Diagnosis: `AskUserQuestion` preview panel was being overloaded with whole documents and planning alternatives — content didn't fit and couldn't be read.
- Move: Added `## Gate Presentation` shared convention. The gate carries only the decision; long content (drafts, ADRs, spec sections, options lists) renders in the message body before the `AskUserQuestion` call.
- Applied in: `cpm2:epics` (3 sites), `cpm2:spec` (Section 7 Review), `cpm2:retro`.

**Issue 2 — Mid-epic stops (DONE)**:

- Diagnosis: `continue/stop/commit` prompts were appearing far more often than intended, breaking the work loop.
- Move: Added `No unauthorised checkpoints` + `Forbidden phrasings` Guidelines to `cpm2:do`. Added `Loop without prompting` callout in Step 7. The model is no longer free to insert checkpoint gates that aren't part of the skill's defined flow.

**Issue 3 — Default to automation (DONE)**:

- Diagnosis: Stories were defaulting to `[manual]` testing because automation took more thought to specify. Manual should be the justified exception, not the lazy default.
- Move: Reworded `cpm2:epics` Step 3 line and `cpm2:spec` Section 6b. New `Default to automation` Guidelines entry in epics with explicit automatable/manual category lists. Added a tag distribution summary block in Step 3 stories render so the bias toward `[manual]` is visible.

**Issue 4 — Test sub-agent delegation (PARKED)**:

- Question: Is it useful or appropriate to delegate automated test writing to a sub-agent?
- Outcome: Parked for a future pass. Open question.

**Issue 5 — Tool Operations (DONE)**:

- Diagnosis: Skill text used `Glob` / `Grep` as if they were specific tools. Newer Claude Code defaults (bfs, ugrep) and project `CLAUDE.md` preferences (fff, ripgrep) created friction.
- Move: Added `## Tool Operations` shared convention. `Glob` and `Grep` are semantic operations meaning "find files matching a pattern" and "search file contents for a pattern" — use whichever tool the harness provides. Project `CLAUDE.md` preferences win over the convention's vocabulary. No skill rewrites needed.

**Issue 6 — Refactoring State Management (DONE)**:

- Diagnosis: `## State Management` was being restated near-verbatim in 16+ skills, producing drift and obscuring the shared contract.
- Move: Added `## Progress File Management` shared convention (path resolution, session-ID handling, resume adoption, companion compact summary cleanup, write semantics, late-deletion rule). Each skill's `## State Management` section now references the shared procedure and only declares its own per-skill Lifecycle and Format. Affected skills: `do`, `epics`, `spec`, `retro`, `architect`, `archive`, `brief`, `consult`, `discover`, `library`, `party`, `present`, `quick`, `ralph`, `review`, `pivot`.

**Issue 7 — Retros consumption loop (DONE)**:

- Diagnosis: Retros were being generated and then left hanging — no skill incorporated them into its inputs. Per-epic and per-quick capture was correct (with a small fix needed for `cpm2:quick`); the gap was on the consumption side.
- Move: Added `## Retro Awareness` shared convention. Each consumer skill now has a Retro Check section that references the shared procedure plus a per-skill **Retro incorporation** block listing which retro categories matter to this skill and what concrete actions they trigger. Consumer skills with Retro Check: `do`, `spec`, `epics`, `discover`, `architect`, `quick`, `pivot`, `review`. (`brief` was the known holdout — closed in the consistency audit at the end of the session.)

**Issue 8 — Pivot clarity + tension with retros + mid-execution changes (DONE)**:

- Diagnosis: Three change-types (inline edit / pivot / retro) had unclear boundaries. Pivot detection happened post-hoc at epic-level verification. Inline edits left no trail. Pivot and retro didn't cross-link.
- Four moves approved by Chris, all executed:
  1. **`## Change Type Decision` shared convention** added to `cpm2/shared/skill-conventions.md` (between Numbering and Tool Operations) — single source of truth for the decision matrix (inline / pivot / retro / both), the "when in doubt, choose pivot" bias, and the inline-edit breadcrumb format.
  2. **Mid-execution change Guidelines entry** in `cpm2/skills/do/SKILL.md` — instructs the agent to surface change moments explicitly via AskUserQuestion gate with the four labelled options. Each option specifies its concrete action (inline edit triggers breadcrumb; pivot pauses work loop; retro defers to Step 6 Part B; both = combined).
  3. **Inline-edit breadcrumb requirement** is part of the same Guidelines entry — `**Inline change**: {summary} ({date})` field is mandatory when an inline edit is chosen.
  4. **Cross-link pivot ↔ retro**:
     - `cpm2:pivot` Step 5 (new): offers retro handoff at end of pivot workflow.
     - `cpm2:retro` Step 4 (updated): scans synthesised observations for scope-affecting categories (criteria gaps / scope surprises / codebase discoveries) and conditionally surfaces a pivot handoff option alongside the regular pipeline options.

### Outstanding follow-ups

- Issue 4 (sub-agent test delegation) parked — open for a future session.
- `cpm2:archive` Signal 3 should also handle quick sources — noted, not applied.
- `cpm2:status` should suggest retros for completed quick records — noted, not applied.

### Active thread
Consistency audit complete. All revisions consistent within and across skills and shared documents. Committed as `2d1d497` on `main`; pushed to `origin/main`. Versions bumped: cpm2 v0.0.1 → v0.0.2, marketplace v2.3.0 → v2.3.1.
