# /project-context-update

## Meta
- Version: 2.0
- Category: project-management
- Complexity: medium
- Purpose: Update project context documents with version control and consistency validation

## Definition
**Purpose**: Update technical stack, development process, coding standards, or project glossary documents while maintaining consistency across all project context files.

**Syntax**: `/project-context-update [document_type]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| document_type | string | No | prompted | Which document to update | One of: technical-stack, development-process, coding-standards, project-glossary, project-brief |

## INSTRUCTION: Update Project Context Documents

### INPUTS
- document_type: Type of context document to update (optional, prompted if not provided)
- Current context documents in `/project-context/`
- User-specified changes and updates
- Related documents for consistency validation

### PROCESS

#### Phase 1: Environment Verification
1. **CHECK** if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/project-init` first
   - EXIT with initialization guidance
3. **VERIFY** which context documents exist:
   - `/project-context/technical-stack.md` - Technology choices
   - `/project-context/coding-standards.md` - Quality rules
   - `/project-context/development-process.md` - Workflow definitions
   - `/project-context/project-glossary.md` - Domain vocabulary
   - `/project-context/project-brief.md` - Project overview

#### Phase 2: Document Selection
1. IF document_type provided:
   - VALIDATE it matches available document types
   - SET target_document to specified type
2. ELSE:
   - **ASK** user which document to update:
     ```
     Which document would you like to update?

     1. technical-stack       - Frameworks, languages, tools
     2. development-process   - Stage definitions, workflows
     3. coding-standards      - Naming, patterns, quality requirements
     4. project-glossary      - Domain terms, project vocabulary
     5. project-brief         - Project overview and goals

     Enter number or name:
     ```
   - CAPTURE user selection
   - SET target_document based on selection

#### Phase 3: Current State Analysis
1. **READ** current content from `/project-context/[target_document].md`
2. **PARSE** existing structure:
   - Identify main sections
   - Extract current technology choices (if technical-stack)
   - Understand existing standards and patterns
   - Note areas that may need updating
3. **DISPLAY** current state summary to user
4. **IDENTIFY** dependent documents that may be affected

#### Phase 4: Change Specification
1. **ASK** user what changes to make:
   - Add new technology/library (requires dependent updates)
   - Update existing entry (cascade changes to related standards)
   - Remove deprecated item (update all references)
   - Reorganize structure (maintain compatibility)
   - Migrate from one technology to another (comprehensive update)

2. **GATHER** specific details:
   - WHAT is being changed
   - WHY the change is needed
   - WHEN it should take effect
   - HOW it impacts other documents

3. **ASK** for version numbers and documentation links (if technical change)

#### Phase 5: Impact Analysis
1. **ANALYZE** impact on other context documents:

   IF updating technical-stack:
   - CHECK if coding-standards need updates
   - VERIFY development-process matches new stack
   - REVIEW project-glossary for new terms
   - IDENTIFY test commands that may change

   IF updating coding-standards:
   - VERIFY alignment with technical-stack
   - CHECK if development-process reviews need updates
   - NOTE impact on existing stories

   IF updating development-process:
   - CHECK if stages match technical-stack capabilities
   - VERIFY coding-standards align with new process
   - NOTE story templates that may need updates

   IF updating project-glossary:
   - ENSURE terms align with technical-stack
   - VERIFY consistency with project-brief terminology

2. **REPORT** identified impacts to user:
   ```
   Impact Analysis:
   ━━━━━━━━━━━━━━━━
   Primary Change: technical-stack.md

   Affected Documents:
   - coding-standards.md: Test command references need update
   - development-process.md: QA stage testing strategy needs alignment

   Affected Stories:
   - 2 stories in /development may need test updates
   - 1 story in /review may need coding standard adjustments
   ```

#### Phase 6: Change Application
1. **CREATE** backup before modifications:
   - COPY original file to `/project-context/versions/`
   - USE format: `[document]-backup-[timestamp].md`
   - LOG backup location

2. **APPLY** changes to target document:
   - UPDATE specified sections
   - MAINTAIN document structure
   - PRESERVE formatting and organization
   - ADD timestamps or version notes if appropriate

3. **SAVE** updated document to original location

#### Phase 7: Consistency Validation
1. **VALIDATE** consistency across project-context:
   - CHECK technical-stack and coding-standards align
   - VERIFY development-process matches technology choices
   - ENSURE project-glossary includes relevant terms
   - CONFIRM project-brief reflects current state

