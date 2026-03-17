# dotfiles

## Setup

Clone the repo, then run the bootstrap script to install dependencies and copy dotfiles to your home directory:

```bash
git clone https://github.com/pjquirk/dotfiles.git ~/dotfiles
~/dotfiles/script/bootstrap
```

## Usage

**Pull** — get the latest dotfiles from the remote and overwrite your local copies:

```bash
script/pull
```

**Push** — copy your local dotfiles into the repo, commit, and push to remote:

```bash
script/push
```
