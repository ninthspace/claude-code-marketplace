# Skill rules and their placement

**Number**: 05-06  
**Source spec**: 05  
**Status**: complete  

## Why this epic is shaped this way

Seven rules and one restriction, and the first story is about none of them individually. Where a rule lands decides what it reaches, and that is not a detail to settle while writing each one: the ban on speaking an id aloud sat in its own shared section from 0.6.0 and went on being broken because one skill of twenty-three cited that section. The rule existed, was well worded, and reached nothing.

So the placement is established first, from a count of each rule's consuming skills, and a sweep asserts the citation rather than trusting it. The three rule-writing stories all wait on that decision. Its own criteria are warranted by the decision that made it rather than by requirement text, because no requirement states the placement rule — recorded as a warrant so the roll-up's silence about them is readable instead of ambiguous.

**A structural limit bounds what this epic can do.** Skill bodies are read verbatim and nothing appends to them, so the one document every body opens with is the only channel a cross-cutting rule has. A rule shaped as *restate this at steps 4, 7 and 9* cannot be carried that way at all; it has to be written once as a general disposition or left in the skill that needs it.

The host restriction is here rather than with the environment assertions because it constrains how these rules are written: none may claim an enforcement the harness does not have. A rule promising a safety net that is not there teaches a run to lean on one that will not catch it, which is worse than the rule's absence.

## Where each rule lands, and the count that decided it

ADR 05-05 decides the rule; story 1 applies it to the eight. The counts are measurements taken from this working tree, not figures carried from the spec's prose.

| Rule | Consumers | Lands in |
|---|---|---|
| FR16 — a gate is written and performed as two steps | 20 skills cite **Gate Presentation** | that section |
| FR17 — a criterion names the rejected outcome as though it happened | `epics`, `quick`, `spec` | a shared section all three cite |
| FR19 — the rows say what was written; the session state does not | 20 skills cite **Session Startup** | that section |
| FR20 — a run of writes is read back, batched | 12 skills write runs of rows | a shared section they cite |
| FR18 — a binding quotes the clause the criterion tests | `epics` alone writes bindings | `epics`' own body |
| FR21 — the four execution rules | `do`, "the execution skill" | `do`'s own body |
| FR15 — integrity at the breakdown's confirm step | `epics` alone | `epics`' own body |
| ENV6 — no rule claims a host capability | every body; a restriction, not a rule to place | story 6's sweep |

**"A section its consumers already cite" is read as the file, not the heading.** All twenty-three skills already name `dpm/shared/skill-conventions.md` and read it at startup; the `This skill uses **X**` line is what each declares it takes from it. A new section is therefore legitimate provided every consumer names it — which is what criterion 3's must-NOT forbids the absence of: a section *no skill cites*.

**Two faults the count turned up, both pre-existing and both now fixed.** `do` cited **Implementation Guidelines**, which is a section of *CPM's* conventions and not of these — a run told to follow a rule whose text is nowhere. By this story's own rule a single-consumer rule belongs in that skill's body, so `do` now carries the three rules it was reaching for. And **A Closing Note on Length and Tone** was cited by nobody: criterion 3's must-NOT already true in the tree. Its content duplicated **Conversational Output**, which every skill cites; the one sentence that was not duplicated moved there and the section is gone.

**Recorded and not fixed:** **Naming a Document** has exactly one citer, `status`. By this rule it belongs in that skill's body, but it carries none of this epic's rules and moving it is a separate change.

## Four requirements delivered whole and claimed on less than the whole

FR15, FR21 and ENV6 are claimed: each carries bindings that quote every obligation it states — FR21 one per sub-rule, ENV6 the prohibition and the reason for it.

**FR16, FR17, FR18, FR19 and FR20 are not, and the reason is the same for all five.** Each states two or three obligations in one sentence and carries a single binding quoting one of them. The written rules cover every clause and every clause is asserted — FR16's "nothing a gate decides is written before it is answered", FR17's "dropped rather than inverted", FR18's coverage bound and its `must_not` clause, FR19's per-parent resume, FR20's label-checking and its counts-from-the-report — but a claim says *the bound fragments account for the requirement whole*, and they do not.

This is the same standing epic 05-02 recorded for FR13 and FR14, and leaving it consistent matters more than the five green rows. The fix is a binding each, which is a breakdown rather than a judgement to make at a roll-up.

