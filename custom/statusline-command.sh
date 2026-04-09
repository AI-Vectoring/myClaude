#!/bin/bash
input=$(cat)

fields=()
fields+=( "$(echo "$input" | jq -r '.model.display_name // "?"')" )
fields+=( "ctx: $(echo "$input" | jq -r '(.context_window.used_percentage | tostring) + "%"')" )
fields+=( "limit 5h: $(echo "$input" | jq -r '(.rate_limits.five_hour.used_percentage | round | tostring) + "%"')" )
fields+=( "limit 7d: $(echo "$input" | jq -r '(.rate_limits.seven_day.used_percentage | round | tostring) + "%"')" )
fields+=( "reset: $(echo "$input" | jq -r '.rate_limits.five_hour.resets_at | strflocaltime("%H:%M")')" )
fields+=( "tokin: $(echo "$input" | jq -r '.context_window.total_input_tokens // 0')" )
fields+=( "tokout: $(echo "$input" | jq -r '.context_window.total_output_tokens // 0')" )

output=$(printf '%s  |  ' "${fields[@]}")
output="${output%  |  }"

printf "\033[2;37m%s\033[0m" "$output"
