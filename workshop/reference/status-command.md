# Claude Code Status Line

This document has two sections:

1. **Quick reference** — setup, available JSON fields, and a test command. This is the section that covers everything needed for myClaude's current status line implementation (`custom/statusline-command.sh`).
2. **Deep dive** — full JSON structure, detailed field explanations, script examples in multiple languages, caching strategies, and troubleshooting.

---

# Quick Reference

> Official documentation: https://docs.anthropic.com/en/docs/claude-code/statusline
> https://code.claude.com/docs/en/statusline

## What It Is

The status line is a customizable bar at the bottom of the Claude Code interface. It runs a shell script you configure, receives JSON session data via stdin, and displays whatever the script prints. It updates after every assistant message.

## Setup

Add a `statusLine` field to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

Make the script executable:

```bash
chmod +x ~/.claude/statusline.sh
```

Alternatively, use the `/statusline` slash command and describe what you want in natural language — Claude Code generates the script and updates settings automatically.

## How It Works

Claude Code pipes a JSON object to your script via stdin on every update. Your script reads the JSON, extracts fields, and prints to stdout. Whatever you print appears in the status bar.

**When it updates:** after each assistant message, on permission mode change, on vim mode toggle. Updates are debounced at 300ms.

**Script output:**
- Single or multiple lines (each `echo` = one row)
- ANSI color codes (`\033[32m` = green, `\033[0m` = reset)
- OSC 8 clickable links (requires iTerm2, Kitty, or WezTerm)

## Available JSON Fields

| Field | Description |
|---|---|
| `model.display_name` | Model name, e.g. `Sonnet 4.6` |
| `model.id` | Model ID, e.g. `claude-sonnet-4-6` |
| `cwd` / `workspace.current_dir` | Current working directory (updates as you `cd`) |
| `workspace.project_dir` | Directory where Claude Code was launched (static) |
| `workspace.added_dirs` | Extra dirs added via `/add-dir` |
| `cost.total_cost_usd` | Session cost in USD |
| `cost.total_duration_ms` | Total elapsed time in ms since session start |
| `cost.total_api_duration_ms` | Time spent waiting for API responses in ms |
| `cost.total_lines_added` | Lines of code added this session |
| `cost.total_lines_removed` | Lines of code removed this session |
| `context_window.used_percentage` | % of context window used |
| `context_window.remaining_percentage` | % of context window remaining |
| `context_window.context_window_size` | Max tokens (200k or 1M) |
| `context_window.total_input_tokens` | Cumulative input tokens for the session |
| `context_window.total_output_tokens` | Cumulative output tokens for the session |
| `context_window.current_usage` | Token counts from the last API call only |
| `exceeds_200k_tokens` | Boolean: true when total tokens exceed 200k |
| `rate_limits.five_hour.used_percentage` | 5-hour rate limit consumed (Pro/Max only) |
| `rate_limits.five_hour.resets_at` | Unix timestamp when 5-hour window resets |
| `rate_limits.seven_day.used_percentage` | 7-day rate limit consumed (Pro/Max only) |
| `rate_limits.seven_day.resets_at` | Unix timestamp when 7-day window resets |
| `session_id` | Unique session identifier |
| `session_name` | Custom name set with `--name` or `/rename` (absent if not set) |
| `vim.mode` | `NORMAL` or `INSERT` when vim mode is on (absent if off) |
| `worktree.name` / `.path` / `.branch` | Worktree info (absent unless `--worktree` session) |
| `transcript_path` | Path to the conversation transcript file |
| `version` | Claude Code version |
| `output_style.name` | Current output style name |

## Testing

```bash
echo '{"model":{"display_name":"Sonnet 4.6"},"context_window":{"used_percentage":25},"cost":{"total_cost_usd":0.05}}' | ~/.claude/statusline.sh
```

## Disabling

Run `/statusline remove` or delete the `statusLine` key from `~/.claude/settings.json`.

---

# Deep Dive

## Official URLs

- **Primary docs:** https://code.claude.com/docs/en/statusline
- **Canonical (redirects to above):** https://docs.anthropic.com/en/docs/claude-code/statusline
- **Settings reference:** https://code.claude.com/docs/en/settings
- **Output styles:** https://code.claude.com/docs/en/output-styles

---

## What It Is

The status line is a customizable bar at the bottom of Claude Code. It runs any shell script you configure. Claude Code pipes JSON session data to your script via stdin; whatever your script prints to stdout gets displayed.

