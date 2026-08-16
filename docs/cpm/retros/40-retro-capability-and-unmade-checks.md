# Retro: Runtime Capability and Unmade Checks

**Date**: 2026-08-11  
**Source**: docs/epics/47-11-epic-capability-and-unmade-checks.md  
**Stories**: 3/3 complete

## Summary

Three guarantees the spec stated and nothing enforced: a capability check that did not exist, a
register that advertised a mechanism it did not have, and an adoption obligation on the corpus that
every suite passed by driving the tool directly. All three are now enforced. The through-line is
that each was **green before the work started** — none of them failed anywhere, which is what let
them stay unbuilt.

## Observations

### Scope Surprises

- **The epic named three skills to settle and the corpus held five.** `clean` and `publish` were  
  already exempt in their own words, so a check written to the three named would have been correct  
  about them and silent about the other two. When a story enumerates its subjects in prose, derive  
  the set from the live surface before writing the check and let a floor guard the count — the  
  enumeration in an acceptance criterion is a description of the problem, not a specification of it.

### Testing Gaps

- **A named limb can check the wrong place and read as passing.** Story 1's "the probe leaves  
  nothing behind" assertion read `sqlite_schema`, and the probe writes to `temp.`, which is not in  
  it. The mutation it was written for was caught by a *later* test instead. What makes the property  
  real is that the probe is repeatable on one connection — asserting that is what caught it. Where a  
  cleanup assertion names a location, check that the location is where the thing under test would  
  actually be.
- **A vacuous regex reads exactly like a working one.** Story 3's exempt-skill control used  
  `/\b(create_session|update_session)\b/`; the leading `\b` never matches, because skills write the  
  callable form and the character before the verb is an underscore. The check found nothing anywhere,  
  so every exemption passed by never being tested. Nothing about the pattern read as wrong — only a  
  planted control that *should* have failed exposed it.

### Patterns Worth Reusing

- **`audit(inputs) → complaints` instead of a run of assertions.** Extracting the reconciliation into  
  a function returning a complaint list let the controls drive the deliverable itself on planted  
  inputs, rather than restating its rules in a second place. A control that reimplements what it  
  guards tests the reimplementation — the same defect the story was closing, one level up. Reused  
  three times across these two epics and worth reaching for wherever a check has a must-NOT.

## Recommendations

- **Probe behaviourally rather than declaratively where the two differ.** Story 1 chose creating a  
  virtual table over `sqlite_compileoption_used` and `PRAGMA compile_options`, because both of those  
  report the compile flag and reach the capability only through the assumption that a flag set  
  implies a module registered. Check the assumption before designing around it.
- **Force a failure through a test-only seam, not a production override.** An env var the probe reads  
  would be a way to talk a real server out of its own safety check, added for a test's convenience.  
  A `--import` module hook rewrote `hasFts5` in the spawned process instead and left no production  
  surface behind.
- **Every derived enumeration needs a floor.** A parse matching no rows, a glob matching no skills,  
  and a registry yielding no tools each satisfy every per-item check by having no items. Three of  
  this epic's five must-NOTs were exactly this shape.
- **A citation resolves a name and cannot read what the test asserts.** Where a register cites tests,  
  mutation-check each conversion at its source and record it — the citation mechanism cannot close  
  that gap itself.
