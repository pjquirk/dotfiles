---
name: "daily-triage"
description: "Generate a daily triage brief at the start of each work day: yesterday's summary plus today's prioritized actions and quick-start tasks, grouped by project with linked evidence."
title: "Daily Triage"
metadata:
  author: "PJ Quirk <pquirk@nvidia.com>"
  tags:
    - productivity
    - daily-summary
    - daily-triage
    - next-actions
    - outlook
    - slack
    - teams
    - gitlab
    - jira
  team: "hwinf-scm"
  domain: "personal-productivity"
version: "1.0.0"
---

# Daily Triage

Generate a combined daily brief at the start of each work day:
- **Quick Starts** — fast morning tasks (replies, scheduling) to clear the decks
- **Yesterday's Work** — concise summary of what was done, grouped by project, with linked evidence
- **Today's Next Steps** — prioritized actions and discussions needed, grouped by project

## Configuration

Read `~/.claude/daily-triage.yaml` if it exists. See [README.md](README.md) for all fields and defaults.

## When to Use This Skill

Use when the user asks to:
- Generate a daily triage or daily brief
- Start the day / prepare for the day
- See what was done yesterday
- Create a daily note or morning summary

## Instructions

### Step 0: Read Config and Compute Dates

Read `~/.claude/daily-triage.yaml`. Extract:
- `notes_dirs` — ordered list of candidate notes directories; use the first one that exists on disk. Falls back to `notes_dir` (scalar) for backwards compatibility. If neither is set, or none of the listed paths exist, **stop immediately** — do not ask the user for the location.
- `priorities` — optional list of priority project names

Resolve `notes_dir` (the active notes directory) as follows:
1. If `notes_dirs` is a non-empty list, iterate in order and use the first path that exists (`test -d`). If none exist, stop and tell the user: `No notes directory found — set notes_dirs in ~/.claude/daily-triage.yaml.`
2. Otherwise if `notes_dir` (scalar) is set, check that it exists (`test -d`). If it does not exist, stop with the same message.
3. If neither key is present in the config file (or the file is absent), stop with the same message.

Compute dates:

```bash
TODAY=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%u)   # 1=Mon … 7=Sun
YEAR=$(date +%Y)
MONTH_FOLDER=$(date +"%m - %B")   # e.g. "04 - April"
PREV_MONTH_FOLDER=$(date -d "1 month ago" +"%m - %B")
PREV_YEAR=$(date -d "1 month ago" +%Y)
THREE_DAYS=$(date -d "3 days" +%Y-%m-%d)

# Default lookback: last business day at midnight (used when no prior triage file exists)
if [ "$DAY_OF_WEEK" = "1" ]; then
  SINCE=$(date -d "3 days ago" +%Y-%m-%d)   # Monday → last Friday
else
  SINCE=$(date -d "1 day ago" +%Y-%m-%d)
fi
SINCE_DATETIME="${SINCE}T00:00:00"

# Override: use the creation time of the most recent prior triage file if one exists.
# This preserves the exact time-of-day the last triage was generated, so queries
# pick up everything that happened after that run — not just after midnight.
# Triage files are named YYYY-MM-DD.md under notes_dir.
LAST_TRIAGE=$(find "{notes_dir}" -name "20[0-9][0-9]-[0-9][0-9]-[0-9][0-9].md" \
  -not -name "$TODAY.md" -not -path "*/\.*" \
  -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

if [ -n "$LAST_TRIAGE" ]; then
  # Use birth time (creation time), not mtime — the user edits the triage file
  # throughout the day, advancing mtime and shrinking the next day's lookback window.
  BIRTH=$(stat --format="%W" "$LAST_TRIAGE" 2>/dev/null)
  if [ -n "$BIRTH" ] && [ "$BIRTH" != "0" ]; then
    SINCE=$(date -d "@$BIRTH" +%Y-%m-%d)
    SINCE_DATETIME=$(date -d "@$BIRTH" +%Y-%m-%dT%H:%M:%S)
  else
    # Fallback: mtime if filesystem doesn't support birth time
    SINCE=$(date -r "$LAST_TRIAGE" +%Y-%m-%d)
    SINCE_DATETIME=$(date -r "$LAST_TRIAGE" +%Y-%m-%dT%H:%M:%S)
  fi
fi

# ET display version — server runs in UTC; always show Eastern to the user.
SINCE_DATETIME_ET=$(TZ="America/New_York" date -d "$SINCE_DATETIME" +"%Y-%m-%dT%H:%M:%S")

```

