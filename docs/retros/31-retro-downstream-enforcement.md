# Retro: Downstream Enforcement and the `[target]` Tag

**Date**: 2026-07-27
**Source**: docs/specifications/46-spec-environmental-requirements.md
**Stories**: 4/4 complete

## Summary

Epic 46-03 is the enforcement half of spec 46. Where 46-02 taught `cpm:spec` and `cpm:brief` to
*capture* environmental constraints, this epic makes the rest of the pipeline act on them:
`cpm:epics` gap-checks the new class as a peer of Must Have, and `[target]` — a tag for a check
that is mechanical but can only run against the real deployment target — reaches `cpm:spec`,
`cpm:epics`, `cpm:do` and `cpm:ralph`. Four stories, three new suites, 59 suites green and 1,615
assertions at close, from 1,542 at 46-02's close.

The scope widened at breakdown with Chris's approval, and the widening is the epic's most
load-bearing decision. Spec 46's In Scope list does not name `cpm:ralph`, and without it `[target]`
fails *open*: `do/SKILL.md:281` read "`[manual]` or no tag: Self-assess", so an unrecognised tag
landed in "no tag" and got self-assessed — worse than an untagged criterion, because it reads in
the epic doc as a deliberate verification choice while being the opposite of one. Adding a tag to a
vocabulary without adding a branch to every reader is how a tag becomes a lie.

Two themes run through the observations. The first is that this epic kept meeting assertions that
were satisfied by the change which removed the thing they guarded — three times, in three different
disguises. The second is that almost everything here is prose in a SKILL.md, so the strongest
available oracle is a correspondence between two documents; the epic learned, twice, exactly what
that shape can and cannot say.

## Observations

### Testing Gaps

- **A presence-set comparison answers "do these name the same tags?" and cannot answer "do they say  
  the same thing about them?"** Story 3 asserted that `cpm:do`'s two statements of the verification  
  partition — the per-criterion routing map at `:281` and the verification-gate rule at `:239` —  
  name the same tags. A mutation deleted the gate rule's *substantive* `[target]` sentence ("record  
  `target-only — unverified in this environment` and assess nothing") and the suite stayed green:  
  the tag was still named, in the rule's trailing exception clause, so the two sets still matched.  
  The set comparison is the right oracle for the criterion that genuinely asks *which* tags are  
  named, and the wrong one for the criterion that asks what each statement does with them. Where a  
  claim is about what a rule *does*, the set comparison needs an assertion on the treatment beside  
  it. The general shape is retro 28's: the assertion was satisfied by the change that removed the  
  feature.

- **The tidy repair that makes an assertion unable to fail.** Story 4 needed a mechanical rule for  
  "which lines name the automated tag set", across four skills that name it at several sites each.  
  Collecting every line that names level tags over-collects: `epics/SKILL.md:464`'s worked example  
  names `[unit]`, `[integration]` and `[manual]` together, correctly, being an illustration of a  
  result rather than a statement of the set. The obvious repair is to keep only lines whose  
  level-tag set has exactly three members — and that repair **defines away every line that dropped  
  one**, so the assertion could never fail. This is retro 30's vacuity wearing a filter instead of a  
  `sort -u | grep -c .`, and it hides better, because a filter reads as a tidy-up rather than as a  
  claim. A filter that removes the cases an assertion exists to catch is a deletion, not a  
  narrowing. The suite reads one designated operative site per skill instead, and its header names  
  what that does not cover.

- **A derived value needs escaping at the point it enters a pattern, and the control that fires  
  first is what makes the mistake survivable.** Story 3's suite derives the tag's *name* from  
  `cpm:spec`'s vocabulary rather than typing it, so a consistent rename across three files leaves  
  the suite green — which it did. The cost was a defect with no visible symptom: `[target]`  
  interpolated into a `sed` basic regular expression is a *character class* matching one of  
  `t`, `a`, `r`, `g`, `e`, so the slice matched nothing and came back empty. Nothing in the  
  assertions themselves would have said so. The non-empty control, stated before the assertions  
  that depend on the slice, fired on unmodified files and named it in one line.

### Codebase Discoveries

- **No executable in this repository reads test-approach tags at all.** `grep` across  
  `cpm/hooks/lib/` and `cpm/hooks/` finds no `[unit]`, `[manual]` or `[integration]`, and  
  `coverage-parse.sh` has no notion of a tag. Verification routing exists *only* as prose in  
  SKILL.md files. This matters beyond one story: retro 29's remedy — "build a fixture, run the real  
  script for its exit code, assert which branch that code selects" — was the disposition applied at  
  this epic's consumption gate, and it had nothing to run. It was surfaced to Chris rather than  
  quietly substituted, and he chose the adaptation. Any future retro lesson phrased as "run the real  
  thing" needs checking against this fact before it is dispositioned Applied.

- **The interface around `ralph/SKILL.md:162` is the stated length, not the sentence.** The story  
  carried `[plan]` because four suites were believed to treat that sentence as an interface. They do  
  not: `grep` for `Task complete means` and `tagged criteria` across all twelve suites that read  
  `ralph/SKILL.md` returns zero. What *is* machine-checked is `**Length: 2858 characters**` at  
  `:159`, compared against the measured line by `test-ralph-autonomous-wiring.sh` and  
  `test-ralph-promise.sh`. So the content edit was free and the *length* edit was guarded — and the  
  guard was confirmed to guard, by watching both suites fail before `:159` was updated and pass  
  after. A length edit that never failed first would mean the guard was not watching.

