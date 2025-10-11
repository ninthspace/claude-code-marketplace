# /sdd:story-flow

## Meta
- Version: 1.0
- Category: workflow-automation
- Complexity: high
- Purpose: Automate the complete story lifecycle from creation to deployment

## Definition
**Purpose**: Execute the complete story development workflow in sequence, automating the progression through all stages from story creation to production deployment.

**Syntax**: `/sdd:story-flow <prompt|story_id> [--start-at=step] [--stop-at=step] [--auto]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| prompt\|story_id | string | Yes | - | Story prompt/title or existing story ID (e.g., STORY-2025-001, STORY-DUE-001) | Non-empty string |
| --start-at | string | No | new | Start at specific step (new\|start\|implement\|review\|qa\|validate\|save\|ship) | Valid step name |
| --stop-at | string | No | ship | Stop at specific step | Valid step name |
| --auto | flag | No | false | Skip confirmations between steps | Boolean flag |

## INSTRUCTION: Execute Story Workflow Sequence

### INPUTS
- prompt\|story_id: Either a new story description or an existing story ID
- --start-at: Optional step to begin from (default: new)
- --stop-at: Optional step to end at (default: ship)
- --auto: Optional flag to run all steps without confirmation

### PROCESS

#### Phase 1: Initialization
1. **PARSE** input to determine if it's a new prompt or existing story ID:
   - IF matches pattern `STORY-[A-Z0-9]+-\d+`: Use as existing story ID
     * Supports: STORY-2025-001 (year-based)
     * Supports: STORY-DUE-001 (phase-based)
     * Supports: STORY-AUTH-001 (feature-based)
   - ELSE: Treat as new story prompt

2. **VALIDATE** start-at and stop-at parameters:
   - ENSURE start-at comes before stop-at in sequence
   - VALID SEQUENCE: new → start → implement → review → qa → validate → save → ship
   - IF invalid: SHOW error and exit

3. **DISPLAY** workflow plan:
   ```
   📋 STORY WORKFLOW PLAN
   ═══════════════════════
   Story: [prompt or ID]
   Sequence: [start-at] → [stop-at]
   Mode: [auto ? "Automatic" : "Interactive"]

   Steps to execute:
   [list of steps that will run]
   ```

#### Phase 2: Sequential Execution

**STEP 1: /sdd:story-new** (IF start-at is "new")
1. **DETECT** if input is existing story ID:
   - CHECK pattern: `STORY-[A-Z0-9]+-\d+`
   - SEARCH for story file in all story directories:
     * /stories/backlog/
     * /stories/development/
     * /stories/review/
     * /stories/qa/
     * /stories/completed/
     * /project-context/phases/*/
2. IF story file found:
   - SKIP story creation
   - USE found story_id
   - PROCEED to next step
3. ELSE (new story):
   - EXECUTE: `/sdd:story-new` with prompt as story title
   - CAPTURE: Generated story ID
   - IF --auto flag NOT set:
     - SHOW: Story creation summary
     - ASK: "Continue to next step? (y/n)"
     - IF no: EXIT workflow
   - UPDATE: Current story_id variable

**STEP 2: /sdd:story-start** (IF in range)
1. EXECUTE: `/sdd:story-start [story_id]`
2. VERIFY: Branch created and checked out
3. IF --auto flag NOT set:
   - SHOW: Branch and environment status
   - ASK: "Continue to implementation? (y/n)"
   - IF no: EXIT with current status
4. IF error:
   - LOG: Error details
   - OFFER: Skip this step, retry, or abort
   - PROCEED based on user choice

**STEP 3: /sdd:story-implement** (IF in range)
1. EXECUTE: `/sdd:story-implement [story_id]`
2. VERIFY: Code generated successfully
3. IF --auto flag NOT set:
   - SHOW: Files created/modified summary
   - ASK: "Continue to review? (y/n)"
   - IF no: EXIT with suggestion to run `/sdd:story-save`
4. IF error:
   - SHOW: Implementation issues
   - OFFER: Retry implementation or manual fix
   - WAIT for user decision

**STEP 4: /sdd:story-review** (IF in range)
1. EXECUTE: `/sdd:story-review [story_id]`
2. VERIFY: Code quality checks passed
3. IF --auto flag NOT set:
   - SHOW: Review results
   - ASK: "Continue to QA? (y/n)"
   - IF no: EXIT with refactor suggestions
4. IF review finds issues:
   - DISPLAY: Issues found
   - IF --auto: CONTINUE anyway with warning
   - ELSE: OFFER to fix before continuing

**STEP 5: /sdd:story-qa** (IF in range)
1. EXECUTE: `/sdd:story-qa [story_id]`
2. VERIFY: All tests passed
3. IF --auto flag NOT set:
   - SHOW: Test results summary
   - ASK: "Continue to validation? (y/n)"
   - IF no: EXIT with test failure details
4. IF tests fail:
   - DISPLAY: Failed tests
   - HALT workflow (QA must pass)
   - SUGGEST: Fix tests and run `/sdd:story-flow [story_id] --start-at=qa`
   - EXIT

**STEP 6: /sdd:story-validate** (IF in range)
1. EXECUTE: `/sdd:story-validate [story_id]`
2. VERIFY: All acceptance criteria met
3. IF --auto flag NOT set:
   - SHOW: Validation checklist
   - ASK: "Ready to save and ship? (y/n)"
   - IF no: EXIT with validation details
4. IF validation fails:
   - DISPLAY: Unmet criteria
   - HALT workflow
   - SUGGEST: Address issues and retry
   - EXIT

**STEP 7: /sdd:story-save** (IF in range)
1. EXECUTE: `/sdd:story-save` with auto-generated commit message
2. VERIFY: Changes committed successfully
3. IF --auto flag NOT set:
   - SHOW: Commit summary
   - ASK: "Continue to ship? (y/n)"
   - IF no: EXIT with ship instructions
4. IF commit fails:
   - SHOW: Git errors
   - OFFER: Resolve conflicts or abort
   - WAIT for resolution

**STEP 8: /sdd:story-ship** (IF in range AND is stop-at)
1. EXECUTE: `/sdd:story-ship [story_id]`
2. VERIFY: Merged and deployed successfully
3. SHOW: Final completion summary
4. IF error:
   - HALT before deployment
   - SHOW: Deployment errors
   - SUGGEST: `/sdd:story-rollback [story_id]` if needed
   - MANUAL intervention required

#### Phase 3: Completion Summary

**DISPLAY** workflow completion status:
```
✅ STORY WORKFLOW COMPLETED
═══════════════════════════
Story: [story_id] - [Title]
Status: [current stage]

