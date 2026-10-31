import { expect, test } from 'claude-code/testing'

import { checkoutOf, decide, isCommit, openPasses } from './guard'
import type { Fs } from './guard'

/** An in-memory file system: `files` maps a path to its text, `dirs` lists the directories; counts every call. */
function fake(files: Record<string, string>, dirs: string[] = []): Fs & { calls: number } {
  const all = new Set(dirs)
  for (const path of Object.keys(files)) {
    const parts = path.split('/')
    for (let i = 1; i < parts.length; i++) all.add(parts.slice(0, i).join('/') || '/')
  }
  const fs = {
    calls: 0,
    exists: async (path: string) => { fs.calls++; return path in files || all.has(path) },
    read: async (path: string) => { fs.calls++; if (!(path in files)) throw new Error(`ENOENT ${path}`); return files[path] as string },
    list: async (path: string) => {
      fs.calls++
      const prefix = `${path}/`
      const names = new Map<string, string>()
      for (const f of Object.keys(files)) if (f.startsWith(prefix)) names.set(f.slice(prefix.length).split('/')[0] as string, f.slice(prefix.length).includes('/') ? 'dir' : 'file')
      for (const d of all) if (d.startsWith(prefix)) names.set(d.slice(prefix.length).split('/')[0] as string, 'dir')

      return [...names].map(([name, kind]) => ({ name, kind }))
    },
  }

  return fs
}

const MAIN = '/work/app'
const SCRATCH = `${MAIN}/.git/cpm-next/scratch`
const WT = '/work/app-wt'

/** A repository with a `.git` directory, and a pass directory whose `tree` names `tree` (none when undefined). */
const repo = (tree: string | undefined, extra: Record<string, string> = {}) => fake({
  [`${MAIN}/.git/HEAD`]: 'ref: refs/heads/main',
  ...(tree === undefined ? {} : { [`${SCRATCH}/49-01-epic-red-passes-2/tree`]: tree, [`${SCRATCH}/49-01-epic-red-passes-2/manifest`]: '' }),
  ...extra,
})

test('git commit is recognised through -C, -c, cd and && and not in other git commands', () => {
  expect(isCommit('git commit -m "x"')).toBe(true)
  expect(isCommit('cd sub && git commit -am x')).toBe(true)
  expect(isCommit('git -C . commit -m x')).toBe(true)
  expect(isCommit('git -c user.name=a commit -m x')).toBe(true)
  expect(isCommit('git --no-pager commit')).toBe(true)
  expect(isCommit('git add -A; git commit')).toBe(true)
  expect(isCommit('git status')).toBe(false)
  expect(isCommit('git log --grep commit')).toBe(false)
  expect(isCommit('echo done')).toBe(false)
  expect(isCommit('git commit-tree abc')).toBe(false)
})

test('git commit is recognised through quoted and space-separated global options', () => {
  expect(isCommit('git -C "my dir" commit -m x')).toBe(true)
  expect(isCommit("git -C 'my dir' commit -m x")).toBe(true)
  expect(isCommit('git --git-dir /x/.git --work-tree /x commit -m x')).toBe(true)
  expect(isCommit('git -p commit')).toBe(true)
  expect(isCommit('git --paginate commit')).toBe(true)
  expect(isCommit('git -C "my dir" status')).toBe(false)
})

test('git commit is recognised when an option argument is only partly quoted', () => {
  expect(isCommit('git -C "$HOME"/wt commit -m x')).toBe(true)
  expect(isCommit('git -C "$(pwd)"/x commit')).toBe(true)
  expect(isCommit('git -C "a"b commit')).toBe(true)
  expect(isCommit('git -C "a\\"b" commit -m x')).toBe(true)
  expect(isCommit('git -c user.name="A B" commit -m x')).toBe(true)
  expect(isCommit('git -C x\\ y commit')).toBe(true)
  expect(isCommit('git -C "$HOME"/wt status')).toBe(false)
})

test('a long run of quoted options that ends in another subcommand is judged at once', () => {
  const command = `git ${'-C "a" '.repeat(26)}status`
  const started = Date.now()
  expect(isCommit(command)).toBe(false)
  expect(Date.now() - started).toBeLessThan(250)
  expect(isCommit(`git ${'-C "a" '.repeat(26)}commit -m x`)).toBe(true)
  const unterminated = `git -C a"${'x'.repeat(20000)}`
  const begun = Date.now()
  expect(isCommit(unterminated)).toBe(false)
  expect(Date.now() - begun).toBeLessThan(250)
})

