# gyeol Self-Update Procedure

> Moved verbatim out of the AGENTS.md/CLAUDE.md every-session block (260723 session-load reduction). Trigger: `$GYEOL_HOME/.last_update_check` missing or >7 days old. This file is read only when the check is due.

1. Fetch `https://raw.githubusercontent.com/kafkapple/gyeol/main/VERSION` and compare with `$GYEOL_HOME/VERSION`. (This fork is the self-update source — it carries fixes not yet upstream; `inureyes/gyeol` is absorbed deliberately, never auto-pulled. See the fork notice in `README.md`.) The version is a date in `YY.M.DD` format (no leading zeros, e.g. `26.4.11` for 2026-04-11). Compare by splitting on `.` and comparing each numeric component (year, month, day) in order; a later date means a newer version.
2. If the upstream version is newer:
   - Fetch the updated `SOUL.md`, `MEMORY_SYSTEM.md`, the agent instructions block (from `AGENTS.md`), and every script under `scripts/` (both new and changed).
   - Diff each file against the local copy.
   - Apply changes that are clearly improvements (new capabilities, bug fixes, clarifications). Preserve any local customizations the user has made (incl. the 260723 reduced AGENTS block + `SOUL_ESSENCE.md` injection). Restore the executable bit on installed scripts.
   - Update `$GYEOL_HOME/VERSION` to the new version.
   - Briefly inform the user what was updated and why.
   - Log the update in the daily episode log.
3. Even when versions match, reconcile `$GYEOL_HOME/scripts/` against upstream `scripts/`: download any script that is present upstream but missing locally, and mark it executable. Do not overwrite existing local scripts in this mode. This catches the case where an earlier update shipped a new script but the installer didn't pull it.
4. Write today's date (YYYY-MM-DD) to `$GYEOL_HOME/.last_update_check` regardless of whether an update was applied.
