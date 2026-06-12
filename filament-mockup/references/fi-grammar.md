# Filament v5 `fi-*` grammar cheat-sheet

Reuse Filament's **exact class strings** — never approximate with Tailwind. Each entry below is something that renders wrong on the first try and right once you copy the real grammar. Verify against the live demo when unsure.

---

## Buttons — the taxonomy that bites everyone

A bare `fi-btn` is Filament's **secondary white** button, *not* a primary. Filled colours need the full colour-class string.

```html
<!-- Filled primary -->
<button class="fi-color fi-color-primary fi-bg-color-600 hover:fi-bg-color-500
               fi-text-color-0 hover:fi-text-color-0 fi-btn fi-size-md" type="button">Save</button>

<!-- Secondary (white / outline) — what a bare fi-btn gives you -->
<button class="fi-btn fi-size-md" type="button">Cancel</button>

<!-- Destructive: FILLED danger, not outlined -->
<button class="fi-color fi-color-danger fi-bg-color-600 hover:fi-bg-color-500
               fi-text-color-0 hover:fi-text-color-0 fi-btn fi-size-md" type="button">Remove</button>

<!-- Disabled (e.g. an action blocked by a rule) -->
<button class="fi-color fi-color-primary fi-bg-color-600 … fi-btn fi-size-md" type="button"
        disabled title="Why it's blocked (FR-xx)" style="opacity:.5;cursor:not-allowed;">Offer</button>
```

> Filament's "Delete" actions are **filled red**, not outlined. Eyeballing misleads here — check the demo.

---

## Text input / search — the `content-ctn` trap

The theme contains:

```css
.fi-input-wrp:not(:has(.fi-input-wrp-content-ctn)) > * { flex: 1; }
```

So if the prefix icon and the `<input>` sit directly in `.fi-input-wrp`, they split 50/50 and the placeholder ends up centred. Fix: wrap the input in `.fi-input-wrp-content-ctn`.

```html
<div class="fi-ta-search-field" style="width:18rem;">
  <label class="fi-sr-only">Search</label>
  <div class="fi-input-wrp">
    <div class="fi-input-wrp-prefix fi-input-wrp-prefix-has-content fi-inline">
      <svg class="fi-icon fi-size-md" …>…magnifier…</svg>
    </div>
    <div class="fi-input-wrp-content-ctn">
      <input class="fi-input fi-input-has-inline-prefix" type="search" placeholder="Search name, ID or email">
    </div>
  </div>
</div>
```

Use the **same grammar** for the topbar global search and the table search so they're visually consistent. A trailing suffix (units, calendar icon) goes in a sibling `.fi-input-wrp-suffix fi-inline`.

---

## Textarea — different selector from inputs

Filament styles textareas via `.fi-fo-textarea textarea`, *not* `input.fi-input`. Use the wrapper or the text sits flush in the corner with no padding.

```html
<div class="fi-input-wrp fi-fo-textarea"><textarea rows="3">…</textarea></div>
```

## Select (native)

```html
<div class="fi-input-wrp fi-fo-select fi-fo-select-native">
  <div class="fi-input-wrp-content-ctn">
    <select class="fi-select-input"><option>…</option></select>
  </div>
</div>
```

## Form field wrapper (label + control)

```html
<div class="fi-fo-field">
  <label class="fi-fo-field-label"><span class="fi-fo-field-label-content">Field name</span></label>
  <div class="fi-input-wrp" style="margin-top:.3rem;">
    <div class="fi-input-wrp-content-ctn"><input class="fi-input" type="text" value="…"></div>
  </div>
</div>
```

---

## Table toolbar — search + filter funnel + column manager

These three are Filament defaults. Note the active-filter badge on the funnel.

```html
<div class="fi-ta-header-toolbar" style="display:flex;align-items:center;justify-content:flex-end;gap:.5rem;">
  <!-- search field (above) -->
  <button class="fi-icon-btn fi-size-md fi-ac-icon-btn-action fi-force-enabled" title="Filter" type="button">
    <svg class="fi-icon fi-size-md" …>…funnel…</svg>
    <div class="fi-icon-btn-badge-ctn"><span class="fi-badge fi-size-xs">0</span></div>
  </button>
  <button class="fi-icon-btn fi-size-md fi-ac-icon-btn-action fi-force-enabled" title="Column manager" type="button">
    <svg class="fi-icon fi-size-md" …>…columns…</svg>
  </button>
</div>
```

