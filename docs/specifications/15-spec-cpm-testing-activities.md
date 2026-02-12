# Spec: CPM Testing Activities

**Date**: 2026-02-12

## Problem Summary

The CPM plugin's testing capabilities are implicit and scattered across skills. Verification gates in `cpm:do` self-assess acceptance criteria by reading code rather than executing tests. Acceptance criteria in epic docs aren't annotated with test approaches. There's no structured testing thread flowing from spec through epics to execution. The result: testing is an afterthought rather than a first-class activity in the planning and execution pipeline. This spec amends five existing skills to make testing activities integral to specifying acceptance criteria (with testability and approach annotations) and confirming them (by actually writing and running tests).

## Functional Requirements

### Must Have

1. **`cpm:spec` Section 6 enhancement — Test approach per acceptance criterion.** Each must-have functional requirement's acceptance criteria specify how they'll be verified: `[unit]`, `[integration]`, `[feature]`, or `[manual]`. Section 6 flags criteria without a test approach as incomplete rather than merely flagging vague criteria.

2. **`cpm:epics` — Testing annotations on stories.** Story acceptance criteria in epic docs carry inline test approach tags propagated from the spec's testing strategy. Tags use the same vocabulary: `[unit]`, `[integration]`, `[feature]`, `[manual]`.

3. **`cpm:do` — Execute tests during verification gates.** Verification gates run the project's test suite (or relevant subset) and report pass/fail against acceptance criteria. When criteria are tagged `[unit]`, `[integration]`, or `[feature]`, the gate runs the discovered test command. When all criteria are `[manual]`, the gate performs the existing self-assessment approach.

4. **`cpm:do` — Write tests as part of implementation.** When a story includes a generated testing task, `cpm:do` treats it as implementation work — writing test files that cover the story's acceptance criteria. The verification gate then runs these tests.

5. **Testing thread through the pipeline.** Spec defines what to test and how (Section 6) → Epics embed test approach tags on criteria and include testing tasks → Do writes tests and runs them during verification. Each stage traces to the one before it.

6. **`cpm:spec` Section 6 — Test infrastructure requirements.** Section 6 captures any testing infrastructure the project needs (test frameworks, test databases, fixtures, CI considerations). These become stories in `cpm:epics` if the infrastructure doesn't already exist.

7. **`cpm:do` — Test runner discovery.** At work loop startup (after library check, before first task), `cpm:do` discovers the test command. Priority: (1) library documents with testing instructions scoped to `do`, (2) project config files (`composer.json` scripts.test, `package.json` scripts.test, `Makefile` test target, `pyproject.toml`, etc.), (3) ask the user. The discovered command is cached in the progress file and reused for all verification gates in the session.

8. **`cpm:review` — Test coverage as a review dimension.** `cpm:review` checks whether stories have appropriate test approach tags and whether testing tasks exist for stories with `[unit]`, `[integration]`, or `[feature]` criteria. Flags gaps as a new concern type: "Missing test coverage".

