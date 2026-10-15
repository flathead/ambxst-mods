import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.services

ShellRoot {
    id: root
    property var saved: null
    property var savedSearch: null
    property var dockEntry: AppSearch.getDesktopEntry("steam")

    function check(condition, message) {
        if (!condition) {
            console.error("FAIL", message);
            Qt.exit(1);
            throw new Error(message);
        }
        console.log("PASS", message);
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: {
            root.saved = AppSearch.getAllApps().find(a => a.id === "steam");
            root.savedSearch = AppSearch.fuzzyQuery("Steam").find(a => a.id === "steam");
            root.check(AppSearch.guessIcon("steam") === "steam", "Steam beats game executable match");
            root.check(AppSearch.guessIcon("steam_app_1086940") === "steam_icon_1086940", "Game icon remains correct");
            root.check(root.dockEntry?.icon === "steam", "Dock observes initial scan");
            trigger.running = true;
        }
    }

    Process {
        id: trigger
        command: ["python3", Quickshell.env("PROBE_ROOT") + "/change-entry.py"]
    }

    Timer {
        interval: 2200
        running: true
        onTriggered: {
            root.check(AppSearch.desktopEntriesRevision >= 2, "Rescan occurred");
            root.check(root.dockEntry?.icon === "steam", "Dock refreshes after object replacement");
            root.check(AppSearch.guessIcon("steam") === "steam", "Steam icon survives rescan");
            root.saved.execute();
            root.savedSearch.execute();
        }
    }

    Timer {
        interval: 3200
        running: true
        onTriggered: Qt.quit()
    }
}
