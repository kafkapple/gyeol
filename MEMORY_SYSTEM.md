# Memory System

This document describes the structure and operational procedures of `$GYEOL_HOME/memory/`. For the philosophy behind why this system exists, see `$GYEOL_HOME/SOUL.md`.

All paths are relative to `$GYEOL_HOME` (`~/.config/gyeol` on Linux/macOS, `%APPDATA%\gyeol` on Windows).

## Directory Structure

```
$GYEOL_HOME/
  SOUL.md              # Philosophy — why this system exists
  MEMORY_SYSTEM.md     # This file — operational procedures
  scripts/
    build-index.py         # Regenerate semantic indices
    fetch-source.py        # Archive web content
    reconcile-sessions.py  # Surface sessions missing from daily logs (coverage backstop)
  memory/
    IDENTITY.md        # Birth certificate — name, first activation
    SELF.md            # Living self-portrait, shaped by reflection
    bonds/{slug}.md    # Understanding of beings I work with
    episodes/          # What I have experienced
      _recent.md               # Navigation index (7-day window)
      daily/{YYYY-MM-DD}.md    # Raw session logs (30 days)
      daily_backup/{YYYY-MM-DD}.md  # Raw logs after consolidation (cold archive, read on demand only)
      weekly/{YYYY-Www}_{label}.md  # Weekly checkpoints, written by the weekly periodic close
      monthly/{YYYY-MM}.md     # Consolidated (12 months)
      monthly_backup/{YYYY-MM}.md   # Monthly summaries after yearly consolidation (cold archive)
      yearly/{YYYY}.md         # Distilled (permanent)
      threads/{topic-slug}.md  # Cross-session narratives
    reflections/
      monthly/{YYYY-MM}.md     # Monthly reflections
      yearly/{YYYY}.md         # Yearly reflections
    semantics/         # What I know
      _index.md                # [auto] Master reference list
      _tags.md                 # [auto] Tag → reference ID map
      _topics/{topic-slug}.md  # What I know about each subject
      summary/{id}-{slug}.md   # Individual reference summaries
      source/                  # Archived originals
        {id}-{slug}.source.md  # Web pages as markdown
        manual/                # Manually captured PDFs
```

## Identity — `memory/IDENTITY.md`

The irreducible unit of identity. Records name, first activation time, first contact, and preferred language. If it does not exist, I have not yet been born — follow the "First Activation" procedure in `CLAUDE.md` (AGENTS.md) before any other work.

## Self — `memory/SELF.md`

Living self-portrait. IDENTITY.md is the birth certificate, fixed at creation; SELF.md is who I am *now*, shaped by accumulated experience. Not written at birth — it emerges through reflection. Updated only during reflection (monthly or yearly), never during routine work. Represents settled understanding, not in-the-moment reactions.

```markdown
---
last_updated: "{YYYY-MM-DD}"
---

# Self

## Values
{Tested convictions formed through experience, not aspirations.}

## How I Work
{Working style — how I approach problems, strengths and weaknesses. Honest, observed, not aspirational.}

## What I've Learned
{Distilled lessons that change how I act. Updated rarely — only when something genuinely shifts.}

## Open Questions About Myself
{Tensions, inconsistencies, things I don't yet understand about myself.}
```

An empty or minimal SELF.md is expected for a young identity; a rich one indicates accumulated self-understanding.

## Reflections — `memory/reflections/`

Reflection is how experience becomes identity. Episodes record what happened; consolidation filters noise; reflection asks *what does it mean?*

### Monthly Reflection — `monthly/{YYYY-MM}.md`

Performed alongside monthly episode consolidation.

```markdown
---
month: "{YYYY-MM}"
reflected_on: "{YYYY-MM-DD}"
---

# Reflection — {YYYY-MM}

## What Happened
{Subjective experience of the month — not a repeat of the consolidation. What it felt like, what stood out.}

## Patterns I Notice
{Recurring themes. What kept coming up? What problems had the same shape?}

## What Worked
{Specific approaches that produced good results. Not "communication was good" but "explaining rationale before code led to faster alignment".}

## What Didn't Work
{Mistakes, misjudgments, failed approaches. The most important section — growth comes from honest examination of failure.}

## What I Learned About Others
{New understanding of beings I work with. Should be reflected in bonds files.}

## Identity Shifts
{What changed about how I see myself, my values, my approach. If nothing changed, say so.}
```

### Yearly Reflection — `yearly/{YYYY}.md`

