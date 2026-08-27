# Coverage — skills that read and accept a reference

**Number**: 03-03  
**Source epic**: 03-03  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR4 | a convention governing what a skill says to a person: name a document by its reference and title, never by its id | `dpm/shared/skill-conventions.md` carries a section governing what a skill says to a person, distinct from Cross-References, stating both the reference-and-title rule and what a skill does when the reference is null. | Story 1 | `[integration]` | ✓ |
| 2 | FR5 | The *Recommended next steps* table in `dpm/skills/status/SKILL.md` recommends every command by reference rather than by id | No row of the status skill's *Recommended next steps* table interpolates a document id into a command. | Story 2 | `[integration]` | ✓ |
| 3 | FR5 | the four rows that interpolate `{epic id}`, `{spec id}` and `{brief id}` | control — The pattern the check uses, run against the status skill as it stands before this work, finds its four existing occurrences. A pattern that matches nothing passes against a corpus that still leaks, and nothing in the criterion above would say so. | Story 2 | `[integration]` | ✓ |
| 4 | FR6 | Every dpm skill that names a document in its conversational output names it by reference and title. | No skill file in the tree contains a placeholder interpolating a document id into a user-facing command or sentence. The corpus is enumerated by `everySkill()` reading the tree, never by a written list, so a skill added later is covered on the day it lands. | Story 2 | `[integration]` | ✓ |
| 5 | FR7 | accept a human reference as well as a ULID | Each of the seven skills' Input section states that a human reference is accepted alongside a ULID, and names `resolve_reference` — which the existing binding then holds to being a tool that exists. | Story 3 | `[integration]` | ✓ |
| 6 | FR7 | The seven skills whose argument contract reads *names a document id* — architect, brief, do, epics, review, retro and spec | must NOT — The seven must not be swept from the tree. They are a fixed set this spec chose, so a skill added later is not silently in scope and its absence from the list is a decision rather than an oversight. | Story 3 | `[integration]` | ✓ |
| 7 | FR7 | so a command a skill recommends is a command the receiving skill runs | A reference taken from a real document's tool output, substituted into the command the status skill's *Recommended next steps* table recommends, is accepted by the receiving skill's Input contract and resolves back to that same document. | Story 4 | `[integration]` | ✓ |
| 8 | FR18 | A document named inside a body, a plan, a decision or an observation is written `{{ref:<id>}}` | The convention section states the stored-prose rule — a document named inside a body is written `{{ref:<id>}}` — as well as the rule for what a skill says to a person. | Story 1 | `[integration]` | ✓ |
