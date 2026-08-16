---
title: Promoted Retro Lessons
source: docs/retros/ (promoted via /cpm:retro learn)
added: 2026-08-11
last-reviewed: 2026-08-13
scope:

  - do
summary: Durable lessons promoted out of the retro layer, where they had proved true across several epics rather than once. Each entry names the retro observation it came from; that observation is retired at source, so a lesson lives here or there and never in both.
---

## Reach for it before assuming the surface has it
**Promoted**: 2026-08-11  
**Source**: docs/retros/38-retro-skills-read-surface.md → Codebase Discoveries → "The surface refuses what it never anticipated, and refuses it quietly. `entityTools` drops nulls, so a waiver cannot be lifted and the refused clear reports success — the third story to hit that, carried since retro 36. `list_artifact_document` was scoped one way only. `artifact.url` and `published_at` are both `NOT NULL`. `review_agent` is kind-pinned to `review`. `document_kind` was neither readable nor listable. The shared `Perspectives` procedure loads a roster without `include_body` and renders voices off nothing. Every one was found by a consumer reaching for it; none by reading the schema."  
**Scope**: do

A tool surface, schema, or shared procedure will accept a call it was never designed for and
answer it wrongly without erroring. Every gap of this kind found in this project was found by a
consumer reaching for something; none came from reading the schema. Reading is not a substitute
for reaching.

- **Walk the reads before writing the consumer.** Call each read the new skill, migration or  
  client will need, and look at what comes back. It costs minutes; the alternative is a debugging  
  pass, and sometimes a shipped defect.
- **Expect the quiet refusal, not the loud one.** These failures do not throw. A dropped null  
  reports success. A one-way scope returns rows. A withheld column arrives as an absent field  
  rather than an error. Ask what a wrong answer would look like, and whether you could tell.

**A fix at the site is not a fix of the class.** This was recorded in three consecutive retros —
36, 38 and 39 — and each time repaired where it surfaced and nowhere else. Retro 38 named the
shared `Perspectives` procedure reading a roster without `include_body`; that was fixed, and the
23 skill files beside it were not, which is the defect epic 47-12 exists to close. When a surface
behaviour bites once, sweep every caller before closing it.

## Amendment — 2026-08-13 (via retro)

**Source**: docs/retros/42-retro-dpm-database-lifecycle.md  
**Category**: Criteria gaps

An absence can be delivered by something other than the mechanism under test. Before marking a
criterion of the form "X is not created / does not happen" as met, ask what else in the current state
of the tree would produce that absence — a crashed process, a sibling change, a fix that landed
elsewhere. Where the answer is "something else could", the criterion needs the mechanism named before
it can be verified.
