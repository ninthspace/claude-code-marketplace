# /story-continue

## Meta
- Version: 2.0
- Category: workflow
- Complexity: standard
- Purpose: Resume work on the most recently active story with context-aware status reporting

## Definition
**Purpose**: Resume development on the most recently modified story by displaying current status, git branch information, and suggesting appropriate next actions based on story stage.

**Syntax**: `/story-continue`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| - | - | - | - | No parameters required | - |

## INSTRUCTION: Continue Story Development

### INPUTS
- Story files from `/stories/development/`, `/stories/review/`, `/stories/qa/`
- Current git branch and status
- Project context from `/project-context/` (optional for enhanced guidance)

### PROCESS

#### Phase 1: Story Discovery
1. **SEARCH** for most recently modified story in order:
   - CHECK `/stories/development/` (highest priority)
   - CHECK `/stories/review/` (if no development stories)
   - CHECK `/stories/qa/` (if no review stories)
   - CHECK `/stories/backlog/` (fallback if nothing active)

2. **IDENTIFY** most recent story by:
   - SORT by file modification time (most recent first)
   - SELECT first result
   - IF no stories found: PROCEED to Phase 6 (No Active Stories)

3. **EXTRACT** story ID from filename:
   - PARSE filename pattern: `STORY-YYYY-NNN.md`
   - VALIDATE story ID format

#### Phase 2: Story File Analysis
1. **READ** story file content
2. **PARSE** and **EXTRACT** key information:
   - Story title
   - Current status (backlog/development/review/qa/completed)
   - Branch name
   - Last progress log entry (most recent)
   - Implementation checklist with status
   - Success criteria (marked/unmarked)
   - Technical notes and dependencies
   - Started date
   - Completed date (if applicable)

3. **IDENTIFY** incomplete checklist items:
   - COUNT total checklist items
   - COUNT completed items (`[x]`)
   - COUNT remaining items (`[ ]`)
   - LIST remaining items for display

#### Phase 3: Git Status Check
1. **GET** current git branch:
   - RUN: `git branch --show-current`
   - STORE current branch name

2. **COMPARE** with story branch:
   - IF current branch matches story branch:
     * SHOW: "✅ On correct branch: [branch-name]"
   - IF current branch differs from story branch:
     * SHOW: "⚠️ Not on story branch"
     * CURRENT: [current-branch]
     * EXPECTED: [story-branch]
     * OFFER: "Switch to story branch? (y/n)"

3. **CHECK** git working tree status:
   - RUN: `git status --porcelain`
   - IF uncommitted changes exist:
     * COUNT modified files
     * COUNT untracked files
     * SHOW: "⚠️ You have uncommitted changes"
     * LIST: Modified and untracked files
     * SUGGEST: `/story-save` to commit progress
   - IF working tree clean:
     * SHOW: "✅ Working tree clean"

4. **CHECK** branch sync status:
   - RUN: `git rev-list --left-right --count origin/[branch]...[branch]`
   - IF branch ahead of remote:
     * SHOW: "⬆️ [N] commits ahead of remote"
     * SUGGEST: Push to remote when ready
   - IF branch behind remote:
     * SHOW: "⬇️ [N] commits behind remote"
     * SUGGEST: Pull latest changes
   - IF diverged:
     * SHOW: "⚠️ Branch has diverged from remote"
     * SUGGEST: Rebase or merge required

#### Phase 4: Progress Summary Display
1. **DISPLAY** comprehensive story status:
   ```
   📖 RESUMING STORY
   ════════════════════════════════════
   Story: [STORY-ID] - [Title]
   Status: [development/review/qa]
   Branch: [branch-name]

   📅 Timeline:
   Started: [date]
   Last Updated: [date]
   [If completed:] Completed: [date]

   📊 Progress:
   Implementation: [X/Y] tasks complete ([Z%])
   - [x] Completed item 1
   - [x] Completed item 2
   - [ ] Remaining item 1
   - [ ] Remaining item 2

   📝 Last Progress Entry:
   [Most recent progress log entry with timestamp]

   🔧 Git Status:
   [Branch status - on correct branch or need to switch]
   [Working tree status - clean or uncommitted changes]
   [Sync status - ahead/behind/diverged from remote]
   ```

