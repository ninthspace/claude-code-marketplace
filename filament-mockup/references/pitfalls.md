# Pitfalls & checklists

## Symptom → cause → fix

| Symptom | Cause | Fix |
|---------|-------|-----|
| Buttons look washed-out / white | Bare `fi-btn` = secondary | Full `fi-color fi-bg-color-600 fi-text-color-0 …` string (fi-grammar §Buttons) |
| Search placeholder centred | Missing `.fi-input-wrp-content-ctn` wrapper | Wrap the `<input>` (fi-grammar §Text input) |
| Textarea text flush to corner | `input.fi-input` rule doesn't match `<textarea>` | Use the `.fi-fo-textarea` wrapper |
| Topbar/sidebar dividers don't align | Sidebar stuck at `top:64px` | Pin sidebar `top:0`, equalise heights + border |
| Header border missing on the right | Border on `-ctn`, painted over by content | Move border to `.fi-topbar` |
| Section looks boxed-in / wrong | Added a real `border` | `.fi-section` is radius + ring only — no border |
| Main content invisible | Filament's Alpine opacity-fade never runs | `.fi-main-ctn { opacity:1 !important }` |
| Filters won't sit in the table | Filament tables can't host cross-cutting filters inline | Custom Livewire filter section above the table (`.mk-custom`) |
| Numbers don't add up | Hand-written figures | Compute from one data array (`arr.reduce(...)`) |
| Phantom features in the spec | Invented UI with no FR | Trace every element to an FR; flag genuine new needs as proposed requirements |
| Playwright `ERR_FILE_NOT_FOUND` | cwd reset to repo root between calls | `cd` into `reference/`; resolve path from `__dirname` |

---

## Checklists

### Per project (once)
- [ ] Capture theme CSS + tokens + font from a real Filament v5 panel (`scripts/capture.mjs` → `reference/`)
- [ ] Note the captured Filament version in a comment
- [ ] Scaffold from `assets/mockup-shell.html`; drop in the theme link + tokens
- [ ] Build the FR → screen inventory matrix

### Per screen
- [ ] Every field / column / widget cites an FR
- [ ] Stock-Filament vs custom-Livewire pieces marked (`.mk-custom` + FR-citing tag)
- [ ] Real `fi-*` grammar (buttons, inputs, table, badges, sections)
- [ ] Data-driven; numbers reconcile across screens
- [ ] Added to the bottom navigator
- [ ] Playwright-verified (no console errors; assertions pass)

### Before sign-off
- [ ] Coverage audit table: every FR mapped, or explicitly marked out-of-scope (customer-facing / pure email-system behaviours / doc deliverables)
- [ ] Consistent date format throughout
- [ ] Indicator toggle defaults OFF (clean view first)
- [ ] Temp verification scripts deleted; working tree clean