**One thing FR18 changed about how this is read.** The rule this epic just wrote says a requirement is covered as far as its criteria go and no further. Each of these five has a criterion that *does* measure every clause — the criteria are about the rule being in force, not about one sentence of it — so the shortfall is in the fragments rather than in the work or in what was verified.

## Story 1 — Establish where each rule lands

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Every rule with more than two consuming skills is placed in a shared section that all of its consumers already cite, and a sweep asserts that citation rather than trusting it. `[integration]`
- Every rule with one or two consumers is placed in those skills' own bodies rather than in a shared section. `[integration]`
- must NOT — A rule is placed in a new shared section that no skill cites. `[integration]`

### Task 1 — Count each rule's consuming skills

**Status**: complete — Counted from the corpus in this working tree: 20 skills cite **Gate Presentation**, 20 cite **Session Startup**, 23 cite **Conversational Output**; `epics`, `quick` and `spec` write criteria; `epics` alone writes coverage bindings; 12 skills write runs of rows; FR21 names `do` and FR15 names the breakdown skill.

**The count paid for itself immediately, finding two faults of exactly the kind the epic was written about.** `do` cited **Implementation Guidelines**, a section of CPM's conventions that DPM does not have — a run sent to read a rule whose text is nowhere. And **A Closing Note on Length and Tone** was cited by nobody, which is criterion 3's must-NOT already true in the tree. Both were invisible because `section()` answers a missing heading with an empty string and `reachable()` reads only the `shared **X**` form.

Recorded, not fixed: **Naming a Document** has one citer, `status`. By the rule it belongs in that body, but it carries none of this epic's rules.  

A read over the skill corpus, per rule. The count is what decides placement, and it is established before any rule is written rather than after.

### Task 2 — Record the placement per rule against its count

**Status**: complete — Recorded as section 2 on the epic — the table of rule, consumers and placement — so the three rule-writing stories read a row rather than re-deriving the decision.

Both faults fixed as part of it. `do` lost the dangling citation and gained "How this skill changes a codebase", carrying the three rules it was reaching for: edit with the Edit tool rather than a stream processor, correctness before speed, version control stays with the user. **A Closing Note on Length and Tone** is gone from the shared conventions, its tone sentence folded into **Conversational Output** — the section all twenty-three already cite, which is where the rule reaches everyone it was written for rather than nobody.  

Addresses the first two criteria. More than two consumers means a shared section all of them already cite; one or two means those skills' own bodies.

### Task 3 — Write the citation sweep

**Status**: complete — tests/skill-citations.test.js — six tests, both directions, over the whole corpus read from the directory rather than listed.

**The reading took three attempts and each failure was the sweep's, not the corpus's.** The first reported five skills citing a section that does not exist, because the files are hard-wrapped and `**Written\nDeliverable Length**` straddles a line — whitespace is now collapsed. The second reported **Naming a Document** as an orphan, because `status` cites it in a third form, `see **X** in the shared conventions`, that neither the `uses` line nor the delegation pattern matches. So citation is now read by *what a skill names* — any bolded name that is a heading — and only the three explicit "go and read this" forms are held to naming a real section. A fourth form would have been missed by the narrower reading and is not by this one.

Four mutations. The dangling citation restored → two tests fail. An uncited section planted → the orphan direction fails alone. **Gate Presentation** left with two citers → the placement test fails, which is criterion 1 asserted rather than described. The corpus narrowed to one skill → three fail, including the guard on its size. That last one the plan predicted would fail nothing; it fails because the guard was written, which is the difference between a sweep that could be quietly narrowed and one that could not.  

Addresses the rejection. Asserts that every shared section carrying one of these rules is cited by each skill the rule is for — the failure being a rule that exists, reads well, and reaches nobody.

### Retro

- The story was written about a failure that had happened once, and counting found two more of it sitting in the tree. `do` cited **Implementation Guidelines** — a section of CPM's conventions, not DPM's — so a run was told to go and read a rule whose text is nowhere. And **A Closing Note on Length and Tone** was cited by no skill at all, which is this story's own must-NOT already true before the story started. Neither is subtle; both were invisible because the two mechanisms that could have seen them look elsewhere. `section()` answers a missing heading with an empty string, so a dangling citation splices nothing and nothing complains; `reachable()` matches only the `shared **X**` delegation, never the `This skill uses **X**` line where almost every citation actually lives. A guard that returns silence for its own failure case is worse than no guard, because it occupies the place one would go.

