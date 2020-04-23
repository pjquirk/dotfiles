# dotfiles

My various dotfiles, backed up via cron.

On my dev machine, I've set the backup script to run once a day when it's probably turned on:

```sh
# Open my cron jobs in an editor
crontab -e

# Add this line in the file
0 12 * * * cd /Users/pjquirk/Source/GitHub/dotfiles && ./backup.sh
```
