# /sdd:story-save

## Meta
- Version: 2.0
- Category: workflow
- Complexity: comprehensive
- Purpose: Commit current work with properly formatted commit message and story file update

## Definition
**Purpose**: Save current progress by creating a properly formatted git commit with automatic commit type detection, story context integration, and story file progress logging.

**Syntax**: `/sdd:story-save [message]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| message | string | No | auto-generated | Custom commit message or description | Max 500 chars |

## INSTRUCTION: Save Story Progress

### INPUTS
- Current git working directory changes
- Story ID from branch name or active story
- Story file from `/docs/stories/development/`, `/docs/stories/review/`, or `/docs/stories/qa/`
- Optional: User-provided commit message
- Project context from `/docs/project-context/` (optional for enhanced commit messages)

### PROCESS

#### Phase 1: Git Status Analysis
1. **CHECK** git repository status:
   - RUN: `git status --porcelain`
   - IF no changes exist:
     * SHOW: "✅ Working tree clean - nothing to commit"
     * SUGGEST: Continue working or use /sdd:story-review
     * EXIT gracefully

2. **CATEGORIZE** changes:
   - MODIFIED files: List files with 'M' status
   - UNTRACKED files: List files with '??' status
   - DELETED files: List files with 'D' status
   - RENAMED files: List files with 'R' status

3. **ANALYZE** file sizes:
   - CHECK for large files (> 5MB)
   - WARN about potentially sensitive files (.env, credentials.json, etc.)
   - FLAG binary files that might bloat repository

4. **DISPLAY** changes summary:
   ```
   📝 CHANGES TO COMMIT
   ════════════════════════════════════
   Modified: [count] files
   - [file1]
   - [file2]

   Untracked: [count] files
   - [file3]
   - [file4]

   [If warnings exist:]
   ⚠️ WARNINGS:
   - Large file detected: [file] ([size]MB)
   - Potential secret: [file]
   ```

#### Phase 2: Story Context Discovery
1. **IDENTIFY** current story:
   - ATTEMPT 1: Extract from current git branch name
     * PATTERN: feature/[story-id]-[description]
     * EXAMPLE: feature/STORY-AUTH-001-login-form → STORY-AUTH-001
   - ATTEMPT 2: Find most recently modified story in /docs/stories/development/
   - ATTEMPT 3: Check /docs/stories/review/ and /docs/stories/qa/
   - IF no story found: PROCEED without story context

2. **READ** story file (if found):
   - EXTRACT story title
   - EXTRACT current status
   - EXTRACT branch name
   - EXTRACT last progress log entry
   - EXTRACT implementation checklist status

3. **VALIDATE** story alignment:
   - IF story branch doesn't match current branch:
     * WARN: "Current branch doesn't match story branch"
     * ASK: Continue with commit anyway? (y/n)

#### Phase 3: Commit Type Detection
1. **ANALYZE** changed files to determine commit type:

   **Detection Rules:**
   - `feat`: New feature files, new components, new functionality
     * New files in app/, src/, lib/
     * New Livewire components, React components, Vue components
     * New controllers, models, services

   - `fix`: Bug fixes, error corrections
     * Modifications to fix issues
     * Changes to error handling
     * Corrections to logic

   - `refactor`: Code restructuring without behavior change
     * File moves, renames
     * Code organization changes
     * Performance improvements without new features

   - `test`: Test additions or modifications
     * New or modified files in tests/, __tests__/
     * Test files (.test.js, .spec.js, Test.php)

   - `docs`: Documentation only
     * Changes to .md files only
     * README updates
     * Comment updates only

   - `style`: Formatting, whitespace, linting
     * Style files only (.css, .scss, .sass)
     * Formatting changes (after running Pint, Prettier)

   - `perf`: Performance improvements
     * Optimization changes
     * Database query improvements
     * Caching additions

   - `chore`: Maintenance, dependencies, configuration
     * package.json, composer.json updates
     * Config file changes
     * Build script updates

2. **SELECT** primary commit type:
   - IF multiple types apply: SELECT most significant
   - PRIORITY ORDER: feat > fix > refactor > test > perf > docs > style > chore

3. **DETERMINE** scope from changes:
   - IF story exists: USE story context (e.g., "auth", "profile", "cart")
   - ELSE: USE directory/module name
   - EXAMPLES: "auth", "api", "ui", "database", "tests"

#### Phase 4: Commit Message Generation
1. **IF** user provided message:
   - USE provided message as description
   - FORMAT: `[type]([scope]): [user message]`
   - EXAMPLE: "feat(auth): add two-factor authentication"

2. **ELSE** auto-generate message:
   - ANALYZE changes to create descriptive message
   - USE story title if available
   - INCLUDE key changes summary
   - FORMAT: `[type]([scope]): [auto-generated description]`

3. **CREATE** full commit message:
   ```
   [type]([scope]): [description]

   [If story exists:]
   Story: [STORY-ID] - [Story Title]

   Changes:
   - [Change 1]
   - [Change 2]
   - [Change 3]

   [If applicable:]
   Files: [count] modified, [count] added, [count] deleted
   ```

4. **VALIDATE** commit message format:
   - TYPE must be valid conventional commit type
   - SCOPE should be lowercase, hyphen-separated
   - DESCRIPTION should be lowercase, imperative mood
   - LENGTH should be under 72 chars for first line

#### Phase 5: Story File Update
1. **IF** story file exists:
   - **ADD** progress log entry:
     ```markdown
     - [YYYY-MM-DD HH:MM]: [commit description]
       * Files: [list key files]
       * Type: [commit type]
       * [Additional context if significant changes]
     ```

2. **UPDATE** checklist items (if applicable):
   - DETECT completed work from commit type
   - IF commit type is "test": Mark "Unit tests" or "Integration tests" as complete
   - IF commit type is "feat": Check if feature implementation complete
   - IF commit type is "docs": Mark "Documentation" as complete

3. **NOTE** implementation decisions (if significant):
   - ADD to Technical Notes section if architectural changes
   - DOCUMENT trade-offs or important decisions
   - REFERENCE commit hash (will be added after commit)

#### Phase 6: Staging and Commit
1. **STAGE** changes:
   - IF story file was updated: INCLUDE story file in commit
   - ADD all relevant modified files
   - ADD all relevant untracked files
   - EXCLUDE files from .gitignore
   - SKIP large files or sensitive files (with warning)

2. **CREATE** commit:
   - RUN: `git add [files]`
   - RUN: `git commit -m "[commit message]"`
   - CAPTURE commit hash
   - CAPTURE commit timestamp

3. **UPDATE** story file with commit hash:
   - ADD commit hash to latest progress log entry
   - FORMAT: `Commit: [hash]`

4. **VERIFY** commit succeeded:
   - RUN: `git log -1 --oneline`
   - CONFIRM commit appears in history

#### Phase 7: Commit Summary Display
1. **DISPLAY** comprehensive commit summary:
   ```
   ✅ CHANGES COMMITTED
   ════════════════════════════════════
   Commit: [hash]
   Type: [type]
   Scope: [scope]
   Message: [description]

   [If story exists:]
   Story: [STORY-ID] - [Story Title]

   Files Changed: [count]
   📄 Modified: [count]
   - [file1] ([+X/-Y lines])
   - [file2] ([+X/-Y lines])

   ➕ Added: [count]
   - [file3] ([+X lines])

   ➖ Deleted: [count]
   - [file4] ([X lines])

   Statistics:
   Lines Added: [count]
   Lines Removed: [count]

   💡 NEXT STEPS:
   1. /sdd:story-implement [story-id] - Continue development
   2. /sdd:story-review - Move to code review when ready
   3. git push - Push to remote when ready to share
   ```

### OUTPUTS
- Git commit with formatted conventional commit message
- Updated story file with progress log entry
- Commit statistics and file change summary
- Next action suggestions based on story status

### RULES
- MUST check for uncommitted changes before proceeding
- MUST determine appropriate commit type from changes
- MUST create properly formatted conventional commit message
- MUST update story file before committing (include in same commit)
- MUST warn about large files or potential secrets
- SHOULD auto-detect story context from branch name
- SHOULD provide meaningful auto-generated messages
- SHOULD include story context in commit body
- MUST NOT commit files that likely contain secrets
- MUST NOT proceed if no changes exist
- NEVER force push or amend commits without confirmation

## Examples

### Example 1: Feature Implementation Commit
```bash
INPUT:
/sdd:story-save

