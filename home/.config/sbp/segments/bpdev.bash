#! /usr/bin/env bash

segments::bpdev() {
  if [[ ! -z "$BPDEV" ]]; then
    print_themed_segment 'highlight' 'BPDEV'
  fi
}