Completed Steps:
✓ Story created/loaded
✓ Development started (branch: [name])
✓ Implementation generated
✓ Code review passed
✓ QA tests passed
✓ Validation successful
✓ Changes committed
✓ Deployed to production

[IF stopped before ship:]
⏸️ Workflow Paused
Next Step: /sdd:story-flow [story_id] --start-at=[next-step]

[IF any warnings:]
⚠️ Warnings:
[list of non-blocking issues]

Total Duration: [time elapsed]
Next Actions:
[context-appropriate suggestions]
```

### OUTPUTS
- Fully executed story workflow from specified start to stop
- Progress updates at each step
- Error handling with recovery options
- Final summary with deployment status

### RULES
- MUST execute steps in correct sequence order
- MUST validate each step before proceeding to next
- MUST halt on QA or validation failures
- SHOULD ask for confirmation between steps (unless --auto)
- MUST provide clear error messages and recovery options
- NEVER skip critical validation steps
- ALWAYS save work before shipping
- MUST update story file status at each stage

## Examples

### Example 1: Full Workflow from New Story
```bash
INPUT:
/sdd:story-flow "Add user registration form with email verification"

PROCESS:
→ Step 1/8: Creating story...
✅ Story created: STORY-2025-015
→ Prompt: Continue to start development? (y/n) y

→ Step 2/8: Starting development...
✅ Branch created: feature/registration-015
→ Prompt: Continue to implementation? (y/n) y

→ Step 3/8: Generating implementation...
✅ Files created: RegistrationForm.php, registration-form.blade.php, RegistrationTest.php
→ Prompt: Continue to review? (y/n) y

→ Step 4/8: Running code review...
✅ Review passed: 0 issues found
→ Prompt: Continue to QA? (y/n) y

→ Step 5/8: Running QA tests...
✅ All tests passed (Unit: 5, Feature: 3, Browser: 2)
→ Prompt: Continue to validation? (y/n) y

→ Step 6/8: Validating story...
✅ All acceptance criteria met
→ Prompt: Ready to save and ship? (y/n) y

→ Step 7/8: Committing changes...
✅ Committed: "feat: add user registration form with email verification"
→ Prompt: Continue to ship? (y/n) y

→ Step 8/8: Shipping to production...
✅ Merged to main, deployed successfully

OUTPUT:
✅ STORY WORKFLOW COMPLETED
═══════════════════════════
Story: STORY-2025-015 - Add user registration form
Status: shipped

All steps completed successfully ✓
Total Duration: 12 minutes
```

### Example 2: Resume from Existing Story (Year-based ID)
```bash
INPUT:
/sdd:story-flow STORY-2025-010 --start-at=qa --auto

PROCESS:
→ Loading story: STORY-2025-010
→ Starting from: qa
→ Auto mode: enabled

→ Step 1/4: Running QA tests...
✅ All tests passed

→ Step 2/4: Validating story...
✅ Validation successful

→ Step 3/4: Committing changes...
✅ Changes committed

→ Step 4/4: Shipping to production...
✅ Deployed successfully

OUTPUT:
✅ STORY WORKFLOW COMPLETED
Story: STORY-2025-010
Executed: qa → validate → save → ship
Duration: 3 minutes
```

### Example 2b: Phase-based Story ID
```bash
INPUT:
/sdd:story-flow STORY-DUE-001 --start-at=start

PROCESS:
→ Detected phase-based story: STORY-DUE-001
→ Found in: /project-context/phases/phase-due-dates/
→ Starting from: start
→ Skipping story creation (already exists)

→ Step 1/7: Starting development...
✅ Branch created: feature/due-001-database-schema
→ Prompt: Continue to implementation? (y/n) y

