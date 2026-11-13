# Auditor: independent tests

Read this file when the story has an `**Independent tests**` line other than `skipped`, and read it again whenever it is not in context. It holds the checks of the auditor's check 5 on a story's independent tests; the line's forms are in the contract, beside this file.

A story with an `**Independent tests**` line is held to the tests on it, and each of these is a Critical:

- a file on the line whose blob, recomputed with `git hash-object` as the contract defines it, differs from the one recorded on the line (a revision having rewritten it there);
- a marked story whose line still reads `due`;
- a criterion an independent test proves whose `Evidence` line does not cite that test;
- a change the story made to shared test setup, test-runner config, factories or environment, or code that branches on the test environment or names a sample's values, that changes what an independent test checks.

A `before the build` red is accepted when the line has no ` — revised` note for its file, the test's file still matches its blob, the boundary existed at the story's start (read from the commit before the story where there is one, and otherwise from the story's diff, which must not add the entry point) and the failure text is what the cited assertion prints; check 5's Warning on an undo or mutation the assertion doesn't depend on does not apply to it.
