#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

bar=""
if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct" | awk '{printf "%d", ($1 / 100 * 15 + 0.5)}')
  empty=$((15 - filled))

  if [ "$used_pct" -ge 90 ]; then
    color=$'\033[31m'       # red
  elif [ "$used_pct" -ge 75 ]; then
    color=$'\033[38;5;208m' # orange
  elif [ "$used_pct" -ge 50 ]; then
    color=$'\033[33m'       # yellow
  else
    color=$'\033[32m'       # green
  fi
  reset=$'\033[0m'

  filled_blocks=""
  empty_blocks=""
  for i in $(seq 1 "$filled"); do filled_blocks="${filled_blocks}█"; done
  for i in $(seq 1 "$empty"); do empty_blocks="${empty_blocks}░"; done
  context_section="  |  Context: ${color}${filled_blocks}${reset}${empty_blocks} ${color}${used_pct}%${reset}"
fi

hostname=$(hostname -s)
printf "💻 %s • %s  |  %s%s\n" "$hostname" "$cwd" "$model" "$context_section"
