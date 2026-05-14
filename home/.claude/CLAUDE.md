# Personal Claude Instructions — PJ Quirk

## Identity

- **Name:** PJ Quirk
- **Email:** pquirk@nvidia.com
- **Role:** Software engineer at NVIDIA (hardware infrastructure / SCM tooling)
- **Primary repo host:** GitLab (`gitlab-master.nvidia.com` / `jirasw.nvidia.com` Jira)

## Git & Code Review

- Use `glab` (not `gh`) for all GitLab MR operations.
- Commit email must be `pquirk@nvidia.com`.
- MR titles follow the format: `<Short description> (est. review time N minutes)`.
- Target branch for MRs is `main` unless told otherwise.
- Always push the source branch before creating an MR (`--push` flag or prior `git push`).

## Communication Style

- Keep responses short and direct — no trailing summaries of what was just done.
- No emojis unless explicitly requested.
- Use markdown link syntax for file/line references, not backtick paths.

## Tooling Preferences

- Shell: bash
- Linters are CI-pinned — never suggest unpinned versions.

## Workflow Defaults

- When creating MRs, include an estimated review time in the title.
- Check for a `CLAUDE.md` in any project before starting work — project rules override these personal defaults.
- Do not push to `main` directly; always use a branch + MR.
