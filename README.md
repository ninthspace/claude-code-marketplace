# Story-Driven Development Marketplace

A Claude Code plugin marketplace providing comprehensive tools for story-driven agile development workflows.

## Overview

This marketplace contains plugins that enable complete story-driven development workflows, from ideation through production deployment. All tools are designed to work seamlessly with Claude Code and can be installed individually or as a complete suite.

## Installation

### Install from Marketplace

```bash
# Install the entire marketplace (all plugins)
claude install marketplace /path/to/story-marketplace

# Or from GitHub (once published)
claude install marketplace https://github.com/yourusername/story-marketplace
```

### Install Individual Plugin

```bash
# Install just the story-driven-development plugin
claude install plugin https://github.com/yourusername/story-marketplace/plugins/story-driven-development
```

## Available Plugins

### Story-Driven Development (v1.0.0)

**30+ commands for complete agile development workflow**

A comprehensive plugin providing:
- Project setup and initialization
- Story management and tracking
- Development workflow automation
- Code review and quality checks
- Automated testing and QA
- Deployment and rollback
- Metrics and analysis
- Daily workflow helpers

**Key Features:**
- Context-aware commands that adapt to your tech stack
- Git integration for version control
- Automated testing support
- Browser testing (Playwright/Pest)
- Progressive enhancement with project context
- Works immediately, no configuration required

**Tech Stack Support:**
- Laravel/TALL stack
- React/Next.js
- Vue.js
- Node.js/Express
- Python/Django
- Ruby on Rails
- Any tech stack with adaptation

**Quick Start:**
```bash
/story-new "Add user authentication"
/story-start STORY-2024-001
/story-implement STORY-2024-001
/story-save "Implement user authentication"
/story-review STORY-2024-001
/story-qa STORY-2024-001
/story-validate STORY-2024-001
/story-ship STORY-2024-001
```

[View full documentation](./plugins/story-driven-development/README.md)

## Marketplace Structure

```
story-marketplace/
├── .claude-plugin/
│   └── marketplace.json     # Marketplace manifest
├── plugins/
│   └── story-driven-development/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── commands/        # 30+ command files
│       ├── README.md
│       ├── LICENSE
│       └── CHANGELOG.md
├── README.md                # This file
└── LICENSE
```

## Using the Plugins

### Core Workflow

1. **Create Story**: Define what you're building
2. **Start Development**: Create branch and setup
3. **Implement**: Generate code with AI assistance
4. **Save**: Commit with formatted messages
5. **Review**: Quality checks and refactoring
6. **QA**: Automated testing
7. **Validate**: Final checks before shipping
8. **Ship**: Deploy to production

### Command Categories

- **📦 Project Setup** - Initialize projects and manage context
- **📝 Story Management** - Create, track, and manage stories
- **🛠️ Development** - Start, implement, and save work
- **🔍 Review** - Quality checks and refactoring
- **✅ QA & Testing** - Automated testing and validation
- **🚀 Shipping** - Deploy features and handle rollbacks
- **📊 Analysis** - Metrics, patterns, and technical debt
- **📅 Daily Workflow** - Daily standup and planning

## Requirements

- **Claude Code CLI** - Required for all plugins
- **Git** - Required for version control commands
- **Test Framework** - Required for QA commands (project-specific)

## Optional Configuration

For best results, create a `/project-context/` directory in your project with:

- `technical-stack.md` - Your technology choices and versions
- `coding-standards.md` - Your coding standards and conventions
- `development-process.md` - Your workflow stages and criteria

The plugins will automatically read these files and adapt their behavior to match your project's needs.

## Key Principles

- **No Prerequisites**: Commands work immediately with smart defaults
- **Tech Stack Agnostic**: Adapts to your actual technology choices
- **Context-Aware**: Reads project configuration when available
- **Independent**: Each command works standalone
- **Full Lifecycle**: From idea to production deployment

## Publishing Plugins

To contribute a new plugin to this marketplace:

1. Create your plugin following the [plugin structure](https://docs.claude.com/en/docs/claude-code/plugins)
2. Place it in `plugins/your-plugin-name/`
3. Update `marketplace.json` to include your plugin
4. Submit a pull request with documentation

## Future Plugins

This marketplace is designed to grow. Future plugin categories may include:

- **Testing Tools** - Advanced test generation and coverage
- **Documentation Generators** - Automated documentation creation
- **Code Quality** - Linting, formatting, and analysis
- **CI/CD Integration** - Pipeline automation and deployment
- **Team Collaboration** - PR templates, review workflows
- **Performance Monitoring** - Benchmarking and profiling

## License

MIT - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please:
1. Follow the existing plugin structure
2. Include comprehensive documentation
3. Add tests where applicable
4. Update the marketplace manifest
5. Submit a pull request

## Support

For issues or questions:
- Open an issue on GitHub
- Check plugin-specific documentation
- Review the [Claude Code plugin docs](https://docs.claude.com/en/docs/claude-code/plugins)

## Changelog

See individual plugin CHANGELOG.md files for version history.

## Author

Chris Aves

## Links

- [Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Marketplace Documentation](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
