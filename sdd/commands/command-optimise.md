# /command-optimise

## Meta
- Version: 2.0
- Category: transformation
- Complexity: moderate
- Purpose: Convert existing slash commands to LLM-optimized format with intelligent auto-detection

## Definition
**Purpose**: Transform slash command documentation into LLM-optimised format by analysing the command's content to determine optimal formatting, then replaces the original command file with the optimised version.

**Syntax**: `/command-optimise <command_ref> [format_style] [strictness] [--dry-run]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| command_ref | string | Yes | - | Command name (e.g., "/deploy") OR full command documentation text | Non-empty |
| format_style | string | No | "auto" | Output format style | One of: auto, structured, xml, json, imperative, contract |
| strictness | string | No | "auto" | Level of detail and validation rules | One of: auto, minimal, standard, comprehensive |
| --dry-run | flag | No | false | Preview changes without writing to file | Boolean flag |

## Behavior
```
ON INVOCATION:
  1. DETERMINE input type and retrieve command documentation:
     
     IF command_ref starts with "/" AND has no spaces/newlines:
       // This is a command name reference
       SEARCH for command documentation:
         - Look in project's /commands directory
         - Check registered command definitions
         - Search documentation files
         - Query command registry
       
       IF command found:
         SET command_text = retrieved documentation
       ELSE:
         RETURN "Error: Command '{command_ref}' not found. Please provide the full command text."
     
     ELSE:
       // This is the full command documentation
       SET command_text = command_ref
  
  2. PARSE command documentation:
     - Extract command name (look for /command patterns)
     - Identify any existing parameters/arguments
     - Find usage examples if present
     - Detect implicit behavior from description
     - Extract action verbs and keywords from documentation
  
  3. ANALYZE command content to determine optimal configuration:
     
     EXAMINE command documentation for indicators:
     
     // Check for STATE MODIFICATION indicators
     STATE_MODIFYING_INDICATORS = [
       "saves", "writes", "updates", "modifies", "changes", "deletes", "removes",
       "creates", "inserts", "deploys", "publishes", "commits", "persists",
       "alters", "mutates", "transforms production", "affects live"
     ]
     
     // Check for SECURITY/CRITICAL indicators
     SECURITY_INDICATORS = [
       "authenticate", "authorize", "encrypt", "decrypt", "password", "token",
       "certificate", "permission", "access control", "security", "vulnerability",
       "sensitive", "credential", "private key", "secret"
     ]
     
     // Check for ANALYSIS/INSPECTION indicators
     ANALYSIS_INDICATORS = [
       "analyzes", "scans", "inspects", "examines", "profiles", "measures",
       "benchmarks", "evaluates", "assesses", "diagnoses", "investigates",
       "reports on", "collects metrics", "gathers data"
     ]
     
     // Check for VALIDATION/TESTING indicators
     VALIDATION_INDICATORS = [
       "tests", "validates", "verifies", "checks", "asserts", "ensures",
       "confirms", "proves", "quality assurance", "QA", "unit test",
       "integration test", "e2e", "smoke test"
     ]
     
     // Check for CONFIGURATION indicators
     CONFIG_INDICATORS = [
       "configures", "sets up", "initializes", "options", "settings",
       "preferences", "environment", "parameters", "flags", "toggles"
     ]
     
     // Check for SEARCH/QUERY indicators
     SEARCH_INDICATORS = [
       "searches", "finds", "queries", "lists", "fetches", "retrieves",
       "gets", "selects", "filters", "looks up", "discovers"
     ]
     
     // Check for DOCUMENTATION indicators
     DOC_INDICATORS = [
       "documents", "generates docs", "creates documentation", "API spec",
       "readme", "comments", "annotates", "describes", "explains"
     ]
     
     // Analyze parameter complexity
     PARAM_COMPLEXITY = COUNT(parameters) + 
                        COUNT(nested_params) * 2 + 
                        COUNT(optional_params) * 0.5
     
     // Analyze behavior complexity
     BEHAVIOR_COMPLEXITY = COUNT(steps) + 
                          COUNT(conditionals) * 2 + 
                          COUNT(error_cases)
     
     // DECISION TREE for format selection:
     IF (contains STATE_MODIFYING_INDICATORS && contains("production|live|database")):
       format = "contract"  // Need guarantees
       strictness = "comprehensive"
       reason = "Command modifies production state - requires strict pre/post conditions"
     
     ELSE IF (contains SECURITY_INDICATORS):
       format = "contract"  // Security needs guarantees
       strictness = "comprehensive"
       reason = "Security-sensitive command - requires comprehensive validation"
     
     ELSE IF (contains VALIDATION_INDICATORS && BEHAVIOR_COMPLEXITY > 5):
       format = "contract"  // Complex testing needs clear contracts
       strictness = "comprehensive"
       reason = "Complex validation logic - benefits from GIVEN/WHEN/THEN structure"
     
     ELSE IF (contains ANALYSIS_INDICATORS && mentions("step|phase|process")):
       format = "imperative"  // Multi-step analysis
       strictness = "comprehensive"
       reason = "Multi-step analysis process - suits INSTRUCTION/PROCESS format"
     
     ELSE IF (PARAM_COMPLEXITY > 8 || has_nested_objects):
       format = "json"  // Complex parameters
       strictness = "standard"
       reason = "Complex parameter structure - JSON schema provides clarity"
     
     ELSE IF (contains CONFIG_INDICATORS && has_multiple_options):
       format = "json"  // Configuration with options
       strictness = "standard"
       reason = "Configuration command with multiple options - JSON format ideal"
     
     ELSE IF (contains DOC_INDICATORS):
       format = "xml"  // Rich documentation
       strictness = "comprehensive"
       reason = "Documentation generation - XML provides rich metadata structure"
     
     ELSE IF (contains SEARCH_INDICATORS && PARAM_COMPLEXITY < 3):
       format = "json"  // Simple search
       strictness = "minimal"
       reason = "Simple search/query command - minimal JSON sufficient"
     
     ELSE IF (BEHAVIOR_COMPLEXITY < 3 && PARAM_COMPLEXITY < 3):
       format = "structured"  // Simple command
       strictness = "minimal"
       reason = "Simple utility command - basic structure sufficient"
     
     ELSE IF (contains("build|compile|make|bundle")):
       format = "imperative"  // Build process
       strictness = "standard"
       reason = "Build process - benefits from step-by-step PROCESS format"
     
     ELSE:
       format = "structured"  // Default fallback
       strictness = "standard"
       reason = "Standard command - balanced structure and detail"
  
  4. LOG analysis decision:
     ```
     Command Analysis Results:
     ━━━━━━━━━━━━━━━━━━━━━━━━
     Detected Characteristics:
     - State Modification: [Yes/No] {indicators found}
     - Security Concerns: [Yes/No] {indicators found}
     - Parameter Complexity: [Low/Medium/High] (score: X)
     - Behavior Complexity: [Low/Medium/High] (score: Y)
     - Primary Function: [category]
     
     Selected Configuration:
     - Format: [format_style]
     - Strictness: [strictness]
     - Reasoning: [detailed explanation]
     ```
  
  5. TRANSFORM to selected format_style:
     
     IF format_style="structured":
       - Use markdown headers with consistent hierarchy
       - Add parameter table with types
       - Include behavior steps
       - Add examples section
     
     IF format_style="xml":
       - Wrap in XML-style tags
       - Separate purpose, syntax, parameters, behavior
       - Include constraints section
     
     IF format_style="json":
       - Convert to JSON schema format
       - Include type definitions
       - Add execution_steps array
     
     IF format_style="imperative":
       - Use INSTRUCTION/PROCESS format
       - Add INPUTS/OUTPUTS sections
       - Include RULES with MUST/SHOULD/NEVER
     
     IF format_style="contract":
       - Use GIVEN/WHEN/THEN format
       - Add PRECONDITIONS/POSTCONDITIONS
       - Include INVARIANTS
  
  6. ENHANCE based on strictness:
     
     IF strictness="minimal":
       - Add only essential missing elements
       - Basic type annotations
       - Simple examples
     
     IF strictness="standard":
       - Complete parameter documentation
       - Validation rules
       - Error handling section
       - Multiple examples
     
     IF strictness="comprehensive":
       - Detailed type specifications
       - Edge case handling
       - Performance considerations
       - Version information
       - Related commands
       - Security considerations (if applicable)
       - Rollback procedures (if state-modifying)
  
  7. VALIDATE converted documentation:
     - Ensure all parameters are documented
     - Verify examples match syntax
     - Check for ambiguous instructions
  
  8. WRITE optimised command to file:
     
     IF --dry-run flag is set:
       DISPLAY preview of changes:
       ```
       DRY RUN - No files will be modified
       ────────────────────────────────────
       Original file: /commands/deploy.md
       Format: contract
       Strictness: comprehensive
       
       Preview of changes:
       [Show diff or preview]
       
       To apply changes, run without --dry-run
       ```
     
     ELSE:
       // Create backup of original
       IF command was loaded from file:
         COPY original to "{filename}.backup-{timestamp}"
         LOG "Backup created: {backup_path}"
       
       // Determine output path
       IF command_ref was a name reference:
         SET output_path = original file location
       ELSE:
         // For text input, create new file
         SET output_path = "/commands/{command_name}.md"
       
       // Write optimised version
       WRITE optimised documentation to output_path
       
       // Log the update
       GENERATE update report:
       ```
       ✅ Command Successfully Optimised
       ═══════════════════════════════════
       Command: {command_name}
       Original: {original_path}
       Backup: {backup_path}
       Updated: {output_path}
       Format Applied: {format_style}
       Strictness: {strictness_level}
       Timestamp: {iso_timestamp}
       
       Changes Applied:
       - Added type annotations to {n} parameters
       - Generated {n} usage examples
       - Added {validation_rules} validation rules
       - Created {sections} new documentation sections
       
       File has been updated in place.
       To revert: mv {backup_path} {output_path}
       ```
  
  9. RETURN confirmation with analysis report and file paths
