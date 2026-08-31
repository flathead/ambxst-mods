### Task 2: Offscreen load-check script

**Files:**
- Create: `~/.local/src/ambxst-mods/qml-check.sh`

This script is local tooling and stays out of the repository.

- [ ] **Step 1: Write the script**

```bash
cat > ~/.local/src/ambxst-mods/qml-check.sh <<'EOF'
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
EOF
chmod +x ~/.local/src/ambxst-mods/qml-check.sh
```

- [ ] **Step 2: Verify it passes on the known-good tree**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/ambxst-v2
```

Expected: `PASS: only the expected offscreen backend failure`

- [ ] **Step 3: Verify it actually catches a break**

Prove the gate works before trusting it.

```bash
cd ~/ambxst-v2
cp modules/services/I18n.qml /tmp/I18n.qml.bak
printf '\nItem { property int broken: = }\n' >> modules/services/I18n.qml
~/.local/src/ambxst-mods/qml-check.sh ~/ambxst-v2; echo "rc=$?"
cp /tmp/I18n.qml.bak modules/services/I18n.qml
```

Expected: `FAIL: unexpected diagnostics` and `rc=1`, then the file is restored

---

