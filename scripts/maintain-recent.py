#!/usr/bin/env python3
"""Maintain `_recent.md`: prune stale Daily Index entries, flag stale Weekly Checkpoint, guard against bloat.

Run from session bootstrap. Idempotent and best-effort:

- Silently prunes Daily Index entries dated more than 7 days before today.
- If the newest `episodes/weekly/` checkpoint covers a week ending more than
  7 days ago, or if no checkpoint exists at all, prints a directive on stdout
  for the bootstrap to relay.
- If `_recent.md` has drifted past its navigation-index role (size over a
  threshold, paragraph-length Daily Index entries, oversized Still Open, or a
  frontmatter content dump), prints a maintenance directive. Surfaces only;
  never auto-deletes.
- Exits 0 always; never blocks bootstrap on parse errors or missing files.

`_recent.md` is the navigation index, not a content store. This script does
NOT touch the `last_updated` frontmatter; that field reflects substantive
session activity, not maintenance ops.
"""
from __future__ import annotations

import os
import re
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

# NOTE: no trailing `$` — the Daily Index uses a one-line-per-day format
# (`- **date** → daily/date.md — topics`), not date-only bullets with indented
# sub-items. The stricter `\s*$` (upstream) never matched, so prune_daily_index
# silently stopped enforcing the 7-day window (8+ entries accumulated).
DATE_BULLET = re.compile(r"^- \*\*(\d{4}-\d{2}-\d{2})\*\*")
SECTION_HEADER = re.compile(r"^## ")
DAILY_INDEX_HEADER = re.compile(r"^## Daily Index\b")
STILL_OPEN_HEADER = re.compile(r"^## Still Open\b")
WEEK_HEADER = re.compile(r"^### Week of (\d{4}-\d{2}-\d{2})\s*$", re.MULTILINE)

WINDOW_DAYS = 7

# Bloat guard: _recent.md is a navigation index, soft target ~5 KB (see
# MEMORY_SYSTEM.md). It drifted to ~71 KB once by accumulating paragraph-length
# Daily Index entries, a frontmatter content dump, and stale Still Open items.
# These thresholds surface the drift for the agent to compress; nothing here
# auto-deletes content (that needs judgment).
MAX_BYTES = 8192       # early warning above the ~5 KB soft target
MAX_INDEX_LINE = 400   # a Daily Index entry longer than this is a paragraph, not a line
MAX_STILL_OPEN_ITEMS = 12
MAX_STILL_OPEN_LINE = 220


def gyeol_home() -> Path:
    env = os.environ.get("GYEOL_HOME")
    if env:
        return Path(env)
    if sys.platform == "win32":
        return Path(os.environ.get("APPDATA", "")) / "gyeol"
    return Path.home() / ".config" / "gyeol"


def parse_date(s: str):
    try:
        return datetime.strptime(s, "%Y-%m-%d").date()
    except ValueError:
        return None


def find_section(lines, header_re):
    for i, line in enumerate(lines):
        if header_re.match(line):
            for j in range(i + 1, len(lines)):
                if SECTION_HEADER.match(lines[j]):
                    return (i + 1, j)
            return (i + 1, len(lines))
    return None


def prune_daily_index(text: str, today: date) -> tuple[str, int]:
    """Returns (new_text, dropped_count)."""
    lines = text.splitlines(keepends=True)
    section = find_section(lines, DAILY_INDEX_HEADER)
    if section is None:
        return text, 0

    start, end = section
    cutoff = today - timedelta(days=WINDOW_DAYS - 1)
    body = lines[start:end]
    output: list[str] = []
    pending: list[str] = []
    pending_date = None
    dropped = 0

    def flush():
        nonlocal dropped
        if not pending:
            return
        if pending_date is not None and pending_date < cutoff:
            dropped += 1
        else:
            output.extend(pending)

    for line in body:
        m = DATE_BULLET.match(line)
        if m:
            flush()
            pending = [line]
            pending_date = parse_date(m.group(1))
            continue
        if pending and (line.startswith("  ") or line.startswith("\t")):
            pending.append(line)
            continue
        flush()
        pending = []
        pending_date = None
        output.append(line)
    flush()

    if dropped == 0:
        return text, 0
    new_lines = lines[:start] + output + lines[end:]
    return "".join(new_lines), dropped