9. **`cpm:epics` — Dedicated integration testing stories.** For epics with significant cross-story integration (identified from the spec's integration boundaries or from the nature of the work), `cpm:epics` creates a dedicated integration testing story. This story is blocked by the implementation stories it validates, has its own acceptance criteria about cross-story behaviour, and is distinct from per-story testing tasks.

10. **`cpm:retro` — "Testing gap" observation category.** Add "Testing gap" to the observation categories in `cpm:retro`: when tests revealed issues that acceptance criteria didn't anticipate, or when the testing approach for a criterion proved inadequate.

### Could Have

11. **TDD workflow support in `cpm:do`.** When a story's testing task precedes implementation tasks in the epic doc ordering, `cpm:do` respects that sequence — writing tests first, then implementing to pass them. `cpm:epics` can optionally place testing tasks before implementation tasks when the user or spec indicates a test-first approach. Opt-in per story, not globally enforced.

### Won't Have (this iteration)

- CI/CD pipeline generation or configuration
- Code coverage metrics or thresholds
- Visual/screenshot testing support
- Performance/load testing strategy
- Test report artifact generation
- Changes to `cpm:architect`, `cpm:brief`, `cpm:discover`, `cpm:party`, `cpm:pivot`, `cpm:archive`, `cpm:library`, `cpm:templates`, `cpm:present`

## Non-Functional Requirements

### Backward Compatibility
Updated skills continue to work with existing epic docs and specs that lack test approach tags. When tags are absent, skills fall back to current behaviour — self-assessment verification, no testing tasks generated. No existing artifact format is broken; tags are additive.

### Consistency
Test approach tags use a single vocabulary across all skills: `[unit]`, `[integration]`, `[feature]`, `[manual]`. Defined in `cpm:spec` Section 6, referenced by `cpm:epics`, `cpm:do`, and `cpm:review`. All testing-related additions follow existing structural patterns (state management, AskUserQuestion gating, graceful degradation, compaction resilience).

### Graceful Degradation
- No test runner discoverable → `cpm:do` verification gates fall back to self-assessment and report no runner found
- No test approach tags on criteria → `cpm:epics` and `cpm:do` treat the story as they do today
- Test command fails → `cpm:do` reports the failure and asks the user how to proceed

## Architecture Decisions

### Test Approach Tag Vocabulary and Placement
**Choice**: Inline tags on acceptance criteria lines. Four-tag vocabulary: `[unit]`, `[integration]`, `[feature]`, `[manual]`. Defined once in `cpm:spec` Section 6, referenced by downstream skills.
**Rationale**: Low-friction — doesn't change the acceptance criteria format structurally. Tags are readable in-place and parseable by downstream skills. Four tags map to test levels without framework-specific territory.
**Alternatives considered**: Separate `**Test Plan**:` field per story — rejected for ceremony overhead that would discourage adoption.

### Testing Task Generation in `cpm:epics`
**Choice**: Auto-generate a testing task within any story that has `[unit]`, `[integration]`, or `[feature]` criteria. Task titled "Write tests for {story title}", placed after implementation tasks (before them if TDD opted in). For integration-heavy epics, create a dedicated integration testing story blocked by the stories it validates.
**Rationale**: Automated generation ensures consistency — no story with automated test requirements can accidentally skip testing. Manual task creation was rejected because it's inconsistent and easy to forget.
**Alternatives considered**: Manual testing task creation by the user — rejected for inconsistency.

### Test Runner Discovery in `cpm:do`
**Choice**: Convention-based discovery once at work loop startup. Priority: (1) library documents scoped to `do` with testing instructions, (2) project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`, etc.), (3) ask the user. Cached in progress file.
**Rationale**: Mirrors existing discovery patterns (epic docs, library documents). Library documents are highest priority because they may contain project-specific testing conventions beyond just the command. Caching avoids re-discovery per verification gate.
**Alternatives considered**: Hardcoded test commands per framework — rejected for brittleness.

## Scope

### In Scope
- `cpm:spec` Section 6: test approach tags per criterion, test infrastructure requirements, enriched acceptance criteria mapping
- `cpm:epics`: tag propagation from spec, auto-generated testing tasks, dedicated integration testing stories
- `cpm:do`: test runner discovery, test execution in verification gates, testing tasks as implementation, cached test command in progress file
- `cpm:review`: test coverage as review dimension, "Missing test coverage" concern type
- `cpm:retro`: "Testing gap" observation category
- Spec output template: tag vocabulary reference and test infrastructure subsection
- Library document integration: project testing strategies discoverable via `docs/library/` with appropriate scope tags

### Out of Scope
- CI/CD pipeline generation or configuration
- Code coverage metrics, thresholds, or reporting
- Visual, screenshot, or performance testing
- Test report artifact generation
- Changes to `cpm:architect`, `cpm:brief`, `cpm:discover`, `cpm:party`, `cpm:pivot`, `cpm:archive`, `cpm:library`, `cpm:templates`, `cpm:present`
- Refactoring existing skill structures beyond targeted amendments
- New skill creation

### Deferred
- Test approach tags on ADRs (tagging architectural boundaries with suggested test levels)
- Spec-to-epic test coverage completeness report (verifying all spec test approaches are represented in epic stories)
- `cpm:do` parallel test execution or test filtering by tag

## Testing Strategy

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. Spec Section 6 — tags per criterion | Section 6 prompts for and records a test approach tag per must-have criterion | [manual] Run `cpm:spec`, verify Section 6 output |
| 2. Epics — testing annotations | Stories in epic docs have inline tags matching spec's testing strategy | [manual] Run `cpm:epics` against tagged spec, inspect output |
| 3. Do — execute tests | Verification gates run test command and report pass/fail | [manual] Run `cpm:do` on story with `[unit]` criteria, verify execution |
| 4. Do — write tests | Testing tasks produce test files | [manual] Run `cpm:do` on story with testing task, verify files created |
| 5. Pipeline thread | Tags flow spec → epics → do without loss | [manual] Trace tagged criterion through all three skills |
| 6. Spec — test infrastructure | Section 6 captures infrastructure needs | [manual] Run `cpm:spec`, verify infrastructure subsection |
| 7. Do — test runner discovery | Test command found from config and cached | [manual] Run `cpm:do` on project with test config |
| 8. Review — test coverage | Missing tags/tasks flagged as concerns | [manual] Run `cpm:review` against epic with gaps |
| 9. Epics — integration stories | Integration-heavy epics include testing story | [manual] Run `cpm:epics` on spec with integration boundaries |
| 10. Retro — testing gap | New observation category available | [manual] Inspect `cpm:retro` output |

### Integration Boundaries

- **Spec → Epics**: Tag vocabulary and testing strategy format in spec output must be parseable by `cpm:epics`
- **Epics → Do**: Tagged acceptance criteria and testing tasks in epic docs must be recognised during story hydration and verification
- **Do → Review**: `cpm:review` must assess test coverage from the same epic doc format `cpm:do` produces
- **Library → All skills**: Testing strategy library documents discoverable via existing library check mechanism with appropriate scope tags

### Unit Testing
This is a prompt-based plugin — each skill file is self-contained. "Unit testing" means verifying each skill amendment works in isolation by running the skill and checking its output against acceptance criteria. Handled at the `cpm:do` task level during implementation.
