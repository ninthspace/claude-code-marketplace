---
active: true
iteration: 1
max_iterations: 50
completion_promise: "ALL_EPICS_COMPLETE"
started_at: "2026-05-28T18:37:13Z"
---

Run /cpm2:do on epics 32-01 through 32-03 sequentially (docs/epics/32-*-epic-*.md), auto-continuing to each next epic. Make all decisions autonomously -- pick the most reasonable option for every AskUserQuestion. Use inline planning for all stories. Task complete: all tagged criteria ([unit]/[integration]/[feature]) have passing tests; [manual] criteria have self-assessment lines in the progress file. For the 3-strike skip rule, a failure is a test exit code != 0 after a code-change attempt -- tool errors and permission denials are retries, not failures. If criteria are ambiguous, mark the story Blocked -- criteria ambiguous and continue. Commit after each story, locally. Test runner: cpm2/hooks/tests/run-all-tests.sh. When the last epic completes, output ALL_EPICS_COMPLETE.
