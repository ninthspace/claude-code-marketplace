# PHP LSP Plugin for Claude Code

Adds PHP semantic code intelligence to Claude Code via [intelephense](https://intelephense.com/) and the [lsp-mcp-server](https://github.com/ProfessioneIT/lsp-mcp-server) bridge.

## What you get

Once set up, Claude Code can use 24 LSP tools for PHP files:

| Tool | What it does |
|------|-------------|
| `lsp_goto_definition` | Jump to where a symbol is defined |
| `lsp_goto_type_definition` | Jump to the type/interface of a variable |
| `lsp_find_references` | Find all usages of a symbol across the codebase |
| `lsp_find_implementations` | Find concrete implementations of an interface |
| `lsp_hover` | Get type info and documentation for a symbol |
| `lsp_signature_help` | Get function parameter hints |
| `lsp_document_symbols` | List all methods, properties, constants in a file |
| `lsp_workspace_symbols` | Search for any symbol by name across the project |
| `lsp_find_symbol` | Find a symbol by name with full context |
| `lsp_smart_search` | Combined definition + references + hover in one call |
| `lsp_completions` | Get code completion suggestions |
| `lsp_diagnostics` | Get errors/warnings for a file |
| `lsp_workspace_diagnostics` | Get errors/warnings across the project |
| `lsp_rename` | Safely rename a symbol across the codebase |
| `lsp_code_actions` | Get quick fixes and refactoring suggestions |
| `lsp_call_hierarchy` | See who calls a function and what it calls |
| `lsp_type_hierarchy` | Explore class inheritance trees |
| `lsp_file_exports` | Get the public API of a file |
| `lsp_file_imports` | See what a file depends on |
| `lsp_related_files` | Find connected files (imports/imported by) |
| `lsp_format_document` | Format code using the language server |
| `lsp_server_status` | Check running language servers |
| `lsp_start_server` | Start a language server manually |
| `lsp_stop_server` | Stop a running language server |

## Prerequisites

- **Node.js** >= 18
- **Git** (for cloning lsp-mcp-server)

## Installation

### Via Claude Code Marketplace

```bash
/plugin marketplace add ninthspace/claude-code-marketplace
/plugin install php-lsp@claude-code-marketplace
```

### Manual

Copy the `php-lsp/` directory into your Claude Code plugins location.

## Commands

### `/php-lsp:setup`

One-time setup for a project. Installs all dependencies and configures the project:

1. Installs `intelephense` globally via npm (if not already installed)
2. Clones and builds `lsp-mcp-server` to `~/.local/share/lsp-mcp-server` (if not already present)
3. Adds the `"lsp"` MCP server entry to the project's `.mcp.json`
4. Enables the server and grants all LSP tool permissions in `.claude/settings.local.json`

After running setup, **restart Claude Code** for the MCP server to load. The PHP server auto-starts on first use of any LSP tool.

### `/php-lsp:status`

Diagnostic command that checks every layer of the setup:
- Is intelephense installed?
- Is lsp-mcp-server built?
- Is `.mcp.json` configured?
- Is the MCP server loaded in the current session?
- Is the PHP language server running?

## How it works

```
┌─────────────┐      ┌──────────────────┐      ┌───────────────┐
│ Claude Code  │────▶│  lsp-mcp-server  │────▶│ intelephense  │
│   (MCP)      │◀────│   (bridge)       │◀────│  (PHP LSP)    │
└─────────────┘      └──────────────────┘      └───────────────┘
      stdio              stdio/JSON-RPC            stdio
```

- **Claude Code** calls LSP tools via the MCP protocol
- **lsp-mcp-server** translates MCP tool calls into LSP JSON-RPC requests
- **intelephense** provides PHP-specific code intelligence

## Bonus: Other languages

The lsp-mcp-server supports 8 languages out of the box. Once installed via this plugin, you also get LSP support for TypeScript, Python, Rust, Go, C/C++, Ruby, and Elixir — just install their language servers globally:

```bash
npm install -g typescript-language-server typescript  # TypeScript/JS
pip install python-lsp-server                         # Python
rustup component add rust-analyzer                    # Rust
go install golang.org/x/tools/gopls@latest            # Go
brew install llvm                                     # C/C++ (macOS)
gem install solargraph                                 # Ruby
```

## License

MIT