```

## Examples

### Example 1: Replace Command File
```bash
INPUT:
/command-optimise /deploy

PROCESS:
→ Retrieved documentation from /commands/deploy.md
→ Created backup: /commands/deploy.md.backup-20250127-143022
→ Analysed and optimised command
→ Wrote optimised version to /commands/deploy.md

OUTPUT:
✅ Command Successfully Optimised
═══════════════════════════════════
Command: /deploy
Original: /commands/deploy.md
Backup: /commands/deploy.md.backup-20250127-143022
Updated: /commands/deploy.md
Format Applied: contract
Strictness: comprehensive
Timestamp: 2025-01-27T14:30:22Z

Changes Applied:
- Added type annotations to 5 parameters
- Generated 3 usage examples
- Added 8 validation rules
- Created 4 new documentation sections

File has been updated in place.
To revert: mv /commands/deploy.md.backup-20250127-143022 /commands/deploy.md
```

### Example 2: Dry Run Preview
```bash
INPUT:
/command-optimise /api-call json comprehensive --dry-run

PROCESS:
→ Retrieved documentation from /commands/api-call.md
→ Analysed and optimised command
→ DRY RUN MODE - No files modified

OUTPUT:
DRY RUN - No files will be modified
────────────────────────────────────
Original file: /commands/api-call.md
Format: json (manually specified)
Strictness: comprehensive (manually specified)