#### Phase 5: Context-Aware Next Actions
**IF status is "development":**
1. **SUGGEST** development actions:
   ```
   💡 NEXT STEPS:
   1. /story-implement [story-id] - Continue implementation
   2. /story-save - Commit current progress
   3. /story-review - Move to code review when complete

   Development Commands:
   - Run server: [detected from project context]
   - Run tests: [detected from project context]
   - Run linter: [detected from project context]
   ```

**IF status is "review":**
1. **CHECK** for review issues:
   - READ story file for review notes
   - IDENTIFY any failed checks or requested changes
   - LIST issues that need addressing

2. **SUGGEST** review actions:
   ```
   💡 NEXT STEPS:
   [If issues exist:]
   Issues to Address:
   - [Issue 1 from review notes]
   - [Issue 2 from review notes]

   Actions:
   1. Fix identified issues in code
   2. /story-save - Commit fixes
   3. /story-qa - Move to QA when review passes

   [If no issues:]
   Review Status: ✅ All checks passed
   1. /story-qa - Move to quality assurance
   2. /story-refactor - Optional improvements
   ```

**IF status is "qa":**
1. **SUGGEST** QA actions:
   ```
   💡 NEXT STEPS:
   1. /story-test-integration - Run integration tests
   2. /story-validate - Perform final validation checks
   3. /story-ship - Deploy when QA complete

   QA Checklist:
   - [ ] Manual testing across browsers
   - [ ] Performance testing
   - [ ] Accessibility testing
   - [ ] Security review
   - [ ] Documentation verification
   ```

**IF status is "backlog":**
1. **SUGGEST** starting development:
   ```
   💡 NEXT STEPS:
   This story is still in backlog.

   1. /story-start [story-id] - Begin development
   2. /story-start [story-id] --boilerplate - Start with boilerplate
   ```

#### Phase 6: No Active Stories Found
1. **IF** no stories found in development, review, or qa:
   - **SEARCH** for completed stories
   - **COUNT** total completed stories
   - **DISPLAY**:
     ```
     ✅ NO ACTIVE STORIES
     ════════════════════════════════════

     All stories are complete or in backlog.

     Completed Stories: [count]
     [List last 3 completed stories with titles]

     💡 NEXT STEPS:
     1. /story-new - Create a new story
     2. /story-start [story-id] - Start a backlog story
     3. /project-status - View full project status

     Backlog Stories Available:
     [List backlog stories if any exist]
     ```

### OUTPUTS
- Formatted story status summary
- Git branch and working tree status
- Progress metrics and completion percentage
- Incomplete checklist items
- Context-aware next action suggestions
- Optional: Switch to story branch (if needed)

### RULES
- MUST search development, review, and qa directories in order
- MUST display most recently modified story
- MUST show current git status and branch
- MUST suggest actions appropriate to story status
- SHOULD offer to switch branches if not on story branch
- SHOULD highlight uncommitted changes if present
- SHOULD calculate and display progress percentage
- MUST handle case when no active stories exist
- NEVER modify story file (read-only command)
- NEVER create or delete files

## Examples

### Example 1: Resume Development Story
```bash
INPUT:
/story-continue

PROCESS:
→ Searching for active stories...
→ Found: /stories/development/STORY-AUTH-001.md
→ Modified: 2 hours ago
→ Analyzing story status...
→ Checking git branch...
→ Current branch: feature/auth-001-login-form ✅

OUTPUT:
📖 RESUMING STORY
════════════════════════════════════
Story: STORY-AUTH-001 - Implement Login Form
Status: development
Branch: feature/auth-001-login-form

📅 Timeline:
Started: 2025-09-28
Last Updated: 2 hours ago

📊 Progress:
Implementation: 6/10 tasks complete (60%)
- [x] Feature implementation
- [x] Unit tests
- [x] Integration tests
- [x] Error handling
- [x] Loading states
- [x] Browser tests
- [ ] Performance optimization
- [ ] Accessibility
- [ ] Security review
- [ ] Documentation

📝 Last Progress Entry:
[2025-09-28 14:30] Implemented login form with validation.
Added unit tests and feature tests. All tests passing.
Created browser test for login flow.

🔧 Git Status:
✅ On correct branch: feature/auth-001-login-form
⚠️ You have uncommitted changes (3 files modified)
Files:
  M app/Livewire/Auth/LoginForm.php
  M tests/Feature/Auth/LoginTest.php
  M stories/development/STORY-AUTH-001.md

💡 NEXT STEPS:
1. /story-implement STORY-AUTH-001 - Continue implementation
2. /story-save - Commit current progress
3. /story-review - Move to code review when complete

Development Commands:
- Run server: composer dev
- Run tests: vendor/bin/pest
- Run linter: vendor/bin/pint
```

