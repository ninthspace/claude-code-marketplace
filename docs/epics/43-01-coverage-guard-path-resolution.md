# Coverage Matrix: Guard Path Resolution

**Source spec**: docs/specifications/43-spec-ralph-autonomous-stalls.md
**Epic**: docs/epics/43-01-epic-guard-path-resolution.md
**Date**: 2026-07-26

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR7 | `SUPPRESS` fires from a skill-issued invocation. | With `.claude/ralph-loop.local.md` present and `CLAUDE_PROJECT_DIR` unset, the guard invoked as `shared/skill-conventions.md` documents returns `SUPPRESS` | Story 4 | `[integration]` | ✓ |
| 2 | FR7 (must NOT) | must NOT export `CLAUDE_PROJECT_DIR` in that test — the unset case *is* the requirement | must NOT export `CLAUDE_PROJECT_DIR` in those cases — the unset case *is* the requirement | Story 4 | `[integration]` | ✓ |
| 3 | FR8 | `SKIP` fires from a skill-issued invocation. | Two guard calls, same `CPM_SESSION_ID`, `CLAUDE_PROJECT_DIR` unset → `RUN` then `SKIP` | Story 4 | `[integration]` | ✓ |
| 4 | FR9 | `/cpm:clean` enumerates real progress files. | With N progress files present and `CLAUDE_PROJECT_DIR` unset, `clean`'s documented invocation emits N records | Story 3 | `[integration]` | ✓ |
| 5 | FR9 (story-originated) | — | must NOT pass a path argument that an unset variable renders as a bare `/docs/plans` prefix | Story 3 | — | ✓ |
| 6 | FR10 | Tests exercise the skills' calling convention. | Every guard/classifier suite contains at least one case run with `CLAUDE_PROJECT_DIR` unset | Story 4 | `[integration]` | ✓ |
| 7 | FR10 (enabling) | Tests exercise the skills' calling convention. | `test-helpers.sh` provides a helper that runs a command with named environment variables **removed** from its environment, not set to empty | Story 1 | `[integration]` | ✓ |
| 8 | NFR1 | an unresolvable project root yields `SUPPRESS`, not `RUN`. The safety net is advisory (worst case: leftover files); a stalled loop is the defect being fixed. | An unresolvable project root yields `SUPPRESS` and a stderr warning naming the resolution attempt | Story 2 | `[integration]` | ✓ |
| 9 | NFR2 | any degraded path reports on stderr. Cause B was silent for months. | The resolved root is validated (exists, is a directory) and echoed to stderr | Story 2 | `[integration]` | ✓ |
| 9b | NFR4 | macOS and Linux, no new dependencies. | Resolution succeeds in a non-git directory by falling through to `$PWD`, and uses no command outside the shell already in use | Story 2 | — | ✓ |
| 10 | NFR3 | `session-start.sh:65`, `session-start-compact.sh:47` and `post-compact.sh` run in hook context where the variable is set. They are correct and stay untouched. | `session-start.sh`, `session-start-compact.sh` and `post-compact.sh` behaviour is unchanged — existing suites pass untouched | Story 5 | `[integration]` | ✓ |
| 11 | AD1 | helpers resolve their own root (`$CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `$PWD`), validate it, and echo it to stderr | `cleancheck-guard.sh` and `progress-classify.sh` each resolve their project root in the order `$CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `$PWD` | Story 2 | — | ✓ |
| 12 | AD1 | `RALPH_STATE` gains an argument override so tests can drive it directly | `RALPH_STATE` accepts an argument override | Story 2 | — | ✓ |

## Notes

Row 9's Spec Test Approach was empty when this matrix was first built — NFR2 was stated as a requirement in spec 43 and given no row in its Acceptance Criteria Coverage table. Surfaced by this matrix and corrected in the spec with an `**Inline change**` breadcrumb on 2026-07-26; the tag above reflects the amended spec.