2. **DETECT** inconsistencies or conflicts:
   - Mismatched technology references
   - Outdated process descriptions
   - Missing terminology definitions
   - Conflicting standards

3. **REPORT** validation results to user

#### Phase 8: Cascading Updates (Optional)
1. IF other documents affected:
   - **ASK** user if they want to update related documents now
   - FOR EACH document requiring update:
     * SHOW what needs to change
     * ASK for confirmation
     * APPLY updates if approved
   - LOG all cascading changes

2. IF user declines cascading updates:
   - PROVIDE list of manual updates needed
   - SUGGEST specific changes for each document
   - NOTE in target document that related updates pending

#### Phase 9: Story Impact Assessment
1. **IDENTIFY** stories affected by context changes:
   - SCAN `/stories/development/` for impacted stories
   - CHECK `/stories/review/` for stories needing review updates
   - NOTE `/stories/qa/` stories requiring test updates

2. **SUGGEST** actions for affected stories:
   - Re-run `/story-review` for stories with new standards
   - Re-run `/story-qa` for stories with new test requirements
   - Update story documentation with new references

#### Phase 10: Completion Summary
1. **DISPLAY** update summary:
   ```
   ✅ Context Document Updated
   ═══════════════════════════════════

   Document: technical-stack.md
   Backup: /project-context/versions/technical-stack-backup-20251001-104500.md

   Changes Applied:
   - Added: Playwright for E2E testing
   - Updated: Node.js version 18 → 20
   - Removed: Deprecated library XYZ

   Cascading Updates:
   - coding-standards.md: Updated test naming conventions
   - development-process.md: Added Playwright to QA stage

   Affected Stories: 2 in development
   Recommended Actions:
   1. Review STORY-XXX-005 test setup
   2. Update STORY-XXX-007 with new standards
   ```

2. **PROVIDE** next steps:
   - Commands to run for impacted stories
   - Documentation links for new technologies
   - Timeline for completing related updates

### OUTPUTS
- Updated `/project-context/[document].md` - Modified context document
- Backup `/project-context/versions/[document]-backup-[timestamp].md` - Original version
- Updated related documents (if cascading updates approved)
- Impact assessment report
- Recommended actions list

### RULES
- MUST create backup before any modifications
- MUST validate consistency across all context documents
- MUST identify and report impacts on other documents
- MUST identify and report impacts on existing stories
- SHOULD offer to update related documents
- SHOULD provide specific update recommendations
- NEVER overwrite without creating backup
- ALWAYS maintain document structure and formatting

## Examples

### Example 1: Add New Testing Framework
```bash
INPUT:
/project-context-update technical-stack

INTERACTION:
→ Shows current technical-stack.md content
→ Asks: "What would you like to update?"
→ User: "Add Playwright for E2E testing"
→ Asks: "Version number?" → "1.40"
→ Asks: "Documentation link?" → "https://playwright.dev"

IMPACT ANALYSIS:
Analyzing impact...
- coding-standards.md: Test naming conventions need update
- development-process.md: QA stage needs Playwright integration
- 2 stories in /development may need test updates

OUTPUT:
✅ Context Document Updated
═══════════════════════════════════

Document: technical-stack.md
Backup: /project-context/versions/technical-stack-backup-20251001-104500.md

Changes Applied:
- Added: Playwright 1.40 for E2E testing
- Updated: Browser/E2E testing section

Cascading Updates Available:
1. coding-standards.md - Add Playwright test patterns
2. development-process.md - Update QA stage with Playwright

Would you like to apply cascading updates now? [y/n]
```