### Example 2: Resume Review Story
```bash
INPUT:
/story-continue

PROCESS:
→ Searching for active stories...
→ No stories in development
→ Found: /stories/review/STORY-PROFILE-002.md
→ Modified: 1 day ago
→ Analyzing story status...
→ Checking git branch...
→ Current branch: main
→ Expected branch: feature/profile-002-settings

OUTPUT:
📖 RESUMING STORY
════════════════════════════════════
Story: STORY-PROFILE-002 - User Profile Settings
Status: review
Branch: feature/profile-002-settings

📅 Timeline:
Started: 2025-09-27
Last Updated: 1 day ago

📊 Progress:
Implementation: 10/10 tasks complete (100%)
All implementation tasks completed ✅

📝 Last Progress Entry:
[2025-09-27 16:45] Code review completed. Minor formatting
issues found. Need to run Pint and update comments.

🔧 Git Status:
⚠️ Not on story branch
Current: main
Expected: feature/profile-002-settings
✅ Working tree clean

Review Notes:
- Fix code formatting (run Pint)
- Add missing PHPDoc comments for public methods
- Update test descriptions to be more descriptive

💡 NEXT STEPS:
Issues to Address:
- Code formatting needs fixes
- Missing documentation comments
- Test descriptions need improvement

Actions:
1. Switch to feature/profile-002-settings branch
2. Fix identified issues in code
3. /story-save - Commit fixes
4. /story-qa - Move to QA when review passes

Switch to story branch now? [y/n]
```

### Example 3: Resume QA Story
```bash
INPUT:
/story-continue

PROCESS:
→ Searching for active stories...
→ No stories in development or review
→ Found: /stories/qa/STORY-CART-003.md
→ Modified: 3 hours ago
→ Analyzing story status...
→ Checking git branch...

OUTPUT:
📖 RESUMING STORY
════════════════════════════════════
Story: STORY-CART-003 - Shopping Cart Checkout
Status: qa
Branch: feature/cart-003-checkout

📅 Timeline:
Started: 2025-09-25
Last Updated: 3 hours ago
Expected Completion: 2025-09-29

📊 Progress:
Implementation: 10/10 tasks complete (100%)
QA Progress: 3/5 checks complete (60%)

📝 Last Progress Entry:
[2025-09-28 13:20] QA testing in progress. Manual testing
complete across Chrome, Firefox, Safari. Performance testing
shows good results. Starting accessibility review.

🔧 Git Status:
✅ On correct branch: feature/cart-003-checkout
✅ Working tree clean
⬆️ 2 commits ahead of remote

QA Checklist:
- [x] Manual testing across browsers
- [x] Performance testing
- [x] Security review
- [ ] Accessibility testing
- [ ] Documentation verification

💡 NEXT STEPS:
1. Complete accessibility testing
2. Verify documentation is up to date
3. /story-validate - Perform final validation checks
4. /story-ship - Deploy when QA complete

QA Commands:
- Run accessibility audit: npm run a11y
- Run security scan: npm run security-check
- Run full test suite: vendor/bin/pest
```

### Example 4: No Active Stories
```bash
INPUT:
/story-continue

PROCESS:
→ Searching for active stories...
→ No stories in development
→ No stories in review
→ No stories in qa
→ Checking completed stories...
→ Found 5 completed stories

OUTPUT:
✅ NO ACTIVE STORIES
════════════════════════════════════

All stories are complete or in backlog.

Completed Stories: 5
Recently completed:
- STORY-AUTH-001: Implement Login Form (completed 2025-09-28)
- STORY-PROFILE-002: User Profile Settings (completed 2025-09-27)
- STORY-CART-003: Shopping Cart (completed 2025-09-26)

💡 NEXT STEPS:
1. /story-new - Create a new story
2. /story-start [story-id] - Start a backlog story
3. /project-status - View full project status

Backlog Stories Available:
- STORY-SEARCH-004: Search Functionality
- STORY-NOTIF-005: Notification System
- STORY-EXPORT-006: Data Export Feature
```