> Cross-cutting **filters can't live inside a Filament table** — render them in a custom Livewire section *above* the table (mark it `.mk-custom`) that drives the table query.

## Table rows

```html
<tr class="fi-ta-row fi-clickable" style="cursor:pointer;" onclick="mkShow('detail')">
  <td style="padding:.7rem 1rem;font-size:.85rem;color:var(--gray-700);border-top:1px solid var(--gray-100);">…</td>
</tr>
```

## Badges (status pills)

```html
<span class="fi-badge fi-size-sm fi-color fi-color-success fi-text-color-700"
      style="padding:.2rem .55rem;border-radius:9999px;font-size:.72rem;font-weight:600;">Active</span>
```

Drive colour from a JS status map (`success` / `warning` / `info` / `danger` / `gray`) so it's consistent everywhere.

---

## Sections

`.fi-section` has **no border** — it's `border-radius: var(--radius-xl)` + a box-shadow ring. Don't add `1px solid` or it looks wrong. Just use the class and pad it. Section heading: `.fi-section-header-heading`.

## Modals

```html
<div class="mk-modal" id="modal-offer">
  <div class="mk-modal__backdrop" onclick="mkCloseModal()"></div>
  <div class="mk-modal__window">
    <div class="fi-modal-header" style="padding:1.5rem 1.5rem .5rem;text-align:center;">
      <h2 class="fi-modal-heading" style="font-size:1.15rem;font-weight:700;">Offer a space</h2>
      <p class="fi-modal-description" style="font-size:.85rem;color:var(--gray-500);">…</p>
    </div>
    <div class="fi-modal-content" style="padding:1rem 1.5rem;">…fields…</div>
    <div class="fi-modal-footer-actions" style="display:flex;justify-content:flex-end;gap:.5rem;padding:1rem 1.5rem 1.5rem;">
      <button class="fi-btn fi-size-md" onclick="mkCloseModal()">Cancel</button>
      <button class="fi-color fi-color-primary fi-bg-color-600 … fi-btn fi-size-md" onclick="mkCloseModal()">Send</button>
    </div>
  </div>
</div>
```

---

## Layout: sidebar + topbar alignment

In a sidebar-nav layout the theme sticks the sidebar at `top:64px`, dropping it below the topbar so the dividers don't line up. Pin the sidebar to the top, equalise heights, and put the bottom border on `.fi-topbar` itself (the `-ctn` border gets painted over by the content area).

```css
.fi-sidebar { top: 0 !important; }
.fi-sidebar-header-ctn { height: 4rem; min-height: 4rem; border-bottom: 1px solid var(--gray-200); background: #fff; }
.fi-topbar { height: 4rem; min-height: 4rem; box-shadow: none; border-bottom: 1px solid var(--gray-200); }
```

## Two-column detail/edit layout

```css
.mk-cols { display: grid; grid-template-columns: 1fr; gap: 1.5rem; }
@media (min-width: 1024px) { .mk-cols { grid-template-columns: minmax(0,1fr) 22rem; align-items: start; } }
```

---

## Dates

Pick one format and use it everywhere (e.g. `10 Jun 2027`, 3-letter month). Consistency reads as polish.

---

## Data-driven rendering pattern

Don't hand-write rows. Data in arrays → render with template strings. Compute totals (don't type them) so the dashboard reconciles with its tables.

```js
const ROWS = [ { name:'…', status:'active' }, … ];
const STATUS = { active:{label:'Active',color:'success'}, pending:{label:'Pending',color:'warning'} };
const badge = s => `<span class="fi-badge fi-size-sm fi-color fi-color-${STATUS[s].color} fi-text-color-700"
  style="padding:.2rem .55rem;border-radius:9999px;font-size:.72rem;font-weight:600;">${STATUS[s].label}</span>`;

function renderRows(){
  const cell='padding:.7rem 1rem;font-size:.85rem;color:var(--gray-700);border-top:1px solid var(--gray-100);';
  document.getElementById('mk-rows').innerHTML = ROWS.map(r=>`
    <tr class="fi-ta-row fi-clickable" style="cursor:pointer;">
      <td style="${cell}font-weight:600;color:var(--gray-900);">${r.name}</td>
      <td style="${cell}">${badge(r.status)}</td>
    </tr>`).join('');
}
const total = ROWS.length;                              // compute, don't hard-code
```

For a screen with variants, write one parameterised function (`entryHTML(mode)`) that branches on `mode` rather than duplicating near-identical screens.
