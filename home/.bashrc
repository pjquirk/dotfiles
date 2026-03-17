#! /bin/bash
#
# Use .bashrc to run commands that should run every time you launch a new shell.

##### Shortcuts for managing dotfiles
alias dot-cd='cd ~/src/GitHub/pjquirk/dotfiles'
alias dot-push='~/src/GitHub/pjquirk/dotfiles/script/push'
alias dot-pull='~/src/GitHub/pjquirk/dotfiles/script/pull'

##### Setup GPG
GPG_TTY=$(tty)
export GPG_TTY

##### Aliases
export LS_OPTIONS=''
alias ls='ls -l $LS_OPTIONS'
alias src='cd ~/src'

##### Ensure ls uses colors
UNAME=$(uname)
export UNAME
if [ "$UNAME" = "Darwin" ]; then
  # https://www.cyberciti.biz/faq/apple-mac-osx-terminal-color-ls-output-option/
  export CLICOLOR=1
  export LSCOLORS=ExFxCxDxBxegedabagaced
else
  export LS_OPTIONS='--color=auto'
  eval "$(dircolors)"
fi

##### Enable git command/branch/etc tab completion
if [ -f "$HOME/.config/pjquirk/nvidia.bashrc" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.git-completion.bash"
fi

##### Start sbp:  https://github.com/brujoand/sbp
# It's either installed via brew already, or in a bp-dev
# setup script (e.g. my dotfiles)
if [ -z "$SBP_PATH" ]; then
  if [ -d ~/.sbp ]; then
    SBP_PATH="$HOME/.sbp"
  else
    # SBP was probably installed via brew
    SBP_PATH="/usr/local/opt/sbp"
  fi
fi
if [ -f "${SBP_PATH}/sbp.bash" ]; then
  # shellcheck disable=SC1091
  source "${SBP_PATH}/sbp.bash"
fi

##### TODO Management
# source "$HOME/.config/pjquirk/todo.sh"

##### Colorful manpages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
# Set to avoid `env` output from changing console colour
export LESS_TERMEND=$'\E[0m'

##### Set the text editor to use
export EDITOR="vim"
if [ -n "$CODESPACES" ]; then
  # When using the command line, git can't find VS Code
  export GIT_EDITOR="vim"
fi

##### Company-specific environment variables and aliases
if [ -f "$HOME/.config/pjquirk/nvidia.bashrc" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/pjquirk/nvidia.bashrc"
fi
