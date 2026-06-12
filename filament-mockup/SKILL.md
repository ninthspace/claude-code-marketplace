---
name: filament-mockup
description: "Build static, high-fidelity Filament v5 admin mockups from a brief or spec for stakeholder sign-off, BEFORE scaffolding any real Filament/Laravel code. Use when asked to 'create a Filament mockup', 'admin backend mockup', 'Filament v5 mockup', 'mock up the admin panel', turn a brief/spec/PRD into clickable admin screens, or produce sign-off mockups for a Filament back-end. Produces one self-contained HTML file using the real captured Filament theme CSS. NOT for production Filament code, nor for customer-facing/front-end mockups."
license: Proprietary
metadata:
  author: chris-aves
  version: "1.0"
---

# Filament v5 admin mockups — brief/spec → sign-off

Turn a product brief or spec into a set of high-fidelity, static, **throwaway** Filament-v5 admin mockups for stakeholder sign-off — *before* any Laravel/Filament code is scaffolded.

## What this produces

A **single self-contained HTML file** that looks pixel-accurate to a real Filament v5 panel (it links the real captured theme CSS and reuses Filament's exact `fi-*` markup), is clickable enough to walk a stakeholder through every screen and flow, and is **discarded at build time** (the real Filament build regenerates all of it natively).

| It IS | It is NOT |
|-------|-----------|
| A sign-off artefact | Production code |
| Real Filament `fi-*` CSS + markup | A scaffolded Filament resource/panel |
| Vanilla-JS screen switching | Livewire / Alpine / a server |
| Data-driven by small JS arrays | Connected to a DB or API |
| Faithful to the brief's FRs | A place to invent new features |

**Why static, not a real scaffold:** speed of iteration (edit one file vs re-migrate/re-seed), zero environment (opens by `file://`), it keeps the conversation on *the spec* rather than the framework, and it's throwaway by design.

## When to use

Use when the user wants admin/back-end screens validated against a brief/spec before build — "Filament mockup", "admin backend mockup", "mock up the admin panel", "turn this brief into Filament screens". **Prerequisite:** a brief/spec with **numbered functional requirements** (FR-01, FR-02, …) — numbering is what makes traceability auditable. If the brief has no FR numbers, add them (or agree a numbering) first.

Do **not** use for production Filament code or for customer-facing/front-end mockups.

## Relationship to the `frontend-design` skill

Do **not** invoke `frontend-design` for these mockups — for either styling *or* page/content planning. The two skills pull in opposite directions:

- `frontend-design` optimises for a **distinctive, memorable, non-generic** aesthetic — bold typography, custom palettes, grid-breaking layouts. That is exactly what you do **not** want here: the value of a Filament admin mockup is **maximum fidelity to Filament's existing design language** (the captured `fi-*` theme, Albert Sans, standard resource layouts). A "creative" admin mockup misrepresents what will actually be built and undermines sign-off.
- For **which pages to create and the content of each page**, the drivers are the **FR → screen matrix** (the brief) and **Filament's resource archetypes** (index / detail / edit / config / modal / dashboard / profile) — see Phase 2. `frontend-design` does not add information-architecture or admin-content-planning value.

The boundary: `frontend-design` is the right skill for the **customer-facing / front-end** mockups that sit alongside this one. This skill is for the **admin back-end** only. Use each on its own side of that line.

## Pipeline position

```
brief / spec  →  MOCKUP (sign-off)  →  spec (firmed up)  →  epics  →  build
                 ▲ this skill
```

The mockup is the cheapest place to find a missing screen, a wrong field, or a flow that doesn't close. So the cardinal rule:

> **Every element traces to an FR.** If something seems needed but isn't in the brief, flag it as a *proposed* requirement — don't silently add it. Invented UI that survives sign-off leaks into the spec as a phantom requirement.

## Two non-negotiable conventions

1. **The `mk-` namespace.** Everything you add that isn't Filament (screen switcher, navigator, custom-component annotations, modal shims) is prefixed `mk-`. Everything `fi-*` is real Filament. The boundary must be visible in the source and trivial to strip.
2. **Verify, don't eyeball.** For anything subtle (spacing, whether a class is actually matching, computed styles), measure it with Playwright (`scripts/verify.mjs`), then delete the temp script. A clean run = no console errors + your assertions pass.

## Setup (once per project)

Both bundled scripts (`capture.mjs`, `verify.mjs`) need **Node** and **Playwright**. From the project root:

```bash
npm i -D playwright            # add `npm init -y` first if there's no package.json
npx playwright install chromium   # downloads the browser binary (cached globally; a no-op if already present)
```

Notes:
- Node resolves `import { chromium } from 'playwright'` by walking up to the nearest `node_modules`, so a **project-local** dev install works even though the scripts run from `docs/mockups/reference/`.
- A Playwright installed into **global npm** also satisfies the import. A **Homebrew `playwright` CLI** does **not** — it's a separate binary that `import 'playwright'` can't resolve. If `node verify.mjs` throws `Cannot find package 'playwright'`, do the project-local install above.
- The browser binaries are cached per-machine (`~/Library/Caches/ms-playwright` on macOS), so `playwright install` only downloads once across all projects.

---

## Workflow

### Phase 0 — Capture the real Filament skin (once per project)

Fidelity comes from lifting the **compiled theme CSS** and design tokens from a real Filament v5 panel, not hand-rolling them.

Run `scripts/capture.mjs` against a real panel (the official demo at `https://demo.filamentphp.com` publishes guest credentials, or use any Filament app you control). It downloads the compiled theme stylesheet into `reference/css/`. Then copy into the mockup:

- the **theme `<link>`** (note the Filament version in a comment — it's a dated snapshot);
- the **`:root` palette tokens** (oklch variables for primary/danger/gray/info/success/warning);
- the **font** (the demo uses Albert Sans via bunny.net).

Also **screenshot the real components** you'll reproduce (buttons, table, search, modals). These are your fidelity reference and your evidence when someone says "that doesn't look like Filament."

### Phase 1 — Scaffold the file

Start from `assets/mockup-shell.html` — a working single-file scaffold containing the document shell, the `mk-` stylesheet, the sidebar/topbar, the bottom navigator, the "this is a mockup" banner with the indicator toggle, and the vanilla-JS controllers (`mkShow`, `mkOpenModal`, `mkCloseModal`, `mkToggleCustom`). Drop in the captured theme link + tokens from Phase 0.

Copy the body classes verbatim from a real panel (`fi-body fi-panel-admin fi-body-has-navigation fi-body-has-topbar`) and keep `class="fi"` on `<html>` — they activate the layout rules in the theme CSS.

### Phase 2 — Inventory the screens from the FRs

Before writing markup, build an **FR → screen matrix**. Map each FR to the screen that satisfies it. Typical Filament archetypes: dashboard (stat + table/chart widgets), resource index (table + toolbar), resource detail/edit (form sections), config screens, action modals, empty state, profile/preferences. Anything in the brief with no home is a missing screen; any element with no FR is an oversight (flag it) or scope creep (cut it). This matrix is also your coverage checklist for Phase 6.

### Phase 3 — Build screens with real `fi-*` grammar

Reuse Filament's **exact class strings** — never approximate with Tailwind. See `references/fi-grammar.md` for the full cheat-sheet (button taxonomy, the search-field `content-ctn` trap, textarea/select, table toolbar, badges, sections, sidebar+topbar alignment, dates). Each entry there is a thing that's wrong on the first try and right once you copy the real grammar.

Mark genuinely **custom (Livewire-in-Filament) components** — filter bars, timelines, schedule matrices, third-party-backed panels — with the dashed `.mk-custom` box + an FR-citing tag. Whether a piece is stock-Filament or custom-Livewire is one of the most useful things the mockup communicates, because it drives the build estimate.

### Phase 4 — Wire data-driven rendering

Don't hand-write table rows. Put data in small JS arrays and render with template strings (see the example in `assets/mockup-shell.html` and `references/fi-grammar.md`). Two rules:

- **Reconcile the numbers.** A dashboard total must equal the sum of its rows — compute it (`arr.reduce(...)`), don't type it. Mismatches destroy stakeholder trust.
- **Parameterise variant screens.** If a detail screen has two states, write one `entryHTML(mode)` that branches, not two near-identical screens.

### Phase 5 — Verify with Playwright

Use `scripts/verify.mjs` (copy it into the project's `reference/` dir, point it at the mockup, add assertions for what you just built). Run it, confirm `errors: []` and assertions pass, then **delete the temp script** to keep the tree clean. To diagnose *why* a style is off, use CDP `CSS.getMatchedStylesForNode` to see which theme rule is matching.

> Shell cwd can reset to the repo root between calls — `cd` into `reference/` each time and resolve the mockup with `__dirname` + `join(__dirname,'..',…)`.

### Phase 6 — Review loop & sign-off

- Send the rendered file (single-file means the stakeholder can open it themselves). Take change requests **one at a time**; edit, re-verify, send back.
- When told "that doesn't look like Filament," go back to the real demo, capture the exact markup/screenshot, match it — don't argue from memory.
- Before declaring done, run a **coverage audit**: a table walking every FR and where it's represented (or why it's legitimately out of scope — e.g. customer-facing FRs in an admin mockup, or pure email/system behaviours with no static surface). This audit opens the spec and becomes the build checklist.

See `references/pitfalls.md` for the symptom→cause→fix table and the per-project / per-screen / pre-sign-off checklists.

---

## Bundled files

| File | Use |
|------|-----|
| `assets/mockup-shell.html` | Ready-to-use single-file scaffold (shell, `mk-` styles, navigator, banner, JS controllers, one example screen + modal). Start here in Phase 1. |
| `scripts/capture.mjs` | Phase 0 skin capture — downloads the compiled theme CSS from a real Filament panel. |
| `scripts/verify.mjs` | Phase 5 verification template — loads the mockup headless, reports console errors, runs assertions. |
| `references/fi-grammar.md` | The `fi-*` markup cheat-sheet — buttons, inputs/search, textarea/select, table toolbar, badges, sections, layout, data-rendering pattern. |
| `references/pitfalls.md` | Symptom→cause→fix table and the checklists. |
