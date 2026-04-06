# Claude Code Permissions

Claude Code's permission system is configured in `~/.claude/settings.json` under a `permissions` object. Changes are hot-reloaded mid-session via the `ConfigChange` event — no restart required.

## Schema

```json
{
  "permissions": {
    "allow": [],
    "ask":   [],
    "deny":  []
  }
}
```

- **`allow`** — tools that run automatically without prompting the user
- **`ask`** — tools that always prompt the user for approval
- **`deny`** — tools that are blocked entirely

**Evaluation order: deny → ask → allow.** The first matching rule wins, so deny always takes precedence.

## Tool Specifiers

### Bash commands
```json
"allow": ["Bash(npm run *)"],
"deny":  ["Bash(rm *)", "Bash(git push *)"]
```

### File operations
```json
"allow": ["Read", "Edit(/docs/**)"],
"deny":  ["Edit(.env)"]
```

### Web requests
```json
"allow": ["WebFetch(domain:github.com)"]
```

### MCP tools
```json
"allow": ["mcp__puppeteer__*"]
```

### Subagents
```json
"deny": ["Agent(Explore)"]
```

## Default Mode

You can also set the baseline permission mode for a session:

```json
{
  "defaultMode": "default"
}
```

Available modes: `default`, `plan`, `auto`, `dontAsk`, `bypassPermissions`, `acceptEdits`.

## Additional Controls

- **`disableBypassPermissionsMode`**: set to `"disable"` to prevent bypass mode from being used
- **`disableAutoMode`**: set to `"disable"` to prevent auto mode from being used

## Editing Settings Safely

/update-config is a skill that helps you modify Claude Code's settings.json configuration files.

  What it does:

  It guides safe edits to one of three settings files:

  ┌─────────────────────────────┬────────────────────────────────────────┐
  │            File             │                 Scope                  │
  ├─────────────────────────────┼────────────────────────────────────────┤
  │ ~/.claude/settings.json     │ Global — applies to all projects       │
  ├─────────────────────────────┼────────────────────────────────────────┤
  │ .claude/settings.json       │ Project — shared with team via git     │
  ├─────────────────────────────┼────────────────────────────────────────┤
  │ .claude/settings.local.json │ Local — personal overrides, gitignored │
  └─────────────────────────────┴────────────────────────────────────────┘

  What you can configure:

  - Hooks — automated commands that fire on events like PostToolUse, PreCompact, Stop, etc. Example: auto-run prettier after every file edit, log all bash commands, run
   tests after code changes.
  - Permissions — allow or deny specific tool calls without prompting (e.g., Bash(git:*), Edit(.claude))
  - Environment variables — inject env vars into every session
  - Model — override the default model
  - MCP servers — enable/disable specific servers
  - Attribution — customize or remove commit/PR footers

  The skill enforces safety:
  - Always reads the existing file before writing (never clobbers your config)
  - Merges new settings into existing arrays rather than replacing them
  - Tests hook commands before writing them
  - Validates JSON syntax after changes

  Example use cases:
  "auto-format my Python files with black after every edit"
  "allow npm commands without prompting"
  "log all bash commands I run to a file"
  "set DEBUG=true for this project"

## Example: Minimal Safe Config

```json
{
  "permissions": {
    "allow": ["Read", "Bash(git status)", "Bash(git log *)"],
    "ask":   ["Edit", "Bash(git commit *)", "WebFetch"],
    "deny":  ["Bash(rm *)", "Bash(git push --force*)"]
  }
}
```
