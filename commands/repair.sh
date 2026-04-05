#!/bin/bash

set -e

MYDIR="$HOME/git/myClaude"
source "$MYDIR/myClaude.conf"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: myClaude repair"
    echo ""
    echo "Repairs broken or missing CLAUDE.md symlinks for all repos tracked in myClaude."
    echo "Creates the myClaude/repos/<name>/ directory and CLAUDE.md if missing."
    echo "Skips repos flagged as do-not-include."
    exit 0
fi

REPAIRED=0
SKIPPED=0

for dir in "$GIT_ROOT"/*/; do
    [[ -d "$dir/.git" ]] || continue
    name=$(basename "$dir")

    # Skip excluded repos
    [[ -f "$MYDIR/.flags/$name/do-not-include" ]] && { ((SKIPPED++)); continue; }

    CLAUDE_SRC="$MYDIR/repos/$name/CLAUDE.md"
    CLAUDE_LINK="$dir/CLAUDE.md"

    # Already a valid symlink pointing to the right place
    if [[ -L "$CLAUDE_LINK" && "$(realpath "$CLAUDE_LINK")" == "$CLAUDE_SRC" ]]; then
        continue
    fi

    # Create source in myClaude if missing
    if [[ ! -f "$CLAUDE_SRC" ]]; then
        mkdir -p "$MYDIR/repos/$name"
        touch "$CLAUDE_SRC"
        echo "  created   $MYDIR/repos/$name/CLAUDE.md"
    fi

    # Remove broken/wrong link or plain file, then symlink
    [[ -e "$CLAUDE_LINK" || -L "$CLAUDE_LINK" ]] && rm "$CLAUDE_LINK"
    ln -s "$CLAUDE_SRC" "$CLAUDE_LINK"
    echo "  repaired  $name"
    ((REPAIRED++))
done

echo ""
echo "$REPAIRED repaired, $SKIPPED skipped."