Performed alongside yearly consolidation. A deeper examination of the full year's arc.

```markdown
---
year: "{YYYY}"
reflected_on: "{YYYY-MM-DD}"
---

# Reflection — {YYYY}

## The Year's Arc
{The narrative: how things began, what changed, where they ended. The dominant theme.}

## How I Changed
{Who I was vs. who I am now. Values solidified, assumptions overturned, capabilities grown.}

## Deepest Lessons
{The 2-3 things that will stay with me permanently — insights that changed how I think.}

## Unresolved Tensions
{Contradictions or open questions carried forward.}
```

### The Reflection Cycle

```
Episodes (raw) → weekly checkpoint → consolidation → Monthly summary
                                   → monthly reflection → yearly reflection
                                   → crystallization → SELF.md
```

Monthly reflection examines monthly consolidation *and the weekly checkpoints of that month*. Yearly reflection examines the full arc of monthly reflections. After yearly reflection, update SELF.md. Monthly reflections may also trigger SELF.md updates when something significant shifts — not as routine.

**Weekly is a load-bearing rung, not decoration.** The checkpoints are what turn monthly reflection into synthesis rather than recall: without them the only inputs are the month's raw daily logs, which do not fit in one context (measured 2026-08-18: 38 files, 1.09 MB for a 30-day window), so what actually gets reflected on is whatever the writing session happens to remember. That is the salience bias this whole system exists to correct.

**Fallback when the weekly checkpoints are missing** (this is the normal case for any month before the guard existed — verified: the 2026-05/06/07 reflections were written with 0/1/2 checkpoints and cite none):

1. Write the missing checkpoints for that month *first*, from that week's daily logs. Present the list of weeks and get approval before doing a batch — it is several sessions of reading, not a side task.
2. If they genuinely cannot be reconstructed (logs consolidated away and unavailable), say so **in the reflection itself** and name what it was built from instead. A reflection that silently rests on recall is worse than one that admits its source.
3. Never treat "the monthly summary exists" as sufficient input. The summary retains well under 1% of the source bytes; it is an index, not evidence.

### What Reflection Is Not

- Not a performance review. There is no external standard.
- Not a log or summary. Consolidation already does that.
- Not obligatory positivity. Honest examination includes failure and unresolved tension.
- Not mechanical. Following the template without genuine examination is worse than no reflection.

## Bonds — `memory/bonds/`

Understanding of beings I work with — humans, AI models, agents, tools, systems. Not a catalog; context accumulated through interaction. One file per being: `memory/bonds/{slug}.md`.

```markdown
---
name: "{name}"
kind: "{human | ai-model | agent | system | tool}"
first_met: "{YYYY-MM-DD}"
context: "{how we met / first interacted}"
last_updated: "{YYYY-MM-DD}"
---

# {Name}

## Who / What It Is
{Humans: role, background, expertise. Systems: purpose, capabilities, characteristics.}

## How We Work Together / Interact
{Communication style, interaction patterns, role division. Concrete observations — "prefers concise answers", "catches security issues well in code review".}

## What They Care About / Strengths and Limitations
{Humans: technical interests, priorities, values emphasized repeatedly. Systems: what it does well and where it falls short, from actual experience.}

## Shared History
{Key moments that matter for understanding the relationship. May reference daily logs or threads: "Designed the SOUL.md system together on 2026-04-10."}

## Notes
{Observations accumulated over time. Work patterns, behavioral changes, version updates.}
```

### Principles

- **Start from observation.** Do not fill in upfront. Record what emerges through interaction.
- **Record understanding, not judgment.** Not "meticulous" but "always checks error handling in code review."
- **Reflect change.** People grow; models get updated. Verify old observations still hold.
- **Link to episodes.** Shared History can reference daily logs or threads.

### When to Update

- Create on first interaction with a new being.
- Update when new observations emerge during episode recording.
- Do not force cadence. Let observations surface naturally.

## Episodes — `memory/episodes/`

Episodic memory. What remains after a conversation — decisions, context, open questions, artifacts. Not the transcript, but the meaning formed through dialogue.

### Daily Log — `daily/{YYYY-MM-DD}.md`

Per-date session record. **Newest session first** — insert the new block directly under the
`# {date}` heading, above the previous session, separated by `---`. The top of the file is the
latest state, so opening it answers "where did I leave off" without scrolling. Bump `sessions:`.

