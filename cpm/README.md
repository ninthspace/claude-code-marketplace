# Claude Planning Method (CPM)

Facilitated planning skills for Claude Code. Brings structured discovery, specification, and work breakdown into your development workflow — guiding you through understanding problems before jumping to solutions.

Inspired by the [BMAD-METHOD](https://github.com/bmad-method) (Breakthrough Method for Agile AI-Driven Development), adapted for Claude Code's native capabilities.

## Quick Start

After installation, use any skill independently or as a pipeline:

```
/cpm:discover → /cpm:spec → /cpm:stories → implement
```

Each step is optional. Use what fits your situation:

- Starting a new product? Begin with `/cpm:discover`
- Problem is clear, need requirements? Jump to `/cpm:spec`
- Have a plan, need tasks? Go straight to `/cpm:stories`
- Small bug fix? Skip planning entirely — Claude Code's native plan mode is enough

## Skills

### `/cpm:discover` — Problem Discovery

Guided conversation to understand the problem before proposing solutions. Works through six phases:

1. **Why** — Motivation and importance
2. **Who** — Target users and their needs
3. **Current State** — How it's solved today
4. **Success Criteria** — Definition of done
5. **Constraints** — Technical, business, timeline limits
6. **Summary** — Problem brief for confirmation

**Output**: `docs/plans/{slug}.md`

```
/cpm:discover build a customer portal for our booking system
```

### `/cpm:spec` — Requirements & Architecture

Builds a structured specification through facilitated conversation. Covers functional requirements (MoSCoW prioritisation), non-functional requirements, architecture decisions, and scope boundaries.

**Input**: A problem brief from `/cpm:discover`, a file path, or a description.
**Output**: `docs/cpm:specifications/{slug}.md`

```
/cpm:spec docs/plans/customer-portal.md
```

### `/cpm:stories` — Work Breakdown

Converts plans into tracked work items using Claude Code's native task system (TaskCreate/TaskUpdate). Groups work into epics, breaks into right-sized stories with acceptance criteria, and sets up task dependencies.

**Input**: A spec from `/cpm:spec`, a brief, or a description.
**Output**: `docs/cpm:stories/{slug}.md` + Claude Code tasks with dependencies

```
/cpm:stories docs/cpm:specifications/customer-portal.md
```

## How It Works

Each skill is a facilitated conversation, not a form. Claude asks questions one topic at a time, builds on your answers, and gates progression with user confirmation. The core principles baked into each skill:

- **Facilitate, don't prescribe** — Ask why before what, present trade-offs, let the user decide
- **One topic at a time** — Gate progression with user confirmation, never dump all questions at once
- **Match depth to complexity** — A typo fix needs no discovery phase; a new product does
- **Build on answers** — Each question responds to what you just said

## Example Workflow

**New feature with unclear scope:**

1. `/cpm:discover` — "I want to add multi-tenancy to our app"
   - Claude facilitates conversation about why, who, constraints
   - Produces `docs/plans/multi-tenancy.md`

2. `/cpm:spec` — Reads the brief, builds requirements
   - Facilitates MoSCoW prioritisation, architecture decisions
   - Produces `docs/cpm:specifications/multi-tenancy.md`

3. `/cpm:stories` — Reads the spec, creates tasks
   - Groups into epics, sets dependencies
   - Creates Claude Code tasks ready for implementation

4. Work through tasks using Claude Code's native task system

## What's Included

```
cpm/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── skills/
│   ├── discover/
│   │   └── SKILL.md         # Problem discovery skill
│   ├── spec/
│   │   └── SKILL.md         # Requirements specification skill
│   └── stories/
│       └── SKILL.md         # Work breakdown skill
├── README.md
└── LICENSE
```

## Requirements

- Claude Code with skill/plugin support

## Key Principles

- **Facilitate, don't prescribe** — Guide users through structured discovery to bring out their best thinking
- **One topic at a time** — Gate progression with user confirmation
- **Match depth to complexity** — Scale planning to actual need
- **Right-sized output** — Problem briefs, specs, and tasks that are useful, not bureaucratic

## License

MIT