The sweep's reading was wrong twice before it was right, and both failures were mine rather than the corpus's. It first reported five skills citing a section that does not exist, because the files are hard-wrapped and `**Written\nDeliverable Length**` straddles a line. It then reported **Naming a Document** as an orphan, because `status` cites it as `see **X** in the shared conventions` — a third form neither pattern knew. The fix was to stop enumerating forms: a citation is now any bolded name that matches a heading, and only the three explicit "go and read this" phrasings are held to naming a real section. Enumerating the ways a thing can be written is a losing position when the thing is prose, and the second failure is what made that obvious rather than the first.

One prediction in the plan was wrong in a useful direction. It said narrowing the sweep to one skill would fail nothing, which was the argument for reading the corpus from the directory. It fails three tests — because the guard asserting the corpus size was written, and that guard is the whole difference between a sweep somebody can quietly narrow and one they cannot. The prediction was about the sweep as designed; the test was about the sweep as built, and the gap between them is the guard.

Worth recording as a process note: reverting the mutations with `git checkout -- dpm/skills/` also reverted an in-scope edit from the previous epic, and four tests went red for a reason that had nothing to do with the mutation. Restoring from the scratchpad copies, which is what the earlier mutations in this run used, does not have that failure mode.

## Story 2 — The gate rule and the two criterion-writing rules

**Status**: complete  
**Blocked by**: Story 1  

### Acceptance Criteria

- The rule that a gate renders its draft as its own items in the message that asks the question is in force where its consuming skills read, and nothing a gate decides is written before it is answered. `[integration]`
- The rule that a rejected outcome is named as though it had happened is in force at both the spec and the breakdown skills. `[integration]`
- The rule that a binding quotes the clause the criterion actually tests, rather than the nearest verbatim one, is in force at the breakdown skill. `[integration]`

### Task 1 — Write the three rules at the placements decided

**Status**: complete — Three rules at the three placements story 1 recorded.

FR16 into **Gate Presentation**, which twenty skills cite: a gate is two steps and is performed as two — the draft as its own items in the message that asks, not in reasoning nobody can see and not in an earlier message that is no longer the one being answered — and nothing a gate decides is written before it is answered.

FR17 into a new **Writing a Criterion**, cited by `epics`, `quick` and `spec` and by nobody else: a criterion names the rejected outcome as though it had happened, because the document supplies the negation; a clause that only restates the denial is dropped rather than inverted, since inverting one says the opposite of what the spec does.

FR18 into `epics`' own body, beside the `create_coverage` call, since `epics` alone writes bindings. Three clauses: the quoted clause is the one *this criterion* tests rather than the nearest that would pass; a `must_not` quotes the clause whose outcome it rejects, not the requirement's own prohibition; and a requirement is covered as far as its criteria go and no further.

**No rule claims an enforcement the harness does not have** — ENV6 held here rather than waiting for story 6, and asserted: a mutation adding "which the host refuses anyway" to the gate rule fails.  

The gate rule, the rejected-outcome wording rule and the quoted-clause rule, each at the placement Story 1 recorded. No rule claims an enforcement the host does not have.

### Task 2 — Extend the body sweep to cover the three rules

**Status**: complete — tests/skill-rules-gates-criteria.test.js — four tests, each about **reach** rather than wording: the rule is where its consumers look, and each consumer looks there. Story 1's `PLACED` table in skill-citations.test.js gained FR17's row, with its three consumers named individually — a bound on the *number* of citers is satisfied by the wrong three.

Nothing pins a sentence. Each assertion matches the shortest clause carrying the obligation, read with whitespace collapsed, because the files are hard-wrapped and the first draft failed on `as\nthough it had happened` — story 1's lesson, arriving again in the same shape one story later.

Four mutations. `quick` drops its citation → the reach assertion and story 1's placement row both fail, which is the two sweeps agreeing. The gate rule claims a host capability → the ENV6 assertion fails alone. The binding rule's `must_not` half inverted to "whichever clause is nearest" → the binding test fails alone. The whole-corpus reading is what story 1 already proved load-bearing.  

Covers all three criteria.

### Retro

- Story 1's lesson came back one story later in exactly the same shape, which is a useful thing to know about this corpus rather than about either story. The sweep's reading failed on a hard-wrapped section name; this story's assertions failed on a hard-wrapped *phrase*, `as\nthough it had happened`. Same cause, different subject, and the second one arrived despite the first being fresh — because the fix had been applied to the sweep rather than adopted as a habit. Anything matched against these files gets its whitespace collapsed first; `prose()` in tests/support/skills.js already existed for it.

