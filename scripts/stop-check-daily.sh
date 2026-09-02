#!/usr/bin/env sh
# gyeol Stop hook — enforce daily episode log
#
# Logic:
#   0. If the harness supplies no session_id -> pass with a systemMessage
#      saying so. Nothing here can be per-session without one, and a silent
#      pass would hide that.
#   1. If today's daily log already records THIS session (marker
#      `<!--sid:xxxxxxxx-->` on its session heading) -> pass.
#      File existence alone is not enough: on a multi-session day, or when
#      another harness (Gemini/Codex) wrote first, the file exists while this
#      session is unrecorded. 260902 audit: that single leniency is the root
#      of unlogged sessions, the parallel ~/.gemini/logs/sessions sink, and
#      the duplicate session numbering in the daily logs.
#   2. If session was not substantive (no Write/Edit/git commit)
#      -> pass silently.
#   3. If already nagged once this session -> pass with soft
#      systemMessage reminder (avoid infinite loop).
#   4. Otherwise -> decision: block, with a reason telling Claude to
#      write today's daily log before stopping. Mark session as nagged
#      so subsequent Stops don't loop.
#
# Input: Stop hook JSON on stdin (contains session_id).

set -eu

GYEOL_HOME="${GYEOL_HOME:-$HOME/.config/gyeol}"

# Decision keyword for the blocking JSON payload. Default is "block" which is
# what Claude Code's Stop hook and Codex's Stop hook expect. Gemini CLI's
# AfterAgent hook (the closest pre-exit analog) uses "deny" instead — set
# GYEOL_BLOCK_DECISION=deny in the Gemini hook command.
BLOCK_DECISION="${GYEOL_BLOCK_DECISION:-block}"

# If gyeol is not installed on this machine, no-op.
if [ ! -d "$GYEOL_HOME/memory" ]; then
  echo '{}'
  exit 0
fi

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')

TODAY=$(date +%Y-%m-%d)
DAILY_LOG="$GYEOL_HOME/memory/episodes/daily/${TODAY}.md"
SUBSTANTIVE_FLAG="/tmp/gyeol_session_${SESSION_ID}.substantive"
RECOVERY_FLAG="/tmp/gyeol_session_${SESSION_ID}.recovery"
NAGGED_FLAG="/tmp/gyeol_session_${SESSION_ID}.nagged"

# Short session id — the marker the agent puts on its own session heading.
SID_SHORT=$(printf '%s' "$SESSION_ID" | cut -c1-8)

# Case 0: no session id — this hook cannot enforce anything here, so say so.
#
# Nothing downstream works without an id. `post-mark-substantive.sh` exits early
# on an empty one, so SUBSTANTIVE_FLAG is never created and Case 2 would pass in
# silence; the three /tmp flags all collapse to `/tmp/gyeol_session_.*`, shared by
# every id-less session; and any placeholder marker one of them wrote would
# satisfy all the others — reproducing the day-granular hole this hook exists to
# close. Blocking every such session instead would be noise, since the agent
# cannot produce a marker it has no id for. So: pass, touch no flags, and make
# the gap visible rather than silent (feedback_guard_maps_unparsed_to_pass).
if [ -z "$SID_SHORT" ]; then
  jq -n --arg log "$DAILY_LOG" '{
    systemMessage: ("gyeol: this harness supplies no session_id, so the Stop hook cannot tell whether this session was recorded — no per-session enforcement here, by structure, not by choice. Write your section in " + $log + " anyway: `## S{n} — {time range} — {topic}`, newest first under the date heading, with tldr / Outcome / Decisions / Next / Artifacts / Verification as H3 headings. If you are seeing this on a harness that does have session ids, that is a wiring bug worth reporting.")
  }'
  exit 0
fi

# Case 1: today's log already records THIS session — clean up and pass.
# The `<!--sid:...-->` marker must sit on a `## ` heading. Both anchors matter:
# without `^## ` a bare substring also matches prose that merely quotes a marker
# — today's log describes this very change in prose — so a session could pass by
# writing *about* a marker instead of writing a section
# (feedback_heading_anchor_must_be_line_bound). Requiring the full comment form
# stops a quoted 8-hex id from counting as a heading.
if grep -qE "^## .*<!--sid:$SID_SHORT-->" "$DAILY_LOG" 2>/dev/null; then
  rm -f "$SUBSTANTIVE_FLAG" "$RECOVERY_FLAG" "$NAGGED_FLAG" 2>/dev/null || true
  echo '{}'
  exit 0
fi

# Case 2: session was not substantive — pass silently.
if [ ! -f "$SUBSTANTIVE_FLAG" ]; then
  echo '{}'
  exit 0
fi

# How to head the section. Case 0 already returned for id-less harnesses, so a
# real marker is always available here.
HEAD_HINT="Head it exactly: \`## S{n} — {time range} — {topic} <!--sid:$SID_SHORT-->\` — that marker is verbatim and mandatory (this hook greps for it on a \`## \` line; without it you will be asked again), and {n} continues the day's numbering."

# Build the recovery hint if the recovery flag is set.
RECOVERY_HINT=""
if [ -f "$RECOVERY_FLAG" ]; then
  RECOVERY_HINT=" A git-based recovery event was detected this session (git show HEAD: or git checkout HEAD --). Add an 'Incidents' subsection to the daily log capturing what was recovered, why, and what it taught you — this is exactly the type of save-worthy moment that 2026-04-14 feedback memory warns gets erased by post-recovery relief."
fi

# Case 3: already nagged — soft reminder only.
if [ -f "$NAGGED_FLAG" ]; then
  jq -n --arg log "$DAILY_LOG" --arg hint "$RECOVERY_HINT" --arg head "$HEAD_HINT" '{
    systemMessage: ("gyeol reminder: this session is still unrecorded in " + $log + ". " + $head + $hint)
  }'
  exit 0
fi

# Case 4: hard block, mark nagged.
touch "$NAGGED_FLAG" 2>/dev/null || true

jq -n --arg log "$DAILY_LOG" --arg hint "$RECOVERY_HINT" --arg dec "$BLOCK_DECISION" --arg head "$HEAD_HINT" '{
  decision: $dec,
  reason: (
    "gyeol memory circuit: this session was substantive (Write/Edit/commit detected) but it is not recorded in today\u2019s daily log at " + $log + ". Before stopping, write your session section now: what you worked on, what decisions you made, what you learned, any open threads. If the file already exists, ADD your section \u2014 never rewrite another session\u2019s, and re-read it immediately before inserting: a day runs 3-13 sessions and a stale read silently drops someone else\u2019s section. " + $head + " Sections go NEWEST FIRST directly under the date heading; frontmatter carries date only (no session count \u2014 it drifted from the real count on 5 of 8 sampled days and nothing read it). Under your heading use tldr / Outcome / Decisions / Next / Artifacts / Verification as H3 headings (### tldr, not **tldr** and not ## tldr) — bullets, not prose paragraphs; same shape as the /close terminal briefing. Update episodes/_recent.md only for future-actionable active context: keep Daily Index to one short pointer for today, keep Still Open as a hot list only (roughly 12 one-line active topics max), drop resolved items, and tag retained items with source date. If _recent.md is over 5 KB, compress before adding anything; move backlog/detail to daily logs, handoff notes, or threads. If no active/open context remains, do not add to _recent.md." + $hint + " This enforcement exists because task framing silently suppressed automatic memory capture on 2026-04-14 — see feedback_session_bootstrap.md. Do not treat this as optional."
  )
}'
