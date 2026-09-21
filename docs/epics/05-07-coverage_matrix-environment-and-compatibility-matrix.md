# Coverage matrix — Environment and compatibility

**Number**: 05-07  
**Source epic**: 05-07  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | NFR2 | No epic that closes cleanly before this work stops closing after it | Every epic in the committed corpus that reaches a clean close before the change still reaches one after it, and the standing computed for each of its requirements is unchanged. | Story 4 | `[integration]` |  |
| 2 | NFR5 | The change set requires no schema migration | The schema version recorded by the release before this change set and by the release after it are the same number. | Story 5 | `[integration]` |  |
| 3 | ENV1 | the connection asserts both capabilities at open time | The connection refuses to open, naming which capability is missing, where the runtime has no synchronous SQLite binding or its SQLite lacks FTS5; and the manifest declares the runtime floor that supplies both. | Story 1 | `[integration]` |  |
| 4 | ENV2 | The suite runs under Node's own test runner | The manifest's test script invokes the runtime's own test runner, and every test this spec adds is discovered and run by it with no other runner present. | Story 1 | `[integration]` |  |
| 5 | ENV3 | A suite assertion already pins this | The existing suite assertion that the repository's pre-commit hook resolves into this checkout rather than into the plugin cache passes after this change set. | Story 2 | `[integration]` |  |
| 6 | ENV4 | The manifest declares both dependency sets empty and they stay empty | Both dependency sets in the manifest are empty after this change set, and the suite runs on a checkout with no package installation step. | Story 1 | `[integration]` |  |
| 7 | ENV5 | Everything added works where the server is an installed plugin release reading a project's own database | Every tool added here works where the server is an installed plugin release reading a project's own database, with no path that exists only in this checkout. | Story 3 | `[target]` |  |