Output path: `{notes_dir}/{YEAR}/{MONTH_FOLDER}/{TODAY}.md`

Create the month directory if it does not exist:

```bash
mkdir -p "{notes_dir}/{YEAR}/{MONTH_FOLDER}"
```

**Locate the baseline file.** Search for `workstreams.md` in order of preference — current month first, then prior month, then anywhere under `notes_dir`:

```bash
BASELINE=""
CURRENT_WS="{notes_dir}/{YEAR}/{MONTH_FOLDER}/workstreams.md"
PREV_WS="{notes_dir}/{PREV_YEAR}/{PREV_MONTH_FOLDER}/workstreams.md"

if [ -f "$CURRENT_WS" ]; then
  BASELINE="$CURRENT_WS"
elif [ -f "$PREV_WS" ]; then
  BASELINE="$PREV_WS"
else
  BASELINE=$(find "{notes_dir}" -name "workstreams.md" -not -path "*/\.*" \
    -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
fi
```

If `$BASELINE` is non-empty, read it to extract active workstream names and any open "Next:" / `- [ ]` items. If not found, infer workstreams from signal content in Step 1.

---

### Step 0.5: Auth Pre-Flight Check

Run all auth checks **before** touching any data source. A tool that is not installed should be skipped gracefully (noted in the Sources line later). Some tools are optional and skipped gracefully when unauthenticated (slack-cli, jira-cli, gdrive-cli — Claude cannot access their secrets or they may be network-unavailable). Other tools are required and cause a hard stop if unauthenticated — collect all failures, report them together, and do not proceed to Step 1.

Run these checks in parallel:

#### Entra CLIs — outlook-cli, calendar-cli, teams-cli (shared token cache)

```bash
outlook-cli auth status --json 2>/dev/null
```

Authenticated if the JSON field `"authenticated"` is `true`. One check covers all three Entra CLIs.

#### slack-cli

```bash
slack-cli auth status 2>&1
```

Authenticated if output does **not** contain `"Not authenticated"`. **Optional** — if unauthenticated, skip gracefully and note "slack: auth unavailable" in Sources.

#### glab (NVIDIA GitLab)

```bash
glab auth status --hostname gitlab-master.nvidia.com 2>&1
```

Authenticated if output does **not** contain `"not authenticated"` (case-insensitive). Only check `gitlab-master.nvidia.com` — not being logged into `gitlab.com` is not a failure.

#### jira-cli

```bash
jira-cli auth status 2>&1
```

Authenticated if output does **not** contain `"✗ Not authenticated"`. **Optional** — if unauthenticated, skip gracefully and note "jira: auth unavailable" in Sources.

#### gdrive-cli

```bash
gdrive-cli auth status 2>&1
```

Authenticated if output does **not** contain `"Not authenticated"`. **Optional** — if unauthenticated, skip gracefully and note "gdrive: auth unavailable" in Sources.

#### nvbugs-cli

```bash
nvbugs-cli auth status 2>&1
```

**Optional** — skip gracefully and note "nvbugs: auth unavailable" in Sources if not authenticated or not installed. Authenticated if output contains `"authenticated": true` or does **not** contain `"Authenticated: false"`.

---

**If any required tool failed auth**, stop here. Do not proceed to Step 1. Tell the user:

```
Auth check failed for the following tools — fix these before re-running:

- outlook / calendar / teams  →  run: outlook-cli auth login
                                  (or use the `authenticating-entra-device-code` skill)
- glab                        →  run: glab auth login --hostname gitlab-master.nvidia.com
```

