# Retro: Red-first evidence

**Date**: 2026-10-30  
**Source**: docs/epics/47-01-epic-red-first-evidence.md  
**Stories**: 4/4 complete

## Summary

Four prose changes to `do`, `plan`, the auditor and the contract. Story 4 passed on its second audit; Stories 1 to 3 needed four rounds, and Story 1 closed with its last fix unaudited at the user's decision.

## Observations

### Testing Gaps

- The revert method for a recorded red went through four rounds, each finding a data-loss path in the previous wording (copy after undo, a copy overwritten, a stale copy restored, a scratch directory a resumed session cannot find): a rule that tells a builder to change uncommitted files and put them back has to state the order, the copy's lifetime and where the copy is written down, in the first draft. **Recurrence**: docs/library/01-library-lessons-learned.md → "A control mutation needs a revert that cannot take the tree with it"

### Criteria Gaps

- A criterion that names a mapping with no tag to key it on (`static`) could not be applied by the check it fed, and the criterion had to be amended after the audit: when a criterion defines a vocabulary, say what each term is keyed to.
- A criterion promised that `do` and the auditor would follow a lesson, while its tasks edited only `plan` and the contract: check that each criterion's tasks name the file that carries the behaviour.

### Codebase Discoveries

- An agent receives only its own file as a prompt and cannot resolve "this agent's directory"; anything it must read outside its prompt has to be passed in by the caller as a path.

## Recommendations

- Audit a prose rule with the question "what does a reader who is not the writer do with this sentence, in a fresh session?" before the first audit.