### Example 2: Migrate Technology
```bash
INPUT:
/project-context-update technical-stack

INTERACTION:
→ Asks: "What would you like to update?"
→ User: "Migrate from Jest to Vitest"

IMPACT ANALYSIS:
⚠️  Major Change Detected: Test Framework Migration

Affected Documents:
- technical-stack.md: Unit testing framework
- coding-standards.md: Test file conventions, imports
- development-process.md: Test commands in all stages
- project-glossary.md: Testing terminology

Affected Stories:
- 5 stories in /development with existing tests
- 2 stories in /review with test coverage
- 3 stories in /completed may need test migration

OUTPUT:
✅ Context Document Updated
═══════════════════════════════════

Document: technical-stack.md
Backup: /project-context/versions/technical-stack-backup-20251001-104530.md

Changes Applied:
- Removed: Jest (deprecated)
- Added: Vitest 1.0 (new unit testing framework)
- Updated: Test runner commands (npm test → vitest)

Cascading Updates Required:
1. coding-standards.md: Test import statements (expect from 'vitest')
2. development-process.md: Test commands in all stages
3. project-glossary.md: Update testing terminology

⚠️  IMPORTANT: Existing Stories Need Updates
- 5 stories in /development require test migration
- Consider creating migration guide story

Recommended Actions:
1. Update all context documents (run /project-context-update)
2. Create STORY-MIGRATION: Jest to Vitest migration guide
3. Re-run tests for all in-progress stories
4. Update test templates in /stories/templates/
```

### Example 3: Update Coding Standards
```bash
INPUT:
/project-context-update coding-standards

INTERACTION:
→ Shows current coding-standards.md
→ Asks: "What would you like to update?"
→ User: "Change line length from 80 to 120 characters"

IMPACT ANALYSIS:
Analyzing impact...
- Technical stack: No changes needed
- Development process: No changes needed
- Existing code: May need reformatting
- Stories: 3 in /review may need re-review

OUTPUT:
✅ Context Document Updated
═══════════════════════════════════

Document: coding-standards.md
Backup: /project-context/versions/coding-standards-backup-20251001-104600.md

Changes Applied:
- Updated: Line length limit 80 → 120 characters
- Updated: Prettier configuration reference

No cascading updates required.

⚠️  Code Formatting Impact:
- Existing code may need reformatting
- Run: npm run format (or equivalent)
- Consider: Re-review 3 stories in /review with new standard

Recommended Actions:
1. Run formatter across codebase
2. Re-review STORY-XXX-003, STORY-XXX-006, STORY-XXX-009
3. Update editor/IDE settings to 120 char limit
```

### Example 4: No Project Context
```bash
INPUT:
/project-context-update

OUTPUT:
⚠️  PROJECT CONTEXT NOT FOUND

The /project-context/ directory does not exist.

To set up the story-driven development system, run:
→ /project-init

This will create:
- Project context directory
- All context documents
- Document templates
```

## Edge Cases

### Document Doesn't Exist
- DETECT missing document
- OFFER to create it with standard template
- IF user confirms, create document and continue
- ELSE suggest running `/project-init`

### No Changes Specified
- IF user can't specify changes clearly
- OFFER examples of common updates
- PROVIDE guided questions
- ALLOW user to cancel if not ready

### Conflicting Updates
- DETECT conflicts between updates
- EXPLAIN the conflict to user
- SUGGEST resolution approaches
- REQUIRE user decision before proceeding

### Large Cascading Impact
- IF changes affect many documents/stories
- WARN user about scope of impact
- SUGGEST breaking into smaller updates
- PROVIDE option to review impact before applying

## Error Handling
- **Missing /project-context/**: Suggest `/project-init` with clear instructions
- **Document not found**: Offer to create with template or abort
- **Backup creation fails**: MUST NOT proceed with updates, report error
- **Permission errors**: Report specific file with access issue
- **Validation failures**: Show inconsistencies, suggest fixes, don't force update

## Performance Considerations
- Document reads are fast (< 100ms)
- Impact analysis scales with document count (typically < 1s)
- Backup creation is quick (< 50ms per file)
- Story scanning may take longer (100+ stories: ~2-3s)

## Security Considerations
- Verify write permissions before modifications
- Validate all file paths stay within project
- Create backups before any destructive operations
- Don't expose sensitive configuration data

## Related Commands
- `/project-init` - Initialize project structure if missing
- `/project-brief` - Update high-level project documentation
- `/story-review` - Re-review stories with new standards
- `/story-qa` - Re-test stories with new requirements
- `/project-status` - View current project state

## Constraints
- ⚠️ MUST create backup before any modification
- ✅ MUST validate consistency across context documents
- ✅ MUST identify impact on other documents and stories
- 📋 SHOULD offer to apply cascading updates
- 🔄 SHOULD provide specific recommendations
- ⚡ MUST complete analysis in < 5 seconds
- 💾 NEVER overwrite without backup