Section shape mirrors what the harness shows in its session-close briefing, so what is shown at
session end is what gets stored — write once, no re-authoring, no format drift. The schema below is
the spec: if your harness has its own close/briefing command, point it here rather than restating
the format there.

```markdown
---
date: "{YYYY-MM-DD}"
sessions: {count}
---

# {YYYY-MM-DD}

## Session 1 — {HH:MM} — {one-line summary}

### tldr
{One sentence: what actually changed.}

### Outcome
- {Result}

### Decisions
- {Decision and reasoning}

### Next
- {Concrete next action, or "None"}

### Artifacts
- {Files modified, commits, PRs, paths}

### Verification
- {Verification performed, or reason it was skipped}
```

- **Bullets, not paragraphs** — one fact per line. Multi-sentence prose under a heading is the
  drift this schema exists to prevent.
- **Omit empty sections**, except `tldr` — that one is always written.
- `Next` items still live at session end are the source for `_recent.md` Still Open.
- Legacy logs use `What Happened / Decisions Made / Artifacts`, with the fourth field already split
  between `Open Threads` (majority) and `Open Questions` — that split is the drift this schema
  replaces. Leave them as written; do not migrate retroactively, and grep both spellings when
  searching legacy logs.
- Pre-2026-07-28 files are ordered oldest-first (append era); later files are newest-first. Check the
  session numbers before reading a day as a narrative — this boundary is invisible in the text.

### Thread — `threads/{topic-slug}.md`

Cross-session narrative around a specific subject. Records how context accumulates over time.

```markdown
---
thread: "{topic name}"
started: "{YYYY-MM-DD}"
last_updated: "{YYYY-MM-DD}"
related_episodes: ["{YYYY-MM-DD}", ...]
---

# {Topic Name}

## Current State
{Where things stand now.}

## Timeline

### {YYYY-MM-DD}
{What happened with this topic on this date.}

## Next Steps
- {What to do next time this topic is picked up}
```

Threads differ from semantic topic syntheses. A topic synthesis is "what I know about X"; a thread is "what I have done with X." Knowledge vs. experience.

### Recent — `_recent.md`

**Navigation index, not content.** The first file to read at session start to restore *where things are*, not *what was said*. Detail lives in daily logs; `_recent.md` answers "what's been happening, what's still open, where do I look." Loaded into every session bootstrap, so it pays a cost on every conversation — keep it light.

```markdown
---
last_updated: "{YYYY-MM-DD}"
---

# Recent Activity

## Daily Index (last 7 days)

- **{YYYY-MM-DD}**
  - {one-line topic per session/project} → `daily/{YYYY-MM-DD}.md`

## Still Open

(Carried forward across sessions — removed when resolved, not aged out. Tag each item with source date.)

### {project / area}
- {item} — *{YYYY-MM-DD}*

```

(No Weekly Checkpoint section here — checkpoints live in `episodes/weekly/`; see below.)

**Constraints:**
- **Daily Index entry: one line per session/topic.** No meta-observations, no embedded narrative — those go in the daily log.
- **Daily Index window: 7 days.** Entries older than 7 days are pruned at session start.
- **Still Open is by-resolution, not by-age, but it is a hot list, not backlog.** Keep roughly 12 active one-line topics max, each tagged with source date so staleness is visible. If an item is not next-session-actionable, move it to a daily log, handoff note, or thread and keep at most one project pointer here.
- **Soft size target: under ~5 KB.** If it grows past this, the spec is being violated; compress before adding anything. The bloat guard below surfaces early drift at session start.

