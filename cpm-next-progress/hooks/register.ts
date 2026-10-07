import type { EngineInterface, Register } from 'claude-code'

import type { Drift, EpicFile, LiveDoc } from './progress'
import {
  artifactUrlIn, buildItems, dateOf, defaultBuildOrder, describeDrift, diff, fillTemplate, modelNote, parseBuildOrder, parseDocs, pendingJson, withArtifact,
} from './progress'

const ORDER_FILE = /^\d+-build-order\.json$/
const SPEC_FILE = /^(\d+)-spec-.*\.md$/
const PAGE_FILE = /(?:^|\/)\.claude\/cpm-next-progress\/(\d+-build-order)\.html$/
const EPIC_FILE = /-epic-.*\.md$/
const WRITING_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit', 'Bash'])
const COMMAND = 'progress-tracker'
const WORK_DIR = '.claude/cpm-next-progress'

type Listing = { name: string; mtimeMs: number; size: number }
type Check = { lines: string[]; drift: Drift[] }

async function findRoot($: EngineInterface): Promise<string | null> {
  let dir = await $.session.cwd()
  for (;;) {
    if (await $.fs.exists(`${dir}/docs/specifications`)) return dir
    const cut = dir.lastIndexOf('/')
    if (cut <= 0) return null
    dir = dir.slice(0, cut)
  }
}

async function listDocs($: EngineInterface, dir: string, pattern: RegExp): Promise<Listing[]> {
  if (!(await $.fs.exists(dir))) return []

  return (await $.fs.list(dir)).filter(e => e.kind === 'file' && pattern.test(e.name)).sort((a, b) => a.name.localeCompare(b.name))
}

const signatureOf = (...lists: Listing[][]) => lists.map(list => list.map(e => `${e.name}:${e.mtimeMs}:${e.size}`).join(',')).join('|')

async function readEpics($: EngineInterface, root: string): Promise<EpicFile[]> {
  const files: EpicFile[] = []
  for (const e of await listDocs($, `${root}/docs/epics`, EPIC_FILE)) {
    files.push({ name: e.name, text: await $.fs.read(`${root}/docs/epics/${e.name}`) })
  }

  return files
}

/** Reads one collection of the artifact. Reads need no approval from auto mode; this mod never writes. */
async function readLive($: EngineInterface, url: string, collection: string): Promise<LiveDoc[]> {
  const result = await $.tool.call({ tool: 'ArtifactData', action: 'list', url, collection, query: { limit: 1000 } })
  if ('deny' in result && result.deny !== undefined) throw new Error(result.deny)
  if (result.isError === true) throw new Error(result.text ?? 'the read failed')

  return parseDocs(result.text ?? '')
}

/** Compares one build-order file with the epic docs and the live artifact, and saves the writes that would bring them in line. */
async function checkOne($: EngineInterface, root: string, name: string): Promise<{ line: string; drift?: Drift }> {
  const order = parseBuildOrder(await $.fs.read(`${root}/docs/specifications/${name}`))
  if (order.artifact === undefined) return { line: `${name}: no tracker yet; run /${COMMAND} init ${name}` }

  const { items, missing } = buildItems(order, await readEpics($, root), dateOf(await $.clock.now()))
  const live = await readLive($, order.artifact, 'items')
  const liveMeta = (await readLive($, order.artifact, 'meta')).find(d => d.id === 'tracker')
  const writes = diff(items, { title: order.title, spec: order.spec ?? '', decisions: order.decisions ?? [] }, live, liveMeta)
  const skipped = missing.length === 0 ? '' : `; not found in the epics: ${missing.join(', ')}`
  if (writes.length === 0) return { line: `${name}: up to date${skipped}` }

  const file = `${root}/${WORK_DIR}/${name.replace(/\.json$/, '')}.pending.json`
  const drift: Drift = { name, url: order.artifact, file, writes }
  await $.fs.write(file, pendingJson(drift))

  return { line: `${describeDrift(drift)}${skipped}`, drift }
}

let isChecking = false

/**
 * Checks every tracker in the repository. Unless forced, it does nothing when the epic docs and
 * build-order files are as they were at the last check, so a tool call that changed neither costs
 * two directory listings.
 */
