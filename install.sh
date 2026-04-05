#!/bin/bash

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$REPO_DIR/myClaude.conf"

# Update MYCLAUDE_HOME to actual repo location
sed -i "s|^MYCLAUDE_HOME=.*|MYCLAUDE_HOME=\"$REPO_DIR\"|" "$CONF"

# Install dependencies
if ! command -v jq &>/dev/null; then
    echo "Installing jq..."
    sudo apt-get install -y jq
fi

# Install dispatcher
sudo cp "$REPO_DIR/myClaude.sh" /usr/local/bin/myClaude
sudo chmod +x /usr/local/bin/myClaude

# Create GIT_ROOT if it doesn't exist
source "$CONF"
mkdir -p "$GIT_ROOT"

# Install Claude Code skills
mkdir -p "$HOME/.claude/skills/refresh"
ln -sf "$REPO_DIR/skills/refresh/SKILL.md" "$HOME/.claude/skills/refresh/SKILL.md"

echo "myClaude installed."
echo "  dispatcher: /usr/local/bin/myClaude"
echo "  home:       $REPO_DIR"
echo "  git root:   $GIT_ROOT"
