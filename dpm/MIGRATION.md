# Moving to dpm from CPM

dpm keeps planning work as data rather than as files. That is the whole reason this guide exists:
your CPM planning documents are prose, and dpm cannot read prose — not because nobody got round to
writing an importer, but because reading prose is the thing dpm was built to stop doing.

So there is no "migrate" command, and there is not going to be one. What there is instead is a short
list of things worth carrying over by hand, and a much longer list of things you should leave exactly
where they are.

Everything below is done by asking Claude, in a normal conversation, in a project where dpm is
installed. You will not need to know anything about how dpm stores things.

---

## First: `docs/` becomes generated output

**Do this before you run anything else.**

The thing to understand up front is that dpm writes markdown into `docs/` as a side effect of its
own work. Once you start using it, twelve folders under `docs/` stop being things you maintain and
become output — regenerated from dpm's data whenever it publishes:

`plans` · `briefs` · `specifications` · `epics` · `reviews` · `retros` · `quick` · `discussions` ·
`communications` · `audits` · `runbooks` · `library`

Your CPM history lives in some of those same folders. Because dpm regenerates them, it also tidies
up files in them that it thinks are its own leftovers — and a good number of your CPM documents are
named closely enough to qualify. It always asks first, and `/dpm:publish` shows you the list before
removing anything, but you do not want to be making that judgement one file at a time months from
now.

**Move all twelve, not the ones that look risky.** Which folders are actually in danger today comes
down to whether CPM and dpm happen to use the same word for the same kind of document — they both
say `spec`, but CPM's `plan` is dpm's `problem_brief`. That is a coincidence rather than a promise,
and one rename in a future version of dpm turns a safe folder into a doomed one with nothing to tell
you. Sorting them is work you would have to redo on every upgrade, and getting it wrong costs files.

So move your history somewhere dpm does not look at all. `docs/cpm/` is not one of the twelve, and
dpm only ever looks one folder deep, so anything under it is permanently out of reach:

```sh
mkdir -p docs/cpm
git mv docs/plans docs/briefs docs/specifications docs/epics docs/retros docs/quick \
       docs/discussions docs/communications docs/reviews docs/audits docs/runbooks \
       docs/library docs/cpm/
```

`git mv` fails on a folder you do not have, so drop from that list any you never used — CPM never
writes `audits` or `runbooks`, so most people will drop those two.

**Use `docs/cpm/` rather than `docs/archive/`.** If you ever ran `/cpm:archive`, you already have
`docs/archive/epics/` and friends, and moving a folder onto an existing one of the same name just
fails. A separate home also keeps the two meanings apart: `docs/archive/` is work you archived while
using CPM, `docs/cpm/` is everything from the CPM era, parked. Both are equally invisible to dpm, so
leave any existing `docs/archive/` exactly where it is.

**`docs/architecture/` stays exactly where it is.** dpm has no folder for architecture decisions —
it renders them inside the document that raised them — so it never writes there and never looks
there. Leave your ADRs alone.

After this, expect `docs/specifications/` and the rest to fill up again with dpm's own files. That
is the system working. Two rules follow from it, and they're permanent:

- **Never move your archive back**, and never hand-write into those twelve folders. Anything you put
  there is competing with a generator.
- **`docs/cpm/` is now where your history lives.** It stays readable, greppable and in git
  exactly as it was — every path in the rest of this guide assumes it is there.

This step alone is a complete, valid migration. If you stop here, dpm works fine — it just starts
with an empty slate. Everything after this is a head start, not a requirement.

---

## What is worth carrying over, and what is not

When a dpm skill starts work, it looks at four things:

- **your library documents** — coding standards, architecture notes, domain glossaries
- **lessons from past retros** that are still true
- **decisions that still constrain the work** — your ADRs
- **the constraints on any project still in flight** — the environment, the things you can't change

That's the list. It does not look at your old specs, epics, coverage matrices, quick records or
review findings — not because they're unimportant, but because they're **finished**. Nothing in dpm
ever consults a completed epic. Carrying one across is typing you'll never get back.

The rule of thumb: **if it still tells a future conversation something it needs, carry it. If it
records what already happened, leave it.**

---

## Carrying the four things across

Ask for these **in this order**, in one conversation or several — each gives the next something to
attach to. Claude will handle the mechanics; you're deciding *what* goes, not *how*.

