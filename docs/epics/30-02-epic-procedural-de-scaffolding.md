# Procedural De-Scaffolding

**Source spec**: docs/specifications/30-spec-cpm2-post-switch-refinements.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: Epic 30-01

## Compress ralph Prompt Assembly and remove Permissions Check
**Story**: 1
**Status**: Complete
**Retro**: [Smooth delivery] Prompt Assembly compressed from 28 to 8 lines without touching the template itself. Permissions Check removal was clean — replacement note placed directly after Stop Hook Detection provides the same information in 2 lines instead of 16.
**Blocked by**: —
**Satisfies**: R3 — ralph Prompt Assembly compression, R4 — ralph Permissions Check removal

**Acceptance Criteria**:

- Prompt Assembly section in `cpm2/skills/ralph/SKILL.md` is ≤ 10 lines, names all interpolation variables, and states the plain-text / no-markdown constraint exactly once [manual]
- The interpolated ralph prompt produced by the compressed section is byte-identical for equivalent inputs to the prompt produced by the Spec-29 baseline (spot-check one realistic invocation — epic range, glob, max iterations, test runner, resume flag, task budget) [manual]
- Zero occurrences of "Permissions Check" section heading remain in `cpm2/skills/ralph/SKILL.md` [manual]
- A replacement note appears in the ralph startup flow explaining that permission denials pause the loop at runtime and that users can pre-add common Bash permissions (`Bash(git:*)`, `Bash(bash:*)`) to avoid stalls [manual]
- The replacement note references the Ralph Wiggum stop-hook resume pattern so readers understand how the loop recovers after a user grants a permission [manual]
- must NOT: no load-bearing ralph pre-flight step is removed beyond Permissions Check (Epic Discovery, Strip [plan] Tags, Stop Hook Detection all remain) [manual]

### Rewrite ralph Prompt Assembly section
**Task**: 1.1
**Description**: Replace the Prompt Assembly section in `cpm2/skills/ralph/SKILL.md` with a concise version: one sentence naming the plain-text / no-markdown / no-backticks constraint; a short list of interpolation variables (epic range, glob, max iterations, test runner, resume flag, task budget); and the template string. Remove restated reasons for the plain-text constraint and any duplicated variable documentation.
**Status**: Complete

### Remove ralph Permissions Check (Step 1d)
**Task**: 1.2
**Description**: Delete the Permissions Check section from `cpm2/skills/ralph/SKILL.md`. Renumber any following sub-steps if applicable. Add a one-paragraph replacement note in the startup flow (near Stop Hook Detection) explaining runtime pause behaviour and the optional pre-add step for common Bash permissions.
**Status**: Complete

### Verify ralph prompt output parity
**Task**: 1.3
**Description**: Construct one realistic ralph invocation scenario (e.g. epics 30-01 through 30-03, glob `docs/epics/30-*-epic-*.md`, max-iterations 50, test runner `composer test`, no resume, task budget 30) and confirm the interpolated prompt produced from the compressed Prompt Assembly is byte-identical to what the Spec-29 version would produce. Record the result in the task retro.
**Status**: Complete
**Retro**: [Smooth delivery] Template text is byte-identical between baseline (513656c) and current — diff produced zero output. The compression only removed surrounding instructional prose; the template and variable list were preserved verbatim.

---

## De-scaffold procedural recipes in do/spec/epics
**Story**: 2
**Status**: Complete
**Retro**: [Smooth delivery] All four de-scaffolding targets compressed without losing load-bearing rules. Verification gate rewrite (Task 2.4) was naturally completed alongside Test Execution (Task 2.1) since they were adjacent in the file.
**Blocked by**: —
**Satisfies**: R5 — Procedural de-scaffolding

**Acceptance Criteria**:

