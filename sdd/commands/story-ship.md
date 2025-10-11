# /story-ship

## Meta
- Version: 2.0
- Category: workflow
- Complexity: comprehensive
- Purpose: Ship validated story to production with deployment, validation, and cleanup

## Definition
**Purpose**: Deploy a QA-validated story to production by merging to main branch, creating releases, deploying to production environment, performing post-deployment validation, and completing story archival.

**Syntax**: `/story-ship <story_id> [--skip-tests] [--dry-run]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | Yes | - | Story identifier (e.g., "STORY-2025-001") | Must match pattern STORY-\d{4}-\d{3} |
| --skip-tests | flag | No | false | Skip running tests on merged code (not recommended) | Boolean flag |
| --dry-run | flag | No | false | Simulate deployment without executing | Boolean flag |

## INSTRUCTION: Ship Story to Production

### INPUTS
- story_id: Story identifier from /stories/qa/
- Story file with QA validation data
- Git repository with feature branch
- Project context from /project-context/

### PROCESS

#### Phase 1: Pre-Flight Checks
1. **VERIFY** story location:
   - CHECK story is in `/stories/qa/` directory
   - IF NOT in qa:
     - CHECK `/stories/review/` - suggest running `/story-qa` first
     - CHECK `/stories/development/` - suggest completing review and QA
     - EXIT with appropriate guidance

2. **VALIDATE** story readiness:
   - READ story file and verify:
     * ALL Success Criteria marked [x]
     * ALL Implementation Checklist items marked [x]
     * ALL QA Checklist items marked [x] (or marked N/A)
     * QA validation section completed
     * Test results documented
     * Performance benchmarks met
   - IF any required items unchecked:
     - DISPLAY incomplete items
     - OFFER to mark as complete if user confirms
     - EXIT if critical items missing

3. **CHECK** git status:
   - VERIFY on feature branch
   - ENSURE all changes committed
   - CHECK branch is up to date with remote
   - IF uncommitted changes exist:
     - DISPLAY uncommitted files
     - OFFER to commit with auto-generated message
     - EXIT if user declines

4. **RUN** pre-merge tests (unless --skip-tests):
   - Execute test suite on feature branch
   - VERIFY all tests pass
   - IF tests fail:
     - DISPLAY failed tests
     - SUGGEST fixing issues before shipping
     - EXIT and keep story in QA

5. **DISPLAY** pre-flight summary:
   ```
   ✈️ PRE-FLIGHT CHECK
   ═══════════════════

   Story: [STORY-ID] - [Title]
   Branch: [branch-name]
   Status: Ready for deployment

   ✅ Story in QA directory
   ✅ All checklists complete
   ✅ All changes committed
   ✅ Tests passing ([count] tests)
   ✅ QA validation complete

   Ready to ship to production.
   ```

#### Phase 2: Branch Merge
1. **LOAD** project context:
   - READ `/project-context/development-process.md` for merge strategy
   - IDENTIFY main branch name (main/master)
   - CHECK for branch protection rules

2. **SWITCH** to main branch:
   - RUN: `git checkout main` (or master)
   - PULL latest changes: `git pull origin main`
   - VERIFY clean state

3. **MERGE** feature branch:
   - ATTEMPT merge: `git merge --no-ff [branch-name]`
   - IF conflicts detected:
     - DISPLAY conflicting files
     - PROVIDE merge conflict resolution guide
     - OFFER interactive conflict resolution
     - VERIFY resolution with user
   - IF merge successful:
     - SHOW merge commit details
     - NOTE files changed and lines added/removed

4. **RUN** tests on merged code (unless --skip-tests):
   - Execute full test suite on main branch
   - VERIFY all tests still pass
   - IF tests fail after merge:
     - DISPLAY failed tests
     - OFFER to abort merge
     - SUGGEST investigating merge conflicts
     - EXIT if user chooses to abort

5. **DISPLAY** merge summary:
   ```
   🔀 MERGE COMPLETE
   ═════════════════

   Merged: [branch-name] → main
   Commit: [commit-hash]
   Files changed: [count]
   Tests: [count] passing
   ```

#### Phase 3: Release Creation
1. **DETERMINE** version strategy:
   - CHECK for existing version file (package.json, composer.json, etc.)
   - IF versioning used:
     - READ current version
     - SUGGEST next version (semantic versioning)
     - PROMPT user for version number
   - IF no versioning:
     - USE story ID as release identifier
     - CREATE date-based version: v[YYYY.MM.DD]

2. **GENERATE** changelog entry:
   - EXTRACT from story file:
     * Story title and description
     * Success criteria achieved
     * Technical changes made
     * Known issues or limitations
   - FORMAT as changelog entry with version

3. **CREATE** git tag:
   - IF versioning used:
     - CREATE annotated tag: `git tag -a v[version] -m "[Story title]"`
   - IF no versioning:
     - CREATE annotated tag: `git tag -a [story-id] -m "[Story title]"`
   - PUSH tag to remote: `git push origin --tags`

4. **UPDATE** version files (if applicable):
   - UPDATE package.json, composer.json, etc.
   - COMMIT version bump
   - PUSH to remote

5. **DISPLAY** release summary:
   ```
   📦 RELEASE CREATED
   ══════════════════

   Version: [version]
   Tag: v[version]
   Story: [STORY-ID]
   Date: [YYYY-MM-DD]

   Changelog entry created
   Version files updated
   ```

#### Phase 4: Production Deployment
1. **DETECT** deployment configuration:
   - CHECK for deployment scripts in project
   - COMMON locations:
     * `scripts/deploy.sh`
     * `.github/workflows/deploy.yml`
     * `composer deploy` / `npm run deploy`
     * `deployer.phar`
   - READ `/project-context/technical-stack.md` for deployment method

2. **EXECUTE** deployment (unless --dry-run):
   - IF automated deployment configured:
     - RUN deployment command
     - STREAM output to user
     - TRACK deployment progress
   - IF no automation:
     - PROVIDE manual deployment instructions
     - CHECKLIST deployment steps
     - WAIT for user confirmation

3. **MONITOR** deployment:
   - WATCH for deployment completion
   - TRACK any errors or warnings
   - LOG deployment output
   - IF deployment fails:
     - CAPTURE error details
     - SUGGEST rollback
     - EXIT to Phase 9 (Rollback Handling)

4. **DISPLAY** deployment status:
   ```
   🚀 DEPLOYING TO PRODUCTION
   ═══════════════════════════

   Environment: production
   Version: [version]
   Method: [deployment-method]

   [Real-time deployment output...]

   ✅ Deployment successful
   ```

#### Phase 5: Post-Deployment Validation
1. **RUN** smoke tests:
   - LOAD test configuration from project context
   - EXECUTE critical path tests:
     * Homepage loads
     * Authentication works
     * Core features functional
     * APIs responding
   - IF smoke tests fail:
     - CAPTURE test failures
     - SUGGEST immediate rollback
     - EXIT to Phase 9 (Rollback Handling)

2. **CHECK** application health:
   - VERIFY application is running
   - CHECK health endpoints (if available)
   - VALIDATE database connectivity
   - CONFIRM cache is functioning
   - TEST key integrations

3. **MONITOR** initial metrics:
   - CHECK error rates (first 5 minutes)
   - VERIFY response times
   - WATCH for exceptions/crashes
   - MONITOR resource usage
   - IF metrics anomalous:
     - ALERT user to issues
     - SUGGEST monitoring plan
     - OFFER rollback option

4. **VALIDATE** story-specific functionality:
   - TEST features from Success Criteria
   - VERIFY changes are live
   - CHECK user-facing improvements
   - VALIDATE data integrity
   - TEST critical user paths

5. **DISPLAY** validation results:
   ```
   ✅ POST-DEPLOYMENT VALIDATION
   ═════════════════════════════

   Smoke Tests: [X/Y] passed
   Health Checks: All systems operational
   Metrics: Within normal ranges
   Story Features: Validated and live

   Application healthy and ready for users.
   ```

#### Phase 6: Story Completion
1. **VERIFY** all checklists one final time:
   - CHECK all Success Criteria marked [x]
   - CHECK all Implementation items marked [x]
   - CHECK all QA items marked [x]
   - IF any unchecked:
     - MARK as complete with timestamp
     - NOTE completion in progress log

2. **UPDATE** story file:
   - SET status to "complete"
   - ADD completion date: today's date
   - ADD deployment information:
     * Deployed version
     * Deployment timestamp
     * Production environment
   - ADD progress log entry: "Shipped to production - [timestamp]"
   - RECORD final metrics:
     * Total development time
     * Total commits
     * Final test coverage

3. **ENSURE** completed directory exists:
   - CREATE `/stories/completed/` if missing
   - ADD `.gitkeep` if directory created

4. **MOVE** story file:
   - FROM: `/stories/qa/[story-id].md`
   - TO: `/stories/completed/[story-id].md`
   - VERIFY move successful

5. **COMMIT** story completion:
   - ADD moved file to git
   - COMMIT with message: "chore: ship [story-id] to production"
   - PUSH to main branch

#### Phase 7: Release Notes Generation
1. **COMPILE** release notes:
   - EXTRACT from story file:
     * What's New (user-facing changes)
     * Technical Changes (developer-facing)
     * Bug Fixes (if applicable)
     * Known Issues or Limitations
     * Upgrade Instructions (if needed)

2. **FORMAT** release notes:
   ```
   📦 RELEASE NOTES
   ════════════════
   Version: [version]
   Date: [YYYY-MM-DD]
   Story: [STORY-ID] - [Title]

   WHAT'S NEW:
   - [User-facing feature 1]
   - [User-facing feature 2]
   - [User-facing improvement 3]

   TECHNICAL CHANGES:
   - [Implementation detail 1]
   - [API change 2]
   - [Database migration 3]
   - [Configuration change 4]

   BUG FIXES:
   - [Bug fix 1]
   - [Bug fix 2]

   KNOWN ISSUES:
   - [Limitation 1]
   - [Known issue 2]

   UPGRADE NOTES:
   - [Special instruction 1]
   - [Migration step 2]

   ROLLBACK PLAN:
   See story file for detailed rollback procedure.
   ```

3. **PUBLISH** release notes:
   - ADD to `CHANGELOG.md` (if exists)
   - CREATE GitHub release (if using GitHub)
   - UPDATE documentation site (if applicable)
   - NOTIFY team/stakeholders (if configured)

#### Phase 8: Documentation and Cleanup
1. **UPDATE** documentation:
   - ADD features to README (if user-facing)
   - UPDATE API documentation (if API changes)
   - REFRESH user guides (if workflows changed)
   - UPDATE architecture docs (if structure changed)

2. **CLEAN UP** branches:
   - DELETE local feature branch: `git branch -d [branch-name]`
   - DELETE remote feature branch: `git push origin --delete [branch-name]`
   - VERIFY branches deleted
   - KEEP main branch clean

3. **ARCHIVE** temporary files:
   - REMOVE build artifacts
   - CLEAN up test recordings (unless needed)
   - COMPRESS large logs
   - REMOVE temporary screenshots

4. **VERIFY** repository state:
   - CHECK git status is clean
   - ENSURE on main branch
   - VERIFY all changes pushed
   - CONFIRM no uncommitted files

5. **UPDATE** project tracking:
   - MARK story complete in project board (if applicable)
   - UPDATE story count in metrics
   - RECORD deployment in tracking system
   - NOTIFY relevant stakeholders

#### Phase 9: Success Summary (or Rollback Handling)
1. **IF** deployment successful:
   - **GENERATE** success summary:
     ```
     🚀 SUCCESSFULLY SHIPPED!
     ════════════════════════
     Story: [STORY-ID] - [Title]

     DEPLOYMENT:
     • Environment: production
     • Version: [version]
     • Deployed: [timestamp]
     • Duration: [development time]

     VALIDATION:
     • Smoke tests: ✅ Passed
     • Health checks: ✅ Operational
     • Metrics: ✅ Normal
     • Features: ✅ Live

     MONITORING:
     • Application logs: [link or command]
     • Error tracking: [link or command]
     • Performance dashboard: [link]

     ROLLBACK PLAN:
     Available in story file at:
     /stories/completed/[story-id].md

     NEXT STEPS:
     1. Monitor application for 24 hours
     2. Watch for user feedback and issues
     3. Review metrics and performance
     4. Run /story-complete [story-id] to archive with learnings
     5. Celebrate the successful deployment! 🎉

     SUGGESTED MONITORING PERIOD:
     • First hour: Active monitoring
     • First 24 hours: Regular checks
     • First week: Periodic validation
     ```

2. **IF** deployment failed or validation failed:
   - **CAPTURE** failure details
   - **DISPLAY** error information
   - **SUGGEST** rollback:
     ```
     ❌ DEPLOYMENT FAILED
     ════════════════════
     Story: [STORY-ID] - [Title]

     FAILURE DETAILS:
     • Phase: [deployment/validation]
     • Error: [error-message]
     • Timestamp: [timestamp]

     CURRENT STATE:
     • Code: Merged to main
     • Deployment: Failed or unstable
     • Story: Kept in QA directory

     RECOMMENDED ACTION:
     /story-rollback [story-id]

     This will:
     1. Revert the merge commit
     2. Remove the release tag
     3. Rollback deployment (if possible)
     4. Move story back to appropriate stage

     Do you want to rollback now? (y/n)
     ```
   - **IF** user confirms rollback:
     - EXECUTE `/story-rollback` command
     - EXIT with rollback results
   - **IF** user declines:
     - KEEP story in QA
     - LOG incident in story file
     - EXIT with manual resolution guidance

### OUTPUTS
- `/stories/completed/[story-id].md` - Completed story with deployment data
- Git merge commit on main branch
- Git release tag (v[version] or [story-id])
- Updated CHANGELOG.md (if exists)
- Release notes (displayed and optionally published)
- Deleted feature branch (local and remote)
- Clean repository state

### RULES
- MUST verify story is in `/stories/qa/` before proceeding
- MUST validate all checklists complete (or prompt user)
- MUST run tests on merged code (unless --skip-tests)
- MUST create release tag for traceability
- MUST perform post-deployment validation
- MUST move story to `/stories/completed/` on success
- MUST cleanup feature branches after successful merge
- SHOULD generate comprehensive release notes
- SHOULD update relevant documentation
- NEVER force push to main branch
- ALWAYS provide rollback option on failure
- MUST commit story move with descriptive message
- MUST push all changes to remote repository

## Examples

### Example 1: Successful Deployment
```bash
INPUT:
/story-ship STORY-2025-001

