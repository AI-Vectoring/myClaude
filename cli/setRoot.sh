#!/bin/bash

set -e

CONF="$MYCLAUDE_HOME/myClaude.conf"

if [[ -z "$1" || "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: myClaude setRoot <path>"
    echo ""
    echo "Sets the root directory where git repos are stored."
    echo "Default: ~/git"
    exit 0
fi

NEW_ROOT="$1"

if [[ ! -d "$NEW_ROOT" ]]; then
    echo "Error: directory does not exist: $NEW_ROOT" >&2
    exit 1
fi

sed -i "s|^GIT_ROOT=.*|GIT_ROOT=\"$NEW_ROOT\"|" "$CONF"
echo "GIT_ROOT set to $NEW_ROOT"