test('a commit is refused while a pass directory names this checkout, naming the directory', async () => {
  const reason = await decide('git commit -m x', MAIN, repo(MAIN))
  expect(reason).toContain('49-01-epic-red-passes-2')
  expect(reason).toContain(`${SCRATCH}/49-01-epic-red-passes-2`)
})

test('a commit from a subdirectory is refused too', async () => {
  expect(await decide('git commit -m x', `${MAIN}/src/deep`, repo(MAIN))).toContain('red pass is open')
})

test('commits reached through cd and git -C are refused', async () => {
  expect(await decide('cd src && git commit -m x', MAIN, repo(MAIN))).toContain('red pass')
  expect(await decide('git -C . commit -m x', MAIN, repo(MAIN))).toContain('red pass')
})

test('a commit passes when there is no scratch folder, when it is empty, and when the pass names another checkout', async () => {
  expect(await decide('git commit -m x', MAIN, repo(undefined))).toBeUndefined()
  expect(await decide('git commit -m x', MAIN, fake({ [`${MAIN}/.git/HEAD`]: '' }, [SCRATCH]))).toBeUndefined()
  expect(await decide('git commit -m x', MAIN, repo(WT))).toBeUndefined()
  // The same fixture as the refused case, with only `tree` changed.
  expect(await decide('git commit -m x', MAIN, repo(MAIN))).not.toBeUndefined()
})

/** The main repository plus a linked worktree at WT whose `.git` file points into it. */
const withWorktree = (tree: string) => fake({
  [`${MAIN}/.git/HEAD`]: 'ref: refs/heads/main',
  [`${MAIN}/.git/worktrees/app-wt/commondir`]: '../..\n',
  [`${WT}/.git`]: `gitdir: ${MAIN}/.git/worktrees/app-wt\n`,
  [`${SCRATCH}/49-02-epic-auditor-checks-1/tree`]: tree,
})

test('a worktree finds the main repository\'s scratch folder through commondir', async () => {
  const fs = withWorktree(WT)
  expect(await checkoutOf(WT, fs)).toEqual({ top: WT, common: `${MAIN}/.git` })
  expect(await decide('git commit -m x', WT, fs)).toContain('49-02-epic-auditor-checks-1')
})

test('a pass in a worktree does not block the main checkout, nor the reverse', async () => {
  expect(await decide('git commit -m x', MAIN, withWorktree(WT))).toBeUndefined()
  expect(await decide('git commit -m x', WT, withWorktree(MAIN))).toBeUndefined()
})

/** `fs` seen through a symlink: paths under /link are the same files as under /work, and `real` resolves them. */
const viaLink = (fs: Fs): Fs => {
  const target = (path: string) => path.replace('/link', '/work')

  return { exists: p => fs.exists(target(p)), read: p => fs.read(target(p)), list: p => fs.list(target(p)), real: async p => target(p) }
}

test('a cwd reached through a symlink still matches the pass, which names the resolved checkout', async () => {
  expect(await decide('git commit -m x', '/link/app', viaLink(repo(MAIN)))).toContain('red pass')
})

test('a command that is not a commit reads nothing, even with a pass open', async () => {
  const fs = repo(MAIN)
  expect(await decide('git status', MAIN, fs)).toBeUndefined()
  expect(await decide('npm test', MAIN, fs)).toBeUndefined()
  expect(fs.calls).toBe(0)
  await decide('git commit -m x', MAIN, fs)
  expect(fs.calls).toBeGreaterThan(0)
})

test('a directory with no repository above it lets a commit through', async () => {
  expect(await decide('git commit -m x', '/tmp/nowhere', fake({}))).toBeUndefined()
})

test('only a file in the scratch folder is no pass', async () => {
  const fs = fake({ [`${MAIN}/.git/HEAD`]: '', [`${SCRATCH}/.keep`]: '' })
  expect(await decide('git commit -m x', MAIN, fs)).toBeUndefined()
})

test('only directories count as passes, and the open ones are listed in order', async () => {
  const fs = fake({
    [`${MAIN}/.git/HEAD`]: '',
    [`${SCRATCH}/b-1/tree`]: MAIN,
    [`${SCRATCH}/a-1/tree`]: MAIN,
    [`${SCRATCH}/note.txt`]: MAIN,
  })
  expect(await openPasses({ top: MAIN, common: `${MAIN}/.git` }, fs)).toEqual([`${SCRATCH}/a-1`, `${SCRATCH}/b-1`])
})
