---
name: cpm:templates
description: Template discoverability and scaffolding. Lists all CPM artifact templates showing each skill, its output format, whether structural or presentational, and the override path if applicable. Previews any template skeleton. Scaffolds override files for presentational templates. Triggers on "/cpm:templates".
---

# Template Discoverability & Scaffolding

Explore and customise the templates used by CPM artifact-producing skills. CPM uses a two-tier template system:

- **Structural templates** are data contracts parsed by downstream skills. They cannot be overridden — their format is fixed. Examples: problem briefs, specs, epic docs, review files, retro files.
- **Presentational templates** can be overridden with project-level files at `docs/templates/`. They control how information is presented but aren't parsed by other skills. Examples: product briefs, ADRs, communications.

## Subcommands

This skill dispatches based on `$ARGUMENTS`:

- No arguments or `list` → **List** all templates
- `preview {skill}` → **Preview** a template skeleton
- `scaffold {skill}` → **Scaffold** an override file

If `$ARGUMENTS` doesn't match any subcommand, show the help text with available subcommands.

## List

Show all CPM artifact-producing skills with their template metadata. Present as a formatted table:

| Skill | Output Format | Type | Override Path |
|-------|--------------|------|---------------|
| `cpm:discover` | Problem brief | Structural | — (fixed) |
| `cpm:brief` | Product brief | Presentational | `docs/templates/brief.md` |
| `cpm:spec` | Specification | Structural | — (fixed) |
| `cpm:architect` | ADR | Presentational | `docs/templates/architect.md` |
| `cpm:epics` | Epic doc | Structural | — (fixed) |
| `cpm:do` | Epic doc updates | Structural | — (fixed) |
| `cpm:present` | Communication | Presentational | `docs/templates/present/{format}.md` |
| `cpm:review` | Review file | Structural | — (fixed) |
| `cpm:retro` | Retro file | Structural | — (fixed) |

After showing the table, check for existing overrides:
1. **Glob** `docs/templates/*.md` and `docs/templates/present/*.md`.
2. If any overrides exist, list them: "Active overrides: {paths}".
3. If none exist, note: "No project-level overrides found."

## Preview

Usage: `/cpm:templates preview {skill}`

Show the template skeleton for the specified skill. This displays the embedded default template — the markdown structure the skill uses when no project override exists.

To preview a template:
1. Parse `{skill}` from `$ARGUMENTS` (e.g. `brief`, `architect`, `present`). Accept with or without the `cpm:` prefix.
2. Read the corresponding SKILL.md file from the skill directory.
3. Find the output format section (usually under `## Output`) and extract the template from the markdown code block.
4. Display the template to the user.

This works for both structural and presentational templates — users can preview any template to understand the expected format, even if they can't override structural ones.

## Scaffold

Usage: `/cpm:templates scaffold {skill}`

Create a project-level override file for a presentational template. This copies the embedded default template to `docs/templates/` where the user can customise it.

To scaffold a template:
1. Parse `{skill}` from `$ARGUMENTS`.
2. **Check if the template is presentational**. If it's structural, tell the user: "The {skill} template is structural (used as a data contract by downstream skills) and cannot be overridden. Run `/cpm:templates preview {skill}` to view the format."
3. Determine the override path:
   - `cpm:brief` → `docs/templates/brief.md`
   - `cpm:architect` → `docs/templates/architect.md`
   - `cpm:present` → Ask which format to scaffold, then `docs/templates/present/{format}.md`
4. Check if the override file already exists. If so, tell the user and ask whether to overwrite.
5. Read the embedded default template from the skill's SKILL.md.
6. Create the `docs/templates/` directory (and `present/` subdirectory if needed) if it doesn't exist.
7. Write the template to the override path.
8. Tell the user: "Scaffolded template at `{path}`. Edit this file to customise the output format for `{skill}`."

## Guidelines

- **No state management needed.** This skill is stateless — it doesn't produce planning artifacts or run multi-phase facilitation. No progress file required.
- **Fast and informational.** List, preview, and scaffold should each complete in a single response. No AskUserQuestion gating needed for list or preview.
- **Respect the two-tier boundary.** Never scaffold a structural template override. The distinction exists to protect data contracts between skills.
