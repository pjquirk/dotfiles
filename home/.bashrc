# bashrc
#
# Use .bashrc to run commands that should run every time you launch a new shell.

##### Aliases
alias src='cd ~/Source'
alias ls='ls -l'


##### Ensure ls uses colors
export UNAME=$(uname)
if [ "$UNAME" = "Darwin" ]; then
  # https://www.cyberciti.biz/faq/apple-mac-osx-terminal-color-ls-output-option/
  export CLICOLOR=1
  export LSCOLORS=ExFxCxDxBxegedabagaced
else
  LS_COLORS="ow=01;34:*.cs=35:*.csproj=1;33:*.proj=1;33:ex=0"
  export LS_COLORS
fi


##### Convenience function for creating pristing GHAE instances
export DEV_USER=paquirk7894
function pristine_ghae(){
  pushd ~/Source/GitHub/github/ghae-kube
  ./script/ensure-azure-login
  az group update -n "$DEV_USER" --set tags.auto_cleanup_date_utc='01/01/21@00:00:00'
  ms_user=$(az ad signed-in-user show --query mailNickname --output tsv)
  sed -i '' -e "s/^export DEV_USER=$ms_user[0-9]*$/export DEV_USER=$ms_user$RANDOM/g" ~/.bashrc
  source ~/.bashrc
  ./script/setup --subscription "GHAE Dev 3" --enable-actions
  popd
}


##### Enable git command/branch/etc tab completion
source ~/.git-completion.bash


##### Start sbp:  https://github.com/brujoand/sbp
SBP_PATH="/usr/local/opt/sbp"
source "${SBP_PATH}/sbp.bash"
