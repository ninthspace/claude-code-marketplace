# Spec's writing steps gate before they record

**Date**: 2026-08-12  
**Status**: Complete

## Context

A `/dpm:spec` run reached Section 6, Step 6b, rendered its proposed criteria and tags, and ended the
turn instead of asking for approval. The skill's blanket rule at `:90` is **section**-granular —
*"Gate each section with `AskUserQuestion`"* — but Section 6 facilitates in `####` steps, so the rule
does not reach them. `architect:86`, `discover:61` and `brief:65` all carry *"one at a time, one gate
per turn, each with `AskUserQuestion`"*; `spec:227` had only the pacing half, *"Work through them one
at a time."*

A sweep of all 23 dpm skills found `spec` is the only one exposed to this: every other skill's gate
rule is at least as fine-grained as the units it facilitates (`epics` gates each *step*, `archive`
and `pivot` each *unit* or *change*, `architect`/`discover`/`brief` each *phase*), and `spec` is the
only skill with two depths of process structure — `### Section n` plus `#### Step na` — which is what
makes the gap possible at all.

Six `####` steps sit outside the blanket rule; three of them write rows. Quick execution was right
for it: two files, no new pattern, and the fix is a rule the file already states three sections
further up.

## Acceptance Criteria

**Fix criteria** (the broken behaviour is resolved):

- Step 6b names `AskUserQuestion` and gates each requirement's criteria and tags before the next  
  requirement is taken up `[unit]` — **Met**
- Steps 3a and 6c each name `AskUserQuestion` at the point they record `[unit]` — **Met**

**Regression criteria** (the original bug cannot recur):

- A `####` step that writes rows and names no `AskUserQuestion` is reported by name, derived from  
  the file's own headings rather than a transcribed list `[unit]` — **Met**
- The check is non-vacuous: it complains on a planted gateless step, and complains that the step  
  enumeration is empty when handed a source with no steps `[unit]` — **Met**

## Changes Made

- `dpm/skills/spec/SKILL.md` — the Process rule gains the step-level obligation (*"A step that  
  records rows carries its own gate… one item at a time, one gate per turn. A rendered proposal is  
  not an approved one, and a turn that ends on one has recorded nothing and asked nothing"*). Step 3a  
  gates its entries before recording them; Step 6b gates per requirement and its must-not probe now  
  rides that gate rather than standing as a question with no mechanism; Step 6c gates between  
  refining and recording. The blanket rule stays section-granular — widening it to steps would demand  
  a gate on 6d, which records nothing by design.
- `dpm/tests/skill-spec.test.js` — `ungated(source) → complaints` over the `####` steps parsed from  
  the file, keyed on whether the step writes rather than on its heading, with floors on both  
  enumerations. One new test.

## Verification

Suite run from the repo root — `node --test "dpm/**/*.test.js"` — 631 pass, 0 fail (630 before; the
new test is the +1). Running it from inside `dpm/` makes the glob match nothing and reports a silent
false pass, so the root is the only place the number means anything.

Three mutations driven, each reverted, each reaching one test and no others:

| mutation | result |
|---|---|
| Step 6b's gate sentence reverted to the original pacing-only wording | 1 fail — *"Step 6b: Give each requirement a criterion and a tag records rows and names no AskUserQuestion"* |
| Step 3a's gate removed | 1 fail — *"Step 3a: Environmental constraints records rows and names no AskUserQuestion"* |
| the heading parse changed from `^#### ` to `^##### ` | 1 fail — both floors: *"0 #### steps parsed, below the 6"* and *"0 of them record rows, below the 3"* |

The third is the one that matters most: with every writing step now gated, the live file cannot tell
a working per-step check from one whose parse silently matches nothing.

## Retro

**Pattern worth reusing**: keying the audit on what a step *does* — writes rows — rather than on
which steps a list names decided membership without my judgement, and grew the fix from the one step
reported to the three that share its shape; a rule naming the steps would have been a copy of the
file rather than a check on it, and would have left 3a and 6c to fail the same way later.
