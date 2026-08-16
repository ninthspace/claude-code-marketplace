# Coverage — The key map and its guard

**Number**: 02-02  
**Source epic**: 02-02  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR1 | `r` refreshes, `R` clears the cache, `a` registers a project, `x` unregisters the highlighted one | Driving a running board: `r` re-reads every registered project, `R` empties the cache, `a` opens the register picker, and `x` unregisters the highlighted project. | Story 1 | `[feature]` | ✓ |
| 2 | FR1 | A capability the DPM board reaches only through the command palette today gains its CPM key. | Refresh and unregister are reachable by key, not only through the command palette as they are today. | Story 1 | `[feature]` | ✓ |
| 3 | FR1 | Every key the CPM board binds carries the same meaning on the DPM board | must NOT — No key the CPM board binds does something different on the DPM board. | Story 1 | `[integration]` | ✓ |
| 4 | FR1 | `z` shows or hides retired work | A board opened over a project holding complete, superseded, withdrawn and live rows shows only the live ones; `z` reveals all four groups; `z` again returns to the first state. | Story 2 | `[feature]` | ✓ |
| 5 | FR2 | Retired work is hidden when the board opens and `z` toggles it | A board opened over a project holding complete, superseded, withdrawn and live rows shows only the live ones; `z` reveals all four groups; `z` again returns to the first state. | Story 2 | `[feature]` | ✓ |
| 6 | FR2 | Each press says which way it went | Each press says which way it went, so a board that was already showing everything is distinguishable from one that has just been told to. | Story 2 | `[feature]` | ✓ |
| 7 | FR2 | where retired means `complete` together with the two states `status_model.RETIRED` already names | must NOT — No row in a live state — ready, in progress, blocked or pending — is removed by the filter, with one case per live state rather than one case for the set. | Story 2 | `[unit]` | ✓ |
| 8 | FR2 | where retired means `complete` together with the two states `status_model.RETIRED` already names | control — With the filter widened to hide a live state, the case above fails and names the state it lost — so a filter that removed nothing at all could not pass it. | Story 2 | `[unit]` | ✓ |
| 9 | FR3 | The forced re-read gives up `R` and takes `ctrl+r`; search and coverage gaps keep `ctrl+f` and `ctrl+g`. | Driving a running board: `ctrl+r` re-reads every project ignoring the cache, `ctrl+f` opens search, `ctrl+g` opens coverage gaps. | Story 3 | `[feature]` |  |
| 10 | FR3 | bound to a key that collides with nothing in the CPM map | must NOT — No capability the DPM board has and the CPM board lacks is bound to a key that appears in the CPM board's map, read from that board's source by the same reader story 1 uses. | Story 3 | `[integration]` |  |
| 11 | FR7 | use the CPM board's wording wherever the action is the same one | The footer shows every bound key, using the CPM board's wording wherever the action is the same one. | Story 4 | `[feature]` |  |
| 12 | FR7 | The footer labels and the command-palette entries describe the keys as they stand after FR1 and FR3 | must NOT — No footer label or palette entry describes a key that is not bound, and no bound key is missing from the footer — both directions, because either alone is satisfied by a board that documents nothing. | Story 4 | `[unit]` |  |
| 13 | FR8 | every further difference found is either closed or recorded as deliberate | Bindings, footer and command palette each have a recorded outcome: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. | Story 6 | `[manual]` |  |
| 14 | FR8 | A difference nobody has looked at is neither. | must NOT — None of bindings, footer or command palette is left with no outcome recorded. A surface nobody compared reads exactly like one that was compared and agreed. | Story 6 | `[manual]` |  |
| 15 | FR9 | fails something mechanically the next time one board moves and the other does not | Changing a DPM binding so that a key the CPM board binds does something else makes the parity check fail, and the failure names the key. | Story 5 | `[integration]` |  |
| 16 | ENV4 | the CPM board's source is readable at `cpm/tools/board/` relative to the marketplace checkout root | The CPM board's source is readable at `cpm/tools/board/` relative to the marketplace checkout root, from the directory the suite runs in. | Story 5 | `[integration]` |  |
| 17 | ENVX3 | the board must not require the CPM plugin to be installed or readable | The board starts, paints its columns and answers its keys with no CPM tree anywhere on its path. | Story 5 | `[feature]` |  |
