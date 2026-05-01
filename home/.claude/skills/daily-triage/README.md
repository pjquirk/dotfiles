# Daily Triage

Generates a combined daily brief at the start of each work day. Run it each morning to get:

- **Quick Starts** — fast tasks (< 5 min each) to knock out before diving in
- **Yesterday's Work** — concise project-grouped summary of what was done, with linked evidence
- **Today's Next Steps** — prioritized actions and discussions needed, grouped by project

Output is saved as `{notes_dir}/{YYYY}/{MM - Month}/{YYYY-MM-DD}.md`.

## Setup

1. Copy the example config:

   ```bash
   cp ~/.claude/skills/daily-triage/daily-triage.example.yaml ~/.claude/daily-triage.yaml
   ```

2. Edit `~/.claude/daily-triage.yaml` and set at minimum: `notes_dir: "/path/to/your/Nvidia/notes/folder"`
3. Optionally create a `workstreams.md` in your current month folder to anchor project names and TODOs
4. Run the skill at the start of each work day: `/daily-triage`

## Configuration

| Field | Required | Description |
|---|---|---|
| `notes_dir` | Yes | Root of your notes directory. Output goes in `{notes_dir}/{YYYY}/{MM - Month}/{YYYY-MM-DD}.md` |
| `priorities` | No | List of project names to rank first in the next-steps section |

## Baseline File (auto-discovered)

The skill automatically searches for `workstreams.md` — no config needed. Search order:

1. `{notes_dir}/{YYYY}/{MM - Month}/workstreams.md` — current month
2. `{notes_dir}/{YYYY}/{MM - Month}/workstreams.md` — prior month
3. Most recently modified `workstreams.md` anywhere under `notes_dir`

Put project names, open `- [ ]` items, and "Next:" notes in this file and the skill will use them to anchor project grouping and seed the next-steps section. If no `workstreams.md` is found, projects are inferred from signal content (email subjects, MR titles, chat names).

Data Sources

The skill queries these sources and skips any that are unavailable:

┌───────────────┬──────────────┬───────────────────────────────────────────────────┐
│    Source     │     CLI      │                 What it extracts                  │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Outlook sent  │ outlook-cli  │ Emails you sent yesterday (strongest work signal) │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Outlook inbox │ outlook-cli  │ Inbound requests, threads awaiting response       │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Calendar      │ calendar-cli │ Meetings attended yesterday; upcoming meetings    │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Teams         │ teams-cli    │ Chats, decisions, docs shared                     │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Slack         │ slack-cli    │ Messages you sent, DMs needing reply              │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ GitLab        │ glab         │ MRs opened/reviewed/merged                        │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Jira          │ jira-cli     │ Issues updated (requires API token auth)          │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Perforce      │ p4           │ Changelists submitted                             │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Google Drive  │ gdrive-cli   │ Docs modified                                     │
├───────────────┼──────────────┼───────────────────────────────────────────────────┤
│ Local notes   │ find         │ Recently edited markdown files                    │
└───────────────┴──────────────┴───────────────────────────────────────────────────┘

Example Output

```md
# 2026-04-30 — Daily Brief

**Wrap-up window:** 2026-04-29
**Sources:** outlook (sent 4, inbox 12), calendar (3 meetings), teams, slack, gitlab

---

## Quick Starts

- [ ] Accept/decline: Madhu's Farewell meeting invite (notResponded)
- [ ] Reply to Jai re: bare metal Rocky machine request

---

## Yesterday's Work

### Shadow Sync

- Debugged container SSH alias issue with Shawn; `gitlab-to-p4` resolves inconsistently[^1]
- George shared Rocky Linux host list and Ansible server URL in containers meeting[^2]

### git2p4

- Investigated git2p4 production issue on dc6-git-gf-21 with Jai and Zac[^3]

---

## Today's Next Steps

### Shadow Sync

- [ ] Follow up with Jai on bare metal Rocky machine — blocking all non-prod testing
- [ ] Read Docker/NFS docs Shawn shared[^4]

**Discussions needed:**
- Sync with Kevin (Mon 2026-05-04, already planned) re: deployment location

---

[^1]: Teams "Git2P4 debug session" 2026-04-29
[^2]: Teams "talk about containers" 2026-04-29
[^3]: Teams "Investigate git2p4 issue" 2026-04-28
[^4]: https://docs.google.com/document/d/...
```
