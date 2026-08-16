# Coverage — Fixture and environment

**Number**: 02-01  
**Source epic**: 02-01  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ENV1 | `uv run pytest` from `dpm/tools/board` runs the suite, with pytest 8 or later, pytest-asyncio 0.24 or later | pytest and pytest-asyncio are present at or above the stated minimums, and the suite runs from `dpm/tools/board`. | Story 2 | `[unit]` | ✓ |
| 2 | ENV2 | the dependency list in `pyproject.toml` and the PEP 723 inline block at the top of `board.py` naming the same packages | The dependency list in `pyproject.toml` and the PEP 723 inline block in `board.py` name the same packages. | Story 2 | `[unit]` | ✓ |
| 3 | ENV3 | a markdown renderer importable from a package the board already declares | The markdown renderer imports, and neither dependency list has gained an entry for it. | Story 2 | `[unit]` | ✓ |
| 4 | ENVX1 | the suite must not require network access | A socket opened during the suite raises and is recorded, so the run is known to have needed no network rather than assumed to have needed none. | Story 2 | `[unit]` | ✓ |
| 5 | ENVX2 | must not require a package outside `board.py`'s inline block | `board.py` imports nothing outside the standard library and the packages its own inline block declares. | Story 2 | `[unit]` | ✓ |
| 6 | ENV5 | Python 3.11 or later on the machine the board runs on, provisioned by `uv run` from the inline block | The host running the board has Python 3.11 or later, and `uv run` provisions the board from its inline block there. | Story 2 | `[target]` |  |
| 7 | ENV6 | a fixture project whose database holds epics and stories in every state the model defines, retired ones included, and at least one document long enough to time a render against | The fixture builds, and holds at least one epic or story in each state the model defines — including `complete`, `superseded` and `withdrawn` — together with a document long enough to time a render against. | Story 1 | `[integration]` | ✓ |
