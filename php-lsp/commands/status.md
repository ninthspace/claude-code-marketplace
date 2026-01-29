# /php-lsp:status Command

Check the status of the PHP LSP integration — whether the MCP server is loaded, the PHP language server is running, and intelephense is installed.

## Usage

```bash
/php-lsp:status
```

## Implementation

### Step 1: Check intelephense installation

1. Run `npm list -g intelephense` via Bash.
2. Record whether it's installed and the version.

### Step 2: Check lsp-mcp-server installation

1. Check if `~/.local/share/lsp-mcp-server/dist/index.js` exists via Bash.
2. Record whether it's built and ready.

### Step 3: Check project configuration

1. Read `.mcp.json` in the project root.
2. Check if the `"lsp"` key exists under `mcpServers`.
3. Read `.claude/settings.local.json` in the project root.
4. Check if `"lsp"` is in `enabledMcpjsonServers`.

### Step 4: Check running servers

1. Run `lsp_server_status` to check if the MCP server is loaded and if the PHP server is running.

### Step 5: Report

Print a diagnostic summary:

```
PHP LSP Status
──────────────────────────────────
  intelephense:     <installed version | NOT INSTALLED>
  lsp-mcp-server:   <built | NOT FOUND>
  .mcp.json:        <configured | NOT CONFIGURED>
  settings:         <enabled | NOT ENABLED>
  MCP server:       <loaded | NOT LOADED>
  PHP server:       <running | stopped>
──────────────────────────────────

<any recommended actions, e.g. "Run /php-lsp:setup to configure" or "Restart Claude Code to load the MCP server" or "Run /php-lsp:start to start the PHP server">
```
