# Contains GitHub related aliases and functions

alias newcs='gh cs create --repo github/github --devcontainer-path .devcontainer/actions-larger-runners/devcontainer.json -m xLargePremiumLinux256gb'
alias rcs='rename_codespace'

create_new_gh_codespace() {
  CODESPACE=$(gh cs create --repo github/github --devcontainer-path .devcontainer/actions-larger-runners/devcontainer.json -m xLargePremiumLinux256gb)

  # Allow renaming a codespace if an argument is passed
  if [ $# -ge 1 ]
  then
    rename_codespace $CODESPACE $1
  fi
}

rename_codespace() {
  if [ $# -lt 2 ]
  then
    echo "Usage: rcs CODESPACE_NAME DISPLAY_NAME"
    return 1
  fi
  CODESPACE_NAME=$1
  DISPLAY_NAME=$2
  gh api -X PATCH user/codespaces/$CODESPACE_NAME -f "display_name=$DISPLAY_NAME" >/dev/null
}

#### Add some common codespaces things
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

#### Copilot Shell
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
