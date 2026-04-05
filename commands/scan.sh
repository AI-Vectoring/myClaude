#!/bin/bash

set -e

MYDIR="$HOME/git/myClaude"
source "$MYDIR/myClaude.conf"

STATE_DIR="$MYDIR"
CURRENT="$STATE_DIR/.state.json"
PREVIOUS="$STATE_DIR/.state.prev.json"

scan() {
    local result="{"
    result+='"repos":['
    first=1
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

NEW_STATE=$(scan)

if [[ ! -f "$CURRENT" ]]; then
    echo "First scan — no previous state to compare."
    echo "$NEW_STATE" > "$CURRENT"
    echo "$NEW_STATE" | python3 -c "
import json,sys
data=json.load(sys.stdin)
for r in data['repos']:
    flags=[]
    if not r['has_claude']: flags.append('no CLAUDE.md')
    if r['has_claude'] and not r['is_linked']: flags.append('not linked')
    if r['do_not_include']: flags.append('do-not-include')
    print(f\"  {r['name']}\" + (f\" ({', '.join(flags)})\" if flags else ''))
"
    exit 0
fi

cp "$CURRENT" "$PREVIOUS"

python3 - <<EOF
import json

with open('$PREVIOUS') as f:
    old = {r['name']: r for r in json.load(f)['repos']}
with open('/dev/stdin') as f:
    new = {r['name']: r for r in json.load(f)['repos']}

added = [n for n in new if n not in old]
removed = [n for n in old if n not in new]
changed = [n for n in new if n in old and new[n] != old[n]]

if added:
    print('New repos:')
    for n in added:
        r = new[n]
        flags = []
        if not r['has_claude']: flags.append('no CLAUDE.md')
        if r['has_claude'] and not r['is_linked']: flags.append('not linked')
        if r['do_not_include']: flags.append('do-not-include')
        print(f"  {n}" + (f" ({', '.join(flags)})" if flags else ''))

if removed:
    print('Removed repos:')
    for n in removed:
        print(f'  {n}')

if changed:
    print('Changed:')
    for n in changed:
        o, r = old[n], new[n]
        diffs = [k for k in r if r[k] != o.get(k)]
        print(f'  {n}: {", ".join(diffs)}')

if not added and not removed and not changed:
    print('No changes since last scan.')
EOF <<< "$NEW_STATE"

echo "$NEW_STATE" > "$CURRENT"
