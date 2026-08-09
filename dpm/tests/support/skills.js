/**
 * Reading a dpm SKILL.md, and binding a test to it in both directions.
 *
 * Twenty-two skills are converted the same way, so what a conversion test needs is here once
 * rather than twenty-two times. The part worth stating is the binding, because it is what stops
 * a conversion test from quietly becoming a test of the tools:
 *
 * - **Every `dpm_*` name the file mentions resolves to a real tool.** Without this a skill can
 *   instruct a run to call something that does not exist, and every behavioural test still
 *   passes, because the test calls the tools it knows about rather than the ones the file names.
 * - **Every tool the test drove is named in the file.** Without this the test drifts: it keeps
 *   passing while the file it claims to exercise loses the call the assertion depends on.
 *
 * Neither direction needs a manifest, and deliberately so. A hand-kept list of "the tools this
 * skill uses" is a third place the truth lives, and it is the one nothing fails on when it goes
 * stale.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SKILLS = join(import.meta.dirname, '..', '..', 'skills');

/**
 * @param {string} name The skill's directory name, which is also its `name:` in the front matter.
 * @returns {string}
 */
export function skillSource(name) {
  return readFileSync(join(SKILLS, name, 'SKILL.md'), 'utf8');
}

/**
 * The front matter as key/value pairs. Deliberately shallow — the fields a skill declares are
 * flat strings, and a parser richer than the format invites assertions the format cannot carry.
 *
 * @param {string} source
 * @returns {Record<string, string>}
 */
export function frontMatter(source) {
  const match = source.match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) return {};

  return Object.fromEntries(match[1].split('\n')
    .map((line) => line.match(/^([a-z_]+):\s*(.*)$/))
    .filter(Boolean)
    .map((field) => [field[1], field[2].trim()]));
}

/**
 * Every distinct `dpm_*` name the file mentions, in sorted order.
 *
 * @param {string} source
 * @returns {string[]}
 */
export function toolNames(source) {
  return [...new Set(source.match(/dpm_[a-z_]+/g) ?? [])].sort();
}

/**
 * The body under a heading, up to the next heading at the same level or above.
 *
 * Sections are how a skill's steps are addressed — "Step 6b", "Section 5" — so a check on a
 * retained behaviour can be scoped to the step that owns it rather than run over the whole file.
 * A rule found anywhere in a four-hundred-line file is a weaker claim than the same rule found
 * in the step that has to apply it.
 *
 * @param {string} source
 * @param {string} heading Matched as a substring of the heading line, so "Step 6b" finds it.
 * @returns {string} The section body, or an empty string when no heading matches.
 */
export function section(source, heading) {
  const lines = source.split('\n');
  const start = lines.findIndex((line) => /^#{2,6} /.test(line) && line.includes(heading));
  if (start === -1) return '';

  const level = lines[start].match(/^#+/)[0].length;
  const rest = lines.slice(start + 1);
  const end = rest.findIndex((line) => {
    const hashes = line.match(/^(#{1,6}) /);
    return hashes && hashes[1].length <= level;
  });

  return (end === -1 ? rest : rest.slice(0, end)).join('\n');
}

/**
 * A dispatcher that records which tools were called and which arguments each call carried, so a
 * run can be checked against the file that prescribed it.
 *
 * **The arguments are recorded because the tool names alone do not catch the failure FR4 is
 * about.** A skill that called `dpm_create_requirement` and never mentioned `class` would pass a
 * name-level binding in both directions while leaving the one column the requirement exists to
 * protect unspecified — and the run would keep working, because the test knows to pass it.
 *
 * @param {object[]} tools
 * @returns {{call: Record<string, Function>, used: Set<string>, passed: Map<string, Set<string>>}}
 */
export function recorder(tools) {
  const used = new Set();
  const passed = new Map();

  const call = Object.fromEntries(tools.map((tool) => [
    tool.name,
    (args) => {
      used.add(tool.name);
      const keys = passed.get(tool.name) ?? new Set();
      for (const key of Object.keys(args ?? {})) keys.add(key);
      passed.set(tool.name, keys);

      return tool.handler(args);
    },
  ]));

  return { call, used, passed };
}

/**
 * The arguments of a tool whose meaning is the value itself — the ones declaring a fixed set of
 * terms. These are what a conversion is most likely to drop back into prose, because a band or a
 * polarity reads naturally as a heading and only fails once something has to read it back.
 *
 * @param {object} tool
 * @returns {string[]}
 */
export function valuedArguments(tool) {
  return Object.entries(tool.inputSchema?.properties ?? {})
    .filter(([, schema]) => Array.isArray(schema.enum))
    .map(([name]) => name);
}