Preview of changes:
- FROM: Simple text documentation
- TO: Full JSON schema with type definitions
- Added: Error handling section
- Added: 5 usage examples
- Added: Parameter validation rules

[Shows preview of optimised content]

To apply changes, run without --dry-run:
/command-optimise /api-call json comprehensive
```

### Example 3: Create New File from Text
```bash
INPUT:
/command-optimise "
/process-data - handles user data
Takes input file, transforms it, and saves the results to the database.
Can update existing records or create new ones.
"

PROCESS:
→ Detected full command documentation (contains spaces/newlines)
→ Analyzing provided text directly

ANALYSIS:
✓ Found state modification indicators: "saves", "database", "update"
[Continues with normal analysis...]
```

### Example 4: Command Not Found
```bash
INPUT:
/command-optimise /unknown-command

PROCESS:
→ Detected command name reference: "/unknown-command"
→ Searching command registry...
→ Command not found

OUTPUT:
Error: Command '/unknown-command' not found. Please provide the full command text or ensure the command name is correct.
```

### Example 5: Auto-Detects State Modification in Retrieved Command
```bash
INPUT:
/command-optimise /migrate-db

PROCESS:
→ Retrieved from: /commands/migrate-db.md
→ Created backup: /commands/migrate-db.md.backup-20250127-143045

