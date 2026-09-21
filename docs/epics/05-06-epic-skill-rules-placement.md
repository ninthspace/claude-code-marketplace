# Skill rules and their placement

**Number**: 05-06  
**Source spec**: 05  
**Status**: pending  

## Why this epic is shaped this way

Seven rules and one restriction, and the first story is about none of them individually. Where a rule lands decides what it reaches, and that is not a detail to settle while writing each one: the ban on speaking an id aloud sat in its own shared section from 0.6.0 and went on being broken because one skill of twenty-three cited that section. The rule existed, was well worded, and reached nothing.

So the placement is established first, from a count of each rule's consuming skills, and a sweep asserts the citation rather than trusting it. The three rule-writing stories all wait on that decision. Its own criteria are warranted by the decision that made it rather than by requirement text, because no requirement states the placement rule — recorded as a warrant so the roll-up's silence about them is readable instead of ambiguous.

**A structural limit bounds what this epic can do.** Skill bodies are read verbatim and nothing appends to them, so the one document every body opens with is the only channel a cross-cutting rule has. A rule shaped as *restate this at steps 4, 7 and 9* cannot be carried that way at all; it has to be written once as a general disposition or left in the skill that needs it.

The host restriction is here rather than with the environment assertions because it constrains how these rules are written: none may claim an enforcement the harness does not have. A rule promising a safety net that is not there teaches a run to lean on one that will not catch it, which is worse than the rule's absence.

## Story 1 — Establish where each rule lands

**Status**: pending  
**Blocked by**: Story 2, Story 3, Story 4  

### Acceptance Criteria

- Every rule with more than two consuming skills is placed in a shared section that all of its consumers already cite, and a sweep asserts that citation rather than trusting it. `[integration]`
- Every rule with one or two consumers is placed in those skills' own bodies rather than in a shared section. `[integration]`
- must NOT — A rule is placed in a new shared section that no skill cites. `[integration]`

### Task 1 — Count each rule's consuming skills

**Status**: pending  

A read over the skill corpus, per rule. The count is what decides placement, and it is established before any rule is written rather than after.

### Task 2 — Record the placement per rule against its count

**Status**: pending  

Addresses the first two criteria. More than two consumers means a shared section all of them already cite; one or two means those skills' own bodies.

### Task 3 — Write the citation sweep

**Status**: pending  

Addresses the rejection. Asserts that every shared section carrying one of these rules is cited by each skill the rule is for — the failure being a rule that exists, reads well, and reaches nobody.

## Story 2 — The gate rule and the two criterion-writing rules

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- The rule that a gate renders its draft as its own items in the message that asks the question is in force where its consuming skills read, and nothing a gate decides is written before it is answered. `[integration]`
- The rule that a rejected outcome is named as though it had happened is in force at both the spec and the breakdown skills. `[integration]`
- The rule that a binding quotes the clause the criterion actually tests, rather than the nearest verbatim one, is in force at the breakdown skill. `[integration]`

### Task 1 — Write the three rules at the placements decided

**Status**: pending  

The gate rule, the rejected-outcome wording rule and the quoted-clause rule, each at the placement Story 1 recorded. No rule claims an enforcement the host does not have.

### Task 2 — Extend the body sweep to cover the three rules

**Status**: pending  

Covers all three criteria.

## Story 3 — The resume and read-back rules

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A resumed step is instructed to list the rows it writes under the parent it writes them to before proposing anything, and to propose only what is missing. `[integration]`
- Read-backs are instructed to batch into one message, with each row checked by its label and every closing count taken from the last report rather than from a tally of the calls sent. `[integration]`

### Task 1 — Write the resume rule and the read-back rule at their placements

**Status**: pending  

The resume rule needs a per-skill ordered read as well as the shared statement, since what a step writes differs per skill.

### Task 2 — Extend the body sweep to cover both rules

**Status**: pending  

Covers both criteria.

## Story 4 — The four execution rules

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- One observation per story, with further categories added to the existing row rather than written as a second observation. `[integration]`
- An unmet criterion is rendered in full, with what the assessment actually found, before any gate asking whether to accept a shortfall. `[integration]`
- Coverage pages are never added up by hand. `[integration]`
- Scratch files sit where the repository's own ignore rules and the next status check account for them, and are removed once the check is made. `[integration]`

### Task 1 — Write the four execution rules at their placements

**Status**: pending  

All four have a single consumer, so by the placement decision they go in that skill's own body rather than in a shared section.

### Task 2 — Extend the body sweep to cover the four rules

**Status**: pending  

Covers all four criteria.

## Story 5 — The integrity check at the confirm step

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- The breakdown skill's confirm step runs the integrity check and treats every violation not marked advisory as a gap, reporting it with the rows it names. `[integration]`

### Task 1 — Add the integrity call and its gap handling to the confirm step

**Status**: pending  

The tool exists and the confirm step does not call it. A non-advisory violation is reported with the rows it names and treated as a gap, alongside the gap check that already runs there.

### Task 2 — Assert the skill names the integrity tool

**Status**: pending  

Covers the criterion. The existing body sweep already checks which tools a skill names, so this is one entry rather than a new mechanism.

## Story 6 — No rule claims a host capability

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- must NOT — A skill body or a document a skill reads at startup claims that the host refuses a badly-formed gate, that a thinking level can be pinned per skill, or that a turn can end by handing off to a fresh context. `[integration]`
- control — A claim of that form planted in a skill body makes the check fail, so the check is shown to discriminate rather than to pass over a corpus it is not reading. `[integration]`

### Task 1 — Add the host-claim check to the body sweep

**Status**: pending  

Addresses the rejection. Reads skill bodies and the documents they open with, for claims that the host refuses a badly-formed gate, pins a thinking level, or ends a turn into a fresh context.

### Task 2 — Plant a claim and confirm the check fails

**Status**: pending  

Addresses the control. A check over a corpus it is not actually reading passes exactly as one over a clean corpus does, and only a planted claim tells the two apart.
