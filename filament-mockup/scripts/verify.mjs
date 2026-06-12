/**
 * Phase 5 — verify the mockup renders correctly (don't eyeball).
 *
 * Copy this into the project's docs/mockups/reference/ dir (or run it from there),
 * point MOCKUP at the file, add assertions for whatever you just built, run it,
 * confirm `errors: []` + assertions, then DELETE your temp copy to keep the tree clean.
 *
 * Usage:
 *   cd docs/mockups/reference
 *   cp "$CLAUDE_PLUGIN_ROOT/scripts/verify.mjs" _r.mjs   # or the script's path in this plugin
 *   # edit the MOCKUP filename + assertions
 *   node _r.mjs && rm _r.mjs
 *
 * cwd can reset to the repo root between shell calls — that's why the path is
 * resolved from __dirname, not relative to cwd.
 *
 * Requires Node + Playwright (see SKILL.md "Setup"):
 *   npm i -D playwright && npx playwright install chromium
 */
import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const MOCKUP = '<project>-admin-mockups.html';                 // <-- set this
const file = 'file://' + join(__dirname, '..', MOCKUP);        // reference/ is one level below mockups/

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

const errors = [];
page.on('console', m => m.type() === 'error' && errors.push(m.text()));
page.on('pageerror', e => errors.push('PAGEERROR: ' + e.message));

await page.goto(file, { waitUntil: 'networkidle' });

// ── Assertions — replace with checks for what you built this round ──
const results = {};

// Example: a screen switches and renders rows.
await page.evaluate(() => window.mkShow('index'));
results.rowCount = await page.locator('#mk-rows tr').count();

// Example: a modal opens and has the expected heading.
// await page.evaluate(() => window.mkOpenModal('offer'));
// results.modalHeading = await page.locator('#modal-offer .fi-modal-heading').innerText();

// Example: measure a computed style to confirm fidelity.
// results.btnBg = await page.locator('button.fi-color-primary').first()
//   .evaluate(el => getComputedStyle(el).backgroundColor);

console.log(JSON.stringify({ errors, ...results }, null, 2));

// To diagnose WHY a style is off, attach CDP and inspect matched rules:
//   const cdp = await page.context().newCDPSession(page);
//   await cdp.send('DOM.enable'); await cdp.send('CSS.enable');
//   ... CSS.getMatchedStylesForNode(nodeId) ...

await browser.close();
process.exit(errors.length ? 1 : 0);
