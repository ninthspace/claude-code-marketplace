# Discussion: Improving CPM execution quality — epics fidelity and quick fix mode

**Date**: 2026-02-25
**Agents**: Jordan, Margot, Bella, Tomas, Casey, Ren

## Discussion Highlights

### Key points so far
- User's core concern: autonomous modes (quick, do) produce structurally complete but sometimes incorrect work. Conversational mode (consult) catches gaps via human-in-the-loop feedback.
- Root cause identified: the spec-to-stories translation loses specificity. Specs have detail, but stories paraphrase loosely and don't verify coverage.
- Three improvements proposed and specced for `/cpm:epics` SKILL.md:
  1. **Criteria fidelity** (Step 3 amendment): acceptance criteria must preserve spec language verbatim — no generalising or softening specific thresholds/values/behaviours.
  2. **Testability standard** (Step 3 amendment): each criterion must describe an observable, verifiable outcome. Flag vague/subjective criteria for rewriting.
  3. **Coverage matrix** (new Step 3d): after all stories defined, build a table mapping every must-have spec requirement to covering stories. GAPs block confirmation until resolved.
- Implementation order: changes 2 & 3 first (improve criteria quality), then change 1 (validates completeness).
- All changes are modifications to `/cpm:epics` SKILL.md only — the spec skill already produces adequate structured output.

### Decisions
1. The fix is in `/cpm:epics`, not in `/cpm:spec` or `/cpm:do`
2. Coverage matrix gates Step 4 (Confirm) — gaps must be resolved before proceeding
3. Changes 2 & 3 are a single unit; change 1 is separate but depends on them

### Implementation spec

**Change 2 — Criteria fidelity (Step 3 amendment):**
- Location: Step 3, alongside existing "Spec traceability" paragraph (~line 83-87)
- Add rule: "When deriving acceptance criteria from a spec, use the spec's language verbatim where it provides specific thresholds, values, or behaviours. Do not generalise, paraphrase, or soften."

**Change 3 — Testability standard (Step 3 amendment):**
- Location: Step 3, after the traceability/fidelity rules
- Add paragraph: "Each acceptance criterion must be testable as written — it describes a specific observable outcome. Flag any criterion that relies on subjective judgement or cannot be verified through code, tests, or inspection."
- Include pass/fail examples: "Users can log in" fails. "User with valid credentials receives a 200 response with a session token" passes.

**Change 1 — Coverage matrix (new Step 3d):**
- Location: new step between current Step 3c (Integration Testing Story) and Step 4 (Confirm)
- Read source spec's "Must Have" functional requirements
- For each requirement, list which story's `**Satisfies**` field references it
- Present as a table: Spec Requirement | Covered by | Criteria match
- Any row with "GAP" is a blocker — user must add a story, extend an existing story, or explicitly defer
- Gates Step 4 confirmation — no unresolved gaps allowed

---

## Part 2: Fix Mode for /cpm:quick

### Key points
- `/cpm:quick` assumes you already know what to change — it's optimised for additions and modifications, not fixes
- Fixes start with a symptom, not a change description — they need diagnosis before a proposal
- The diagnostic feedback loop (investigate → hypothesise → confirm with user) is what makes `/cpm:consult` effective for fixes
- Diagnosis should only apply to fix-like inputs — additions don't benefit and it would add wasted ceremony
- Fix acceptance criteria need two categories: fix criteria (correct behaviour) and regression criteria (original bug is gone)

### Decisions
1. Adaptive Step 1 — classify input as fix or change using simple keyword heuristic, tell user which path, allow override
2. Step 1a (Diagnose) for fix path only — investigate root cause, present hypothesis, confirm with user before proposing
3. Fix-specific acceptance criteria — split into fix criteria + regression criteria in Step 2
4. No separate "fix mode" toggle — classification is automatic and correctable

### Implementation spec

**Input classification (top of Step 1):**
- Simple keyword heuristic: "fix", "broken", "doesn't work", "fails", "bug", "wrong", "error", "issue", "not working", "regression", or symptom language
- One-line signal to user: "This looks like a fix" / "This looks like a straightforward change"
- User can override immediately

**Step 1a: Diagnose (fix path only):**
- Reproduce/confirm symptom, form hypothesis, verify, present to user
- AskUserQuestion with Confirmed/Partially right/Wrong options
- Iterate until confirmed, then proceed to Step 1b (scope assessment)

**Fix-specific acceptance criteria (Step 2):**
- Fix criteria: the broken behaviour is resolved
- Regression criteria: the original bug cannot recur
- Regression criteria should map to test cases when test runner available