PROCESS:
→ Checking git status...
→ Found 5 modified files, 2 new files
→ Detecting story context...
→ Current branch: feature/STORY-AUTH-001-login-form
→ Story: STORY-AUTH-001 - Implement Login Form
→ Analyzing changes...
→ Detected commit type: feat
→ Generating commit message...
→ Updating story file...
→ Staging changes...
→ Creating commit...

OUTPUT:
✅ CHANGES COMMITTED
════════════════════════════════════
Commit: abc1234
Type: feat
Scope: auth
Message: implement login form with validation

Story: STORY-AUTH-001 - Implement Login Form

Files Changed: 7
📄 Modified: 5
- app/Livewire/Auth/LoginForm.php (+145/-0 lines)
- resources/views/livewire/auth/login-form.blade.php (+67/-0 lines)
- routes/web.php (+5/-0 lines)
- tests/Feature/Auth/LoginTest.php (+89/-0 lines)
- stories/development/STORY-AUTH-001.md (+8/-1 lines)

➕ Added: 2
- app/Http/Controllers/Auth/LoginController.php (+52 lines)
- tests/Browser/Auth/LoginFormTest.php (+43 lines)

Statistics:
Lines Added: 409
Lines Removed: 1

💡 NEXT STEPS:
1. /sdd:story-implement STORY-AUTH-001 - Continue development
2. /sdd:story-review - Move to code review when ready
3. git push - Push to remote when ready to share
```

### Example 2: Custom Commit Message
```bash
INPUT:
/sdd:story-save "add rate limiting to login endpoint"

