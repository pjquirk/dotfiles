#! /usr/bin/env bash

segments::bpdev() {
  if [[ ! -z "$BP_DEV" ]]; then
    local tags=''
    if [[ -f "$HOME/.bpdev_tags" ]]; then
      tags=$(cat "$HOME/.bpdev_tags")
      if [[ ! -z $tags ]]; then
        tags=" [$tags]"
      fi
    fi
    print_themed_segment 'highlight' "BPDEV$tags"
  fi
}