Only include the tools that actually failed. Tools that were not installed should be omitted from this list (they will just be absent from the Sources line). slack-cli, jira-cli, and gdrive-cli are optional — their auth failures are not a hard stop and should not appear here.

---

### Step 1: Gather Yesterday's Work Signals (run in parallel)

Query all sources for the date range `$SINCE` through `$TODAY`. Skip any source gracefully if it errors or requires additional setup — note it in the Sources line of the output.

#### 1a. Outlook — Sent Items (strongest signal)

```bash
outlook-cli message find --folder sent --after "$SINCE_DATETIME" --limit 50 --toon
```

Each sent item = work delivered or coordination done. Extract: subject, recipients, brief topic.

#### 1b. Outlook — Inbox (inbound threads you handled)

```bash
outlook-cli message find --after "$SINCE_DATETIME" --limit 30 --toon
```

Look for threads that likely resolved or where you made commitments.

#### 1c. Calendar — Meetings Attended Since Last Triage

```bash
calendar-cli find --after "$SINCE_DATETIME" --before $TODAY --toon
```

Attended meetings = discussions, decisions, or reviews. Note meeting names, event IDs, and any outcome context visible in the body preview. Preserve the event IDs — they are required for Step 1c.ii.

#### 1c.ii. Meeting Transcripts — Create Notes

For each calendar event from Step 1c, attempt to fetch and summarize its transcript, then write a meeting note file into the current month's directory.

**Folder mapping:** Read workstream names from `$BASELINE`. Each workstream maps to a subdirectory:
`{notes_dir}/{YEAR}/{MONTH_FOLDER}/{workstream-name}/`

For meetings that don't match any workstream, use `Meetings` as the folder name.

**For each calendar event (run in parallel where feasible):**

1. Attempt to read the transcript:

```bash
transcript-cli read --event-id <event-id> --toon 2>/dev/null
```

2. If no transcript is returned (transcription was not enabled or recording unavailable), skip this meeting silently.

3. Sanitize the meeting title for use as a filename — strip path-unsafe characters and trim to 100 characters:

```bash
SAFE_TITLE=$(echo "$MEETING_TITLE" | tr -d '/:*?"<>|\\' | sed 's/  */ /g' | cut -c1-100)
```

4. Map to a workstream: read the meeting title, attendees, and transcript content, then pick the workstream from `$BASELINE` whose name and open items best match the meeting topic. If no workstream clearly fits, use `Meetings`.

5. Determine the output path and skip if the file already exists (avoid overwriting notes you may have annotated):

```bash
MEETING_DIR="{notes_dir}/{YEAR}/{MONTH_FOLDER}/{workstream-or-Meetings}"
mkdir -p "$MEETING_DIR"
MEETING_FILE="$MEETING_DIR/Meeting - $SAFE_TITLE.md"
# Skip if already exists
[ -f "$MEETING_FILE" ] && continue
```

6. Write the meeting note file:

```markdown
# {Meeting Title}

**Date:** {date of meeting}
**Attendees:** {comma-separated list of attendees}

## Summary

{2–4 sentence summary of what was discussed and why it matters}

## Key Points

- {key discussion point or decision}
- ...

## Action Items

- [ ] {action item} — {owner if mentioned}
- ...
```

Keep the Summary to 2–4 sentences. Extract action items from explicit commitments in the transcript ("I'll", "we'll", "action item", "follow up", "by end of week"). Omit the Action Items section if there are none.

After processing all meetings, record:
- A list of created file paths (for use in Step 2 and the Sources line)
- Count of meetings with transcripts vs. without

#### 1d. Teams — Chat Messages Since Last Triage

```bash
teams-cli chat list --json
```

For each non-trivial chat (skip onboarding, recurring HR noise), read recent messages:

```bash
teams-cli chat read <chat-id> --limit 20 --json
```

Filter messages to those created on or after `$SINCE`. Look for: messages you sent, decisions made, docs shared, action items. Collect message URLs where available.

