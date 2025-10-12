# /sdd:story-rollback

## Meta
- Version: 2.0
- Category: workflow
- Complexity: comprehensive
- Purpose: Critical rollback procedure for failed deployments or production issues

## Definition
**Purpose**: Execute comprehensive rollback procedure for a deployed story experiencing critical issues in production. Revert code changes, database migrations, configuration, and restore system stability.

**Syntax**: `/sdd:story-rollback <story_id> [--severity=critical|high|medium] [--rollback-type=full|code|database|config]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | Yes | - | Story identifier (e.g., "STORY-2025-001") | Must match pattern STORY-\d{4}-\d{3} |
| --severity | enum | No | high | Issue severity level | critical, high, medium, low |
| --rollback-type | enum | No | full | Type of rollback to perform | full, code, database, config, partial |

## INSTRUCTION: Execute Critical Rollback

### INPUTS
- story_id: Story identifier (usually in /docs/stories/completed/ or /docs/stories/qa/)
- Issue severity and scope
- Rollback plan from story file
- Project context from /docs/project-context/

### PROCESS

#### Phase 1: Story Location and Context
1. **LOCATE** story file:
   - SEARCH `/docs/stories/completed/[story-id].md` first
   - IF NOT FOUND: CHECK `/docs/stories/qa/[story-id].md`
   - IF NOT FOUND: CHECK `/docs/stories/review/[story-id].md`
   - IF NOT FOUND: CHECK `/docs/stories/development/[story-id].md`
   - IF STORY NOT FOUND:
     - EXIT with error message
     - SUGGEST checking story ID

2. **READ** story file and extract:
   - Rollback plan section (if documented)
   - Deployment version/tag
   - Database migrations applied
   - Configuration changes made
   - Dependencies and integrations affected
   - Technical changes summary

3. **IDENTIFY** deployment details:
   - GET current git tag/commit
   - GET previous stable tag/commit
   - IDENTIFY files changed
   - NOTE database migrations run
   - LIST configuration changes

4. **DISPLAY** context:
   ```
   📋 ROLLBACK CONTEXT
   ═══════════════════

   Story: [STORY-ID] - [Title]
   Current Location: /docs/stories/[directory]/
   Deployed Version: [version]
   Previous Version: [previous-version]
   Deployment Time: [timestamp]
   Time Since Deploy: [duration]

   Changes Made:
   - Code: [X] files changed
   - Database: [Y] migrations applied
   - Config: [Z] changes
   - Dependencies: [list]
   ```

#### Phase 2: Situation Assessment
1. **PROMPT** user for incident details (if not provided):
   - What is the issue?
   - How many users are affected?
   - What features are broken?
   - Is there data corruption risk?
   - What is the business impact?

2. **ASSESS** severity (use --severity if provided):
   - **CRITICAL**: Data loss, security breach, complete outage
   - **HIGH**: Major features broken, many users affected
   - **MEDIUM**: Some features degraded, limited user impact
   - **LOW**: Minor issues, cosmetic problems

3. **DETERMINE** rollback strategy:
   - **FULL ROLLBACK**: Revert all changes (code + database + config)
   - **CODE ONLY**: Revert code, keep database changes
   - **DATABASE ONLY**: Rollback migrations, keep code
   - **CONFIG ONLY**: Revert configuration changes
   - **PARTIAL**: Selective rollback of specific changes
   - **HOTFIX**: Fix forward instead of rolling back

4. **GENERATE** assessment report:
   ```
   🚨 ROLLBACK ASSESSMENT
   ══════════════════════

   Severity: [CRITICAL/HIGH/MEDIUM/LOW]

   IMPACT:
   - Users affected: [estimate or percentage]
   - Features broken: [list of broken features]
   - Data corruption risk: [YES/NO - details]
   - Revenue impact: [description if applicable]
   - SLA breach: [YES/NO]

   ROOT CAUSE:
   - [Identified or suspected issue]
   - [Contributing factors]

   ROLLBACK OPTIONS:
   1. ✅ Full rollback to v[previous] (RECOMMENDED)
      - Reverts all changes
      - Restores known stable state
      - Requires database rollback
      - ETA: [X] minutes

   2. Code-only rollback
      - Keeps database changes
      - Faster rollback
      - May cause compatibility issues
      - ETA: [Y] minutes

   3. Hotfix forward
      - Fix specific issue
      - No rollback needed
      - Takes longer to implement
      - ETA: [Z] minutes

   4. Partial rollback
      - Revert specific changes
      - Keep working features
      - Complex to execute
      - ETA: [W] minutes

   RECOMMENDATION: [Strategy based on severity and impact]
   ```

5. **CONFIRM** rollback decision:
   - DISPLAY assessment
   - PROMPT user to confirm strategy
   - WARN about consequences
   - REQUIRE explicit confirmation for critical operations

#### Phase 3: Pre-Rollback Backup
1. **CREATE** safety backup:
   - BACKUP current database state
   - SNAPSHOT current code state (git commit)
   - SAVE current configuration
   - ARCHIVE application logs
   - RECORD current metrics

2. **DOCUMENT** rollback start:
   - TIMESTAMP rollback initiation
   - LOG user who initiated
   - RECORD rollback strategy
   - NOTE current application state

3. **NOTIFY** stakeholders (if configured):
   - ALERT that rollback is starting
   - PROVIDE expected downtime
   - SHARE rollback progress channel

4. **DISPLAY** backup confirmation:
   ```
   💾 PRE-ROLLBACK BACKUP
   ══════════════════════

   ✅ Database backed up: [location]
   ✅ Code state saved: [commit-hash]
   ✅ Configuration saved: [location]
   ✅ Logs archived: [location]
   ✅ Metrics captured: [timestamp]

   Safe to proceed with rollback.
   ```

#### Phase 4: Code Rollback
1. **VERIFY** current branch:
   - CHECK on main branch
   - PULL latest changes
   - CONFIRM clean working directory

2. **IDENTIFY** rollback target:
   - GET previous stable tag: `git describe --tags --abbrev=0 [current-tag]^`
   - OR: USE previous commit from story history
   - VERIFY target commit exists

3. **EXECUTE** code rollback:
   - IF full rollback:
     - REVERT merge commit: `git revert -m 1 [merge-commit]`
   - IF selective rollback:
     - REVERT specific commits
   - PUSH revert to remote: `git push origin main`

4. **REMOVE** problematic release tag:
   - DELETE local tag: `git tag -d [current-tag]`
   - DELETE remote tag: `git push origin --delete [current-tag]`

5. **DISPLAY** code rollback status:
   ```
   ↩️ CODE ROLLBACK
   ════════════════

   ✅ Reverted to: v[previous-version]
   ✅ Revert commit: [commit-hash]
   ✅ Tag removed: [current-tag]
   ✅ Changes pushed to remote

   Files reverted: [count]
   ```

#### Phase 5: Database Rollback
1. **IDENTIFY** migrations to rollback:
   - GET migrations applied in story
   - LIST from most recent to oldest
   - CHECK for data loss risk

2. **WARN** about data loss:
   - IF migrations drop columns/tables:
     - DISPLAY data loss warning
     - REQUIRE explicit confirmation
     - SUGGEST data export if needed

3. **EXECUTE** database rollback:
   - IF Laravel project:
     - RUN: `php artisan migrate:rollback --step=[count]`
   - IF Django project:
     - RUN: `python manage.py migrate [app] [previous-migration]`
   - IF Rails project:
     - RUN: `rails db:rollback STEP=[count]`
   - IF custom migrations:
     - EXECUTE rollback scripts from story

4. **VERIFY** database state:
   - CHECK migration status
   - VALIDATE schema integrity
   - TEST database connectivity
   - VERIFY data integrity

5. **DISPLAY** database rollback status:
   ```
   🗄️ DATABASE ROLLBACK
   ═══════════════════

   ✅ Migrations rolled back: [count]
   ✅ Schema restored to: [previous state]
   ✅ Data integrity: Verified
   ⚠️ Data loss: [description if any]

   Migrations reversed:
   - [migration-1]
   - [migration-2]
   - [migration-3]
   ```

#### Phase 6: Configuration Rollback
1. **IDENTIFY** configuration changes:
   - ENV variables modified
   - Config files changed
   - Feature flags toggled
   - API keys rotated
   - Service endpoints updated

2. **REVERT** configuration:
   - RESTORE previous ENV variables
   - REVERT config files from git
   - DISABLE feature flags
   - RESTORE previous API credentials
   - RESET service endpoints

3. **CLEAR** application caches:
   - IF Laravel: `php artisan cache:clear && php artisan config:clear`
   - IF Node.js: Clear Redis/Memcached
   - IF Django: `python manage.py clear_cache`
   - Clear CDN caches if applicable

4. **RESTART** application services:
   - RESTART web servers
   - RESTART queue workers
   - RESTART cache services
   - RESTART background jobs

5. **DISPLAY** configuration rollback status:
   ```
   ⚙️ CONFIGURATION ROLLBACK
   ════════════════════════

   ✅ ENV variables: Restored
   ✅ Config files: Reverted
   ✅ Feature flags: Disabled
   ✅ Caches: Cleared
   ✅ Services: Restarted

   Changes reverted:
   - [config-change-1]
   - [config-change-2]
   ```

#### Phase 7: Deployment Rollback
1. **DETECT** deployment system:
   - CHECK for deployment scripts
   - IDENTIFY deployment platform
   - READ `/docs/project-context/technical-stack.md`

2. **EXECUTE** deployment rollback:
   - IF automated deployment:
     - RUN deployment script with previous version
     - MONITOR deployment progress
   - IF manual deployment:
     - PROVIDE rollback instructions
     - CHECKLIST rollback steps
     - WAIT for user confirmation

3. **VERIFY** deployment:
   - CHECK application is running
   - VERIFY correct version deployed
   - VALIDATE services started
   - CONFIRM endpoints responding

4. **DISPLAY** deployment status:
   ```
   🚀 DEPLOYMENT ROLLBACK
   ══════════════════════

   ✅ Deployed: v[previous-version]
   ✅ Application: Running
   ✅ Services: Operational
   ✅ Endpoints: Responding

   Deployment method: [method]
   Rollback duration: [X] minutes
   ```

#### Phase 8: Verification and Validation
1. **RUN** smoke tests:
   - TEST homepage loads
   - VERIFY authentication works
   - CHECK core features functional
   - VALIDATE APIs responding
   - TEST critical user paths

2. **CHECK** application health:
   - VERIFY health endpoints
   - CHECK error rates
   - MONITOR response times
   - VALIDATE resource usage
   - CONFIRM database connectivity

3. **VERIFY** issue resolved:
   - TEST specific issue that caused rollback
   - CONFIRM users can access application
   - CHECK reported errors are gone
   - VALIDATE metrics are normal

4. **MONITOR** stability:
   - WATCH for 10 minutes minimum
   - CHECK for new errors
   - MONITOR user activity
   - TRACK key metrics

5. **DISPLAY** verification results:
   ```
   ✅ ROLLBACK VERIFICATION
   ════════════════════════

   Smoke Tests: [X/Y] passed
   Health Checks: All operational
   Error Rates: Normal (< threshold)
   Response Times: Normal
   Resource Usage: Normal

   Original Issue: ✅ RESOLVED
   Application Status: ✅ STABLE

   Safe to restore user access.
   ```

#### Phase 9: Post-Rollback Actions
1. **COMPLETE** post-rollback checklist:
   ```
   📋 POST-ROLLBACK CHECKLIST
   ══════════════════════════

   □ Production stable and verified
   □ Users notified of restoration
   □ Monitoring shows normal metrics
   □ No data loss confirmed
   □ Incident documented
   □ Team notified
   □ Stakeholders updated
   ```

2. **NOTIFY** users (if applicable):
   - ANNOUNCE service restored
   - APOLOGIZE for disruption
   - PROVIDE incident summary
   - SHARE preventive measures

3. **UPDATE** monitoring:
   - RESET alerting thresholds
   - RESUME normal monitoring
   - WATCH for residual issues
   - TRACK recovery metrics

#### Phase 10: Incident Documentation
1. **CREATE** incident report:
   ```
   📊 INCIDENT REPORT
   ══════════════════
   Story: [STORY-ID] - [Title]
   Incident ID: INC-[YYYY-MM-DD]-[number]

   TIMELINE:
   - Deployed: [timestamp]
   - Issue detected: [timestamp]
   - Rollback started: [timestamp]
   - Rollback completed: [timestamp]
   - Service restored: [timestamp]
   - Total duration: [X] minutes

   WHAT HAPPENED:
   [Detailed description of the issue that occurred]

   IMPACT:
   - Users affected: [estimate/percentage]
   - Features broken: [list]
   - Data loss: [YES/NO - details]
   - Business impact: [description]
   - Revenue impact: [if applicable]
   - SLA impact: [if applicable]

   ROOT CAUSE:
   - Primary: [Technical cause]
   - Contributing factors: [list]
   - Detection: [How issue was found]

   RESOLUTION:
   - Action taken: [Rollback strategy used]
   - Code: Reverted to v[previous]
   - Database: [Migrations rolled back or kept]
   - Configuration: [Changes reverted]
   - Verification: [How stability confirmed]

   LESSONS LEARNED:
   - What worked well: [list]
   - What didn't work: [list]
   - Gaps identified: [list]
   - Preventive measures: [list]

   ACTION ITEMS:
   - [ ] [Preventive measure 1]
   - [ ] [Preventive measure 2]
   - [ ] [Testing improvement 1]
   - [ ] [Monitoring enhancement 1]
   - [ ] [Process update 1]

   FOLLOW-UP STORY:
   Create fix story: /sdd:story-new [story-id-for-fix]
   Link to incident: INC-[YYYY-MM-DD]-[number]
   ```

2. **ADD** incident to story file:
   - APPEND incident report to story
   - UPDATE lessons learned section
   - NOTE what needs fixing
   - MARK story as requiring fixes

#### Phase 11: Story Status Update
1. **DETERMINE** story destination:
   - IF issue needs code fixes: Move to `/docs/stories/development/`
   - IF issue needs testing: Move to `/docs/stories/qa/`
   - IF minor tweaks needed: Keep in `/docs/stories/review/`
   - IF investigation needed: Move to `/docs/stories/development/`

2. **ENSURE** target directory exists:
   - CREATE directory if missing
   - ADD `.gitkeep` if directory created

3. **MOVE** story file:
   - FROM: Current location (usually `/docs/stories/completed/`)
   - TO: Appropriate stage directory
   - VERIFY move successful

4. **UPDATE** story file:
   - CHANGE status to appropriate stage
   - ADD rollback incident to progress log
   - UPDATE lessons learned with incident findings
   - CREATE action items for fixes
   - NOTE what caused the rollback

5. **COMMIT** story move:
   - ADD moved file to git
   - COMMIT with message: "rollback: revert [story-id] due to [issue]"
   - PUSH to repository

#### Phase 12: Fix Story Creation
1. **PROMPT** user to create fix story:
   ```
   Do you want to create a fix story now? (y/n)
   ```

2. **IF** user confirms:
   - GENERATE new story ID
   - CREATE fix story file
   - LINK to original story and incident
   - INCLUDE incident details
   - ADD root cause analysis
   - SET high priority
   - POPULATE with fix requirements

3. **DISPLAY** fix story details:
   ```
   📝 FIX STORY CREATED
   ════════════════════

   Story ID: [FIX-STORY-ID]
   Title: Fix [Original Story] - [Issue Description]
   Priority: HIGH
   Location: /docs/stories/backlog/[fix-story-id].md

   Linked to:
   - Original: [STORY-ID]
   - Incident: INC-[YYYY-MM-DD]-[number]

   Next steps:
   1. Review incident report
   2. Investigate root cause
   3. /sdd:story-start [fix-story-id]
   4. Implement fix with additional testing
   5. /sdd:story-ship [fix-story-id] (with caution)
   ```

#### Phase 13: Final Summary
1. **GENERATE** rollback summary:
   ```
   ✅ ROLLBACK COMPLETE
   ════════════════════
   Story: [STORY-ID] - [Title]

   ROLLBACK SUMMARY:
   • Strategy: [Full/Partial/Code-only/etc.]
   • Duration: [X] minutes
   • Version: Reverted from v[current] to v[previous]
   • Impact: [Users affected during rollback]

   ACTIONS TAKEN:
   ✅ Code reverted to v[previous]
   ✅ Database rolled back ([X] migrations)
   ✅ Configuration restored
   ✅ Application redeployed
   ✅ Smoke tests passed
   ✅ Production stable

   CURRENT STATE:
   • Application: ✅ Running v[previous]
   • Health: ✅ All systems operational
   • Users: ✅ Full access restored
   • Monitoring: ✅ Normal metrics
   • Story: Moved to /docs/stories/[directory]/

   INCIDENT REPORT:
   Created: INC-[YYYY-MM-DD]-[number]
   Location: [story-file-path]

   FIX STORY:
   Created: [FIX-STORY-ID] (if created)
   Priority: HIGH
   Location: /docs/stories/backlog/[fix-story-id].md

   NEXT STEPS:
   1. Continue monitoring for 24 hours
   2. Review incident report with team
   3. Implement action items
   4. Start work on fix story: /sdd:story-start [fix-story-id]
   5. Add additional testing to prevent recurrence
   6. Update rollback procedures if needed

   POST-MORTEM:
   Schedule incident review meeting within 48 hours
   to discuss root cause and preventive measures.
   ```

### OUTPUTS
- Reverted git commits on main branch
- Deleted problematic release tag
- Rolled back database migrations (if applicable)
- Restored configuration files
- Moved story file to appropriate stage
- Incident report in story file
- Fix story (if created)
- Clean, stable production environment

### RULES
- MUST locate story file before proceeding
- MUST assess severity and impact
- MUST create pre-rollback backup
- MUST confirm rollback strategy with user
- MUST revert code changes
- MUST rollback database if needed (with data loss warning)
- MUST restore configuration
- MUST verify application stability after rollback
- MUST complete post-rollback checklist
- MUST document incident comprehensively
- MUST update story status and location
- SHOULD create fix story for follow-up
- NEVER execute without confirmation for critical operations
- ALWAYS verify rollback success
- MUST notify stakeholders when configured

## Examples

### Example 1: Critical Full Rollback
```bash
INPUT:
/sdd:story-rollback STORY-2025-003 --severity=critical