PROCESS:
→ Pre-flight checks...
→ Story: STORY-2025-001 in /stories/qa/
→ Validating checklists... ✅
→ Checking git status... ✅
→ Running tests... ✅ (156 tests passed)

→ Switching to main branch...
→ Merging feature/auth-001-login-form...
→ Merge successful - 12 files changed
→ Running tests on merged code... ✅

→ Creating release...
→ Version: v1.1.0
→ Tag created: v1.1.0
→ Changelog updated

→ Deploying to production...
→ Running: composer deploy
→ [deployment output...]
→ Deployment successful ✅

→ Post-deployment validation...
→ Smoke tests: 8/8 passed ✅
→ Health checks: All operational ✅
→ Metrics: Normal ✅

→ Completing story...
→ Moving to /stories/completed/STORY-2025-001.md
→ Cleaning up feature branch...
→ Generating release notes...

OUTPUT:
🚀 SUCCESSFULLY SHIPPED!
════════════════════════
Story: STORY-2025-001 - User Authentication System

DEPLOYMENT:
• Environment: production
• Version: v1.1.0
• Deployed: 2025-03-15 14:32:18 UTC
• Duration: 9 working days

VALIDATION:
• Smoke tests: ✅ Passed (8/8)
• Health checks: ✅ Operational
• Metrics: ✅ Normal
• Features: ✅ Live

