export const TRACKER_DATA =
{
  "items": {
    "55-01-s1": {
      "seq": 1,
      "phase": 1,
      "phaseLabel": "55-01 Rows and meta",
      "phaseNote": "Data first",
      "epic": "55-01",
      "story": "S1",
      "title": "The model each story was built on",
      "status": "Complete",
      "blockedBy": "",
      "note": "",
      "updated": "2026-11-11",
      "model": "opus",
      "took": 38,
      "effort": "high",
      "criteria": {
        "met": 1,
        "total": 1
      }
    },
    "55-01-s2": {
      "seq": 2,
      "phase": 1,
      "phaseLabel": "55-01 Rows and meta",
      "phaseNote": "Data first",
      "epic": "55-01",
      "story": "S2",
      "title": "Rows carry model, effort and needs",
      "status": "In progress",
      "blockedBy": "",
      "note": "",
      "updated": "2026-11-11",
      "model": "sonnet",
      "started": 1794390000000,
      "effort": "medium",
      "criteria": {
        "met": 1,
        "total": 2
      }
    },
    "55-01-s3": {
      "seq": 3,
      "phase": 1,
      "phaseLabel": "55-01 Rows and meta",
      "phaseNote": "Data first",
      "epic": "55-01",
      "story": "S3",
      "title": "Decisions matched to rows",
      "status": "Pending",
      "blockedBy": "55-01 S2",
      "note": "",
      "updated": "2026-11-11",
      "model": "opus",
      "modelPlanned": true,
      "effort": "medium",
      "criteria": {
        "met": 0,
        "total": 0
      }
    },
    "55-01-s4": {
      "seq": 4,
      "phase": 1,
      "phaseLabel": "55-01 Rows and meta",
      "phaseNote": "Data first",
      "epic": "55-01",
      "story": "S4",
      "title": "Waiting on a review",
      "status": "Waiting on input",
      "blockedBy": "",
      "note": "",
      "updated": "2026-11-11",
      "model": "opus",
      "modelPlanned": true,
      "effort": "low",
      "criteria": {
        "met": 0,
        "total": 1
      },
      "needs": [
        {
          "kind": "review",
          "text": "Walk through the detail at 390 px"
        }
      ]
    },
    "55-01-t4.1": {
      "seq": 5,
      "phase": 1,
      "phaseLabel": "55-01 Rows and meta",
      "phaseNote": "Data first",
      "epic": "55-01",
      "story": "T4.1",
      "title": "Write the strip",
      "status": "Pending",
      "blockedBy": "",
      "note": "Shown in the strip",
      "updated": "2026-11-11",
      "model": "opus",
      "modelPlanned": true,
      "effort": "low"
    }
  },
  "meta": {
    "title": "55 The tracker in split view: build order",
    "spec": "docs/specifications/55-spec-tracker-split-view.md",
    "decisions": [
      "[55-01 S4, review] Walk through the detail at 390 px",
      "Pick a release date"
    ],
    "timed": 11,
    "typical": {
      "low": {
        "range": "28–40 min",
        "low": 27.5,
        "high": 39.5
      },
      "medium": {
        "range": "27–40 min",
        "low": 26.75,
        "high": 40.25
      },
      "high": {
        "range": "28–40 min",
        "low": 27.5,
        "high": 39.5
      },
      "xhigh": {
        "range": "28–40 min",
        "low": 27.5,
        "high": 39.5
      }
    },
    "unmatched": [
      "Pick a release date"
    ],
    "updated": "2026-11-11"
  }
}
