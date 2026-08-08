# Retro: dpm — Review and Pivot

**Date**: 2026-08-08  
**Source**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Stories**: 9 epics, 63 stories — none executed; six stories added by this cycle

## Summary

Review 05 ran retro 34's own recommendation — check the artefacts mechanically rather than
read them — across all nine epics, and the pivot applied every finding. The checks earned
their keep and also misled: a quarter of the initial hits were artefacts of the checker, and
one truncated run reported a clean pass it had never computed. The repair then produced the
defect class retro 34 had just finished warning about.

## Observations

### Criteria Gaps

- **FR26's must-NOT clause was covered by no story.** Retro 34's FR21 finding, one  
  requirement later and one layer down: the cascade that added FR26 reached its positive  
  clause and stopped. Retro 34 recommended asking which *side* of a new requirement the  
  cascade reached, and named producer and consumer; the side missed this time was the  
  negative one.
- **Two criteria in one epic could not both pass.** 47-03's matrix row 26 required every  
  table to appear in "exactly one tool's declared coverage"; Story 5's criterion said "at  
  least one". `document` is read by every kind's read tool and `taxonomy` by three, so  
  exactly-one was unsatisfiable. Neither line is wrong alone — the contradiction exists only  
  in the pair, and no check compares an epic's criteria against each other.
- **The fix created the remainder retro 34 warned about.** Six remediation stories, twelve  
  criteria, none of them bindable to a spec requirement — so the both-directions check that  
  found the original gaps now reported twelve new ones. Retro 34's "declare any intended  
  exception" was written about the breakdown; it applies to every repair that adds a story.

### Codebase Discoveries

- **Every `§n` line citation in the breakdown was stale.** 47-01's `§1234`, 47-04's `§202`  
  and `§195`, 47-05's `§332` — all moved by the spec's own pivot, all still resolving, all to  
  the wrong lines. FR28 exists in this spec because a stored number goes stale the moment a  
  merge renumbers its target. The documents specifying FR28 cited the spec by line number.
- **A dangling reference is at its safest while it stays dangling.** 47-02's matrix row 12  
  cited "Story 4" in an epic that had three stories. Adding the remediation story as Story 4  
  would have made that citation resolve — to a real story, silently, and to the wrong one.  
  It was caught by the ordering of the work, not by any check.

### Testing Gaps

- **A truncated check reported a pass it never computed.** `check.py` was piped to `head  
  -80`; 47-01's output filled the buffer and 47-02 was read as clean. That is the false pass  
  this spec exists to eliminate, manufactured by the tooling written to find false passes.
- **A broken normaliser looked like a catastrophic finding.** Epics carry `[unit]` inline  
  where matrices hold the tag in a separate column, so every criterion mismatched until the  
  tags were stripped. A check reporting that everything is broken is reporting on itself.
- **Four of sixteen hits were artefacts of the checker, not defects.** An escaped `\| ✓ \|`  
  broke a naive pipe split; an `### ADn —` heading did not match a `**FRn —**` regex;  
  "Milestones M2 and M4" did not match a singular pattern. Each read as a defect until the  
  artefact was opened.

### Complexity Underestimates

- **The same count drifted for a third consecutive cycle.** Fifteen entity types became  
  sixteen when the pivot added `milestone`, and two epics plus a matrix note kept saying  
  fifteen. Retro 33 recommended deriving counts rather than restating them; retro 34 recorded  
  that recommendation failing; this cycle is it failing again, in the documents retro 34 was  
  written about.

### Patterns Worth Reusing

- **Treat a mechanical check's output as candidates, not findings.** Twelve of sixteen  
  survived verification against the artefact. The check's worth is that it looks everywhere  
  and never tires; the reading is what turns a hit into a finding.
- **Cite by heading or quoted phrase, never by line number.** It costs nothing at write time  
  and does not go stale when the source moves. It is FR28's rule applied to the documents  
  that specify FR28.
- **Declare the exception in the edit that creates it.** The twelve unbindable criteria were  
  declared in all six matrices as part of the repair, so the next run of the check has an  
  expected remainder rather than a fresh mystery.

## Recommendations

- **A repair that adds a story owes its coverage matrix a declaration in the same edit.** The  
  criteria on a remediation story bind to no requirement by construction, so every such story  
  silently widens the gap the check was run to close. Declaring it later means someone  
  re-derives the reason first.
- **Compare an epic's criteria against each other, not only against the matrix and the spec.**  
  47-03's contradiction was invisible to both existing checks: each criterion had a matrix row  
  and each mapped to a requirement. Mutual satisfiability is a third question.
- **Never truncate a check's output.** Write it to a file and read the file. `head` over a  
  per-artefact loop converts a silent gap into a clean bill of health, which is worse than  
  running no check at all.
- **Treat `§n` as unusable in any planning artefact.** Line numbers in this corpus have a  
  half-life of one pivot, and a stale one is indistinguishable from a live one at the point  
  of reading.
- **The count problem is structural, and a third reminder will not fix it.** Retro 33  
  recommended deriving counts, retro 34 recorded the recommendation being ignored, and it was  
  ignored again here. Make the count appear once in the spec and have every other document  
  quote the phrase containing it, so one grep finds every site that has to move.