The placement rule earned itself on FR17, which is the only one of the eight that lands close to the line. Three consumers is "more than two" by one, and a section cited by three of twenty-three skills is the narrowest thing in the shared file. Writing it anywhere else was tempting — `epics` alone would have been half a rule, and `Written Deliverable Length` would have buried a criterion-wording rule in a section about document size. What settled it was that the count is the rule: three is more than two, so it is shared, and the citations are what make "shared" mean something rather than "in a file everyone opens".

The two sweeps agreeing is worth keeping. Dropping `quick`'s citation fails this story's reach assertion *and* story 1's placement row, because one reads the rule's consumers and the other reads the registry's. Neither was written to back the other up, and a change that breaks one breaking both is the evidence that they are looking at the same thing from opposite ends — which is what story 1's whole-corpus reading was for.

ENV6 turned out to be cheaper to hold as each rule is written than to sweep for afterwards. The gate rule is the one that invites the claim — a run wants to be told a badly-formed gate is refused — and the assertion forbidding it sits in the same test as the rule's own obligations. Story 6 still owes the corpus-wide sweep, but no rule this story wrote is waiting on it.

## Story 3 — The resume and read-back rules

**Status**: complete  
**Blocked by**: Story 1  

### Acceptance Criteria

- A resumed step is instructed to list the rows it writes under the parent it writes them to before proposing anything, and to propose only what is missing. `[integration]`
- Read-backs are instructed to batch into one message, with each row checked by its label and every closing count taken from the last report rather than from a tally of the calls sent. `[integration]`

### Task 1 — Write the resume rule and the read-back rule at their placements

**Status**: complete — Both into **Session Startup** as subsections — "Resuming a step" and "Reading back what was written" — rather than a section of their own. Story 1's count put them at twenty consumers, and a new section would have needed twenty citation lines edited to reach the same runs, with any skill that missed one resuming without the rule while still reading the file that holds it.

FR19 states the seam first, because without it the rule reads as bureaucracy: `state` records where a run *believed* it had reached and the rows record what it did, and the two part company exactly when a run is interrupted between a write and the update that would have noted it. Then the obligation — list the rows that step writes, under the parent it writes them to, propose only what is missing, never a row a list has just returned — and the per-parent half, which is what a production loop needs and what `state` cannot express.

**The per-skill ordered read this task called for is named as per-skill rather than enumerated.** Only the skill knows which lists its own step produces, so the shared rule says each skill names its own and stops; enumerating twenty-three reads here would be the shared file deciding what each skill writes.

FR20 in three clauses: read back before the next unit begins and batch into one message; check each row by its label, never by an id held from an earlier call; take every closing count from the last report rather than from a tally of the calls sent.  

The resume rule needs a per-skill ordered read as well as the shared statement, since what a step writes differs per skill.

### Task 2 — Extend the body sweep to cover both rules

**Status**: complete — tests/skill-rules-resume.test.js — four tests. Both rules read through `prose()` so the hard wrapping is collapsed before anything is matched, which is now the habit rather than a repair.

Reach is asserted over the whole corpus even though this story edited no skill: twenty cite **Session Startup**, six named individually, and `templates` is checked as a genuine negative — it opens no session, so it is the honest one rather than a contrived control.

Three mutations. The per-parent resume clause replaced by "resumes wherever `state` says it reached" → the resume test fails alone, which is the clause the story was actually for. The count rule inverted to tallying the run's own calls → the read-back test fails alone. The resume rule given "the host automatically replays whatever the run missed" → the ENV6 test fails alone, which is the claim a resume rule most invites.  

Covers both criteria.

## Story 4 — The four execution rules

**Status**: complete  
**Blocked by**: Story 1  

### Acceptance Criteria

- One observation per story, with further categories added to the existing row rather than written as a second observation. `[integration]`
- An unmet criterion is rendered in full, with what the assessment actually found, before any gate asking whether to accept a shortfall. `[integration]`
- Coverage pages are never added up by hand. `[integration]`
- Scratch files sit where the repository's own ignore rules and the next status check account for them, and are removed once the check is made. `[integration]`

### Task 1 — Write the four execution rules at their placements

