#!/bin/bash

set -e

MYDIR="$HOME/git/myClaude"
source "$MYDIR/myClaude.conf"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: myClaude scan"
    echo ""
    echo "Scans GIT_ROOT for repos and reports full status plus changes since last scan."
    echo ""
    echo "Columns:"
    echo "  REPO       Repository directory name"
    echo "  CLAUDE.MD  missing    = no CLAUDE.md file found"
    echo "             not linked = CLAUDE.md exists but is not a symlink into myClaude"
    echo "             ok         = CLAUDE.md is properly linked"
    echo "  FLAGS      excluded   = marked do-not-include, ignored by myClaude commands"
    exit 0
fi

STATE_DIR="$MYDIR"
CURRENT="$STATE_DIR/.state.json"
PREVIOUS="$STATE_DIR/.state.prev.json"
TMPFILE=$(mktemp)

scan() {
    local result='{"repos":['
    local first=1
    for dir in "$GIT_ROOT"/*/; do
        [[ -d "$dir/.git" ]] || continue
        name=$(basename "$dir")
        has_claude="false"
        is_linked="false"
        do_not_include="false"

        [[ -f "$dir/CLAUDE.md" ]] && has_claude="true"
        [[ -L "$dir/CLAUDE.md" ]] && is_linked="true"
        [[ -f "$STATE_DIR/.flags/$name/do-not-include" ]] && do_not_include="true"

        [[ $first -eq 0 ]] && result+=","
        result+="{\"name\":\"$name\",\"has_claude\":$has_claude,\"is_linked\":$is_linked,\"do_not_include\":$do_not_include}"
        first=0
    done
    result+="]}"
    echo "$result"
}

print_repo_list() {
    local file="$1"
    (
        printf "REPO\tCLAUDE.MD\tFLAGS\n"
        jq -r '.repos[] |
            [
                .name,
                (if .has_claude == false then "missing"
                 elif .is_linked == false then "not linked"
                 else "ok"
                 end),
                (if .do_not_include then "excluded" else "" end)
            ] | @tsv' "$file"
    ) | column -t -s $'\t'
}

NEW_STATE=$(scan)
echo "$NEW_STATE" > "$TMPFILE"

echo "Repos:"
print_repo_list "$TMPFILE"

if [[ ! -f "$CURRENT" ]]; then
    echo ""
    echo "First scan — no previous state to compare."
    cp "$TMPFILE" "$CURRENT"
    rm "$TMPFILE"
    exit 0
fi

cp "$CURRENT" "$PREVIOUS"

ADDED=$(jq -r --slurpfile old "$PREVIOUS" '
    .repos[].name as $n |
    select([$old[0].repos[].name] | index($n) | not) |
    $n' "$TMPFILE")

REMOVED=$(jq -r --slurpfile new "$TMPFILE" '
    .repos[].name as $n |
    select([$new[0].repos[].name] | index($n) | not) |
    $n' "$PREVIOUS")

CHANGED=$(jq -r --slurpfile old "$PREVIOUS" '
    .repos[] |
    . as $new |
    ($old[0].repos[] | select(.name == $new.name)) as $o |
    select($new != $o) |
    .name' "$TMPFILE")

echo ""
echo "Run 'myClaude scan --help' for column descriptions."
echo ""
if [[ -n "$ADDED" || -n "$REMOVED" || -n "$CHANGED" ]]; then
    [[ -n "$ADDED" ]]   && echo "New:     $ADDED"
    [[ -n "$REMOVED" ]] && echo "Removed: $REMOVED"
    [[ -n "$CHANGED" ]] && echo "Changed: $CHANGED"
else
    echo "No changes since last scan."
fi

cp "$TMPFILE" "$CURRENT"
rm "$TMPFILE"