Useful for:
- Monitoring context window usage as you work
- Tracking session costs
- Distinguishing multiple sessions
- Keeping git branch and status always visible

---

## How to Set It Up

### Option 1: `/statusline` command (automatic)

Use the slash command with a natural language description:

```
/statusline show model name and context percentage with a progress bar
```

Claude Code generates a script in `~/.claude/` and updates your settings automatically.

### Option 2: Manual configuration

Add a `statusLine` field to `~/.claude/settings.json` (user settings) or your project's `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 2
  }
}
```

Fields:
- `type`: must be `"command"`
- `command`: path to a script file, or an inline shell command
- `padding`: optional, adds extra horizontal spacing in characters (default `0`)

Inline command example using `jq`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"[\\(.model.display_name)] \\(.context_window.used_percentage // 0)% context\"'"
  }
}
```

### Disable it

Run `/statusline delete` (or `/statusline clear` / `/statusline remove it`), or manually delete the `statusLine` key from your settings.json.

---

## How It Works

1. After each assistant message, when permission mode changes, or when vim mode toggles, Claude Code runs your configured command.
2. JSON session data is piped to the command's stdin.
3. Your script reads the JSON, extracts what it needs, and prints to stdout.
4. Claude Code displays whatever your script printed.

**Debouncing:** updates are debounced at 300ms. Rapid changes batch together; your script runs once things settle.

**Cancellation:** if a new update triggers while your script is still running, the in-flight execution is cancelled.

**Cost:** runs locally, consumes no API tokens.

**Visibility:** temporarily hides during autocomplete suggestions, the help menu, and permission prompts.

**Trust requirement:** the status line only runs if you have accepted the workspace trust dialog. If trust is not accepted, you will see `statusline skipped · restart to fix`.

---

## Available JSON Data

Claude Code sends this JSON structure to your script via stdin:

```json
{
  "cwd": "/current/working/directory",
  "session_id": "abc123...",
  "session_name": "my-session",
  "transcript_path": "/path/to/transcript.jsonl",
  "model": {
    "id": "claude-opus-4-6",
    "display_name": "Opus"
  },
  "workspace": {
    "current_dir": "/current/working/directory",
    "project_dir": "/original/project/directory",
    "added_dirs": []
  },
  "version": "2.1.90",
  "output_style": {
    "name": "default"
  },
  "cost": {
    "total_cost_usd": 0.01234,
    "total_duration_ms": 45000,
    "total_api_duration_ms": 2300,
    "total_lines_added": 156,
    "total_lines_removed": 23
  },
  "context_window": {
    "total_input_tokens": 15234,
    "total_output_tokens": 4521,
    "context_window_size": 200000,
    "used_percentage": 8,
    "remaining_percentage": 92,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  },
  "exceeds_200k_tokens": false,
  "rate_limits": {
    "five_hour": {
      "used_percentage": 23.5,
      "resets_at": 1738425600
    },
    "seven_day": {
      "used_percentage": 41.2,
      "resets_at": 1738857600
    }
  },
  "vim": {
    "mode": "NORMAL"
  },
  "agent": {
    "name": "security-reviewer"
  },
  "worktree": {
    "name": "my-feature",
    "path": "/path/to/.claude/worktrees/my-feature",
    "branch": "worktree-my-feature",
    "original_cwd": "/path/to/project",
    "original_branch": "main"
  }
}
```

### Field Reference

