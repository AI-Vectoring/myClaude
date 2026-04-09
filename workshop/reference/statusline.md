# Claude Code Status Line

## Official Documentation

https://docs.anthropic.com/en/docs/claude-code/statusline
https://code.claude.com/docs/en/statusline

---

## What It Is

The status line is a customizable bar at the bottom of the Claude Code interface. It runs a shell script you configure, receives JSON session data via stdin, and displays whatever the script prints. It updates after every assistant message.

---

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

---

## How It Works

Claude Code pipes a JSON object to your script via stdin on every update. Your script reads the JSON, extracts fields, and prints to stdout. Whatever you print appears in the status bar.

**When it updates:** after each assistant message, on permission mode change, on vim mode toggle. Updates are debounced at 300ms.

**Script output:**
- Single or multiple lines (each `echo` = one row)
- ANSI color codes (`\033[32m` = green, `\033[0m` = reset)
- OSC 8 clickable links (requires iTerm2, Kitty, or WezTerm)

---

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

---

## Testing

```bash
echo '{"model":{"display_name":"Sonnet 4.6"},"context_window":{"used_percentage":25},"cost":{"total_cost_usd":0.05}}' | ~/.claude/statusline.sh
```

---

## Disabling

Run `/statusline remove` or delete the `statusLine` key from `~/.claude/settings.json`.