PROCESS:
→ Locating story STORY-2025-003...
→ Found in /docs/stories/completed/STORY-2025-003.md
→ Loading rollback plan...

What issue are you experiencing?
> Payment processing completely broken, users cannot checkout

How many users are affected?
> All users attempting to purchase (estimated 100+ in last 10 mins)

→ Assessing situation...

OUTPUT:
🚨 ROLLBACK ASSESSMENT
══════════════════════

Severity: CRITICAL

IMPACT:
- Users affected: All users (100+ in 10 minutes)
- Features broken: Payment processing, checkout flow
- Data corruption risk: NO
- Revenue impact: Blocking all sales
- SLA breach: YES

ROOT CAUSE:
- Payment gateway integration broken
- API credential mismatch suspected

ROLLBACK OPTIONS:
1. ✅ Full rollback to v1.2.0 (RECOMMENDED)
   - Reverts all payment changes
   - Restores working checkout
   - Requires 2 migration rollbacks
   - ETA: 5 minutes

RECOMMENDATION: Full rollback (critical revenue impact)

Proceed with full rollback? (yes/no)
> yes

→ Creating pre-rollback backup...
💾 PRE-ROLLBACK BACKUP
✅ Database backed up
✅ Code state saved
✅ Configuration saved
✅ Logs archived

