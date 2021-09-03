#!/usr/bin/env bash

### Install homeshick
git clone git://github.com/andsens/homeshick.git "$HOME/.homesick/repos/homeshick"
# shellcheck disable=SC1091
source "$HOME/.homesick/repos/homeshick/homeshick.sh"

### Clone my dotfiles
homeshick clone pjquirk/dotfiles --quiet --batch
homeshick link dotfiles --force

### Install SBP
git clone git@github.com:brujoand/sbp.git $HOME/.sbp