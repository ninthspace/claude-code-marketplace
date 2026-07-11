# Coverage Matrix: Ralph Prompt Rewrite

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Epic**: docs/epics/29-06-epic-ralph-prompt-rewrite.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R3 — Ralph prompt | Prompt uses only positive instructions (grep) | Prompt uses only positive instructions — zero occurrences of "Do NOT", "NEVER", "Don't" | Story 1 | `[manual]` | ✓ |
| 2 | R3 — Ralph prompt | Prompt defines "task complete" in testable terms | Prompt defines "task complete" as: all tagged criteria have passing test results AND all manual criteria have self-assessment lines in the progress file | Story 1 | `[manual]` | ✓ |
| 3 | R3 — Ralph prompt | Prompt defines "failure" for 3-strike skip | Prompt defines "failure" for the 3-strike skip rule as: a test command exit code ≠ 0 after a code change attempt (tool errors and permission denials are not failures) | Story 1 | `[manual]` | ✓ |
| 4 | R3 — Ralph prompt | Prompt includes task budget advisory | Prompt includes a task budget advisory derived from story size | Story 1 | `[manual]` | ✓ |
| 5 | R3 — Ralph prompt | Prompt includes fallback for ambiguous criteria | Prompt includes a fallback for ambiguous acceptance criteria: mark story "Blocked — criteria ambiguous" and continue | Story 1 | `[manual]` | ✓ |
| 6 | R3 — Ralph prompt | Passes all five Smart Ape migration questions | Prompt passes all five Smart Ape migration questions: explicit intent, success criteria, constraints, task budget + stop criteria, no negative-only instructions | Story 1 | `[manual]` | ✓ |
