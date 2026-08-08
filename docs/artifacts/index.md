# Artifact Register

Published artifacts produced alongside this project's CPM work. Newest first.
Maintained by `/cpm:artifact` — see the associated documents for the work each one came from.

| Artifact | URL | Registered | Associated with | Why |
|---|---|---|---|---|
| dpm — Schema Map | https://claude.ai/code/artifact/bb0b3460-708c-4fdf-8cf8-7664457c896b | 2026-08-08 | `docs/specifications/47-spec-dpm-sqlite-persistence.md`, `docs/reviews/03-review-dpm-sqlite-persistence.md` | Holds spec 47's 37-table data model as six ER diagrams grouped by concern, which a linear DDL listing cannot show — plus the taxonomy evidence, the six invariants SQLite cannot enforce, and a verified table of what the constraints actually reject. Source in this repo at `docs/artifacts/47-dpm-schema-map.html`; edit that and republish passing the URL above |
| Artifact clipboard probe | https://claude.ai/code/artifact/60c498ab-587b-4b00-bb7c-ed70f783e183 | 2026-07-25 | `docs/specifications/41-spec-artifact-pivot.md`, `docs/epics/41-02-epic-pivot-interpretations.md` | Settles AD5's open question — whether `navigator.clipboard.writeText` is permissions-policy gated inside a cross-origin artifact frame — by reporting feature detection and live per-click outcomes, since there is no local oracle for it |
