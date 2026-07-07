#!/usr/bin/env sh
# gyeol SessionEnd hook
#
# Records session-end metadata so the next SessionStart bootstrap can detect
# sessions that ended without a daily-log update and surface them to the
# agent as evidence to retrospect on.
#
# Why a separate evidence-recording hook (instead of, say, blocking exit
# the way Stop / AfterAgent do): SessionEnd fires AFTER the agent has
# stopped, so it cannot make the agent do work. Stop / AfterAgent already
# handle the "block exit when today's daily log is missing AND the session
# was substantive" case. SessionEnd handles the complementary case: the
# session ended cleanly (or the substantive-flag path failed, or the user
# /clear'd, or the harness crashed mid-session) and the next session needs
# to know the gap exists.
#
# The evidence file (~/.config/gyeol/.session-log.jsonl) is consumed by
# session-bootstrap.sh / session-bootstrap-json.sh's staleness check, which
# directs the agent to retrospect, write missing daily logs, then truncate
# this file as part of the procedure.
#
# Idempotency / safety: append-only, never blocks session shutdown.
#
# Harness compatibility:
#   - Claude Code:  SessionEnd hook supported. Register with this script.
#   - Gemini CLI:   SessionEnd exists but is documented as "cannot block
#                   exit and cannot inject context". The evidence-only
#                   role this script plays is still useful — the next
#                   SessionStart bootstrap reads the file regardless of
#                   which harness wrote it. Safe to register.
#   - OpenAI Codex: Prefer SessionEnd when supported; otherwise register
#                   this script on Stop as a fallback so close parity stays
#                   close to the other agents.

GYEOL_HOME="${GYEOL_HOME:-$HOME/.config/gyeol}"

# If gyeol is not installed on this machine, stay silent.
[ -d "$GYEOL_HOME" ] || exit 0

LOG="$GYEOL_HOME/.session-log.jsonl"

INPUT=$(cat 2>/dev/null || true)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
EVENT_NAME=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // .event // empty' 2>/dev/null || true)

# Avoid duplicate end records when both SessionEnd and Stop are wired.
if [ -n "$SESSION_ID" ] && [ -f "$LOG" ] && grep -F "\"session_id\":\"$SESSION_ID\"" "$LOG" >/dev/null 2>&1; then
  exit 0
fi

ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --arg end "$ts" \
  --arg cwd "${PWD:-unknown}" \
  --arg session_id "$SESSION_ID" \
  --arg event_name "$EVENT_NAME" '
  {end:$end, cwd:$cwd}
  + (if $session_id != "" then {session_id:$session_id} else {} end)
  + (if $event_name != "" then {event:$event_name} else {} end)
' >> "$LOG" 2>/dev/null || true

exit 0
