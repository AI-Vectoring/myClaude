#!/bin/bash

set -e

DEV_MODE=false
if [[ "$1" == "--dev" ]]; then
    DEV_MODE=true
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$REPO_DIR/myClaude.conf"
TEMPLATES="$REPO_DIR/workshop/templates"

# Generate private files from templates if they don't exist
[[ -f "$CONF" ]] || cp "$TEMPLATES/myClaude.conf.example" "$CONF"
[[ -f "$REPO_DIR/CLAUDE.md" ]] || cp "$TEMPLATES/CLAUDE.md.example" "$REPO_DIR/CLAUDE.md"

# Update MYCLAUDE_HOME to actual repo location
sed -i "s|^MYCLAUDE_HOME=.*|MYCLAUDE_HOME=\"$REPO_DIR\"|" "$CONF"

# Install dependencies
if ! command -v jq &>/dev/null; then
    echo "Installing jq..."
    sudo apt-get install -y jq
fi

# Install CLI to /usr/local/bin/ (skipped in dev mode)
if [[ "$DEV_MODE" == false ]]; then
    sed "s|__MYCLAUDE_CONF__|$CONF|" "$REPO_DIR/cli/myClaude.sh" | sudo tee /usr/local/bin/myClaude > /dev/null
    sudo chmod +x /usr/local/bin/myClaude
fi

# Create required directories
source "$CONF"
mkdir -p "$GIT_ROOT"
mkdir -p "$REPO_DIR/workshop/internal"

# Install Claude Code skills
mkdir -p "$HOME/.claude/skills/refresh"
ln -sf "$REPO_DIR/custom/skills/refresh/SKILL.md" "$HOME/.claude/skills/refresh/SKILL.md"

if [[ "$DEV_MODE" == true ]]; then
    echo "myClaude dev setup complete."
    echo "  run from: $REPO_DIR/cli/myClaude.sh"
else
    echo "myClaude installed."
    echo "  entry point: /usr/local/bin/myClaude"
fi
echo "  home:       $REPO_DIR"
echo "  git root:   $GIT_ROOT"