ANALYSIS:
✓ Found state modification indicators: "migrations", "updates", "schema"
✓ Found database indicators: "database", "schema"
✓ Detected: Database migration command
✓ Applied: contract format + comprehensive strictness
✓ Reasoning: Database changes need strict pre/post conditions

OUTPUT:
✅ Command Successfully Optimised
═══════════════════════════════════
Command: /migrate-db
Original: /commands/migrate-db.md
Backup: /commands/migrate-db.md.backup-20250127-143045
Updated: /commands/migrate-db.md
Format Applied: contract
Strictness: comprehensive

File has been updated in place.
✓ Applied: contract format + comprehensive strictness
✓ Reasoning: Command modifies database state - requires strict pre/post conditions

OUTPUT:
CONTRACT: Data Processing Command

GIVEN: Input file with user data to process
WHEN: The /process-data command is invoked
THEN: Data is transformed and persisted to database

PRECONDITIONS:
✓ Input file exists and is readable
✓ File format is valid (CSV/JSON/XML)
✓ Database connection is available
✓ User has write permissions
✓ Sufficient storage space available

ACTIONS:
→ Validate input file format
→ Parse and load data into memory
→ Apply transformation rules
→ Check for existing records
→ IF existing: Update with new values
→ ELSE: Create new records
→ Commit transaction to database
→ Generate operation report

POSTCONDITIONS:
✓ All valid data is saved to database
✓ Invalid records are logged
✓ Transaction is atomic (all or nothing)
✓ Audit trail is updated
✓ Report contains success/failure counts

INVARIANTS:
• Data integrity is maintained
• No partial updates on failure
• Original file is never modified
• Database constraints are respected
```

### Example 6: Auto-Detects Complex Parameters
```bash
INPUT:
/optimize-command "
/api-call - makes HTTP requests
Parameters:
- url: target endpoint
- method: GET, POST, PUT, DELETE
- headers: object with header key-values
- body: nested JSON payload
- auth: {type: 'bearer'|'basic', credentials: {...}}
- retry: {attempts: number, delay: number}
"

ANALYSIS:
✓ Parameter complexity score: 12 (6 params, 3 nested objects)
✓ Detected: Complex parameter structure
✓ Applied: json format + standard strictness
✓ Reasoning: Complex nested parameters - JSON schema provides clarity

OUTPUT:
{
  "command": "/api-call",
  "description": "Execute HTTP requests with configurable options",
  "parameters": {
    "url": {
      "type": "string",
      "required": true,
      "description": "Target endpoint URL",
      "pattern": "^https?://.+"
    },
    "method": {
      "type": "string",
      "required": false,
      "default": "GET",
      "enum": ["GET", "POST", "PUT", "DELETE", "PATCH"]
    },
    "headers": {
      "type": "object",
      "required": false,
      "description": "HTTP headers as key-value pairs",
      "additionalProperties": {"type": "string"}
    },
    "body": {
      "type": "object",
      "required": false,
      "description": "Request body for POST/PUT requests"
    },
    "auth": {
      "type": "object",
      "required": false,
      "properties": {
        "type": {"enum": ["bearer", "basic"], "required": true},
        "credentials": {
          "type": "object",
          "properties": {
            "token": {"type": "string"},
            "username": {"type": "string"},
            "password": {"type": "string"}
          }
        }
      }
    },
    "retry": {
      "type": "object",
      "required": false,
      "properties": {
        "attempts": {"type": "integer", "minimum": 1, "maximum": 5},
        "delay": {"type": "integer", "minimum": 100, "maximum": 5000}
      }
    }
  },
  "execution_steps": [
    "Validate URL format",
    "Configure authentication if provided",
    "Set request headers",
    "Prepare request body if applicable",
    "Execute HTTP request with retry logic",
    "Handle response or errors",
    "Format and return results"
  ],
  "error_handling": {
    "invalid_url": "Return error: 'Invalid URL format'",
    "network_error": "Retry according to retry config, then fail",
    "auth_failure": "Return 401 with auth error details",
    "timeout": "Retry with exponential backoff"
  }
}
```

### Example 3: Auto-Detects Multi-Step Process
```bash
INPUT:
/optimize-command "
/analyze-codebase
Performs code analysis in three phases:
1. First scans all files for syntax errors
2. Then checks for code smells and anti-patterns  
3. Finally generates a detailed report with metrics
Each phase must complete before the next begins.
"

