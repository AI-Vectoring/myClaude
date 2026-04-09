#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "?"')
ctx=$(echo "$input" | jq -r '(.context_window.used_percentage | tostring) + "%"')
limit5=$(echo "$input" | jq -r '(.rate_limits.five_hour.used_percentage | round | tostring) + "%"')
limit7=$(echo "$input" | jq -r '(.rate_limits.seven_day.used_percentage | round | tostring) + "%"')
reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at | strftime("%H:%M")')
tok_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
tok_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

printf "\033[2;37m%s  |  ctx: %s  |  limit 5h: %s  |  limit 7d: %s  |  reset: %s  |  tokin: %s  |  tokout: %s\033[0m" \
    "$model" "$ctx" "$limit5" "$limit7" "$reset" "$tok_in" "$tok_out"
