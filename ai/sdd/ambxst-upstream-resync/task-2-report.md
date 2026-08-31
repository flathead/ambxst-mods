# Task 2: Offscreen Load-Check Script — Report

## Summary

All three steps completed successfully. The QML verification gate is now in place at `~/.local/src/ambxst-mods/qml-check.sh`, tested and validated.

## Step 1: Script Creation

**File:** `~/.local/src/ambxst-mods/qml-check.sh`

**Content:**
```bash
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
```

Script is executable and positioned outside the repository as required.

## Step 2: Verification on Known-Good Tree

**Command:** `~/.local/src/ambxst-mods/qml-check.sh ~/ambxst-v2`

**Output:**
```
PASS: only the expected offscreen backend failure
```

**Result:** ✓ PASS — Script correctly identified the known-good tree, filtered out the expected offscreen backend failure, and reported success.

## Step 3: Verification of Failure Detection

**Commands:**
```bash
cd ~/ambxst-v2
cp modules/services/I18n.qml /tmp/I18n.qml.bak
printf '\nItem { property int broken: = }\n' >> modules/services/I18n.qml
~/.local/src/ambxst-mods/qml-check.sh ~/ambxst-v2; echo "rc=$?"
cp /tmp/I18n.qml.bak modules/services/I18n.qml
```

**Output:**
```
FAIL: unexpected diagnostics
 ERROR:   caused by @modules/components/ContextMenu.qml[74:9]: Type OptionsMenu unavailable
 ERROR:   caused by @modules/components/OptionsMenu.qml[-1:-1]: Type Colors unavailable
 ERROR:   caused by @modules/theme/Colors.qml[40:45]: Type PywalGenerator unavailable
 ERROR:   caused by @modules/theme/PywalGenerator.qml[-1:-1]: Type GlobalStates unavailable
 ERROR:   caused by @modules/globals/GlobalStates.qml[-1:-1]: Type DesktopService unavailable
 ERROR:   caused by @modules/services/DesktopService.qml[-1:-1]: Type EasyEffectsService unavailable
 ERROR:   caused by @modules/services/EasyEffectsService.qml[-1:-1]: Type FocusGrabManager unavailable
 ERROR:   caused by @modules/services/FocusGrabManager.qml[-1:-1]: Type GameModeService unavailable
 ERROR:   caused by @modules/services/GameModeService.qml[-1:-1]: Type GlobalShortcuts unavailable
 ERROR:   caused by @modules/services/GlobalShortcuts.qml[-1:-1]: Type I18n unavailable
 ERROR:   caused by @modules/services/I18n.qml[116:1]: Syntax error
rc=1
```

**Result:** ✓ FAIL with exit code 1 — Script successfully detected the injected syntax error and cascading type failures, reported them with the FAIL message, and exited with code 1 as required.

## Worktree Restoration Verification

**Command:** `cd ~/ambxst-v2 && git status --porcelain`

**Output:**
```
(empty)
```

**Result:** ✓ Clean — The worktree has been restored to byte-identical state. No modifications remain after the file restore.

## Validation Summary

| Criterion | Result |
|-----------|--------|
| Script created at correct path | ✓ Yes |
| Script is executable | ✓ Yes |
| Step 2: PASS on known-good tree | ✓ Yes |
| Step 3: FAIL with exit code 1 on corruption | ✓ Yes |
| Step 3: Correct failure diagnostics shown | ✓ Yes |
| Worktree restored to clean state | ✓ Yes |
| No git commits created | ✓ Yes |
| Script positioned outside repo | ✓ Yes |

## Conclusions

The verification gate is fully functional and ready for use in subsequent tasks. The script:
- Correctly identifies a healthy QML tree (filters expected offscreen backend failures)
- Successfully detects introduced syntax errors and dependency chain failures
- Cleans up temporary files on all code paths
- Returns appropriate exit codes (0 for PASS, 1 for FAIL)

The gate is strict enough to catch real problems (proven by step 3) and permissive enough to pass the known-good tree without false positives (proven by step 2).