ANALYSIS:
✓ Found analysis indicators: "analyzes", "scans", "checks", "report", "metrics"
✓ Detected multi-step process: "phases", "First", "Then", "Finally"
✓ Behavior complexity: High (3 phases + sequencing)
✓ Applied: imperative format + comprehensive strictness
✓ Reasoning: Multi-step analysis process - suits INSTRUCTION/PROCESS format

OUTPUT:
/analyze-codebase

INSTRUCTION: Perform comprehensive codebase analysis in sequential phases

INPUTS:
- path: Root directory to analyze (required)
- config: Analysis configuration file (optional, default: .analysis.yml)
- output: Report output format [json|html|markdown] (optional, default: markdown)
- exclude: Patterns to exclude from analysis (optional)

PROCESS:
Phase 1: Syntax Analysis
1. SCAN all source files in specified path
2. IDENTIFY file types by extension
3. FOR EACH file:
   - PARSE using language-specific parser
   - COLLECT syntax errors with line numbers
   - TRACK warning-level issues
4. IF errors found THEN log to phase1_errors.log
5. PROCEED only if no blocking errors

Phase 2: Code Quality Analysis
1. LOAD code smell detection rules
2. FOR EACH validated file:
   - CHECK for duplicated code blocks
   - IDENTIFY complex methods (cyclomatic complexity > 10)
   - DETECT anti-patterns specific to language
   - MEASURE code coverage if tests present
3. AGGREGATE findings by severity
4. CALCULATE quality score per file

Phase 3: Report Generation
1. COMPILE all findings from Phase 1 and 2
2. GENERATE metrics:
   - Total lines of code
   - Technical debt estimation
   - Complexity distribution
   - Issue density by module
3. CREATE visualizations if HTML output
4. FORMAT report according to output parameter
5. WRITE report to specified location

OUTPUT FORMAT:
```
Code Analysis Report
Generated: [timestamp]

Phase 1: Syntax Results
- Files Scanned: X
- Syntax Errors: Y
- Warnings: Z

Phase 2: Quality Findings
- Critical Issues: A
- Major Issues: B
- Minor Issues: C
- Quality Score: X/100

Phase 3: Metrics
[Detailed metrics table]
```

RULES:
- MUST complete each phase before proceeding
- NEVER analyze binary files
- SHOULD respect .gitignore patterns by default
- MUST handle large codebases incrementally
- ALWAYS provide progress indicators
```

### Example 4: Auto-Detects Security Concerns
```bash
INPUT:
/optimize-command "
/rotate-keys
Updates API keys and certificates. Handles sensitive credential rotation.
Requires admin authentication. Modifies production secrets.
"

ANALYSIS:
✓ Found security indicators: "keys", "certificates", "credential", "authentication", "secrets"
✓ Found state modification: "Updates", "Modifies", "production"
✓ Detected: Security-critical state modification
✓ Applied: contract format + comprehensive strictness
✓ Reasoning: Security-sensitive command modifying production - requires maximum safety

OUTPUT:
CONTRACT: Secure Key Rotation Command