→ Step 2/7: Generating implementation...
✅ Migration and model files created
→ Prompt: Continue to review? (y/n) y

[continues through workflow...]

OUTPUT:
✅ STORY WORKFLOW COMPLETED
Story: STORY-DUE-001 - Add Due Date Database Schema
Phase: due-dates
Duration: 8 minutes
```

### Example 3: Partial Workflow
```bash
INPUT:
/sdd:story-flow "Fix login page responsive layout" --stop-at=review

PROCESS:
→ Step 1/4: Creating story...
✅ Story created: STORY-2025-016

→ Step 2/4: Starting development...
✅ Branch created: feature/login-layout-016

→ Step 3/4: Generating implementation...
✅ Implementation complete

→ Step 4/4: Running code review...
✅ Review passed

OUTPUT:
⏸️ WORKFLOW PAUSED AT: review
═══════════════════════════
Story: STORY-2025-016 - Fix login page layout
Status: in-review

Completed: new → start → implement → review
Next: /sdd:story-flow STORY-2025-016 --start-at=qa

To resume full workflow:
/sdd:story-flow STORY-2025-016 --start-at=qa --auto
```

### Example 4: QA Failure Handling
```bash
INPUT:
/sdd:story-flow STORY-2025-012 --start-at=qa --auto

PROCESS:
→ Step 1/4: Running QA tests...
❌ Tests failed: 2 failures in Feature tests

OUTPUT:
❌ WORKFLOW HALTED AT: qa
═══════════════════════════
Story: STORY-2025-012

Failed Tests:
- Feature\TaskCompletionTest::test_task_can_be_marked_complete
- Feature\TaskCompletionTest::test_completed_task_updates_timestamp

QA must pass before proceeding.

Next Actions:
1. Review test failures above
2. Fix implementation issues
3. Run tests: vendor/bin/pest --filter=TaskCompletion
4. Resume workflow: /sdd:story-flow STORY-2025-012 --start-at=qa
```

## Edge Cases

### Story Already Shipped
```
IF story_id found in /stories/completed/:
- SHOW: Story already completed
- OFFER: View story details or create new version
- SUGGEST: /sdd:story-new for related feature
- EXIT workflow
```

### Workflow Interrupted
```
IF user cancels mid-workflow:
- SHOW: Current step and status
- SAVE: Workflow state
- SUGGEST: Resume command with --start-at
- EXIT gracefully
```

### Mixed Mode (Some Steps Already Done)
```
IF starting mid-workflow and previous steps incomplete:
- DETECT: Missing prerequisites
- WARN: "Story implementation not found, cannot run QA"
- SUGGEST: Start from earlier step
- OFFER: Continue anyway (risky) or restart
```

## Error Handling
- **Invalid step name**: Show valid step names and exit
- **Story not found**: Search all story locations (backlog, development, review, qa, completed, phases), suggest `/sdd:story-new` or check story ID
- **Ambiguous story ID**: If multiple stories found with similar IDs, list them and ask user to specify
- **Step prerequisites missing**: Show missing requirements and suggest order
- **Git conflicts**: Halt workflow, show conflict files, require manual resolution
- **Test failures**: Always halt, never auto-continue on failures
- **Deployment errors**: Halt before merge, offer rollback option

## Performance Considerations
- Each step executes sequentially (no parallelization)
- Expected total time: 10-20 minutes for full workflow
- Auto mode reduces interaction time by ~50%
- Can pause/resume at any step without data loss

## Related Commands
- `/sdd:story-new` - Create individual story (Step 1)
- `/sdd:story-start` - Start development (Step 2)
- `/sdd:story-implement` - Generate code (Step 3)
- `/sdd:story-review` - Code review (Step 4)
- `/sdd:story-qa` - Run tests (Step 5)
- `/sdd:story-validate` - Final validation (Step 6)
- `/sdd:story-save` - Commit changes (Step 7)
- `/sdd:story-ship` - Deploy to production (Step 8)
- `/sdd:story-rollback` - Rollback if issues arise

## Constraints
- ✅ MUST execute steps in correct order
- ✅ MUST halt on test or validation failures
- ✅ MUST support flexible story ID patterns (year-based, phase-based, feature-based)
- ✅ MUST search all story locations (backlog, development, review, qa, completed, phases)
- ⚠️ NEVER skip QA or validation steps
- ⚠️ NEVER auto-continue on errors in auto mode
- 📋 MUST save work before shipping
- 🔧 SHOULD provide resume options on failure
- 💾 MUST update story status at each step
- 🚀 MUST verify deployment success before completion

## Notes
- This command automates the entire story lifecycle
- Interactive mode (default) allows review at each step
- Auto mode (`--auto`) speeds up workflow but still halts on errors
- Partial workflows supported via --start-at and --stop-at
- All individual commands can still be run separately
- Workflow state is preserved for resume capability
- Supports multiple story ID formats:
  * Year-based: STORY-2025-001
  * Phase-based: STORY-DUE-001, STORY-AUTH-001
  * Feature-based: STORY-API-001
- Searches all story locations including project-context/phases/
