# bashrc
#
# Use .bashrc to run commands that should run every time you launch a new shell.

##### Setup GPG
GPG_TTY=$(tty)
export GPG_TTY

##### Aliases
if [ -n "$CODESPACES" ]; then
  alias adn="cd $SKYRISE_PATH"
else
  alias adn='cd ~/Source/GitHub/github/actions-dotnet/src'
fi
alias src='cd ~/Source'
alias newcs='gh cs create --repo github/github --devcontainer-path .devcontainer/actions-larger-runners/devcontainer.json -m xLargePremiumLinux'
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


##### Source homeshick (for managing dotfiles)
source "$HOME/.homesick/repos/homeshick/homeshick.sh"


##### TODO Management
source "$HOME/.config/pjquirk/todo.sh"


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

##### Add some common codespaces things
codespaces_fix_common_startup () {
  unset GITHUB_TOKEN
  gh auth logout --user gh-containers-bot
  gh auth refresh
  export GITHUB_TOKEN=$(gh auth token)
  gh extension install github/gh-medic
}
if [ -n "$CODESPACES" ]; then
  alias 'fixmycs'='codespaces_fix_common_startup';
fi

##### Copilot Shell
  copilot_what-the-shell () {
    TMPFILE=$(mktemp);
    trap 'rm -f $TMPFILE' EXIT;
    if /opt/homebrew/bin/github-copilot-cli what-the-shell "$@" --shellout $TMPFILE; then
      if [ -e "$TMPFILE" ]; then
        FIXED_CMD=$(cat $TMPFILE);
        history -s $(history 1 | cut -d' ' -f4-); history -s "$FIXED_CMD";
        eval "$FIXED_CMD"
      else
        echo "Apologies! Extracting command failed"
      fi
    else
      return 1
    fi
  };
alias '??'='copilot_what-the-shell';

  copilot_git-assist () {
    TMPFILE=$(mktemp);
    trap 'rm -f $TMPFILE' EXIT;
    if /opt/homebrew/bin/github-copilot-cli git-assist "$@" --shellout $TMPFILE; then
      if [ -e "$TMPFILE" ]; then
        FIXED_CMD=$(cat $TMPFILE);
        history -s $(history 1 | cut -d' ' -f4-); history -s "$FIXED_CMD";
        eval "$FIXED_CMD"
      else
        echo "Apologies! Extracting command failed"
      fi
    else
      return 1
    fi
  };
alias 'git?'='copilot_git-assist';

  copilot_gh-assist () {
    TMPFILE=$(mktemp);
    trap 'rm -f $TMPFILE' EXIT;
    if /opt/homebrew/bin/github-copilot-cli gh-assist "$@" --shellout $TMPFILE; then
      if [ -e "$TMPFILE" ]; then
        FIXED_CMD=$(cat $TMPFILE);
        history -s $(history 1 | cut -d' ' -f4-); history -s "$FIXED_CMD";
        eval "$FIXED_CMD"
      else
        echo "Apologies! Extracting command failed"
      fi
    else
      return 1
    fi
  };
alias 'gh?'='copilot_gh-assist';
alias 'wts'='copilot_what-the-shell';