| Field | Description |
|-------|-------------|
| `model.id`, `model.display_name` | Current model identifier and display name |
| `cwd`, `workspace.current_dir` | Current working directory (both are the same; prefer `workspace.current_dir`) |
| `workspace.project_dir` | Directory where Claude Code was launched (may differ from `cwd` if the working directory changes) |
| `workspace.added_dirs` | Additional directories added via `/add-dir` or `--add-dir`; empty array if none |
| `cost.total_cost_usd` | Total session cost in USD |
| `cost.total_duration_ms` | Total wall-clock time since session started, in milliseconds |
| `cost.total_api_duration_ms` | Total time spent waiting for API responses, in milliseconds |
| `cost.total_lines_added`, `cost.total_lines_removed` | Lines of code changed |
| `context_window.total_input_tokens`, `context_window.total_output_tokens` | Cumulative token counts across the session |
| `context_window.context_window_size` | Maximum context window size in tokens (200000 by default; 1000000 for extended-context models) |
| `context_window.used_percentage` | Pre-calculated percentage of context window used |
| `context_window.remaining_percentage` | Pre-calculated percentage of context window remaining |
| `context_window.current_usage` | Token counts from the last API call (null before first API call) |
| `exceeds_200k_tokens` | Whether total token count from the most recent response exceeds 200k (fixed threshold) |
| `rate_limits.five_hour.used_percentage`, `rate_limits.seven_day.used_percentage` | Percentage of the 5-hour or 7-day rate limit consumed (0–100) |
| `rate_limits.five_hour.resets_at`, `rate_limits.seven_day.resets_at` | Unix epoch seconds when the rate limit window resets |
| `session_id` | Unique session identifier |
| `session_name` | Custom session name (set with `--name` or `/rename`; absent if not set) |
| `transcript_path` | Path to conversation transcript file |
| `version` | Claude Code version |
| `output_style.name` | Name of the current output style |
| `vim.mode` | Current vim mode (`NORMAL` or `INSERT`; present only when vim mode is enabled) |
| `agent.name` | Agent name (present only when running with `--agent` flag or agent settings configured) |
| `worktree.name` | Active worktree name (present only during `--worktree` sessions) |
| `worktree.path` | Absolute path to the worktree directory |
| `worktree.branch` | Git branch name for the worktree (absent for hook-based worktrees) |
| `worktree.original_cwd` | Directory Claude was in before entering the worktree |
| `worktree.original_branch` | Git branch checked out before entering the worktree (absent for hook-based worktrees) |

### Fields That May Be Absent

- `session_name`: only present when a custom name has been set
- `vim`: only present when vim mode is enabled
- `agent`: only present with `--agent` flag or agent settings
- `worktree`: only present during `--worktree` sessions
- `rate_limits`: only present for Claude.ai subscribers (Pro/Max) after the first API response

### Fields That May Be `null`

- `context_window.current_usage`: null before the first API call
- `context_window.used_percentage`, `context_window.remaining_percentage`: may be null early in the session

Always use fallback defaults in scripts: `// 0` in jq, `or 0` in Python, `|| 0` in Node.js.

### Context Window Fields Explained

The `context_window` object has two ways to track usage:

- **Cumulative totals** (`total_input_tokens`, `total_output_tokens`): sum of all tokens across the entire session. Can exceed context window size.
- **Current usage** (`current_usage`): token counts from the most recent API call. Use this for accurate context percentage.

`current_usage` sub-fields:
- `input_tokens`: input tokens in current context
- `output_tokens`: output tokens generated
- `cache_creation_input_tokens`: tokens written to cache
- `cache_read_input_tokens`: tokens read from cache

`used_percentage` is calculated from input tokens only: `input_tokens + cache_creation_input_tokens + cache_read_input_tokens`. Output tokens are excluded. If you calculate it manually, use the same formula.

---

## What Your Script Can Output

- **Multiple lines**: each `echo` / `print` statement creates a separate row in the status area.
- **ANSI colors**: use escape codes like `\033[32m` for green, `\033[0m` to reset. Terminal must support them.
- **Clickable links**: use OSC 8 escape sequences. Requires a terminal that supports hyperlinks (iTerm2, Kitty, WezTerm). Use Cmd+click on macOS or Ctrl+click on Windows/Linux.

---

## Script Examples

### Quick start: model + directory + context %

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

echo "[$MODEL] 📁 ${DIR##*/} | ${PCT}% context"
```

### Context window progress bar (Bash)

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

echo "[$MODEL] $BAR $PCT%"
```

### Context window progress bar (Python)

```python
#!/usr/bin/env python3
import json, sys

data = json.load(sys.stdin)
model = data['model']['display_name']
pct = int(data.get('context_window', {}).get('used_percentage', 0) or 0)

filled = pct * 10 // 100
bar = '▓' * filled + '░' * (10 - filled)

print(f"[{model}] {bar} {pct}%")
```

### Context window progress bar (Node.js)

```javascript
#!/usr/bin/env node
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
    const data = JSON.parse(input);
    const model = data.model.display_name;
    const pct = Math.floor(data.context_window?.used_percentage || 0);

    const filled = Math.floor(pct * 10 / 100);
    const bar = '▓'.repeat(filled) + '░'.repeat(10 - filled);

    console.log(`[${model}] ${bar} ${pct}%`);
});
```

### Git status with colors (Bash)

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')

GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')

    GIT_STATUS=""
    [ "$STAGED" -gt 0 ] && GIT_STATUS="${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ] && GIT_STATUS="${GIT_STATUS}${YELLOW}~${MODIFIED}${RESET}"

    echo -e "[$MODEL] 📁 ${DIR##*/} | 🌿 $BRANCH $GIT_STATUS"
