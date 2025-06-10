# bash_profile
#
# Use .bash_profile to run commands that should run only once, such as
# customizing the $PATH environment variable.

##### Make Mac stop telling me to use a different shell
UNAME=$(uname)
export UNAME
if [ "$UNAME" = "Darwin" ]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
fi

##### Source the profile file
if [ -f ~/.profile ]; then
  # shellcheck disable=SC1091
	source "$HOME/.profile"
fi

##### SSH
# Setup ssh-agent (not on BP_DEV or Codespaces)
if [[ -z "$BP_DEV" && -z "$CODESPACES" ]]; then
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi


##### Golang
export GOPATH="$HOME/go"
export PATH=$PATH:$GOPATH/bin
export GOPATH="$GOPATH:$HOME/Source/Go"


##### Configure nvm
export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion


##### Set Ruby envvars (locally, codespaces already does this)
#if [ -z "$CODESPACES" ]; then
#  eval "$(rbenv init -)"
#fi


##### Source our bashrc file
if [ -f ~/.bashrc ]; then
  # shellcheck disable=SC1091
	source "$HOME/.bashrc"
fi

##### Add JetBrains tools, user binaries, etc. to the path
export PATH="$PATH:$HOME/bin"

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"