#### 1e. Slack — Messages Sent Since Last Triage

```bash
slack-cli message search --query "from:me after:$SINCE_DATETIME" --limit 20
```

Extract: channels/DMs you were active in, topics discussed, commitments made.

#### 1f. GitLab — MR Activity

Run all three list queries in parallel:

```bash
# Open MRs I authored
GITLAB_HOST=gitlab-master.nvidia.com glab mr list --author @me --state opened -F json

# Open MRs where I am a reviewer
GITLAB_HOST=gitlab-master.nvidia.com glab mr list --reviewer @me --state opened -F json

# Recently merged authored MRs (for Yesterday's Work)
GITLAB_HOST=gitlab-master.nvidia.com glab mr list --author @me --state merged -F json
```

For each open authored MR, fetch full detail (run in parallel):

```bash
GITLAB_HOST=gitlab-master.nvidia.com glab mr view <number> -F json
```

From each `glab mr view` result, extract: `draft`, `pipeline.status` (success / failed / running / pending), `approved_by` (list), `reviewers` (list), `user_notes_count`, `updated_at`.

**Classify each authored MR** into exactly one state:

| State | Condition |
|---|---|
| **draft** | `draft: true` |
| **needs reviewer assigned** | not draft, `reviewers` is empty |
| **awaiting review** | reviewers assigned, no approvals, `updated_at < $SINCE_DATETIME` |
| **has feedback** | reviewer left comments or requested changes since last triage |
| **approved — ready to merge** | at least one approval, CI passing or no pipeline |
| **CI failing** | `pipeline.status == "failed"` |
| **merge blocked** | approved but explicitly blocked (deploy freeze, dependency, merge conflict) |

**Classify each reviewer MR** into one state:

| State | Condition |
|---|---|
| **needs my review** | I have not yet approved or left a comment |
| **reviewed — awaiting author** | I have commented or approved; author has not responded |

Note the MR number, title, URL, workstream (infer from repo name or MR title), days open, and assigned reviewers for use in Steps 2 and 5.

#### 1g. Jira — Issues Updated Yesterday (skip if auth unavailable)

```bash
jira-cli issue find "assignee = currentUser() AND updated >= \"$SINCE_DATETIME\" ORDER BY updated DESC" --limit 20 --toon
```

If this returns an auth error, skip and note "Jira: auth required" in sources.

#### 1h. Google Drive — Docs Edited Yesterday (skip if gdrive-cli unavailable)

```bash
gdrive-cli search --query "modified:yesterday" --limit 10 --output json
```

Extract doc names and URLs for files created or significantly edited.

#### 1j. Local Notes — Recently Modified Files (work diary)

```bash
# Use a reference file stamped at birth time of the last triage — consistent with
# SINCE_DATETIME. Fall back to a synthetic reference at $SINCE midnight if no prior triage.
if [ -n "$LAST_TRIAGE" ]; then
  BIRTH=$(stat --format="%W" "$LAST_TRIAGE" 2>/dev/null)
  if [ -n "$BIRTH" ] && [ "$BIRTH" != "0" ]; then
    touch -d "@$BIRTH" /tmp/triage-ref && REF=/tmp/triage-ref
  else
    REF="$LAST_TRIAGE"
  fi
else
  touch -t $(date -d "$SINCE 00:00" +%Y%m%d%H%M) /tmp/triage-ref
  REF=/tmp/triage-ref
fi
find "{notes_dir}" -name "*.md" -newer "$REF" -not -path "*/\.*" 2>/dev/null
```

These files are a work diary — they often contain the richest record of what was actually done. **Read each one** and extract:
- Completed items (checked `- [x]`, crossed out, or described in past tense)
- Commands run, bugs found, decisions made, things figured out
- Names of collaborators mentioned in context
- Any URLs or references added (bugs, MRs, docs)

Treat this source as equally authoritative as email and Teams for the wrap-up section.

#### 1k. Claude Conversations — Additional Context Only