else
    echo "[$MODEL] 📁 ${DIR##*/}"
fi
```

### Cost and duration tracking (Bash)

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

COST_FMT=$(printf '$%.2f' "$COST")
DURATION_SEC=$((DURATION_MS / 1000))
MINS=$((DURATION_SEC / 60))
SECS=$((DURATION_SEC % 60))

echo "[$MODEL] 💰 $COST_FMT | ⏱️ ${MINS}m ${SECS}s"
```

### Multi-line with color-coded context bar (Bash)

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH"
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${YELLOW}${COST_FMT}${RESET} | ⏱️ ${MINS}m ${SECS}s"
```

### Clickable GitHub link (Bash)

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')

REMOTE=$(git remote get-url origin 2>/dev/null | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')

if [ -n "$REMOTE" ]; then
    REPO_NAME=$(basename "$REMOTE")
    # OSC 8 format: \e]8;;URL\a TEXT \e]8;;\a
    printf '%b' "[$MODEL] 🔗 \e]8;;${REMOTE}\a${REPO_NAME}\e]8;;\a\n"
else
    echo "[$MODEL]"
fi
```

### Rate limit usage (Bash)

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

LIMITS=""
[ -n "$FIVE_H" ] && LIMITS="5h: $(printf '%.0f' "$FIVE_H")%"
[ -n "$WEEK" ] && LIMITS="${LIMITS:+$LIMITS }7d: $(printf '%.0f' "$WEEK")%"

[ -n "$LIMITS" ] && echo "[$MODEL] | $LIMITS" || echo "[$MODEL]"
```

### Caching slow operations (Bash)

Scripts run frequently; cache slow commands like `git status` to avoid lag. Use a fixed cache filename—do not use `$$` or `$PID` because each invocation is a new process and the cache would never be reused.

```bash
#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')

CACHE_FILE="/tmp/statusline-git-cache"
CACHE_MAX_AGE=5  # seconds

cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] || \
    [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

if cache_is_stale; then
    if git rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH=$(git branch --show-current 2>/dev/null)
        STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        MODIFIED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        echo "$BRANCH|$STAGED|$MODIFIED" > "$CACHE_FILE"
    else
        echo "||" > "$CACHE_FILE"
    fi
fi

IFS='|' read -r BRANCH STAGED MODIFIED < "$CACHE_FILE"

if [ -n "$BRANCH" ]; then
    echo "[$MODEL] 📁 ${DIR##*/} | 🌿 $BRANCH +$STAGED ~$MODIFIED"
else
    echo "[$MODEL] 📁 ${DIR##*/}"
fi
```

### Windows (PowerShell)

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -File C:/Users/username/.claude/statusline.ps1"
  }
}
```

```powershell
$input_json = $input | Out-String | ConvertFrom-Json
$cwd = $input_json.cwd
$model = $input_json.model.display_name
$used = $input_json.context_window.used_percentage
$dirname = Split-Path $cwd -Leaf

if ($used) {
    Write-Host "$dirname [$model] ctx: $used%"
} else {
    Write-Host "$dirname [$model]"
}
```

---

## Tips

- **Test with mock input:** `echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":25}}' | ./statusline.sh`
- **Keep output short:** the status bar has limited width; long output may be truncated or wrap.
- **Cache slow operations:** `git status` and similar commands can cause lag since the script runs after every message.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Status line not appearing | Verify script is executable (`chmod +x`). Check output goes to stdout, not stderr. Check `disableAllHooks` is not `true`. Run `claude --debug` to see exit codes. |
| Shows `--` or empty values | Fields are null before the first API response. Use fallbacks like `// 0` in jq. |
| Workspace trust not accepted | You will see `statusline skipped · restart to fix`. Restart and accept the trust prompt. |
| Context percentage unexpected | Use `used_percentage`, not cumulative `total_input_tokens`. Cumulative totals can exceed context window size. |
| OSC 8 links not clickable | Terminal must support OSC 8 (iTerm2, Kitty, WezTerm). Terminal.app does not. SSH/tmux may strip OSC sequences. Use `printf '%b'` not `echo -e`. |
| Display glitches / garbled text | Simplify to plain text output. Multi-line + escape codes is most prone to rendering issues. |
| Script errors or hangs | Non-zero exit code or no output causes status line to go blank. Test your script independently first. Slow scripts block updates until they finish. |
| Notifications truncate status line | System notifications (MCP errors, auto-updates, token warnings) share the same row. On narrow terminals they may cut off your output. |