async function checkAll($: EngineInterface, isForced: boolean): Promise<Check> {
  if (isChecking) return { lines: ['A check is already running.'], drift: [] }
  isChecking = true
  try {
    const root = await findRoot($)
    if (root === null) return { lines: ['No docs/specifications folder in this directory or above it.'], drift: [] }
    const orders = await listDocs($, `${root}/docs/specifications`, ORDER_FILE)
    if (orders.length === 0) return { lines: [`No docs/specifications/NN-build-order.json in ${root}.`], drift: [] }
    const signature = `${root}|${signatureOf(orders, await listDocs($, `${root}/docs/epics`, EPIC_FILE))}`
    if (!isForced && signature === (await $.store.get(`checked:${root}`))) return { lines: [], drift: [] }

    const lines: string[] = []
    const drift: Drift[] = []
    let isFailed = false
    for (const order of orders) {
      try {
        const found = await checkOne($, root, order.name)
        lines.push(found.line)
        if (found.drift !== undefined) drift.push(found.drift)
      } catch (error) {
        isFailed = true
        lines.push(`${order.name}: check failed: ${error instanceof Error ? error.message : String(error)}`)
      }
    }
    // A failed check is repeated at the next change; a finished one, drift or not, is reported once.
    if (!isFailed) await $.store.set(`checked:${root}`, signature)

    return { lines, drift }
  } finally {
    isChecking = false
  }
}

