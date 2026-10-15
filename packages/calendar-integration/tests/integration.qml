import QtQuick
import QtTest
import Quickshell
import qs.config
import qs.modules.services
import qs.modules.bar
import qs.modules.widgets.dashboard.controls

ShellRoot {
    Window {
        id: window
        width: 900
        height: 800
        visible: true
        color: "#202020"

        QtObject { id: bar; property string orientation: "horizontal" }
        CalendarPanel {
            id: panel
            width: 480
            height: 780
            currentSection: "settings"
        }
        BarCalendarIndicator { id: indicator; x: 510; y: 30; bar: bar }

        TestCase {
            id: checks
            name: "CalendarAllDay"
            when: false

            function findItem(item, name) {
                if (item.objectName === name) return item;
                for (const child of item.children || []) {
                    const found = findItem(child, name);
                    if (found) return found;
                }
                return null;
            }

            function dateString(date) {
                return date.getFullYear() + "-" + String(date.getMonth() + 1).padStart(2, "0")
                    + "-" + String(date.getDate()).padStart(2, "0");
            }

            function test_setting_and_bar() {
                const now = new Date();
                const tomorrow = new Date(now);
                tomorrow.setDate(tomorrow.getDate() + 1);
                const event = { id: "day", title: "Day off", allDay: true,
                    start: dateString(now), end: dateString(tomorrow) };
                const meeting = { id: "meeting", title: "Team call", allDay: false,
                    start: new Date(now.getTime() + 3600000).toISOString(),
                    end: new Date(now.getTime() + 7200000).toISOString() };
                CalendarService.events = [event, meeting];
                const control = findItem(panel, "barIncludeAllDaySwitch");
                verify(control !== null, "The settings control exists");
                compare(control.checked, false);
                compare(control.enabled, true);
                compare(indicator.nextEvent.id, "meeting");

                control.forceActiveFocus();
                keyClick(Qt.Key_Space);
                compare(panel.pendingBarIncludeAllDay, true);
                compare(Config.calendar.barIncludeAllDay, false, "Keep the change pending until Save");
                compare(panel.hasChanges, true);
                panel.saveToConfig();
                compare(Config.calendar.barIncludeAllDay, true);
                compare(CalendarService.barIncludeAllDay, true);
                compare(indicator.nextEvent.id, "day");
                compare(indicator.timeUntilLive, "All day");

                panel.pendingBarIncludeAllDay = false;
                panel.resetToConfig();
                compare(panel.pendingBarIncludeAllDay, true);
                panel.pendingBarShowNextEvent = false;
                compare(control.enabled, false);
                compare(control.checked, true, "Keep the preference when the parent mode is off");
                panel.resetToConfig();

                I18n.resolvedLanguage = "ru";
                compare(indicator.timeUntilLive, "Весь день");
                compare(control.Accessible.name, "Учитывать события на весь день");
                I18n.resolvedLanguage = "es";
                compare(indicator.timeUntilLive, "Todo el día");
                I18n.resolvedLanguage = "en";

                const after = new Date(tomorrow);
                after.setDate(after.getDate() + 1);
                CalendarService.events = [{ id: "future", title: "Holiday", allDay: true,
                    start: dateString(tomorrow), end: dateString(after) }];
                compare(indicator.nextEvent.id, "future");
                verify(indicator.timeUntilLive.indexOf("All day · ") === 0);

                CalendarService.events = [event, { id: "current", title: "Live meeting", allDay: false,
                    start: new Date(now.getTime() - 60000).toISOString(),
                    end: new Date(now.getTime() + 60000).toISOString() }];
                compare(indicator.nextEvent.id, "current");
                // No eventsChanged signal: the clock tick must refresh selection.
                CalendarService.events[1].end = new Date(now.getTime() - 1000).toISOString();
                indicator._tick++;
                compare(indicator.nextEvent.id, "day");
                console.log("CALENDAR_QML_ASSERTIONS_PASSED");
            }

        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            try {
                window.requestActivate();
                checks.test_setting_and_bar();
                exitTimer.start();
            } catch (error) {
                console.error("CALENDAR_QML_FAILURE", error);
                Qt.exit(1);
            }
        }
    }
    Timer { id: exitTimer; interval: 200; onTriggered: Qt.quit() }
    Timer { interval: 10000; running: true; onTriggered: Qt.exit(1) }
}
