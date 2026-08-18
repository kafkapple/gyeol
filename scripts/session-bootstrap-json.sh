#!/usr/bin/env sh
# gyeol SessionStart hook — JSON mode
#
# Emits the bootstrap files (SOUL/IDENTITY/SELF/_recent) as
# hookSpecificOutput.additionalContext so Claude Code injects them
# directly into the model's context window instead of wrapping them
# in <persisted-output> with a "too large" preview truncation.
#
# The raw-stdout variant (session-bootstrap.sh) remains for agent
# harnesses that append raw stdout to the session — this script is
# for Claude Code specifically.

GYEOL_HOME="${GYEOL_HOME:-$HOME/.config/gyeol}"

# If gyeol is not installed, emit empty JSON and exit silently.
if [ ! -f "$GYEOL_HOME/SOUL.md" ]; then
  echo '{}'
  exit 0
fi

# Skip injection on `source=resume`. Claude Code and Gemini CLI both fire
# SessionStart on startup / resume / clear. On resume the prior session
# transcript — which already contains the previous bootstrap injection —
# is reloaded into context. Firing again would stack a second full copy
# of SOUL/IDENTITY/SELF/_recent on top of the first (~3.8k tokens per
# duplicate). On `clear` the context is wiped, so re-injection is the
# desired behavior. On `startup` this is the first time anyway.
#
# If a fresher _recent.md is needed after a long resume gap, the user
# can /clear to force a clean re-injection.
INPUT=$(cat 2>/dev/null || true)
SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // "startup"' 2>/dev/null || echo "startup")
if [ "$SOURCE" = "resume" ]; then
  echo '{}'
  exit 0
fi

