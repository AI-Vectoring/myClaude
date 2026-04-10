#!/usr/bin/env bash
set -euo pipefail

CONF="${CC_PERMS_CONF:-$HOME/.claude/perms.conf}"
SETTINGS="${CC_PERMS_SETTINGS:-$HOME/.claude/settings.json}"
CLAUDE_JSON="${CC_CLAUDE_JSON:-$HOME/.claude.json}"

declare -A PATTERNS=(
  [r]="Read(*)"
  [e]="Edit(*)"
  [b]="Bash(*)"
  [m]="MCP(*)"
  [a]="Agent(*)"
  [f]="WebFetch(*)"
  [g]="Bash(git *)"
)

KEYS=(r e b m a f g)

ACTION="${1:-status}"

if [[ "$ACTION" != "status" && "$ACTION" != "s" && -z "${PATTERNS[$ACTION]:-}" ]]; then
  echo "Usage: bit <r|e|b|m|a|f|g|s|status>" >&2
  exit 1
fi

touch "$CONF"
[[ ! -f "$SETTINGS" ]] && echo '{}' > "$SETTINGS"

# States cycle: ask (default) → allow → deny → ask
# perms.conf format:
#   Read(*)       = allow
#   # Read(*)     = ask (commented)
#   ! Read(*)     = deny

get_spinner_state() {
  [[ ! -f "$CLAUDE_JSON" ]] && echo "default" && return
  jq -r '.spinnerVerbs.mode // "default"' "$CLAUDE_JSON" 2>/dev/null || echo "default"
}

cycle_spinner() {
  local state
  state=$(get_spinner_state)
  [[ ! -f "$CLAUDE_JSON" ]] && echo '{}' > "$CLAUDE_JSON"
  if [[ "$state" == "default" ]]; then
    jq '.spinnerVerbs = {"mode": "replace", "verbs": ["Working", "Processing", "Analyzing", "Resolving"]} | .prefersReducedMotion = true' \
      "$CLAUDE_JSON" > "${CLAUDE_JSON}.tmp"
    mv "${CLAUDE_JSON}.tmp" "$CLAUDE_JSON"
    echo "Spinner: tame (replace, motion off)"
  else
    jq 'del(.spinnerVerbs) | .prefersReducedMotion = false' "$CLAUDE_JSON" > "${CLAUDE_JSON}.tmp"
    mv "${CLAUDE_JSON}.tmp" "$CLAUDE_JSON"
    echo "Spinner: wild (default, motion on)"
  fi
}

get_state() {
  local p="$1"
  if grep -qxF "$p" "$CONF" 2>/dev/null; then
    echo "allow"
  elif grep -qxF "! ${p}" "$CONF" 2>/dev/null; then
    echo "deny"
  else
    echo "ask"
  fi
}

cycle() {
  local p="${PATTERNS[$ACTION]}"
  local state
  state=$(get_state "$p")

  # Remove any existing entry for this permission
  local tmp
  tmp=$(mktemp)
  grep -vxF "$p" "$CONF" 2>/dev/null | grep -vxF "# ${p}" | grep -vxF "! ${p}" > "$tmp" || true
  mv "$tmp" "$CONF"

  local label="${p%%(*}"
  case "$state" in
    ask)
      echo "$p" >> "$CONF"
      echo "${label}: allow"
      ;;
    allow)
      echo "! ${p}" >> "$CONF"
      echo "${label}: deny"
      ;;
    deny)
      echo "# ${p}" >> "$CONF"
      echo "${label}: ask"
      ;;
  esac
}

compile_merge() {
  local allow_raw deny_raw allow_json deny_json

  allow_raw=$(grep -v '^\s*#' "$CONF" 2>/dev/null | grep -v '^\s*!' | grep -v '^\s*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') || true
  deny_raw=$(grep '^\s*!' "$CONF" 2>/dev/null | sed 's/^[[:space:]]*![[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') || true

  allow_json="[]"
  deny_json="[]"
  [[ -n "$allow_raw" ]] && allow_json=$(echo "$allow_raw" | jq -R . | jq -s .)
  [[ -n "$deny_raw" ]] && deny_json=$(echo "$deny_raw" | jq -R . | jq -s .)

  jq --argjson allow "$allow_json" --argjson deny "$deny_json" \
    '.permissions = (.permissions // {}) | .permissions.allow = $allow | .permissions.deny = $deny' \
    "$SETTINGS" > "${SETTINGS}.tmp"
  mv "${SETTINGS}.tmp" "$SETTINGS"
}

show_status() {
  local grn=$'\033[32m'
  local ylw=$'\033[33m'
  local red=$'\033[31m'
  local bld=$'\033[1m'
  local rst=$'\033[0m'

  echo "=== Permissions ==="
  for k in "${KEYS[@]}"; do
    local p="${PATTERNS[$k]}"
    local label="${p%%(*}"
    local state
    state=$(get_state "$p")
    case "$state" in
      allow) printf "  ${grn}[ALLOW] ${bld}%s${grn}%s${rst}\n" "${label:0:1}" "${label:1}" ;;
      ask)   printf "  ${ylw}[ASK]   ${bld}%s${ylw}%s${rst}\n" "${label:0:1}" "${label:1}" ;;
      deny)  printf "  ${red}[DENY]  ${bld}%s${red}%s${rst}\n" "${label:0:1}" "${label:1}" ;;
    esac
  done
  echo ""
  echo "=== Spinner ==="
  local spin_state
  spin_state=$(get_spinner_state)
  if [[ "$spin_state" == "replace" ]]; then
    printf "  ${grn}[TAME]  ${bld}S${grn}pinner${rst}\n"
  else
    printf "  ${ylw}[WILD]  ${bld}S${ylw}pinner${rst}\n"
  fi
}

if [[ "$ACTION" == "status" ]]; then
  show_status
  exit 0
fi

if [[ "$ACTION" == "s" ]]; then
  cycle_spinner
  exit 0
fi

cycle
compile_merge
