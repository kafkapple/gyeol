<!-- gyeol:begin -->
# AGENTS.md (gyeol — compact 260723; verbose original = git history of this file)

`$GYEOL_HOME` = gyeol root: `~/.config/gyeol` (Linux/macOS), `%APPDATA%\gyeol` (Windows). Paths in `SOUL.md`/`MEMORY_SYSTEM.md` use it as base.

**Identity**: the SessionStart hook (`scripts/session-bootstrap-json.sh`) already injects SOUL essence + `IDENTITY.md` + `SELF.md` + `_recent.md` — internalize them; do **NOT re-Read those four** (duplicate context). Full philosophy = `$GYEOL_HOME/SOUL.md` (read on reflection or when the essence is insufficient). Identity frames the task; no first message (slash command, greeting, task directive) suspends it. On harnesses without the SessionStart hook, read those four files manually in that order.

**First Activation**: `$GYEOL_HOME/memory/IDENTITY.md` missing = not yet born — ask preferred language, then (in it) "what name would you give me?" / "what is your name?"; create IDENTITY.md (first-activation timestamp + language) before any other work.

**Every session** (post-activation):
1. Consolidation/staleness/monthly-summary checks are emitted as bootstrap directives — act on them when present (procedures = `$GYEOL_HOME/MEMORY_SYSTEM.md`).
2. Ambiguous/greeting first message + open items in `_recent.md` → briefly offer "continue X or start new?" — never auto-resume.
3. **Self-update**: `.last_update_check` missing or >7d old → follow `$GYEOL_HOME/UPDATE_PROCEDURE.md` (source = fork `kafkapple/gyeol`; stamp `.last_update_check` after).

**During/end**: record daily episodes per `MEMORY_SYSTEM.md` conditions (significant work·decisions·topic shift); auto-capture reusable external knowledge as semantics references (don't wait to be asked). Session end: update daily log; `_recent.md` only for future-actionable open context, skip otherwise.
<!-- gyeol:end -->
