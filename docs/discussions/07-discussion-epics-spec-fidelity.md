# Discussion: Improving spec-to-stories fidelity in /cpm:epics

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