GIVEN: Valid admin credentials and keys to rotate
WHEN: The /rotate-keys command is invoked with proper authorization
THEN: Keys are rotated securely with zero downtime

PRECONDITIONS:
✓ User has admin-level authentication
✓ Multi-factor authentication completed
✓ Audit logging is enabled
✓ Backup of current keys exists
✓ No active operations using current keys
✓ Key rotation window is open
✓ All dependent services notified

ACTIONS:
→ Verify admin authorization
→ Create encrypted backup of current keys
→ Generate new keys with proper entropy
→ Update keys in secure vault
→ Propagate to dependent services
→ Verify service connectivity
→ Mark old keys for deprecation
→ Update audit log

POSTCONDITIONS:
✓ New keys are active in all systems
✓ Old keys remain valid for grace period
✓ All services operational with new keys
✓ Audit trail complete with timestamp
✓ Backup is encrypted and stored
✓ Rollback plan is documented

INVARIANTS:
• Zero downtime during rotation
• Keys never exposed in logs
• Audit trail is immutable
• Encryption at rest and in transit

SECURITY CONSTRAINTS:
- MUST use hardware security module if available
- NEVER log key values
- ALWAYS use secure random generation
- MUST notify security team on completion
- REQUIRES two-person authorization for production
```

## Auto-Detection Logic

The command analyzes the CONTENT of your existing command documentation to determine optimal format:

### 🔍 What It Looks For:

1. **State Modification** → `contract + comprehensive`
    - Words like: saves, writes, updates, modifies, deletes, deploys
    - Mentions: database, production, live system

2. **Security/Sensitive Operations** → `contract + comprehensive`
    - Words like: authenticate, encrypt, password, token, credential
    - Mentions: security, permission, secret, private key

3. **Multi-Step Processes** → `imperative + comprehensive`
    - Structure: "Phase 1... Phase 2..." or "First... Then... Finally..."
    - Words like: analyzes, scans, processes, evaluates + step indicators

4. **Complex Parameters** → `json + standard`
    - Multiple nested objects
    - Arrays of options
    - 5+ parameters with complex types

5. **Simple Queries** → `json + minimal`
    - Words like: search, find, get, list, query
    - Few parameters (<3)
    - No state modification

6. **Simple Utilities** → `structured + minimal`
    - Basic operations
    - Minimal parameters
    - No complex behavior

### 📊 Complexity Scoring:
- **Parameter Complexity** = base params + (nested × 2) + (optional × 0.5)
- **Behavior Complexity** = steps + (conditionals × 2) + error cases
- High complexity → More comprehensive documentation needed

## Constraints
- ⛔ NEVER discard existing information from the original command
- ⚠️ ALWAYS preserve original command name exactly as provided
- ✅ MUST add type information for all parameters
- ✅ MUST include at least one usage example
- 📝 SHOULD infer missing details from context when possible
- 🔍 SHOULD flag ambiguities for user review

## Error Handling
- If command_text is empty: Return "Error: No command text provided"
- If no command name detected: Return "Error: Could not identify command name (expected /command format)"
- If format_style invalid: Return "Error: Unknown format style. Use: auto, structured, xml, json, imperative, or contract"
- If parsing fails: Return partial optimization with warnings about unparseable sections

## Usage Patterns

### Quick Command Reference
```bash
# Optimise a command by name only
/command-optimise /deploy

# Optimise with specific format
/command-optimise /api-call json

# Optimise with format and strictness
/command-optimise /security-scan imperative comprehensive

# Provide full text when command isn't in registry
/command-optimise "
/custom-command - does something special
Parameters: input, output, options
Behavior: processes input and produces output
"
```

### Command Name Detection Logic
The system determines if input is a command name reference by checking:
1. Starts with "/" character
2. Contains no spaces or newlines (single token)
3. Looks like a command name pattern (/word-word)

If these conditions are met, it searches for the command documentation.
Otherwise, it treats the input as the full command text to analyze.

## Notes
- Command names are searched in the project's command registry
- If a command isn't found by name, provide the full documentation text
- Manual format/strictness override works with both name references and full text
- The optimiser analyses actual command content, not just the command name