- `cpm2:do` Test Execution step is ≤ 3 sentences and covers both the tagged case (`[unit]` / `[integration]` / `[feature]` → run test command, interpret result) and the untagged / `[manual]` case (self-assess by code inspection) [manual]
- `cpm2:spec` test-approach tag propagation is ≤ 4 sentences and covers the three cases: propagate from spec when present, propose when story introduces new criteria, skip when spec has no Testing Strategy [manual]
- `cpm2:epics` Epic Filename Convention retains its parent-extraction rules (load-bearing) but the "integers, not strings" warning appears exactly once (down from three occurrences in the current file) [manual]
- `cpm2:do` verification gate uses outcome language ("verification loops without reducing failures") and routes the stalled case through AskUserQuestion (continue / mark as known issue / stop) [manual]
- No numeric threshold such as "2 times" or "3 times" remains in the `cpm2:do` verification gate [manual]
- must NOT: no load-bearing instruction disappears during de-scaffolding. Before-and-after cross-check against the Spec-29 baseline confirms parent-extraction rules, tagged-criteria semantics, must-NOT handling, and library-doc test-runner priority all survive [manual]

### Rewrite cpm2:do Test Execution step
**Task**: 2.1
**Description**: Replace the current 4-step Test Execution enumeration in `cpm2/skills/do/SKILL.md` (lines approx. 203–211 in the current file) with a 2–3 sentence outcome statement covering both tagged and untagged cases. Preserve the reference to the cached test command from Test Runner Discovery. Preserve the existing graceful-degradation path (test runner = none → fall back to self-assessment).
**Status**: Complete

### Rewrite cpm2:spec test-approach tag propagation
**Task**: 2.2
**Description**: Replace the current nested-conditional propagation guidance in `cpm2/skills/spec/SKILL.md` with a 3–4 sentence version covering propagate / propose / skip. Preserve the tag vocabulary (`[unit]`, `[integration]`, `[feature]`, `[manual]`, `[tdd]`) and the must-NOT confirmation gate from Spec 29.
**Status**: Complete

### Compress cpm2:epics Epic Filename Convention
**Task**: 2.3
**Description**: Edit `cpm2/skills/epics/SKILL.md` to remove duplicate "integers, not strings" warnings while keeping the parent-extraction rules (spec-id prefix, sub-number assignment, coverage companion naming). Leave one explicit statement of integer comparison — placed adjacent to the rule it protects — and delete the repetitions.
**Status**: Complete

### Rewrite cpm2:do verification gate to outcome language
**Task**: 2.4
**Description**: Replace the "If a fix-and-recheck cycle has run 2 times and criteria remain unmet, stop cycling" gate in `cpm2/skills/do/SKILL.md` with an outcome-based gate: if verification loops without reducing the count of failing criteria after a fix attempt, use AskUserQuestion to offer continue / mark as known issue / stop. Preserve the existing success path and the tie to acceptance criteria verification.
**Status**: Complete
**Retro**: [Smooth delivery] Already completed as part of Task 2.1 — the verification round limit was adjacent to the Test Execution step and both were rewritten in the same edit.

### Cross-check de-scaffolded sections against Spec-29 baseline
**Task**: 2.5
**Description**: For each of the four refactored sections (tasks 2.1–2.4), diff the current file against the Spec-29 baseline (commit 513656c) and confirm no load-bearing instruction was dropped. Record in the task retro any rules that survived, any that moved, and any judgement calls on what counted as ceremony vs. content.
**Status**: Complete
**Retro**: [Smooth delivery] All load-bearing rules survived: do — tagged/untagged criteria handling, test-command-none fallback, stalled-verification AskUserQuestion gate. spec — tag propagation downstream, propose/skip cases, must-NOT probing, flag-vague-criteria. epics — scoped glob, integer comparison, max+1 union, sub-number immutability. Ceremony removed: numbered step lists, redundant explanatory prose, repeated warnings, verbose examples.

## Lessons

### Smooth Deliveries

- Story 1: ralph Prompt Assembly compressed from 28 to 8 lines without touching the template; Permissions Check removal was clean — 2-line replacement note placed directly after Stop Hook Detection.
- Story 2: All four de-scaffolding targets compressed without losing load-bearing rules. Verification gate rewrite (Task 2.4) was naturally completed alongside Test Execution (Task 2.1) since they were adjacent in the file.

### Patterns Worth Reusing

- When de-scaffolding procedural recipes, diff against the baseline commit *before* starting work — this makes the "ceremony vs. content" judgement call explicit and auditable rather than relying on in-context assessment alone.
