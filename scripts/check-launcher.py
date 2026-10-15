#!/usr/bin/env python3
"""Exercise the patched AppSearch with a real Quickshell desktop-entry rescan."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="Clean supported Ambxst checkout")
    args = parser.parse_args()
    package = Path(__file__).resolve().parents[1] / "packages/app-launcher-reliability"
    qs = shutil.which("qs")
    if not qs:
        parser.error("Quickshell (qs) is required for the runtime test")
    with tempfile.TemporaryDirectory(prefix="app-rescan-", dir="/tmp") as directory:
        root = Path(directory)
        base = root / "base"
        subprocess.run(["git", "clone", "--shared", str(args.source.resolve()), str(base)],
                       check=True, capture_output=True)
        subprocess.run(["git", "-C", str(base), "apply", str(package / "patches/feature.patch")], check=True)
        services = root / "modules/services"
        services.mkdir(parents=True)
        shutil.copy2(base / "modules/services/AppSearch.qml", services / "AppSearch.qml")
        (services / "UsageTracker.qml").write_text(
            'pragma Singleton\nimport QtQuick\nQtObject { function getUsageScore(id) { return 0; } }\n')
        (services / "qmldir").write_text(
            'singleton AppSearch 1.0 AppSearch.qml\nsingleton UsageTracker 1.0 UsageTracker.qml\n')
        shutil.copy2(package / "tests/rescan.qml", root / "shell.qml")
        marker = root / "launches"
        old_marker = root / "old-command"
        (root / "mark.py").write_text(
            'from pathlib import Path\nimport sys\nwith Path(sys.argv[1]).open("a") as f: f.write("x")\n')
        def entry(target):
            return (f'[Desktop Entry]\nType=Application\nName=Steam\nIcon=steam\n'
                    f'Exec=python3 {root}/mark.py {target}\n')
        for kind in ["user", "system"]:
            applications = root / kind / "applications"
            applications.mkdir(parents=True)
            (applications / "steam.desktop").write_text(entry(old_marker))
        (root / "user/applications/bg3.desktop").write_text(
            "[Desktop Entry]\nType=Application\nName=Baldur's Gate 3\nIcon=steam_icon_1086940\n"
            "Exec=steam steam://rungameid/1086940\n")
        (root / "change-entry.py").write_text(
            f'from pathlib import Path\nPath({str(root / "user/applications/steam.desktop")!r})'
            f'.write_text({entry(marker)!r})\n')
        runtime = root / "run"
        runtime.mkdir(mode=0o700)
        env = {**os.environ, "QT_QPA_PLATFORM": "offscreen", "XDG_RUNTIME_DIR": str(runtime),
               "XDG_DATA_HOME": str(root / "user"), "XDG_DATA_DIRS": str(root / "system"),
               "PROBE_ROOT": str(root)}
        result = subprocess.run([qs, "-p", str(root / "shell.qml")], env=env,
                                text=True, capture_output=True, timeout=15)
        output = result.stdout + result.stderr
        print(output, end="")
        if result.returncode or "FAIL" in output or output.count("PASS") != 6:
            raise SystemExit("Quickshell rescan assertions failed")
        if old_marker.exists() or not marker.exists() or marker.read_text() != "xx":
            raise SystemExit("Saved launcher/search callbacks did not both use the updated command")
        print("PASS both saved callbacks launch the updated desktop command")


if __name__ == "__main__":
    main()