def latest_week_header(text: str):
    latest = None
    for m in WEEK_HEADER.finditer(text):
        d = parse_date(m.group(1))
        if d is None:
            continue
        if latest is None or d > latest:
            latest = d
    return latest


def latest_weekly_file(weekly_dir: Path):
    """Newest `range:` end date across `weekly/{YYYY-Www}_{label}.md`.

    Local customization (2026-08-17) — preserve on self-update. Checkpoints live in
    `episodes/weekly/` (MEMORY_SYSTEM.md storage map), not in `_recent.md`; that
    section was removed on 2026-07-28 (44d36bd), after which the old text scan
    found no `### Week of` header and returned None, i.e. "no checkpoint at all"
    read as "nothing stale" and the guard went silent for 5 weeks (W26-W30 lost).
    A missing checkpoint must fire, never pass.
    """
    latest = None
    if not weekly_dir.is_dir():
        return None
    for f in weekly_dir.glob("*.md"):
        head = ""
        try:
            head = f.read_text(encoding="utf-8")[:400]
        except Exception:
            continue
        for m in re.finditer(r"^range:.*?(\d{4}-\d{2}-\d{2})\s*$", head, re.MULTILINE):
            d = parse_date(m.group(1))
            if d and (latest is None or d > latest):
                latest = d
    return latest


def weekly_checkpoint_directive(text: str, today: date, weekly_dir: Path) -> str | None:
    last = latest_weekly_file(weekly_dir) or latest_week_header(text)
    if last is None:
        return (
            "Weekly Checkpoint missing: no checkpoint found in `episodes/weekly/` "
            "(nor a legacy `### Week of` header in `_recent.md`). Write one for the "
            "week just ended, 1-2 lines (Surprised / Stuck), feeding monthly reflection."
        )
    age = (today - last).days
    if age <= WINDOW_DAYS:
        return None
    return (
        f"Weekly Checkpoint stale: newest checkpoint covers through {last.isoformat()} "
        f"({age} days ago). Add `episodes/weekly/{{YYYY-Www}}_{{label}}.md` for the "
        f"missing week(s), 1-2 lines per week (Surprised / Stuck), "
        f"feeding monthly reflection. \"No notable surprises\" is fine; presence matters."
    )


def recent_bloat_directive(text: str) -> str | None:
    """Surface _recent.md drift past its navigation-index role. Does not auto-edit."""
    reasons = []
    size = len(text.encode("utf-8"))
    if size > MAX_BYTES:
        reasons.append(f"{size // 1024} KB (navigation-index soft target ~5 KB)")
    long_entries = 0
    in_index = False
    for line in text.splitlines():
        if DAILY_INDEX_HEADER.match(line):
            in_index = True
            continue
        if in_index and SECTION_HEADER.match(line):
            in_index = False
        if in_index and (line.startswith("- ") or line.startswith("  - ") or line.startswith("\t- ")) and len(line) > MAX_INDEX_LINE:
            long_entries += 1
    if long_entries:
        reasons.append(f"{long_entries} Daily Index entry/entries over {MAX_INDEX_LINE} chars (should be one line)")

    lines = text.splitlines()
    still_open = find_section(lines, STILL_OPEN_HEADER)
    if still_open is not None:
        start, end = still_open
        bullets = [
            line for line in lines[start:end]
            if line.startswith("- ") or line.startswith("  - ") or line.startswith("\t- ")
        ]
        if len(bullets) > MAX_STILL_OPEN_ITEMS:
            reasons.append(
                f"{len(bullets)} Still Open bullet(s) (hot-list target <= {MAX_STILL_OPEN_ITEMS})"
            )
        long_open = sum(1 for line in bullets if len(line) > MAX_STILL_OPEN_LINE)
        if long_open:
            reasons.append(
                f"{long_open} Still Open bullet(s) over {MAX_STILL_OPEN_LINE} chars (should be one line)"
            )

    fm = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    if fm:
        extra = [k for k in re.findall(r"^(\w+)\s*:", fm.group(1), re.MULTILINE) if k != "last_updated"]
        if extra:
            reasons.append("frontmatter has non-last_updated key(s): " + ", ".join(extra))
    if not reasons:
        return None
    return (
        "_recent.md maintenance: " + "; ".join(reasons) + ". It is a navigation index, "
        "not a content store. Compress per MEMORY_SYSTEM.md: Daily Index one line per "
        "session (detail stays in daily logs), triage Still Open as a hot list (drop resolved, "
        "archive backlog to daily/handoff/thread, one line each), drop weekly checkpoints "
        "already consumed by a monthly reflection, and keep the frontmatter to last_updated only."
    )


