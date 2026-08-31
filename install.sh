#!/usr/bin/env bash
set -euo pipefail

# Ambxst Mods Installer
# Applies custom modifications on top of a clean ambxst install.
#
# Modifications:
#   1. AudioDeviceSwitcher — bar button for audio I/O device switching
#      with Arctis headset battery display and volume scroll
#   2. Audio.qml — wpctl fallback for reliable sink/source switching
#   3. CompactPlayer — volume scroll on the media player notch
#   4. cli.sh — fix QT_QPA_PLATFORMTHEME (kde instead of qt6ct)
#
# Usage:
#   ./install.sh [ambxst-dir]
#   Default ambxst-dir: ~/.local/src/ambxst

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AMBXST_DIR="${1:-$HOME/.local/src/ambxst}"

if [[ ! -f "$AMBXST_DIR/shell.qml" ]]; then
    echo "Error: ambxst not found at $AMBXST_DIR"
    echo "Usage: $0 [path-to-ambxst]"
    exit 1
fi

echo "Ambxst directory: $AMBXST_DIR"
cd "$AMBXST_DIR"

# --- 1. Copy new files ---
echo "[1/3] Copying AudioDeviceSwitcher.qml..."
cp "$SCRIPT_DIR/AudioDeviceSwitcher.qml" modules/bar/AudioDeviceSwitcher.qml

# --- 2. Apply patch ---
echo "[2/3] Applying patches..."
if git apply --check "$SCRIPT_DIR/changes.patch" 2>/dev/null; then
    git apply "$SCRIPT_DIR/changes.patch"
    echo "  Patch applied cleanly."
else
    echo "  Patch doesn't apply cleanly (already applied or ambxst changed)."
    echo "  Trying with --3way merge..."
    if git apply --3way "$SCRIPT_DIR/changes.patch" 2>/dev/null; then
        echo "  3-way merge succeeded."
    else
        echo "  Falling back to manual patching..."
        patch -p1 --forward --batch < "$SCRIPT_DIR/changes.patch" || true
        echo "  Check for .rej files if something failed."
    fi
fi

# --- 3. Verify ---
echo "[3/3] Verifying..."
errors=0

if [[ ! -f modules/bar/AudioDeviceSwitcher.qml ]]; then
    echo "  FAIL: AudioDeviceSwitcher.qml missing"
    errors=$((errors + 1))
fi

if ! grep -q "AudioDeviceSwitcher" modules/bar/BarContent.qml 2>/dev/null; then
    echo "  FAIL: AudioDeviceSwitcher not in BarContent.qml"
    errors=$((errors + 1))
fi

if ! grep -q "wpctlProc" modules/services/Audio.qml 2>/dev/null; then
    echo "  FAIL: wpctl fix not in Audio.qml"
    errors=$((errors + 1))
fi

if ! grep -q "WheelHandler" modules/widgets/defaultview/CompactPlayer.qml 2>/dev/null; then
    echo "  FAIL: Volume scroll not in CompactPlayer.qml"
    errors=$((errors + 1))
fi

if grep -q 'QT_QPA_PLATFORMTHEME=qt6ct' cli.sh 2>/dev/null; then
    echo "  WARN: cli.sh still has qt6ct (may need manual fix)"
fi

if [[ $errors -eq 0 ]]; then
    echo ""
    echo "All mods installed successfully."
    echo "Restart QuickShell: killall qs && ambxst &"
else
    echo ""
    echo "$errors check(s) failed. Review output above."
fi