**Status**: complete — All four into `do`'s own body, one consumer each, and **each beside the step it governs rather than gathered into a section of its own** — a run reads the rule at the point it would otherwise break it.

One observation per story sits at Step 6 where the observation is written, and says why: a second category goes on the existing row because `/dpm:retro` groups by category and two observations saying one thing count the story twice.

The unmet criterion goes immediately before the gate it qualifies — rendered in full with what the assessment actually found, because a gate asking whether to accept a shortfall nobody has seen is asking for approval of a summary of it.

The coverage rule sits in the roll-up and names the alternative rather than only the prohibition: `check_coverage` answers it in one call. Both failure modes are stated, since a run told only "do not total pages" will total them carefully instead of not totalling them.

The scratch-file rule joins the two existing rules about how this skill touches a working tree, in "How this skill changes a codebase" — which that section now has four of, and which exists because of story 1's dangling-citation fix.  

All four have a single consumer, so by the placement decision they go in that skill's own body rather than in a shared section.

### Task 2 — Extend the body sweep to cover the four rules

**Status**: complete — tests/skill-rules-execution.test.js — six tests, one per criterion plus placement and ENV6.

**The placement assertion's first reading was wrong and is recorded rather than quietly fixed.** It asked which skills call `update_task` as a proxy for "the execution skill" and got `do` and `pivot` — `pivot` amends a breakdown and touches tasks doing it, without running any. A proxy that misfires on the second skill it meets is a worse answer than the direct one, so the assertion is now that `do` alone carries the four rules.

Three mutations, each failing what it should. Half the coverage rule dropped → that test alone. The one-observation rule inverted to "an observation per finding" → the observation test and the placement test, which is the two readings agreeing. The scratch rule given "the host cleans it for you" → the ENV6 test alone, and that is the claim a scratch-file rule most invites.  

Covers all four criteria.

## Story 5 — The integrity check at the confirm step

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The breakdown skill's confirm step runs the integrity check and treats every violation not marked advisory as a gap, reporting it with the rows it names. `[integration]`

### Task 1 — Add the integrity call and its gap handling to the confirm step

**Status**: complete — Added to `epics`' Step 4, beside the gap check that already runs there, with the distinction between them stated: the gap check reads what the rows *say*, integrity reads whether they *hold*. A breakdown can be complete by the first reading and broken by the second, which is why a clean gap check is not a reason to skip it.

Two clauses beyond the call itself. **Advisory is the register's call, not the run's** — the rule says the register decides, because a run working it out for itself would be a second answer to a question the register already holds. And **report the rows, not the count** — the check returns them, and "three violations" sends the reader back to a call they cannot make.  

The tool exists and the confirm step does not call it. A non-advisory violation is reported with the rows it names and treated as a gap, alongside the gap check that already runs there.

### Task 2 — Assert the skill names the integrity tool

**Status**: complete — tests/skill-rules-integrity.test.js — four tests, plus one change to the existing `epics` suite that matters more than any of them: **the recorded run now drives `check_integrity` at Step 4**, so the instruction is exercised rather than merely written. The three-direction binding in skill-epics.test.js then holds the skill and the run to each other, which naming a tool in prose alone does not.

The advisory assertion reads `REGISTER` rather than carrying its own list, because the rule tells a run to ask the register which entries are advisory and a second list here would be exactly the duplication the rule prevents — and would go stale the first time an entry was added.

Two mutations. The advisory distinction dropped from the rule → this story's test fails alone. `advisory: true` flipped to `false` in the register → nine tests across six files fail, which is a fact about how much of the suite rests on that flag rather than a control for this story; recorded as such.  

Covers the criterion. The existing body sweep already checks which tools a skill names, so this is one entry rather than a new mechanism.

## Story 6 — No rule claims a host capability

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A skill body or a document a skill reads at startup claims that the host refuses a badly-formed gate, that a thinking level can be pinned per skill, or that a turn can end by handing off to a fresh context. `[integration]`
- control — A claim of that form planted in a skill body makes the check fail, so the check is shown to discriminate rather than to pass over a corpus it is not reading. `[integration]`

### Task 1 — Add the host-claim check to the body sweep

**Status**: complete — tests/skill-host-claims.test.js — over all twenty-three skill bodies **and** the shared conventions, which are in scope precisely because a claim there reaches twenty-three runs at once.

