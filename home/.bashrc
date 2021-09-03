# bashrc
#
# Use .bashrc to run commands that should run every time you launch a new shell.

##### Aliases
alias src='cd ~/Source'
export LS_OPTIONS=''
alias ls='ls -l $LS_OPTIONS'


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
# shellcheck disable=SC1091
source "$HOME/.git-completion.bash"


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