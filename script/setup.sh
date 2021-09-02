#!/usr/bin/env bash

### Install homeshick
git clone git://github.com/andsens/homeshick.git "$HOME/.homesick/repos/homeshick"
# shellcheck disable=SC1091
source "$HOME/.homesick/repos/homeshick/homeshick.sh"

### Clone my dotfiles
$HOME/.homesick/repos/homeshick/bin/homeshick --quiet clone pjquirk/dotfiles