# Worktree mode

Read by `do` when it runs with `--parallel` or `--parallel check`, or when unblocked stories that share files or runtime state are waiting to be built. `SKILL.md` beside this file defines the terms used here (the isolated suite, the red, the builder directory).

With `--parallel`, unblocked stories are built together even when they share files, each subagent in its own git worktree (the Agent tool's `isolation: "worktree"`), merged by the lead. Worktrees isolate files, not the running app, its domains, real databases, webhooks or third-party services, so these stories still run one at a time, after the batch:

- one that depends on another story in the batch;
- one that changes a dependency lock file, `.env` or shared config;
- a migration that changes a table another story in the batch uses;
- one whose criteria need the running app: a `[browser]` criterion, a browser check, Dusk, a real webhook or a third-party call.

Run at most three at once. A worktree starts from the last commit, so commit the run's own work before each fan-out. If the tree holds changes this run didn't make, don't use worktree mode: say so, and build one at a time.

A worktree's test results count only if the suite is isolated (see **Scratch directories and isolation**), outbound HTTP is faked with stray requests prevented (`Http::preventStrayRequests()`), queues and mail are faked, and no build output the checkout lacks is needed (in Laravel, Vite's manifest, unless tests call `withoutVite()`). Otherwise the subagents write code only, and the lead runs each story's tests after merging it.

Each subagent's prompt adds:

- Set up the worktree first. Install dependencies from the lock file (`composer install`, `npm ci`); never symlink `vendor/` or `node_modules/`, since Composer's autoloader would then load the lead's code. Copy from the lead's checkout the gitignored files its tests need (`.env`, local settings), pointed at test resources.
- Start no server, run no migrations or seeders against a real database, call no real service, and leave the epic doc alone.
- Commit the story on the worktree's branch, and report the branch, the files changed, the tests run with their output, what proves each criterion, and the red for each test-proven one. The lead writes the `Evidence` lines.

The lead merges the branches in story order with `git merge --no-ff`, so each story's merge commit, against its first parent, is that story alone for its audit. After resolving a conflict, it runs both stories' tests again, then the full suite once. It removes each worktree and its branch once the story is merged.

`--parallel check` builds nothing and writes nothing. It reports the unblocked stories in scope, the batches worktree mode would form and why any story stays out, whether the suite is isolated (citing the config lines that show it), and the setup each worktree would need.