MONITORING:
• Application logs: php artisan pail
• Error tracking: Check Sentry dashboard
• Performance: Watch response times

ROLLBACK PLAN:
Available in story file at:
/stories/completed/STORY-2025-001.md

NEXT STEPS:
1. Monitor application for 24 hours
2. Watch for user feedback and issues
3. Review metrics and performance
4. Run /story-complete STORY-2025-001 to archive
5. Celebrate the successful deployment! 🎉

📦 RELEASE NOTES
════════════════
Version: v1.1.0
Date: 2025-03-15
Story: STORY-2025-001 - User Authentication System

WHAT'S NEW:
- User registration with email verification
- Secure login with session management
- Password reset functionality
- Remember me option for convenience

TECHNICAL CHANGES:
- Added AuthMiddleware for route protection
- Implemented JWT token handling
- Created authentication test suite
- Added password hashing with bcrypt

ROLLBACK PLAN:
See /stories/completed/STORY-2025-001.md
```

### Example 2: Deployment with Manual Steps
```bash
INPUT:
/story-ship STORY-2025-002

PROCESS:
→ Pre-flight checks... ✅
→ Merging to main... ✅
→ Creating release v1.2.0... ✅

→ Detecting deployment configuration...
→ No automated deployment found

OUTPUT:
📋 MANUAL DEPLOYMENT REQUIRED
══════════════════════════════