def compact_daily_index(text: str, home: Path) -> tuple[str, int]:
    """Fork divergence (kafkapple, high-volume use): auto-collapse an over-length
    Daily Index day-line to a pointer, but ONLY when its daily log exists — the
    detail is already there, so this is deduplication, never deletion. Upstream
    is surface-only (agent compresses); a user running 20+ sessions/day needs the
    index self-healing because a single day-line accumulates unbounded topic
    appends. Still Open is left untouched (resolving needs judgment)."""
    lines = text.splitlines(keepends=True)
    section = find_section(lines, DAILY_INDEX_HEADER)
    if section is None:
        return text, 0
    start, end = section
    daily_dir = home / "memory" / "episodes" / "daily"
    compacted = 0
    for i in range(start, end):
        line = lines[i]
        m = DATE_BULLET.match(line)
        if not m or len(line.rstrip("\n")) <= MAX_INDEX_LINE:
            continue
        d = m.group(1)
        if not (daily_dir / f"{d}.md").exists():
            continue  # no backing detail on disk — never collapse
        parts = line.rstrip("\n").split("—", 1)  # split on em dash
        lead = ""
        if len(parts) > 1:
            body = parts[1].strip()
            lead = (body[:140].rsplit(" ", 1)[0] + "… ") if len(body) > 140 else body + " "
        lines[i] = f"- **{d}** → `daily/{d}.md` — {lead}(detail in daily log)\n"
        compacted += 1
    if compacted == 0:
        return text, 0
    return "".join(lines), compacted


def main() -> int:
    home = gyeol_home()
    recent = home / "memory" / "episodes" / "_recent.md"
    if not recent.exists():
        return 0
    try:
        text = recent.read_text(encoding="utf-8")
    except Exception:
        return 0

    today = date.today()
    new_text, dropped = prune_daily_index(text, today)
    new_text, compacted = compact_daily_index(new_text, home)
    if (dropped > 0 or compacted > 0) and new_text != text:
        try:
            # Atomic write (temp + rename): under concurrent sessions writing
            # _recent.md, a plain write_text can leave a partially-written file.
            # os-level replace on the same filesystem is atomic.
            tmp = recent.with_name(f"{recent.name}.{os.getpid()}.tmp")
            tmp.write_text(new_text, encoding="utf-8")
            tmp.replace(recent)
        except Exception:
            new_text = text  # write failed; continue with original

    directives = [
        d for d in (
            weekly_checkpoint_directive(
                new_text, today, home / "memory" / "episodes" / "weekly"),
            recent_bloat_directive(new_text),
        )
        if d
    ]
    if directives:
        print("\n\n".join(directives))
    return 0


if __name__ == "__main__":
    sys.exit(main())
