/**
 * Phase 0 — capture the real Filament v5 skin.
 *
 * Downloads the compiled theme stylesheet(s) from a real Filament panel into
 * ./css/ so the mockup can render the genuine `fi-*` component styles offline.
 *
 * Usage (run from the plugin's bundled scripts/ dir — point the download at your
 * project's reference dir, or cd there first):
 *   cd docs/mockups/reference
 *   node "$CLAUDE_PLUGIN_ROOT/scripts/capture.mjs"   # or the script's path in this plugin
 *
 * The official demo (https://demo.filamentphp.com) publishes guest credentials
 * on its login screen — fine for harvesting CSS. Never hard-code real creds.
 *
 * After running:
 *   - copy the :root palette tokens + font <link> from the panel's <head> into the mockup;
 *   - note the Filament version (footer of the demo, or composer.lock in your app) in a comment.
 *
 * Requires Node + Playwright (see SKILL.md "Setup"):
 *   npm i -D playwright && npx playwright install chromium
 */
import { chromium } from 'playwright';
import { writeFile, mkdir } from 'fs/promises';

const PANEL_LOGIN = process.env.FI_LOGIN || 'https://demo.filamentphp.com/admin/login';
const EMAIL       = process.env.FI_EMAIL || 'admin@filamentphp.com';
const PASSWORD    = process.env.FI_PASSWORD || 'demo.Filament@2021!';

await mkdir('css', { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage();

await page.goto(PANEL_LOGIN, { waitUntil: 'networkidle' });
// Best-effort login — selectors match Filament's default login form.
try {
  await page.fill('input[type=email], #data\\.email', EMAIL, { timeout: 4000 });
  await page.fill('input[type=password], #data\\.password', PASSWORD, { timeout: 4000 });
  await page.click('button[type=submit]');
  await page.waitForLoadState('networkidle');
} catch {
  console.log('No login form found (already in, or different panel) — continuing.');
}

// Grab every stylesheet; keep the ones that look like the compiled Filament theme.
const hrefs = await page.$$eval('link[rel=stylesheet]', ls => ls.map(l => l.href));
const themeHrefs = hrefs.filter(h => /theme|filament|app/i.test(h));

let saved = 0;
for (const href of themeHrefs) {
  try {
    const res = await page.request.get(href);
    if (!res.ok()) continue;
    const css = await res.text();
    if (css.length < 5000) continue;           // skip tiny/util sheets
    const name = (href.split('/').pop() || 'theme.css').split('?')[0];
    await writeFile(`css/${name}`, css);
    console.log(`saved css/${name}  (${(css.length/1024|0)}KB)`);
    saved++;
  } catch (e) { console.log(`skip ${href}: ${e.message}`); }
}

// Dump the :root token block(s) so you can paste the palette into the mockup head.
const rootCss = await page.evaluate(() => {
  const out = [];
  for (const sheet of document.styleSheets) {
    let rules; try { rules = sheet.cssRules; } catch { continue; }
    for (const r of rules || []) {
      if (r.selectorText === ':root' && r.style.cssText.includes('--')) out.push(r.cssText);
    }
  }
  return out.join('\n\n');
});
await writeFile('css/_root-tokens.css', rootCss);
console.log(`saved css/_root-tokens.css  (paste the palette into the mockup <head>)`);

console.log(`\nDone. ${saved} stylesheet(s) captured. Point the mockup's theme <link> at the biggest one.`);
await browser.close();