Story: STORY-2025-002 - Profile Management
Version: v1.2.0

Please complete the following deployment steps:

1. [ ] SSH into production server
2. [ ] Pull latest changes: git pull origin main
3. [ ] Install dependencies: composer install --no-dev
4. [ ] Run migrations: php artisan migrate --force
5. [ ] Clear caches: php artisan cache:clear
6. [ ] Restart services: sudo systemctl restart php-fpm
7. [ ] Verify application is running

Have you completed all deployment steps? (y/n)
> y

→ Running post-deployment validation...
→ Smoke tests: 10/10 passed ✅
→ Completing story...

[Success summary displayed]
```

### Example 3: Deployment Failure with Rollback
```bash
INPUT:
/story-ship STORY-2025-003

PROCESS:
→ Pre-flight checks... ✅
→ Merging to main... ✅
→ Creating release v1.3.0... ✅
→ Deploying to production...
→ Error: Database migration failed

OUTPUT:
❌ DEPLOYMENT FAILED
════════════════════
Story: STORY-2025-003 - Payment Integration

FAILURE DETAILS:
• Phase: deployment
• Error: Database migration "add_payment_columns" failed
• Timestamp: 2025-03-16 10:15:42 UTC
• Exit code: 1

ERROR MESSAGE:
SQLSTATE[42S21]: Column already exists: 1060 Duplicate column name 'payment_status'

