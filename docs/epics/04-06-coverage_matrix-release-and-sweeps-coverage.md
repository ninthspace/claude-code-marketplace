# Coverage — Release

**Number**: 04-06  
**Source epic**: 04-06  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | NFR5 | Every TEXT column and every tool this change adds is judged by the derived sweeps before release rather than exempted from them. | Every TEXT column this change adds carries a prose-columns classification, reconciled in both directions so a column added later fails until judged and an entry for a column the schema no longer has fails too. | Story 1 | `[unit]` | ✓ |
| 2 | NFR5 | Every TEXT column and every tool this change adds is judged by the derived sweeps before release rather than exempted from them. | The retirement tool is registered and reached by the parity sweeps without an exemption. | Story 1 | `[unit]` | ✓ |
| 3 | NFR5 | rather than exempted from them | must NOT — No column or tool this change adds is exempted from a derived sweep. | Story 1 | `[unit]` | ✓ |
| 4 | ENV3 | The dpm plugin can be reinstalled from this working tree once the schema version bumps. | After the schema version bumps, reinstalling the plugin from this working tree restores write access to this project's database, which the integrity report describes as skew until it happens. | Story 2 | `[manual]` |  |
