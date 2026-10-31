# User checks for spec 49

**Source spec**: docs/specifications/49-spec-cheaper-red-first-evidence.md  
**Date**: 2026-10-31  
**Status**: Pending  
**Blocked by**: Epic 49-06-epic-release

These checks are carried out by the user after release; `do` writes each `Evidence` line only from the user's answer.

## Red passes and the guard work in an installed release
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR2, FR3, FR4, FR5, FR10, FR11, FR12

**Acceptance Criteria**:

- The user pushes the release, runs `claude plugin update` for the three plugins and lets `plugin-sync` reload the session, then confirms `claude plugin list` shows cpm-next 0.11.0, whats-next 0.3.0 and cpm-next-progress 0.8.0, and that `claude --debug` shows the cpm-next hooks module loaded. The observation is the versions and the load line `[user]`
- In a scratch repository with a test suite, the user runs `/cpm-next:do` on a one-story epic with two test-proven criteria. The observation is a `**Scratch**` line naming a directory under `.git/cpm-next/scratch/` during the pass, no permission prompt for the copies or the deletion, both directory and line gone at the end, and `Evidence` lines in the new form with no `green after restore` `[user]`
- The user interrupts a second run during its red pass (after the first copy), then runs `git commit -am test` through Claude. The observation is the commit refused, naming the story's directory. The user then runs `/cpm-next:do` again; the observation is the mutated file restored (`git diff` matching what it was before the pass) and the directory gone before any other work `[user]`
- In the scratch repository, the user runs `/cpm-next:do --parallel` on two independent one-story epics that edit different files. The observation is both commit on their worktree branches without a refusal once their passes end, `.git/cpm-next/scratch/` empty afterwards, and the user's report of whether any commit made by a subagent during its own open pass was refused (the guard reads the session's directory, so this shows what the engine reports for a subagent) `[user]`
- In the same repository, a story whose only open criterion is `[user]` shows as "Waiting on you" in `/next`, in the What's next pane (with the story's unproven criteria listed under it) and, when nothing else is left to build, in the band above the prompt, and as `Waiting on input` in the progress tracker, while a story that depends on it is labelled as waiting on that check and is not offered as next `[user]`
- In a project with a `[browser]` criterion and no local server running, the user runs `/cpm-next:do` on it. The observation is the first message naming the missing server and how to start it `[user]`

### Run the checks
**Task**: 1.1  
**Description**: Carried out by the user; `do` writes the `Evidence (user, …)` lines from their answers.  
**Status**: Pending

---
