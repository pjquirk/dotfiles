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
- `notes_dir` — root of the notes directory (ask the user if not set)
- `priorities` — optional list of priority project names

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

# Override: use the mtime of the most recent prior triage file if one exists.
# This preserves the exact time-of-day the last triage was generated, so queries
# pick up everything that happened after that run — not just after midnight.
# Triage files are named YYYY-MM-DD.md under notes_dir.
LAST_TRIAGE=$(find "{notes_dir}" -name "20[0-9][0-9]-[0-9][0-9]-[0-9][0-9].md" \
  -not -name "$TODAY.md" -not -path "*/\.*" \
  -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

if [ -n "$LAST_TRIAGE" ]; then
  SINCE=$(date -r "$LAST_TRIAGE" +%Y-%m-%d)
  SINCE_DATETIME=$(date -r "$LAST_TRIAGE" +%Y-%m-%dT%H:%M:%S)
fi

P4_SINCE=$(date -r "${LAST_TRIAGE:-/dev/null}" +%Y/%m/%d 2>/dev/null || date -d "$SINCE" +%Y/%m/%d)
P4_SINCE_TIME=$(date -r "${LAST_TRIAGE:-/dev/null}" +%H:%M:%S 2>/dev/null || echo "00:00:00")
P4_TODAY=$(date +%Y/%m/%d)
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

Run all auth checks **before** touching any data source. A tool that is not installed should be skipped gracefully (noted in the Sources line later). Some tools are optional and skipped gracefully when unauthenticated (slack-cli, jira-cli, gdrive-cli — Claude cannot access their secrets). Other tools are required and cause a hard stop if unauthenticated — collect all failures, report them together, and do not proceed to Step 1.

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

#### p4

```bash
p4 login -s 2>&1
```

Authenticated if the command succeeds and output contains a ticket expiry line. If the command fails due to a **network/server error** (e.g. "Connect to server failed"), treat p4 as unavailable and skip it gracefully — that is a connectivity issue, not an auth failure.

---

**If any required tool failed auth**, stop here. Do not proceed to Step 1. Tell the user:

```
Auth check failed for the following tools — fix these before re-running:

- outlook / calendar / teams  →  run: outlook-cli auth login
                                  (or use the `authenticating-entra-device-code` skill)
- glab                        →  run: glab auth login --hostname gitlab-master.nvidia.com
- p4                          →  run: p4 login
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

Attended meetings = discussions, decisions, or reviews. Note meeting names and any outcome context visible in the body preview.

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

```bash
glab mr list --author @me --output json
glab mr list --reviewer @me --output json
```

Filter for items with `updated_at >= $SINCE_DATETIME`. Note: MR title, URL, status changes (opened/merged/approved/commented), linked issue numbers.

#### 1g. Jira — Issues Updated Yesterday (skip if auth unavailable)

```bash
jira-cli issue find "assignee = currentUser() AND updated >= \"$SINCE_DATETIME\" ORDER BY updated DESC" --limit 20 --toon
```

If this returns an auth error, skip and note "Jira: auth required" in sources.

#### 1h. Perforce — Changelists Submitted (skip if p4 unavailable)

```bash
p4 changes -u $USER -s submitted @${P4_SINCE}:${P4_SINCE_TIME},@$P4_TODAY
```

Extract CL numbers and descriptions. Link each as `https://p4hw-swarm.nvidia.com/changes/CLNUM`.

#### 1i. Google Drive — Docs Edited Yesterday (skip if gdrive-cli unavailable)

```bash
gdrive-cli search --query "modified:yesterday" --limit 10 --output json
```

Extract doc names and URLs for files created or significantly edited.

#### 1j. Local Notes — Recently Modified Files (work diary)

```bash
# Use the triage file itself as the reference when available — exact mtime, no rounding.
# Fall back to a synthetic reference file at $SINCE midnight when there is no prior triage.
if [ -n "$LAST_TRIAGE" ]; then
  REF="$LAST_TRIAGE"
else
  touch -t $(date -d "$SINCE 00:00" +%Y%m%d%H%M) $TMPDIR/wrapup-ref
  REF=$TMPDIR/wrapup-ref
fi
find "{notes_dir}" -name "*.md" -newer "$REF" -not -path "*/\.*" 2>/dev/null
```

These files are a work diary — they often contain the richest record of what was actually done. **Read each one** and extract:
- Completed items (checked `- [x]`, crossed out, or described in past tense)
- Commands run, bugs found, decisions made, things figured out
- Names of collaborators mentioned in context
- Any URLs or references added (bugs, MRs, docs)

Treat this source as equally authoritative as email and Teams for the wrap-up section.

---

### Step 2: Synthesize Recent Work by Project

Group all signals from Step 1 into projects/workstreams. Use workstream names from `$BASELINE` if found; otherwise infer from signal content (email subjects, MR titles, Teams chat names).

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

From Step 1f results: MRs in "opened" or "review_requested" state that need attention.

#### 3e. Open Jira Issues

From Step 1g results (if available): issues in "In Progress", "To Do", or "Open" state.

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

---

### Step 5: Synthesize Today's Next Steps by Project

Use signals from Step 3 plus any open items from `$BASELINE` (if found).

For each project:
- List open actions as `- [ ]` checkboxes, ≤ 15 words each
- Note discussions needed: who, why, urgency (this week / soon / when convenient)
- Use footnotes for MR URLs, Jira ticket links, bug numbers

Prioritization within each project:
1. Blocking others — someone is waiting on you
2. Time-sensitive — known deadline or meeting today
3. Quick wins — < 30 min, clears an open thread
4. Exploratory — no external pressure

If `priorities` is configured, boost those project sections to the top of the Next Steps section.

Also emit a **Scheduling Needed** sub-section for syncs that need to be booked:
- Can it piggyback on an existing calendar meeting?
- Does it need a new slot?

---

### Step 6: Write the Output File

Path: `{notes_dir}/{YEAR}/{MONTH_FOLDER}/{TODAY}.md`

```markdown
# {TODAY} — Daily Brief

**Wrap-up window:** {SINCE_DATETIME} → now
**Sources:** outlook (sent N, inbox N), calendar (N meetings), teams, slack, gitlab[, jira][, p4][, gdrive]

---

## Quick Starts

- [ ] {fast task — < 5 min}
- [ ] {fast task}

---

## Yesterday's Work

### {Project 1}

- {What was done — one sentence}[^1]
- {Another thing done}[^2][^3]

### {Project 2}

- ...

---

## Today's Next Steps

### {Project 1}

- [ ] {action item}[^4]
- [ ] {action item}

**Discussions needed:**
- Sync with {person} re: {topic} — urgency: {this week / soon / when convenient}

### {Project 2}

- [ ] ...

### Scheduling Needed

- {Person + topic} — {piggyback on existing meeting OR needs new slot}

---

[^1]: {URL}
[^2]: {URL}
```

**Format rules:**
- Past tense in the wrap-up; imperative in next steps
- Footnotes for all external links; keep prose clean
- Quick Starts appear before everything else
- Max 5 bullets per project in the wrap-up; merge minor items if needed
- Omit entire sections (including the project header) if there are no signals for that project
- No redundancy: if something is done, it does not appear in next steps

---

## Privacy

This skill reads sent email, calendar events, Teams and Slack messages, GitLab MR data, Jira issues, Perforce changelists, Google Drive file metadata, and local notes files. All access goes through authenticated CLIs (outlook-cli, calendar-cli, teams-cli, slack-cli, glab, jira-cli, p4, gdrive-cli); this skill does not bypass access controls. Output is saved locally to your configured `notes_dir`. Review before sharing — the output may aggregate content from multiple sensitive sources.
