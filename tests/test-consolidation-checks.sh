#!/bin/bash
# Consolidation-directive tests for scripts/session-bootstrap-json.sh.
#
# Drives the REAL script against a synthetic $GYEOL_HOME, so the rules are checked
# as they actually run rather than as a reimplementation. Covers the year level
# (Yearly / Archive-only(year), per year, incl. the 12-month boundary) plus a
# month-level regression so the two loops cannot silently break each other.
#
# Run:  bash tests/test-consolidation-checks.sh
# Extend: append a block plus `chk "<name>" <expected> "$(cnt \'<needle>\')"`.
# Cases are all relative to today, so the suite does not rot as the calendar moves.
set -u
BASE="$(dirname "$0")"
H="$BASE/gy"; rm -rf "$H"
mkdir -p "$H/memory/episodes/daily" "$H/memory/episodes/monthly" \
         "$H/memory/episodes/yearly" "$H/memory/episodes/monthly_backup" "$H/scripts"
: > "$H/SOUL.md"
printf -- '---\nlast_updated: %s\n---\n' "$(date +%Y-%m-%d)" > "$H/memory/episodes/_recent.md"
cp "$BASE/../scripts/session-bootstrap-json.sh" "$H/scripts/"

run() { GYEOL_HOME="$H" sh "$H/scripts/session-bootstrap-json.sh" </dev/null 2>/dev/null; }
cnt() { run | grep -c "$1"; }
reset_months() { rm -f "$H/memory/episodes/monthly/"*.md "$H/memory/episodes/yearly/"*.md; }

CUR_Y=$(date +%Y); CUR_M=$(date +%m)
# a month N months before the current month, as YYYY-MM
back() { python3 -c "
cy,cm=$CUR_Y,int('$CUR_M'); t=cy*12+cm-$1; print(f'{(t-1)//12:04d}-{(t-1)%12+1:02d}')"; }

pass=0; fail=0
chk() { # name expected actual
  if [ "$2" = "$3" ]; then echo "  PASS  $1 (=$3)"; pass=$((pass+1));
  else echo "  FAIL  $1 (expected $2, got $3)"; fail=$((fail+1)); fi; }

echo "=== 현재 기준월: $CUR_Y-$CUR_M ==="

echo "--- Y1: 2025 완결(요약 없음) -> YEARLY DUE ---"
# 2025-11 은 2026-08 기준 9개월이라 아직 미달 — 실제로 2025 전체가 적격이 되는 시점은
# 최신월 2025-12 가 12개월을 넘기는 2026-12. 규칙 검증용으로 적격 구간을 쓴다.
reset_months
: > "$H/memory/episodes/monthly/2025-03.md"; : > "$H/memory/episodes/monthly/2025-06.md"
chk "YEARLY for 2025" 1 "$(cnt 'Newest monthly summary of 2025')"
chk "no ARCHIVE-ONLY(year)" 0 "$(cnt 'ARCHIVE-ONLY DUE (year)')"

echo "--- Y2: 2025 + yearly 요약 존재 -> ARCHIVE-ONLY(year) ---"
: > "$H/memory/episodes/yearly/2025.md"
chk "ARCHIVE-ONLY(year) 2025" 1 "$(cnt 'Year 2025 already has')"
chk "no YEARLY" 0 "$(cnt 'YEARLY CONSOLIDATION DUE')"
chk "strays 열거됨" 1 "$(run | grep -c '2025-03.md 2025-06.md')"

echo "--- Y3: 올해($CUR_Y) 는 어떤 지시도 없어야 함 ---"
reset_months
: > "$H/memory/episodes/monthly/$CUR_Y-01.md"
chk "current-year silent" 0 "$(cnt "of $CUR_Y")"

echo "--- Y4: 경계값 11개월 전 -> 무지시 / 12개월 전 -> 발동 ---"
reset_months
: > "$H/memory/episodes/monthly/$(back 11).md"
chk "11개월 -> 무지시" 0 "$(cnt 'YEARLY CONSOLIDATION DUE')"
reset_months
: > "$H/memory/episodes/monthly/$(back 12).md"
chk "12개월 -> 발동" 1 "$(cnt 'YEARLY CONSOLIDATION DUE')"

echo "--- Y5: 막힌 2025 가 통합대상 2024 를 가리면 안 됨(다년 루프) ---"
reset_months
: > "$H/memory/episodes/monthly/2024-06.md"          # yearly 없음 -> YEARLY
: > "$H/memory/episodes/monthly/2025-06.md"
: > "$H/memory/episodes/yearly/2025.md"              # yearly 있음 -> ARCHIVE-ONLY
chk "2024 YEARLY 발행" 1 "$(cnt 'Newest monthly summary of 2024')"
chk "2025 ARCHIVE-ONLY 발행" 1 "$(cnt 'Year 2025 already has')"

echo "--- Y5b: 실제 2025 타임라인 — 2025-12 보유 시 2026-08 무지시 / 2026-12 이후 발동 ---"
reset_months
: > "$H/memory/episodes/monthly/2025-12.md"
chk "2025-12 보유 -> 2026-08 무지시" 0 "$(cnt 'YEARLY CONSOLIDATION DUE')"
echo "     (2025-12 는 현재 $(python3 -c "print((2026*12+8)-(2025*12+12))")개월 전 — 12개월 도달은 2026-12)"

echo "--- Y6: monthly 비었을 때 무지시·무오류 ---"
reset_months
chk "empty -> 무지시" 0 "$(cnt 'DUE')"

echo "--- Y7: 월 단위 회귀 (연 로직 추가로 깨지지 않았나) ---"
: > "$H/memory/episodes/daily/2026-05-03.md"; : > "$H/memory/episodes/daily/2026-05-27.md"
: > "$H/memory/episodes/daily/2026-06-04.md"
: > "$H/memory/episodes/monthly/2026-05.md"
chk "2026-05 ARCHIVE-ONLY(day)" 1 "$(cnt 'Month 2026-05 already has')"
chk "2026-06 MONTHLY" 1 "$(cnt 'Newest daily log of 2026-06')"

echo
echo "TOTAL: $pass passed, $fail failed"
[ "$fail" = 0 ] && echo "YEARLY RESULT: PASS" || echo "YEARLY RESULT: FAIL"
