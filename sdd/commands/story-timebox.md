# /sdd:story-timebox

## Meta
- Version: 2.0
- Category: productivity
- Complexity: medium
- Purpose: Set focused work session timer with progress tracking and checkpoints

## Definition
**Purpose**: Start a time-boxed work session with automatic progress checkpoints, metrics tracking, and session logging for story development.

**Syntax**: `/sdd:story-timebox [duration] [mode]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| duration | number | No | 2 | Session duration in hours | 0.5-8 hours |
| mode | string | No | standard | Timer mode: standard or pomodoro | standard/pomodoro |

## INSTRUCTION: Start Timeboxed Work Session

### INPUTS
- duration: Session length in hours (or use default)
- mode: Timer mode (standard with checkpoints or pomodoro technique)
- Current active story from `/docs/stories/development/`
- Session goal from user

### PROCESS

#### Phase 1: Session Initialization
1. **DETERMINE** session parameters:
   - IF duration provided: USE specified hours
   - IF no duration: DEFAULT to 2 hours
   - IF mode provided: USE specified mode (standard/pomodoro)
   - IF no mode: DEFAULT to standard

2. **FIND** active story:
   - SCAN `/docs/stories/development/` for active story
   - IF multiple stories: ASK user which story to focus on
   - IF no active story: SUGGEST using `/sdd:story-start [id]` first

3. **ASK** user for session goal:
   - "What do you want to accomplish in this session?"
   - RECORD goal for tracking

#### Phase 2: Session Planning
1. **CALCULATE** time checkpoints:

   IF standard mode (duration in hours):
   - Start time: [current timestamp]
   - 25% checkpoint: [start + 0.25 * duration]
   - 50% checkpoint: [start + 0.50 * duration]
   - 75% checkpoint: [start + 0.75 * duration]
   - End time: [start + duration]

   IF pomodoro mode:
   - Calculate 25-minute work intervals
   - 5-minute short breaks
   - 15-minute long break after 4 intervals
   - Total time based on duration

2. **GENERATE** session plan based on goal:
   - Break down goal into 4 quarterly segments
   - Suggest specific tasks for each quarter
   - Include testing and cleanup phases

3. **CREATE** session tracking file:
   - Location: `.timebox/session-[timestamp].md`
   - Contains: Story ID, goal, plan, checkpoints

#### Phase 3: Session Start Display
1. **DISPLAY** session start summary:
   ```
   ⏰ TIMEBOX SESSION STARTED
   ═══════════════════════════════════

   Duration: [X] hours ([X] minutes)
   Started: [HH:MM AM/PM]
   Ends at: [HH:MM AM/PM]

   Story: [STORY-ID] - [Title]
   Session Goal: [User's stated goal]

   📍 CHECKPOINTS:
   - 25% ([HH:MM]): Quick progress check
   - 50% ([HH:MM]): Halfway review
   - 75% ([HH:MM]): Wrap-up warning
   - 100% ([HH:MM]): Session complete

   Timer Mode: [Standard/Pomodoro]
   ```

2. **SHOW** session plan:
   ```
   📋 SESSION PLAN
   ══════════════════════════════════

   Quarter 1 (0-25%): [Focus area]
   - [ ] [Specific task 1]
   - [ ] [Specific task 2]

   Quarter 2 (25-50%): [Focus area]
   - [ ] [Specific task 3]
   - [ ] [Specific task 4]

   Quarter 3 (50-75%): [Focus area]
   - [ ] [Test what was built]
   - [ ] [Address any issues found]

   Quarter 4 (75-100%): [Focus area]
   - [ ] [Commit changes]
   - [ ] [Update story progress]
   - [ ] [Document session notes]

   🎯 START NOW: Begin with [first task]
   ```

3. **REMIND** user:
   - I'll check in at each checkpoint
   - Mention checkpoints when user provides updates
   - Track progress throughout session

#### Phase 4: Checkpoint Management
**At each 25%, 50%, 75% checkpoint**, IF user interacts:

1. **DISPLAY** checkpoint notification:
   ```
   🔔 CHECKPOINT: [25/50/75]% Complete
   ═══════════════════════════════════

   Time Elapsed: [X] minutes
   Time Remaining: [X] minutes
   Current Time: [HH:MM AM/PM]

   Progress Check:
   - Planned: [Tasks planned for this quarter]
   - What's done: [Ask user what was completed]
   - On track: [Calculate based on response]

   [IF on track:]
   Great progress! Continue with: [next planned task]

   [IF behind:]
   Adjust plan: [Suggest focusing on priority items]

   [IF ahead:]
   Excellent! Consider: [Suggest stretch goals]
   ```

2. **UPDATE** session tracking file:
   - Log checkpoint reached
   - Record user's progress update
   - Note any plan adjustments

#### Phase 5: Session Metrics Tracking
**Throughout session**, TRACK:

1. **Code Metrics** (if user commits/shows changes):
   - Lines added/removed
   - Files modified
   - Commits made

2. **Test Metrics** (if tests run):
   - Tests added
   - Tests passing/failing
   - Coverage changes

3. **Progress Metrics**:
   - Tasks completed vs planned
   - Checkpoint adherence
   - Goal achievement percentage

#### Phase 6: Session Interruption Handling
IF user says "pause", "stop", "brb", or similar:

1. **PAUSE** session:
   ```
   ⏸️ SESSION PAUSED
   ═══════════════════════════════════

   Paused at: [HH:MM AM/PM]
   Time Elapsed: [X] minutes
   Time Remaining: [X] minutes

   Progress so far:
   - [Tasks completed]

   To resume: Simply mention you're back or say "resume"
   To end early: Say "end session"
   ```

2. **SAVE** pause state to session tracking file

IF user returns:
1. **RESUME** session:
   ```
   ▶️ SESSION RESUMED
   ═══════════════════════════════════

   Welcome back!
   Time Remaining: [X] minutes
   Next Checkpoint: [time]

   Continue with: [current task]
   ```

#### Phase 7: Session Completion
**At session end** OR IF user says "end session":

1. **DISPLAY** session summary:
   ```
   ✅ SESSION COMPLETE
   ═══════════════════════════════════

   Total Duration: [X] hours [X] minutes
   Story: [STORY-ID] - [Title]

   SESSION GOAL:
   [Original goal stated]

   ACCOMPLISHED:
   ✓ [Completed task 1]
   ✓ [Completed task 2]
   ✓ [Completed task 3]
   ⏳ [Partial task - note what's left]

   SESSION METRICS:
   - Planned vs Actual: [X]%
   - Code changes: [X] files, [X] lines
   - Commits: [X]
   - Tests: [X] added, [X/Y] passing
   - Checkpoints hit: [X/4]

   WHAT WENT WELL:
   - [Success point 1]
   - [Success point 2]

   CHALLENGES:
   - [Challenge encountered]
   - [How addressed or needs addressing]

   FOR NEXT SESSION:
   - [Specific next task to start with]
   - [Any blockers to resolve first]
   - [Estimated time needed]

   NEXT STEPS:
   1. /sdd:story-save           # Save progress to story
   2. /sdd:story-quick-check    # Verify everything works
   3. Take a break! 🎉
   ```

2. **ASK** user for session notes:
   - "What went well this session?"
   - "What was challenging?"
   - "What should you focus on next time?"

3. **UPDATE** story progress log:
   - Append session summary to story file
   - Note tasks completed and time spent
   - Record any blockers or notes

4. **SAVE** session to history:
   - Complete session tracking file
   - Add to `.timebox/history/` for velocity analysis

5. **SUGGEST** next session:
   - Based on progress rate
   - Consider remaining work
   - Recommend duration and focus

#### Phase 8: Pomodoro Mode (Special Handling)
IF mode = pomodoro:

1. **STRUCTURE** session as intervals:
   ```
   🍅 POMODORO MODE ACTIVE
   ═══════════════════════════════════

   Session Structure:
   🍅 Pomodoro 1: 25 minutes (Focus)
   ☕ Break: 5 minutes
   🍅 Pomodoro 2: 25 minutes (Focus)
   ☕ Break: 5 minutes
   🍅 Pomodoro 3: 25 minutes (Focus)
   ☕ Break: 5 minutes
   🍅 Pomodoro 4: 25 minutes (Focus)
   🎉 Long Break: 15 minutes

   Total Time: ~2 hours

   Current: 🍅 Pomodoro 1
   Focus Task: [First planned task]
   Time Remaining: 25:00
   ```

2. **AT EACH INTERVAL END**:
   - Notify completion
   - Show brief summary
   - Announce break time or next pomodoro
   - Track completed pomodoros

3. **DURING BREAKS**:
   - Remind user to step away
   - Show break time remaining
   - Announce when break ends

### OUTPUTS
- `.timebox/session-[timestamp].md` - Session tracking file
- Updated story progress log with session summary
- Session history added to `.timebox/history/`
- Velocity metrics for future planning

### RULES
- MUST find active story before starting session
- MUST calculate accurate checkpoint times
- MUST track session start and end timestamps
- MUST save session data to tracking file
- SHOULD remind at checkpoints if user is active
- SHOULD track metrics if commits/tests are mentioned
- SHOULD update story progress log at session end
- NEVER interrupt user during focused work
- ALWAYS provide encouragement and progress acknowledgment
- MUST handle pause/resume gracefully

## Timer Mode Details

### Standard Mode
- Single continuous session with 4 checkpoints (25%, 50%, 75%, 100%)
- Flexible focus periods
- Checkpoints for progress assessment and plan adjustment
- Best for: Larger tasks, exploratory work, complex implementations

### Pomodoro Mode
- Fixed 25-minute work intervals
- Mandatory 5-minute breaks between intervals
- 15-minute long break after 4 intervals
- Structured and disciplined approach
- Best for: Deep focus, avoiding burnout, building work habits

## Examples

### Example 1: Standard 2-Hour Session
```bash
INPUT:
/sdd:story-timebox

OUTPUT:
→ Finding active story...
→ Located: STORY-2025-003 in development

What do you want to accomplish in this session?
> Implement the task editing feature and write tests

⏰ TIMEBOX SESSION STARTED
═══════════════════════════════════

Duration: 2 hours (120 minutes)
Started: 2:00 PM
Ends at: 4:00 PM

Story: STORY-2025-003 - Task Management System
Session Goal: Implement task editing feature and write tests

📍 CHECKPOINTS:
- 25% (2:30 PM): Quick progress check
- 50% (3:00 PM): Halfway review
- 75% (3:30 PM): Wrap-up warning
- 100% (4:00 PM): Session complete

Timer Mode: Standard

📋 SESSION PLAN
══════════════════════════════════

Quarter 1 (0-25%): Feature Implementation
- [ ] Create TaskEdit Livewire component
- [ ] Add edit form with validation

Quarter 2 (25-50%): Continue Implementation
- [ ] Implement update logic in controller
- [ ] Add authorization checks

Quarter 3 (50-75%): Testing
- [ ] Write feature tests for edit flow
- [ ] Test validation rules
- [ ] Test authorization

Quarter 4 (75-100%): Cleanup & Documentation
- [ ] Run all tests and verify passing
- [ ] Commit changes with descriptive message
- [ ] Update story progress log

🎯 START NOW: Begin with creating TaskEdit Livewire component
```

### Example 2: Pomodoro Mode
```bash
INPUT:
/sdd:story-timebox 2 pomodoro

OUTPUT:
→ Finding active story...
→ Located: STORY-2025-005 in development

What do you want to accomplish in this session?
> Refactor TaskManager component to reduce complexity

🍅 POMODORO MODE ACTIVE
═══════════════════════════════════

Session Structure:
🍅 Pomodoro 1: 25 minutes (Focus)
☕ Break: 5 minutes
🍅 Pomodoro 2: 25 minutes (Focus)
☕ Break: 5 minutes
🍅 Pomodoro 3: 25 minutes (Focus)
☕ Break: 5 minutes
🍅 Pomodoro 4: 25 minutes (Focus)
🎉 Long Break: 15 minutes

Total Time: ~2 hours

Story: STORY-2025-005 - Code Refactoring
Session Goal: Refactor TaskManager component to reduce complexity

🍅 POMODORO 1 (25:00)
Focus: Extract reusable methods from TaskManager
- [ ] Identify duplicate code blocks
- [ ] Create private helper methods

🎯 START NOW: Begin analyzing TaskManager for duplication

[After 25 minutes]
✅ POMODORO 1 COMPLETE

Nice work! Take a 5-minute break.
☕ Break time: 5:00

Next: 🍅 Pomodoro 2 - Continue refactoring
```

### Example 3: Short 30-Minute Session
```bash
INPUT:
/sdd:story-timebox 0.5

OUTPUT:
→ Finding active story...
→ Located: STORY-2025-007 in development

What do you want to accomplish in this session?
> Add validation rules to API endpoints

⏰ TIMEBOX SESSION STARTED
═══════════════════════════════════

Duration: 0.5 hours (30 minutes)
Started: 10:00 AM
Ends at: 10:30 AM

Story: STORY-2025-007 - REST API Development
Session Goal: Add validation rules to API endpoints

📍 CHECKPOINTS:
- 50% (10:15 AM): Halfway check
- 100% (10:30 AM): Session complete

Timer Mode: Standard (short session - fewer checkpoints)

📋 SESSION PLAN
══════════════════════════════════

First Half (0-50%): Implementation
- [ ] Add validation rules to TaskController
- [ ] Add validation rules to CategoryController

Second Half (50-100%): Testing & Wrap-up
- [ ] Test validation with invalid data
- [ ] Commit changes

🎯 START NOW: Add validation to TaskController
```

## Edge Cases

### No Active Story
- DETECT no story in `/docs/stories/development/`
- SUGGEST using `/sdd:story-start [id]` to begin a story
- OFFER to start session without story tracking
- EXIT if user declines

### Session Already Active
- DETECT existing session tracking file
- ASK user: Resume previous session or start new?
- IF resume: Load previous session state
- IF new: Complete previous session first

### Very Long Duration (> 4 hours)
- WARN about diminishing returns beyond 4 hours
- SUGGEST breaking into multiple sessions
- OFFER to set up with extra break time
- ALLOW if user confirms

### User Goes Silent Mid-Session
- Don't interrupt if user is focused
- Only mention checkpoints if user becomes active near checkpoint time
- Session tracking continues regardless

## Error Handling
- **No active story**: Suggest `/sdd:story-start [id]` or allow storyless session
- **Invalid duration**: Suggest valid range (0.5-8 hours)
- **Invalid mode**: Suggest "standard" or "pomodoro"
- **Session file write error**: Log warning, continue without persistent tracking

## Performance Considerations
- Session tracking is lightweight (< 1KB file)
- Checkpoint calculations happen at start (no ongoing computation)
- Metrics collected passively from user updates
- History files archived monthly to maintain performance

## Related Commands
- `/sdd:story-start [id]` - Begin story before timeboxing
- `/sdd:story-save` - Save progress after session
- `/sdd:story-quick-check` - Verify work after session
- `/sdd:project-status` - View velocity metrics from past sessions

## Constraints
- ✅ MUST find or create active story context
- ✅ MUST calculate accurate checkpoint times
- ✅ MUST save session data for history
- 📋 SHOULD remind at checkpoints (if user active)
- 🔧 SHOULD track metrics from user updates
- 💾 MUST update story progress log at end
- ⚠️ NEVER interrupt during focused work
- 🎯 ALWAYS acknowledge progress and provide encouragement
- ⏸️ MUST handle pause/resume gracefully
- 🧪 SHOULD suggest realistic next sessions based on velocity