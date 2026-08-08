# Retro: dpm — Breakdown and Cascade

**Date**: 2026-08-08  
**Source**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Stories**: 9 epics, 57 stories, 179 tasks — none executed

## Summary

Spec 47 was broken into nine epics and nine coverage matrices, then pivoted to close the five
self-hosting register entries the breakdown had raised. Three requirements were added (FR26,
FR27, FR28) and cascaded across five epics. Every substantive defect found in this session —
in the breakdown, in the matrices, and in the amended schema — was found by **running a check
over the finished artefacts**, not by reading them. None of those checks is run by any CPM
skill.

## Observations

### Criteria Gaps

- **FR21 was covered by no story in any of the nine epics.** The work was in scope — Story 1  
  writes the DDL and the DDL contains the triggers — but no criterion asserted a trigger  
  fires, and FR21's entire content is that something fires. Found by running the cross-epic  
  union check against the spec's 113 tagged criteria partway through the breakdown rather  
  than at the end, which is the only reason it was fixable in the same run.
- **Thirteen coverage rows cited criteria that no story carried.** They were appended during  
  the FR21 fix: the six FR21 criteria went into both the epic and the matrix, and thirteen  
  others went into the matrix alone. A coverage row naming a criterion that does not exist is  
  a green mark with nothing behind it — the exact false pass this spec exists to remove, in  
  the document that records it as a register entry.
- **Four criteria carried no coverage row**, in two epics the pivot did not otherwise touch.  
  The same comparison in the opposite direction. Both directions are real defects and neither  
  is visible by reading one document.
- **Adding a requirement covered its read side and missed its write side.** FR28 says a prose  
  reference is a `{{ref:<id>}}` marker; the cascade reached every epic that *resolves* markers  
  and none of the five authoring skills that *write* them. The failure would have surfaced at  
  a render the offending skill never performed, in a file it never wrote.

### Codebase Discoveries

- **Two cross-row invariants were found by executing the amended schema, not by designing  
  it.** A document and its milestone must belong to the same spec; every `{{ref:}}` marker  
  must resolve to a live artefact. Both were written into the spec's register after probes  
  refused or accepted something unexpected. This is retro 33's central lesson holding for a  
  second run on the same document.
- **A designed mechanism failed on the corpus's hardest case and was replaced mid-flight.** A  
  `document_reference` table was the obvious answer to prose references, and it cannot reach  
  retro 33's citation of spec 47, which lives in `observation.text` — a child row, not a  
  section. Embedded markers can live in any text column. The case that broke it was in the  
  corpus being modelled, not in a test.

### Complexity Underestimates

- **One count moved and seven documents needed editing.** Twenty-two entity types became  
  twenty-three, and the correction landed in two epics' story criteria, three task headings,  
  four matrix rows and three prose notes. Retro 33 recorded the same shape one layer up and  
  recommended "count in code, quote in prose"; the breakdown restated the count in prose  
  anyway, in a document written after that retro.

### Patterns Worth Reusing

- **Compare the epic's criteria against its matrix's criteria, both directions.** Fourteen  
  lines of script over nine epic/matrix pairs; found two defect classes in one pass. `cpm:epics`  
  writes the matrix from the stories it just wrote, so it has no reason to check — which is  
  precisely why the check finds things.
- **Run the cross-epic union check early, not at the end.** Run partway through, an uncovered  
  requirement is a story to add. Run at the end, it is a finding to record.
- **Gate the cascade per epic rather than per change.** Five gates instead of roughly twenty,  
  each presenting a table of what moves and why, and each still small enough to reject. Two  
  of the five gates surfaced a decision worth making that a per-change gate would have buried.

## Recommendations

- **Run a both-directions set comparison between every epic and its coverage matrix before  
  the breakdown is confirmed.** Epic criteria with no row, and rows citing criteria no story  
  carries, are different failures with different consequences, and a one-way check finds only  
  one. Declare any intended exception — a roll-up criterion the matrix expands — in the  
  matrix notes, so the comparison has an expected remainder rather than an unexplained one.
- **Run the spec-coverage union check partway through the breakdown, not after it.** The  
  finding is the same; only the cost of acting on it changes.
- **When a pivot adds a requirement, ask which side of it the cascade reached.** A requirement  
  with a producer and a consumer will cascade to whichever the spec's own criteria describe,  
  and the other side goes uncovered without anything looking wrong.
- **Any count restated in prose is a maintenance liability, and knowing that is not enough.**  
  Retro 33 recommended deriving counts once; the breakdown written after it restated one in  
  seven places. Where a count cannot be derived, name the places it appears at the point it is  
  first written, so the sweep exists before the drift does.
