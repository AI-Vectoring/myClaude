#!/bin/bash

set -e

source "$HOME/git/myClaude/myClaude.conf"

SUBCOMMAND="$1"
shift || true

case "$SUBCOMMAND" in
    newRepo)
        exec "$MYCLAUDE_HOME/commands/newRepo.sh" "$@"
        ;;
    scan)
        exec "$MYCLAUDE_HOME/commands/scan.sh" "$@"
        ;;
    setRoot)
        exec "$MYCLAUDE_HOME/commands/setRoot.sh" "$@"
        ;;
    ""|-h|--help)
        echo "Usage: myClaude <command> [options]"
        echo ""
        echo "Commands:"
        echo "  newRepo   Create a new GitHub repo with CLAUDE.md wired up"
        echo "  scan      Scan git root for repos and report changes since last scan"
        echo "  setRoot   Set the root directory where git repos are stored"
        echo ""
        echo "Run 'myClaude <command> --help' for command-specific help."
        ;;
    *)
        echo "Unknown command: $SUBCOMMAND" >&2
        echo "Run 'myClaude --help' for usage." >&2
        exit 1
        ;;
esac