CURRENT STATE:
• Code: Merged to main (commit abc123)
• Deployment: Failed during migrations
• Story: Kept in QA directory

RECOMMENDED ACTION:
/story-rollback STORY-2025-003

This will:
1. Revert the merge commit
2. Remove the release tag v1.3.0
3. Rollback deployment (revert to v1.2.0)
4. Move story back to QA for fixes

Do you want to rollback now? (y/n)
> y

→ Executing rollback...
[Rollback process initiated]
```

### Example 4: Dry Run
```bash
INPUT:
/story-ship STORY-2025-004 --dry-run

PROCESS:
→ DRY RUN MODE - No changes will be made
→ Pre-flight checks... ✅
→ Would merge feature/notifications to main
→ Would create release v1.4.0
→ Would deploy to production
→ Would run post-deployment validation
→ Would move story to completed

OUTPUT:
🔍 DRY RUN COMPLETE
═══════════════════

Story: STORY-2025-004 - Push Notifications

SIMULATED ACTIONS:
✓ Merge feature/notifications → main
✓ Create release tag v1.4.0
✓ Deploy to production
✓ Run smoke tests
✓ Move to /stories/completed/
✓ Delete feature branch

ESTIMATED DURATION: ~5 minutes

No actual changes were made.
Run without --dry-run to execute deployment.
```

## Edge Cases

### Incomplete Checklists
- DETECT unchecked Success Criteria or Implementation items
- DISPLAY incomplete items with context
- OFFER to mark as complete if user confirms
- WARN about shipping with incomplete items
- EXIT if critical items missing (user decides what's critical)

### Merge Conflicts
- DETECT conflicts during merge
- DISPLAY conflicting files and conflict markers
- PROVIDE merge conflict resolution guide
- OFFER interactive conflict resolution
- VERIFY resolution with user before continuing
- RE-RUN tests after conflict resolution

### Failed Tests After Merge
- CAPTURE test failures on merged code
- DISPLAY failed test details
- SUGGEST investigating merge-related issues
- OFFER to abort merge and reset
- KEEP story in QA if merge aborted
- LOG incident in story progress log

### Deployment Timeout
- MONITOR deployment progress
- DETECT if deployment hangs or times out
- PROVIDE option to continue waiting or abort
- LOG timeout incident
- SUGGEST checking deployment logs manually
- OFFER rollback option

### Failed Smoke Tests
- CAPTURE smoke test failures
- DISPLAY which tests failed and why
- ASSESS severity of failures
- OFFER immediate rollback for critical failures
- ALLOW user to investigate for non-critical failures
- LOG post-deployment issues in story file

### No Version Management
- DETECT absence of version files
- USE story ID as release identifier
- CREATE date-based version as alternative
- SUGGEST implementing semantic versioning
- CONTINUE with story-based releases

## Error Handling
- **Story ID missing**: Return "Error: Story ID required. Usage: /story-ship <story_id>"
- **Invalid story ID format**: Return "Error: Invalid story ID format. Expected: STORY-YYYY-NNN"
- **Story not in QA**: Report current location and suggest appropriate next step
- **Uncommitted changes**: Display files and offer to commit or exit
- **Test failures**: Display failures, offer to fix or abort
- **Merge conflicts**: Provide resolution guide and interactive help
- **Deployment failure**: Capture details, suggest rollback, log incident
- **Validation failure**: Assess severity, offer rollback for critical issues
- **Git errors**: Display error, suggest manual resolution, provide recovery steps

## Performance Considerations
- Run tests in parallel when possible
- Stream deployment output in real-time
- Cache git operations during session
- Perform post-deployment validation concurrently
- Generate release notes asynchronously
- Cleanup branches in background after success

## Related Commands
- `/story-qa` - Move story to QA before shipping
- `/story-rollback` - Rollback failed deployment
- `/story-complete` - Archive story after successful deployment
- `/story-validate` - Run final validation before shipping
- `/project-status` - View all project stories

## Constraints
- ✅ MUST verify story in QA directory
- ✅ MUST validate checklists complete
- ✅ MUST run tests on merged code
- 🔀 MUST merge to main branch (no fast-forward)
- 🏷️ MUST create release tag
- 🚀 MUST deploy to production environment
- ✔️ MUST perform post-deployment validation
- 📝 MUST generate release notes
- 🧹 MUST cleanup feature branches
- 💾 MUST move story to completed on success
- 🚫 NEVER force push to main
- ↩️ ALWAYS provide rollback option on failure
- 📊 MUST update story with deployment data