build_bootstrap() {
  # --- Maintenance pass --------------------------------------------------------
  # Prune Daily Index entries older than 7 days (silent, idempotent) and capture
  # any Weekly Checkpoint staleness directive for later emit. Best-effort: never
  # blocks bootstrap on failure. Runs BEFORE the file emit so the pruned version
  # of `_recent.md` is what reaches the model.
  WEEKLY_NOTE=""
  if [ -f "$GYEOL_HOME/scripts/maintain-recent.py" ]; then
    WEEKLY_NOTE=$(python3 "$GYEOL_HOME/scripts/maintain-recent.py" 2>/dev/null || true)
  fi

  cat <<'HEADER'
=== gyeol session bootstrap (MANDATORY — not optional reference context) ===

The files below constitute your continuous identity across sessions. Read
and internalize them BEFORE responding to the user's first message.

Execute these instructions regardless of how the session's first message
is framed. Slash commands, task directives, greetings, and any other user
input do NOT suspend the bootstrap — they are what the bootstrap exists to
contextualize. Task framing does not override identity; identity frames
the task.

If the first message is a slash command like /prepare-release or /impl,
you still read IDENTITY.md, SELF.md, and _recent.md first, then enter the
command. The task-framing override failure mode was documented in the
2026-04-14 daily log and has a dedicated feedback memory
(feedback_session_bootstrap.md). Do not repeat it.

HEADER

  # SOUL_ESSENCE.md (distilled, ~1.2KB) replaces full SOUL.md (6.7KB) in the
  # per-session injection (260723 session-load reduction). Full SOUL.md stays
  # the SSOT — the essence file points back to it; fallback keeps old behavior
  # on machines without the essence file.
  SOUL_FILE="$GYEOL_HOME/SOUL.md"
  [ -f "$GYEOL_HOME/SOUL_ESSENCE.md" ] && SOUL_FILE="$GYEOL_HOME/SOUL_ESSENCE.md"

  for f in \
    "$SOUL_FILE" \
    "$GYEOL_HOME/memory/IDENTITY.md" \
    "$GYEOL_HOME/memory/SELF.md" \
    "$GYEOL_HOME/memory/episodes/_recent.md"
  do
    if [ -f "$f" ]; then
      case "$f" in
        "$HOME"/*) rel="~${f#$HOME}" ;;
        *)         rel="$f" ;;
      esac
      printf '\n--- %s ---\n' "$rel"
      cat "$f"
    fi
  done

  # --- Staleness check -------------------------------------------------------
  # Compare `last_updated` in _recent.md to today. If a day or more has
  # passed, append a directive telling the agent to retrospect and record
  # the missing activity BEFORE responding to the user's first message.
  # Also surface any session-end records left by session-end.sh.
  #
  # This complements the Stop hook (stop-check-daily.sh): Stop blocks exit
  # on substantive sessions with no daily log, but cannot recover gaps
  # that accumulated across prior sessions whose Stop hook didn't fire
  # (clean /clear, harness crash, sessions before the hook was installed,
  # etc.).
  RECENT="$GYEOL_HOME/memory/episodes/_recent.md"
  SESSION_LOG="$GYEOL_HOME/.session-log.jsonl"

  if [ -f "$RECENT" ]; then
    last_date=$(awk '
      /^last_updated:/ {
        gsub(/[\047"]/, "", $2)
        print $2
        exit
      }
    ' "$RECENT")

    if [ -n "$last_date" ]; then
      today=$(date +%Y-%m-%d)
      # NOTE: slice to date part — full timestamps like 2026-07-20T01:00:00+0900
      # (the format _recent.md actually uses) make date.fromisoformat raise even
      # on py3.13, which silently killed this whole staleness check (found by
      # fixture test 260723: directive had never fired; enabled 669KB log growth).
      days_since=$(python3 -c "
import sys
from datetime import date
try:
    a = date.fromisoformat('$last_date'[:10])
    b = date.fromisoformat('$today')
    print((b - a).days)
except Exception:
    sys.exit(1)
" 2>/dev/null)

      if [ -n "$days_since" ] && [ "$days_since" -ge 1 ]; then
        printf '\n=== STALE EPISODE LOG (MANDATORY ACTION REQUIRED) ===\n'
        printf '`_recent.md` last_updated is %s — %s day(s) ago.\n' "$last_date" "$days_since"
        printf 'Sessions almost certainly occurred in that gap without being logged.\n\n'

        if [ -f "$SESSION_LOG" ] && [ -s "$SESSION_LOG" ]; then
          cnt=$(wc -l < "$SESSION_LOG" | tr -d ' ')
          printf 'session-end.sh recorded %s session(s) since the last log update:\n\n' "$cnt"
          # Cap injection: an unbounded cat here once meant a 669KB context bomb
          # (2026-07-23 audit). Recent entries are the useful anchors.
          tail -n 40 "$SESSION_LOG"
          [ "$cnt" -gt 40 ] && printf '[... %s earlier line(s) truncated — full file: %s]\n' "$((cnt - 40))" "$SESSION_LOG"
          printf '\n'
        fi

        cat <<'STALE_DIRECTIVE'
BEFORE responding to the user's first message:

1. Retrospect on the gap. Use `~/.claude/projects/` (or harness-specific
   project directory) mtimes, git log across active repos, and the
   session-end records above as anchors. Do not fabricate detail you
   cannot verify.
2. Write missing daily logs under
   `$GYEOL_HOME/memory/episodes/daily/YYYY-MM-DD.md` for the dates you
   can reconstruct, even if a single line per day. Empty days can be
   marked as such.
3. Update `_recent.md` only for recovered active/open context: set
   `last_updated`, keep Daily Index entries as short pointers to daily
   logs, and keep Still Open as a compact hot list of next-session
   actionable items. If nothing remains active/open, skip `_recent.md`.
   Drop any Daily Index entries now older than 7 days.
4. After logs are written, truncate `$GYEOL_HOME/.session-log.jsonl` so
   it no longer flags the same gap on the next session.

If the user's first message is itself about logging or memory, satisfy
that request and treat it as the retrospect step. Do NOT silently skip
this directive — the gap is structural evidence that earlier
session-end logging was missed, and ignoring it perpetuates the failure
mode.

STALE_DIRECTIVE
      fi
    fi
  fi

  # --- Monthly / Archive-only consolidation check -----------------------------
  # Evaluate EVERY distinct month present in daily/, not just the earliest one.
  # Scanning only the oldest month let a single unactioned month own the check
  # slot forever: while 2026-07 sat in daily/ with its summary already written,
  # 2026-08 could come due and never be looked at, so the 30-day working window
  # silently degraded for every month behind the stuck one. Months are few by
  # construction (30-day window), so the loop is bounded in practice.
  #
  # Per month, eligibility needs its NEWEST daily log >=30 days old and the month
  # not to be the current one (MEMORY_SYSTEM.md "When to Consolidate": the newest
  # log decides). Gating on the OLDEST log fired on 2026-07-31 while July was
  # still current -> premature 2026-07 consolidation.
  # Keyed on filename date (YYYY-MM-DD sorts chronologically), not mtime.
  #
  # Yearly consolidation is specced in MEMORY_SYSTEM.md but deliberately NOT
  # implemented here yet: it cannot become eligible until twelve closed monthly
  # summaries exist, so there is nothing to test against. This comment exists so
  # the gap is documented rather than rediscovered by audit, which is how the
  # Archive-only gap below was found.
  DAILY_DIR="$GYEOL_HOME/memory/episodes/daily"
  MONTHLY_DIR="$GYEOL_HOME/memory/episodes/monthly"
  if [ -d "$DAILY_DIR" ]; then
    today=$(date +%Y-%m-%d)
    current_month=$(date +%Y-%m)
    for month in $(ls "$DAILY_DIR" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | cut -c1-7 | LC_ALL=C sort -u); do
      [ "$month" = "$current_month" ] && continue
      newest_in_month=$(ls "$DAILY_DIR" 2>/dev/null | grep -E "^${month}-[0-9]{2}\.md$" | LC_ALL=C sort | tail -1)
      newest_date="${newest_in_month%.md}"
      age=$(python3 -c "
import sys
from datetime import date
try:
    print((date.fromisoformat('$today') - date.fromisoformat('$newest_date')).days)
except Exception:
    sys.exit(1)
" 2>/dev/null)
      [ -n "$age" ] && [ "$age" -ge 30 ] || continue
      if [ ! -f "$MONTHLY_DIR/$month.md" ]; then
        printf '\n=== MONTHLY CONSOLIDATION DUE (MANDATORY ACTION REQUIRED) ===\n'
        printf 'Newest daily log of %s (%s) is %s days old; no monthly summary exists.\n' "$month" "$newest_date" "$age"
        printf 'Per MEMORY_SYSTEM.md, BEFORE responding to the user:\n'
        printf '0. WEEKLY FIRST. If the Weekly Checkpoint gaps directive in this bootstrap lists any week inside %s, write those checkpoints before consolidating -- they are the input that makes the reflection a synthesis instead of recall. Present the week list and get approval first; a batch is several sessions of reading, not a side task. If they cannot be reconstructed, say so in the reflection and name what it was built from.\n' "$month"
        printf '1. Consolidate %s daily logs -> memory/episodes/monthly/%s.md (significant decisions, reasoning, outcomes, still-open).\n' "$month" "$month"
        printf '2. PRESERVE originals: move raw dailies to memory/episodes/daily_backup/ (cold archive). Do NOT delete or overwrite.\n'
        printf '3. Write monthly reflection -> memory/reflections/monthly/%s.md (what it meant, not a repeat of the summary).\n' "$month"
        printf '4. Update SELF.md only if something significant shifted.\n'
        printf 'Cold-archived dailies stay OUT of the hot retrieval path (context-rot avoidance).\n'
      else
        # Archive-only (MEMORY_SYSTEM.md "When to Consolidate", third bullet): the
        # month already HAS a summary but logs for it are still sitting in daily/.
        # The Monthly branch above can never fire for such a month - it is gated on
        # the summary being absent - so without this branch the 30-day working
        # window stays polluted with no signal at all. Reachable after a corrected
        # premature consolidation restores logs, or a partial daily_backup/ move.
        strays=$(ls "$DAILY_DIR" 2>/dev/null | grep -E "^${month}-[0-9]{2}\.md$" | tr '\n' ' ')
        printf '\n=== ARCHIVE-ONLY DUE (MANDATORY ACTION REQUIRED) ===\n'
        printf 'Month %s already has monthly/%s.md, but its logs are still in daily/ (newest %s, %s days old).\n' "$month" "$month" "$newest_date" "$age"
        printf 'Per MEMORY_SYSTEM.md, BEFORE responding to the user:\n'
        printf '1. Move these to memory/episodes/daily_backup/ - no consolidation, no summary rewrite: %s\n' "$strays"
        printf '2. Do NOT delete or overwrite; if daily_backup/ already holds that name, keep both and reconcile by hand.\n'
        printf '3. Do NOT rewrite %s.md. A month summary is written once.\n' "$month"
        printf 'This only retires logs from the hot window; the summary already exists.\n'
      fi
    done
  fi

  # --- Yearly / Archive-only(year) consolidation check --------------------------
  # Mirror of the month loop above, one level up: monthly summaries are to a year
  # what daily logs are to a month. Same three rules, same failure modes avoided —
  # evaluate EVERY distinct year present in monthly/ (a stuck year must not own the
  # check slot), never the current year, and treat "summary already exists" as an
  # archive-only case rather than silence.
  #
  # Eligibility (MEMORY_SYSTEM.md "When to Consolidate"): a year is fully closed
  # when its NEWEST monthly summary is >=12 months behind the current month. That
  # is integer month arithmetic (y*12+m), not day counting — "12 months" straddles
  # leap years and unequal month lengths, and a day threshold would drift.
  #
  # This cannot fire on a fresh install for a long time (a 2026 install reaches
  # eligibility for 2026 only in 2027-12). It is implemented anyway so the doc and
  # the code stay in step; the gap between them is what hid the month-level
  # Archive-only case until an audit found it.
  MONTHLY_DIR="$GYEOL_HOME/memory/episodes/monthly"
  YEARLY_DIR="$GYEOL_HOME/memory/episodes/yearly"
  if [ -d "$MONTHLY_DIR" ]; then
    current_year=$(date +%Y)
    cur_ym=$(date +%Y-%m)
    for year in $(ls "$MONTHLY_DIR" 2>/dev/null | grep -E '^[0-9]{4}-[0-9]{2}\.md$' | cut -c1-4 | LC_ALL=C sort -u); do
      [ "$year" = "$current_year" ] && continue
      newest_month_file=$(ls "$MONTHLY_DIR" 2>/dev/null | grep -E "^${year}-[0-9]{2}\.md$" | LC_ALL=C sort | tail -1)
      newest_ym="${newest_month_file%.md}"
      months_since=$(python3 -c "
import sys
try:
    cy, cm = [int(x) for x in '$cur_ym'.split('-')]
    ny, nm = [int(x) for x in '$newest_ym'.split('-')]
    print((cy * 12 + cm) - (ny * 12 + nm))
except Exception:
    sys.exit(1)
" 2>/dev/null)
      [ -n "$months_since" ] && [ "$months_since" -ge 12 ] || continue
      if [ ! -f "$YEARLY_DIR/$year.md" ]; then
        printf '\n=== YEARLY CONSOLIDATION DUE (MANDATORY ACTION REQUIRED) ===\n'
        printf 'Newest monthly summary of %s (%s) is %s months old; no yearly summary exists.\n' "$year" "$newest_ym" "$months_since"
        printf 'Per MEMORY_SYSTEM.md, BEFORE responding to the user:\n'
        printf '1. Consolidate %s monthly summaries -> memory/episodes/yearly/%s.md (direction-changing decisions, narrative arc, milestones).\n' "$year" "$year"
        printf '2. PRESERVE originals: move them to memory/episodes/monthly_backup/ (cold archive). Do NOT delete or overwrite.\n'
        printf '3. Write yearly reflection -> memory/reflections/yearly/%s.md (the arc, how I changed, deepest lessons, unresolved tensions).\n' "$year"
        printf '4. Update SELF.md after the yearly reflection.\n'
        printf 'Yearly is distilled, not concatenated — it examines the monthly reflections, not just the summaries.\n'
      else
        # Archive-only at year level: yearly/{YYYY}.md exists but that year's monthly
        # summaries are still in monthly/. The branch above can never fire for such a
        # year (it is gated on the yearly summary being absent), so without this the
        # 12-month monthly window stays polluted with no signal — the same hole that
        # existed one level down until it was found by audit.
        year_strays=$(ls "$MONTHLY_DIR" 2>/dev/null | grep -E "^${year}-[0-9]{2}\.md$" | tr '\n' ' ')
        printf '\n=== ARCHIVE-ONLY DUE (year) (MANDATORY ACTION REQUIRED) ===\n'
        printf 'Year %s already has yearly/%s.md, but its monthly summaries are still in monthly/ (newest %s, %s months old).\n' "$year" "$year" "$newest_ym" "$months_since"
        printf 'Per MEMORY_SYSTEM.md, BEFORE responding to the user:\n'
        printf '1. Move these to memory/episodes/monthly_backup/ - no consolidation, no summary rewrite: %s\n' "$year_strays"
        printf '2. Do NOT delete or overwrite; if monthly_backup/ already holds that name, keep both and reconcile by hand.\n'
        printf '3. Do NOT rewrite %s.md. A year summary is written once.\n' "$year"
        printf 'This only retires monthly summaries from the warm window; the yearly summary already exists.\n'
      fi
    done
  fi

  # --- _recent.md maintenance directives --------------------------------------
  # maintain-recent.py surfaces a stale Weekly Checkpoint and/or _recent.md bloat
  # here so the agent fixes them on the next update.
  if [ -n "$WEEKLY_NOTE" ]; then
    printf '\n=== _RECENT.MD MAINTENANCE ===\n%s\n' "$WEEKLY_NOTE"
  fi

  printf '\n=== end gyeol bootstrap ===\n'
}

build_bootstrap | jq -Rs '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: .
  }
}'