→ Executing code rollback...
↩️ CODE ROLLBACK
✅ Reverted to: v1.2.0
✅ Revert commit: def789
✅ Tag removed: v1.3.0

→ Executing database rollback...
🗄️ DATABASE ROLLBACK
✅ Migrations rolled back: 2
✅ Schema restored

→ Restoring configuration...
⚙️ CONFIGURATION ROLLBACK
✅ ENV variables restored
✅ Caches cleared
✅ Services restarted

→ Deploying previous version...
🚀 DEPLOYMENT ROLLBACK
✅ Deployed: v1.2.0
✅ Application: Running

→ Verifying rollback...
✅ ROLLBACK VERIFICATION
Smoke Tests: 12/12 passed
Original Issue: ✅ RESOLVED
Application Status: ✅ STABLE

→ Creating incident report...
→ Moving story to /docs/stories/development/

✅ ROLLBACK COMPLETE
════════════════════
Story: STORY-2025-003 - Payment Integration

ROLLBACK SUMMARY:
• Strategy: Full rollback
• Duration: 6 minutes
• Version: Reverted from v1.3.0 to v1.2.0
• Impact: Brief interruption during rollback

ACTIONS TAKEN:
✅ Code reverted to v1.2.0
✅ Database rolled back (2 migrations)
✅ Configuration restored
✅ Payment service restored

