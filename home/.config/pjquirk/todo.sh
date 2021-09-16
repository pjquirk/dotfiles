#!/usr/env/var bash
# shellcheck shell=bash

CLI_NAME='todo'

todo_help () {
  echo "ToDo Tracking with gh CLI

Usage: ${CLI_NAME} [command]

Commands:
  <no arg>          Displays current list of issues
  new (create)      Creates a new issue in the linked repository
  close             Closes an existing issue in the linked repository
  ref               Creates a new issue to track a different given issue
  open (view)       Opens the given issue in a browser
  help              Displays this message
"
  return 1
}

gh_repo () {
  gh --repo pjquirk/worknotes "$@"
}

todo_list () {
  gh_repo issue list --assignee @me
}

todo_new () {
  IFS=' ' # make sure "$*" is joined with spaces
  # Glob all arguments into a string
  local title="$*"
  if [[ -z "${title}" ]]; then
    echo \
"Creates a new issue in the linked repository.

Usage: ${CLI_NAME} new <title>
Examples:
  ${CLI_NAME} new A pretty standard title
  ${CLI_NAME} new \"A title that contains an ' or \" character\"" >&2
    return 1
  fi
  gh_repo issue create --assignee @me --body "" --title "${title}"
}

todo_close () {
  local number="${1}"
  if ! [[ $number =~ ^[0-9]+$ ]] ; then
   echo \
"Closes an existing issue in the linked repository.

Usage: ${CLI_NAME} close <issue number>
Examples:
  ${CLI_NAME} close 123" >&2
   return 1
  fi
  gh_repo issue close "${number}"
}

todo_open () {
  local number="${1}"
  if ! [[ $number =~ ^[0-9]+$ ]] ; then
    echo \
"Opens an issue in a browser.

Usage: ${CLI_NAME} open <issue number>
Examples:
  ${CLI_NAME} open 123" >&2
   return 1
  fi
  gh_repo issue view "${number}" --web
}

todo_ref () {
  local uri="$1"
  if [[ -z "${uri}" ]]; then
    echo \
"Creates a new issue to track a different given issue.

Usage: ${CLI_NAME} ref <issue URI>
Examples:
  ${CLI_NAME} ref https://github.com/owner/repo/issues/1" >&2
    return 1
  fi
  local issue_title
  issue_title=$(gh issue view "${uri}" --json title --jq '.title')
  gh_repo issue create --assignee @me --body "Notes for ${uri}" --title "${issue_title}"
}

todo () {
  local command="$1"
  if [[ -z "$command" ]]; then
    todo_list
  else
    shift # Remove the command from the list of args
    case "$command" in
      new|create)
        todo_new "$@"
        ;;
      close)
        todo_close "$@"
        ;;
      ref)
        todo_ref "$@"
        ;;
      open|view)
        todo_open "$@"
        ;;
      help)
        todo_help
        ;;
      *)
        echo "Unknown command: $command" >&2
        todo_help
        ;;
    esac
  fi
}