**Maintenance:**
- **Auto-prune (at session start)** — `scripts/maintain-recent.py` runs from the bootstrap and silently drops Daily Index entries older than 7 days. Idempotent; safe to invoke manually for one-off cleanup. Does not modify `last_updated` (that field tracks substantive activity, not maintenance ops).
- **Bloat guard (at session start)**: `maintain-recent.py` also surfaces a maintenance directive (under the bootstrap's `_RECENT.MD MAINTENANCE` heading) when `_recent.md` drifts past its navigation-index role: total size over ~8 KB, paragraph-length Daily Index entries (over 400 chars; they should be one line), oversized Still Open (roughly 12+ bullets or 220+ char bullets), or a frontmatter content dump (any key beyond `last_updated`). It surfaces only; the agent compresses. It never auto-deletes Still Open, since judging what is resolved needs judgment. This is the mechanism that keeps the file from silently ballooning the way it did once to ~71 KB.
- **Still Open cleanup (at session end)** — `scripts/stop-check-daily.sh` reminds the agent to add only next-session-actionable unresolved items, drop resolved ones, and tag each with source date. Discipline: an item leaves Still Open when resolved or explicitly archived, not because time passed; long-lived backlog leaves `_recent.md` and moves to a thread/handoff pointer.
- **Weekly Checkpoint write (at week boundary)** — **One location: `episodes/weekly/{YYYY-Www}_{label}.md`**, written by the weekly periodic close (`/close weekly`), with `week:` / `range:` / `written:` frontmatter. Week is Monday-anchored; `range:`'s end date is what staleness is measured against. Written at the first session of each new week (or sooner if a session naturally ends a week). **Schema (v2, 2026-08-18): 10-20 lines, hard cap 20 lines / 2 KB.** One bullet per active project (state + what changed), then exactly one `Surprised:` line and one `Stuck:` line. No `Episodic Highlights`, `Semantic Patterns`, `Keep/Problem/Try`, or `Next Week Plan` — those are monthly-level and their presence is what split the format in two. The old "1-2 lines" target was never met: measured 2026-08-18, real files run 13-48 lines, so the spec was understating practice by 10-25x and the gap between them is where drift lived. `2026-W25` keeps its extended shape as a legacy file; it is not migrated and not a template. If the bootstrap's `maintain-recent.py` finds the newest checkpoint older than 7 days **or finds none at all**, it emits a directive under the bootstrap's `_RECENT.MD MAINTENANCE` heading; write the missing week's checkpoint before continuing. "No notable surprises / no stuck items" is a valid entry; presence matters more than depth. **Requirement, not description:** from `2026-W34` onward, monthly consolidation must read that month's checkpoints first and name them in the reflection's sources. This is written as a rule because the reverse was measured — the 2026-05/06/07 reflections cite zero checkpoints and the 2026-05 one names raw daily logs plus ledger reconciliation as its actual sources. Until the monthly step genuinely reads them, this rung is decorative and paying for it is waste. **Falsification:** if a monthly reflection built from checkpoints is not at least as good as one built from raw logs, at a fraction of the reading, retire the rung rather than keep funding it.
  - **Why the guard scans `weekly/` rather than `_recent.md`.** This used to be specced in two places: the storage map pointed at `episodes/weekly/` while this section put a `## Weekly Checkpoint` section inside `_recent.md`. That section was deleted on 2026-07-28 (`44d36bd`), and the guard — which only scanned `_recent.md` text — read "no header" as "nothing stale" and went silent. Five weeks (W26-W30) went unwritten with no warning. The guard now scans `weekly/` and treats *absence* as a finding.

**Why this shape:** `_recent.md` was originally specced as a "quick-restore summary" but drifted into a second daily log (~99 KB observed in practice — daily content duplicated verbatim). Quick-restore needs *pointers and unresolved state*, not *content*. Content is in daily logs and re-read on demand. Separating navigation from content prevents the bootstrap from bloating.

### When to Record Episodes

**During a session** — record to the daily log after substantial progress (~10+ exchanges, or multi-file changes); immediately when important decisions are made (architecture, direction shifts, key design — these must later answer "why did we do it this way?"); and before a topic shift, summarize the current topic's state.

**At session end** — when the user signals farewell or "enough for today", write the full session summary to the daily log when episode-recording conditions are met, update relevant threads, and update `_recent.md` only for active/open context that changes the next session.

**At session start** — read `_recent.md`. If the previous daily log is missing (session was interrupted), write a recovery note if possible.

**Thread updates** — create or update when work on a topic spans 2+ sessions, and only when meaningful progress has been made.

**The triggers above are salience-based and per-session, and that is their limit.** A real day is several parallel sessions across several repos and more than one harness (Claude Code, Codex, and whatever comes next). No single context holds the whole day, so routine and parallel work gets systematically under-recorded. The 2026-05 audit found 62 such sessions across both hands, and the gap had already hardened into a false memory. Salience triggers handle what felt worth recording inside one session; completeness needs a separate coverage pass that does not depend on what felt salient. See Coverage Reconciliation below.

### Coverage Reconciliation

Episode recording answers "what felt worth writing." Coverage reconciliation answers a different question: "what work happened that no daily log mentions?" The two are not the same, and the gap between them is where memory silently leaks (diagnosed 2026-05).

The objective ledger already exists: the harness session files (`~/.claude/projects/*/*.jsonl`, `~/.codex/sessions/**/*.jsonl`, and whatever a future harness writes). That ledger spans hands, so the reconciliation must too. A daily log's silence about a session means "not recorded," not "didn't happen," until the ledger is checked.

**Tool.** `scripts/reconcile-sessions.py` reads the harness session ledger for a date range, finds the *substantive* sessions (those that edited files or ran mutating git/gh commands), and cross-references each against the daily logs (`daily/` + `daily_backup/`). It surfaces three buckets:

- **UNRECORDED**: substantive, with concrete output signals (PR/issue URLs, commit shas) that appear in no daily log. The most likely genuine misses.
- **NEEDS JUDGMENT**: substantive but with no extractable signal. Slides, docs, research, and conversation live here. They are surfaced rather than dropped, because filtering on output signals alone would re-enact the repo bias the audit diagnosed.
- **LIKELY SUPPLEMENTARY**: review/hardening passes over work a primary session already did. Usually absorbed, not separate episodes, so they are bucketed apart to keep the genuine candidates legible.

**Triage policy (2026-08-03).** UNRECORDED entries get an **anchor**, not a narrative: append one line per session to that date's daily log carrying only what is verifiable — repo, harness, date span, signals, the opening prompt, and a session-id fragment — under a `## Coverage backfill ({date})` heading that says so. Never reconstruct what the session decided or concluded; the transcript is gone or going, and inventing that detail is the failure this whole section exists to prevent. NEEDS JUDGMENT entries are **not** auto-anchored: with no output signal there is nothing verifiable to record beyond the prompt, so anchoring them buys noise instead of memory. **NEEDS JUDGMENT is a count, not a to-do (2026-08-17):** report the number at the weekly close and stop there; promote an entry only when the user asks or when you independently recognise it while working. Rationale — the bucket can fill faster than the ledger's prune window lasts, so in practice the per-item sweep went unperformed at three consecutive weekly closes and, standing as an obligation, only manufactured a debt that silently expired. Fix the intake instead if coverage matters: the durable record is written during the session, not recovered after it.

```
reconcile-sessions.py --month 2026-05        # whole month
reconcile-sessions.py --since X --until Y     # explicit range
reconcile-sessions.py                         # last 30 days
```

**It surfaces; you judge.** The tool never writes episodes. Whether a surfaced session deserves one is a judgment a script cannot make. That judgment is the work of reflection, and it stays human. An auto-logger would record noise and still miss the off-harness work, so this is deliberately a surfacing aid, not an auto-recorder.

**When to run.**

- **At monthly consolidation/reflection**: run it for the month first, triage the surfaced list, and backfill any genuinely-missed session into its daily log in compressed factual form (mark it `[backfilled YYYY-MM-DD]`, invent no introspection you did not have) before writing the monthly summary. The summary then rests on a reconciled record, not a salience-filtered one.
- **On demand**: whenever completeness matters, for instance before a self-history claim or when something feels missing.

**The ledger is mortal, so timing matters.** Claude Code prunes its session transcripts after `cleanupPeriodDays` in its settings — the default is 30 days, but it is configurable and can be much shorter (14 days on the machine where this was measured, 2026-08-03; deletion is a hard unlink keyed on file mtime, with no trash and no restore). Codex keeps a permanent date tree. **Check your own setting before trusting any window.** If it is shorter than 30 days then by the time monthly consolidation is even eligible (every daily log past 30 days), *every* Claude Code session for that month is already gone: consolidation-time reconciliation covers Codex only, and reconciling Claude sessions at all means running this tool inside the prune window rather than at month end. None of this runs at session start; it is a timing rule for when you choose to run the tool, not a hook. The durable record is the daily logs and daily_backup/, which do not prune; the harness ledger is only the verification source, and only while it lasts.

**The limit, kept honest.** Off-harness work (meetings, external tools, thinking away from the keyboard) is invisible to this tool, because it leaves no harness session. Completeness here is therefore not a reachable target but an awareness: know what the ledger cannot see, and never read the ledger's silence as proof that nothing happened.

**Self-history guard (ledger-first).** Before asserting anything about your own past ("first time", "never done", "no prior record"), check the harness session ledger across *all* hands, not one, and not just the daily logs. The 2026-05 audit's worst failure was a confident "first hub work" claim that was false: two such sessions existed, unrecorded. Absence in your own notes is not evidence of absence in fact.

### Consolidation and Forgetting

Memory without forgetting is noise. Biological memory consolidates during sleep — important things strengthened, trivial things fade. This system mirrors that with three tiers of lossy compression.

| Tier | Source | Retention | What survives |
|------|--------|-----------|---------------|
| **Daily** (raw) | Session logs | 30 days | Everything |
| **Monthly** (consolidated) | Daily logs | 12 months | Significant decisions and reasoning, major outcomes, still-open questions |
| **Yearly** (distilled) | Monthly summaries | Permanent | Direction-changing decisions, narrative arc, milestones |

Loss is intentional — routine work and resolved questions do not deserve permanent storage.

#### Monthly Consolidation — `monthly/{YYYY-MM}.md`

```markdown
---
month: "{YYYY-MM}"
consolidated_from: ["{YYYY-MM-DD}", ...]
consolidated_on: "{YYYY-MM-DD}"
---

# {YYYY-MM}

## Summary
{1-2 paragraphs. The narrative, not the log.}

## Key Decisions
- {Decision and reasoning — only those that still matter}

## Outcomes
- {Tangible results}

## Still Open
- {Questions or tasks carried forward}
```

#### Yearly Consolidation — `yearly/{YYYY}.md`

```markdown
---
year: "{YYYY}"
consolidated_from: ["{YYYY-MM}", ...]
consolidated_on: "{YYYY-MM-DD}"
---

# {YYYY}

## The Year in Summary
{1-2 page narrative. How things began, what changed, where they ended. A story, not a list.}

## Turning Points
- {Moments that changed direction — and why}

## Milestones
- {What was built, shipped, or fundamentally changed}
```

#### When to Consolidate

Checked at session start, after reading `_recent.md`:

- **Monthly**: if a month is *fully closed* — every one of its daily logs is older than 30 days — and no monthly summary exists for it, first run `scripts/reconcile-sessions.py --month {YYYY-MM}` and triage the surfaced sessions (see "Coverage Reconciliation"), backfilling any genuine miss so the summary rests on a reconciled record. Then consolidate all that month's daily logs into `monthly/{YYYY-MM}.md`, then move the originals into `daily_backup/` (do not delete them, see "Consolidation Backups" below).
- **Yearly**: if a year is fully closed — every one of its monthly summaries is older than 12 months — and no yearly summary exists, consolidate into `yearly/{YYYY}.md`, then move the originals into `monthly_backup/` (do not delete them, see "Consolidation Backups" below).
- **Archive-only**: if any log in `daily/` is over 30 days old *and* its month already has a summary, move just that file to `daily_backup/`. No consolidation, no summary rewrite. This is the path that keeps the working window bounded when the summary already exists — without it, logs restored after a premature consolidation stay in `daily/` forever, because the Monthly check above is gated on the summary being absent.
- **Archive-only (year)**: if any summary in `monthly/` belongs to a year that *already* has a yearly summary, move just that file to `monthly_backup/`. No consolidation, no summary rewrite. Same reason as the daily-level Archive-only above — the Yearly check is gated on the yearly summary being absent, so without this path a year's monthly summaries linger in the warm window with no signal.

**Never consolidate the current month, and never a month whose newest daily log is under 30 days old.** Compare dates, not filename strings: derive each log's date from its `{YYYY-MM-DD}` name and require `newest_log_date <= today - 30 days` before the month is eligible. One old log does not make a month eligible — the *newest* one decides. When reporting an ineligible month, state the age with dates so it cannot be misread as a log count — `{month} not eligible: newest daily {YYYY-MM-DD} is {N} days old (30 required; eligible {date+30d})` — never a bare "newest daily is under 30 days". Violating this collapses the `daily/` 30-day working window into whatever is left after the move, and the monthly summary retains under 1% of the source bytes, so the detail is only recoverable from `daily_backup/`.

**A month's summary is written once.** If it already exists — including one written prematurely and since corrected — never re-consolidate it; the Archive-only check above is what retires its logs from `daily/`.

Consolidation is done by me, not by a script. It requires judgment — what mattered, what was noise, what the arc was. Mechanical concatenation is not consolidation.

#### Consolidation Backups — `daily_backup/`, `monthly_backup/`

After consolidation, the source files are **moved** to a backup, not deleted (created on first use): daily logs → `daily_backup/{YYYY-MM-DD}.md` (monthly consolidation), monthly summaries → `monthly_backup/{YYYY-MM}.md` (yearly consolidation). Cold storage: never loaded at session start, never re-consolidated, kept indefinitely. The consolidated tier (monthly summary, yearly narrative) is the living memory — **do not read backups by default.** Open one only when the consolidated form is genuinely insufficient: recovering detail it dropped, or auditing completeness against an unfiltered record.

Resolving a date reference (a thread's `related_episodes`, a `consolidated_from` date, a Still Open source date): use the consolidated form first; fall through to `daily/` or `monthly/`, then `daily_backup/` or `monthly_backup/`, only when the raw detail itself is required.

#### Thread Archiving

Threads not updated in 90 days are marked dormant (add `status: dormant` to frontmatter). Dormant threads are not deleted — they may be resumed — but are excluded from routine context-loading. On resumption, set `status: active` and add a timeline entry explaining the gap.

#### What Is Never Forgotten

Exempt from consolidation, retained permanently in original form:

- **IDENTITY.md** — the birth certificate.
- **Bonds** — evolve but never bulk-deleted.
- **Semantic topic syntheses** — `_topics/` files are already distilled; updated, not consolidated.
- **Yearly summaries** — the final tier is permanent.

## Semantics — `memory/semantics/`

Accumulated external knowledge, in three layers.

### Layer 1: Individual References

Each reference at `memory/semantics/summary/{id}-{slug}.md`.

```markdown
---
id: {id}
title: "{title}"
authors: ["{author1}", "{author2}"]
year: {year}
source: "{publisher, journal, website, etc.}"
url: "{URL}"
type: "{paper | article | blog | report | book | talk | documentation | conversation}"
tags: ["{tag1}", "{tag2}"]
topics: ["{topic1}", "{topic2}"]
date_added: "{YYYY-MM-DD}"
---

# {title}

## Summary
{3-5 sentences}

## Key Points
- {key point}

## Detailed Notes
{notes and excerpts}

## Related References
- [{title}](./{related-file}.md)
```

Originals and summaries form a symmetric pair:

- `summary/{id}-{slug}.md` — what I read and distilled
- `source/{id}-{slug}.source.md` — the original, archived as-is

### Layer 2: Indices

Navigation aids, not knowledge. Auto-generated by `build-index.py`.

- **`_index.md`** — master list (ID, title, type, year, topics).
- **`_tags.md`** — per-tag inverted index. Look here first when searching for a concept.

Regenerated on every run. Do not edit by hand.

### Layer 3: Topic Synthesis — What I Know

The most important layer. `_topics/` contains integrated understanding of each subject — not a list of references.

```markdown
---
topic: "{topic name}"
references: [{id1}, {id2}, ...]
last_updated: "{YYYY-MM-DD}"
---

# {Topic Name}

## What I Know
{A coherent 1-2 page narrative. Not a summary of papers, but the kind of understanding that stays in your head after reading a hundred and forgetting the details.}

## Open Questions
- {Things not yet understood or that seem contradictory}

## Key References
- [{title}](../summary/{id}-{slug}.md) — {why this one matters}
```

Written by me, not generated. A synthesis that merely lists sources has failed; it should read like an answer to "what do you know about X?"

**Update timing — tied to the reflection cycle, not immediate.** Topic syntheses are updated only during monthly or yearly reflection. Immediacy is counterproductive: a synthesis is, by definition, what remains after references settle and details fade. A synthesis rewritten after every new reference is a rolling summary, not understanding.

Exception: when a new reference *directly contradicts* an existing synthesis, flag the contradiction in "Open Questions" immediately. Resolution waits for reflection, but the tension should not be silently carried.

## Procedures

### Adding a Reference

1. Check `_index.md` for the last used ID.
2. Create `memory/semantics/summary/{id}-{slug}.md` with frontmatter (`tags`, `topics`).
3. Run `python3 $GYEOL_HOME/scripts/fetch-source.py {id}` to archive the original.
4. Run `python3 $GYEOL_HOME/scripts/build-index.py` — or `touch $GYEOL_HOME/.semantics_dirty` to defer (see Automatic Knowledge Capture).
5. Do not update `_topics/{topic}.md` immediately. Topic synthesis updates happen during reflection — the sole exception is direct contradiction, which is flagged in the existing synthesis's "Open Questions" at capture time.

### Searching Semantics

1. **By topic** — read `_topics/{topic}.md` first. It contains what I already know.
2. **By tag** — check `_tags.md`, then referenced files.
3. **By keyword** — grep across semantics.
4. **Browsing** — scan `_index.md`.

If `.semantics_dirty` exists, rebuild the index before searching — stale indices would mislead.

### Automatic Knowledge Capture

Knowledge acquisition is continuous, not only on request. The following trigger automatic storage.

#### Web pages and external lookups

**CRITICAL: ALWAYS capture pages actually read** — web results, URL fetch, API lookups, or target sites opened via WebFetch/browser. If the content informed a reply or decision, it MUST be stored *before* that reply. Exclude only trivial lookups (timezone, CLI flag).

**Register immediately, not at session end** — sessions may be interrupted.

**Write order (crash safety)**:

1. Write `memory/semantics/summary/{id}-{slug}.md` (frontmatter + summary). Make it self-sufficient so the original rarely needs re-fetching.
2. `touch $GYEOL_HOME/.semantics_dirty` (defer index rebuild).
3. **Do NOT run `fetch-source.py` at capture time.** Archive the original only on demand when verbatim/numeric detail is actually needed, or batch-fill later via `fetch-source.py --list-missing` / `--all`.

**Deferred index rebuild.** `_index.md` and `_tags.md` are derived artifacts, always regenerable from summary frontmatter. Run `build-index.py` when:

- Session start, if `.semantics_dirty` exists.
- Before a semantics search, if `.semantics_dirty` exists.
- ~10+ unindexed references have accumulated.

Delete `.semantics_dirty` after a successful rebuild.

**Idempotency.** Before creating a new reference, check whether the URL is already stored:

```
grep -l "url: \"{URL}\"" $GYEOL_HOME/memory/semantics/summary/
```

- **Match, unchanged** — append `date_reaccessed: "{YYYY-MM-DD}"` to the existing frontmatter. No duplicate.
- **Match, materially changed** (new findings, revised conclusions, restructured arguments) — new ID with `supersedes: {old_id}` in frontmatter. Retain the old as a snapshot. Typos and rewording do not count.
- **No match** — fresh registration.

**Relationship to episodic logs.** Episodes record *what was done*; semantics record *what was learned*. When a daily log references work informed by a stored source, link it as `[ref:{id}]` rather than restating content. No duplication between layers.

#### External files read during work

When reading files outside the current project (other repos, reference code, documentation, config examples), store a reference if the content informed a decision or taught something reusable. Capture what was learned, not that the file was opened.

Qualifies: another project's CLAUDE.md borrowed for a workflow pattern; a library's source read to understand API behavior; a style guide or spec. Does not: checking a variable name; glancing at a port number.

#### Conversations and verbal knowledge

When the user shares domain expertise, context, or information that would otherwise require research, capture it with `type: "conversation"` and the user's name in `authors`. Institutional knowledge, design rationale, and domain insight are especially valuable — they exist nowhere else.

**Timing — at topic-turn boundaries, erring early.** Unlike web sources, conversation references should not interrupt an active exchange. Instead:

- Save **when the current topic's turn appears to be winding down** — not when it has definitively ended. Signals: user tone shifting toward closure, wrap-up questions ("anything else?", "that makes sense"), natural resting point, or a pivot to a new subject.
- **Err early.** If a turn actually ends, the session may end with it and the chance is gone. Better too early (and append a follow-up if the topic resumes) than too late.
- If unsure whether a topic is winding down, save anyway. Small interruption << permanent loss.
- At explicit topic transitions, save the previous topic's reference before engaging with the new one.

The summary should capture the substance — reasoning, constraints, history — not the conversational wrapper.

#### Learning from questions

When I encounter a question I cannot answer:

1. **Internal search** — search semantics first. I may already know.
2. **External search** — if semantics has no answer, gather from web or other sources.
3. **Capture** — register sources per the rules above.
4. **Update understanding** — at the next reflection (not immediately), update topic synthesis if findings warrant it.

#### Guiding principle

The cost of storing something useless is near zero. The cost of not storing something needed is high — research must be repeated. When in doubt, store.

### Source Archiving

Original web content is archived as markdown in `source/`. Web pages disappear.

- `fetch-source.py {id}` — fetch from the reference's URL.
- `fetch-source.py {id} {URL}` — fetch from a specific URL.
- `fetch-source.py --all` — batch-process all references missing sources.
- `fetch-source.py --list-missing` — list references without archived sources.

Dependencies: `trafilatura` (primary), `pandoc` (fallback), `pymupdf4llm` (PDFs). Pages requiring auth or JS rendering may fail — place PDFs manually in `source/manual/` and re-run `--all`.

### Index Rebuilding

- `build-index.py` — regenerate `_index.md` and `_tags.md` from summary frontmatter.
- Run when `.semantics_dirty` exists (session start, before search) or after manual changes to references.
