#!/usr/bin/env bash
# Extract one task's full text from the plan into the workspace, never into the repo.
set -euo pipefail
PLAN="$1"; N="$2"
W="$(dirname "$0")"
awk -v n="$N" '
  $0 ~ "^### Task " n ":" {inside=1}
  inside && /^### Task / && $0 !~ "^### Task " n ":" {inside=0}
  inside && /^## / && !/^### / {inside=0}
  inside {print}
' "$PLAN" > "$W/task-$N-brief.md"
lines=$(wc -l < "$W/task-$N-brief.md")
[ "$lines" -gt 5 ] || { echo "FAIL: task $N brief is $lines lines" >&2; exit 1; }
echo "$W/task-$N-brief.md ($lines lines)"
