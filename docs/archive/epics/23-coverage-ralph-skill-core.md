# Coverage Matrix: Ralph Skill Core

**Source spec**: docs/specifications/26-spec-cpm-ralph-integration.md
**Epic**: docs/epics/23-epic-ralph-skill-core.md
**Date**: 2026-04-01

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | 1. New skill | SKILL.md exists at `cpm/skills/ralph/SKILL.md` with valid frontmatter | SKILL.md exists at `cpm/skills/ralph/SKILL.md` with valid frontmatter (name, description, trigger) | Story 1 | `[manual]` | ✓ |
| 2 | 1. New skill | Skill appears in Claude Code's skill list when plugin is installed | Skill appears in Claude Code's skill list when plugin is installed | Story 1 | `[manual]` | ✓ |
| 3 | 2. Epic selection | Accepts explicit epic doc paths as arguments | Accepts explicit epic doc paths as arguments | Story 2 | `[feature]` | ✓ |
| 4 | 2. Epic selection | Auto-discovers incomplete epics when no args provided | Auto-discovers incomplete epics when no args provided | Story 2 | `[feature]` | ✓ |
| 5 | 2. Epic selection | Handles range-style epic references | Handles range-style epic references | Story 2 | `[feature]` | ✓ |
| 6 | 3. Prompt generation | Generated prompt calls `/cpm:do` with the correct epic list | Generated prompt calls `/cpm:do` with the correct epic list | Story 3 | `[manual]` | ✓ |
| 7 | 3. Prompt generation | Generated prompt includes autonomous behaviour instructions | Generated prompt includes autonomous behaviour instructions | Story 3 | `[manual]` | ✓ |
| 8 | 3. Prompt generation | Generated prompt includes completion promise wrapper | Generated prompt includes completion promise wrapper | Story 3 | `[manual]` | ✓ |
| 9 | 4. Autonomous decisions | Generated prompt instructs Claude not to use AskUserQuestion | Generated prompt instructs Claude not to use AskUserQuestion | Story 3 | `[manual]` | ✓ |
| 10 | 4. Autonomous decisions | Generated prompt specifies fallback behaviour for each gate type | Generated prompt specifies fallback behaviour for each gate type (test failures, unmet criteria, stuck tasks) | Story 3 | `[manual]` | ✓ |
| 11 | 5. Multi-epic transitions | Generated prompt instructs auto-continue to next epic | Generated prompt instructs auto-continue to next epic | Story 3 | `[manual]` | ✓ |
| 12 | 5. Multi-epic transitions | A Ralph loop completes multiple epics sequentially | A Ralph loop completes multiple epics sequentially | Story 3 | `[feature]` | ✓ |
| 13 | 6. Completion detection | Generated command includes `--completion-promise` flag | Generated command includes `--completion-promise` flag | Story 3 | `[manual]` | ✓ |
| 14 | 6. Completion detection | Generated prompt includes `<promise>` output at correct point | Generated prompt includes `<promise>` output at correct point | Story 3 | `[manual]` | ✓ |
| 15 | 7. Pre-flight validation | Skill fails fast if no incomplete epics found | Skill fails fast if no incomplete epics found | Story 1 | `[feature]` | ✓ |
| 16 | 7. Pre-flight validation | Skill warns if Ralph Wiggum plugin not detected | Skill warns if Ralph Wiggum plugin not detected | Story 1 | `[feature]` | ✓ |
| 17 | 7. Pre-flight validation | Skill discovers and reports test runner | Skill discovers and reports test runner | Story 1 | `[feature]` | ✓ |
| 18 | 8. Progress persistence | Generated prompt instructs execution log maintenance | Generated prompt instructs execution log maintenance | Story 5 | `[manual]` | ✓ |
| 19 | 8. Progress persistence | Epic doc status fields update correctly across Ralph iterations | Epic doc status fields update correctly across Ralph iterations | Story 5 | `[feature]` | ✓ |
| 20 | 9. Stuck detection | Generated prompt includes stuck threshold and skip logic | Generated prompt includes stuck threshold and skip logic | Story 3 | `[manual]` | ✓ |
| 21 | 9. Stuck detection | A stuck task is eventually skipped in a real Ralph loop | A stuck task is eventually skipped in a real Ralph loop | Story 3 | `[feature]` | ✓ |
| 22 | 10. Execution log | Generated prompt specifies log file path and append-only format | Generated prompt specifies log file path and append-only format | Story 3 | `[manual]` | ✓ |
| 23 | 10. Execution log | Log file is human-readable markdown after a real run | Log file is human-readable markdown after a real run | Story 3 | `[feature]` | ✓ |
| 24 | 11. Dry-run mode | Skill presents generated command without executing | Skill presents generated command without executing | Story 4 | `[feature]` | ✓ |
| 25 | 11. Dry-run mode | Output is copy-pasteable as a valid `/ralph-loop` command | Output is copy-pasteable as a valid `/ralph-loop` command | Story 4 | `[manual]` | ✓ |
| 26 | 12. Max iterations | Accepts `--max-iterations` argument | Accepts `--max-iterations` argument | Story 4 | `[feature]` | ✓ |
| 27 | 12. Max iterations | Default is applied when not specified | Default max iterations is applied when not specified | Story 4 | `[feature]` | ✓ |
| 28 | 13. Story filtering | Accepts story filters and includes them in generated prompt | Accepts story filters and includes them in generated prompt | Story 2 | `[feature]` | ✓ |
| 29 | 14. Notification | Generated prompt includes completion sentinel/output | Generated prompt includes completion sentinel/output | Story 3 | `[manual]` | ✓ |
| 30 | 15. Resume | Detects existing execution log and epic statuses from previous run | Detects existing execution log and epic statuses from previous run | Story 5 | `[feature]` | ✓ |
| 31 | 15. Resume | Adjusts generated prompt to continue from previous run's state | Adjusts generated prompt to continue from previous run's state | Story 5 | `[feature]` | ✓ |
| 32 | 16. Coupling notice | SKILL.md includes prominent maintenance coupling section | SKILL.md includes prominent maintenance coupling section | Story 6 | `[manual]` | ✓ |
| 33 | 16. Coupling notice | Notice lists specific `cpm:do` AskUserQuestion locations overridden by prompt template | Notice lists specific `cpm:do` AskUserQuestion locations overridden by prompt template | Story 6 | `[manual]` | ✓ |
