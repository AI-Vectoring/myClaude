#!/bin/bash

set -e

MYDIR="$HOME/git/myClaude"
source "$MYDIR/myClaude.conf"

VISIBILITY="--private"

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--public)
            VISIBILITY="--public"
            shift
            ;;
        -h|--help)
            echo "Usage: newRepo [-p|--public] <repo-name>"
            echo ""
            echo "Creates a new GitHub repo, clones it to ~/git/, and wires up a"
            echo "CLAUDE.md symlink via ~/git/myClaude/repos/<repo-name>/CLAUDE.md."
            echo ""
            echo "Options:"
            echo "  -p, --public   Create a public repo (default: private)"
            echo "  -h, --help     Show this help"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            REPO_NAME="$1"
            shift
            ;;
    esac
done

if [[ -z "$REPO_NAME" ]]; then
    echo "Usage: newRepo.sh [-p|--public] <repo-name>" >&2
    exit 1
fi

REPO_DIR="$GIT_ROOT/$REPO_NAME"
CLAUDE_DIR="$MYDIR/repos/$REPO_NAME"

gh repo create "$REPO_NAME" "$VISIBILITY" --clone --clone-dir "$GIT_ROOT"

mkdir -p "$CLAUDE_DIR"
touch "$CLAUDE_DIR/CLAUDE.md"
ln -s "$CLAUDE_DIR/CLAUDE.md" "$REPO_DIR/CLAUDE.md"

echo "Created $REPO_NAME"
echo "  repo:   $REPO_DIR"
echo "  claude: $CLAUDE_DIR/CLAUDE.md -> $REPO_DIR/CLAUDE.md"
