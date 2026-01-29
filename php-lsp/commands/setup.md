# /php-lsp:setup Command

Set up PHP LSP (intelephense) integration for the current project via the lsp-mcp-server MCP bridge. This enables semantic code intelligence for PHP files in Claude Code — go-to-definition, find references, hover info, diagnostics, rename, code actions, and more.

## Usage

```bash
/php-lsp:setup
```

## Implementation

Execute ALL of the following steps in order. Do not skip steps. Report progress as you go.

### Step 1: Check prerequisites

1. Run `node --version` to verify Node.js >= 18 is available.
2. If Node.js is missing or too old, stop and tell the user:
   ```
   Node.js 18+ is required. Install it from https://nodejs.org or via your package manager.
   ```

### Step 2: Ensure intelephense is installed globally

1. Run `npm list -g intelephense` to check if it is already installed.
2. If NOT installed, run `npm install -g intelephense` to install it.
3. Confirm installation succeeded by running `npm list -g intelephense`.
4. Report the installed version.

### Step 3: Ensure lsp-mcp-server is installed

The lsp-mcp-server bridges Claude Code (MCP) to language servers (LSP). It must be cloned and built once.

**Default location:** `~/.local/share/lsp-mcp-server`

1. Check if `~/.local/share/lsp-mcp-server/dist/index.js` exists.
2. If it does NOT exist:
   a. Create the parent directory if needed: `mkdir -p ~/.local/share`
   b. Check if the repo directory exists at all (`~/.local/share/lsp-mcp-server`).
   c. If the directory does not exist, clone it:
      ```bash
      git clone https://github.com/ProfessioneIT/lsp-mcp-server.git ~/.local/share/lsp-mcp-server
      ```
   d. Install dependencies and build:
      ```bash
      cd ~/.local/share/lsp-mcp-server && npm install && npm run build
      ```
3. Verify `~/.local/share/lsp-mcp-server/dist/index.js` now exists. If not, stop and report the error.
4. Resolve the absolute path for the `dist/index.js` file — you will need it in the next step.

### Step 4: Add `lsp` MCP server to the project's `.mcp.json`

1. Read the current project's `.mcp.json` file (in the project root / current working directory).
2. If `.mcp.json` does not exist, create it with an empty `mcpServers` object.
3. If the `"lsp"` key already exists under `mcpServers`, skip this step and report it's already configured.
4. If the `"lsp"` key does NOT exist, add it using the resolved absolute path from Step 3:
   ```json
   "lsp": {
     "command": "node",
     "args": ["<absolute-path-to>/lsp-mcp-server/dist/index.js"],
     "env": {
       "LSP_MCP_LOG_LEVEL": "info"
     }
   }
   ```
   Preserve all existing `mcpServers` entries — only add `"lsp"` alongside them.

### Step 5: Enable the LSP server in `.claude/settings.local.json`

1. Read `.claude/settings.local.json` in the project root. If it doesn't exist, create it.
2. Ensure `"enableAllProjectMcpServers": true` is set.
3. Ensure `"lsp"` is in the `enabledMcpjsonServers` array (add if missing, don't duplicate).
4. Ensure at minimum these permissions are in the `permissions.allow` array (add any that are missing, don't duplicate):
   - `"mcp__lsp__lsp_find_symbol"`
   - `"mcp__lsp__lsp_server_status"`
   - `"mcp__lsp__lsp_start_server"`
   - `"mcp__lsp__lsp_stop_server"`
   - `"mcp__lsp__lsp_document_symbols"`
   - `"mcp__lsp__lsp_hover"`
   - `"mcp__lsp__lsp_goto_definition"`
   - `"mcp__lsp__lsp_goto_type_definition"`
   - `"mcp__lsp__lsp_find_references"`
   - `"mcp__lsp__lsp_find_implementations"`
   - `"mcp__lsp__lsp_workspace_symbols"`
   - `"mcp__lsp__lsp_diagnostics"`
   - `"mcp__lsp__lsp_workspace_diagnostics"`
   - `"mcp__lsp__lsp_completions"`
   - `"mcp__lsp__lsp_call_hierarchy"`
   - `"mcp__lsp__lsp_type_hierarchy"`
   - `"mcp__lsp__lsp_code_actions"`
   - `"mcp__lsp__lsp_rename"`
   - `"mcp__lsp__lsp_smart_search"`
   - `"mcp__lsp__lsp_file_exports"`
   - `"mcp__lsp__lsp_file_imports"`
   - `"mcp__lsp__lsp_related_files"`
   - `"mcp__lsp__lsp_format_document"`
   - `"mcp__lsp__lsp_signature_help"`

### Step 6: Report results

Print a summary of what was done:

```
PHP LSP setup complete.

  intelephense: <version>
  lsp-mcp-server: ~/.local/share/lsp-mcp-server
  .mcp.json: lsp server configured
  .claude/settings.local.json: lsp enabled + 24 tool permissions granted

IMPORTANT — Restart Claude Code now.
The MCP server won't load until you restart the session.
After restart, the PHP server auto-starts on first use of any LSP tool.
```

## Notes

- This command modifies `.mcp.json` and `.claude/settings.local.json`. It preserves all existing content and only adds what's missing.
- The lsp-mcp-server supports 8 languages (TypeScript, Python, Rust, Go, C/C++, Ruby, PHP, Elixir). Once configured, other language servers work too if installed globally.
- After setup, a Claude Code restart is required for the MCP server to load.
