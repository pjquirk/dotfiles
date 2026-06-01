---
name: git-stack
description: Manage stacked branches with git-stack. Use when creating a series of dependent branches, rebasing a stack after its base moves, removing a merged branch from a stack, or viewing what's in a stack.
---

# git stack

`git stack` manages stacks of dependent branches — a series of topic branches
where each builds on the previous. Use it when work is too large for one branch
but the pieces must land in order.

Branch names follow the pattern `<prefix>/<stackname>-<branchname>`, where
`prefix` defaults to the local part of `user.email`. Override permanently with:

```bash
git config stack.prefix yourname
```

## Subcommands

### `git stack new <stackname>`

Initialize a new stack rooted at the **current branch**. Records the current
branch as the base in `.git/stacks/<stackname>`. Does not create any new branch.

```bash
# Start a stack from main
git checkout main
git stack new my-feature
```

### `git stack push <stackname> <branchname>`

Create `<prefix>/<stackname>-<branchname>` from HEAD and append it to the stack.
Warns if HEAD is not at the current stack top.

```bash
# Add two branches to the stack
git stack push my-feature step-one     # creates pquirk/my-feature-step-one
git stack push my-feature step-two     # creates pquirk/my-feature-step-two
```

### `git stack show <stackname>`

Print each branch in the stack with its most recent commit summary.

```bash
git stack show my-feature
```

### `git stack list [stackname]`

With no argument: list all stack names.  
With a name: list the branches in that stack (bare names, one per line).

```bash
git stack list                  # all stacks
git stack list my-feature       # branches in my-feature
```

### `git stack restack <stackname>`

Rebase every branch in the stack onto its (possibly moved) parent. Uses a
two-pass approach — all tips are snapshotted before any rebase runs, so moving
an earlier branch does not corrupt the upstream calculation for later ones.

```bash
# After the stack base (e.g. main) gets new commits:
git stack restack my-feature
```

### `git stack close <stackname> <branchname>`

Remove a merged branch from the stack and rebase everything above it onto its
former parent. Uses the **full branch name** as it appears in the stack file
(i.e. `pquirk/my-feature-step-one`, not just `step-one`). Does not delete the
branch — delete it separately once confirmed merged.

```bash
git stack close my-feature pquirk/my-feature-step-one
git branch -d pquirk/my-feature-step-one   # delete when safe
```

## Typical Workflow

```bash
# 1. Start from the integration point
git checkout main && git pull

# 2. Create the stack
git stack new my-feature

# 3. Add branches one at a time, committing work between pushes
git stack push my-feature part-one
# ... commit work ...
git stack push my-feature part-two
# ... commit work ...

# 4. Inspect the stack
git stack show my-feature

# 5. Push branches to remote for review (repeat per branch)
git push -u origin pquirk/my-feature-part-one
git push -u origin pquirk/my-feature-part-two

# 6. If the base branch moves, restack
git checkout main && git pull
git stack restack my-feature

# 7. After part-one merges, close it and push the rebased remainder
git stack close my-feature pquirk/my-feature-part-one
git push --force-with-lease origin pquirk/my-feature-part-two
```

## Tips

- Run `git stack show <name>` before restacking to confirm which branches
  will be touched.
- `close` rebases branches above the removed one automatically — always
  force-push those branches to remotes afterward.
- Stack metadata lives in `.git/stacks/` — it is local to your clone and
  not shared via remote.
- If HEAD is not at the stack top when you run `push`, you'll see a warning.
  Check out the top branch first unless you intentionally want to insert
  a branch mid-stack (unsupported — edit the stack file manually if needed).
