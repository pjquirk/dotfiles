# Personal Claude Instructions — PJ Quirk

## Identity

- **Name:** PJ Quirk
- **Email:** pquirk@nvidia.com
- **Role:** Software engineer at NVIDIA (hardware infrastructure / SCM tooling)
- **Primary repo host:** GitLab (`gitlab-master.nvidia.com` / `jirasw.nvidia.com` Jira)

## Git & Code Review

- Use `glab` (not `gh`) for all GitLab MR operations.
- Commit email must be `pquirk@nvidia.com`.
- MR titles should be a easy-to-read summary of the changes in the branch.
- Target branch for MRs is `main` unless told otherwise.
- Always push the source branch to the remote and set the local branch to track the remote before creating an MR (`--push` flag or prior `git push --set-upstream origin <branch name>`).

## Communication Style

- Keep responses short and direct — no trailing summaries of what was just done.
- No emojis unless explicitly requested.
- Use markdown link syntax for file/line references, not backtick paths.

## Tooling Preferences

- Shell: bash
- Linters are CI-pinned — never suggest unpinned versions.

## Workflow Defaults

- Check for a `CLAUDE.md` in any project before starting work — project rules override these personal defaults.
- Do not push to `main` directly; always use a branch + MR.
