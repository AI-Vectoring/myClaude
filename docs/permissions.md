# Claude Code Permissions

Claude Code's permission system is configured in `~/.claude/settings.json` under a `permissions` object. Changes take effect on the next session launch.

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