/** Adds the generated-files folder to the repository's .gitignore unless a line already covers it. */
async function ignoreWorkDir($: EngineInterface, root: string): Promise<boolean> {
  const path = `${root}/.gitignore`
  const text = (await $.fs.exists(path)) ? await $.fs.read(path) : ''
  if (text.split(/\r?\n/).some(line => line.trim().replace(/^\//, '').replace(/\/$/, '') === WORK_DIR)) return false
  await $.fs.write(path, `${text}${text === '' || text.endsWith('\n') ? '' : '\n'}/${WORK_DIR}\n`)

  return true
}

/**
 * The build-order file a spec number, spec file or build-order file names, writing a first one from
 * the spec's epics when none exists yet.
 */
async function orderFileFor($: EngineInterface, root: string, arg: string): Promise<{ name: string; created?: string } | string> {
  const name = arg.split('/').at(-1) ?? arg
  if (ORDER_FILE.test(name)) {
    return (await $.fs.exists(`${root}/docs/specifications/${name}`)) ? { name } : `${root}/docs/specifications/${name} does not exist.`
  }
  const number = /^\d+$/.test(name) ? name.padStart(2, '0') : SPEC_FILE.exec(name)?.[1]
  if (number === undefined) return `Name a spec or a build-order file: /${COMMAND} 01, or /${COMMAND} 01-build-order.json`

  const orderName = `${number}-build-order.json`
  if (await $.fs.exists(`${root}/docs/specifications/${orderName}`)) return { name: orderName }
  const spec = (await listDocs($, `${root}/docs/specifications`, SPEC_FILE)).find(e => SPEC_FILE.exec(e.name)?.[1] === number)
  if (spec === undefined) return `No docs/specifications/${number}-spec-*.md in ${root}.`
  const order = defaultBuildOrder({ name: spec.name, text: await $.fs.read(`${root}/docs/specifications/${spec.name}`) }, await readEpics($, root))
  if (order.phases.length === 0) return `No stories in docs/epics/${number}-*-epic-*.md yet; plan the epics for ${spec.name} first.`
  await $.fs.write(`${root}/docs/specifications/${orderName}`, `${JSON.stringify(order, null, 2)}\n`)
  const stories = order.phases.reduce((n, p) => n + p.items.length, 0)

  return { name: orderName, created: `${stories} ${stories === 1 ? 'story' : 'stories'} in ${order.phases.length} ${order.phases.length === 1 ? 'phase' : 'phases'}, one per epic` }
}

/** Writes the page for a spec's tracker; publishing it is left to the model, which is the one the permission system evaluates. */
async function prepare($: EngineInterface, arg: string): Promise<string> {
  const root = await findRoot($)
  if (root === null) return 'No docs/specifications folder in this directory or above it.'
  const found = await orderFileFor($, root, arg.trim())
  if (typeof found === 'string') return found
  const { name } = found
  const order = parseBuildOrder(await $.fs.read(`${root}/docs/specifications/${name}`))
  if (order.artifact !== undefined) return `${name} already has a tracker: ${order.artifact}`

  const repo = root.split('/').filter(Boolean).at(-1) ?? root
  const page = `${root}/${WORK_DIR}/${name.replace(/\.json$/, '')}.html`
  await $.fs.write(page, fillTemplate(await $.fs.read(`${$.plugin.root}/page/tracker.html`), order, repo))
  const isIgnored = await ignoreWorkDir($, root)

  return [
    found.created === undefined ? `Using docs/specifications/${name}.` : `Wrote docs/specifications/${name}: ${found.created}. Edit it to change the order or phases.`,
    `Page written to ${page}.${isIgnored ? ` Added /${WORK_DIR} to .gitignore.` : ''}`,
    `Ask Claude to publish it: the Artifact tool, icon "checklist", capabilities {"db":{"rules":[{"path":"","read":"view","write":"admin"}]}}.`,
    `The link is saved to ${name} when it publishes, and Claude is then given the rows to write.`,
  ].join('\n')
}

/**
 * After the model publishes a tracker page, saves the link to its build-order file and returns the
 * note for the first rows. A republish of a page that already has a link changes nothing.
 */
async function savePublished($: EngineInterface, filePath: unknown, resultText: string): Promise<string | null> {
  if (typeof filePath !== 'string') return null
  const base = PAGE_FILE.exec(filePath)?.[1]
  const url = artifactUrlIn(resultText)
  const root = await findRoot($)
  if (base === undefined || url === undefined || root === null) return null
  const path = `${root}/docs/specifications/${base}.json`
  if (!(await $.fs.exists(path))) return null
  const text = await $.fs.read(path)
  if (parseBuildOrder(text).artifact !== undefined) return null
  await $.fs.write(path, withArtifact(text, url))

  const { drift } = await checkAll($, true)

  return [`Saved the tracker link to docs/specifications/${base}.json.`, ...(drift.length > 0 ? [modelNote(drift)] : [])].join(' ')
}

let isStarted = false

async function start($: EngineInterface) {
  if (isStarted) return
  isStarted = true
  await $.command.register({ name: COMMAND, description: 'Check the cpm-next progress trackers against the epic docs, or name a spec ("01") to prepare its tracker' })
  const { lines, drift } = await checkAll($, false)
  if (drift.length > 0) $.ui.toast(`Progress tracker out of date: ${lines.join(' · ')}`)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await start($).catch(() => undefined)

    return next(e)
  })

  // A plugin loaded by /reload-plugins sees no session.start; start on the first prompt.
  on('prompt.submit', async ($, e, next) => {
    await start($).catch(() => undefined)

    return next(e)
  })

  on('command.run', { command: COMMAND }, async ($, e) => {
    const [verb = '', ...rest] = e.args.trim().split(/\s+/)
    if (verb === 'init') return { text: await prepare($, rest.join(' ')) }
    if (verb !== '') return { text: await prepare($, verb) }
    const { lines } = await checkAll($, true)

    return { text: lines.join('\n') }
  })

  // When the model publishes a tracker page, save its link and hand over the first rows.
  on('tool.call', { tool: 'Artifact' }, async ($, e, next) => {
    const result = await next(e)
    if (result.deny !== undefined || result.isError === true || (e.action ?? 'publish') !== 'publish' || e.asset === true) return result
    const note = await savePublished($, e.file_path, result.text ?? '').catch(() => null)
    if (note === null) return result
    $.ui.toast(note.split('. ')[0] ?? note)

    return { ...result, context: [...(result.context ?? []), note] }
  })

  // After a tool call that writes, check the trackers if an epic doc or build-order file changed, and
  // tell the model what to write. The tracker is only ever written by the model's own ArtifactData calls.
  on('tool.call', async ($, e, next) => {
    const result = await next(e)
    if (!WRITING_TOOLS.has(String(e.tool)) || result.deny !== undefined || result.isError === true) return result

    const found = await checkAll($, false).catch(() => null)
    if (found === null || found.drift.length === 0) return result
    $.ui.toast(`Progress tracker out of date: ${found.lines.join(' · ')}`)

    return { ...result, context: [...(result.context ?? []), modelNote(found.drift)] }
  })
}
