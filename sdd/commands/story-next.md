# /story-next

Suggests what to work on next based on priorities and status.

## Implementation

**Format**: Imperative (comprehensive)
**Actions**: Multi-step analysis with dependency validation
**Modifications**: None (read-only recommendations)

### Analysis Steps

#### 1. Assess Current State
- List all stories in `/stories/development/`
- List all stories in `/stories/review/`
- List all stories in `/stories/qa/`
- List all completed stories in `/stories/completed/`
- Read backlog priorities from `/stories/backlog/`
- Read dependency graph from `/project-context/story-relationships.md`

#### 2. Validate Dependencies
- Cross-reference dependencies against completed stories
- Verify no recommended stories exist in `/stories/completed/`
- Flag mismatches between planned vs actual completion status
- Identify stories with all dependencies satisfied

#### 3. Apply Decision Logic

Priority order:
1. Stories in QA with issues (closest to shipping)
2. Stories in review with feedback
3. Stories in development > 3 days (complete or timebox)
4. Critical bugs/security issues
5. High-priority backlog items with satisfied dependencies
6. Technical debt or improvements

### Output Format

#### Primary Recommendations

```
📋 NEXT STORY RECOMMENDATIONS
============================

🥇 HIGHEST PRIORITY
------------------
[STORY-ID]: [Title]
Status: Available (verified not completed)
Dependencies: [List with completion status]
Reason: [Why this is most important]
Estimated effort: [X days]
Business value: [High/Medium/Low]

Command: /story-start [STORY-ID]

🥈 SECOND OPTION
---------------
[STORY-ID]: [Title]
Status: Available (verified not completed)
Dependencies: [List with completion status]
Reason: [Why consider this]
Estimated effort: [X days]
Trade-off: [What you defer]

🥉 THIRD OPTION
--------------
[STORY-ID]: [Title]
Status: Available (verified not completed)
Dependencies: [List with completion status]
Reason: [Alternative path]
Benefit: [Specific advantage]
```

#### Decision Factors

```
⚖️ DECISION FACTORS

Time available:
- Full day → Start new feature
- Few hours → Fix bugs/review
- < 1 hour → Quick improvements

Energy level:
- High → Complex new work
- Medium → Continue existing
- Low → Simple fixes/docs

Dependencies:
- Waiting on review: [list]
- Blocked by external: [list]
- Ready to start: [list]
```

#### Backlog Overview

```
📚 BACKLOG OVERVIEW

✅ COMPLETED STORIES:
[List from /stories/completed/ with dates]

📋 REMAINING BACKLOG:

High Priority:
1. [Story] - [Est.] - Available
2. [Story] - [Est.] - Blocked by [X]

Medium Priority:
3. [Story] - [Est.] - Available
4. [Story] - [Est.] - Blocked by [X]

Quick Wins (<1 day):
5. [Bug fix] - 2 hours
6. [Doc update] - 1 hour

Technical Debt:
7. [Refactor] - [Est.]
8. [Performance] - [Est.]
```

#### Pattern Insights (Optional)

If sufficient historical data:
```
📊 PATTERN INSIGHTS

Based on history:
- Fastest completions: [story type]
- Most productive: [day/time]
- Success patterns: [insights]

Recommendation: [Specific suggestion]
```

#### Risk Assessment

```
⚠️ RISK CONSIDERATIONS

Risky to start now:
- [Complex story] - End of week
- [Large refactor] - Before deadline

Safe to start:
- [Small feature] - Low risk
- [Bug fix] - Quick win
```

#### Project Context

```
🎯 PROJECT PRIORITIES

This sprint/week focus: [Main goal]
Upcoming deadline: [Date] - [What's due]
User feedback priority: [Most requested]
```

### Empty State

If no clear next story:
```
💭 NO CLEAR PRIORITY

Productive alternatives:
1. Code review backlog
2. Update documentation
3. Write tests for untested code
4. Refactor complex functions
5. Learn new tool/technique

Create new story: /story-new
```

### Action Plan

Always conclude with:
```
✅ RECOMMENDED ACTION PLAN
=========================

Right now:
1. [Immediate action]
   Command: /[command-to-run]

Then:
2. [Follow-up action]

This week:
3. [Week goal]
```

### Notes
- Read-only analysis, no file modifications
- Validates all dependencies against filesystem
- Prevents recommending completed stories
- Waits for user decision before any action