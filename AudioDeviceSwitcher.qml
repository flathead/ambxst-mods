pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.config

Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    property bool popupOpen: devicePopup.isOpen

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.maximumWidth: 36
    Layout.maximumHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    // --- Headset battery ---
    property int headsetBattery: -1
    property bool headsetOn: false

    readonly property bool isArctisSink: {
        const desc = (Audio.sink?.description ?? "").toLowerCase();
        const name = (Audio.sink?.name ?? "").toLowerCase();
        return desc.includes("arctis") || name.includes("arctis");
    }

    readonly property bool showBattery: isArctisSink && headsetOn && headsetBattery >= 0

    property Process batteryProc: Process {
        id: batteryProc
        command: ["dbus-send", "--session", "--print-reply", "--dest=name.giacomofurlan.ArctisManager.Next",
                  "/name/giacomofurlan/ArctisManager/Next/Status",
                  "name.giacomofurlan.ArctisManager.Next.Status.GetStatus"]
        running: false
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.headsetBattery = -1;
                root.headsetOn = false;
                return;
            }
            try {
                const raw = batteryProc.stdout.text;
                const match = raw.match(/string\s+"([\s\S]+)"/);
                if (!match) return;
                const data = JSON.parse(match[1]);
                const hs = data?.headset;
                root.headsetOn = hs?.headset_power_status?.value === "on";
                root.headsetBattery = hs?.headset_battery_charge?.value ?? -1;
            } catch (e) {
                root.headsetBattery = -1;
                root.headsetOn = false;
            }
        }
    }

    Timer {
        id: batteryTimer
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: batteryProc.running = true
    }

    // --- Icon helpers ---
    function sinkIcon(): string {
        const desc = (Audio.sink?.description ?? "").toLowerCase();
        const name = (Audio.sink?.name ?? "").toLowerCase();
        if (desc.includes("arctis") || name.includes("arctis"))
            return Icons.headphones;
        if (desc.includes("hdmi"))
            return Icons.speakerHigh;
        return Icons.speaker;
    }

    function deviceIcon(node, isSink: bool): string {
        const desc = (node?.description ?? "").toLowerCase();
        const name = (node?.name ?? "").toLowerCase();
        if (desc.includes("arctis") || name.includes("arctis"))
            return Icons.headphones;
        if (isSink) {
            if (desc.includes("hdmi"))
                return Icons.speakerHigh;
            return Icons.speaker;
        }
        return Icons.mic;
    }

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: root.popupOpen ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius: root.vertical ? root.startRadius : root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.popupOpen ? 0 : (root.isHovered ? 0.25 : 0)
            radius: parent.radius ?? 0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        // Icon + battery layout
        Row {
            anchors.centerIn: parent
            spacing: 1

            Text {
                id: buttonIcon
                text: root.sinkIcon()
                font.family: Icons.font
                font.pixelSize: root.showBattery ? 14 : 18
                color: root.popupOpen ? buttonBg.item : Styling.srItem("overprimary")
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
                Behavior on font.pixelSize {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration / 2 }
                }
            }

            Text {
                visible: root.showBattery
                text: root.headsetBattery + "%"
                font.family: Styling.defaultFont
                font.pixelSize: 9
                font.bold: true
                color: root.popupOpen ? buttonBg.item : Styling.srItem("overprimary")
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: devicePopup.toggle()

            onWheel: wheel => {
                if (wheel.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (wheel.angleDelta.y < 0)
                    Audio.decrementVolume();
            }
        }

        StyledToolTip {
            visible: root.isHovered && !root.popupOpen
            tooltipText: {
                const name = Audio.friendlyDeviceName(Audio.sink);
                if (root.showBattery)
                    return name + " · " + root.headsetBattery + "%";
                return name;
            }
        }
    }

    BarPopup {
        id: devicePopup
        anchorItem: buttonBg
        bar: root.bar
        popupPadding: 8

        contentWidth: 260
        contentHeight: popupColumn.implicitHeight + popupPadding * 2

        ColumnLayout {
            id: popupColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 2

            // Section: Output
            Text {
                Layout.leftMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 2
                text: "Output"
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                font.bold: true
                color: Colors.overSurfaceVariant
                opacity: 0.6
            }

            Repeater {
                model: Audio.outputDevices

                delegate: Item {
                    id: outputDelegate
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 36

                    readonly property bool isSelected: Audio.sink === modelData
                    property bool itemHovered: false

                    PwObjectTracker {
                        objects: [outputDelegate.modelData]
                    }

                    StyledRect {
                        anchors.fill: parent
                        variant: outputDelegate.isSelected ? "primary" : (outputDelegate.itemHovered ? "focus" : "common")
                        enableShadow: false
                        radius: Styling.radius(-2)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: outputDelegate.itemHovered = true
                        onExited: outputDelegate.itemHovered = false
                        onClicked: {
                            Audio.setDefaultSink(outputDelegate.modelData);
                            devicePopup.close();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: root.deviceIcon(outputDelegate.modelData, true)
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: outputDelegate.isSelected
                                ? Styling.srItem("primary")
                                : Colors.overBackground
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Audio.friendlyDeviceName(outputDelegate.modelData)
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            font.weight: outputDelegate.isSelected ? Font.Bold : Font.Normal
                            color: outputDelegate.isSelected
                                ? Styling.srItem("primary")
                                : Colors.overBackground
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: outputDelegate.isSelected
                            text: Icons.accept
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: Styling.srItem("primary")
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                height: 1
                color: Colors.surfaceBright
            }

            // Section: Input
            Text {
                Layout.leftMargin: 8
                Layout.bottomMargin: 2
                text: "Input"
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                font.bold: true
                color: Colors.overSurfaceVariant
                opacity: 0.6
            }

            Repeater {
                model: Audio.inputDevices

                delegate: Item {
                    id: inputDelegate
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 36

                    readonly property bool isSelected: Audio.source === modelData
                    property bool itemHovered: false

                    PwObjectTracker {
                        objects: [inputDelegate.modelData]
                    }

                    StyledRect {
                        anchors.fill: parent
                        variant: inputDelegate.isSelected ? "primary" : (inputDelegate.itemHovered ? "focus" : "common")
                        enableShadow: false
                        radius: Styling.radius(-2)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: inputDelegate.itemHovered = true
                        onExited: inputDelegate.itemHovered = false
                        onClicked: {
                            Audio.setDefaultSource(inputDelegate.modelData);
                            devicePopup.close();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: root.deviceIcon(inputDelegate.modelData, false)
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: inputDelegate.isSelected
                                ? Styling.srItem("primary")
                                : Colors.overBackground
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Audio.friendlyDeviceName(inputDelegate.modelData)
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            font.weight: inputDelegate.isSelected ? Font.Bold : Font.Normal
                            color: inputDelegate.isSelected
                                ? Styling.srItem("primary")
                                : Colors.overBackground
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: inputDelegate.isSelected
                            text: Icons.accept
                            font.family: Icons.font
                            font.pixelSize: 14
                            color: Styling.srItem("primary")
                        }
                    }
                }
            }
        }
    }
}