PROCESS:
→ Checking git status...
→ Found 2 modified files
→ Using custom message: "add rate limiting to login endpoint"
→ Detecting story context...
→ Story: STORY-AUTH-001 - Implement Login Form
→ Analyzing changes...
→ Detected commit type: feat
→ Generating commit message...
→ Updating story file...
→ Creating commit...

OUTPUT:
✅ CHANGES COMMITTED
════════════════════════════════════
Commit: def5678
Type: feat
Scope: auth
Message: add rate limiting to login endpoint

Story: STORY-AUTH-001 - Implement Login Form

Changes:
- Added rate limiting middleware (5 attempts per minute)
- Updated login controller to use rate limiter
- Added rate limit exceeded error message

Files Changed: 2
📄 Modified: 2
- app/Http/Middleware/RateLimitLogin.php (+28/-0 lines)
- app/Livewire/Auth/LoginForm.php (+12/-3 lines)

Statistics:
Lines Added: 40
Lines Removed: 3

💡 NEXT STEPS:
1. /sdd:story-implement STORY-AUTH-001 - Continue development
2. /sdd:story-review - Move to code review when ready
3. git push - Push to remote when ready to share
```

### Example 3: Test Addition Commit
```bash
INPUT:
/sdd:story-save

PROCESS:
→ Checking git status...
→ Found 3 new files (all tests)
→ Detecting story context...
→ Story: STORY-PROFILE-002 - User Profile Settings
→ Analyzing changes...
→ Detected commit type: test
→ Generating commit message...
→ Updating story file (marking test checklist items complete)...
→ Creating commit...

OUTPUT:
✅ CHANGES COMMITTED
════════════════════════════════════
Commit: ghi9012
Type: test
Scope: profile
Message: add comprehensive unit and browser tests

Story: STORY-PROFILE-002 - User Profile Settings

Files Changed: 4
➕ Added: 3
- tests/Unit/ProfileSettingsTest.php (+76 lines)
- tests/Feature/ProfileUpdateTest.php (+92 lines)
- tests/Browser/ProfileSettingsTest.php (+58 lines)

📄 Modified: 1
- stories/development/STORY-PROFILE-002.md (+3/-3 lines)
  * Marked "Unit tests" as complete
  * Marked "Browser tests" as complete

Statistics:
Lines Added: 229
Lines Removed: 3

💡 NEXT STEPS:
1. /sdd:story-implement STORY-PROFILE-002 - Continue development
2. /sdd:story-review - Move to code review when ready
3. git push - Push to remote when ready to share
```

### Example 4: No Changes to Commit
```bash
INPUT:
/sdd:story-save

PROCESS:
→ Checking git status...
→ No uncommitted changes found

OUTPUT:
✅ WORKING TREE CLEAN
════════════════════════════════════

No changes to commit.

Current Status:
Branch: feature/STORY-AUTH-001-login-form
Story: STORY-AUTH-001 - Implement Login Form
Last Commit: abc1234 (2 hours ago)

💡 NEXT STEPS:
1. /sdd:story-implement STORY-AUTH-001 - Continue implementation
2. /sdd:story-review - Move to code review if complete
3. /sdd:story-continue - Resume work on story
```

### Example 5: Warning About Large Files
```bash
INPUT:
/sdd:story-save

PROCESS:
→ Checking git status...
→ Found 3 modified files, 1 large file
→ Warning: Large file detected

OUTPUT:
⚠️ LARGE FILE DETECTED
════════════════════════════════════

Found large file that may bloat repository:
- public/videos/demo.mp4 (12.5 MB)

Changes to commit:
📄 Modified: 2
- app/Livewire/VideoPlayer.php
- resources/views/livewire/video-player.blade.php

