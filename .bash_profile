export GOPATH="$HOME/go"
export PATH=$PATH:$GOPATH/bin
export GOPATH="$GOPATH:$HOME/Source/Go"

alias src='cd ~/Source'

alias ls='ls -l'

export UNAME=$(uname)
export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion

eval "$(rbenv init -)"

# in iterm2, set the badge to `\(user.iterm2environment)`
function set_iterm2_environment() {
  export iterm2environment=$1
  export iterm2environmentshort=$2
  printf "\033]1337;SetUserVar=%s=%s\007" iterm2environment `echo -n $iterm2environmentshort | base64`
}
export -f set_iterm2_environment 1>/dev/null

# get current branch in git repo
function parse_git_branch() {
  BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
  if [[ ! "${BRANCH}" == "" ]]
  then
    STAT=`parse_git_dirty`
    echo "[${BRANCH}${STAT}]"
  else
    echo ""
  fi
}

# get current status of git repo
function parse_git_dirty {
  local git_status=`git status 2>&1 | tee`
  local dirty=`echo -n "${git_status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
  local untracked=`echo -n "${git_status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
  local ahead=`echo -n "${git_status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
  local newfile=`echo -n "${git_status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
  local renamed=`echo -n "${git_status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
  local deleted=`echo -n "${git_status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
  local bits=''
  if [[ "${renamed}" == "0" ]]; then
    bits=">${bits}"
  fi
  if [[ "${ahead}" == "0" ]]; then
    bits="*${bits}"
  fi
  if [[ "${newfile}" == "0" ]]; then
    bits="+${bits}"
  fi
  if [[ "${untracked}" == "0" ]]; then
    bits="?${bits}"
  fi
  if [[ "${deleted}" == "0" ]]; then
    bits="x${bits}"
  fi
  if [[ "${dirty}" == "0" ]]; then
    bits="!${bits}"
  fi
  if [[ ! "${bits}" == "" ]]; then
    echo " ${bits}"
  else
    echo ""
  fi
}

set_prompt () {
  LastExitCodeValue=$? # Must come first!
  if [ -n "$ZSH_VERSION" ]; then
    Blue=$'%{\e[01;34m%}'
    White=$'%{\e[01;37m%}'
    Yellow=$'%{\e[01;33m%}'
    Cyan=$'%{\e[01;40m%}'
    Red=$'%{\e[01;31m%}'
    RedBackground=$'%{\e[37;41m%}'
    Green=$'%{\e[01;32m%}'
    Reset=$'%{\e[00m%}'
    FancyX='\342\234\227'
    Checkmark='\342\234\223'
    Time='%*'
    Pwd='%1~'
    LastExitCode='%?'
  else
    Blue='\[\e[01;34m\]'
    White='\[\e[01;37m\]'
    Yellow='\[\e[01;33m\]'
    Cyan='\[\e[01;40m\]'
    Red='\[\e[01;31m\]'
    RedBackground='\[\e[37;41m\]'
    Green='\[\e[01;32m\]'
    Reset='\[\e[00m\]'
    FancyX='\342\234\227'
    Checkmark='\342\234\223'
    Time='\t'
    Pwd='\W'
    LastExitCode='$?'
  fi

  # If the last command was successful, print a green check mark. Otherwise, print a red X.
  # Or actually just print the exit code itself as an integer.
  if [ $LastExitCodeValue = "0" ]; then
    #PS1+="$Green$Checkmark "
    PS1="$Green$LastExitCode "
  else
    #PS1+="$Red$FancyX "
    PS1="$Red$LastExitCode "
  fi

  PS1+="$Reset $Time "

# If root, just print the host in red. Otherwise, print the current user and host in green.
#  if [[ $EUID == 0 ]]; then
#    PS1+="$Red\\u$Green@\\h "
#  else
#    PS1+="$Green\\u@\\h "
#  fi

  # set iterm2 environments for Skyrise/Vagrant/GHES inner loops
  if [[ $(hostname) =~ ^ip-[0-9]+-[0-9]+-[0-9]+-[0-9]+$ ]]; then # e.g., "ip-172-28-128-7"
    set_iterm2_environment "macos>bpdev" bpdev
  elif [[ $(hostname) =~ "bpdev" ]]; then
    set_iterm2_environment "macos>bpdev>ghes" ghes
  else
    set_iterm2_environment macos macos
  fi
  PS1+="$Green$iterm2environment: "

  # Print the working directory and prompt marker in blue
  PS1+="$Blue$Pwd"

  # Git status
  PS1+=" $Red$(parse_git_branch)"

  # Reset propt color
  PS1+="$Reset> "

  # Set the title of the window in bash
  if [ -n "$BASH_VERSION" ]; then
    case "$TERM" in
    xterm*|rxvt*)
      PS1="\[\e]0;$iterm2environment: \w\a\]$PS1"
      ;;
    esac
  fi
}

PROMPT_COMMAND='set_prompt'

if [ -n "$ZSH_VERSION" ]; then
  precmd() { 
    # Set the prompt first because the first thing it does is check the last error code.
    eval "$PROMPT_COMMAND" 
    # Set the title of the window in zsh
    echo -ne "\e]1;$iterm2environment: ${PWD/#"$HOME"/~}\a"
  }
fi

if [ "$UNAME" = "Darwin" ]; then
  # https://www.cyberciti.biz/faq/apple-mac-osx-terminal-color-ls-output-option/
  export CLICOLOR=1
  export LSCOLORS=ExFxCxDxBxegedabagaced
else
  LS_COLORS="ow=01;34:*.cs=35:*.csproj=1;33:*.proj=1;33:ex=0"
  export LS_COLORS
fi

source ~/.git-completion.bash