Find JSONL transcript files modified since `$SINCE` across all Claude project directories, capped at the 30 most recently modified:

```bash
find ~/.claude/projects -name "*.jsonl" -newer "$REF" -not -path "*/\.*" \
  -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -30 | cut -d' ' -f2-
```

For each file found, extract user and assistant turns to surface:
- Bugs, MR numbers, or ticket IDs discussed
- Decisions made or conclusions reached
- Commands run and their outcomes
- Names of people or systems mentioned

**Critical constraint:** Do NOT produce standalone wrap-up bullets sourced solely from Claude conversations. Use this context only to enrich or add detail to signals already found via other sources (email, calendar, Teams, GitLab, notes). For example: if an email mentions bug 6142383 and a Claude conversation shows you investigated it and found the root cause, add that detail to the email-sourced bullet — don't create a new bullet just from the conversation.

#### 1l. NVBugs — Bug Activity (skip if nvbugs-cli unavailable)

Determine the current user's full name for NVBugs person-name searches:

```bash
NVBUGS_FULLNAME=$(git config user.name 2>/dev/null)
```

Run the following queries in parallel:

```bash
# Bugs where I am the assigned engineer
nvbugs-cli search bugs --engineer "$NVBUGS_FULLNAME" --toon 2>&1

# Bugs where I am action-required-by (ARB) — someone is waiting on me
nvbugs-cli search bugs --arb "$NVBUGS_FULLNAME" --toon 2>&1
```

From the results, identify bugs whose `ModifiedDate` falls on or after `$SINCE` — these are bugs with recent activity. For each such bug, note: bug ID, synopsis, status (`BugAction`), and priority.

**Bugs where I've recently commented:** nvbugs does not expose a global "bugs I commented on" query. Instead, collect any NVBugs bug IDs surfaced by other sources in Step 1 (emails, Teams messages, notes files, Claude transcripts) and fetch their current state:

```bash
nvbugs-cli bug get <bug-id> --toon 2>&1
```

Fetch each unique bug ID found in other signals that is not already returned by the engineer/ARB queries above. This captures bugs I'm actively discussing but not formally assigned to.

Link all bugs as `https://nvbugspro.nvidia.com/bug/BUGID`.

---

### Step 2: Synthesize Recent Work by Project

Group all signals from Step 1 into projects/workstreams. Use workstream names from `$BASELINE` if found; otherwise infer from signal content (email subjects, MR titles, Teams chat names).

Also incorporate meeting note files created in Step 1c.ii — they are a direct record of what was discussed. Pull concrete outcomes, decisions, and named collaborators from the meeting summaries into the appropriate project's wrap-up bullets. Link to the meeting note file using a footnote (relative path from `notes_dir`).

For each project, write 2–5 bullets in **past tense**:
- Concrete outcomes: "Debugged SSH alias issue with Shawn", "Merged MR for Ansible playbook"
- Credit collaborators by name
- Assign a footnote number (`[^N]`) to each artifact or conversation that has a URL
- Collect all URLs for the footnote block at the bottom

**Rules:**
- One sentence per bullet, ≤ 20 words
- No forward-looking statements ("Next:", "will do") — those go in Step 5
- Skip noise: automated Nagios alerts, routine notification emails, farewell threads with no work content
- If a signal is too ambiguous to describe concretely, skip it

---

### Step 3: Gather Today's Next-Step Signals (run in parallel)

These can reuse results already fetched in Step 1 where relevant.

#### 3a. Outlook — Inbound Requests Needing Response

From Step 1b results, scan for:
- Direct requests ("can you...", "please...", "need you to...")
- Threads where you were the last recipient but haven't replied
- Meeting follow-ups ("as discussed", "action item", "per our sync")

#### 3b. Calendar — Upcoming Meetings (next 3 business days)

```bash
calendar-cli find --after $TODAY --before $THREE_DAYS --toon
```

Identify: meetings needing prep, recurring syncs to bring status to, 1:1s needing talking points.

#### 3c. Baseline TODOs

