# /sdd:story-blocked

Marks story as blocked and logs the reason.

## Implementation

**Format**: Imperative (comprehensive)
**Actions**: Multi-step status update with tracking
**Modifications**: Updates story file, adds progress log entry

### Input Parameters
```
/sdd:story-blocked [STORY-ID] [reason]
```
- `STORY-ID` (optional): Defaults to current active story
- `reason` (optional): Prompted if not provided

### Execution Steps

#### 1. Identify Target Story
- If `STORY-ID` provided, locate story file across all directories
- Otherwise, determine current active story from git branch
- Verify story exists and is not already completed

#### 2. Capture Blocking Details

Prompt user for:

```
🚫 BLOCKING ISSUE
================

Story: [ID] - [Title]
Blocked since: [timestamp]

Reason for block:
- [ ] Waiting on external dependency
- [ ] Need clarification on requirements
- [ ] Technical issue/bug
- [ ] Waiting for code review
- [ ] Infrastructure/environment issue
- [ ] Missing access/permissions
- [ ] Other: [specify]

Detailed description:
[What exactly is blocking progress]

What's needed to unblock:
[Specific action or information needed]

Who can help:
[Person/team who can resolve]

Estimated resolution:
[When might this be resolved]
```

#### 3. Update Story File

Modifications to make:
1. Update YAML frontmatter:
   ```yaml
   status: blocked
   blocked_since: [ISO timestamp]
   blocked_reason: [selected reason]
   ```

2. Add progress log entry:
   ```markdown
   ## [Timestamp] - BLOCKED

   **Reason**: [selected reason]
   **Details**: [detailed description]
   **Needed to unblock**: [requirements]
   **Can help**: [person/team]
   **Estimated resolution**: [timeframe]

   **Completed before block**:
   - [List work finished before blocking]
   ```

3. Add `[BLOCKED]` tag to story title if not present

#### 4. Suggest Alternative Work

```
💡 WHILE BLOCKED, YOU COULD:

Related work:
- [ ] Write tests for completed parts
- [ ] Document what's built so far
- [ ] Refactor existing code

Other stories:
- [Story X]: Ready to start
- [Story Y]: Quick bug fix

Improvements:
- Update documentation
- Fix technical debt
- Review other PRs
```

#### 5. Track Blocked Time

Calculate and display:

```
⏱️ BLOCKED TIME TRACKING

This story:
- Previously blocked: [X hours total]
- Current block: Started [timestamp]

All stories this week:
- Total blocked time: [X hours]
- Main block reasons: [Top 3]
```

Update story metadata:
```yaml
blocked_time_total: [X hours]
blocked_instances: [count]
```

#### 6. Create Follow-up Reminder

```
📅 FOLLOW-UP SCHEDULED

Check status in: [X hours/days]
Reminder for: [date/time]

Auto-check will:
- Verify if still blocked
- Suggest escalation if needed
- Track resolution time
```

Add to story metadata:
```yaml
follow_up_date: [ISO timestamp]
```

#### 7. Pattern Detection

If same blocking reason appears multiple times:

```
⚠️ PATTERN DETECTED

This is the [Nth] time blocked by:
[Similar blocking reason]

Consider:
- Process improvement
- Better communication
- Different approach
```

Add note to project context or retrospective file.

### Output Format

#### Block Confirmation

```
✅ STORY BLOCKED
===============

Story: [STORY-ID] - [Title]
Blocked since: [timestamp]
Reason: [selected reason]

📊 BLOCK REPORT
==============

Current blocks:
1. [Story ID]: [Reason] - [Duration]
2. [Story ID]: [Reason] - [Duration]

This week's blocks:
- External deps: [X hours]
- Clarifications: [X hours]
- Technical: [X hours]

Impact:
- Velocity reduced by [X]%
- [X] stories delayed
```

#### Unblock Procedure

For future reference:

When running `/sdd:story-continue` or `/sdd:story-unblock`:
```
✅ UNBLOCKED!
============

Was blocked for: [total time]
Resolution: [what resolved it]

Actions taken:
- Remove [BLOCKED] tag
- Update status to previous state
- Log resolution in progress
- Resume work
```

#### Escalation Path

If blocked > 4 hours:
```
⚠️ ESCALATION RECOMMENDED
========================

Blocked for: [X hours]

Actions:
- Notify: [escalation contact]
- Consider: Alternative approach
- Document: For retrospective
```

### Notes
- Modifies story YAML frontmatter and progress log
- Tracks blocking time in metadata
- Suggests productive alternatives
- Does not automatically switch stories (waits for user decision)
- Creates follow-up reminder for resolution checking