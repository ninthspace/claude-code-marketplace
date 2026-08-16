# Coverage — Neighbour version skew

**Number**: 01-01  
**Source epic**: 01-01  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR1 | reports when a newer version of the plugin is installed alongside the version it is running from | Given a root holding the running version and a higher-numbered sibling, the check reports a skew naming the higher version. | Story 3 | `[unit]` |  |
| 2 | FR1 | a newer version of the plugin is installed alongside | Given a root whose siblings are all lower than or equal to the running version, the check reports no skew. | Story 3 | `[unit]` |  |
| 3 | FR1 | The server reports when a newer version of the plugin is installed alongside the version it is running from. | must NOT — The check reports a skew for a sibling lower than the running version. A reversed comparison satisfies the first criterion on any machine with more than one version installed, so the first criterion alone does not pin the direction. | Story 3 | `[unit]` |  |
| 4 | FR1 | The server reports when a newer version of the plugin is installed alongside | A `check_integrity` call against a constructed root holding a higher sibling returns a skew field naming both versions, with `ok` still true. | Story 7 | `[integration]` |  |
| 5 | FR1a | evaluated at the moment it is reported, never cached from server start | Two consecutive reports against a root that gained a higher sibling between them return different verdicts. | Story 4 | `[integration]` |  |
| 6 | FR1a | never cached from server start | control — With the check deliberately memoised, the two-consecutive-reports criterion fails, and the failure has been observed and read rather than assumed. | Story 4 | `[integration]` |  |
| 7 | FR1b | when the plugin root is not a version directory, reporting could-not-check | Given a root whose name does not parse as a version, the check reports could-not-check. | Story 3 | `[unit]` |  |
| 8 | FR1b | reporting could-not-check rather than failing and rather than claiming no skew | Given a root with no sibling directories at all, the check reports could-not-check rather than no skew. | Story 3 | `[unit]` |  |
| 9 | FR1b | completes without error | must NOT — The check throws for an unreadable or unparseable root. | Story 3 | `[unit]` |  |
| 10 | FR1b | reporting could-not-check rather than failing | A `check_integrity` call against a root that is not a version directory returns could-not-check, with `ok` still true. | Story 7 | `[integration]` |  |
| 11 | FR4 | names the version running, the newer version found, and what to do about it | A reported skew contains the running version, the newer version found, and a remedy naming a session restart. | Story 5 | `[unit]` |  |
| 12 | FR4 | composed in one place rather than assembled separately by each caller | must NOT — The skew sentence is composed in more than one place. | Story 5 | `[unit]` |  |
| 13 | FR5 | The report distinguishes checked-and-found-no-skew from could-not-check | The three states — skew found, no skew, could not check — are distinguishable without parsing message text. | Story 3 | `[unit]` |  |
| 14 | FR5 | distinguishes checked-and-found-no-skew from could-not-check | must NOT — A check that could not run renders as no skew. | Story 3 | `[unit]` |  |
| 15 | FR5 | The report distinguishes checked-and-found-no-skew from could-not-check | The skew field is present in the response when no skew was found. | Story 5 | `[unit]` |  |
| 16 | NFR1 | costs one bounded directory read per report | The check performs exactly one directory read per invocation. | Story 2 | `[unit]` |  |
| 17 | NFR1 | no recursion | must NOT — The check recurses into subdirectories. | Story 2 | `[unit]` |  |
| 18 | NFR1 | no process spawn, no network call | must NOT — The check spawns a process or opens a socket. | Story 2 | `[unit]` |  |
| 19 | NFR2 | A skew check that cannot complete degrades to could-not-check | A directory read that throws produces could-not-check and a successful tool response. | Story 5 | `[integration]` |  |
| 20 | NFR2 | It never fails the tool call and never stops the server | must NOT — An error from the check propagates out of the tool handler. | Story 5 | `[integration]` |  |
| 21 | NFR2 | It never fails the tool call and never stops the server | control — With the error handling removed, the criterion that a throwing read produces could-not-check fails, and that failure has been observed and read rather than assumed. | Story 5 | `[integration]` |  |
| 22 | NFR4 | It creates no file and no directory, and writes nothing anywhere | After a report, the filesystem beneath and beside the plugin root is unchanged. | Story 2 | `[integration]` |  |
| 23 | NFR4 | creates no file and no directory | must NOT — The check creates a file or directory anywhere. | Story 2 | `[integration]` |  |
| 24 | NFR5 | The coupling to the host's plugin cache layout is recorded in the project's maintenance record | The maintenance record documents the assumed plugin cache layout and what breaks if the host changes it. | Story 6 | `[manual]` |  |
| 25 | NFR5 | named from no skill file | must NOT — Any file under the skills directory names the maintenance record's path. | Story 6 | `[unit]` |  |
| 26 | ENV1 | Node 22.5.0 or later, matching `engines.node` | The running Node satisfies `REQUIRED_NODE`, and `engines.node` equals it. | Story 1 | `[unit]` |  |
| 27 | ENV2 | the suite runs via the built-in `node --test` runner with no install step | The test script invokes only the built-in runner, with no binary resolved from `node_modules`. | Story 1 | `[unit]` |  |
| 28 | ENV3 | a directory holding sibling version directories | A constructed directory of sibling version directories exists in the suite, and the check reports a verdict against it. | Story 1 | `[unit]` |  |
| 29 | ENV5 | the running plugin's own directory is derivable from the module's URL at runtime | Resolving from the module's own URL names the directory the module was loaded from. | Story 2 | `[unit]` |  |
| 30 | ENVX1 | no runtime or development dependency may be required | `dependencies` and `devDependencies` are both empty. | Story 3 | `[unit]` |  |
| 31 | ENVX2 | the suite must not require the real plugin cache or the user's home directory | The check reads only the path it was given. | Story 2 | `[unit]` |  |
| 32 | ENVX2 | the user's home directory | must NOT — Any path a test resolves runs through the user's home directory. | Story 2 | `[unit]` |  |
| 33 | ENVX3 | an environment variable naming the plugin root must not be required | The resolver reads no value from `process.env`. | Story 2 | `[unit]` |  |
| 34 | ENVX4 | network access must not be required | No path this spec adds makes an outbound call. | Story 2 | `[unit]` |  |
| 35 | ENV6 | a temporary filesystem location the suite can create, write to and remove | A test creates a temporary location, writes into it, and asserts it is gone afterwards. | Story 1 | `[unit]` |  |
