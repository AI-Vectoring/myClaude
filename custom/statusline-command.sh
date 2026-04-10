#!/bin/bash
# IMPORTANT: This file is the repo source, NOT the live file.
# Claude Code's statusLine hook points to: ~/.claude/statusline-command.sh
# That file is a SEPARATE COPY — edits here have no effect until synced.
# To sync: cp /home/yosu/git/myClaude/custom/statusline-command.sh ~/.claude/statusline-command.sh
# Or re-run: myClaude statusLine on   (re-registers the hook path — check settings.json after)
input=$(cat)

CONF_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$CONF_DIR/statusline.conf"

fields=()

# --- Model ---
fields+=( "$(echo "$input" | jq -r '.model.display_name // "?"')" )
# fields+=( "$(echo "$input" | jq -r '.model.id // "?"')" )

# --- Context window ---
fields+=( "ctx: $(echo "$input" | jq -r '(.context_window.used_percentage | tostring) + "%"')" )
# fields+=( "ctx left: $(echo "$input" | jq -r '(.context_window.remaining_percentage // 0 | tostring) + "%"')" )
# fields+=( "ctx size: $(echo "$input" | jq -r '(.context_window.context_window_size // 0 | tostring)')" )
# fields+=( "$(echo "$input" | jq -r 'if .exceeds_200k_tokens then "200k+" else empty end')" )
fields+=( "tokin: $(echo "$input" | jq -r '.context_window.total_input_tokens // 0')" )
fields+=( "tokout: $(echo "$input" | jq -r '.context_window.total_output_tokens // 0')" )

# --- Rate limits ---
fields+=( "limit 5h: $(echo "$input" | jq -r '(.rate_limits.five_hour.used_percentage | round | tostring) + "%"')" )
fields+=( "limit 7d: $(echo "$input" | jq -r '(.rate_limits.seven_day.used_percentage | round | tostring) + "%"')" )
fields+=( "reset: $(echo "$input" | jq -r '.rate_limits.five_hour.resets_at | strflocaltime("%H:%M")')" )
# fields+=( "7d reset: $(echo "$input" | jq -r '.rate_limits.seven_day.resets_at | strflocaltime("%H:%M")')" )

# --- Cost ---
# fields+=( "cost: $(printf '$%.4f' "$(echo "$input" | jq -r '.cost.total_cost_usd // 0')")" )
# fields+=( "time: $(echo "$input" | jq -r '(.cost.total_duration_ms // 0) as $ms | ($ms/60000|floor|tostring) + "m" + (($ms%60000)/1000|floor|tostring) + "s"')" )
# fields+=( "api time: $(echo "$input" | jq -r '(.cost.total_api_duration_ms // 0) as $ms | ($ms/60000|floor|tostring) + "m" + (($ms%60000)/1000|floor|tostring) + "s"')" )
# fields+=( "lines +$(echo "$input" | jq -r '.cost.total_lines_added // 0') -$(echo "$input" | jq -r '.cost.total_lines_removed // 0')" )

# --- Session ---
# fields+=( "$(echo "$input" | jq -r '.session_name // empty')" )
# fields+=( "v$(echo "$input" | jq -r '.version // "?"')" )
# fields+=( "style: $(echo "$input" | jq -r '.output_style.name // "?"')" )

# --- Contextual (absent unless active) ---
# fields+=( "vim: $(echo "$input" | jq -r '.vim.mode // empty')" )
# fields+=( "agent: $(echo "$input" | jq -r '.agent.name // empty')" )
# fields+=( "worktree: $(echo "$input" | jq -r '.worktree.branch // empty')" )

# --- Line 2: clock, dir, project, git ---
fields2=()
fields2+=( "$(date +%H:%M)" )

current_dir="$(echo "$input" | jq -r '.workspace.current_dir // ""')"
fields2+=( "dir: $(echo "$current_dir" | awk -F'/' '{print $(NF)}')" )

project_dir="$(echo "$input" | jq -r '.workspace.project_dir // ""')"
fields2+=( "project: $(echo "$project_dir" | awk -F'/' '{print $(NF)}')" )

git_branch="$(git -C "$current_dir" branch --show-current 2>/dev/null)"
[ -n "$git_branch" ] && fields2+=( "git: $git_branch" )

# --- Line 3: Permissions from perms.conf ---
PERMS_CONF="${CC_PERMS_CONF:-$HOME/.claude/perms.conf}"
CLAUDE_JSON="${CC_CLAUDE_JSON:-$HOME/.claude.json}"
bold=$'\033[1m'
grn=$'\033[32m'
ylw=$'\033[33m'
red=$'\033[31m'
sl=$'\033['"${brightness};${color}m"
declare -A PERM_LABELS=( [Read]=Read [Edit]=Edit [Bash]=Bash [MCP]=MCP ["Agent(*)"]=Agent [WebFetch]=Fetch ["Bash(git *)"]=Git )
perms_parts=()
for entry in Read Edit Bash MCP "Agent(*)" WebFetch "Bash(git *)"; do
  label="${PERM_LABELS[$entry]}"
  first="${label:0:1}"
  rest="${label:1}"
  if [ -f "$PERMS_CONF" ] && grep -qxF "$entry" "$PERMS_CONF" 2>/dev/null; then
    perms_parts+=( "${grn}${bold}${first}${grn}${rest}" )
  elif [ -f "$PERMS_CONF" ] && grep -qxF "! ${entry}" "$PERMS_CONF" 2>/dev/null; then
    perms_parts+=( "${red}${bold}${first}${red}${rest}" )
  else
    perms_parts+=( "${ylw}${bold}${first}${ylw}${rest}" )
  fi
done

# --- Spinner verb state ---
spinner_mode="default"
if [ -f "$CLAUDE_JSON" ]; then
  spinner_mode=$(jq -r '.spinnerVerbs.mode // "default"' "$CLAUDE_JSON" 2>/dev/null || echo "default")
fi
if [[ "$spinner_mode" == "replace" ]]; then
  spin_part="${grn}${bold}S${grn}pin"
else
  spin_part="${ylw}${bold}S${ylw}pin"
fi

line3="  ${perms_parts[0]}${sl}  |  ${perms_parts[1]}${sl}  |  ${perms_parts[2]}${sl}  |  ${perms_parts[3]}${sl}  |  ${perms_parts[4]}${sl}  |  ${perms_parts[5]}${sl}  |  ${perms_parts[6]}${sl}  |  ${spin_part}"

line1=$(printf '%s  |  ' "${fields[@]}")
line1="${line1%  |  }"
line2=$(printf '%s  |  ' "${fields2[@]}")
line2="${line2%  |  }"

printf "\033[${brightness};${color}m%s\n%s\n%s\033[0m" "$line1" "$line2" "$line3"
