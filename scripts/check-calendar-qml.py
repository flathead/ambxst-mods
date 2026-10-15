#!/usr/bin/env python3
"""Test the calendar's QML controls and bar with an isolated settings file."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="Composed calendar source tree")
    args = parser.parse_args()
    source = args.source.resolve()
    repo = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="calendar-qml-", dir="/tmp") as directory:
        root = Path(directory)
        def write(name, content):
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
        def copy(name):
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source / name, target)
        for name in ["modules/bar/BarCalendarIndicator.qml", "modules/services/CalendarService.qml",
                     "modules/widgets/dashboard/controls/CalendarPanel.qml"]:
            copy(name)
        helper = source / "modules/services/CalendarEventSelection.js"
        if not helper.exists():
            helper = repo / "packages/calendar-integration/payload/modules/services/CalendarEventSelection.js"
        shutil.copy2(helper, root / "modules/services/CalendarEventSelection.js")
        write("modules/services/qmldir", "singleton CalendarService 1.0 CalendarService.qml\nsingleton I18n 1.0 I18n.qml\n")
        strings = {language: {key: value for key, value in json.loads(
            (source / "translations" / f"{language}.json").read_text()).items() if key.startswith("calendar.")}
            for language in ["en", "ru", "es"]}
        write("modules/services/I18n.qml", '''pragma Singleton
import QtQuick
QtObject {
    property string resolvedLanguage: "en"
    property var dictionaries: (''' + json.dumps(strings, ensure_ascii=False) + ''')
    function t(key) { return dictionaries[resolvedLanguage][key] || key; }
}
''')
        write("modules/globals/qmldir", "singleton GlobalStates 1.0 GlobalStates.qml\n")
        write("modules/globals/GlobalStates.qml", "pragma Singleton\nimport QtQuick\nQtObject {}\n")
        write("config/qmldir", "singleton Config 1.0 Config.qml\n")
        config = (source / "config/Config.qml").read_text()
        start = config.index("        adapter: JsonAdapter {", config.index("id: calendarLoader"))
        end = config.index("\n        }", start)
        adapter = config[start:end + len("\n        }")]
        write("config/Config.qml", '''pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    property bool calendarReady: false
    property int animDuration: 0
    property string defaultFont: "DejaVu Sans"
    property QtObject theme: QtObject { property string font: "DejaVu Sans" }
    property QtObject calendar: store.adapter
    function saveCalendar() { store.writeAdapter(); }
    FileView {
        id: store
        path: Quickshell.env("CALENDAR_SETTINGS_FILE")
''' + adapter + '''
    }
}
''')
        colors = ["outline", "outlineVariant", "overBackground", "overSurfaceVariant", "primary", "red",
                  "surfaceBright", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerLow"]
        write("modules/theme/Colors.qml", "pragma Singleton\nimport QtQuick\nQtObject {\n" +
              "\n".join(f'property color {name}: "#cccccc"' for name in colors) + "\n}\n")
        write("modules/theme/Styling.qml", '''pragma Singleton
import QtQuick
QtObject {
    function fontSize(delta) { return 16 + delta; }
    function radius(delta) { return 8 + delta; }
    function srItem(name) { return "#cccccc"; }
}
''')
        write("modules/theme/Icons.qml", '''pragma Singleton
import QtQuick
QtObject {
    property string font: "DejaVu Sans"
    property string calendarBlank: "C"
    property string arrowLeft: "<"
    property string caretDown: "v"
    property string caretRight: ">"
    property string sync: "S"
}
''')
        write("modules/theme/qmldir", "\n".join(f"singleton {name} 1.0 {name}.qml" for name in ["Colors", "Styling", "Icons"]) + "\n")
        write("modules/components/StyledRect.qml", '''import QtQuick
Rectangle {
    property string variant: "pane"
    property bool enableShadow: false
    property bool enableBorder: false
    color: "#333333"
}
''')
        write("modules/components/BarPopup.qml", '''import QtQuick
Item {
    property Item anchorItem
    property var bar
    property int popupPadding: 12
    property int contentWidth: 260
    property int contentHeight: 0
    property bool isOpen: false
    visible: isOpen
    function toggle() { isOpen = !isOpen; }
}
''')
        write("modules/components/Separator.qml", "import QtQuick\nRectangle { property bool vert: false; implicitHeight: 1 }\n")
        write("modules/components/qmldir", "StyledRect 1.0 StyledRect.qml\nBarPopup 1.0 BarPopup.qml\nSeparator 1.0 Separator.qml\n")
        write("modules/widgets/dashboard/controls/PanelTitlebar.qml", '''import QtQuick
Item {
    property string title
    property string statusText
    property color statusColor
    property var actions
    implicitHeight: 48
}
''')
        shutil.copy2(repo / "packages/calendar-integration/tests/integration.qml", root / "shell.qml")
        settings = root / "calendar.json"
        settings.write_text(json.dumps({"barIndicator": True, "barShowNextEvent": True}))
        runtime = root / "run"
        runtime.mkdir(mode=0o700)
        env = {**os.environ, "QT_QPA_PLATFORM": "offscreen", "XDG_RUNTIME_DIR": str(runtime),
               "CALENDAR_SETTINGS_FILE": str(settings)}
        result = subprocess.run(["qs", "-p", str(root / "shell.qml")], env=env,
                                capture_output=True, text=True, timeout=15)
        output = result.stdout + result.stderr
        print(output, end="")
        if result.returncode or "FAIL!" in output or "CALENDAR_QML_ASSERTIONS_PASSED" not in output:
            raise SystemExit("Calendar QML integration test failed")
        if json.loads(settings.read_text()).get("barIncludeAllDay") is not True:
            raise SystemExit("The settings file did not retain the all-day preference")
        print("PASS settings persistence, keyboard toggle, translations, event selection and bar labels")


if __name__ == "__main__":
    main()
