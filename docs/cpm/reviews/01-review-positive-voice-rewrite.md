# Review: Positive Voice Rewrite

**Date**: 2026-04-18
**Source**: docs/epics/29-02-epic-positive-voice-rewrite.md
**Scope**: Epic
**Agents**: Elli, Jordan, Bella, Tomas
**Findings**: 7 (0 critical, 3 warnings, 4 suggestions)

## Summary

The epic delivered its core objective — ~180 negative instructions rewritten to positive form across all 18 SKILL.md files with consistent shared vocabulary. Coverage matrix is 5/5 verified. The main concerns are around acceptance criteria quality rather than implementation quality: preserved negatives lack explicit annotation markers, the token count criterion technically failed (waived at +0.23%), and Story 3 was a redundant verification pass that duplicated work already done by story-level gates.

## Findings

### Spec Compliance

- **[Warning]** 📝 **Elli**: Preserved negatives rely on contextual rationale, not explicit annotation.  
  → Story 3, criterion 1: The spec requires "preserved negatives annotated with load-bearing rationale." Seven negatives were preserved across 6 files, but none carry explicit inline annotations (e.g. a comment or parenthetical explaining *why* it was kept). The rationale is implicit — a reader familiar with the context can see they're descriptive, not instructive — but a grep-based audit can't distinguish them from missed rewrites. Future maintainers will re-triage these same 7 items without markers.

- **[Warning]** 📋 **Jordan**: Token count criterion technically failed and was waived.  
  → Story 3, criterion 3: Post-rewrite is 313,103 bytes vs 312,376 baseline (+727 bytes, +0.23%). The criterion says "has not increased" — a binary test that technically fails. The coverage matrix marks it ✓ despite the literal criterion not being met. The criterion should have included a tolerance (e.g. "has not increased by more than 1%").

### Testability Concerns

- **[Warning]** 🔍 **Tomas**: Acceptance criterion for preserved negatives is not machine-verifiable.  
  → Story 3, criterion 1: "Grep returns only entries with inline load-bearing rationale" conflates a machine-verifiable grep with a human judgement about rationale quality. The grep is automatable but the rationale assessment requires reading each match in context. The criterion should have separated the count check from the qualitative review, or specified what "inline rationale" looks like structurally.

- **[Suggestion]** 🔍 **Tomas**: No diff-based verification was performed for criterion 2.  
  → Story 3, criterion 2: "No net-new negative instructions introduced (diff comparison)" was verified by total remaining count (7, all pre-existing) rather than an actual `git diff`. Since changes weren't committed between stories, a proper diff comparison wasn't possible. The criterion should have specified when the baseline snapshot is taken.

### Scope Creep

- **[Suggestion]** 💻 **Bella**: Story 3 added no value — it was a redundant verification pass.  
  → Story 3: The retro itself notes "Verification was effectively done during Story 1 and 2 gate tasks — Story 3 was a formality." For bulk text transformation epics, the final verification should be folded into the last story's gate rather than split into its own story.

### Unclear Requirements

- **[Suggestion]** 📋 **Jordan**: Story scope estimates were significantly off, suggesting the initial audit methodology needs improvement.  
  → Story 2: The epic estimated 78 occurrences across 14 standalone skills. Actual count was 124 — a 59% undercount. The per-file estimates in Task 2.1 and 2.2 were all wrong, indicating the pre-epics audit used a narrower grep pattern than the implementation.

- **[Suggestion]** 📝 **Elli**: Graceful degradation phrasing varies by skill — consider a canonical form.  
  → Stories 1-2: The positive replacement for "Never block" uses skill-specific subjects ("The work loop always continues", "The discussion always continues", "The consultation always continues", etc.). The pattern is recognisable but a future consistency grep would need multiple patterns instead of one canonical phrase.

## Remediation

Autofix offered but declined. Warnings are informational for future epic design — the annotation marker warning (Elli) is not actionable because skill files are LLM prompts where annotations would become part of the instructions. The token count tolerance (Jordan) and criterion separability (Tomas) are acceptance criteria design lessons for future specs. 3 warnings remain as feed-forward context.
