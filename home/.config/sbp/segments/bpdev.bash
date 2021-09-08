#! /usr/bin/env bash

segments::bpdev() {
  if [[ ! -z "$BP_DEV" ]]; then
    print_themed_segment 'highlight' 'BPDEV'
  fi
}
