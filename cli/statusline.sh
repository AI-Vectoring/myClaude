#!/bin/bash

set -e

source "$MYCLAUDE_HOME/myClaude.conf"

SCRIPT="$MYCLAUDE_HOME/custom/statusline-command.sh"
SETTINGS="$HOME/.claude/settings.json"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: myClaude statusLine <on|off>"
    echo ""
    echo "Enables or disables the Claude Code status line."
    echo "  on   — adds statusLine config to ~/.claude/settings.json"
    echo "  off  — removes statusLine config from ~/.claude/settings.json"
    exit 0
fi

if [[ -z "$1" ]]; then
    echo "Usage: myClaude statusLine <on|off>" >&2
    exit 1
fi

case "$1" in
    on)
        if [[ ! -f "$SETTINGS" ]]; then
            echo '{}' > "$SETTINGS"
        fi
        jq --arg cmd "bash $SCRIPT" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$SETTINGS.tmp"
        mv "$SETTINGS.tmp" "$SETTINGS"
        echo "Status line enabled."
        ;;
    off)
        if [[ ! -f "$SETTINGS" ]]; then
            echo "No settings file found." >&2
            exit 1
        fi
        jq 'del(.statusLine)' "$SETTINGS" > "$SETTINGS.tmp"
        mv "$SETTINGS.tmp" "$SETTINGS"
        echo "Status line disabled."
        ;;
    *)
        echo "Unknown argument: $1 (use on or off)" >&2
        exit 1
        ;;
esac
