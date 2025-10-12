# /sdd:story-status

Shows all stories and their current stages.

## Implementation

**Format**: Structured (standard)
**Actions**: Read-only query
**Modifications**: None

### Discovery
1. List stories in each stage directory:
   - `/docs/stories/development/`
   - `/docs/stories/review/`
   - `/docs/stories/qa/`
   - `/docs/stories/completed/`
   - `/docs/stories/backlog/`

2. For each story file found:
   - Extract story ID from filename
   - Read title from YAML frontmatter
   - Parse started date from metadata
   - Extract branch name
   - Read most recent progress log entry

### Output Format
```
📊 STORY STATUS OVERVIEW
========================

🚧 DEVELOPMENT (active work)
---------------------------
• [STORY-ID]: [Title]
  Started: [Date] | Branch: [branch-name]
  Last update: [most recent progress entry]

🔍 REVIEW (code review & checks)
--------------------------------
• [List stories in review stage]

✅ QA (final validation)
-----------------------
• [List stories in QA stage]

📦 COMPLETED (last 5)
--------------------
• [Recent completed stories with completion dates]

💡 BACKLOG
----------
• [Backlog items by priority]

📈 SUMMARY
----------
Total active: [count]
This week completed: [count]
Average cycle time: [if data available]
```

### Empty State
If no stories exist:
```
💡 NO STORIES FOUND

Get started:
1. Create your first story with /sdd:story-new
2. Set up full structure with /sdd:project-init
```

### Notes
- Shows read-only snapshot of current state
- Does not modify any files
- Displays maximum 5 completed stories (most recent)