➕ Added: 1
- public/videos/demo.mp4 (12.5 MB) ⚠️

Recommendation:
Large files should be stored externally (S3, CDN) or
use Git LFS for version control.

Continue with commit? [y/n]
> n

Commit cancelled.

💡 SUGGESTIONS:
1. Move large files to external storage
2. Add to .gitignore if not needed in repository
3. Use Git LFS for large binary files
4. /sdd:story-save (retry after removing large files)
```

### Example 6: Fix Commit with Auto-Detection
```bash
INPUT:
/sdd:story-save

PROCESS:
→ Checking git status...
→ Found 2 modified files
→ Detecting story context...
→ Story: STORY-CART-003 - Shopping Cart Checkout
→ Analyzing changes...
→ Detected commit type: fix (error handling changes detected)
→ Generating commit message...
→ Creating commit...

OUTPUT:
✅ CHANGES COMMITTED
════════════════════════════════════
Commit: jkl3456
Type: fix
Scope: cart
Message: fix cart total calculation rounding error

Story: STORY-CART-003 - Shopping Cart Checkout

Changes:
- Fixed rounding error in cart total calculation
- Changed to use Decimal for currency calculations
- Updated tests to verify correct rounding

Files Changed: 2
📄 Modified: 2
- app/Services/CartService.php (+8/-4 lines)
- tests/Unit/CartServiceTest.php (+15/-2 lines)

Statistics:
Lines Added: 23
Lines Removed: 6

💡 NEXT STEPS:
1. /sdd:story-implement STORY-CART-003 - Continue development
2. /sdd:story-review - Move to code review when ready
3. git push - Push to remote when ready to share
```

## Edge Cases

### No Story Context Available
```
IF no story can be determined from branch or files:
- PROCEED with commit using generic scope
- USE directory name or "app" as scope
- SKIP story file update
- WARN: "No story context found - commit without story reference"
```

### Multiple Stories Detected
```
IF branch name doesn't match active story:
- WARN: "Branch name suggests [STORY-A] but active story is [STORY-B]"
- ASK: Which story should this commit be associated with?
- USE selected story for commit message and file update
```

### Untracked Story File
```
IF story file exists but is untracked:
- INCLUDE story file in commit
- NOTE: "Adding story file to repository"
- PROCEED with normal commit flow
```

### Commit Message Too Long
```
IF generated message exceeds 72 characters:
- TRUNCATE first line to 72 chars
- MOVE details to commit body
- ENSURE proper formatting
```

### Detached HEAD State
```
IF in detached HEAD state:
- WARN: "Currently in detached HEAD state"
- SHOW current commit
- SUGGEST: Create branch or checkout existing branch
- OFFER: Continue commit anyway? (y/n)
```

### Merge Conflicts Present
```
IF merge conflicts detected:
- HALT: "Cannot commit with unresolved merge conflicts"
- LIST conflicted files
- SUGGEST: Resolve conflicts first using git mergetool
- EXIT with error
```

## Error Handling
- **Not in git repository**: Return "Error: Not in a git repository. Run 'git init' first"
- **No changes to commit**: Show "Working tree clean" and exit gracefully
- **Git command fails**: Show git error and suggest manual resolution
- **Story file read error**: Warn and proceed without story context
- **Story file write error**: Show error but continue with commit (story update optional)
- **Large file detected**: Warn and ask for confirmation before proceeding
- **Sensitive file detected**: Warn strongly and require explicit confirmation

## Performance Considerations
- Use `git status --porcelain` for fast, parseable output
- Read only necessary parts of story file (don't parse everything)
- Cache story context within command execution
- Run git commands in sequence (they're fast enough)
- Skip expensive diff calculations for very large commits
- Use `git diff --stat` instead of full diff for summary

## Related Commands
- `/sdd:story-implement` - Generate implementation before saving
- `/sdd:story-continue` - Resume work before saving
- `/sdd:story-review` - Move to review after saving
- `/sdd:story-start` - Begin development before implementation
- `/sdd:project-status` - View all stories and their status

## Constraints
- ✅ MUST check for uncommitted changes
- ✅ MUST generate proper conventional commit message
- ✅ MUST update story file before committing
- ✅ MUST include story file in commit
- ⚠️ NEVER commit secrets or sensitive files without warning
- ⚠️ NEVER commit large files without confirmation
- 📋 SHOULD auto-detect commit type from changes
- 💡 SHOULD provide meaningful commit messages
- 🔧 SHOULD include story context in commit
- 💾 MUST verify commit succeeded before reporting success