**The claims are read as a class rather than as a blocklist of sentences.** ENV6 names three by example, and an author who rewords one is not making a new claim — so each pattern matches the *promise* (the host does something on the run's behalf) and a fourth entry catches the general "the host/harness will…" form. A separate test drives three paraphrases none of the example wordings would have matched.

Two patterns were too narrow on their first run and both failures were the sweep's: "Set the thinking level" put the verb before the noun, and "handing over" is not "hand over". Fixed rather than the examples softened.  

Addresses the rejection. Reads skill bodies and the documents they open with, for claims that the host refuses a badly-formed gate, pins a thinking level, or ends a turn into a fresh context.

### Task 2 — Plant a claim and confirm the check fails

**Status**: complete — Planted in the suite and planted live, because the two answer different questions.

In the suite: each of the four forbidden claims fed through the same reading and required to be caught, plus an assertion that the four plantings are caught by four *different* patterns — so no entry is carrying another's weight and passing as though it worked. And four real sentences from the rules this epic wrote are required **not** to fire, because a reading that matched everything would pass every planting and fail the corpus.

Live: "The host refuses a badly-formed gate" appended to `skills/review/SKILL.md`, then "The harness will replay whatever a resumed run missed" appended to the shared conventions. Each fails the sweep alone. The second is the one that mattered — it confirms the shared file is genuinely in the corpus rather than assumed to be, which is the exemption the highest-reach text in the project would otherwise have had.  

Addresses the control. A check over a corpus it is not actually reading passes exactly as one over a clean corpus does, and only a planted claim tells the two apart.

### Retro

- Stories 2 to 5 each asserted ENV6 for their own rule as it was written, and story 6 is what none of them could do — and the difference is not thoroughness, it is subject. A per-rule assertion is about the rule; the sweep is about the corpus, and the corpus includes twenty-two skills this epic never opened. Holding ENV6 as each rule was written was still worth it: by the time the sweep ran there was nothing for it to find, which is the cheap order rather than the diligent one.

The sweep's patterns were wrong twice in the same direction, and the direction is the finding. Both failures were too *narrow* — "Set the thinking level" puts the verb before the noun, "handing over" is not "hand over" — so the sweep reported a clean corpus for claims it simply could not see. A prose check that fails narrow is indistinguishable from a prose check that works, which is why the control has to plant each claim separately and assert that four plantings are caught by four different patterns. Without that count, one pattern doing nothing is invisible: the other three catch their own examples and the suite is green.

Reading the claims as a class rather than as a blocklist is the part worth carrying. ENV6 names three by example; an author who rewords one has not made a new claim, and a pattern pinned to the example wording would let every restatement through while looking like enforcement. The fourth entry — the general "the host will…" form — exists because the three named claims are instances of one thing, and the thing is what the rule is about.

Planting in the shared conventions mattered more than planting in a skill. A skill body failing the sweep proves the sweep reads skills; the shared file failing it proves the highest-reach text in the project is in scope rather than assumed to be. It would have been the natural omission — the corpus is "the skills" until somebody asks what a skill reads at startup.

## Retro Applied

- 10 · A control pinning an exact figure is a change detector wearing a control's clothes · applied — Sharper here than anywhere this run, because the subject is prose. A test that pins a rule's sentence fires the day somebody improves the wording, and a run fixing it learns that the test is about the string — after which the rule is no longer checked. So every assertion in this epic is over what a rule *requires* — the citation is present, the named tool is named, the claim of a host capability is absent — and never over how it is phrased. Where a specific sentence genuinely has to be pinned, it is pinned to the shortest clause that carries the obligation.
- 10 · A retro's mechanism transfers and its arithmetic does not · applied — Story 1 is a counting story — "the placement is established first, from a count of each rule's consuming skills" — so this applies to its central move rather than to its edges. The count is taken from the corpus in this working tree, now, and no figure from an earlier epic or from the spec's own prose is carried into it. The four epics before this one each broke a different number of tests than predicted; the count here is the thing being measured, so measuring it is the work rather than a preliminary to it.
- 10 · An assertion that leaves something alone is vacuous when the fixture holds one of it · applied — The governing lesson, and this epic's own shaping note describes the failure it protects against: a rule that "existed, was well worded, and reached nothing" because one skill of twenty-three cited it. Every citation sweep here therefore runs against the **whole** skill corpus rather than the skills a story happened to edit, and each carries a planted control — a skill body with the citation removed must make the sweep fail. A sweep whose corpus is the files it just edited cannot tell a rule that reaches everything from one that reaches only what was in front of it.