### 1. Constraints, if any project is still in flight

If you have work that hasn't finished, its constraints are worth having — the environment it has to
run in, the things it must not depend on. dpm asks about these early in every new spec, and anything
already recorded is something you won't be asked for twice.

> "We're continuing the billing work. Its constraints are in
> `docs/cpm/plans/03-plan-billing.md` under Constraints — carry those into dpm."

If nothing is in flight, skip this.

### 2. Your library documents — the one that matters most

**If you only do one thing, do this one.** Library documents are read by every dpm skill, every
time. A coding standard left as a file in `docs/cpm/` is a coding standard no skill will ever
see again.

> "Carry `docs/cpm/library/` into dpm's library. Each one should be readable by the same
> skills its front-matter lists in `scope:`."

That last part matters. Each library document is marked with which skills should read it — some are
for whoever is writing code, others for whoever is making architectural decisions. If that gets
lost, the document is in dpm and no skill picks it up. Say it explicitly and check it afterwards.

**Watch for amendment sections.** CPM library documents grow `## Amendment — 2026-03-14 (via retro)`
blocks over time. dpm expects a document to read as one document, so ask Claude to fold each
amendment into the part it changes rather than copying the trail:

> "Fold the Amendment sections into the body as you go — I want each document to read as one
> current document, not as a history of edits."

### 3. Lessons you've learned

If you've been running `/cpm:retro learn`, the lessons that earned their keep are already collected
in `docs/cpm/library/lessons-learned.md` — which means step 2 already brought them across, and
this is usually the densest, most valuable thing in the whole migration.

What's left in the individual retro files is mostly the transient stuff the promotion process
deliberately left behind. Scan them, and if two or three observations are still genuinely true and
never got promoted, mention them:

> "There are a couple of lessons in `docs/cpm/retros/` that never got promoted and are still
> true — the one about the payment sandbox, and the one about migrations on the read replica. Add
> those to dpm as retro observations."

Expect this to be a short list. If it isn't, that's usually a sign step 2 hasn't been done yet.

### 4. Decisions that still bind

Your ADRs, but only the ones still in force. Skip anything superseded, and anything that only ever
constrained work that's now finished.

> "Carry these ADRs into dpm: `docs/architecture/02-adr-event-sourcing.md` and
> `05-adr-multi-tenancy.md`. Include the options that were rejected and why."

Note the path — `docs/architecture/` did not move, because dpm never touches it.

**Ask for the rejected options.** A decision that records only what was chosen doesn't tell a future
conversation anything — the value is in what was considered and set aside, because that's what stops
the same argument being had again.

---

## Checking it worked

Don't count things. Run something and see whether it notices.

Start a new spec in the project:

```
/dpm:spec
```

Read the first few lines of what it says back. It should tell you what it found — something like
*"Found 2 existing decisions: Event sourcing for the ledger, Multi-tenancy by schema"*, and a note
naming the library documents it's going to use.

- **It names your decisions and your library documents** — the migration worked. Stop here.
- **It says it found nothing** — the material is in dpm but not reachable. Nine times out of ten
  that's the scope from step 2: the documents are there, but nothing knows which skills should read
  them. Say so and ask Claude to check.

You can stop the spec run as soon as you've read the startup lines. You're testing the migration,
not writing a spec.

---

## Three things that catch people out

**A library document with no scope looks completely fine and does nothing.** It imports without
error, it's there if you go looking, and not one skill will ever open it. This is the single most
common way a migration ends up half-done, and the check above is how you catch it.

**Do it in conversation, a few files at a time.** It's tempting to ask for the whole corpus in one
go, or to ask Claude to write a script. Don't. Turning your prose into dpm's data is exactly the
job dpm refuses to do automatically, for the same reason it's worth your attention here: the
judgement about what's still true and what's finished is yours, and it can only be made one document
at a time. Read what comes back.

**Less will carry over than you expect, and that's the design.** A project with three years of CPM
history might carry across four library documents, two ADRs and a handful of lessons. That can feel
like you've thrown something away. You haven't — it's all still in `docs/cpm/`, still in git,
still readable by you and by Claude whenever you ask. What's changed is that dpm won't be reading it
over your shoulder, which is precisely what makes it faster.