From `$BASELINE` (if found) and notes modified in Step 1j, extract all open `- [ ]` / "Next:" / "TODO:" items.

#### 3d. Open GitLab MRs

From Step 1f classification results. For each open authored MR, map state to action:

| MR state | Action needed |
|---|---|
| draft | none — still in progress |
| needs reviewer assigned | assign reviewers |
| awaiting review | ping reviewers if stalled (no activity in 2+ days) |
| has feedback | respond to reviewer comments |
| approved — ready to merge | merge (or note what's blocking) |
| CI failing | fix pipeline |
| merge blocked | note the blocker explicitly |

For each reviewer MR in "needs my review" state, it's a direct action item regardless of age.

#### 3e. Open Jira Issues

From Step 1g results (if available): issues in "In Progress", "To Do", or "Open" state.

#### 3f. Open NVBugs

From Step 1l results (if available):
- Bugs assigned to me with status "HW - Open - To fix" or "HW - Open - To verify" — I need to take action or verify a fix.
- Bugs where I'm ARB — someone is waiting on me specifically.
- Bug IDs from other signals (email, Teams, notes) fetched in Step 1l — include their current status so I know what needs attention.

---

### Step 4: Identify Quick Starts

Quick Starts are tasks completable in < 5 minutes. Limit to 5–8 items.

Candidates (in priority order):
1. Unread/unreplied emails since `$SINCE` needing a short ack or 1–2 sentence reply
2. Slack or Teams DMs where you haven't responded
3. Calendar invites not yet accepted or declined
4. Short scheduling tasks ("send calendar invite to X for sync re: Y")
5. Flagged emails that just need a forward or quick ack

If an item requires more than 5 minutes of thought, move it to Next Steps instead.

**Dual-listing is intentional:** a Quick Start item may be the immediate 2-minute action (e.g., "ping Oleg re: Bug 6142383") while the same bug also appears in Next Steps carrying its full context and status. The Quick Start is the action; Next Steps is the work. Do not collapse them.

---

### Step 5: Synthesize Today's Next Steps by Project

Use signals from Step 3 plus any open items from `$BASELINE` (if found).

For each project:
- List open actions as `- [ ]` checkboxes, ≤ 15 words each
- Use footnotes for MR URLs, Jira ticket links, bug numbers

**Stale item ordering:** Before writing a workstream's list, compare its open `- [ ]` items against the prior triage file (`$LAST_TRIAGE`). Items that appeared as unchecked in that file and remain unchecked now are "carried over." Place carried-over items at the *bottom* of their workstream's list, after new or recently progressed items. Do not create a separate section — position alone signals freshness.

Prioritization within each project (top to bottom, then carried-over items last):
1. Blocking others — someone is waiting on you
2. Time-sensitive — known deadline or meeting today
3. Quick wins — < 30 min, clears an open thread
4. Exploratory — no external pressure
5. Carried over from prior triage (unchanged, no recent activity)

If `priorities` is configured, boost those project sections to the top of the Next Steps section.

For each open NVBug from Step 3f, add it to the relevant project's Next Steps as a `- [ ]` checkbox. Format as: `- [ ] Bug NNNNNN: {synopsis} — {status} [{priority}]` with a footnote link. Group bugs by project/workstream where possible; put unclassified bugs under a **NVBugs** subsection. Bugs in "To verify" status should be flagged as needing explicit follow-up.

Emit a **GitLab MRs** subsection listing all open MRs. Place it before the workstream sections so it's always visible at the top of Today's Next Steps. Omit MRs in `draft` or `reviewed — awaiting author` states (no action needed from you). Format:

```
### GitLab MRs

**Authored:**
- [ ] !NNN: {title} — {state label}[^N]

**Reviewing:**
- [ ] !NNN: {title} ({author}) — needs review[^N]
```

State labels for authored MRs: `awaiting review — N days` / `has feedback` / `ready to merge` / `CI failing` / `blocked: {reason}` / `assign reviewers`. Omit the "Authored:" or "Reviewing:" sub-heading if that group is empty. Omit the entire GitLab MRs section if there are no actionable MRs.

Also emit a **Scheduling Needed** sub-section for syncs that need to be booked:
- Can it piggyback on an existing calendar meeting?
- Does it need a new slot?

---

### Step 6: Write the Output File

Path: `{notes_dir}/{YEAR}/{MONTH_FOLDER}/{TODAY}.md`

```markdown
# {TODAY} — Daily Brief

---

## Quick Starts

- [ ] {fast task — < 5 min}
- [ ] {fast task}

---

## Today's Next Steps

### GitLab MRs

**Authored:**
- [ ] !NNN: {title} — {state label}[^1]

**Reviewing:**
- [ ] !NNN: {title} ({author}) — needs review[^2]

### {Project 1}

- [ ] {action item}[^3]
- [ ] {action item}

### {Project 2}

- [ ] ...

### Scheduling Needed

- {Person + topic} — {piggyback on existing meeting OR needs new slot}

---

## Yesterday's Work

### {Project 1}

- {What was done — one sentence}[^2]
- {Another thing done}[^3][^4]

### {Project 2}

- ...

---

**Wrap-up window:** {SINCE_DATETIME_ET} ET → now
**Sources:** outlook (sent N, inbox N), calendar (N meetings, N transcripts), teams, slack, gitlab[, jira][, gdrive][, nvbugs (N assigned, N arb)][, claude transcripts]

[^1]: {URL}
[^2]: {URL}

---

## End of Day

### What I Got Done Today

<!-- fill in at end of day -->

### Thoughts for Tomorrow

<!-- fill in at end of day -->
```

**Format rules:**
- Past tense in the wrap-up; imperative in next steps
- Footnotes for all external links; keep prose clean
- Section order: Quick Starts → Today's Next Steps → Yesterday's Work → Wrap-up window + Sources → Footnotes → End of Day
- Max 5 bullets per project in the wrap-up; merge minor items if needed
- Omit entire sections (including the project header) if there are no signals for that project
- No redundancy: if something is done, it does not appear in next steps
- The **End of Day** section is intentionally left empty — it is a fill-in-later journal prompt, not generated content

---

### Step 7: Update workstreams.md

Update the current month's `workstreams.md` (`$CURRENT_WS`) to reflect what was done and what remains open. **Only run this step if `$BASELINE` equals `$CURRENT_WS`** — do not write to a prior-month file.

Make three passes, then write the updated file:

1. **Mark completed items.** For each `- [ ]` item in workstreams.md, check whether it matches something in Yesterday's Work (Step 2) that was completed — an item explicitly checked (`- [x]`) in a notes file, an MR described as merged, or a bug described as closed. If matched, change `- [ ]` to `- [x]`. Match on artifact identifiers (bug ID, MR number) or close text similarity; do not require exact string match.

2. **Add new open items.** For each `- [ ]` item generated in Today's Next Steps (Step 5) that references a concrete artifact (bug ID, MR number, named task), check whether a matching item already exists in workstreams.md. If not present, append it to the end of the appropriate workstream section.

3. **Rewrite "Next:" lines.** For each workstream section, rewrite the trailing `Next:` line (or add one if absent) to reflect the 2–3 highest-priority open items remaining for that workstream, drawn from Today's Next Steps.

Keep all existing content — only change `[ ]` → `[x]` for completed items, append missing open items, and update `Next:` lines. Never remove or reorder existing items.

---

## Privacy

This skill reads sent email, calendar events, Teams and Slack messages, GitLab MR data, Jira issues, Google Drive file metadata, NVBugs bug data, local notes files, and Claude conversation transcripts stored under `~/.claude/projects/`. All external access goes through authenticated CLIs (outlook-cli, calendar-cli, teams-cli, slack-cli, glab, jira-cli, gdrive-cli, nvbugs-cli); this skill does not bypass access controls. Output is saved locally to your configured `notes_dir`. Review before sharing — the output may aggregate content from multiple sensitive sources.
