#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
style=$(echo "$input" | jq -r '.output_style.name // empty')

if [ -n "$used" ]; then
  context_str="ctx ${used}%"
else
  context_str="ctx --"
fi

parts="\xf0\x9f\x93\x81 ${cwd}  |  ${model}"

if [ -n "$style" ]; then
  parts="${parts}  |  ${style}"
fi

parts="${parts}  |  ${context_str}"

printf "%b\n" "$parts"
