# Plugins

> Official documentation: https://code.claude.com/docs/en/plugins

Plugins package skills, agents, hooks, and MCP servers into a distributable unit. They are installed globally and available across all projects. Skills inside a plugin are namespaced: `/plugin-name:skill-name`.

## Directory structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json         # Required manifest
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
├── commands/               # Legacy, same as skills/
├── agents/
│   └── <agent-name>.md
├── hooks/
│   └── hooks.json
├── CLAUDE.md               # Loaded into context when plugin is active
├── AGENTS.md               # Same as CLAUDE.md for other harnesses
└── .mcp.json               # MCP server configuration
```

## plugin.json

```json
{
  "name": "my-plugin",
  "description": "What this plugin does",
  "version": "1.0.0",
  "author": { "name": "Your Name" }
}
```

The `name` field becomes the namespace prefix for all skills: a skill in `skills/hello/` becomes `/my-plugin:hello`.

## Installation

Plugins are installed from marketplaces or local directories:

```bash
# From a marketplace
/plugin install plugin-name

# Local development/testing
claude --plugin-dir ./my-plugin
```

Use `/reload-plugins` to pick up changes without restarting.

## CLAUDE.md in plugins

Any `CLAUDE.md` at the plugin root is automatically loaded into context every session while the plugin is installed. Same for `AGENTS.md` (used by Codex and other harnesses). This is a common source of context pollution — if a plugin ships contributor guidelines or irrelevant content in its `CLAUDE.md`, it loads every session.

myClaude addresses this by symlinking plugin `CLAUDE.md` files to controlled versions in `myClaude/plugins/<plugin>/CLAUDE.md`.

## Namespacing

Plugin skills are always namespaced to prevent conflicts between plugins. A skill named `hello` in a plugin named `my-plugin` is invoked as `/my-plugin:hello`, not `/hello`.

Standalone skills (in `~/.claude/skills/`) use short names without a namespace prefix.