CURRENT STATE:
• Application: ✅ Running v1.2.0
• Checkout: ✅ Working normally
• Users: ✅ Can complete purchases
• Story: Moved to /docs/stories/development/

INCIDENT REPORT:
Created: INC-2025-03-16-001
Location: /docs/stories/development/STORY-2025-003.md

NEXT STEPS:
1. Monitor payment processing
2. Investigate API credential issue
3. Add payment integration tests
4. Implement with better validation
5. /sdd:story-start STORY-2025-003 when ready
```

### Example 2: Code-Only Rollback
```bash
INPUT:
/sdd:story-rollback STORY-2025-004 --rollback-type=code

PROCESS:
→ Locating story...
→ Found in /docs/stories/completed/STORY-2025-004.md

What issue are you experiencing?
> UI rendering broken on mobile devices

→ Assessing situation...
→ Severity: HIGH
→ Rollback type: Code only (database changes OK)

→ Executing code rollback...
→ Keeping database migrations
→ Reverting frontend changes...

OUTPUT:
✅ ROLLBACK COMPLETE
════════════════════
Story: STORY-2025-004 - Mobile UI Update

ROLLBACK SUMMARY:
• Strategy: Code-only rollback
• Duration: 3 minutes
• Database: No changes (migrations kept)

ACTIONS TAKEN:
✅ Code reverted
✅ Frontend assets rebuilt
✅ Application redeployed
✅ Mobile UI: Restored to previous version

