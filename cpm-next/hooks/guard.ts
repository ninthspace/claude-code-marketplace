// Pure logic for the commit guard: finds the checkout a command runs in and the red passes open in it
// (cpm-next/shared/artifacts.md, the `**Scratch**` field). It fails open: a read that rejects lets the commit through.

export type Fs = {
  read: (path: string) => Promise<string>
  exists: (path: string) => Promise<boolean>
  list: (path: string) => Promise<{ name: string; kind: string }[]>
  /** Where a path lands once symlinks are followed; `git rev-parse --show-toplevel`, which writes `tree`, follows them. */
  real?: (path: string) => Promise<string>
}

/** `git commit`, also through `git -C dir commit`, `git -c k=v commit`, git's global flags and after `cd x &&`. */
// An argument is a run of unquoted characters, escapes and quoted parts, each character consumed one way only, so a long run cannot backtrack exponentially.
const ARG = String.raw`((?:[^\s"'\\]|\\.|"(?:[^"\\]|\\.)*"|'[^']*')+)`
const GLOBAL = String.raw`(-[Cc]\s+${ARG}|-[pP]|--(no-pager|paginate|bare|literal-pathspecs|no-optional-locks)|--(git-dir|work-tree|namespace)(=|\s+)${ARG})`
const COMMIT = new RegExp(String.raw`(^|[\s;&|()])git(\s+${GLOBAL})*\s+commit(\s|$)`)

export const isCommit = (command: string): boolean => COMMIT.test(command)

/** `rel` resolved against `base`, an absolute path; `..` and `.` collapsed. */
export function resolvePath(base: string, rel: string): string {
  const parts = (rel.startsWith('/') ? rel : `${base}/${rel}`).split('/')
  const out: string[] = []
  for (const part of parts) {
    if (part === '' || part === '.') continue
    if (part === '..') out.pop()
    else out.push(part)
  }

  return `/${out.join('/')}`
}

export type Checkout = { top: string; common: string }

/**
 * The checkout holding `cwd` and its git common directory, found by walking up to a `.git`: a directory is
 * the common directory itself; a file points to a git directory, whose `commondir` file, when it has one
 * (a worktree), points on to the common directory.
 */
export async function checkoutOf(cwd: string, fs: Fs): Promise<Checkout | undefined> {
  let dir = resolvePath('/', cwd)
  for (;;) {
    const dotGit = `${dir === '/' ? '' : dir}/.git`
    if (await fs.exists(dotGit)) {
      const top = fs.real === undefined ? dir : await fs.real(dir).then(r => r, () => dir)
      const text = await fs.read(dotGit).then(t => t, () => undefined)
      if (text === undefined) return { top, common: dotGit }
      const pointed = /^gitdir:\s*(.+?)\s*$/m.exec(text)?.[1]
      if (pointed === undefined) return undefined
      const gitDir = resolvePath(dir, pointed)
      const common = (await fs.exists(`${gitDir}/commondir`)) ? resolvePath(gitDir, (await fs.read(`${gitDir}/commondir`)).trim()) : gitDir

      return { top, common }
    }
    if (dir === '/') return undefined
    dir = resolvePath(dir, '..')
  }
}

/** The pass directories in the common directory whose `tree` file names `top`, as absolute paths. */
export async function openPasses(checkout: Checkout, fs: Fs): Promise<string[]> {
  const scratch = `${checkout.common}/cpm-next/scratch`
  if (!(await fs.exists(scratch))) return []
  const open: string[] = []
  for (const entry of await fs.list(scratch)) {
    if (entry.kind !== 'dir') continue
    const tree = await fs.read(`${scratch}/${entry.name}/tree`).then(t => t.trim(), () => undefined)
    if (tree === checkout.top) open.push(`${scratch}/${entry.name}`)
  }

  return open.sort()
}

export function refusal(passes: string[]): string {
  const stories = passes.map(p => `${p.split('/').at(-1)} (${p})`).join('; ')

  return `A red pass is open in this checkout: ${stories}. Its files are mutated until the pass ends. Resume /cpm-next:do on the story, or copy the files in that directory back to their repository paths, then commit.`
}

/** The reason to refuse `command` run from `cwd`, or undefined to let it through; reads nothing unless it is a commit. */
export async function decide(command: string, cwd: string, fs: Fs): Promise<string | undefined> {
  if (!isCommit(command)) return undefined
  const checkout = await checkoutOf(cwd, fs)
  if (checkout === undefined) return undefined
  const passes = await openPasses(checkout, fs)

  return passes.length === 0 ? undefined : refusal(passes)
}
