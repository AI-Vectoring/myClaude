#!/bin/bash

set -e

source "__MYCLAUDE_CONF__"

SUBCOMMAND="$1"
shift || true

case "$SUBCOMMAND" in
    newRepo)
        exec "$MYCLAUDE_HOME/cli/newRepo.sh" "$@"
        ;;
    scan)
        exec "$MYCLAUDE_HOME/cli/scan.sh" "$@"
        ;;
    setRoot)
        exec "$MYCLAUDE_HOME/cli/setRoot.sh" "$@"
        ;;
    repair)
        exec "$MYCLAUDE_HOME/cli/repair.sh" "$@"
        ;;
    statusLine)
        exec "$MYCLAUDE_HOME/cli/statusline.sh" "$@"
        ;;
    status)
        exec "$MYCLAUDE_HOME/cli/status.sh" "$@"
        ;;
    ""|-h|--help)
        echo "Usage: myClaude <command> [options]"
        echo ""
        echo "Commands:"
        echo "  newRepo      Create a new GitHub repo with CLAUDE.md wired up"
        echo "  scan         Scan git root for repos and report changes since last scan"
        echo "  setRoot      Set the root directory where git repos are stored"
        echo "  repair       Re-create missing or broken CLAUDE.md symlinks"
        echo "  status       Show effective statusline and available fields"
        echo "  statusLine   Enable or disable the Claude Code status line"
        echo ""
        echo "Run 'myClaude <command> --help' for command-specific help."
        ;;
    *)
        echo "Unknown command: $SUBCOMMAND" >&2
        echo "Run 'myClaude --help' for usage." >&2
        exit 1
        ;;
esac
