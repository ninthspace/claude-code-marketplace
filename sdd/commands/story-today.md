# /story-today

Shows current story, stage, and next actions for today's work.

## Implementation

**Format**: Structured (standard)
**Actions**: Read-only summary
**Modifications**: None

### Discovery
1. Check current git context:
   - Active branch name
   - Uncommitted changes count
   - Last commit timestamp

2. Find active stories:
   - List files in `/stories/development/`
   - List files in `/stories/review/`
   - List files in `/stories/qa/`
   - Match branch name to story files

3. Parse active story:
   - Read story metadata from YAML frontmatter
   - Extract progress log entries
   - Identify completed vs remaining tasks

### Output Format

```
📅 TODAY'S FOCUS
===============
Date: [Today's date]
Time: [Current time]

🎯 ACTIVE STORY
--------------
[STORY-ID]: [Title]
Status: [development/review/qa]
Branch: [branch-name]
Started: [X days ago]

📊 CURRENT PROGRESS
-----------------
Last activity: [last commit/change]

Completed:
✅ [Completed item 1]
✅ [Completed item 2]

In Progress:
🔄 [Current task]

Remaining:
⏳ [Todo item 1]
⏳ [Todo item 2]
```

#### Next Actions

```
🚀 NEXT ACTIONS
--------------
1. [Specific next task]
   Command: /story-[appropriate]

2. [Second priority task]
   Command: /story-[appropriate]

3. [Third task if applicable]
```

#### Attention Needed

If blockers exist:
```
⚠️ ATTENTION NEEDED
------------------
- [Failing tests]
- [Unresolved conflicts]
- [Missing dependencies]
- [Review feedback]
```

#### Time Management

```
⏰ TIME ALLOCATION
-----------------
Suggested for today:
- Morning: [Main development task]
- Afternoon: [Testing/review]

Estimated to complete: [X hours]

Consider: /story-timebox 2
```

#### Context Reminders

If applicable:
```
📌 REMEMBER
----------
- [Project standard]
- [Technical decision]
- [Deadline]
```

#### Project Health

```
💚 PROJECT HEALTH
----------------
Tests: [Passing/Failing]
Build: [Success/Failed]
Coverage: [X%]
Lint: [Clean/Issues]
```

### Empty State

If no active story:
```
💡 NO ACTIVE STORY
-----------------

Options:
1. Continue previous: /story-continue
2. Start new: /story-new
3. Review backlog: /story-next
4. Fix tech debt: /story-tech-debt
```

#### Standup Summary

Always include:
```
📢 STANDUP SUMMARY
-----------------
Yesterday: [What was completed]
Today: [What will be worked on]
Blockers: [Any impediments]
```

### Notes
- Read-only display of current state
- Does not modify any files
- Suggests highest priority task to begin with