#!/usr/bin/env bash
# Load an Ambxst tree offscreen and report anything beyond the expected
# layer-shell backend failure. Offscreen resolves the full QML type graph,
# so syntax errors and unknown properties surface here.
set -uo pipefail
TREE="${1:-$HOME/ambxst-v2}"
LOG=$(mktemp)
QT_QPA_PLATFORM=offscreen timeout 25s qs -p "$TREE/shell.qml" >"$LOG" 2>&1
# Strip ANSI colour, drop the known-good offscreen failure and its noise.
sed -e 's/\x1b\[[0-9;]*m//g' "$LOG" \
  | grep -E '^\s*(ERROR|WARN)' \
  | grep -vE 'No PanelWindow backend loaded|Type ContextMenu unavailable|Failed to load configuration' \
  | grep -vE 'WAYLAND_DISPLAY is present|set QT_QPA_PLATFORM|--- WARNING ---' \
  > "$LOG.filtered"
if [ -s "$LOG.filtered" ]; then
  echo "FAIL: unexpected diagnostics"
  cat "$LOG.filtered"
  rm -f "$LOG" "$LOG.filtered"
  exit 1
fi
echo "PASS: only the expected offscreen backend failure"
rm -f "$LOG" "$LOG.filtered"