### Example 5: Branch Diverged
```bash
INPUT:
/story-continue

PROCESS:
→ Searching for active stories...
→ Found: /stories/development/STORY-API-004.md
→ Checking git status...
→ Branch has diverged from remote

OUTPUT:
📖 RESUMING STORY
════════════════════════════════════
Story: STORY-API-004 - REST API Endpoints
Status: development
Branch: feature/api-004-endpoints

📅 Timeline:
Started: 2025-09-28
Last Updated: 30 minutes ago

📊 Progress:
Implementation: 4/10 tasks complete (40%)
- [x] Feature implementation
- [x] Unit tests
- [x] Integration tests
- [x] Error handling
- [ ] Loading states
- [ ] Browser tests
- [ ] Performance optimization
- [ ] Accessibility
- [ ] Security review
- [ ] Documentation

📝 Last Progress Entry:
[2025-09-28 15:45] Implemented API endpoints for user
resources. Added authentication middleware.

🔧 Git Status:
✅ On correct branch: feature/api-004-endpoints
⚠️ You have uncommitted changes (2 files modified)
⚠️ Branch has diverged from remote
Local: 3 commits ahead
Remote: 2 commits ahead
Action required: Rebase or merge

💡 NEXT STEPS:
⚠️ IMPORTANT: Resolve branch divergence first

1. Option A: Rebase on remote
   git fetch origin
   git rebase origin/feature/api-004-endpoints

2. Option B: Merge remote changes
   git fetch origin
   git merge origin/feature/api-004-endpoints

After resolving:
3. /story-implement STORY-API-004 - Continue implementation
4. /story-save - Commit progress
```

## Edge Cases

### Multiple Stories Modified Simultaneously
```
IF multiple stories have same modification time:
- SELECT story with most recent progress log entry
- IF still tied: SELECT by alphabetical story ID
- LOG: "Multiple stories modified recently, selected: [story-id]"
```

### Story File Corrupted or Invalid
```
IF story file cannot be parsed:
- LOG: "Warning: Story file appears corrupted"
- SHOW: Available story metadata (ID, file path, mod time)
- SUGGEST: Manual review of story file
- OFFER: Try next most recent story
```

### Git Repository Not Initialized
```
IF not in git repository:
- SKIP git status checks
- SHOW: Story information only
- WARN: "Not in git repository, git status unavailable"
- SUGGEST: Initialize git repository
```

### Branch Deleted Remotely
```
IF story branch no longer exists on remote:
- WARN: "Story branch not found on remote"
- SUGGEST: Push branch to remote or create new branch
- SHOW: Local branch status only
```

### Working Directory Outside Project Root
```
IF cwd not in project root:
- ATTEMPT to find project root
- IF found: Continue from project root
- IF not found: HALT with error
- SUGGEST: Run from project root directory
```

## Error Handling
- **No story directories exist**: Return "Error: No story directories found. Run /project-init first"
- **Story file read error**: Show "Error reading story file: [error]" and try next story
- **Invalid story format**: Warn and show what could be parsed
- **Git command fails**: Show git error and continue with story info only
- **Branch switch fails**: Show error and offer manual switch instructions

## Performance Considerations
- Scan directories once and cache file list
- Use file modification time for quick sorting (no need to read all files)
- Read only the most recent story file completely
- Parse story file sections on-demand (not all at once)
- Git commands run in parallel when possible
- Cache git status results within command execution

## Related Commands
- `/story-start [id]` - Start new story development
- `/story-implement [id]` - Continue implementation
- `/story-save` - Commit current progress
- `/story-review` - Move story to code review
- `/story-qa` - Move story to quality assurance
- `/project-status` - View all project stories

## Constraints
- ✅ MUST find most recently modified story
- ✅ MUST display comprehensive story status
- ✅ MUST check and display git status
- ✅ MUST suggest context-appropriate next actions
- ⚠️ NEVER modify story files (read-only)
- ⚠️ NEVER create or delete files
- 📋 SHOULD offer to switch branches if needed
- 💡 SHOULD highlight uncommitted changes
- 🔧 SHOULD detect and report sync issues