Database migrations were not rolled back
as they are compatible with previous code.
```

### Example 3: Story Not Found
```bash
INPUT:
/sdd:story-rollback STORY-2025-999

PROCESS:
→ Searching for STORY-2025-999...
→ Not found in /docs/stories/completed/
→ Not found in /docs/stories/qa/
→ Not found in /docs/stories/review/
→ Not found in /docs/stories/development/

OUTPUT:
❌ STORY NOT FOUND
══════════════════

Story ID: STORY-2025-999

The story file was not found in any directory:
- /docs/stories/completed/
- /docs/stories/qa/
- /docs/stories/review/
- /docs/stories/development/
- /docs/stories/backlog/

Please verify the story ID and try again.

To see all stories: /sdd:project-status
```

## Edge Cases

### Database Data Loss Risk
- DETECT migrations that drop columns/tables
- CALCULATE potential data loss
- WARN user with specific details
- REQUIRE explicit confirmation
- OFFER to export data before rollback
- LOG data loss for incident report

### Partial Rollback Complexity
- IDENTIFY dependencies between changes
- ASSESS compatibility of partial rollback
- WARN about potential issues
- SUGGEST full rollback if too complex
- PROVIDE option to proceed with caution

### No Rollback Plan Documented
- WARN that rollback plan missing
- USE default rollback strategy
- GENERATE rollback steps from git history
- PROCEED with extra caution
- SUGGEST documenting rollback plans for future

### Rollback Verification Failure
- DETECT continued issues after rollback
- ASSESS if rollback successful but different issue
- OFFER to rollback further (older version)
- SUGGEST investigating root cause
- PROVIDE emergency contact information

### Multiple Stories Since Deployment
- DETECT other stories deployed after target
- WARN about reverting multiple changes
- LIST all stories that will be affected
- REQUIRE explicit confirmation
- SUGGEST selective rollback instead

## Error Handling
- **Story ID missing**: Return "Error: Story ID required. Usage: /sdd:story-rollback <story_id>"
- **Invalid story ID format**: Return "Error: Invalid story ID format. Expected: STORY-YYYY-NNN"
- **Story not found**: Search all directories and report not found
- **Rollback failure**: Capture error, provide manual rollback steps, alert for help
- **Database rollback error**: Stop rollback, restore from backup, seek manual intervention
- **Deployment failure**: Attempt re-deployment, provide manual steps, escalate if needed
- **Verification failure**: Alert that issue persists, suggest further rollback or investigation

## Performance Considerations
- Execute rollback steps in parallel when safe
- Stream rollback output in real-time
- Monitor application health continuously during rollback
- Generate incident report asynchronously after rollback

## Related Commands
- `/sdd:story-ship` - Ship story (the opposite of rollback)
- `/sdd:story-qa` - Return story to QA for fixes
- `/sdd:story-new` - Create fix story for addressing issues
- `/sdd:project-status` - View all project stories

## Constraints
- ✅ MUST locate story file before proceeding
- ✅ MUST assess severity and impact
- ✅ MUST create pre-rollback backup
- ✅ MUST confirm rollback strategy
- 🔄 MUST revert code changes
- 🗄️ MUST rollback database with caution
- ⚙️ MUST restore configuration
- ✔️ MUST verify application stability
- 📋 MUST complete post-rollback checklist
- 📊 MUST document incident
- 📝 SHOULD create fix story
- 🚫 NEVER execute without confirmation for critical operations
- ⚠️ ALWAYS warn about data loss
- 📣 MUST notify stakeholders