- **`coverage-rollup.sh:330` reads as forbidding what AD4 requires.** Task 1.1 needed `cpm:epics`  
  to classify the environmental requirement class, and the roll-up's comment reads as forbidding a  
  skill from naming the `ENV`/`ENVX` prefixes. AD4 and spec 46's Integration Boundaries settle it  
  the other way — the one-definition constraint governs the two lib-to-lib seams, not the skills —  
  corroborated by `test-environmental-class.sh:138` scoping its own inventory to  
  `cpm/hooks/lib/*.sh`. Resolved at source rather than guessed; guessed wrong, the skill would have  
  been told to classify by a name it was never given.

### Patterns Worth Reusing

- **Correspondence and inventory are different claims, at any number of sides.** Story 1  
  demonstrated it at two sides: a mutation adding the same third blocking class to *both*  
  `epics/SKILL.md` and `coverage-rollup.sh` left the correspondence assertion green — correctly,  
  the components still agree — while both inventory assertions fired. Story 4 reproduced it at  
  four: a consistent rename of `[feature]` across `spec`, `epics`, `do` and `ralph` left all three  
  correspondence hops green and fired only the inventory. Correspondence cannot distinguish "all  
  sides right" from "all sides drifted together"; an inventory cannot distinguish real agreement  
  from literals that happen to match. Where a criterion says components agree *and* names what they  
  should agree on, that is two assertions, and the consistent-rename mutation is what shows neither  
  is redundant.

- **A mutation expected to stay green is as informative as one expected to fire.** Used four times  
  in this epic. Its distinctive value is negative: on Story 3 it revealed that four assertions were  
  failing purely because the tag's name was typed into a slicer, which would have read to the next  
  author as "renaming the tag breaks the contract" when the contract is indifferent to the name.  
  No firing mutation would have found that.

- **Promotion decided by evidence across three stories, in both directions.** `assert_agrees` was  
  declined at one caller in Story 1, promoted at three in Story 2, and a shared tag-extraction  
  helper was declined again in Story 4 — not on the count but on the *shape of the loss*.  
  `assert_agrees` carries a contract you can omit entirely and never notice, because the suite still  
  passes without its non-empty controls. A missing `sort -u` in a tag extraction goes red on its own  
  first run. Only the first shape is a silent loss, and only silent losses justify the coupling.

### Scope Surprises

- **A rule stated per-X, where X has always had exactly one Y.** `do/SKILL.md:281`'s "`[manual]` or  
  no tag" and `ralph/SKILL.md:162`'s "all tagged criteria (`[unit]`/`[integration]`/`[feature]`)…  
  and all `[manual]` criteria" were both written when `[manual]` was the only non-automated tag.  
  Neither is wrong; both are unextendable, and both fail *open* when extended. The epic predicted  
  this at breakdown, citing retro 23, and the prediction is what got `cpm:ralph` into scope — but  
  note that predicting the category did not prevent the instances. Story 2 met retro 23's  
  `assert_not_contains` trap exactly where the epic said it would and fell into it anyway, because  
  the defect was in the slice *boundary*, not the assertion: the slice ran past the paragraph  
  distinguishing `[manual]` from `[target]`, written minutes earlier in the same task. Prose you  
  have just authored does not feel like part of the neighbourhood you are slicing, which is  
  precisely when it is.

- **The `[plan]` gate paid for itself on the wrong thing.** It was applied for a sentence's blast  
  radius and earned itself on a *figure* — `ralph/SKILL.md:192`'s prose arithmetic, which restates  
  the template's length as "2,858 less the 103-character opening and the 927-character completion  
  clause" and is guarded by nothing. Editing the template silently falsifies it, and the sentence's  
  own closing warning is that a reader who checks only the guarded figure would draw the wrong  
  conclusion. It was corrected by hand and a paragraph added stating plainly that **these four  
  figures have no test**. That is retro 24's lesson recurring: a stated figure whose only guard is  
  the next editor's diligence.

## Recommendations

1. **Pair every set-comparison assertion with a treatment assertion where the criterion is about  
   behaviour.** "Both statements name the same tags" is a real claim and a weak one. If the sentence  
   under test tells someone what to *do*, assert what it says to do, not only what it mentions.

2. **Treat any filter added to make an extraction "cleaner" as a claim requiring its own mutation.**  
   The Story 4 near-miss would have shipped an assertion that could not fail. The test is simple:  
   name a defect the assertion exists to catch, then check the filter does not remove it from the  
   input.

3. **Before dispositioning a retro lesson Applied, check its remedy is available here.** Retro 29's  
   remedy assumed an executable to run. Two minutes of `grep` at the gate would have surfaced that  
   before the story was planned around it, rather than during planning.

4. **`ralph/SKILL.md:192`'s four figures still have no test.** Deferred out of Story 3 deliberately,  
   and recorded in the skill itself. It is a small, self-contained `/cpm:quick` — derive all four  
   from the template line and assert the arithmetic — and it is the third time this epic has met a  
   stated figure with no consumer.

5. **The NFR6 delta table pins live skill sizes and will go stale.** `docs/epics/46-03-…`'s `After`  
   column is asserted against `wc -c` on the five skill files, so the next unrelated change to any  
   of them fails `test-downstream-enforcement-integration.sh` — correctly, but noisily. Story 4's  
   criterion was written that way deliberately and the cost is named in both the epic doc and the  
   suite header. The remedy when it fires is a fresh baseline row, **not** a looser assertion. Worth  
   deciding, before that day, whether the point-in-time half earns its keep or whether the durable  
   half — the table's internal arithmetic and its agreement with the prose baseline — is the whole  
   of NFR6's real value.
