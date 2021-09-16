#!/usr/env/var bash
# shellcheck shell=bash

tdhelp () {
  echo 'ToDo:'
  echo '  todo              List open items'
  echo '  tdn "<title>"     Create a new issue'
  echo '  tdc <number>      Close an existing issue'
  echo '  tdo <number>      Open an issue for notes'
}

gh_repo () {
  gh --repo pjquirk/worknotes "$@"
}

todo () {
  gh_repo issue list --assignee @me
}

tdn () {
  IFS=' ' # make sure "$*" is joined with spaces
  # Glob all arguments into a string
  local title="$*"
  if [[ -z "${title}" ]]; then
    echo \
"Expected a title for the issue, e.g.:
  ${FUNCNAME[0]} A pretty standard title
  ${FUNCNAME[0]} \"A title that contains an ' or \" character\"" >&2
    return 1
  fi
  gh_repo issue create --assignee @me --body "" --title "${title}"
}

tdc () {
  local number="${1}"
  if ! [[ $number =~ ^[0-9]+$ ]] ; then
   echo \
"Expected an issue number to close, e.g.:
  ${FUNCNAME[0]} 123" >&2
   return 1
  fi
  gh_repo issue close "${number}"
}

tdo () {
  local number="${1}"
  if ! [[ $number =~ ^[0-9]+$ ]] ; then
   echo \
"Expected an issue number to open, e.g.:
  ${FUNCNAME[0]} 123" >&2
   return 1
  fi
  gh_repo issue view "${number}" --web
}

tdl () {
  local uri="$1"
  if [[ -z "${uri}" ]]; then
    echo \
"Expected a URL of an issue to link, e.g.:
  ${FUNCNAME[0]} https://github.com/owner/repo/issues/1" >&2
    return 1
  fi
  local issue_title
  issue_title=$(gh issue view "${uri}" --json title --jq '.title')
  gh_repo issue create --assignee @me --body "Notes for ${uri}" --title "${issue_title}"
}
